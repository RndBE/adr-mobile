import 'package:adr_mobile/shared/widgets/skeleton.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('SkeletonHasilPengukuranPage renders full loading layout', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: SkeletonHasilPengukuranPage())),
    );

    expect(find.byType(SkeletonHasilPengukuranPage), findsOneWidget);
    expect(find.byType(SkeletonBox), findsWidgets);
    expect(find.byType(SkeletonCircle), findsWidgets);
  });
}
