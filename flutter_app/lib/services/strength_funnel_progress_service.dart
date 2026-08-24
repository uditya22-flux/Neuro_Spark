import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../features/strength_funnel/models/strength_funnel_progress.dart';

/// Persists strength funnel session progress locally for resume between layers.
class StrengthFunnelProgressService {
  static const _progressKey = 'mindbridge_strength_funnel_progress_v1';

  Future<void> save(StrengthFunnelProgress progress) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_progressKey, jsonEncode(progress.toJson()));
    debugPrint(
      '[StrengthFunnelProgress] Saved layer ${progress.layerNumber} '
      '(awaitingNext=${progress.awaitingNextLayer}).',
    );
  }

  Future<StrengthFunnelProgress?> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_progressKey);
      if (raw == null || raw.isEmpty) return null;
      return StrengthFunnelProgress.fromJson(
        Map<String, dynamic>.from(jsonDecode(raw) as Map),
      );
    } catch (e) {
      debugPrint('[StrengthFunnelProgress] load failed: $e');
      return null;
    }
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_progressKey);
  }
}

StrengthFunnelProgress decodeStrengthFunnelProgressJson(String raw) {
  return StrengthFunnelProgress.fromJson(
    Map<String, dynamic>.from(jsonDecode(raw) as Map),
  );
}
