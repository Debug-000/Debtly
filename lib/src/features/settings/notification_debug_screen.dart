import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers.dart';
import '../../core/design/tokens.dart';
import '../../core/widgets/soft_card.dart';

class NotificationDebugScreen extends ConsumerStatefulWidget {
  const NotificationDebugScreen({super.key});

  @override
  ConsumerState<NotificationDebugScreen> createState() =>
      _NotificationDebugScreenState();
}

class _NotificationDebugScreenState
    extends ConsumerState<NotificationDebugScreen> {
  DateTime _pickedDateTime = DateTime.now().add(const Duration(minutes: 3));
  String _status = 'Ready';
  List<String> _pending = const [];

  @override
  void initState() {
    super.initState();
    _refreshState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notification Debug')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpace.md),
        children: [
          SoftCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Status'),
                const SizedBox(height: 6),
                Text(_status),
              ],
            ),
          ),
          const SizedBox(height: AppSpace.md),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              FilledButton(
                onPressed: () async {
                  await _run('Request permissions', () async {
                    final service = ref.read(notificationServiceProvider);
                    await service.requestPermissions();
                  });
                },
                child: const Text('Request permissions'),
              ),
              FilledButton.tonal(
                onPressed: () async {
                  await _run('Instant test', () async {
                    await ref.read(notificationServiceProvider).showInstantTest();
                  });
                },
                child: const Text('Instant test'),
              ),
              FilledButton.tonal(
                onPressed: () async {
                  await _run('10s test', () async {
                    await ref.read(notificationServiceProvider).showTestIn10Seconds();
                  });
                },
                child: const Text('Notify in 10s'),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.md),
          SoftCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Schedule exact date/time'),
                const SizedBox(height: AppSpace.sm),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Selected time'),
                  subtitle: Text(_pickedDateTime.toLocal().toString()),
                  trailing: const Icon(Icons.schedule_rounded),
                  onTap: _pickDateTime,
                ),
                const SizedBox(height: AppSpace.xs),
                FilledButton.tonal(
                  onPressed: () async {
                    await _run('Schedule exact test', () async {
                      await ref
                          .read(notificationServiceProvider)
                          .scheduleTestAt(_pickedDateTime);
                    });
                  },
                  child: const Text('Schedule test at selected time'),
                ),
                const SizedBox(height: AppSpace.xs),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton(
                      onPressed: () async {
                        final t = TimeOfDay.fromDateTime(_pickedDateTime);
                        await _run('Monthly recurring test', () async {
                          await ref.read(notificationServiceProvider).scheduleMonthlyTest(
                                dayOfMonth: _pickedDateTime.day,
                                hour: t.hour,
                                minute: t.minute,
                              );
                        });
                      },
                      child: const Text('Monthly recurring test'),
                    ),
                    OutlinedButton(
                      onPressed: () async {
                        final t = TimeOfDay.fromDateTime(_pickedDateTime);
                        await _run('Yearly recurring test', () async {
                          await ref.read(notificationServiceProvider).scheduleYearlyTest(
                                month: _pickedDateTime.month,
                                day: _pickedDateTime.day,
                                hour: t.hour,
                                minute: t.minute,
                              );
                        });
                      },
                      child: const Text('Yearly recurring test'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpace.md),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              OutlinedButton(
                onPressed: () async {
                  await _run('List pending', _refreshPendingOnly);
                },
                child: const Text('List pending'),
              ),
              OutlinedButton(
                onPressed: () async {
                  await _run('Cancel all', () async {
                    await ref
                        .read(financeControllerProvider.notifier)
                        .cancelAllReminders();
                  });
                },
                child: const Text('Cancel all'),
              ),
              OutlinedButton(
                onPressed: () async {
                  await _run('Reschedule all active', () async {
                    await ref
                        .read(financeControllerProvider.notifier)
                        .rescheduleAllActiveReminders();
                  });
                },
                child: const Text('Reschedule from DB'),
              ),
              OutlinedButton(
                onPressed: () async {
                  await _run('Hard reset + reschedule', () async {
                    await ref
                        .read(notificationServiceProvider)
                        .hardResetAndroidNotificationCache();
                    await ref
                        .read(financeControllerProvider.notifier)
                        .rescheduleAllActiveReminders();
                  });
                },
                child: const Text('Hard reset + reschedule'),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.md),
          SoftCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Pending notifications'),
                const SizedBox(height: AppSpace.sm),
                if (_pending.isEmpty)
                  const Text('No pending notifications')
                else
                  ..._pending.map((e) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text(e),
                      )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _pickedDateTime,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime(2100),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_pickedDateTime),
    );
    if (time == null) return;

    setState(() {
      _pickedDateTime = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> _refreshState() async {
    final service = ref.read(notificationServiceProvider);
    final diag = await service.getDiagnostics();
    final pending = await service.getPendingRequests();

    if (!mounted) return;
    setState(() {
      _status =
          'timezone=${diag.timezone} | notificationsEnabled=${diag.notificationsEnabled} | exactAlarm=${diag.exactAlarmAllowed} | battery=${diag.ignoresBatteryOptimizations} | manufacturer=${diag.deviceManufacturer} | pending=${diag.pendingCount}\n'
          'lastAttempt=${diag.lastScheduleAttempted} | lastSuccess=${diag.lastScheduleSucceeded} | lastError=${diag.lastScheduleError ?? '-'}\n'
          'attempted=${diag.attemptedCount} | succeeded=${diag.succeededCount} | failed=${diag.failedCount} | skipped=${diag.skippedCount}\n'
          'lastSkip=${diag.lastSkipReason ?? '-'}\n'
          'pendingReadError=${diag.lastPendingReadError ?? '-'}\n'
          'warnings=${diag.warnings.isEmpty ? '-' : diag.warnings.join(' | ')}';
      _pending = pending
          .map((p) => 'id=${p.id} title=${p.title ?? '-'} payload=${p.payload ?? '-'}')
          .toList(growable: false);
    });
  }

  Future<void> _refreshPendingOnly() async {
    final pending = await ref.read(notificationServiceProvider).getPendingRequests();
    if (!mounted) return;
    setState(() {
      _pending = pending
          .map((p) => 'id=${p.id} title=${p.title ?? '-'} payload=${p.payload ?? '-'}')
          .toList(growable: false);
    });
  }

  Future<void> _run(String label, Future<void> Function() fn) async {
    setState(() => _status = '$label...');
    try {
      await fn();
      await _refreshState();
      setState(() => _status = '$label: OK');
    } catch (e) {
      setState(() => _status = '$label: ERROR $e');
    }
  }
}
