import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../../core/utils/date_utils_ext.dart';
import '../../domain/models/models.dart';
import '../../domain/services/recurrence_engine.dart';
import '../local/app_database.dart';
import 'finance_repository.dart';

class FinanceRepositoryImpl implements FinanceRepository {
  FinanceRepositoryImpl(this._database, this._engine);

  final AppDatabase _database;
  final RecurrenceEngine _engine;
  final _uuid = const Uuid();

  @override
  Future<void> seedIfEmpty() async {
    // Intentionally left empty: app must start with no demo records.
  }

  @override
  Future<void> purgeExpiredPlans() async {
    final db = await _database.db;
    await db.delete(
      'plans',
      where: 'retention_until IS NOT NULL AND retention_until <= ?',
      whereArgs: [DateTime.now().toIso8601String()],
    );
  }

  @override
  Future<List<ObligationPlan>> getPlans({bool includeArchived = false}) async {
    final db = await _database.db;
    final rows = await db.query(
      'plans',
      where: includeArchived ? null : 'archived = 0',
      orderBy: 'updated_at DESC',
    );
    return rows.map(ObligationPlan.fromMap).toList(growable: false);
  }

  @override
  Future<ObligationPlan?> getPlan(String planId) async {
    final db = await _database.db;
    final rows = await db.query('plans', where: 'id = ?', whereArgs: [planId]);
    if (rows.isEmpty) return null;
    return ObligationPlan.fromMap(rows.first);
  }

