import 'package:adr_mobile/features/analisa/models/analisa_sensor_history_query.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('builds RTS table history query from a date range', () {
    final query = buildSensorHistoryQuery(
      start: DateTime(2026, 5, 20),
      end: DateTime(2026, 5, 20, 23, 59, 59),
    );

    expect(query.table, 'rts');
    expect(query.from, '2026-05-20 00:00:00');
    expect(query.to, '2026-05-20 23:59:59');
  });
}
