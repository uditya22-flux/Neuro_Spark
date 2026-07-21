import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/sandbox_session.dart';
import '../models/sandbox_attempt.dart';

class SandboxState {
  final SandboxSession? currentSession;
  final bool isLoading;
  final int currentDifficultyTier;
  final int totalPuzzlesSolved;
  final int streakCount;
  final String activeVerticalId;

  const SandboxState({
    this.currentSession,
    this.isLoading = false,
    this.currentDifficultyTier = 1,
    this.totalPuzzlesSolved = 0,
    this.streakCount = 0,
    this.activeVerticalId = 'calendar_genius',
  });

  SandboxState copyWith({
    SandboxSession? currentSession,
    bool? isLoading,
    int? currentDifficultyTier,
    int? totalPuzzlesSolved,
    int? streakCount,
    String? activeVerticalId,
  }) {
    return SandboxState(
      currentSession: currentSession ?? this.currentSession,
      isLoading: isLoading ?? this.isLoading,
      currentDifficultyTier: currentDifficultyTier ?? this.currentDifficultyTier,
      totalPuzzlesSolved: totalPuzzlesSolved ?? this.totalPuzzlesSolved,
      streakCount: streakCount ?? this.streakCount,
      activeVerticalId: activeVerticalId ?? this.activeVerticalId,
    );
  }
}

class SandboxController extends StateNotifier<SandboxState> {
  SandboxController() : super(const SandboxState());

  SupabaseClient? get _client {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  /// Initialize sandbox session for user and vertical.
  Future<void> startSession({
    required String userId,
    required String verticalId,
  }) async {
    state = state.copyWith(isLoading: true, activeVerticalId: verticalId);

    final client = _client;
    if (client != null) {
      try {
        final response = await client.functions.invoke(
          'sandbox-session',
          queryParameters: {'user_id': userId},
          body: {'vertical_id': verticalId},
        );
        if (response.data != null && response.data is Map) {
          final session = SandboxSession.fromJson(Map<String, dynamic>.from(response.data as Map));
          state = state.copyWith(
            currentSession: session,
            currentDifficultyTier: session.currentDifficultyTier,
            isLoading: false,
          );
          return;
        }
      } catch (e) {
        debugPrint('[SandboxController] Error starting session via API: $e. Using local session.');
      }
    }

    // Local Session Fallback
    final localSession = SandboxSession(
      sessionId: 'session_${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      verticalId: verticalId,
      startedAt: DateTime.now(),
      themeBundle: 'theme_astronomy_v3',
      currentDifficultyTier: state.currentDifficultyTier,
    );

    state = state.copyWith(
      currentSession: localSession,
      isLoading: false,
    );
  }

  /// Record puzzle attempt and quietly adjust difficulty tier.
  Future<void> recordAttempt({
    required int puzzleSeed,
    required int timeToSolveMs,
    required int correctionsCount,
  }) async {
    final session = state.currentSession;
    if (session == null) return;

    final attempt = SandboxAttempt(
      attemptId: 'attempt_${DateTime.now().millisecondsSinceEpoch}',
      sessionId: session.sessionId,
      puzzleSeed: puzzleSeed,
      timeToSolveMs: timeToSolveMs,
      correctionsCount: correctionsCount,
      difficultyTier: state.currentDifficultyTier,
      completed: true,
      occurredAt: DateTime.now(),
    );

    // Quiet difficulty adjustment rule (Section 5.1):
    // Fast clean solve (0 corrections & < 12s) quietly increases difficulty tier.
    // Struggle (>= 3 corrections or > 40s) quietly decreases difficulty tier.
    int nextTier = state.currentDifficultyTier;
    int nextStreak = state.streakCount;

    if (correctionsCount == 0 && timeToSolveMs < 12000) {
      nextStreak++;
      if (nextStreak >= 2 && nextTier < 5) {
        nextTier++;
        nextStreak = 0;
      }
    } else if (correctionsCount >= 3 || timeToSolveMs > 40000) {
      nextStreak = 0;
      if (nextTier > 1) {
        nextTier--;
      }
    }

    state = state.copyWith(
      currentDifficultyTier: nextTier,
      totalPuzzlesSolved: state.totalPuzzlesSolved + 1,
      streakCount: nextStreak,
    );

    final client = _client;
    if (client != null) {
      try {
        await client.functions.invoke(
          'sandbox-attempt',
          body: attempt.toJson(),
        );
      } catch (e) {
        debugPrint('[SandboxController] Error logging attempt via API: $e');
      }
    }
  }
}

final sandboxControllerProvider = StateNotifierProvider<SandboxController, SandboxState>((ref) {
  return SandboxController();
});