  @override
  Future<void> upsertPlan(ObligationPlan plan) async {
    final db = await _database.db;
    await db.insert(
      'plans',
      plan.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> deletePlan(String planId, {bool permanent = false}) async {
    final db = await _database.db;
    if (permanent) {
      await db.delete('plans', where: 'id = ?', whereArgs: [planId]);
      return;
    }
    final keepUntil = DateTime.now().add(const Duration(days: 30)).toIso8601String();
    await db.update(
      'plans',
      {
        'archived': 1,
        'retention_until': keepUntil,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [planId],
    );
  }

  @override
  Future<void> closePlan(String planId) async {
    final db = await _database.db;
    final keepUntil = DateTime.now().add(const Duration(days: 30)).toIso8601String();
    await db.update(
      'plans',
      {
        'manual_closed': 1,
        'retention_until': keepUntil,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [planId],
    );
  }

  @override
  Future<List<ReminderConfig>> getRemindersForPlan(String planId) async {
    final db = await _database.db;
    final rows = await db.query(
      'reminders',
      where: 'plan_id = ?',
      whereArgs: [planId],
      orderBy: 'type ASC',
    );
    return rows.map(ReminderConfig.fromMap).toList(growable: false);
  }

  @override
  Future<void> replaceReminders(
    String planId,
    List<ReminderConfig> reminders,
  ) async {
    final db = await _database.db;
    await db.transaction((tx) async {
      await tx.delete('reminders', where: 'plan_id = ?', whereArgs: [planId]);
      for (final reminder in reminders) {
        await tx.insert('reminders', reminder.toMap());
      }
    });
  }

  @override
  Future<List<Occurrence>> getOccurrences({String? planId}) async {
    final db = await _database.db;
    final rows = await db.query(
      'occurrences',
      where: planId == null ? null : 'plan_id = ?',
      whereArgs: planId == null ? null : [planId],
      orderBy: 'due_date ASC',
    );
    return rows.map(Occurrence.fromMap).toList(growable: false);
  }

  @override
  Future<void> upsertOccurrence(Occurrence occurrence) async {
    final db = await _database.db;
    await db.insert(
      'occurrences',
      occurrence.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> ensureOccurrencesForPlan(
    String planId, {
    int horizonDays = 420,
  }) async {
    final plan = await getPlan(planId);
    if (plan == null || plan.archived) return;

    final db = await _database.db;
    final now = DateTime.now();
    final existing = await getOccurrences(planId: plan.id);
    final bySeq = {for (final o in existing) o.sequenceIndex: o};

    final to = now.add(Duration(days: horizonDays));
    var index = 0;
    while (true) {
      final date = _engine.occurrenceDate(plan, index);
      if (date == null || date.isAfter(to)) break;
      if (bySeq[index] == null) {
        await db.insert(
          'occurrences',
          Occurrence(
            id: _uuid.v4(),
            planId: plan.id,
            sequenceIndex: index,
            dueDate: date,
            amountCents: plan.amountCents,
            paidAmountCents: 0,
            status: date.dateOnly.isBefore(now.dateOnly)
                ? OccurrenceStatus.overdue
                : OccurrenceStatus.due,
          ).toMap(),
        );
      }
      index++;
      if (index > 2400) break;
    }

    final refreshed = await getOccurrences(planId: planId);
    for (final item in refreshed) {
      if (item.status == OccurrenceStatus.paid) continue;
      final newStatus = item.dueDate.dateOnly.isBefore(now.dateOnly)
          ? OccurrenceStatus.overdue
          : OccurrenceStatus.due;
      if (newStatus != item.status) {
        await db.update(
          'occurrences',
          {'status': newStatus.name},
          where: 'id = ?',
          whereArgs: [item.id],
        );
      }
    }

    final latestPlan = await getPlan(planId);
    if (latestPlan == null) return;
    final done = _engine.isCompleted(latestPlan, refreshed);
    if (done && latestPlan.retentionUntil == null) {
      await db.update(
        'plans',
        {
          'retention_until':
              DateTime.now().add(const Duration(days: 30)).toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [planId],
      );
    }
  }

  @override
  Future<void> addPayment(PaymentRecord payment) async {
    final db = await _database.db;
    await db.transaction((tx) async {
      await tx.insert('payments', payment.toMap());

      final occurrenceRows = await tx.query(
        'occurrences',
        where: 'id = ?',
        whereArgs: [payment.occurrenceId],
      );
      if (occurrenceRows.isEmpty) return;
      final occurrence = Occurrence.fromMap(occurrenceRows.first);
      final newPaid = occurrence.paidAmountCents + payment.amountCents;
      final status = newPaid >= occurrence.amountCents
          ? OccurrenceStatus.paid
          : occurrence.dueDate.dateOnly.isBefore(DateTime.now().dateOnly)
              ? OccurrenceStatus.overdue
              : OccurrenceStatus.due;

      await tx.update(
        'occurrences',
        {
          'paid_amount_cents': newPaid,
          'status': status.name,
        },
        where: 'id = ?',
        whereArgs: [payment.occurrenceId],
      );

      await tx.update(
        'plans',
        {'updated_at': DateTime.now().toIso8601String()},
        where: 'id = ?',
        whereArgs: [payment.planId],
      );
    });
  }

  @override
  Future<List<PaymentRecord>> getPayments({String? planId, int limit = 200}) async {
    final db = await _database.db;
    final rows = await db.query(
      'payments',
      where: planId == null ? null : 'plan_id = ?',
      whereArgs: planId == null ? null : [planId],
      orderBy: 'paid_at DESC',
      limit: limit,
    );
    return rows.map(PaymentRecord.fromMap).toList(growable: false);
  }

  @override
  Future<void> deletePayment(String paymentId) async {
    final db = await _database.db;
    await db.transaction((tx) async {
      final rows = await tx.query('payments', where: 'id = ?', whereArgs: [paymentId]);
      if (rows.isEmpty) return;
      final payment = PaymentRecord.fromMap(rows.first);

      await tx.delete('payments', where: 'id = ?', whereArgs: [paymentId]);

      final paidRows = await tx.rawQuery(
        'SELECT COALESCE(SUM(amount_cents), 0) AS total FROM payments WHERE occurrence_id = ?',
        [payment.occurrenceId],
      );
      final total = (paidRows.first['total'] as int?) ?? 0;

      final occurrenceRows = await tx.query(
        'occurrences',
        where: 'id = ?',
        whereArgs: [payment.occurrenceId],
      );
      if (occurrenceRows.isEmpty) return;
      final occurrence = Occurrence.fromMap(occurrenceRows.first);
      final status = total >= occurrence.amountCents
          ? OccurrenceStatus.paid
          : occurrence.dueDate.dateOnly.isBefore(DateTime.now().dateOnly)
              ? OccurrenceStatus.overdue
              : OccurrenceStatus.due;

      await tx.update(
        'occurrences',
        {'paid_amount_cents': total, 'status': status.name},
        where: 'id = ?',
        whereArgs: [payment.occurrenceId],
      );
    });
  }

  @override
  Future<List<SalaryConfig>> getSalaryConfigs() async {
    final db = await _database.db;
    final rows = await db.query('salary_configs', orderBy: 'month_key DESC');
    return rows.map(SalaryConfig.fromMap).toList(growable: false);
  }

  @override
  Future<void> upsertSalaryConfig(SalaryConfig config) async {
    final db = await _database.db;
    await db.insert(
      'salary_configs',
      config.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<AppSettings> getSettings() async {
    final db = await _database.db;
    final rows = await db.query('settings', where: 'id = 1');
    if (rows.isEmpty) return AppSettings.defaults;
    return AppSettings.fromMap(rows.first);
  }

  @override
  Future<void> saveSettings(AppSettings settings) async {
    final db = await _database.db;
    await db.update('settings', settings.toMap(), where: 'id = 1');
  }

  @override
  Future<void> clearAllData() async {
    final db = await _database.db;
    await db.transaction((tx) async {
      await tx.delete('payments');
      await tx.delete('occurrences');
      await tx.delete('reminders');
      await tx.delete('plans');
      await tx.delete('salary_configs');
      await tx.update(
        'settings',
        AppSettings.defaults.toMap(),
        where: 'id = 1',
      );
    });
  }
}
