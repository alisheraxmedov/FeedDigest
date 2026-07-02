/*
NotificationService wraps flutter_local_notifications for the daily digest
reminder. Per the reality check, this is a *fixed-time local reminder* — the
notification body is static and the fresh digest is generated when the user
opens the app and taps the digest action. No server/push is involved.

Scheduling uses zonedSchedule + matchDateTimeComponents.time so a single call
repeats every day at the chosen local time; the Android boot receiver re-arms it
after a reboot. Inexact scheduling avoids the SCHEDULE_EXACT_ALARM permission.
*/
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const int _dailyId = 1001;
  static const String _channelId = 'daily_digest';
  static const String _channelName = 'Daily digest';

  bool _ready = false;

  Future<void> _ensureReady() async {
    if (_ready) return;
    tz_data.initializeTimeZones();
    try {
      tz.setLocalLocation(tz.getLocation(await FlutterTimezone.getLocalTimezone()));
    } catch (_) {
      // Fall back to the default (UTC) location if the platform lookup fails.
    }
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwin = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: darwin),
    );
    _ready = true;
  }

  /// Asks the OS for notification permission. Returns true if granted (or if the
  /// platform doesn't gate it). Android 13+ and iOS both prompt here.
  Future<bool> requestPermission() async {
    await _ensureReady();
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android != null) {
      return await android.requestNotificationsPermission() ?? false;
    }
    final ios = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    if (ios != null) {
      return await ios.requestPermissions(alert: true, badge: true, sound: true) ??
          false;
    }
    return true;
  }

  Future<void> scheduleDaily({
    required int hour,
    required int minute,
    required String title,
    required String body,
  }) async {
    await _ensureReady();
    await _plugin.zonedSchedule(
      _dailyId,
      title,
      body,
      _nextInstance(hour, minute),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> cancelDaily() async {
    await _ensureReady();
    await _plugin.cancel(_dailyId);
  }

  tz.TZDateTime _nextInstance(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }
}
