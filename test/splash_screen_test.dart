import 'package:adr_mobile/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('splash uses the same product logo as login', (tester) async {
    SharedPreferences.setMockInitialValues({'isFirstTimeApp': false});

    await tester.pumpWidget(
      const MaterialApp(home: SplashScreen(startNavigation: false)),
    );

    expect(find.byType(Image), findsOneWidget);
    expect(find.byIcon(Icons.radar_rounded), findsNothing);
    expect(find.text('ADR Monitor'), findsOneWidget);
  });
}
