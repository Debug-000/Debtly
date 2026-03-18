import 'package:intl/intl.dart';

extension DateOnly on DateTime {
  DateTime get dateOnly => DateTime(year, month, day);

  bool isSameDate(DateTime other) =>
      year == other.year && month == other.month && day == other.day;

  String get monthKey => DateFormat('yyyy-MM').format(this);
}

DateTime safeDate(int year, int month, int day) {
  final last = DateTime(year, month + 1, 0).day;
  return DateTime(year, month, day.clamp(1, last));
}
