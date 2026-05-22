import 'package:adr_mobile/features/analisa/data/analisa_repository.dart';
import 'package:adr_mobile/features/analisa/models/analisa_summary.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('builds sensor summary from stats', () {
    final stats = SensorStats(
      min: 10,
      max: 20,
      avg: 15,
      points: [
        SensorPoint(
          waktu: DateTime(2026, 5, 21, 8),
          nilai: 12,
          low: 10,
          high: 14,
        ),
        SensorPoint(
          waktu: DateTime(2026, 5, 21, 9),
          nilai: 18,
          low: 16,
          high: 20,
        ),
      ],
    );

    final summary = SensorAnalysisSummary.fromStats(stats);

    expect(summary.latest, 18);
    expect(summary.average, 15);
    expect(summary.minimum, 10);
    expect(summary.maximum, 20);
  });

  test('builds prisma summary with delta and trend label', () {
    final summary = PrismaAnalysisSummary.fromPoints([
      PrismaPoint(waktu: DateTime(2026, 5, 21, 8), nilai: 100.125),
      PrismaPoint(waktu: DateTime(2026, 5, 21, 9), nilai: 100.325),
    ]);

    expect(summary.latest, 100.325);
    expect(summary.first, 100.125);
    expect(summary.delta, closeTo(0.2, 0.0001));
    expect(summary.trendLabel, 'Naik');
  });

  test('formats analysis values with unit', () {
    expect(formatAnalysisValue(11.6, unit: 'Volt'), '11.60 Volt');
    expect(formatAnalysisValue(null, unit: '%'), '-');
  });
}
