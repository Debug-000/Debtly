import 'package:flutter/material.dart';

enum ObligationKind { debt, obligation, expense }

enum RecurrenceType { oneTime, monthly, yearly, customDays }

enum DurationType { fixedMonths, fixedYears, untilClosed, untilDate }

enum ReminderType {
  dueDate,
  oneDayBefore,
  firstDayOfMonth,
  salaryDay,
  customDaysBefore,
}

enum CustomIntervalUnit { days, months }

enum PlanStatus { active, completed, closed }

enum OccurrenceStatus { due, paid, overdue }

enum ItemFilter { all, dueToday, upcoming, overdue, completed, monthly, yearly }

enum AccentTheme { ocean, violet, ruby, emerald }

class ObligationPlan {
  const ObligationPlan({
    required this.id,
    required this.title,
    required this.notes,
    required this.category,
    required this.amountCents,
    required this.startDate,
    required this.dueDay,
    required this.kind,
    required this.recurrenceType,
    this.customIntervalDays,
    this.customIntervalMonths,
    required this.durationType,
    this.durationValue,
    this.endDate,
    required this.affectsSalary,
    required this.manualClosed,
    required this.archived,
    this.retentionUntil,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String title;
  final String notes;
  final String category;
  final int amountCents;
  final DateTime startDate;
  final int dueDay;
  final ObligationKind kind;
  final RecurrenceType recurrenceType;
  final int? customIntervalDays;
  final int? customIntervalMonths;
  final DurationType durationType;
  final int? durationValue;
  final DateTime? endDate;
  final bool affectsSalary;
  final bool manualClosed;
  final bool archived;
  final DateTime? retentionUntil;
  final DateTime createdAt;
  final DateTime updatedAt;

  PlanStatus get planStatus {
    if (manualClosed) return PlanStatus.closed;
    return PlanStatus.active;
  }

  ObligationPlan copyWith({
    String? id,
    String? title,
    String? notes,
    String? category,
    int? amountCents,
    DateTime? startDate,
    int? dueDay,
    ObligationKind? kind,
    RecurrenceType? recurrenceType,
    int? customIntervalDays,
    int? customIntervalMonths,
    DurationType? durationType,
    int? durationValue,
    DateTime? endDate,
    bool? affectsSalary,
    bool? manualClosed,
    bool? archived,
    DateTime? retentionUntil,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ObligationPlan(
      id: id ?? this.id,
      title: title ?? this.title,
      notes: notes ?? this.notes,
      category: category ?? this.category,
      amountCents: amountCents ?? this.amountCents,
      startDate: startDate ?? this.startDate,
      dueDay: dueDay ?? this.dueDay,
      kind: kind ?? this.kind,
      recurrenceType: recurrenceType ?? this.recurrenceType,
      customIntervalDays: customIntervalDays ?? this.customIntervalDays,
      customIntervalMonths: customIntervalMonths ?? this.customIntervalMonths,
      durationType: durationType ?? this.durationType,
      durationValue: durationValue ?? this.durationValue,
      endDate: endDate ?? this.endDate,
      affectsSalary: affectsSalary ?? this.affectsSalary,
      manualClosed: manualClosed ?? this.manualClosed,
      archived: archived ?? this.archived,
      retentionUntil: retentionUntil ?? this.retentionUntil,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'title': title,
      'notes': notes,
      'category': category,
      'amount_cents': amountCents,
      'start_date': startDate.toIso8601String(),
      'due_day': dueDay,
      'kind': kind.name,
      'recurrence_type': recurrenceType.name,
      'custom_interval_days': customIntervalDays,
      'custom_interval_months': customIntervalMonths,
      'duration_type': durationType.name,
      'duration_value': durationValue,
      'end_date': endDate?.toIso8601String(),
      'affects_salary': affectsSalary ? 1 : 0,
      'manual_closed': manualClosed ? 1 : 0,
      'archived': archived ? 1 : 0,
      'retention_until': retentionUntil?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory ObligationPlan.fromMap(Map<String, Object?> map) {
    return ObligationPlan(
      id: map['id']! as String,
      title: map['title']! as String,
      notes: map['notes']! as String,
      category: map['category']! as String,
      amountCents: map['amount_cents']! as int,
      startDate: DateTime.parse(map['start_date']! as String),
      dueDay: map['due_day']! as int,
      kind: ObligationKind.values.byName(map['kind']! as String),
      recurrenceType:
          RecurrenceType.values.byName(map['recurrence_type']! as String),
      customIntervalDays: map['custom_interval_days'] as int?,
      customIntervalMonths: map['custom_interval_months'] as int?,
      durationType: DurationType.values.byName(map['duration_type']! as String),
      durationValue: map['duration_value'] as int?,
      endDate: map['end_date'] == null
          ? null
          : DateTime.parse(map['end_date']! as String),
      affectsSalary: (map['affects_salary']! as int) == 1,
      manualClosed: (map['manual_closed']! as int) == 1,
      archived: (map['archived']! as int) == 1,
      retentionUntil: map['retention_until'] == null
          ? null
          : DateTime.parse(map['retention_until']! as String),
      createdAt: DateTime.parse(map['created_at']! as String),
      updatedAt: DateTime.parse(map['updated_at']! as String),
    );
  }
}

class ReminderConfig {
  const ReminderConfig({
    required this.id,
    required this.planId,
    required this.type,
    this.offsetDays,
    this.hour = 9,
    this.minute = 0,
  });

  final String id;
  final String planId;
  final ReminderType type;
  final int? offsetDays;
  final int hour;
  final int minute;

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'plan_id': planId,
      'type': type.name,
      'offset_days': offsetDays,
      'hour': hour,
      'minute': minute,
    };
  }

  factory ReminderConfig.fromMap(Map<String, Object?> map) {
    return ReminderConfig(
      id: map['id']! as String,
      planId: map['plan_id']! as String,
      type: ReminderType.values.byName(map['type']! as String),
      offsetDays: map['offset_days'] as int?,
      hour: (map['hour'] as int?) ?? 9,
      minute: (map['minute'] as int?) ?? 0,
    );
  }
}

class Occurrence {
  const Occurrence({
    required this.id,
    required this.planId,
    required this.sequenceIndex,
    required this.dueDate,
    required this.amountCents,
    required this.paidAmountCents,
    required this.status,
  });

  final String id;
  final String planId;
  final int sequenceIndex;
  final DateTime dueDate;
  final int amountCents;
  final int paidAmountCents;
  final OccurrenceStatus status;

  int get remainingCents => amountCents - paidAmountCents;
  bool get isFullyPaid => remainingCents <= 0;

  Occurrence copyWith({
    int? paidAmountCents,
    OccurrenceStatus? status,
  }) {
    return Occurrence(
      id: id,
      planId: planId,
      sequenceIndex: sequenceIndex,
      dueDate: dueDate,
      amountCents: amountCents,
      paidAmountCents: paidAmountCents ?? this.paidAmountCents,
      status: status ?? this.status,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'plan_id': planId,
      'sequence_index': sequenceIndex,
      'due_date': dueDate.toIso8601String(),
      'amount_cents': amountCents,
      'paid_amount_cents': paidAmountCents,
      'status': status.name,
    };
  }

  factory Occurrence.fromMap(Map<String, Object?> map) {
    return Occurrence(
      id: map['id']! as String,
      planId: map['plan_id']! as String,
      sequenceIndex: map['sequence_index']! as int,
      dueDate: DateTime.parse(map['due_date']! as String),
      amountCents: map['amount_cents']! as int,
      paidAmountCents: map['paid_amount_cents']! as int,
      status: OccurrenceStatus.values.byName(map['status']! as String),
    );
  }
}

class PaymentRecord {
  const PaymentRecord({
    required this.id,
    required this.planId,
    required this.occurrenceId,
    required this.amountCents,
    required this.paidAt,
    required this.note,
  });

  final String id;
  final String planId;
  final String occurrenceId;
  final int amountCents;
  final DateTime paidAt;
  final String note;

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'plan_id': planId,
      'occurrence_id': occurrenceId,
      'amount_cents': amountCents,
      'paid_at': paidAt.toIso8601String(),
      'note': note,
    };
  }

  factory PaymentRecord.fromMap(Map<String, Object?> map) {
    return PaymentRecord(
      id: map['id']! as String,
      planId: map['plan_id']! as String,
      occurrenceId: map['occurrence_id']! as String,
      amountCents: map['amount_cents']! as int,
      paidAt: DateTime.parse(map['paid_at']! as String),
      note: map['note']! as String,
    );
  }
}

class SalaryConfig {
  const SalaryConfig({
    required this.id,
    required this.monthKey,
    required this.amountCents,
    required this.salaryDay,
  });

