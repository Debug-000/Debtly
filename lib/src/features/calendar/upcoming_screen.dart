import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../core/utils/date_utils_ext.dart';
import '../../domain/models/models.dart';

class UpcomingScreen extends StatefulWidget {
  const UpcomingScreen({
    super.key,
    required this.occurrences,
    required this.plansById,
    required this.onOpen,
  });

  final List<Occurrence> occurrences;
  final Map<String, ObligationPlan> plansById;
  final void Function(String planId) onOpen;

  @override
  State<UpcomingScreen> createState() => _UpcomingScreenState();
}

class _UpcomingScreenState extends State<UpcomingScreen> {
  DateTime _focused = DateTime.now();
  DateTime? _selected;

  @override
  Widget build(BuildContext context) {
    final selected = _selected ?? DateTime.now();
    final selectedItems = widget.occurrences
        .where((o) => o.dueDate.isSameDate(selected))
        .toList(growable: false);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        TableCalendar<Occurrence>(
          firstDay: DateTime(2020),
          lastDay: DateTime(2100),
          focusedDay: _focused,
          selectedDayPredicate: (day) => _selected?.isSameDate(day) ?? false,
          eventLoader: (day) => widget.occurrences
              .where((o) => o.dueDate.isSameDate(day))
              .toList(growable: false),
          onDaySelected: (selectedDay, focusedDay) {
            setState(() {
              _selected = selectedDay;
              _focused = focusedDay;
            });
          },
        ),
        const SizedBox(height: 16),
        Text('Items on ${selected.day}/${selected.month}/${selected.year}'),
        const SizedBox(height: 8),
        if (selectedItems.isEmpty)
          const Text('No obligations on this date')
        else
          ...selectedItems.map(
            (o) {
              final plan = widget.plansById[o.planId];
              return ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(plan?.title ?? 'Unknown'),
                subtitle: Text(plan?.category ?? ''),
                trailing: o.status == OccurrenceStatus.overdue
                    ? const Icon(Icons.warning_amber, color: Colors.orange)
                    : const Icon(Icons.arrow_forward_ios, size: 14),
                onTap: () => widget.onOpen(o.planId),
              );
            },
          ),
      ],
    );
  }
}
