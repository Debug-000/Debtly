import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/services.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../../core/utils/date_utils_ext.dart';
import '../models/models.dart';

const _dueChannel = 'due_reminders_v2';
const _nativeChannel = MethodChannel('debtly/native');

class NotificationDiagnostics {
  const NotificationDiagnostics({
    required this.timezone,
    required this.pendingCount,
    required this.notificationsEnabled,
    required this.exactAlarmAllowed,
    required this.ignoresBatteryOptimizations,
    required this.deviceManufacturer,
    required this.lastScheduleAttempted,
    required this.lastScheduleSucceeded,
    required this.lastScheduleError,
    required this.warnings,
    required this.attemptedCount,
    required this.succeededCount,
    required this.failedCount,
    required this.skippedCount,
    required this.lastSkipReason,
    required this.lastPendingReadError,
  });

  final String timezone;
  final int pendingCount;
  final bool? notificationsEnabled;
  final bool? exactAlarmAllowed;
  final bool? ignoresBatteryOptimizations;
  final String deviceManufacturer;
  final DateTime? lastScheduleAttempted;
  final DateTime? lastScheduleSucceeded;
  final String? lastScheduleError;
  final List<String> warnings;
  final int attemptedCount;
  final int succeededCount;
  final int failedCount;
  final int skippedCount;
  final String? lastSkipReason;
  final String? lastPendingReadError;
}

class NotificationService {
  NotificationService();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  String _timezone = 'UTC';
  DateTime? _lastScheduleAttempted;
  DateTime? _lastScheduleSucceeded;
  String? _lastScheduleError;
  int _attemptedCount = 0;
  int _succeededCount = 0;
  int _failedCount = 0;
  int _skippedCount = 0;
  String? _lastSkipReason;
  String? _lastPendingReadError;

  Future<void> init(void Function(String payload) onTap) async {
    tz.initializeTimeZones();
    await _setupLocalTimezone();

    const android = AndroidInitializationSettings('ic_stat_debtly');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      defaultPresentAlert: true,
      defaultPresentBadge: true,
      defaultPresentSound: true,
    );

    const settings = InitializationSettings(android: android, iOS: ios);

