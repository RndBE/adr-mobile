import 'package:adr_mobile/features/analisa/models/analisa_month_picker.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('formats Indonesian month picker title', () {
    expect(formatAnalisaMonthTitle(year: 2026, month: 5), 'Mei 2026');
  });

  test('disables future months in the current year', () {
    final now = DateTime(2026, 5, 21);

    expect(isAnalisaMonthEnabled(year: 2026, month: 5, maxDate: now), isTrue);
    expect(isAnalisaMonthEnabled(year: 2026, month: 6, maxDate: now), isFalse);
    expect(isAnalisaMonthEnabled(year: 2025, month: 12, maxDate: now), isTrue);
  });

  test('builds selected month date from the first day of month', () {
    expect(buildAnalisaMonthDate(year: 2026, month: 2), DateTime(2026, 2));
  });
}
