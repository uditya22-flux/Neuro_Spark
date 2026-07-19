import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'supabase_service.dart';

class FirebaseService {
  final SupabaseService _supabaseService;
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  FirebaseService(this._supabaseService);

  Future<void> initializeAndRegisterToken() async {
    try {
      // 1. Request notifications permissions
      final settings = await _fcm.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: true, // Crucial for sensory custom notifications overrides
        provisional: false,
        sound: false, // Set to false to adhere to low-stimulation guidelines (custom sounds used instead)
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        if (kDebugMode) {
          print('Notification permissions granted: ${settings.authorizationStatus}');
        }

        // 2. Fetch the FCM token
        String? token;
        if (Platform.isIOS || Platform.isMacOS) {
          token = await _fcm.getAPNSToken();
        }
        
        // Retrieve the standard FCM registration token
        token = await _fcm.getToken();

        if (token != null) {
          await syncTokenToSupabase(token);
        }

        // 3. Listen for token refreshes and sync
        _fcm.onTokenRefresh.listen((newToken) async {
          await syncTokenToSupabase(newToken);
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('Firebase Notification initialization error: $e');
      }
    }
  }

  Future<void> syncTokenToSupabase(String token) async {
    try {
      final client = _supabaseService.client;
      final currentUser = client.auth.currentUser;

      if (currentUser != null) {
        // Upsert into Supabase 'devices' profile map table
        await client.from('devices').upsert({
          'user_id': currentUser.id,
          'fcm_token': token,
          'device_type': Platform.isAndroid ? 'android' : 'ios',
          'updated_at': DateTime.now().toIso8601String(),
        });
        if (kDebugMode) {
          print('FCM Token synced to Supabase: $token');
        }
      } else {
        if (kDebugMode) {
          print('No authenticated user. FCM Token cache not written to DB yet.');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error syncing FCM Token to Supabase: $e');
      }
    }
  }
}

final firebaseServiceProvider = Provider<FirebaseService>((ref) {
  final supabaseService = ref.watch(supabaseServiceProvider);
  return FirebaseService(supabaseService);
});
