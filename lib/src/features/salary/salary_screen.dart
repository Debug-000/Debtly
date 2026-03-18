import 'package:flutter/material.dart';

import '../../core/design/tokens.dart';
import '../../core/widgets/empty_state_card.dart';
import '../../core/utils/currency.dart';
import '../../core/widgets/money_text.dart';
import '../../core/widgets/section_title.dart';
import '../../core/widgets/soft_card.dart';
import '../../domain/models/models.dart';

class SalaryScreen extends StatelessWidget {
  const SalaryScreen({
    super.key,
    required this.month,
    required this.summary,
    required this.currency,
    required this.config,
    required this.onEditSalary,
    required this.monthlyHistory,
  });

  final DateTime month;
  final SalarySummary summary;
  final String currency;
  final SalaryConfig? config;
  final void Function(int amountCents, int salaryDay, String monthKey) onEditSalary;
  final List<(String key, SalarySummary summary)> monthlyHistory;

  @override
  Widget build(BuildContext context) {
    final accent = context.accentColors;
    final max = summary.salaryAmountCents <= 0 ? 1 : summary.salaryAmountCents;
    final paidRatio = (summary.paidCents / max).clamp(0.0, 1.0);
    final projectedRatio =
        ((summary.paidCents + summary.upcomingCents) / max).clamp(0.0, 1.0);

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        AppSpace.md,
        AppSpace.sm,
        AppSpace.md,
        AppSpace.xxl,
      ),
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpace.lg),
          decoration: BoxDecoration(
            color: AppPalette.surfaceRaised,
            borderRadius: BorderRadius.circular(AppRadius.xl),
            border: Border.all(color: AppPalette.borderStrong),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Monthly balance',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  IconButton(
                    onPressed: () => _editSalary(context),
                    icon: const Icon(Icons.edit_rounded),
                  ),
                ],
              ),
              const SizedBox(height: AppSpace.xs),
              MoneyText(
                summary.remainingCents,
                currency: currency,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: summary.remainingCents < 0
                          ? AppPalette.danger
                          : AppPalette.textPrimary,
                    ),
              ),
              const SizedBox(height: AppSpace.md),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _BalanceMeter(
                    accent: accent.primary,
                    paidRatio: paidRatio,
                    projectedRatio: projectedRatio,
                    remainingCents: summary.remainingCents,
                    currency: currency,
                  ),
                ],
              ),
              const SizedBox(height: AppSpace.md),
              Row(
                children: [
                  Expanded(
                    child: _Figure(
                      label: 'Salary',
                      tone: AppPalette.info,
                      value: MoneyText(
                        summary.salaryAmountCents,
                        currency: currency,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpace.sm),
                  Expanded(
                    child: _Figure(
                      label: 'Paid',
                      tone: AppPalette.success,
                      value: MoneyText(
                        summary.paidCents,
                        currency: currency,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpace.sm),
              Row(
                children: [
                  Expanded(
                    child: _Figure(
                      label: 'Upcoming',
                      tone: AppPalette.warning,
                      value: MoneyText(
                        summary.upcomingCents,
                        currency: currency,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpace.sm),
                  Expanded(
                    child: _Figure(
                      label: 'Projected',
                      tone: summary.projectedRemainingCents < 0
                          ? AppPalette.danger
                          : accent.primary,
                      value: MoneyText(
                        summary.projectedRemainingCents,
                        currency: currency,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: summary.projectedRemainingCents < 0
                                  ? AppPalette.danger
                                  : AppPalette.textPrimary,
                            ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpace.lg),
        const SectionTitle(
          'Monthly history',
          subtitle: 'A compact view of recent salary months and balance outcomes.',
        ),
        const SizedBox(height: AppSpace.sm),
        if (monthlyHistory.isNotEmpty) ...[
          _TrendStrip(history: monthlyHistory.take(6).toList()),
          const SizedBox(height: AppSpace.md),
        ],
        if (monthlyHistory.isEmpty)
          const EmptyStateCard(
            title: 'No salary history yet',
            subtitle: 'Your saved monthly salary snapshots will show up here.',
            icon: Icons.account_balance_wallet_outlined,
          )
        else
          ...monthlyHistory.take(6).map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpace.sm),
                  child: SoftCard(
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(entry.$1,
                                  style: Theme.of(context).textTheme.titleMedium),
                              const SizedBox(height: AppSpace.xxs),
                              Text(
                                'Paid ${formatMoney(entry.$2.paidCents, currency)}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        MoneyText(
                          entry.$2.remainingCents,
                          currency: currency,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
      ],
    );
  }

  Future<void> _editSalary(BuildContext context) async {
    final amountController = TextEditingController(
      text: ((config?.amountCents ?? summary.salaryAmountCents) / 100)
          .toStringAsFixed(2),
    );
    var day = config?.salaryDay ?? 1;

    await showDialog<void>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Salary setup'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: amountController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Amount'),
              ),
              const SizedBox(height: AppSpace.sm),
              Container(
                padding: const EdgeInsets.all(AppSpace.md),
                decoration: BoxDecoration(
                  color: AppPalette.surfaceRaised,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Salary day',
                        style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: AppSpace.xs),
                    Text('$day',
                        style: Theme.of(context).textTheme.headlineSmall),
                    Slider(
                      value: day.toDouble(),
                      min: 1,
                      max: 28,
                      divisions: 27,
                      label: '$day',
                      onChanged: (v) => setState(() => day = v.round()),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                onEditSalary(
                  parseToCents(amountController.text),
                  day,
                  '${month.year}-${month.month.toString().padLeft(2, '0')}',
                );
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Figure extends StatelessWidget {
  const _Figure({
    required this.label,
    required this.value,
    required this.tone,
  });

  final String label;
  final Widget value;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 96),
      padding: const EdgeInsets.all(AppSpace.sm),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.035),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: tone.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: tone,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: AppSpace.xs),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.xs),
          value,
        ],
      ),
    );
  }
}

class _BalanceMeter extends StatelessWidget {
  const _BalanceMeter({
    required this.accent,
    required this.paidRatio,
    required this.projectedRatio,
    required this.remainingCents,
    required this.currency,
  });

  final Color accent;
  final double paidRatio;
  final double projectedRatio;
  final int remainingCents;
  final String currency;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 176,
      height: 176,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 176,
            height: 176,
            child: CircularProgressIndicator(
              value: 1,
              strokeWidth: 14,
              color: AppPalette.surfaceMuted,
              backgroundColor: AppPalette.surfaceMuted,
            ),
          ),
          SizedBox(
            width: 176,
            height: 176,
            child: CircularProgressIndicator(
              value: projectedRatio,
              strokeWidth: 14,
              color: AppPalette.warning.withValues(alpha: 0.5),
              backgroundColor: Colors.transparent,
            ),
          ),
          SizedBox(
            width: 176,
            height: 176,
            child: CircularProgressIndicator(
              value: paidRatio,
              strokeWidth: 14,
              color: accent,
              backgroundColor: Colors.transparent,
            ),
          ),
          Container(
            width: 126,
            height: 126,
            decoration: BoxDecoration(
              color: AppPalette.surface,
              shape: BoxShape.circle,
              border: Border.all(color: AppPalette.border),
            ),
            padding: const EdgeInsets.all(AppSpace.sm),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Remaining', style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: AppSpace.xxs),
                MoneyText(
                  remainingCents,
                  currency: currency,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: remainingCents < 0
                            ? AppPalette.danger
                            : AppPalette.textPrimary,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TrendStrip extends StatelessWidget {
  const _TrendStrip({
    required this.history,
  });

  final List<(String key, SalarySummary summary)> history;

  @override
  Widget build(BuildContext context) {
    final accent = context.accentColors;
    final values = history.map((e) => e.$2.remainingCents.abs()).toList(growable: false);
    final max = values.isEmpty ? 1 : values.reduce((a, b) => a > b ? a : b).clamp(1, 1 << 30);

    return SoftCard(
      backgroundColor: AppPalette.surfaceRaised,
      child: SizedBox(
        height: 104,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (final entry in history)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 260),
                            curve: Curves.easeOutCubic,
                            height: 18 +
                                ((entry.$2.remainingCents.abs() / max) * 42).toDouble(),
                            decoration: BoxDecoration(
                              color: entry.$2.remainingCents < 0
                                  ? AppPalette.danger.withValues(alpha: 0.82)
                                  : accent.primary.withValues(alpha: 0.82),
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpace.xs),
                      Text(
                        entry.$1.split('-').last,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
