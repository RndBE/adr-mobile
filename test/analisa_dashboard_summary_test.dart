import 'package:adr_mobile/features/analisa/data/analisa_repository.dart';
import 'package:adr_mobile/features/analisa/models/analisa_dashboard_summary.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('builds sensor summary from stats and latest point', () {
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

    final summary = AnalisaSensorSummary.fromStats(stats);

    expect(summary.latest, 18);
    expect(summary.avg, 15);
    expect(summary.min, 10);
    expect(summary.max, 20);
  });

  test('builds prisma summary with movement direction', () {
    final summary = AnalisaPrismaSummary.fromStats(
      PrismaStats(
        points: [
          PrismaPoint(waktu: DateTime(2026, 5, 21, 8), nilai: 100),
          PrismaPoint(waktu: DateTime(2026, 5, 21, 9), nilai: 103.5),
        ],
      ),
    );

    expect(summary.first, 100);
    expect(summary.latest, 103.5);
    expect(summary.delta, 3.5);
    expect(summary.directionLabel, 'Naik');
  });

  test('formats analysis values with unit', () {
    expect(formatAnalysisValue(11.678, unit: 'Volt'), '11.68 Volt');
    expect(formatAnalysisValue(null, unit: '%'), '-');
  });

  test('builds full hourly sensor series for previous day', () {
    final points = [
      SensorPoint(waktu: DateTime(2026, 5, 20, 3), nilai: 10, low: 9, high: 11),
    ];

    final series = buildHourlySensorSeries(
      points: points,
      day: DateTime(2026, 5, 20),
      now: DateTime(2026, 5, 21, 13),
    );

    expect(series.length, 24);
    expect(series.first.waktu.hour, 0);
    expect(series.last.waktu.hour, 23);
    expect(series[3].nilai, 10);
    expect(series[4].nilai, isNull);
  });

  test('builds hourly prisma series only until current hour for today', () {
    final series = buildHourlyPrismaSeries(
      points: [PrismaPoint(waktu: DateTime(2026, 5, 21, 2), nilai: 110.5)],
      day: DateTime(2026, 5, 21),
      now: DateTime(2026, 5, 21, 8, 30),
    );

    expect(series.length, 9);
    expect(series.first.waktu.hour, 0);
    expect(series.last.waktu.hour, 8);
    expect(series[2].nilai, 110.5);
    expect(series[8].nilai, isNull);
  });
}
