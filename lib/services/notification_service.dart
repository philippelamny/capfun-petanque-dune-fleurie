import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// Schedules the "5 minutes left" / "last end" notifications for a round,
/// and shows an immediate one when a round is manually ended early.
/// Notifications fire even if the app is backgrounded or the screen is
/// locked.
class NotificationService {
  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  static const _fiveMinId = 1001;
  static const _lastEndId = 1002;

  Future<void> init() async {
    if (_initialized) return;
    tz_data.initializeTimeZones();
    try {
      tz.setLocalLocation(tz.local);
    } catch (_) {
      // Fall back to UTC if the local timezone can't be resolved.
    }

    // Notifications are a best-effort feature: if the platform plugin isn't
    // available (e.g. running in `flutter test`, or an unsupported desktop
    // target), the app must keep working without reminders.
    try {
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      await _plugin.initialize(
        const InitializationSettings(android: androidSettings, iOS: iosSettings),
      );

      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await android?.requestNotificationsPermission();
      await android?.requestExactAlarmsPermission();
      await _plugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
      _initialized = true;
    } catch (_) {
      _initialized = false;
    }
  }

  Future<void> scheduleRoundReminders({
    required DateTime roundEnd,
  }) async {
    if (!_initialized) return;
    await cancelRoundReminders();
    final fiveMin = roundEnd.subtract(const Duration(minutes: 5));
    final twoMin = roundEnd.subtract(const Duration(minutes: 2));
    final now = DateTime.now();

    if (fiveMin.isAfter(now)) {
      await _schedule(
        id: _fiveMinId,
        title: 'Plus que 5 minutes !',
        body: 'Le temps du round touche bientôt à sa fin.',
        when: fiveMin,
      );
    }
    if (twoMin.isAfter(now)) {
      await _schedule(
        id: _lastEndId,
        title: 'Dernière mène !',
        body: "Il reste 2 minutes, c'est la dernière mène.",
        when: twoMin,
      );
    }
  }

  Future<void> cancelRoundReminders() async {
    if (!_initialized) return;
    await _plugin.cancel(_fiveMinId);
    await _plugin.cancel(_lastEndId);
  }

  Future<void> _schedule({
    required int id,
    required String title,
    required String body,
    required DateTime when,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'round_timer',
      'Chronomètre de round',
      channelDescription: 'Alertes de fin de round pendant un tournoi',
      importance: Importance.high,
      priority: Priority.high,
    );
    const details = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );
    await _plugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(when, tz.local),
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }
}
