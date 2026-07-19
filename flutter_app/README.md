# MindBridge Flutter client

This is the child and guardian client skeleton for the private beta.

## Safety boundary

- `features/child/domain/child_experience.dart` is the only child experience DTO. It contains sensory configuration, puzzle payloads, and neutral celebration text only.
- `features/guardian/domain/adult_exploratory_note.dart` is guardian-only. Play routes must never import it.
- The client gives children a visible pause, stop, and skip path. No scores, error states, re-engagement prompts, or notifications are included.

## Local development

Run `flutter pub get`, then `flutter test` and `flutter run`. The API repositories are intentionally typed integration seams; endpoint response mappers are completed when the backend OpenAPI contract is available.
