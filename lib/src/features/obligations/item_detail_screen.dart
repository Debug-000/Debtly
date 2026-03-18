import 'package:flutter/material.dart';

import '../../core/design/tokens.dart';
import '../../core/widgets/empty_state_card.dart';
import '../../core/utils/currency.dart';
import '../../core/widgets/money_text.dart';
import '../../core/widgets/section_title.dart';
import '../../core/widgets/soft_card.dart';
import '../../domain/models/models.dart';

class ItemDetailScreen extends StatelessWidget {
  const ItemDetailScreen({
    super.key,
    required this.plan,
    required this.occurrences,
    required this.payments,
    required this.reminders,
    required this.currency,
    required this.onAddPayment,
    required this.onEdit,
    required this.onClose,
  });

  final ObligationPlan plan;
  final List<Occurrence> occurrences;
  final List<PaymentRecord> payments;
  final List<ReminderConfig> reminders;
  final String currency;
  final void Function(Occurrence occurrence, int cents) onAddPayment;
  final VoidCallback onEdit;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final accent = context.accentColors;
    final sorted = [...occurrences]..sort((a, b) => a.dueDate.compareTo(b.dueDate));
    final open = sorted.where((e) => e.status != OccurrenceStatus.paid).toList();
    final next = open.isEmpty ? null : open.first;
    final statusTone = next == null
        ? AppPalette.success
        : next.status == OccurrenceStatus.overdue
            ? AppPalette.danger
            : next.dueDate.year == DateTime.now().year &&
                    next.dueDate.month == DateTime.now().month &&
                    next.dueDate.day == DateTime.now().day
                ? AppPalette.warning
                : accent.primary;
    final statusLabel = next == null
        ? 'Completed'
        : next.status == OccurrenceStatus.overdue
            ? 'Overdue'
            : next.dueDate.year == DateTime.now().year &&
                    next.dueDate.month == DateTime.now().month &&
                    next.dueDate.day == DateTime.now().day
                ? 'Due today'
                : 'Active';

    return Scaffold(
      appBar: AppBar(
        title: Text(plan.title),
        actions: [IconButton(onPressed: onEdit, icon: const Icon(Icons.edit_rounded))],
      ),
      body: ListView(
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
              border: Border.all(color: statusTone.withValues(alpha: 0.16)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        plan.category,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                    _HeroBadge(label: statusLabel, tone: statusTone),
                  ],
                ),
                const SizedBox(height: AppSpace.xs),
                MoneyText(
                  plan.amountCents,
                  currency: currency,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: AppSpace.md),
                Row(
                  children: [
                    Expanded(
                      child: _MetaBlock(
                        label: 'Next due',
                        value: next == null
                            ? 'No open cycle'
                            : '${next.dueDate.day}/${next.dueDate.month}/${next.dueDate.year}',
                      ),
                    ),
                    const SizedBox(width: AppSpace.sm),
                    Expanded(
                      child: _MetaBlock(
                        label: 'Repeats',
                        value: plan.recurrenceType.name,
                      ),
                    ),
                  ],
                ),
                if (plan.notes.isNotEmpty) ...[
                  const SizedBox(height: AppSpace.md),
                  Text(plan.notes, style: Theme.of(context).textTheme.bodyMedium),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpace.lg),
          const SectionTitle(
            'Open cycles',
            subtitle: 'Upcoming or overdue cycles waiting for payment.',
          ),
          const SizedBox(height: AppSpace.sm),
          if (open.isEmpty)
            const EmptyStateCard(
              title: 'No open cycles',
              subtitle: 'Everything here is paid or completed.',
              icon: Icons.check_circle_outline_rounded,
            )
          else
            ...open.take(6).map(
              (occurrence) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpace.sm),
                  child: SoftCard(
                    borderColor: occurrence.status == OccurrenceStatus.overdue
                        ? AppPalette.danger.withValues(alpha: 0.18)
                        : accent.primary.withValues(alpha: 0.12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${occurrence.dueDate.day}/${occurrence.dueDate.month}/${occurrence.dueDate.year}',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: AppSpace.xxs),
                            Text(
                              '${formatMoney(occurrence.paidAmountCents, currency)} paid • ${formatMoney(occurrence.remainingCents, currency)} left',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            const SizedBox(height: AppSpace.xs),
                            _HeroBadge(
                              label: occurrence.status == OccurrenceStatus.overdue
                                  ? 'Overdue'
                                  : 'Open',
                              tone: occurrence.status == OccurrenceStatus.overdue
                                  ? AppPalette.danger
                                  : accent.primary,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpace.sm),
                      FilledButton.tonal(
                        onPressed: () async {
                          final amount = await _askAmount(context, occurrence.remainingCents);
                          if (amount != null && amount > 0) {
                            onAddPayment(occurrence, amount);
                          }
                        },
                        child: const Text('Pay'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          const SizedBox(height: AppSpace.lg),
          SectionTitle(
            'Payment log',
            subtitle: payments.isEmpty
                ? 'No payment history yet.'
                : '${payments.length} payment records saved locally.',
          ),
          const SizedBox(height: AppSpace.sm),
          if (payments.isEmpty)
            const EmptyStateCard(
              title: 'Nothing recorded',
              subtitle: 'Every payment you add will appear here.',
              icon: Icons.history_toggle_off_rounded,
            )
          else
            SoftCard(
              child: Column(
                children: payments.map((payment) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: AppSpace.sm),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                payment.note.isEmpty ? 'Payment' : payment.note,
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                              const SizedBox(height: AppSpace.xxs),
                              Text(
                                '${payment.paidAt.day}/${payment.paidAt.month}/${payment.paidAt.year}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        MoneyText(payment.amountCents, currency: currency),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          const SizedBox(height: AppSpace.lg),
          SoftCard(
            backgroundColor: AppPalette.surfaceRaised,
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                OutlinedButton(onPressed: onClose, child: const Text('Close')),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<int?> _askAmount(BuildContext context, int defaultCents) async {
    final controller = TextEditingController(
      text: (defaultCents / 100).toStringAsFixed(2),
    );
    return showDialog<int>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Payment amount'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(labelText: 'Amount'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, parseToCents(controller.text)),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

class _HeroBadge extends StatelessWidget {
  const _HeroBadge({
    required this.label,
    required this.tone,
  });

  final String label;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: tone.withValues(alpha: 0.18)),
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

class _MetaBlock extends StatelessWidget {
  const _MetaBlock({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpace.md),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.035),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: AppSpace.xs),
          Text(value, style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }
}
