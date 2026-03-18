import 'package:flutter/material.dart';

import '../../core/design/tokens.dart';
import '../../core/widgets/empty_state_card.dart';
import '../../core/widgets/money_text.dart';
import '../../core/widgets/section_title.dart';
import '../../core/widgets/soft_card.dart';
import '../../domain/models/models.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({
    super.key,
    required this.summary,
    required this.currency,
    required this.overdueCount,
    required this.dueToday,
    required this.upcomingWeek,
    required this.recentPayments,
    required this.onQuickAdd,
    required this.onOpenItem,
  });

  final SalarySummary summary;
  final String currency;
  final int overdueCount;
  final List<ObligationBundle> dueToday;
  final List<ObligationBundle> upcomingWeek;
  final List<PaymentRecord> recentPayments;
  final VoidCallback onQuickAdd;
  final void Function(String planId) onOpenItem;

  @override
  Widget build(BuildContext context) {
    final accent = context.accentColors;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        AppSpace.md,
        AppSpace.sm,
        AppSpace.md,
        AppSpace.xxl,
      ),
      children: [
        _hero(context),
        const SizedBox(height: AppSpace.md),
        Row(
          children: [
            Expanded(
              child: _signalTile(
                context,
                label: 'Due today',
                value: dueToday.length.toString(),
                tone: accent.primary,
              ),
            ),
            const SizedBox(width: AppSpace.sm),
            Expanded(
              child: _signalTile(
                context,
                label: 'Overdue',
                value: overdueCount.toString(),
                tone: AppPalette.danger,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpace.lg),
        const SectionTitle(
          'This week',
          subtitle: 'Upcoming items that need attention soon.',
        ),
        const SizedBox(height: AppSpace.sm),
        if (upcomingWeek.isEmpty)
          const EmptyStateCard(
            title: 'Nothing pressing',
            subtitle: 'No upcoming obligations for the next seven days.',
            icon: Icons.event_available_rounded,
          )
        else
          ...upcomingWeek.take(4).map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpace.sm),
            child: _AgendaCard(
                  title: item.plan.title,
                  subtitle: item.plan.category,
                  amountCents: item.plan.amountCents,
                  currency: currency,
                  dueDate: item.nextOccurrence?.dueDate,
                  onTap: () => onOpenItem(item.plan.id),
                  accent: accent.primary,
                ),
              ),
              ),
        const SizedBox(height: AppSpace.lg),
        const SectionTitle(
          'Recent payments',
          subtitle: 'Latest paid activity and cash movement.',
        ),
        const SizedBox(height: AppSpace.sm),
        if (recentPayments.isEmpty)
          const EmptyStateCard(
            title: 'No payments yet',
            subtitle: 'Your payment log will appear here once you start marking items paid.',
            icon: Icons.receipt_long_outlined,
          )
        else
          SoftCard(
            child: Column(
              children: [
                for (final payment in recentPayments.take(4))
                  _HistoryRow(
                    title: payment.note.isEmpty ? 'Payment recorded' : payment.note,
                    subtitle:
                        '${payment.paidAt.day}/${payment.paidAt.month}/${payment.paidAt.year}',
                    amount: MoneyText(
                      payment.amountCents,
                      currency: currency,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _hero(BuildContext context) {
    final negative = summary.remainingCents < 0;
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppPalette.surfaceRaised, AppPalette.surface],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: AppPalette.borderStrong),
        boxShadow: AppShadows.soft,
      ),
      padding: const EdgeInsets.all(AppSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Monthly view',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpace.xs),
          Text(
            'Remaining balance',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppSpace.sm),
          MoneyText(
            summary.remainingCents,
            currency: currency,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: negative ? AppPalette.danger : AppPalette.textPrimary,
                ),
          ),
          const SizedBox(height: AppSpace.md),
          Row(
            children: [
              Expanded(
                child: _heroStat(
                  context,
                  'Salary',
                  MoneyText(
                    summary.salaryAmountCents,
                    currency: currency,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ),
              const SizedBox(width: AppSpace.sm),
              Expanded(
                child: _heroStat(
                  context,
                  'Paid',
                  MoneyText(
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
                child: _heroStat(
                  context,
                  'Upcoming',
                  MoneyText(
                    summary.upcomingCents,
                    currency: currency,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ),
              const SizedBox(width: AppSpace.sm),
              Expanded(
                child: _heroStat(
                  context,
                  'Projected',
                  MoneyText(
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
    );
  }

  Widget _heroStat(BuildContext context, String label, Widget value) {
    return Container(
      padding: const EdgeInsets.all(AppSpace.md),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.035),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: AppSpace.xs),
          value,
        ],
      ),
    );
  }

  Widget _signalTile(
    BuildContext context, {
    required String label,
    required String value,
    required Color tone,
  }) {
    return SoftCard(
      backgroundColor: AppPalette.surfaceRaised,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: AppSpace.xs),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: tone,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }

}

class _AgendaCard extends StatelessWidget {
  const _AgendaCard({
    required this.title,
    required this.subtitle,
    required this.amountCents,
    required this.currency,
    required this.dueDate,
    required this.onTap,
    required this.accent,
  });

  final String title;
  final String subtitle;
  final int amountCents;
  final String currency;
  final DateTime? dueDate;
  final VoidCallback onTap;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppPalette.surfaceRaised,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(Icons.schedule_rounded, color: accent),
          ),
          const SizedBox(width: AppSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: AppSpace.xxs),
                Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          const SizedBox(width: AppSpace.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              MoneyText(
                amountCents,
                currency: currency,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpace.xxs),
              Text(
                dueDate == null
                    ? 'No date'
                    : '${dueDate!.day}/${dueDate!.month}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({
    required this.title,
    required this.subtitle,
    required this.amount,
  });

  final String title;
  final String subtitle;
  final Widget amount;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpace.sm),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: AppSpace.xxs),
                Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          amount,
        ],
      ),
    );
  }
}
