import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Local, repeating, user-controlled check-in reminders.
/// No Firebase writes and no changes to the emotional check-in flow.
class MofuchiReminderService {
  MofuchiReminderService._();
  static final MofuchiReminderService instance = MofuchiReminderService._();

  static const _enabledKey = 'mofuchi_reminder_enabled';
  static const _hourKey = 'mofuchi_reminder_hour';
  static const _minuteKey = 'mofuchi_reminder_minute';
  static const _frequencyKey = 'mofuchi_reminder_frequency';
  static const _baseId = 87100;

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    tz.initializeTimeZones();
    final timeZone = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timeZone.identifier));
    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );
    await _plugin.initialize(settings);
    _initialized = true;
  }

  Future<ReminderPreferences> load() async {
    final preferences = await SharedPreferences.getInstance();
    return ReminderPreferences(
      enabled: preferences.getBool(_enabledKey) ?? false,
      hour: preferences.getInt(_hourKey) ?? 20,
      minute: preferences.getInt(_minuteKey) ?? 0,
      frequency: preferences.getString(_frequencyKey) ?? 'Daily',
    );
  }

  Future<bool> _requestPermission() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      return await android?.requestNotificationsPermission() ?? false;
    }
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      final ios = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      return await ios?.requestPermissions(alert: true, badge: true, sound: true) ?? false;
    }
    return true;
  }

  Future<void> save(ReminderPreferences prefs) async {
    await initialize();
    if (prefs.enabled && !await _requestPermission()) {
      throw StateError('Notification permission was not granted.');
    }

    // Cancel only Mofuchi's reminder IDs, never notifications from other features.
    await _cancelReminders();
    if (prefs.enabled) {
      const details = NotificationDetails(
        android: AndroidNotificationDetails(
          'mofuchi_daily_reflection',
          'Mofuchi Reflection Reminders',
          channelDescription: 'Gentle reminders to check in with your feelings',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      );

      if (prefs.frequency == 'Daily') {
        await _plugin.zonedSchedule(
          _baseId,
          'A little moment for you 🌸',
          'How is your garden feeling today? Take a gentle check-in.',
          _nextTime(prefs.hour, prefs.minute),
          details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.time,
        );
      } else {
        final days = prefs.frequency == 'Weekdays'
            ? <int>[1, 2, 3, 4, 5]
            : <int>[6, 7];
        for (final day in days) {
          await _plugin.zonedSchedule(
            _baseId + day,
            'A little moment for you 🌸',
            'How is your garden feeling today? Take a gentle check-in.',
            _nextWeekday(day, prefs.hour, prefs.minute),
            details,
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
            matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
          );
        }
      }
    }

    // Persist only after successful scheduling/cancellation.
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_enabledKey, prefs.enabled);
    await preferences.setInt(_hourKey, prefs.hour);
    await preferences.setInt(_minuteKey, prefs.minute);
    await preferences.setString(_frequencyKey, prefs.frequency);
  }

  tz.TZDateTime _nextTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var next = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (!next.isAfter(now)) next = tz.TZDateTime(tz.local, now.year, now.month, now.day + 1, hour, minute);
    return next;
  }

  tz.TZDateTime _nextWeekday(int weekday, int hour, int minute) {
    var next = _nextTime(hour, minute);
    while (next.weekday != weekday) {
      next = tz.TZDateTime(tz.local, next.year, next.month, next.day + 1, hour, minute);
    }
    return next;
  }

  Future<void> _cancelReminders() async {
    await _plugin.cancel(_baseId);
    for (var day = 1; day <= 7; day++) {
      await _plugin.cancel(_baseId + day);
    }
  }
}

class ReminderPreferences {
  final bool enabled;
  final int hour;
  final int minute;
  final String frequency;

  const ReminderPreferences({
    required this.enabled,
    required this.hour,
    required this.minute,
    required this.frequency,
  });

  ReminderPreferences copyWith({bool? enabled, int? hour, int? minute, String? frequency}) =>
      ReminderPreferences(
        enabled: enabled ?? this.enabled,
        hour: hour ?? this.hour,
        minute: minute ?? this.minute,
        frequency: frequency ?? this.frequency,
      );
}
