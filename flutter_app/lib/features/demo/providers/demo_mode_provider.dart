import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/demo_config.dart';

/// True when the guardian is in the hospital walkthrough demo (synthetic data).
final demoModeProvider = StateProvider<bool>((ref) => DemoConfig.compileTimeEnabled);
