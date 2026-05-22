import 'package:adr_mobile/features/analisa/models/analisa_range_picker.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('builds Sunday-first calendar cells for May 2026', () {
    final cells = buildAnalisaCalendarCells(year: 2026, month: 5);

    expect(cells.length, 42);
    expect(cells.take(5).every((cell) => cell == null), isTrue);
    expect(cells[5], DateTime(2026, 5));
    expect(cells[35], DateTime(2026, 5, 31));
    expect(cells.skip(36).every((cell) => cell == null), isTrue);
  });

  test('formats range pill dates', () {
    expect(formatAnalisaRangePill(DateTime(2026, 5, 5)), '2026-05-05');
  });

  test('detects start end and inside range dates', () {
    final start = DateTime(2026, 5, 5);
    final end = DateTime(2026, 5, 12);

    expect(isAnalisaRangeStart(DateTime(2026, 5, 5), start), isTrue);
    expect(isAnalisaRangeEnd(DateTime(2026, 5, 12), end), isTrue);
    expect(isAnalisaDateInsideRange(DateTime(2026, 5, 9), start, end), isTrue);
    expect(
      isAnalisaDateInsideRange(DateTime(2026, 5, 13), start, end),
      isFalse,
    );
  });
}
