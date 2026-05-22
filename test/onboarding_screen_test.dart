import 'package:adr_mobile/features/onboarding/screens/onboarding_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('onboarding uses a simple illustration first layout', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: OnboardingScreen()));

    expect(find.text('ADR Monitor'), findsNothing);
    expect(find.byType(Image), findsWidgets);
    expect(find.text('Monitor Deformasi'), findsOneWidget);
    expect(
      find.text('Pantau kondisi dari sensor RTS secara real-time.'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('onboarding-bottom-panel')), findsOneWidget);
    expect(find.byKey(const Key('onboarding-copy-panel')), findsNothing);
    expect(find.text('Lewati'), findsOneWidget);
    expect(find.text('Lanjut ->'), findsOneWidget);
  });

  testWidgets('onboarding shows a different visual scene on each slide', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: OnboardingScreen()));

    expect(
      find.byKey(const Key('onboarding-visual-monitoring')),
      findsOneWidget,
    );

    await tester.drag(find.byType(PageView), const Offset(-420, 0));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('onboarding-visual-analytics')),
      findsOneWidget,
    );

    await tester.drag(find.byType(PageView), const Offset(-420, 0));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('onboarding-visual-map')), findsOneWidget);
  });

  testWidgets('onboarding keeps visual and bottom panel size stable', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: OnboardingScreen()));

    await tester.drag(find.byType(PageView), const Offset(-420, 0));
    await tester.pumpAndSettle();
    final analyticsPanelSize = tester.getSize(
      find.byKey(const Key('onboarding-bottom-panel')),
    );
    final analyticsVisualSize = tester.getSize(
      find.byKey(const Key('onboarding-visual-analytics')),
    );

    await tester.drag(find.byType(PageView), const Offset(-420, 0));
    await tester.pumpAndSettle();
    final mapPanelSize = tester.getSize(
      find.byKey(const Key('onboarding-bottom-panel')),
    );
    final mapVisualSize = tester.getSize(
      find.byKey(const Key('onboarding-visual-map')),
    );

    expect(mapPanelSize.height, analyticsPanelSize.height);
    expect(mapVisualSize.height, analyticsVisualSize.height);
  });

  testWidgets('onboarding bottom panel is substantial and reaches the bottom', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: OnboardingScreen()));

    final panelFinder = find.byKey(const Key('onboarding-bottom-panel'));
    final panelSize = tester.getSize(panelFinder);
    final panelBottom = tester.getBottomLeft(panelFinder).dy;
    final screenHeight =
        tester.view.physicalSize.height / tester.view.devicePixelRatio;

    expect(panelSize.height, greaterThanOrEqualTo(220));
    expect(panelBottom, screenHeight);
  });

  testWidgets('onboarding bottom content sits above the navigation inset', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: OnboardingScreen()));

    final panelTop = tester
        .getTopLeft(find.byKey(const Key('onboarding-bottom-panel')))
        .dy;
    final actionRowTop = tester
        .getTopLeft(find.byKey(const Key('onboarding-actions-row')))
        .dy;

    expect(actionRowTop - panelTop, lessThanOrEqualTo(150));
  });
}