  final String id;
  final String monthKey;
  final int amountCents;
  final int salaryDay;

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'month_key': monthKey,
      'amount_cents': amountCents,
      'salary_day': salaryDay,
    };
  }

  factory SalaryConfig.fromMap(Map<String, Object?> map) {
    return SalaryConfig(
      id: map['id']! as String,
      monthKey: map['month_key']! as String,
      amountCents: map['amount_cents']! as int,
      salaryDay: map['salary_day']! as int,
    );
  }
}

class AppSettings {
  const AppSettings({
    required this.currencyCode,
    required this.themeMode,
    required this.notificationsEnabled,
    required this.accentTheme,
  });

  final String currencyCode;
  final ThemeMode themeMode;
  final bool notificationsEnabled;
  final AccentTheme accentTheme;

  AppSettings copyWith({
    String? currencyCode,
    ThemeMode? themeMode,
    bool? notificationsEnabled,
    AccentTheme? accentTheme,
  }) {
    return AppSettings(
      currencyCode: currencyCode ?? this.currencyCode,
      themeMode: themeMode ?? this.themeMode,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      accentTheme: accentTheme ?? this.accentTheme,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'currency_code': currencyCode,
      'theme_mode': themeMode.name,
      'notifications_enabled': notificationsEnabled ? 1 : 0,
      'accent_theme': accentTheme.name,
    };
  }

  factory AppSettings.fromMap(Map<String, Object?> map) {
    return AppSettings(
      currencyCode: map['currency_code']! as String,
      themeMode: ThemeMode.values.byName(map['theme_mode']! as String),
      notificationsEnabled: (map['notifications_enabled']! as int) == 1,
      accentTheme: AccentTheme.values.byName(
        (map['accent_theme'] as String?) ?? AccentTheme.ocean.name,
      ),
    );
  }

  static const defaults = AppSettings(
    currencyCode: 'EUR',
    themeMode: ThemeMode.system,
    notificationsEnabled: true,
    accentTheme: AccentTheme.ocean,
  );
}

class SalarySummary {
  const SalarySummary({
    required this.salaryAmountCents,
    required this.paidCents,
    required this.upcomingCents,
  });

  final int salaryAmountCents;
  final int paidCents;
  final int upcomingCents;

  int get remainingCents => salaryAmountCents - paidCents;
  int get projectedRemainingCents => salaryAmountCents - paidCents - upcomingCents;
}

class ObligationBundle {
  const ObligationBundle({
    required this.plan,
    required this.reminders,
    required this.nextOccurrence,
    required this.isCompleted,
  });

  final ObligationPlan plan;
  final List<ReminderConfig> reminders;
  final Occurrence? nextOccurrence;
  final bool isCompleted;
}
