import 'package:adr_mobile/features/beranda/models/beranda_dashboard_status.dart';
import 'package:adr_mobile/features/beranda/widgets/rts_status_summary_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders RTS status and tilt values in one card', (tester) async {
    final status = BerandaDashboardStatus.fromState(
      isRtsPowered: true,
      isRunning: false,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RtsStatusSummaryCard(
            status: status,
            waktu: '2026-05-21T10:53:00.000Z',
            tiltXText: '1.25',
            tiltYText: '-0.50',
          ),
        ),
      ),
    );

    expect(find.text('Status RTS'), findsOneWidget);
    expect(find.text('RTS Siap'), findsOneWidget);
    expect(find.text('Tilt X'), findsOneWidget);
    expect(find.text('1.25'), findsOneWidget);
    expect(find.text('Tilt Y'), findsOneWidget);
    expect(find.text('-0.50'), findsOneWidget);
  });
}
