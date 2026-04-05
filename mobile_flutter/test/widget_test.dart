import 'package:betaup_mobile/src/ui/common.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('splash screen shows bootstrap copy', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SplashScreen(),
      ),
    );

    expect(find.text('BetaUp'), findsOneWidget);
    expect(find.text('Bootstrapping session'), findsOneWidget);
  });
}
