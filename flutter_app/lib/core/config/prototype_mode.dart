/// Local-only presentation mode. Run with
/// `--dart-define=LOCAL_PROTOTYPE_MODE=true` to keep all preferences on the
/// device and bypass Supabase sign-in. It never calls a cloud AI service.
const localPrototypeMode = bool.fromEnvironment('LOCAL_PROTOTYPE_MODE');

/// Synthetic cloud showcase mode. Run with either
/// `--dart-define=SYNTHETIC_CLOUD_DEMO_MODE=true` or the legacy
/// `--dart-define=SYNTHETIC_DEMO_MODE=true`. It uses an anonymous Supabase
/// session, sends only fixed fictional scene settings, and never sends parent
/// free text or a real child identity to an AI provider.
const syntheticCloudDemoMode =
    bool.fromEnvironment('SYNTHETIC_CLOUD_DEMO_MODE') ||
        bool.fromEnvironment('SYNTHETIC_DEMO_MODE');

/// Backwards-compatible name used by the existing synthetic visual service.
const syntheticDemoMode = syntheticCloudDemoMode;

/// Builder-only Engine 2 showcase. This mode keeps fictional interaction
/// telemetry in memory, skips sign-in, and never calls Supabase or an LLM.
const builderShowcaseMode = bool.fromEnvironment('BUILDER_SHOWCASE_MODE');

/// Developer-only inspection overlay for a live showcase. It is deliberately
/// opt-in so the child-facing canvas remains word-free in every normal run.
///
/// Run with `--dart-define=SHOWCASE_DEBUG_OVERLAY=true` alongside the chosen
/// demo-mode flag when a reviewer needs to see the current layer and sector.
const showcaseDebugOverlay = bool.fromEnvironment('SHOWCASE_DEBUG_OVERLAY');

/// Both showcase modes demonstrate the local 30-to-1 state machine. Only
/// [syntheticCloudDemoMode] persists fictional telemetry and asks OpenAI for a
/// constrained next-puzzle specification.
const adaptiveFunnelDemoMode = builderShowcaseMode || syntheticCloudDemoMode;

/// Both modes skip the guardian sign-in UI, but only [syntheticDemoMode]
/// permits the tightly-scoped cloud demo request.
const presentationDemoMode =
    localPrototypeMode || syntheticCloudDemoMode || builderShowcaseMode;
