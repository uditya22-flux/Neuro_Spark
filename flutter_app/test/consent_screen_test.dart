import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindbridge_app/features/guardian/presentation/consent_screen.dart';

void main() {
  testWidgets('guardian cannot continue until consent is confirmed', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: ConsentScreen()));

    FilledButton continueButton = tester.widget(find.byType(FilledButton));
    expect(continueButton.onPressed, isNull);

    await tester.tap(find.byType(Checkbox));
    await tester.pump();

    continueButton = tester.widget(find.byType(FilledButton));
    expect(continueButton.onPressed, isNotNull);
  });
}
