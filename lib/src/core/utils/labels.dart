import '../../domain/models/models.dart';

String recurrenceLabel(RecurrenceType type) {
  switch (type) {
    case RecurrenceType.oneTime:
      return 'One time';
    case RecurrenceType.monthly:
      return 'Monthly';
    case RecurrenceType.yearly:
      return 'Yearly';
    case RecurrenceType.customDays:
      return 'Custom';
  }
}

String durationLabel(DurationType type) {
  switch (type) {
    case DurationType.fixedMonths:
      return 'Fixed months';
    case DurationType.fixedYears:
      return 'Fixed years';
    case DurationType.untilClosed:
      return 'Until closed';
    case DurationType.untilDate:
      return 'Until end date';
  }
}

String reminderLabel(ReminderType type) {
  switch (type) {
    case ReminderType.dueDate:
      return 'On due date';
    case ReminderType.oneDayBefore:
      return '1 day before';
    case ReminderType.firstDayOfMonth:
      return 'First day of month';
    case ReminderType.salaryDay:
      return 'On salary day';
    case ReminderType.customDaysBefore:
      return 'Custom days before';
  }
}
