// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../core/design/tokens.dart';
import '../../core/utils/currency.dart';
import '../../core/utils/labels.dart';
import '../../core/widgets/section_title.dart';
import '../../core/widgets/soft_card.dart';
import '../../domain/models/models.dart';

class AddEditItemScreen extends StatefulWidget {
  const AddEditItemScreen({
    super.key,
    this.initialPlan,
    this.initialReminders = const [],
    this.onDelete,
  });

  final ObligationPlan? initialPlan;
  final List<ReminderConfig> initialReminders;
  final Future<void> Function()? onDelete;

  @override
  State<AddEditItemScreen> createState() => _AddEditItemScreenState();
}

class _AddEditItemScreenState extends State<AddEditItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _uuid = const Uuid();

  late final TextEditingController _title;
  late final TextEditingController _amount;
  late final TextEditingController _category;
  late final TextEditingController _notes;
  late final TextEditingController _customReminderDays;

  late DateTime _startDate;
  late int _dueDay;
  late ObligationKind _kind;
  late RecurrenceType _recurrence;
  int? _customIntervalDays;
  int? _customIntervalMonths;
  late DurationType _duration;
  int? _durationValue;
  DateTime? _endDate;
  bool _affectsSalary = true;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 9, minute: 0);

  final Set<ReminderType> _reminders = {};

  @override
  void initState() {
    super.initState();
    final initial = widget.initialPlan;

    _title = TextEditingController(text: initial?.title ?? '');
    _amount = TextEditingController(
      text: ((initial?.amountCents ?? 0) / 100).toStringAsFixed(2),
    );
    _category = TextEditingController(text: initial?.category ?? '');
    _notes = TextEditingController(text: initial?.notes ?? '');
    _customReminderDays = TextEditingController(text: '2');

    _startDate = initial?.startDate ?? DateTime.now();
    _dueDay = initial?.dueDay ?? DateTime.now().day;
    _kind = initial?.kind ?? ObligationKind.debt;
    _recurrence = initial?.recurrenceType ?? RecurrenceType.monthly;
    _customIntervalDays = initial?.customIntervalDays;
    _customIntervalMonths = initial?.customIntervalMonths;
    if (_customIntervalMonths == null &&
        (_customIntervalDays ?? 0) >= 60 &&
        (_customIntervalDays! % 30 == 0)) {
      _customIntervalMonths = _customIntervalDays! ~/ 30;
      _customIntervalDays = null;
    }
    _duration = initial?.durationType ?? DurationType.untilClosed;
    _durationValue = initial?.durationValue;
    _endDate = initial?.endDate;
    _affectsSalary = initial?.affectsSalary ?? true;

    for (final r in widget.initialReminders) {
      _reminders.add(r.type);
      _reminderTime = TimeOfDay(hour: r.hour, minute: r.minute);
      if (r.type == ReminderType.customDaysBefore && r.offsetDays != null) {
        _customReminderDays.text = '${r.offsetDays}';
      }
    }
    if (_reminders.isEmpty) {
      _reminders
        ..add(ReminderType.dueDate)
        ..add(ReminderType.oneDayBefore);
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = context.accentColors;
    final editing = widget.initialPlan != null;
    final customByMonths = (_customIntervalMonths ?? 0) > 0;

    return Scaffold(
      appBar: AppBar(title: Text(editing ? 'Edit item' : 'New item')),
      body: Form(
        key: _formKey,
        child: ListView(
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
                  SectionTitle(
                    editing ? 'Refine this plan' : 'Create a new plan',
                    subtitle: 'Keep it short. The schedule and reminders come next.',
                  ),
                  const SizedBox(height: AppSpace.md),
                  TextFormField(
                    controller: _title,
                    decoration: const InputDecoration(labelText: 'Title'),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: AppSpace.sm),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _amount,
                          decoration: const InputDecoration(labelText: 'Amount'),
                          keyboardType:
                              const TextInputType.numberWithOptions(decimal: true),
                          validator: (v) =>
                              parseToCents(v ?? '') <= 0 ? 'Invalid amount' : null,
                        ),
                      ),
                      const SizedBox(width: AppSpace.sm),
                      Expanded(
                        child: TextFormField(
                          controller: _category,
                          decoration: const InputDecoration(labelText: 'Category'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpace.sm),
                  _HintStrip(
                    text:
                        'Use a short title and a single-cycle amount. Category helps keep the list readable.',
                  ),
                  const SizedBox(height: AppSpace.sm),
                  TextFormField(
                    controller: _notes,
                    decoration: const InputDecoration(labelText: 'Notes'),
                    maxLines: 3,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpace.md),
            SoftCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionTitle(
                    'Structure',
                    subtitle: 'Define the type, recurrence, and due rhythm.',
                  ),
                  const SizedBox(height: AppSpace.md),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<ObligationKind>(
                          value: _kind,
                          decoration: const InputDecoration(labelText: 'Item type'),
                          items: ObligationKind.values
                              .map(
                                (e) =>
                                    DropdownMenuItem(value: e, child: Text(e.name)),
                              )
                              .toList(),
                          onChanged: (value) => setState(() => _kind = value!),
                        ),
                      ),
                      const SizedBox(width: AppSpace.sm),
                      Expanded(
                        child: DropdownButtonFormField<RecurrenceType>(
                          value: _recurrence,
                          decoration: const InputDecoration(labelText: 'Repeats'),
                          items: RecurrenceType.values
                              .map(
                                (e) => DropdownMenuItem(
                                  value: e,
                                  child: Text(recurrenceLabel(e)),
                                ),
                              )
                              .toList(),
                          onChanged: (value) =>
                              setState(() => _recurrence = value!),
                        ),
                      ),
                    ],
                  ),
                  if (_recurrence == RecurrenceType.customDays) ...[
                    const SizedBox(height: AppSpace.sm),
                    SegmentedButton<bool>(
                      style: ButtonStyle(
                        backgroundColor: WidgetStateProperty.resolveWith(
                          (states) => states.contains(WidgetState.selected)
                              ? accent.primary.withValues(alpha: 0.18)
                              : AppPalette.surfaceRaised,
                        ),
                      ),
                      segments: const [
                        ButtonSegment(value: false, label: Text('Days')),
                        ButtonSegment(value: true, label: Text('Months')),
                      ],
                      selected: {customByMonths},
                      onSelectionChanged: (selection) {
                        final monthMode = selection.first;
                        setState(() {
                          if (monthMode) {
                            _customIntervalMonths = _customIntervalMonths ?? 3;
                            _customIntervalDays = null;
                          } else {
                            _customIntervalDays = _customIntervalDays ?? 30;
                            _customIntervalMonths = null;
                          }
                        });
                      },
                    ),
                    const SizedBox(height: AppSpace.sm),
                    TextFormField(
                      initialValue: (customByMonths
                              ? (_customIntervalMonths ?? 3)
                              : (_customIntervalDays ?? 30))
                          .toString(),
                      decoration: InputDecoration(
                        labelText: customByMonths ? 'Every X months' : 'Every X days',
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (v) {
                        final parsed = int.tryParse(v);
                        if (customByMonths) {
                          _customIntervalMonths = parsed;
                        } else {
                          _customIntervalDays = parsed;
                        }
                      },
                    ),
                  ],
                  const SizedBox(height: AppSpace.sm),
                  _ActionField(
                    label: 'Start date',
                    value: _formatDate(_startDate),
                    icon: Icons.calendar_month_rounded,
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                        initialDate: _startDate,
                      );
                      if (picked != null) setState(() => _startDate = picked);
                    },
                  ),
                  const SizedBox(height: AppSpace.xs),
                  Container(
                    padding: const EdgeInsets.all(AppSpace.md),
                    decoration: BoxDecoration(
                      color: AppPalette.surfaceRaised,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Due day',
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            const Spacer(),
                            Text(
                              '$_dueDay',
                              style:
                                  Theme.of(context).textTheme.titleMedium?.copyWith(
                                        color: accent.primary,
                                      ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpace.xs),
                        Slider(
                          value: _dueDay.toDouble(),
                          min: 1,
                          max: 31,
                          divisions: 30,
                          label: '$_dueDay',
                          onChanged: (v) => setState(() => _dueDay = v.round()),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpace.md),
            SoftCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionTitle(
                    'Duration',
                    subtitle: 'Choose when this obligation stops generating cycles.',
                  ),
                  const SizedBox(height: AppSpace.md),
                  _HintStrip(
                    text:
                        'Fixed duration ends automatically. Until closed keeps this active until you stop it.',
                  ),
                  const SizedBox(height: AppSpace.md),
                  DropdownButtonFormField<DurationType>(
                    value: _duration,
                    decoration: const InputDecoration(labelText: 'Ends'),
                    items: DurationType.values
                        .map(
                          (e) => DropdownMenuItem(
                            value: e,
                            child: Text(durationLabel(e)),
                          ),
                        )
                        .toList(),
                    onChanged: (value) => setState(() => _duration = value!),
                  ),
                  if (_duration == DurationType.fixedMonths ||
                      _duration == DurationType.fixedYears) ...[
                    const SizedBox(height: AppSpace.sm),
                    TextFormField(
                      initialValue: (_durationValue ?? 12).toString(),
                      decoration: const InputDecoration(labelText: 'Count'),
                      keyboardType: TextInputType.number,
                      onChanged: (v) => _durationValue = int.tryParse(v),
                    ),
                  ],
                  if (_duration == DurationType.untilDate) ...[
                    const SizedBox(height: AppSpace.sm),
                    ListTile(
                      title: const Text('End date'),
                      subtitle: Text(
                        _endDate == null ? 'Select date' : _formatDate(_endDate!),
                      ),
                      trailing: const Icon(Icons.event_rounded),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          firstDate: _startDate,
                          lastDate: DateTime(2100),
                          initialDate: _endDate ?? _startDate,
                        );
                        if (picked != null) setState(() => _endDate = picked);
                      },
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSpace.md),
            SoftCard(
              backgroundColor: AppPalette.surfaceRaised,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionTitle(
                    'Reminders',
                    subtitle: 'Choose when Debtly should nudge you.',
                  ),
                  const SizedBox(height: AppSpace.md),
                  _HintStrip(
                    text:
                        'Pick only useful reminders. A smaller set is easier to trust every day.',
                  ),
                  const SizedBox(height: AppSpace.md),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: ReminderType.values.map((type) {
                      final selected = _reminders.contains(type);
                      return FilterChip(
                        selected: selected,
                        label: Text(reminderLabel(type)),
                        onSelected: (v) {
                          setState(() {
                            if (v) {
                              _reminders.add(type);
                            } else {
                              _reminders.remove(type);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: AppSpace.sm),
                  ListTile(
                    title: const Text('Notification time'),
                    subtitle: Text(
                      '${_reminderTime.hour.toString().padLeft(2, '0')}:${_reminderTime.minute.toString().padLeft(2, '0')}',
                    ),
                    trailing: const Icon(Icons.schedule_rounded),
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: _reminderTime,
                      );
                      if (picked != null) {
                        setState(() => _reminderTime = picked);
                      }
                    },
                  ),
                  if (_reminders.contains(ReminderType.customDaysBefore)) ...[
                    const SizedBox(height: AppSpace.xs),
                    TextFormField(
                      controller: _customReminderDays,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Custom days before',
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpace.xs),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _affectsSalary,
                    title: const Text('Affects monthly balance'),
                    subtitle: const Text('Paid cycles reduce the remaining salary view.'),
                    onChanged: (v) => setState(() => _affectsSalary = v),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpace.lg),
            FilledButton(
              onPressed: _save,
              child: Text(editing ? 'Save changes' : 'Create item'),
            ),
            if (editing && widget.onDelete != null) ...[
              const SizedBox(height: AppSpace.sm),
              Center(
                child: TextButton(
                  onPressed: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text('Delete item'),
                        content: const Text(
                          'This will permanently delete the item and its local history.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancel'),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Delete'),
                          ),
                        ],
                      ),
                    );
                    if (confirmed != true) return;
                    await widget.onDelete?.call();
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: AppPalette.danger,
                  ),
                  child: const Text('Delete item'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime value) {
    return '${value.day}/${value.month}/${value.year}';
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final now = DateTime.now();
    final previous = widget.initialPlan;
    final id = previous?.id ?? _uuid.v4();

    final plan = ObligationPlan(
      id: id,
      title: _title.text.trim(),
      notes: _notes.text.trim(),
      category: _category.text.trim().isEmpty ? 'General' : _category.text.trim(),
      amountCents: parseToCents(_amount.text),
      startDate: _startDate,
      dueDay: _dueDay,
      kind: _kind,
      recurrenceType: _recurrence,
      customIntervalDays:
          _recurrence == RecurrenceType.customDays ? _customIntervalDays : null,
      customIntervalMonths:
          _recurrence == RecurrenceType.customDays ? _customIntervalMonths : null,
      durationType: _duration,
      durationValue:
          (_duration == DurationType.fixedMonths || _duration == DurationType.fixedYears)
              ? (_durationValue ?? 1)
              : null,
      endDate: _duration == DurationType.untilDate ? _endDate : null,
      affectsSalary: _affectsSalary,
      manualClosed: previous?.manualClosed ?? false,
      archived: previous?.archived ?? false,
      retentionUntil: previous?.retentionUntil,
      createdAt: previous?.createdAt ?? now,
      updatedAt: now,
    );

    final reminders = _reminders
        .map(
          (type) => ReminderConfig(
            id: _uuid.v4(),
            planId: id,
            type: type,
            offsetDays: type == ReminderType.customDaysBefore
                ? (int.tryParse(_customReminderDays.text) ?? 2)
                : null,
            hour: _reminderTime.hour,
            minute: _reminderTime.minute,
          ),
        )
        .toList(growable: false);

    Navigator.of(context).pop((plan: plan, reminders: reminders));
  }
}

class _HintStrip extends StatelessWidget {
  const _HintStrip({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final accent = context.accentColors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: accent.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: accent.primary.withValues(alpha: 0.12)),
      ),
      child: Text(text, style: Theme.of(context).textTheme.bodySmall),
    );
  }
}

class _ActionField extends StatelessWidget {
  const _ActionField({
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Ink(
          padding: const EdgeInsets.all(AppSpace.md),
          decoration: BoxDecoration(
            color: AppPalette.surfaceRaised,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: Theme.of(context).textTheme.bodySmall),
                    const SizedBox(height: AppSpace.xs),
                    Text(value, style: Theme.of(context).textTheme.titleMedium),
                  ],
                ),
              ),
              Icon(icon),
            ],
          ),
        ),
      ),
    );
  }
}
