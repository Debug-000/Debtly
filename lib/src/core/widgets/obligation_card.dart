import 'package:flutter/material.dart';

import '../../domain/models/models.dart';
import '../design/tokens.dart';
import '../utils/currency.dart';
import 'status_dot.dart';
import 'soft_card.dart';

class ObligationCard extends StatelessWidget {
  const ObligationCard({
    super.key,
    required this.bundle,
    required this.currency,
    required this.onTap,
    this.compact = false,
  });

  final ObligationBundle bundle;
  final String currency;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final accent = context.accentColors;
    final due = bundle.nextOccurrence;
    final now = DateTime.now();
    final isOverdue = due != null &&
        due.dueDate.isBefore(DateTime(now.year, now.month, now.day));

    final (status, color) = switch (due?.status) {
      OccurrenceStatus.overdue => ('Overdue', AppPalette.danger),
      OccurrenceStatus.paid => ('Paid', AppPalette.success),
      _ when bundle.isCompleted => ('Done', AppPalette.success),
      _ when due != null && due.dueDate.isSameDay(now) => ('Today', AppPalette.warning),
      _ => ('Active', accent.primary),
    };

    final repeat = switch (bundle.plan.recurrenceType) {
      RecurrenceType.monthly => 'Monthly',
      RecurrenceType.yearly => 'Yearly',
      RecurrenceType.oneTime => 'One time',
      RecurrenceType.customDays => 'Custom',
    };

    return SoftCard(
      onTap: onTap,
      padding: EdgeInsets.all(compact ? 14 : 16),
      backgroundColor: isOverdue
          ? AppPalette.surfaceRaised
          : compact
              ? AppPalette.surface
              : AppPalette.surfaceRaised,
      borderColor: color.withValues(alpha: 0.18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bundle.plan.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppSpace.xxs),
                    Text(
                      bundle.plan.category,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpace.sm),
              StatusDot(color: color, label: status),
            ],
          ),
          const SizedBox(height: AppSpace.sm),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MiniPill(
                label: bundle.plan.kind.name,
                tone: color,
              ),
              _MiniPill(
                label: repeat,
                tone: accent.primary,
              ),
            ],
          ),
          SizedBox(height: compact ? AppSpace.sm : AppSpace.md),
          Row(
            children: [
              Expanded(
                child: _MetricLine(
                  label: 'Amount',
                  value: formatMoney(bundle.plan.amountCents, currency),
                ),
              ),
              Expanded(
                child: _MetricLine(
                  label: 'Next due',
                  value: due == null
                      ? 'None'
                      : '${due.dueDate.day}/${due.dueDate.month}/${due.dueDate.year}',
                  emphasis: isOverdue,
                ),
              ),
              Expanded(child: _MetricLine(label: 'Status', value: status)),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricLine extends StatelessWidget {
  const _MetricLine({
    required this.label,
    required this.value,
    this.emphasis = false,
  });

  final String label;
  final String value;
  final bool emphasis;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: AppSpace.xxs),
        Text(
          value,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: emphasis ? AppPalette.danger : AppPalette.textPrimary,
              ),
        ),
      ],
    );
  }
}

class _MiniPill extends StatelessWidget {
  const _MiniPill({
    required this.label,
    required this.tone,
  });

  final String label;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: tone.withValues(alpha: 0.16)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: AppPalette.textPrimary,
            ),
      ),
    );
  }
}

extension on DateTime {
  bool isSameDay(DateTime other) {
    return year == other.year && month == other.month && day == other.day;
  }
}
