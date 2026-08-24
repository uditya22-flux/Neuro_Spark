import 'dart:typed_data';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/intake_models.dart';
import '../../providers/game_environment_provider.dart';
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
      requestSoundPermission: false,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse details) {},
    );
  }

  /// Respects Safe Mode, deep-work windows, and intake sound-trigger blacklists.
  Future<void> showSensoryNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    final safeMode = _ref.read(safeModeProvider);
    final bundle = _ref.read(gameEnvironmentProvider);
    final config = bundle?.config;
    final soundTriggers = bundle?.parent.soundTriggers ?? const <String>[];

    final intakeRequiresSilence = config?.audioMode == AudioMode.completelyMuted ||
        soundTriggers.isNotEmpty;
    final isDeepWork = _checkDeepWorkTimeline();
    final shouldBeSilent = safeMode.isEnabled || isDeepWork || intakeRequiresSilence;
    final hapticEnabled = config?.hapticEnabled ?? false;

    final NotificationDetails platformChannelSpecifics;

    if (shouldBeSilent) {
      final androidSilent = AndroidNotificationDetails(
        'sensory_silent_channel',
        'Silent Sensory Notifications',
        channelDescription: 'Visual-only alerts when intake triggers or Safe Mode are active',
        importance: Importance.low,
        priority: Priority.low,
        playSound: false,
        enableVibration: hapticEnabled,
        vibrationPattern: hapticEnabled ? Int64List.fromList([0, 80, 120, 80]) : null,
      );

      const iosSilent = DarwinNotificationDetails(
        presentSound: false,
        presentAlert: true,
      );

      platformChannelSpecifics = NotificationDetails(
        android: androidSilent,
        iOS: iosSilent,
      );
    } else {
      final useSoftAudio = config?.audioMode != AudioMode.completelyMuted;
      final androidSoft = AndroidNotificationDetails(
        'sensory_soft_channel',
        'Sensory Friendly Alerts',
        channelDescription: 'Low-frequency accessibility notification sounds',
        importance: Importance.max,
        priority: Priority.high,
        sound: useSoftAudio ? const RawResourceAndroidNotificationSound('marimba_hum') : null,
        playSound: useSoftAudio,
        enableVibration: hapticEnabled,
        vibrationPattern: hapticEnabled ? Int64List.fromList([0, 100, 200, 100]) : null,
      );

      final iosSoft = DarwinNotificationDetails(
        sound: useSoftAudio ? 'marimba_hum.caf' : null,
        presentSound: useSoftAudio,
        presentAlert: true,
      );

      platformChannelSpecifics = NotificationDetails(
        android: androidSoft,
        iOS: iosSoft,
      );
    }

    await _notificationsPlugin.show(id, title, body, platformChannelSpecifics);
  }

  bool _checkDeepWorkTimeline() {
    final now = DateTime.now();
    return now.hour >= 14 && now.hour < 16;
  }
}

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService(ref);
});
