import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/consent_repository.dart';
import '../../demo/providers/demo_mode_provider.dart';
import '../../demo/providers/demo_session_providers.dart';

final consentRepositoryProvider = Provider<ConsentRepository>((ref) {
  return SupabaseConsentRepository();
});

final activeConsentVersionProvider = FutureProvider<ConsentVersion?>((ref) {
  return ref.watch(consentRepositoryProvider).loadActiveConsentVersion();
});

final hasActiveConsentProvider = FutureProvider<bool>((ref) async {
  if (ref.watch(demoModeProvider) && ref.watch(demoConsentAcceptedProvider)) {
    return true;
  }
  return ref.watch(consentRepositoryProvider).hasActiveConsent();
});
