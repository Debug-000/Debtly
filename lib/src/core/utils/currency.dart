import 'package:intl/intl.dart';

String formatMoney(int cents, String currencyCode) {
  final value = cents / 100.0;
  return NumberFormat.simpleCurrency(name: currencyCode).format(value);
}

int parseToCents(String input) {
  final cleaned = input.replaceAll(RegExp(r'[^0-9.]'), '');
  if (cleaned.isEmpty) return 0;
  final value = double.tryParse(cleaned) ?? 0;
  return (value * 100).round();
}
