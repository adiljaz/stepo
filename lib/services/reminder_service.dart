import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../db/step_database.dart';

/// Smart hourly reminder service.
///
/// Logic: Between 9am–9pm, if the user has walked fewer than 250 steps in
/// the past hour, fire a motivational push notification.  Automatically
/// cancelled when they start walking again.
class ReminderService {
  static const _channelId = 'stepooo_reminders';
  static const _notifId = 42;

  /// Min steps per hour before we nudge the user.
  static const int kMinHourlySteps = 250;

  static final _plugin = FlutterLocalNotificationsPlugin();
  static Timer? _timer;
  static int _lastHourSteps = 0;

  static Future<void> initialise() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    await _plugin.initialize(
      const InitializationSettings(android: androidSettings),
    );
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  /// Start the periodic check (call once from background service).
  static void start(int Function() getCurrentSteps) {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(minutes: 60), (_) async {
      await _check(getCurrentSteps());
    });
  }

  static Future<void> _check(int currentSteps) async {
    final hour = DateTime.now().hour;
    // Only active between 9am–9pm
    if (hour < 9 || hour >= 21) return;

    final hourlySteps = currentSteps - _lastHourSteps;
    _lastHourSteps = currentSteps;

    if (hourlySteps < kMinHourlySteps) {
      await _send();
    } else {
      await _cancel(); // They started walking — dismiss
    }
  }

  static Future<void> _send() async {
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        'Move Reminders',
        channelDescription: 'Stepooo nudges when you\'ve been inactive',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        icon: '@mipmap/ic_launcher',
      ),
    );

    final messages = [
      ('Time to move! 🚶', 'You\'ve been sitting for a while. A short walk makes a big difference!'),
      ('Step it up! 👟', 'Under 250 steps this hour. Your body will thank you for a quick walk.'),
      ('Break time!', 'Stand up and take a few steps. Even 5 minutes of walking counts.'),
    ];
    final pick = messages[DateTime.now().minute % messages.length];

    await _plugin.show(_notifId, pick.$1, pick.$2, details);
    debugPrint('ReminderService: notification sent');
  }

  static Future<void> _cancel() => _plugin.cancel(_notifId);

  static void stop() {
    _timer?.cancel();
    _cancel();
  }
}
