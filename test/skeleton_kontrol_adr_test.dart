import 'package:adr_mobile/shared/widgets/skeleton.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('SkeletonKontrolAdrPage renders control panel loading layout', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: SkeletonKontrolAdrPage())),
    );

    expect(find.byType(SkeletonKontrolAdrPage), findsOneWidget);
    expect(find.byType(SkeletonBox), findsWidgets);
    expect(find.byType(SkeletonCircle), findsWidgets);
  });
}
