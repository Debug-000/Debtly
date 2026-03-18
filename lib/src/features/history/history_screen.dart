import 'package:flutter/material.dart';

import '../../core/widgets/money_text.dart';
import '../../domain/models/models.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({
    super.key,
    required this.bundles,
    required this.payments,
    required this.currency,
    required this.onOpen,
  });

  final List<ObligationBundle> bundles;
  final List<PaymentRecord> payments;
  final String currency;
  final void Function(String planId) onOpen;

  @override
  Widget build(BuildContext context) {
    final completed = bundles.where((b) => b.isCompleted || b.plan.manualClosed).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Completed / Closed', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        if (completed.isEmpty)
          const Text('No completed items yet')
        else
          ...completed.map(
            (bundle) => ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(bundle.plan.title),
              subtitle: Text(bundle.plan.category),
              trailing: const Icon(Icons.arrow_forward_ios, size: 14),
              onTap: () => onOpen(bundle.plan.id),
            ),
          ),
        const SizedBox(height: 16),
        Text('Payment history', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        if (payments.isEmpty)
          const Text('No payment records')
        else
          ...payments.map(
            (p) => ListTile(
              contentPadding: EdgeInsets.zero,
              title: MoneyText(p.amountCents, currency: currency),
              subtitle: Text(p.note.isEmpty ? 'Payment' : p.note),
              trailing: Text('${p.paidAt.day}/${p.paidAt.month}/${p.paidAt.year}'),
            ),
          ),
      ],
    );
  }
}
