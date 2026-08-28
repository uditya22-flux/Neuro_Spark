import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/consent_repository.dart';

final consentRepositoryProvider = Provider<ConsentRepository>((ref) {
  return SupabaseConsentRepository();
});

final activeConsentVersionProvider = FutureProvider<ConsentVersion?>((ref) {
  return ref.watch(consentRepositoryProvider).loadActiveConsentVersion();
});

final hasActiveConsentProvider = FutureProvider<bool>((ref) {
  return ref.watch(consentRepositoryProvider).hasActiveConsent();
});
