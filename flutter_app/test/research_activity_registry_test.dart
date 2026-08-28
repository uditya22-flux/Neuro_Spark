import 'package:flutter_test/flutter_test.dart';
import 'package:mindbridge_app/features/strength_funnel/data/clinical_activity_bank.dart';
import 'package:mindbridge_app/features/strength_funnel/data/research_activity_registry.dart';

void main() {
  test('every RIASEC sector has at least one research-backed stem', () {
    expect(allSectorsHaveResearchStems, isTrue);
  });

  test('all registry stems have citations and construct domains', () {
    for (final stem in kResearchActivityStems) {
      expect(stem.citationShort, isNotEmpty);
      expect(stem.constructDomain, isNotEmpty);
      expect(stem.presentMomentPrompt, contains('right now'));
      expect(kResearchBibliography.containsKey(stem.citationShort), isTrue);
    }
  });

  test('bank variants resolve to registry stems', () {
    for (final variant in kClinicalActivityBank) {
      expect(variant.stem, isNotNull, reason: 'Missing stem ${variant.researchStemId}');
      expect(variant.presentMomentPrompt, isNotEmpty);
    }
  });
}
