// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers.dart';
import '../../core/design/tokens.dart';
import '../../core/widgets/soft_card.dart';
import '../../domain/models/models.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({
    super.key,
    required this.settings,
    required this.onSave,
    this.onOpenNotificationDebug,
  });

  final AppSettings settings;
  final void Function(AppSettings settings) onSave;
  final VoidCallback? onOpenNotificationDebug;

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  int _debugTapCount = 0;
  late AppSettings _localSettings;

  @override
  void initState() {
    super.initState();
    _localSettings = widget.settings;
  }

  void _applySettings(AppSettings next) {
    setState(() => _localSettings = next);
    widget.onSave(next);
  }

  @override
  Widget build(BuildContext context) {
    final diagnostics =
        ref.watch(financeControllerProvider).valueOrNull?.notificationDiagnostics;
    final isSamsung =
        diagnostics?.deviceManufacturer.toLowerCase() == 'samsung';

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
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
                DropdownButtonFormField<ThemeMode>(
                  value: _localSettings.themeMode,
                  decoration: const InputDecoration(labelText: 'Theme'),
                  items: const [
                    DropdownMenuItem(value: ThemeMode.dark, child: Text('dark')),
                  ],
                  onChanged: (mode) {
                    if (mode != null) {
                      _applySettings(_localSettings.copyWith(themeMode: mode));
                    }
                  },
                ),
                const SizedBox(height: AppSpace.sm),
                _AccentSelector(
                  selected: _localSettings.accentTheme,
                  onSelected: (accentTheme) => _applySettings(
                    _localSettings.copyWith(accentTheme: accentTheme),
                  ),
                ),
                const SizedBox(height: AppSpace.sm),
                DropdownButtonFormField<String>(
                  value: _localSettings.currencyCode,
                  decoration: const InputDecoration(labelText: 'Currency'),
                  items: const ['USD', 'EUR', 'GBP']
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (code) {
                    if (code != null) {
                      _applySettings(_localSettings.copyWith(currencyCode: code));
                    }
                  },
                ),
                const SizedBox(height: AppSpace.xs),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Notifications'),
                  subtitle: const Text('Allow local reminders for upcoming dues.'),
                  value: _localSettings.notificationsEnabled,
                  onChanged: (v) =>
                      _applySettings(_localSettings.copyWith(notificationsEnabled: v)),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpace.md),
          SoftCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Reminder setup',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpace.sm),
                Text(
                  isSamsung
                      ? 'Samsung can delay reminders if the app is sleeping or battery-restricted.'
                      : 'If reminders do not arrive, check notification, alarm, and battery settings.',
                ),
                if (diagnostics != null) ...[
                  const SizedBox(height: AppSpace.sm),
                  _SetupLine(
                    label: 'Notifications',
                    value: diagnostics.notificationsEnabled == true
                        ? 'Allowed'
                        : 'Needs attention',
                  ),
                  _SetupLine(
                    label: 'Exact alarms',
                    value: diagnostics.exactAlarmAllowed == true
                        ? 'Allowed'
                        : 'Needs attention',
                  ),
                  _SetupLine(
                    label: 'Battery',
                    value: diagnostics.ignoresBatteryOptimizations == true
                        ? 'Unrestricted'
                        : 'Restricted or unknown',
                  ),
                ],
                const SizedBox(height: AppSpace.sm),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    FilledButton.tonal(
                      onPressed: () async {
                        await ref.read(notificationServiceProvider).requestPermissions();
                        await ref.read(financeControllerProvider.notifier).refresh();
                      },
                      child: const Text('Request permissions'),
                    ),
                    OutlinedButton(
                      onPressed: () async {
                        await ref
                            .read(notificationServiceProvider)
                            .openAppNotificationSettings();
                      },
                      child: const Text('App notifications'),
                    ),
                    OutlinedButton(
                      onPressed: () async {
                        await ref
                            .read(notificationServiceProvider)
                            .openExactAlarmSettings();
                      },
                      child: const Text('Exact alarms'),
                    ),
                    OutlinedButton(
                      onPressed: () async {
                        await ref
                            .read(notificationServiceProvider)
                            .openBatteryOptimizationSettings();
                      },
                      child: const Text('Battery settings'),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpace.sm),
                Text(
                  isSamsung
                      ? 'Recommended: remove Debtly from Sleeping apps and Deep sleeping apps, then add it to Never sleeping apps.'
                      : 'For critical reminders, keep the app unrestricted in battery settings.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpace.md),
          SoftCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Local data',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpace.sm),
                Text(
                  'Export a local backup file or reset the app back to an empty state.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: AppSpace.md),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    FilledButton.tonal(
                      onPressed: () async {
                        final messenger = ScaffoldMessenger.of(context);
                        final path = await ref
                            .read(financeControllerProvider.notifier)
                            .exportLocalBackup();
                        if (!context.mounted) return;
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text('Backup saved to $path'),
                          ),
                        );
                      },
                      child: const Text('Export backup'),
                    ),
                    OutlinedButton(
                      onPressed: () async {
                        final messenger = ScaffoldMessenger.of(context);
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: const Text('Reset app'),
                            content: const Text(
                              'This will delete all local plans, payments, salary data, and reminders. This cannot be undone.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Cancel'),
                              ),
                              FilledButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text('Delete all'),
                              ),
                            ],
                          ),
                        );
                        if (confirmed != true) return;
                        await ref
                            .read(financeControllerProvider.notifier)
                            .clearAllLocalData();
                        if (!context.mounted) return;
                        setState(() => _localSettings = AppSettings.defaults);
                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text('All local data deleted'),
                          ),
                        );
                      },
                      child: const Text('Reset app'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpace.md),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: widget.onOpenNotificationDebug == null
                ? null
                : () {
                    _debugTapCount += 1;
                    if (_debugTapCount >= 7) {
                      _debugTapCount = 0;
                      widget.onOpenNotificationDebug?.call();
                    }
                  },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpace.sm),
              child: Center(
                child: Text(
                  'Debtly',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppPalette.textMuted.withValues(alpha: 0.45),
                      ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SetupLine extends StatelessWidget {
  const _SetupLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppPalette.textSecondary,
                ),
          ),
        ],
      ),
    );
  }
}

class _AccentSelector extends StatelessWidget {
  const _AccentSelector({
    required this.selected,
    required this.onSelected,
  });

  final AccentTheme selected;
  final ValueChanged<AccentTheme> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Accent', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: AppSpace.sm),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: AccentTheme.values.map((accentTheme) {
            final colors = AppAccentColors.fromTheme(accentTheme);
            final isSelected = accentTheme == selected;
            return GestureDetector(
              onTap: () => onSelected(accentTheme),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? colors.primary.withValues(alpha: 0.14)
                      : AppPalette.surface,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(
                    color: isSelected ? colors.primary : AppPalette.border,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: colors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: AppSpace.sm),
                    Text(_label(accentTheme)),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  String _label(AccentTheme theme) {
    return switch (theme) {
      AccentTheme.ocean => 'Ocean',
      AccentTheme.violet => 'Violet',
      AccentTheme.ruby => 'Ruby',
      AccentTheme.emerald => 'Emerald',
    };
  }
}
