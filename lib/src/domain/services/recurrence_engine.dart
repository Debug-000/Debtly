import '../models/models.dart';
import '../../core/utils/date_utils_ext.dart';

class RecurrenceEngine {
  const RecurrenceEngine();

  List<DateTime> generateDueDates(
    ObligationPlan plan, {
    required DateTime from,
    required DateTime to,
  }) {
    if (to.isBefore(from)) return const [];

    final dates = <DateTime>[];
    var i = 0;
    while (true) {
      final next = occurrenceDate(plan, i);
      if (next == null) break;
      if (next.isAfter(to)) break;
      if (!next.isBefore(from)) {
        dates.add(next);
      }
      i++;
      if (i > 2400) break;
    }
    return dates;
  }

  DateTime? occurrenceDate(ObligationPlan plan, int index) {
    final start = plan.startDate.dateOnly;

    DateTime date;
    switch (plan.recurrenceType) {
      case RecurrenceType.oneTime:
        if (index > 0) return null;
        date = safeDate(start.year, start.month, plan.dueDay);
      case RecurrenceType.monthly:
        final monthsToAdd = index;
        final monthDate = DateTime(start.year, start.month + monthsToAdd, 1);
        date = safeDate(monthDate.year, monthDate.month, plan.dueDay);
      case RecurrenceType.yearly:
        final year = start.year + index;
        date = safeDate(year, start.month, plan.dueDay);
      case RecurrenceType.customDays:
        final months = plan.customIntervalMonths;
        if (months != null && months > 0) {
          final monthDate = DateTime(start.year, start.month + (months * index), 1);
          date = safeDate(monthDate.year, monthDate.month, plan.dueDay);
        } else {
          final every = plan.customIntervalDays ?? 30;
          // Backward compatibility: treat 90/60/120 day custom setups as month-based.
          if (every % 30 == 0 && every >= 60) {
            final monthStep = every ~/ 30;
            final monthDate = DateTime(start.year, start.month + (monthStep * index), 1);
            date = safeDate(monthDate.year, monthDate.month, plan.dueDay);
          } else {
            date = start.add(Duration(days: every * index));
          }
        }
    }

    if (_isBeyondDuration(plan, date, index)) {
      return null;
    }
    return date;
  }

  DateTime? nextDue(
    ObligationPlan plan,
    List<Occurrence> occurrences,
    DateTime now,
  ) {
    final due = occurrences
        .where((o) => o.status != OccurrenceStatus.paid)
        .toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
    if (due.isNotEmpty) return due.first.dueDate;

    final generated = generateDueDates(
      plan,
      from: now,
      to: now.add(const Duration(days: 720)),
    );
    return generated.isEmpty ? null : generated.first;
  }

  bool isCompleted(ObligationPlan plan, List<Occurrence> occurrences) {
    if (plan.manualClosed) return true;
    if (plan.durationType == DurationType.untilClosed) return false;

    final latest = _latestPossibleDate(plan);
    if (latest == null) return false;

    final allAtOrBefore = occurrences
        .where((o) => !o.dueDate.isAfter(latest))
        .toList(growable: false);
    if (allAtOrBefore.isEmpty) return false;
    return allAtOrBefore.every((o) => o.status == OccurrenceStatus.paid);
  }

  bool _isBeyondDuration(ObligationPlan plan, DateTime date, int index) {
    switch (plan.durationType) {
      case DurationType.untilClosed:
        return plan.manualClosed;
      case DurationType.untilDate:
        final end = plan.endDate?.dateOnly;
        if (end == null) return false;
        return date.isAfter(end);
      case DurationType.fixedMonths:
        final months = plan.durationValue ?? 1;
        if (plan.recurrenceType == RecurrenceType.monthly) {
          return index >= months;
        }
        final end = DateTime(plan.startDate.year, plan.startDate.month + months, 0);
        return date.isAfter(end);
      case DurationType.fixedYears:
        final years = plan.durationValue ?? 1;
        if (plan.recurrenceType == RecurrenceType.yearly) {
          return index >= years;
        }
        final end = safeDate(plan.startDate.year + years, plan.startDate.month, plan.dueDay);
        return date.isAfter(end);
    }
  }

  DateTime? _latestPossibleDate(ObligationPlan plan) {
    switch (plan.durationType) {
      case DurationType.untilClosed:
        return null;
      case DurationType.untilDate:
        return plan.endDate?.dateOnly;
      case DurationType.fixedMonths:
        final months = plan.durationValue ?? 1;
        final m = DateTime(plan.startDate.year, plan.startDate.month + months - 1, 1);
        return safeDate(m.year, m.month, plan.dueDay);
      case DurationType.fixedYears:
        final years = plan.durationValue ?? 1;
        return safeDate(
          plan.startDate.year + years - 1,
          plan.startDate.month,
          plan.dueDay,
        );
    }
  }
}
