import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Local consent acceptance for hospital demo (no Supabase auth required).
final demoConsentAcceptedProvider = StateProvider<bool>((ref) => false);
