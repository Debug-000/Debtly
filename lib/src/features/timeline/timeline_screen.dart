import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../core/design/tokens.dart';
import '../../core/widgets/empty_state_card.dart';
import '../../core/widgets/section_title.dart';
import '../../core/widgets/soft_card.dart';
import '../../domain/models/models.dart';

enum TimelineMode { upcoming, history }

class TimelineScreen extends StatefulWidget {
  const TimelineScreen({
    super.key,
    required this.occurrences,
    required this.payments,
    required this.plansById,
    required this.onOpen,
  });

  final List<Occurrence> occurrences;
  final List<PaymentRecord> payments;
  final Map<String, ObligationPlan> plansById;
  final void Function(String planId) onOpen;

  @override
  State<TimelineScreen> createState() => _TimelineScreenState();
}

class _TimelineScreenState extends State<TimelineScreen> {
  TimelineMode _mode = TimelineMode.upcoming;
  DateTime _focused = DateTime.now();
  DateTime? _selected;

  @override
  Widget build(BuildContext context) {
    final accent = context.accentColors;
    final selected = _selected ?? DateTime.now();
    final upcomingForSelected = widget.occurrences
        .where(
          (o) =>
              o.status != OccurrenceStatus.paid &&
              o.dueDate.year == selected.year &&
              o.dueDate.month == selected.month &&
              o.dueDate.day == selected.day,
        )
        .toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));

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
            children: [
              Row(
                children: [
                  Expanded(child: _modeChip(TimelineMode.upcoming, 'Agenda', accent)),
                  const SizedBox(width: AppSpace.sm),
                  Expanded(child: _modeChip(TimelineMode.history, 'History', accent)),
                ],
              ),
              if (_mode == TimelineMode.upcoming) ...[
                const SizedBox(height: AppSpace.md),
                TableCalendar<Occurrence>(
                  firstDay: DateTime(2020),
                  lastDay: DateTime(2100),
                  focusedDay: _focused,
                  selectedDayPredicate: (day) =>
                      _selected != null &&
                      _selected!.year == day.year &&
                      _selected!.month == day.month &&
                      _selected!.day == day.day,
                  eventLoader: (day) => widget.occurrences
                      .where(
                        (o) =>
                            o.status != OccurrenceStatus.paid &&
                            o.dueDate.year == day.year &&
                            o.dueDate.month == day.month &&
                            o.dueDate.day == day.day,
                      )
                      .toList(),
                  onDaySelected: (selectedDay, focusedDay) {
                    setState(() {
                      _selected = selectedDay;
                      _focused = focusedDay;
                    });
                  },
                  calendarStyle: CalendarStyle(
                    defaultTextStyle:
                        Theme.of(context).textTheme.bodyMedium ?? const TextStyle(),
                    weekendTextStyle:
                        Theme.of(context).textTheme.bodyMedium ?? const TextStyle(),
                    outsideTextStyle: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: AppPalette.textMuted) ??
                        const TextStyle(),
                    todayDecoration: BoxDecoration(
                      color: AppPalette.surfaceMuted,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    selectedDecoration: BoxDecoration(
                      color: accent.primary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    markerDecoration: BoxDecoration(
                      color: accent.primary,
                      shape: BoxShape.circle,
                    ),
                    markersMaxCount: 1,
                    cellMargin: const EdgeInsets.all(4),
                    tableBorder: TableBorder.all(
                      color: Colors.transparent,
                    ),
                  ),
                  headerStyle: HeaderStyle(
                    formatButtonVisible: false,
                    titleCentered: true,
                    titleTextStyle: Theme.of(context).textTheme.titleMedium!,
                    leftChevronIcon: const Icon(Icons.chevron_left_rounded),
                    rightChevronIcon: const Icon(Icons.chevron_right_rounded),
                  ),
                  daysOfWeekStyle: DaysOfWeekStyle(
                    weekdayStyle: Theme.of(context).textTheme.bodySmall!,
                    weekendStyle: Theme.of(context).textTheme.bodySmall!,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpace.lg),
        SectionTitle(
          _mode == TimelineMode.upcoming ? 'Selected day' : 'Recent activity',
          subtitle: _mode == TimelineMode.upcoming
              ? 'What is due on ${selected.day}/${selected.month}.'
              : 'Payments and completed actions, newest first.',
        ),
        const SizedBox(height: AppSpace.sm),
        if (_mode == TimelineMode.upcoming)
          _upcomingList(upcomingForSelected)
        else
          _historyList(),
      ],
    );
  }

  Widget _modeChip(TimelineMode mode, String label, AppAccentColors accent) {
    final selected = _mode == mode;
    return GestureDetector(
      onTap: () => setState(() => _mode = mode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 170),
        padding: const EdgeInsets.symmetric(vertical: 13),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected
              ? accent.primary.withValues(alpha: 0.18)
              : AppPalette.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? accent.soft : AppPalette.border,
          ),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: selected ? AppPalette.textPrimary : AppPalette.textSecondary,
              ),
        ),
      ),
    );
  }

  Widget _upcomingList(List<Occurrence> items) {
    if (items.isEmpty) {
      return const EmptyStateCard(
        title: 'Nothing scheduled',
        subtitle: 'No due items for the selected day.',
        icon: Icons.event_note_rounded,
      );
    }

    return Column(
      children: items.map((o) {
        final plan = widget.plansById[o.planId];
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpace.xs),
          child: SoftCard(
            onTap: () => widget.onOpen(o.planId),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        plan?.title ?? 'Unknown',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: AppSpace.xxs),
                      Text(
                        plan?.category ?? '',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _historyList() {
    if (widget.payments.isEmpty) {
      return const EmptyStateCard(
        title: 'No activity yet',
        subtitle: 'Paid actions and history will appear here.',
        icon: Icons.timeline_rounded,
      );
    }

    final items = [...widget.payments]..sort((a, b) => b.paidAt.compareTo(a.paidAt));
    return Column(
      children: items.take(40).map((p) {
        final plan = widget.plansById[p.planId];
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpace.xs),
          child: SoftCard(
            onTap: () => widget.onOpen(p.planId),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        plan?.title ?? 'Payment',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: AppSpace.xxs),
                      Text(
                        '${p.paidAt.day}/${p.paidAt.month}/${p.paidAt.year}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.check_circle_outline_rounded,
                    color: AppPalette.success),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
