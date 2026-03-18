import '../models/models.dart';
import '../../core/utils/date_utils_ext.dart';

class SalaryService {
  const SalaryService();

  SalarySummary summarizeMonth({
    required DateTime month,
    required List<SalaryConfig> salaryConfigs,
    required List<ObligationPlan> plans,
    required List<Occurrence> occurrences,
  }) {
    final key = month.monthKey;
    final selected = _pickSalary(salaryConfigs, key);
    final salaryAmount = selected?.amountCents ?? 0;

    final planById = {for (final p in plans) p.id: p};

    var paid = 0;
    var upcoming = 0;
    for (final o in occurrences) {
      if (o.dueDate.year != month.year || o.dueDate.month != month.month) continue;
      final plan = planById[o.planId];
      if (plan == null || !plan.affectsSalary) continue;

      paid += o.paidAmountCents;
      if (o.status != OccurrenceStatus.paid) {
        upcoming += o.remainingCents;
      }
    }

    return SalarySummary(
      salaryAmountCents: salaryAmount,
      paidCents: paid,
      upcomingCents: upcoming,
    );
  }

  SalaryConfig? _pickSalary(List<SalaryConfig> configs, String monthKey) {
    SalaryConfig? fallback;
    for (final config in configs) {
      if (config.monthKey == 'default') fallback = config;
      if (config.monthKey == monthKey) return config;
    }
    return fallback;
  }
}
