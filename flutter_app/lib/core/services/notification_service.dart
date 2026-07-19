import 'dart:typed_data';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/safe_mode_provider.dart';

class NotificationService {
  final Ref _ref;
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  NotificationService(this._ref);

  Future<void> initialize() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse details) {
        // Handle notification click
      },
    );
  }

  /// Evaluates current state constraints (SafeMode / Deep Work timeline)
  /// and shows a notification message using either the soft sound channel
  /// or a visual-only silent channel to prevent cognitive shock.
  Future<void> showSensoryNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    // 1. Read current SafeMode state from Riverpod
    final safeMode = _ref.read(safeModeProvider);

    // 2. Check if the current time sits inside a "Deep Work Block"
    final isDeepWork = _checkDeepWorkTimeline();

    final bool shouldBeSilent = safeMode.isEnabled || isDeepWork;

    NotificationDetails platformChannelSpecifics;

    if (shouldBeSilent) {
      // Configure silent visual banner (no audio feedback, lower importance)
      const AndroidNotificationDetails androidSilent = AndroidNotificationDetails(
        'sensory_silent_channel',
        'Silent Sensory Notifications',
        channelDescription: 'Visual alerts only for Deep Work or Safe Mode',
        importance: Importance.low,
        priority: Priority.low,
        playSound: false,
        enableVibration: false,
      );

      const DarwinNotificationDetails iosSilent = DarwinNotificationDetails(
        presentSound: false,
        presentAlert: true,
        presentBadge: true,
      );

      platformChannelSpecifics = const NotificationDetails(
        android: androidSilent,
        iOS: iosSilent,
      );
    } else {
      // Configure sensory-friendly soft notification channel
      // The audio asset 'marimba_hum' must reside in: android/app/src/main/res/raw/marimba_hum.mp3
      final AndroidNotificationDetails androidSoft = AndroidNotificationDetails(
        'sensory_soft_channel',
        'Sensory Friendly Alerts',
        channelDescription: 'Low-frequency accessibility notification sounds',
        importance: Importance.max,
        priority: Priority.high,
        sound: const RawResourceAndroidNotificationSound('marimba_hum'),
        playSound: true,
        enableVibration: true,
        vibrationPattern: Int64List.fromList([0, 100, 200, 100]), // Muted double-tap vibration
      );

      const DarwinNotificationDetails iosSoft = DarwinNotificationDetails(
        sound: 'marimba_hum.caf',
        presentSound: true,
        presentAlert: true,
        presentBadge: true,
      );

      platformChannelSpecifics = NotificationDetails(
        android: androidSoft,
        iOS: iosSoft,
      );
    }

    await _notificationsPlugin.show(
      id,
      title,
      body,
      platformChannelSpecifics,
    );
  }

  /// Helper evaluating user timeline for deep focus periods.
  /// (e.g. daily block intervals like 2:00 PM - 4:00 PM)
  bool _checkDeepWorkTimeline() {
    final now = DateTime.now();
    // Simulate deep work time constraints (e.g., between 2:00 PM and 4:00 PM, i.e., 14:00 - 16:00)
    if (now.hour >= 14 && now.hour < 16) {
      return true;
    }
    return false;
  }
}

final notificationServiceProvider = Provider<NotificationService>((ref) {
  final service = NotificationService(ref);
  return service;
});
