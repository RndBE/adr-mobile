import 'package:adr_mobile/shared/widgets/dashboard_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('MetricTile shows label value and unit', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: MetricTile(
            label: 'Battery',
            value: '12.4',
            unit: 'Volt',
            icon: Icons.battery_full_rounded,
            color: Colors.green,
          ),
        ),
      ),
    );

    expect(find.text('Battery'), findsOneWidget);
    expect(find.text('12.4'), findsOneWidget);
    expect(find.text('Volt'), findsOneWidget);
  });

  testWidgets('MenuIconBadge shows icon and navigation hint', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: MenuIconBadge(
            icon: Icons.query_stats_rounded,
            color: Colors.blue,
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.query_stats_rounded), findsOneWidget);
    expect(find.byIcon(Icons.arrow_forward_ios_rounded), findsOneWidget);
  });
}
