import 'package:supabase_flutter/supabase_flutter.dart';

// ---------------------------------------------------------------------------
// Domain models
// ---------------------------------------------------------------------------

enum VerificationMethod { emailOtp, phoneOtp, digilocker }

enum VerificationStatus { pending, verified, failed }

class ParentVerification {
  const ParentVerification({
    required this.id,
    required this.method,
    required this.status,
    this.verifiedAt,
    required this.createdAt,
  });

  final String id;
  final VerificationMethod method;
  final VerificationStatus status;
  final DateTime? verifiedAt;
  final DateTime createdAt;
}

// ---------------------------------------------------------------------------
// Interface
// ---------------------------------------------------------------------------

abstract interface class ParentVerificationRepository {
  Future<ParentVerification?> getVerificationStatus();
  Future<ParentVerification> initiateEmailOtp(String email);
  Future<ParentVerification> initiatePhoneOtp(String phone);
  Future<ParentVerification> completeOtpVerification(String verificationId);
}

// ---------------------------------------------------------------------------
// Supabase implementation
// ---------------------------------------------------------------------------

class SupabaseParentVerificationRepository
    implements ParentVerificationRepository {
  SupabaseClient get _db => Supabase.instance.client;

  /// Returns the most recent verification record for the current guardian,
  /// or null if none exists.
  @override
  Future<ParentVerification?> getVerificationStatus() async {
    final userId = _requireUser();
    final response = await _db
        .from('parent_verifications')
        .select('id, method, status, verified_at, created_at')
        .eq('guardian_id', userId)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();

    if (response == null) return null;
    return _map(response as Map<String, dynamic>);
  }

  /// Inserts a pending email OTP verification record.
  /// Supabase Auth sends the OTP email separately via signInWithOtp.
  @override
  Future<ParentVerification> initiateEmailOtp(String email) async {
    return _insertPending('email_otp');
  }

  /// Inserts a pending phone OTP verification record.
  /// Supabase Auth sends the OTP SMS separately via signInWithOtp.
  @override
  Future<ParentVerification> initiatePhoneOtp(String phone) async {
    return _insertPending('phone_otp');
  }

  /// Marks the verification record as verified once the OTP is confirmed.
  /// Call this after supabase_auth_repository.verifyEmailOtp /
  /// verifyPhoneOtp succeeds.
  @override
  Future<ParentVerification> completeOtpVerification(
    String verificationId,
  ) async {
    final userId = _requireUser();
    final response = await _db
        .from('parent_verifications')
        .update({
          'status': 'verified',
          'verified_at': DateTime.now().toIso8601String(),
        })
        .eq('id', verificationId)
        .eq('guardian_id', userId)
        .select('id, method, status, verified_at, created_at')
        .single();

    return _map(response as Map<String, dynamic>);
  }

  // ------------------------------------------------------------------
  // Helpers
  // ------------------------------------------------------------------

  Future<ParentVerification> _insertPending(String method) async {
    final userId = _requireUser();
    final response = await _db
        .from('parent_verifications')
        .insert({
          'guardian_id': userId,
          'method': method,
          'status': 'pending',
        })
        .select('id, method, status, verified_at, created_at')
        .single();

    return _map(response as Map<String, dynamic>);
  }

  ParentVerification _map(Map<String, dynamic> row) {
    return ParentVerification(
      id: row['id'] as String,
      method: _parseMethod(row['method'] as String),
      status: _parseStatus(row['status'] as String),
      verifiedAt: row['verified_at'] != null
          ? DateTime.parse(row['verified_at'] as String)
          : null,
      createdAt: DateTime.parse(row['created_at'] as String),
    );
  }

  VerificationMethod _parseMethod(String raw) {
    return switch (raw) {
      'email_otp' => VerificationMethod.emailOtp,
      'phone_otp' => VerificationMethod.phoneOtp,
      'digilocker' => VerificationMethod.digilocker,
      _ => VerificationMethod.emailOtp,
    };
  }

  VerificationStatus _parseStatus(String raw) {
    return switch (raw) {
      'verified' => VerificationStatus.verified,
      'failed' => VerificationStatus.failed,
      _ => VerificationStatus.pending,
    };
  }

  String _requireUser() {
    final user = _db.auth.currentUser;
    if (user == null) throw StateError('Not authenticated');
    return user.id;
  }
}
