import 'package:flutter/material.dart';

import '../utils/currency.dart';

class MoneyText extends StatelessWidget {
  const MoneyText(
    this.cents, {
    super.key,
    required this.currency,
    this.style,
    this.negativeColor,
  });

  final int cents;
  final String currency;
  final TextStyle? style;
  final Color? negativeColor;

  @override
  Widget build(BuildContext context) {
    final baseStyle = style ?? Theme.of(context).textTheme.titleMedium;
    final coloredStyle = cents < 0
        ? baseStyle?.copyWith(color: negativeColor ?? Theme.of(context).colorScheme.error)
        : baseStyle;
    return Text(formatMoney(cents, currency), style: coloredStyle);
  }
}