    await _plugin.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        _log('tap payload=$payload');
        if (payload != null) {
          onTap(payload);
        }
      },
    );

    // Proactive reset on Android prevents legacy/corrupted plugin cache from
    // breaking every future schedule call with "Missing type parameter".
    await hardResetAndroidNotificationCache();
    await _createChannel();
    await requestPermissions();
    _log('initialized timezone=$_timezone');
  }

  Future<bool> requestPermissions() async {
    bool granted = true;

    final android =
        _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    final ios =
        _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();

    final androidPermission = await android?.requestNotificationsPermission();
    if (androidPermission == false) granted = false;

    final exact = await android?.requestExactAlarmsPermission();
    if (exact == false) {
      _log('exact alarm permission denied by platform');
    }

    final iosPermission = await ios?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );
    if (iosPermission == false) granted = false;

    final diagnostics = await getDiagnostics();
    _log(
      'permissions notificationsEnabled=${diagnostics.notificationsEnabled} exactAlarmAllowed=${diagnostics.exactAlarmAllowed}',
    );
    return granted;
  }

  Future<NotificationDiagnostics> getDiagnostics() async {
    final android =
        _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    bool? notificationsEnabled;
    bool? exactAlarmAllowed;
    bool? ignoresBatteryOptimizations;
    String manufacturer = '';

    try {
      notificationsEnabled = await android?.areNotificationsEnabled();
    } catch (_) {
      notificationsEnabled = null;
    }

    try {
      exactAlarmAllowed = await android?.canScheduleExactNotifications();
    } catch (_) {
      exactAlarmAllowed = null;
    }

    if (Platform.isAndroid) {
      try {
        ignoresBatteryOptimizations = await _nativeChannel
            .invokeMethod<bool>('isIgnoringBatteryOptimizations');
      } catch (_) {
        ignoresBatteryOptimizations = null;
      }
      try {
        manufacturer =
                await _nativeChannel.invokeMethod<String>('deviceManufacturer') ??
            '';
      } catch (_) {
        manufacturer = '';
      }
    }

    final pending = await getPendingRequests();
    final warnings = <String>[];
    if (notificationsEnabled == false) {
      warnings.add('Notifications are disabled at OS level.');
    }
    if (Platform.isAndroid && exactAlarmAllowed == false) {
      warnings.add('Exact alarms not allowed. Delivery may be delayed.');
    }
    if (Platform.isAndroid && ignoresBatteryOptimizations == false) {
      warnings.add('Battery optimization may delay reminders.');
    }
    if (manufacturer.toLowerCase() == 'samsung') {
      warnings.add('Samsung may delay reminders if the app is sleeping.');
    }
    if (_timezone == 'UTC') {
      warnings.add('Timezone fallback is UTC.');
    }
    if (_lastScheduleError != null && _lastScheduleError!.isNotEmpty) {
      warnings.add('Last schedule error exists.');
    }

    return NotificationDiagnostics(
      timezone: _timezone,
      pendingCount: pending.length,
      notificationsEnabled: notificationsEnabled,
      exactAlarmAllowed: exactAlarmAllowed,
      ignoresBatteryOptimizations: ignoresBatteryOptimizations,
      deviceManufacturer: manufacturer,
      lastScheduleAttempted: _lastScheduleAttempted,
      lastScheduleSucceeded: _lastScheduleSucceeded,
      lastScheduleError: _lastScheduleError,
      warnings: warnings,
      attemptedCount: _attemptedCount,
      succeededCount: _succeededCount,
      failedCount: _failedCount,
      skippedCount: _skippedCount,
      lastSkipReason: _lastSkipReason,
      lastPendingReadError: _lastPendingReadError,
    );
  }

  Future<void> openAppNotificationSettings() async {
    if (!Platform.isAndroid) return;
    await _nativeChannel.invokeMethod('openAppNotificationSettings');
  }

  Future<void> openExactAlarmSettings() async {
    if (!Platform.isAndroid) return;
    await _nativeChannel.invokeMethod('openExactAlarmSettings');
  }

  Future<void> openBatteryOptimizationSettings() async {
    if (!Platform.isAndroid) return;
    await _nativeChannel.invokeMethod('openBatteryOptimizationSettings');
  }

  Future<void> showInstantTest() async {
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        _dueChannel,
        'Due reminders',
        channelDescription: 'Debt and payment reminders',
        importance: Importance.max,
        priority: Priority.high,
        icon: 'ic_stat_debtly',
      ),
      iOS: DarwinNotificationDetails(),
    );

    await _plugin.show(
      id: 900001,
      title: 'Debtly test',
      body: 'Instant notification is working.',
      notificationDetails: details,
      payload: jsonEncode({'debug': true, 'type': 'instant'}),
    );
    _log('instant test shown id=900001');
  }

  Future<void> showTestIn10Seconds() async {
    final when = DateTime.now().add(const Duration(seconds: 10));
    await scheduleTestAt(when);
  }

  Future<void> scheduleTestAt(DateTime when) async {
    await _scheduleWithFallback(
      id: 900002,
      title: 'Debtly test',
      body: 'Scheduled test for ${when.toLocal()}',
      date: when,
      payload: jsonEncode({'debug': true, 'type': 'scheduled'}),
      exactPreferred: true,
    );
  }

  Future<void> scheduleMonthlyTest({
    required int dayOfMonth,
    required int hour,
    required int minute,
  }) async {
    final now = DateTime.now();
    final local = safeDate(now.year, now.month, dayOfMonth);
    final base = DateTime(local.year, local.month, local.day, hour, minute);
    final start = base.isAfter(now)
        ? base
        : DateTime(local.year, local.month + 1, dayOfMonth, hour, minute);

    await _scheduleWithFallback(
      id: 900003,
      title: 'Debtly monthly test',
      body: 'Monthly recurring reminder test',
      date: start,
      payload: jsonEncode({'debug': true, 'type': 'monthly'}),
      exactPreferred: false,
      matchDateTimeComponents: DateTimeComponents.dayOfMonthAndTime,
    );
    _log('monthly test scheduled id=900003 at=$start');
  }

  Future<void> scheduleYearlyTest({
    required int month,
    required int day,
    required int hour,
    required int minute,
  }) async {
    final now = DateTime.now();
    var year = now.year;
    var start = DateTime(year, month, day, hour, minute);
    if (!start.isAfter(now)) {
      year += 1;
      start = DateTime(year, month, day, hour, minute);
    }

    await _scheduleWithFallback(
      id: 900004,
      title: 'Debtly yearly test',
      body: 'Yearly recurring reminder test',
      date: start,
      payload: jsonEncode({'debug': true, 'type': 'yearly'}),
      exactPreferred: false,
      matchDateTimeComponents: DateTimeComponents.dateAndTime,
    );
    _log('yearly test scheduled id=900004 at=$start');
  }

  Future<List<PendingNotificationRequest>> getPendingRequests() async {
    try {
      _lastPendingReadError = null;
      return await _plugin.pendingNotificationRequests();
    } catch (e) {
      _log('pending requests read failed: $e');
      _lastPendingReadError = e.toString();
      if (_isMissingTypeParameterError(e)) {
        await _recoverAndroidCorruptedStore();
        try {
          _lastPendingReadError = null;
          return await _plugin.pendingNotificationRequests();
        } catch (retryError) {
          _lastPendingReadError = retryError.toString();
          _log('pending requests retry failed: $retryError');
        }
      }
      return const [];
    }
  }

  Future<void> cancelAll() async {
    try {
      await _plugin.cancelAll();
      _log('cancelAll called');
    } catch (e) {
      _log('cancelAll failed: $e');
      await _recoverAndroidCorruptedStore();
    }
  }

  Future<void> hardResetAndroidNotificationCache() async {
    await _recoverAndroidCorruptedStore();
  }

  Future<void> cancelPlanNotifications(String planId) async {
    try {
      final pending = await _plugin.pendingNotificationRequests();
      for (final req in pending) {
        if (req.payload != null && req.payload!.contains('"planId":"$planId"')) {
          await _plugin.cancel(id: req.id);
          _log('cancel plan=$planId id=${req.id}');
        }
      }
    } catch (e) {
      _log('cancel plan notifications failed for $planId: $e');
      await _recoverAndroidCorruptedStore();
    }
  }

  Future<void> scheduleForPlan({
    required ObligationPlan plan,
    required List<Occurrence> occurrences,
    required List<ReminderConfig> reminders,
    required SalaryConfig? salaryConfig,
  }) async {
    if (plan.archived || plan.manualClosed) {
      _markSkipped('plan closed/archived (${plan.id})');
      _log('skip scheduling for closed/archived plan=${plan.id}');
      return;
    }
    if (occurrences.isEmpty) {
      _markSkipped('no occurrences for plan=${plan.id}');
      _log('skip scheduling for plan=${plan.id} no occurrences');
      return;
    }
    if (reminders.isEmpty) {
      _markSkipped('no reminders for plan=${plan.id}');
      _log('skip scheduling for plan=${plan.id} no reminders');
      return;
    }

    await cancelPlanNotifications(plan.id);
    final now = DateTime.now();

    for (final occurrence in occurrences) {
      if (occurrence.status == OccurrenceStatus.paid) continue;

      for (final reminder in reminders) {
        if (reminder.hour < 0 ||
            reminder.hour > 23 ||
            reminder.minute < 0 ||
            reminder.minute > 59) {
          _markSkipped(
              'invalid reminder time plan=${plan.id} hour=${reminder.hour} minute=${reminder.minute}');
          _log(
              'invalid reminder time plan=${plan.id} hour=${reminder.hour} minute=${reminder.minute}');
          continue;
        }

        final date = _resolveReminderDate(
          occurrenceDate: occurrence.dueDate,
          reminder: reminder,
          salaryDay: salaryConfig?.salaryDay,
        );

        if (date == null) {
          _markSkipped('null date for plan=${plan.id} type=${reminder.type.name}');
          _log('skip null reminder date plan=${plan.id} type=${reminder.type.name}');
          continue;
        }
        if (date.isBefore(now.subtract(const Duration(minutes: 1)))) {
          _markSkipped(
              'past date for plan=${plan.id} type=${reminder.type.name} date=$date');
          _log(
              'skip old reminder plan=${plan.id} type=${reminder.type.name} date=$date now=$now');
          continue;
        }

        final id = _idFor(plan.id, occurrence.id, reminder.type, reminder.offsetDays);
        final payload = jsonEncode({'planId': plan.id, 'occurrenceId': occurrence.id});

        await _scheduleWithFallback(
          id: id,
          title: plan.title,
          body:
              '${plan.category} due ${occurrence.dueDate.day}/${occurrence.dueDate.month}/${occurrence.dueDate.year}',
          date: date,
          payload: payload,
          exactPreferred: true,
        );
      }
    }
  }

  Future<void> _scheduleWithFallback({
    required int id,
    required String title,
    required String body,
    required DateTime date,
    required String payload,
    required bool exactPreferred,
    DateTimeComponents? matchDateTimeComponents,
  }) async {
    final now = DateTime.now();
    final scheduleDate =
        date.isAfter(now) ? date : now.add(const Duration(seconds: 10));

    _lastScheduleAttempted = DateTime.now();
    _attemptedCount++;
    _lastScheduleError = null;
    _log('schedule id=$id at=$scheduleDate payload=$payload');

    final tzDate = tz.TZDateTime.from(scheduleDate, tz.local);

    try {
      await _plugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: tzDate,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            _dueChannel,
            'Due reminders',
            channelDescription: 'Debt and payment reminders',
            importance: Importance.max,
            priority: Priority.high,
            enableVibration: true,
            playSound: true,
            icon: 'ic_stat_debtly',
          ),
          iOS: DarwinNotificationDetails(),
        ),
        payload: payload,
        androidScheduleMode:
            exactPreferred ? AndroidScheduleMode.exactAllowWhileIdle : AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: matchDateTimeComponents,
      );
      _lastScheduleSucceeded = DateTime.now();
      _succeededCount++;
      _lastScheduleError = null;
      return;
    } catch (e) {
      _log('primary schedule failed id=$id error=$e');
      _lastScheduleError = e.toString();
      _failedCount++;
      if (_isMissingTypeParameterError(e)) {
        await _recoverAndroidCorruptedStore();
      }
    }

    try {
      await _plugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: tzDate,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            _dueChannel,
            'Due reminders',
            channelDescription: 'Debt and payment reminders',
            importance: Importance.max,
            priority: Priority.high,
            enableVibration: true,
            playSound: true,
            icon: 'ic_stat_debtly',
          ),
          iOS: DarwinNotificationDetails(),
        ),
        payload: payload,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: matchDateTimeComponents,
      );
      _lastScheduleSucceeded = DateTime.now();
      _succeededCount++;
      _lastScheduleError = null;
      return;
    } catch (e) {
      _log('fallback inexact schedule failed id=$id error=$e');
      _lastScheduleError = e.toString();
      _failedCount++;
      if (_isMissingTypeParameterError(e)) {
        await _recoverAndroidCorruptedStore();
      }
    }

    _log('schedule dropped id=$id after retries');
  }

  DateTime? _resolveReminderDate({
    required DateTime occurrenceDate,
    required ReminderConfig reminder,
    required int? salaryDay,
  }) {
    final due = occurrenceDate.dateOnly;
    final h = reminder.hour;
    final m = reminder.minute;
    switch (reminder.type) {
      case ReminderType.dueDate:
        return DateTime(
          due.year,
          due.month,
          due.day,
          h,
          m,
        );
      case ReminderType.oneDayBefore:
        return DateTime(
          due.year,
          due.month,
          due.day - 1,
          h,
          m,
        );
      case ReminderType.firstDayOfMonth:
        return DateTime(due.year, due.month, 1, h, m);
      case ReminderType.salaryDay:
        if (salaryDay == null) return null;
        final d = safeDate(due.year, due.month, salaryDay);
        return DateTime(d.year, d.month, d.day, h, m);
      case ReminderType.customDaysBefore:
        final offset = reminder.offsetDays ?? 0;
        return DateTime(
          due.year,
          due.month,
          due.day - offset,
          h,
          m,
        );
    }
  }

  int _idFor(
    String planId,
    String occurrenceId,
    ReminderType type,
    int? offset,
  ) {
    final raw = '$planId|$occurrenceId|${type.name}|${offset ?? 0}';
    return raw.hashCode & 0x7fffffff;
  }

  Future<void> _setupLocalTimezone() async {
    try {
      final name = await FlutterTimezone.getLocalTimezone();
      final location = tz.getLocation(name);
      tz.setLocalLocation(location);
      _timezone = name;
    } catch (e) {
      final offset = DateTime.now().timeZoneOffset;
      final fallback = _offsetToEtcGmt(offset);
      try {
        tz.setLocalLocation(tz.getLocation(fallback));
        _timezone = fallback;
      } catch (_) {
        tz.setLocalLocation(tz.getLocation('UTC'));
        _timezone = 'UTC';
      }
      _log('timezone fallback error=$e using=$_timezone');
    }
  }

  Future<void> _createChannel() async {
    final android =
        _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await android?.createNotificationChannel(
      const AndroidNotificationChannel(
        _dueChannel,
        'Due reminders',
        description: 'Debt and payment reminders',
        importance: Importance.max,
        playSound: true,
      ),
    );
  }

  Future<void> _recoverAndroidCorruptedStore() async {
    if (!Platform.isAndroid) return;

    try {
      final cleared =
          await _nativeChannel.invokeMethod<bool>('clearNotificationPluginCache');
      _log('native plugin cache clear result=$cleared');
    } catch (e) {
      _log('native plugin cache clear failed: $e');
    }

    try {
      await _plugin.cancelAll();
    } catch (_) {}

    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs
          .getKeys()
          .where((k) =>
              k.contains('flutter_local_notifications') ||
              k.contains('scheduled_notifications') ||
              k.contains('notification'))
          .toList(growable: false);
      for (final key in keys) {
        await prefs.remove(key);
      }
      _log('android store recovery removed keys=${keys.length}');
    } catch (e) {
      _log('android store recovery failed: $e');
    }
  }

  bool _isMissingTypeParameterError(Object error) {
    final raw = error.toString();
    return raw.contains('Missing type parameter');
  }

  String _offsetToEtcGmt(Duration offset) {
    final hour = offset.inHours;
    if (hour == 0) return 'UTC';
    final sign = hour > 0 ? '-' : '+';
    final absHour = hour.abs();
    return 'Etc/GMT$sign$absHour';
  }

  void _log(String msg) {
    debugPrint('[NotificationService] $msg');
  }

  void _markSkipped(String reason) {
    _skippedCount++;
    _lastSkipReason = reason;
  }
}
