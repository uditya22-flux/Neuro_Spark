import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindbridge_app/features/dashboard/models/neuro_profile.dart';
import 'package:mindbridge_app/features/dashboard/providers/sdui_controller.dart';
import 'package:mindbridge_app/features/dashboard/widgets/gen_ui_parser.dart';

void main() {
  group('Dynamic GenUI Engine Tests', () {
    test('generateDynamicGenUiSchema creates Space Explorer schema for Space hyper-fixation', () {
      final spaceProfile = NeuroProfile.fromJson(SduiController.mockProfiles['Profile 1: Space Explorer']!);
      final schema = SduiController.generateDynamicGenUiSchema(spaceProfile);

      expect(schema['type'], equals('column'));
      final children = schema['children'] as List;
      expect(children.isNotEmpty, isTrue);

      final headerNode = children.firstWhere((c) => c['type'] == 'mascot_header');
      expect(headerNode['title'], contains('Leo'));
      expect(headerNode['mascot'], equals('rocket'));
      expect(headerNode['theme_label'], contains('Space Explorer'));

      final challengeNode = children.firstWhere((c) => c['type'] == 'challenge_card');
      expect(challengeNode['target_challenge'], contains('Orbital'));

      final breathingNode = children.firstWhere((c) => c['type'] == 'breathing_engine');
      expect(breathingNode['location'], contains('space_station'));
    });

    test('generateDynamicGenUiSchema creates Dinosaur Excavator schema for Dinosaur hyper-fixation', () {
      final dinoProfile = NeuroProfile.fromJson(SduiController.mockProfiles['Profile 2: Dinosaur Paleontology']!);
      final schema = SduiController.generateDynamicGenUiSchema(dinoProfile);

      final children = schema['children'] as List;
      final headerNode = children.firstWhere((c) => c['type'] == 'mascot_header');
      expect(headerNode['mascot'], equals('dinosaur'));
      expect(headerNode['theme_label'], contains('Dinosaur Excavator'));

      final challengeNode = children.firstWhere((c) => c['type'] == 'challenge_card');
      expect(challengeNode['target_challenge'], contains('Fossil Dig'));
    });

    test('generateDynamicGenUiSchema creates Train Conductor schema for Train hyper-fixation', () {
      final trainProfile = NeuroProfile.fromJson(SduiController.mockProfiles['Profile 3: Train Conductor']!);
      final schema = SduiController.generateDynamicGenUiSchema(trainProfile);

      final children = schema['children'] as List;
      final headerNode = children.firstWhere((c) => c['type'] == 'mascot_header');
      expect(headerNode['mascot'], equals('train'));
      expect(headerNode['theme_label'], contains('Train Conductor'));

      final challengeNode = children.firstWhere((c) => c['type'] == 'challenge_card');
      expect(challengeNode['target_challenge'], contains('Metro Routing'));
    });

    testWidgets('GenUiParser renders dynamic mascot_header, challenge_card, and breathing_engine widgets', (WidgetTester tester) async {
      final mockSchema = {
        'type': 'column',
        'children': [
          {
            'type': 'mascot_header',
            'title': 'Hello, Jordan!',
            'subtitle': 'Space explorer personalized UI',
            'mascot': 'rocket',
            'theme_label': 'Space Explorer Theme Active',
          },
          {
            'type': 'challenge_card',
            'title': 'Jordan\'s Talent Growth',
            'target_challenge': 'Orbital Space Path',
            'icon': 'rocket',
            'strengths': ['Pattern Recognition'],
          },
          {
            'type': 'breathing_engine',
            'technique': '4-4-4 Breathing Engine',
            'location': 'Hill Palace Gardens',
            'audio_anchor': 'Soft Rain',
          },
        ],
      };

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: GenUiParser(schema: mockSchema),
            ),
          ),
        ),
      );

      expect(find.text('Hello, Jordan!'), findsOneWidget);
      expect(find.text('Space Explorer Theme Active'), findsOneWidget);
      expect(find.text('Orbital Space Path'), findsOneWidget);
      expect(find.text('Hill Palace Gardens'), findsOneWidget);
      expect(find.text('Pattern Recognition'), findsOneWidget);
    });
  });
}
