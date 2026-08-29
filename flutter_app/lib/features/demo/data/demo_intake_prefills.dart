import '../../../core/config/demo_config.dart';
import '../../../models/intake_models.dart';

/// Predefined hospital-demo answers — use the cheat sheet or tap "Apply demo answers".
class DemoIntakePrefills {
  DemoIntakePrefills._();

  static const clinical = ISAAClinicalProfile(
    socialRelationship: 3,
    emotionalResponsiveness: 3,
    speechCommunication: 4,
    behaviorPatterns: 2,
    sensoryAspects: 3,
    cognitiveComponent: 3,
  );

  static const parent = ParentQualitativeProfile(
    childName: DemoConfig.demoChildName,
    childAge: DemoConfig.demoChildAge,
    hyperFixationCategory: HyperFixationCategory.geometryPatterns,
    soundTriggers: ['Sudden loud chime'],
    visualTriggers: ['Busy animated backgrounds'],
    tactilePreference: TactilePreference.neutral,
  );

  /// Human-readable lines shown on the intake cheat sheet.
  static const cheatSheetLines = <String>[
    'Child name: Aarav',
    'Child age: 9',
    'Hyperfixation: Geometry & patterns',
    'Tactile preference: Neutral (picture cards, not touch-only)',
    'Sound trigger: Sudden loud chime',
    'Visual trigger: Busy animated backgrounds',
    'ISAA — Social relationship: 3',
    'ISAA — Emotional responsiveness: 3',
    'ISAA — Speech & communication: 4 (picture-first routing)',
    'ISAA — Behavior patterns: 2',
    'ISAA — Sensory aspects: 3',
    'ISAA — Cognitive component: 3',
    'Consent: Check the box → Continue',
    'Intake: Tap Continue on each step (answers already filled)',
    'Preview: Confirm & Apply Environment → strength funnel',
  ];
}
