import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../data/local/app_database.dart';
import '../data/repositories/finance_repository.dart';
import '../data/repositories/finance_repository_impl.dart';
import '../domain/models/models.dart';
import '../domain/services/notification_service.dart';
import '../domain/services/recurrence_engine.dart';
import '../domain/services/salary_service.dart';

final appDatabaseProvider = Provider((ref) => AppDatabase());
final recurrenceEngineProvider = Provider((ref) => const RecurrenceEngine());
final salaryServiceProvider = Provider((ref) => const SalaryService());
final notificationServiceProvider = Provider((ref) => NotificationService());

final financeRepositoryProvider = Provider<FinanceRepository>((ref) {
  return FinanceRepositoryImpl(
    ref.read(appDatabaseProvider),
    ref.read(recurrenceEngineProvider),
  );
});

final selectedPlanFromNotificationProvider = StateProvider<String?>((ref) => null);

class FinanceState {
  const FinanceState({
    required this.plans,
    required this.occurrences,
    required this.payments,
    required this.remindersByPlan,
    required this.salaryConfigs,
    required this.settings,
    required this.notificationDiagnostics,
  });

  final List<ObligationPlan> plans;
  final List<Occurrence> occurrences;
  final List<PaymentRecord> payments;
  final Map<String, List<ReminderConfig>> remindersByPlan;
  final List<SalaryConfig> salaryConfigs;
  final AppSettings settings;
  final NotificationDiagnostics notificationDiagnostics;

  List<Occurrence> occurrencesForPlan(String planId) {
    return occurrences.where((o) => o.planId == planId).toList(growable: false);
  }

  List<ObligationBundle> bundles(RecurrenceEngine engine) {
    return plans
        .map((plan) {
          final planOccurrences = occurrencesForPlan(plan.id);
          final next = planOccurrences
              .where((o) => o.status != OccurrenceStatus.paid)
              .toList()
            ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
          final completed = engine.isCompleted(plan, planOccurrences);
          return ObligationBundle(
            plan: plan,
            reminders: remindersByPlan[plan.id] ?? const [],
            nextOccurrence: next.isEmpty ? null : next.first,
            isCompleted: completed || plan.manualClosed,
          );
        })
        .toList(growable: false);
  }

  SalarySummary salarySummaryForMonth(SalaryService service, DateTime month) {
    return service.summarizeMonth(
      month: month,
      salaryConfigs: salaryConfigs,
      plans: plans,
      occurrences: occurrences,
    );
  }
}

final financeControllerProvider =
    AsyncNotifierProvider<FinanceController, FinanceState>(FinanceController.new);

class FinanceController extends AsyncNotifier<FinanceState> {
  final _uuid = const Uuid();

  FinanceRepository get _repo => ref.read(financeRepositoryProvider);
  NotificationService get _notifications => ref.read(notificationServiceProvider);

