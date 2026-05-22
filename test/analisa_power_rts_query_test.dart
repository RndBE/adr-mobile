import 'package:adr_mobile/features/analisa/models/analisa_power_rts_query.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('builds day and month power RTS queries from selected date', () {
    final date = DateTime(2026, 5, 21);

    expect(buildPowerRtsPeriodQuery(0, date).date, '2026-05-21');
    expect(buildPowerRtsPeriodQuery(0, date).period, 'hari');
    expect(buildPowerRtsPeriodQuery(1, date).date, '2026-05-21');
    expect(buildPowerRtsPeriodQuery(1, date).period, 'bulan');
  });

  test('expands custom range into inclusive daily queries', () {
    final range = DateTimeRange(
      start: DateTime(2026, 5, 20),
      end: DateTime(2026, 5, 22),
    );

    final queries = buildPowerRtsRangeQueries(range);

    expect(queries.map((query) => query.date), [
      '2026-05-20',
      '2026-05-21',
      '2026-05-22',
    ]);
    expect(queries.every((query) => query.period == 'hari'), isTrue);
  });
}
