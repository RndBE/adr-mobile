import 'package:adr_mobile/shared/widgets/skeleton.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('SkeletonBerandaPage renders dashboard loading layout', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(child: SkeletonBerandaPage()),
        ),
      ),
    );

    expect(find.byType(SkeletonBerandaPage), findsOneWidget);
    expect(find.byType(SkeletonBox), findsWidgets);
  });
}