  @override
  Future<FinanceState> build() async {
    await _repo.seedIfEmpty();
    await _notifications.init(_onNotificationTapped);
    return _reload();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_reload);
  }

  Future<FinanceState> _reload() async {
    await _repo.purgeExpiredPlans();
    final plans = await _repo.getPlans();
    for (final plan in plans) {
      await _repo.ensureOccurrencesForPlan(plan.id);
    }

    final reminders = <String, List<ReminderConfig>>{};
    for (final plan in plans) {
      reminders[plan.id] = await _repo.getRemindersForPlan(plan.id);
    }

    final occurrences = await _repo.getOccurrences();
    final payments = await _repo.getPayments(limit: 300);
    final salaryConfigs = await _repo.getSalaryConfigs();
    final settings = await _repo.getSettings();

    var data = FinanceState(
      plans: plans,
      occurrences: occurrences,
      payments: payments,
      remindersByPlan: reminders,
      salaryConfigs: salaryConfigs,
      settings: settings,
      notificationDiagnostics: const NotificationDiagnostics(
        timezone: 'unknown',
        pendingCount: 0,
        notificationsEnabled: null,
        exactAlarmAllowed: null,
        ignoresBatteryOptimizations: null,
        deviceManufacturer: '',
        lastScheduleAttempted: null,
        lastScheduleSucceeded: null,
        lastScheduleError: null,
        warnings: [],
        attemptedCount: 0,
        succeededCount: 0,
        failedCount: 0,
        skippedCount: 0,
        lastSkipReason: null,
        lastPendingReadError: null,
      ),
    );

    if (settings.notificationsEnabled) {
      await _rescheduleAll(data);
    }

    final diagnostics = await _notifications.getDiagnostics();
    data = FinanceState(
      plans: plans,
      occurrences: occurrences,
      payments: payments,
      remindersByPlan: reminders,
      salaryConfigs: salaryConfigs,
      settings: settings,
      notificationDiagnostics: diagnostics,
    );

    return data;
  }

  Future<void> savePlan({
    required ObligationPlan plan,
    required List<ReminderConfig> reminders,
  }) async {
    await _repo.upsertPlan(plan);
    await _repo.replaceReminders(plan.id, reminders);
    await _repo.ensureOccurrencesForPlan(plan.id, horizonDays: 550);
    await HapticFeedback.mediumImpact();
    await refresh();
  }

  Future<void> addPayment({
    required String planId,
    required String occurrenceId,
    required int amountCents,
    String note = '',
  }) async {
    await _repo.addPayment(
      PaymentRecord(
        id: _uuid.v4(),
        planId: planId,
        occurrenceId: occurrenceId,
        amountCents: amountCents,
        paidAt: DateTime.now(),
        note: note,
      ),
    );
    await HapticFeedback.mediumImpact();
    await refresh();
  }

  Future<void> closePlan(String planId) async {
    await _repo.closePlan(planId);
    await HapticFeedback.mediumImpact();
    await refresh();
  }

  Future<void> archivePlan(String planId) async {
    await _repo.deletePlan(planId, permanent: false);
    await _notifications.cancelPlanNotifications(planId);
    await HapticFeedback.mediumImpact();
    await refresh();
  }

  Future<void> deletePlanPermanently(String planId) async {
    await _repo.deletePlan(planId, permanent: true);
    await _notifications.cancelPlanNotifications(planId);
    await HapticFeedback.heavyImpact();
    await refresh();
  }

  Future<void> upsertSalary(SalaryConfig config) async {
    await _repo.upsertSalaryConfig(config);
    await HapticFeedback.lightImpact();
    await refresh();
  }

  Future<void> saveSettings(AppSettings settings) async {
    await _repo.saveSettings(settings);
    await HapticFeedback.selectionClick();
    await refresh();
  }

  Future<String> exportLocalBackup() async {
    final current = state.valueOrNull ?? await _reload();
    final payload = {
      'exported_at': DateTime.now().toIso8601String(),
      'version': 1,
      'plans': current.plans.map((e) => e.toMap()).toList(growable: false),
      'occurrences':
          current.occurrences.map((e) => e.toMap()).toList(growable: false),
      'payments': current.payments.map((e) => e.toMap()).toList(growable: false),
      'reminders_by_plan': {
        for (final entry in current.remindersByPlan.entries)
          entry.key: entry.value.map((e) => e.toMap()).toList(growable: false),
      },
      'salary_configs':
          current.salaryConfigs.map((e) => e.toMap()).toList(growable: false),
      'settings': current.settings.toMap(),
    };

    final dir = await getApplicationDocumentsDirectory();
    final stamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final file = File('${dir.path}/debtly_backup_$stamp.json');
    await file.writeAsString(const JsonEncoder.withIndent('  ').convert(payload));
    await HapticFeedback.lightImpact();
    return file.path;
  }

  Future<void> clearAllLocalData() async {
    await _notifications.cancelAll();
    await _repo.clearAllData();
    await HapticFeedback.heavyImpact();
    await refresh();
  }

  Future<void> rescheduleAllActiveReminders() async {
    final current = state.valueOrNull ?? await _reload();
    await _rescheduleAll(current);
  }

  Future<void> cancelAllReminders() async {
    await _notifications.cancelAll();
  }

  Future<void> _rescheduleAll(FinanceState data) async {
    debugPrint(
      '[FinanceController] reschedule start plans=${data.plans.length}',
    );
    final salaryDefault = data.salaryConfigs.where((e) => e.monthKey == 'default');
    final fallback = salaryDefault.isEmpty ? null : salaryDefault.first;

    for (final plan in data.plans) {
      final planOccurrences =
          data.occurrences.where((o) => o.planId == plan.id).toList(growable: false);
      try {
        await _notifications.scheduleForPlan(
          plan: plan,
          occurrences: planOccurrences,
          reminders: data.remindersByPlan[plan.id] ?? const [],
          salaryConfig: fallback,
        );
      } catch (e) {
        debugPrint(
          '[FinanceController] schedule failed plan=${plan.id} title=${plan.title} error=$e',
        );
      }
    }
    debugPrint('[FinanceController] reschedule finished');
  }

  void _onNotificationTapped(String payload) {
    try {
      debugPrint('[FinanceController] notification tapped payload=$payload');
      final map = jsonDecode(payload) as Map<String, dynamic>;
      ref.read(selectedPlanFromNotificationProvider.notifier).state =
          map['planId'] as String?;
    } catch (_) {
      debugPrint('[FinanceController] notification tap payload parse failed');
      ref.read(selectedPlanFromNotificationProvider.notifier).state = null;
    }
  }
}
