import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Guardian authentication is Supabase Auth; no bespoke verify-parent API exists.
class SupabaseAuthRepository {
  static const _androidMagicLinkCallback =
      'io.supabase.neurospark://login-callback/';

  SupabaseClient get _client => Supabase.instance.client;

  Future<void> sendEmailOtp(String email) =>
      _client.auth.signInWithOtp(
        email: email,
        // The custom Android URI reopens this app after the guardian taps the
        // Supabase magic link. On web, Supabase uses the configured Site URL.
        emailRedirectTo: kIsWeb ? null : _androidMagicLinkCallback,
      );

  Future<void> sendPhoneOtp(String phone) =>
      _client.auth.signInWithOtp(phone: phone);

  Future<AuthResponse> verifyEmailOtp(String email, String token) =>
      _client.auth.verifyOTP(type: OtpType.email, email: email, token: token);

  Future<AuthResponse> verifyPhoneOtp(String phone, String token) =>
      _client.auth.verifyOTP(type: OtpType.sms, phone: phone, token: token);

  Future<void> signOut() => _client.auth.signOut();

  Stream<AuthState> get authChanges => _client.auth.onAuthStateChange;
}
