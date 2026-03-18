import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../application/providers.dart';
import '../core/design/tokens.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/date_utils_ext.dart';
import '../core/widgets/loading_state.dart';
import '../domain/models/models.dart';
import '../domain/services/salary_service.dart';
import '../features/dashboard/dashboard_screen.dart';
import '../features/obligations/add_edit_item_screen.dart';
import '../features/obligations/item_detail_screen.dart';
import '../features/obligations/obligations_screen.dart';
import '../features/salary/salary_screen.dart';
import '../features/settings/notification_debug_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/timeline/timeline_screen.dart';

class DebtTrackerApp extends ConsumerWidget {
  const DebtTrackerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(financeControllerProvider);
    final settings = state.valueOrNull?.settings ?? AppSettings.defaults;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Debtly',
      theme: AppTheme.dark(settings.accentTheme),
      darkTheme: AppTheme.dark(settings.accentTheme),
      themeMode: ThemeMode.dark,
      builder: (context, child) {
        final accent = Theme.of(context).extension<AppAccentColors>() ??
            AppAccentColors.fromTheme(settings.accentTheme);
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 280),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          child: _AppBackdrop(
            accent: accent,
            child: child ?? const SizedBox.shrink(),
          ),
        );
      },
      home: const HomeShell(),
    );
  }
}

class _AppBackdrop extends StatelessWidget {
  const _AppBackdrop({
    required this.accent,
    required this.child,
  });

  final AppAccentColors accent;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: DecoratedBox(
            decoration: const BoxDecoration(color: AppPalette.background),
          ),
        ),
        Positioned(
          top: -140,
          right: -60,
          child: _GlowOrb(
            color: accent.primary.withValues(alpha: 0.18),
            size: 260,
          ),
        ),
        Positioned(
          bottom: -180,
          left: -80,
          child: _GlowOrb(
            color: accent.soft.withValues(alpha: 0.14),
            size: 320,
          ),
        ),
        Positioned.fill(child: child),
      ],
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({
    required this.color,
    required this.size,
  });

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color,
              blurRadius: 120,
              spreadRadius: 32,
            ),
          ],
        ),
      ),
    );
  }
}

