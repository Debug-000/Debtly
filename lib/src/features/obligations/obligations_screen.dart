import 'package:flutter/material.dart';

import '../../core/design/tokens.dart';
import '../../core/widgets/empty_state_card.dart';
import '../../core/widgets/obligation_card.dart';
import '../../core/widgets/section_title.dart';
import '../../core/widgets/soft_card.dart';
import '../../domain/models/models.dart';

class ObligationsScreen extends StatefulWidget {
  const ObligationsScreen({
    super.key,
    required this.bundles,
    required this.currency,
    required this.onTap,
  });

  final List<ObligationBundle> bundles;
  final String currency;
  final void Function(String planId) onTap;

  @override
  State<ObligationsScreen> createState() => _ObligationsScreenState();
}

class _ObligationsScreenState extends State<ObligationsScreen> {
  ItemFilter _filter = ItemFilter.all;
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final filtered = widget.bundles.where((bundle) {
      final query = _query.trim().toLowerCase();
      final queryHit = query.isEmpty ||
          bundle.plan.title.toLowerCase().contains(query) ||
          bundle.plan.category.toLowerCase().contains(query);
      if (!queryHit) return false;

      final next = bundle.nextOccurrence;
      switch (_filter) {
        case ItemFilter.all:
          return true;
        case ItemFilter.dueToday:
          return next != null &&
              next.dueDate.year == now.year &&
              next.dueDate.month == now.month &&
              next.dueDate.day == now.day;
        case ItemFilter.upcoming:
          return next != null && next.dueDate.isAfter(today);
        case ItemFilter.overdue:
          return next != null && next.dueDate.isBefore(today);
        case ItemFilter.completed:
          return bundle.isCompleted;
        case ItemFilter.monthly:
          return bundle.plan.recurrenceType == RecurrenceType.monthly;
        case ItemFilter.yearly:
          return bundle.plan.recurrenceType == RecurrenceType.yearly;
      }
    }).toList()
      ..sort((a, b) {
        final ad = a.nextOccurrence?.dueDate;
        final bd = b.nextOccurrence?.dueDate;
        if (ad == null && bd == null) return 0;
        if (ad == null) return 1;
        if (bd == null) return -1;
        return ad.compareTo(bd);
      });

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        AppSpace.md,
        AppSpace.sm,
        AppSpace.md,
        AppSpace.xxl,
      ),
      children: [
        SoftCard(
          backgroundColor: AppPalette.surfaceRaised,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionTitle(
                'Plans',
                subtitle: 'All debts, bills, and recurring obligations.',
              ),
              const SizedBox(height: AppSpace.md),
              TextField(
                decoration: const InputDecoration(
                  hintText: 'Search titles or categories',
                  prefixIcon: Icon(Icons.search_rounded),
                ),
                onChanged: (v) => setState(() => _query = v),
              ),
              const SizedBox(height: AppSpace.sm),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _chip(ItemFilter.all, 'All'),
                    _chip(ItemFilter.dueToday, 'Today'),
                    _chip(ItemFilter.overdue, 'Overdue'),
                    _chip(ItemFilter.upcoming, 'Upcoming'),
                    _chip(ItemFilter.monthly, 'Monthly'),
                    _chip(ItemFilter.yearly, 'Yearly'),
                    _chip(ItemFilter.completed, 'Done'),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpace.sm),
        if (filtered.isEmpty)
          const EmptyStateCard(
            title: 'Nothing here yet',
            subtitle: 'Try a different filter or create a new plan.',
            icon: Icons.view_agenda_outlined,
          )
        else
          ...filtered.map(
            (bundle) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpace.xs),
              child: ObligationCard(
                bundle: bundle,
                currency: widget.currency,
                onTap: () => widget.onTap(bundle.plan.id),
              ),
            ),
          ),
      ],
    );
  }

  Widget _chip(ItemFilter value, String text) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(text),
        selected: _filter == value,
        onSelected: (_) => setState(() => _filter = value),
      ),
    );
  }
}
