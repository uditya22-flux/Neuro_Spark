import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'supabase_service.dart';

class FirebaseService {
  final SupabaseService _supabaseService;

  FirebaseService(this._supabaseService);

  Future<void> initializeAndRegisterToken() async {
    // FCM is charter-blocked and firebase_messaging breaks web builds in this flutter version.
    // This is a no-op implementation.
    if (kDebugMode) {
      print('Firebase Notification initialization skipped (charter-blocked).');
    }
  }

  Future<void> syncTokenToSupabase(String token) async {
    // No-op
  }
}

final firebaseServiceProvider = Provider<FirebaseService>((ref) {
  final supabaseService = ref.watch(supabaseServiceProvider);
  return FirebaseService(supabaseService);
});