class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final asyncState = ref.watch(financeControllerProvider);
    final notificationPlanId = ref.watch(selectedPlanFromNotificationProvider);

    return asyncState.when(
      loading: () => const Scaffold(body: LoadingState()),
      error: (error, _) => Scaffold(body: Center(child: Text('Error: $error'))),
      data: (data) {
        final engine = ref.read(recurrenceEngineProvider);
        final salaryService = ref.read(salaryServiceProvider);
        final bundles = data.bundles(engine);
        final month = DateTime.now();
        final salarySummary = data.salarySummaryForMonth(salaryService, month);

        if (notificationPlanId != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ref.read(selectedPlanFromNotificationProvider.notifier).state = null;
            _openDetail(data, notificationPlanId);
          });
        }

        final overdueCount = bundles
            .where((b) => b.nextOccurrence?.status == OccurrenceStatus.overdue)
            .length;

        final dueToday = bundles.where((b) {
          final due = b.nextOccurrence?.dueDate;
          return due != null && due.isSameDate(DateTime.now());
        }).toList(growable: false);

        final upcomingWeek = bundles.where((b) {
          final due = b.nextOccurrence?.dueDate;
          if (due == null) return false;
          final now = DateTime.now();
          return !due.isBefore(now.dateOnly) && !due.isAfter(now.add(const Duration(days: 7)));
        }).toList(growable: false);

        final screens = [
          DashboardScreen(
            key: const ValueKey('overview'),
            summary: salarySummary,
            currency: data.settings.currencyCode,
            overdueCount: overdueCount,
            dueToday: dueToday,
            upcomingWeek: upcomingWeek,
            recentPayments: data.payments,
            onQuickAdd: _openAdd,
            onOpenItem: (id) => _openDetail(data, id),
          ),
          ObligationsScreen(
            key: const ValueKey('plans'),
            bundles: bundles,
            currency: data.settings.currencyCode,
            onTap: (id) => _openDetail(data, id),
          ),
          TimelineScreen(
            key: const ValueKey('timeline'),
            occurrences: data.occurrences,
            payments: data.payments,
            plansById: {for (final p in data.plans) p.id: p},
            onOpen: (id) => _openDetail(data, id),
          ),
          SalaryScreen(
            key: const ValueKey('salary'),
            month: month,
            summary: salarySummary,
            currency: data.settings.currencyCode,
            config: _salaryFor(data.salaryConfigs, month.monthKey),
            onEditSalary: (amountCents, day, monthKey) async {
              await ref.read(financeControllerProvider.notifier).upsertSalary(
                    SalaryConfig(
                      id: const Uuid().v4(),
                      monthKey: monthKey,
                      amountCents: amountCents,
                      salaryDay: day,
                    ),
                  );
            },
            monthlyHistory: _buildMonthlyHistory(data, salaryService),
          ),
        ];

        return Scaffold(
          appBar: AppBar(
            toolbarHeight: 74,
            title: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppPalette.surfaceRaised,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: context.accentColors.primary.withValues(alpha: 0.14),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: context.accentColors.soft.withValues(alpha: 0.10),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(5),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset(
                      'assets/branding/debtly_logo.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(_titles[_index]),
              ],
            ),
            actions: [
              IconButton(
                onPressed: () => _openSettings(data.settings),
                icon: const Icon(Icons.tune_rounded),
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: () => ref.read(financeControllerProvider.notifier).refresh(),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 260),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.02, 0),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                );
              },
              child: screens[_index],
            ),
          ),
          floatingActionButton: _index == 0 || _index == 1
              ? DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: context.accentColors.primary.withValues(alpha: 0.18),
                        blurRadius: 26,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: FloatingActionButton.extended(
                    onPressed: _openAdd,
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Add'),
                  ),
                )
              : null,
          bottomNavigationBar: NavigationBar(
            height: 80,
            selectedIndex: _index,
            onDestinationSelected: (i) => setState(() => _index = i),
            destinations: const [
              NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Overview'),
              NavigationDestination(icon: Icon(Icons.view_agenda_outlined), label: 'Plans'),
              NavigationDestination(icon: Icon(Icons.timeline_rounded), label: 'Timeline'),
              NavigationDestination(
                icon: Icon(Icons.account_balance_wallet_outlined),
                label: 'Salary',
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _openSettings(AppSettings settings) async {
    await Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 280),
        reverseTransitionDuration: const Duration(milliseconds: 220),
        pageBuilder: (_, animation, __) => FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
          child: SettingsScreen(
            settings: settings,
            onSave: (next) async {
              await ref.read(financeControllerProvider.notifier).saveSettings(next);
            },
            onOpenNotificationDebug: _openNotificationDebug,
          ),
        ),
      ),
    );
  }

  Future<void> _openNotificationDebug() async {
    await Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 280),
        reverseTransitionDuration: const Duration(milliseconds: 220),
        pageBuilder: (_, animation, __) => FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
          child: const NotificationDebugScreen(),
        ),
      ),
    );
  }

  Future<void> _openAdd() async {
    final result = await Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 280),
        reverseTransitionDuration: const Duration(milliseconds: 220),
        pageBuilder: (_, animation, __) => FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
          child: const AddEditItemScreen(),
        ),
      ),
    );
    if (result == null || result is! ({ObligationPlan plan, List<ReminderConfig> reminders})) {
      return;
    }
    await ref.read(financeControllerProvider.notifier).savePlan(
          plan: result.plan,
          reminders: result.reminders,
        );
  }

  Future<void> _openDetail(FinanceState data, String planId) async {
    final plan = data.plans.where((p) => p.id == planId).firstOrNull;
    if (plan == null || !mounted) return;

    await Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 300),
        reverseTransitionDuration: const Duration(milliseconds: 220),
        pageBuilder: (_, animation, __) => FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.03),
              end: Offset.zero,
            ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
            child: ItemDetailScreen(
              plan: plan,
              occurrences: data.occurrencesForPlan(planId),
              payments: data.payments.where((p) => p.planId == planId).toList(),
              reminders: data.remindersByPlan[planId] ?? const [],
              currency: data.settings.currencyCode,
              onAddPayment: (occurrence, cents) async {
                await ref.read(financeControllerProvider.notifier).addPayment(
                      planId: planId,
                      occurrenceId: occurrence.id,
                      amountCents: cents,
                    );
              },
              onEdit: () async {
                final editResult = await Navigator.of(context).push(
                  PageRouteBuilder(
                    transitionDuration: const Duration(milliseconds: 280),
                    reverseTransitionDuration: const Duration(milliseconds: 220),
                    pageBuilder: (_, animation, __) => FadeTransition(
                      opacity: CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeOutCubic,
                      ),
                      child: AddEditItemScreen(
                        initialPlan: plan,
                        initialReminders: data.remindersByPlan[planId] ?? const [],
                        onDelete: () async {
                          await ref
                              .read(financeControllerProvider.notifier)
                              .deletePlanPermanently(planId);
                          if (mounted) {
                            Navigator.of(context).pop();
                            Navigator.of(context).pop();
                          }
                        },
                      ),
                    ),
                  ),
                );
                if (editResult == null ||
                    editResult
                        is! ({ObligationPlan plan, List<ReminderConfig> reminders})) {
                  return;
                }
                await ref.read(financeControllerProvider.notifier).savePlan(
                      plan: editResult.plan,
                      reminders: editResult.reminders,
                    );
              },
              onClose: () async {
                await ref.read(financeControllerProvider.notifier).closePlan(planId);
                if (mounted) Navigator.of(context).pop();
              },
            ),
          ),
        ),
      ),
    );
  }

  SalaryConfig? _salaryFor(List<SalaryConfig> configs, String key) {
    for (final c in configs) {
      if (c.monthKey == key) return c;
    }
    for (final c in configs) {
      if (c.monthKey == 'default') return c;
    }
    return null;
  }

  List<(String, SalarySummary)> _buildMonthlyHistory(
    FinanceState data,
    SalaryService service,
  ) {
    final keys = <String>{};
    for (final config in data.salaryConfigs) {
      if (config.monthKey != 'default') keys.add(config.monthKey);
    }
    for (final payment in data.payments) {
      final date = payment.paidAt;
      keys.add('${date.year}-${date.month.toString().padLeft(2, '0')}');
    }
    for (final occurrence in data.occurrences) {
      final date = occurrence.dueDate;
      keys.add('${date.year}-${date.month.toString().padLeft(2, '0')}');
    }

    final months = keys.toList()
      ..sort((a, b) => b.compareTo(a));

    final list = <(String, SalarySummary)>[];
    for (final key in months.take(6)) {
      final parts = key.split('-');
      if (parts.length != 2) continue;
      final year = int.tryParse(parts[0]);
      final monthIndex = int.tryParse(parts[1]);
      if (year == null || monthIndex == null) continue;
      final month = DateTime(year, monthIndex, 1);
      final summary = data.salarySummaryForMonth(service, month);
      list.add((key, summary));
    }
    return list;
  }
}

const _titles = ['Overview', 'Debts', 'Timeline', 'Salary'];

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
