import '../../domain/models/models.dart';

abstract class FinanceRepository {
  Future<void> seedIfEmpty();
  Future<void> purgeExpiredPlans();

  Future<List<ObligationPlan>> getPlans({bool includeArchived = false});
  Future<ObligationPlan?> getPlan(String planId);
  Future<void> upsertPlan(ObligationPlan plan);
  Future<void> deletePlan(String planId, {bool permanent = false});
  Future<void> closePlan(String planId);

  Future<List<ReminderConfig>> getRemindersForPlan(String planId);
  Future<void> replaceReminders(String planId, List<ReminderConfig> reminders);

  Future<List<Occurrence>> getOccurrences({String? planId});
  Future<void> upsertOccurrence(Occurrence occurrence);
  Future<void> ensureOccurrencesForPlan(String planId, {int horizonDays = 420});

  Future<void> addPayment(PaymentRecord payment);
  Future<List<PaymentRecord>> getPayments({String? planId, int limit = 200});
  Future<void> deletePayment(String paymentId);

  Future<List<SalaryConfig>> getSalaryConfigs();
  Future<void> upsertSalaryConfig(SalaryConfig config);

  Future<AppSettings> getSettings();
  Future<void> saveSettings(AppSettings settings);
  Future<void> clearAllData();
}
