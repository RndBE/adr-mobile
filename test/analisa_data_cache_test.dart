import 'package:adr_mobile/features/analisa/models/analisa_data_cache.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('builds stable sensor and prisma cache keys', () {
    expect(
      buildSensorCacheKey(
        table: 'rts',
        param: 'sensor20',
        from: '2026-05-21 00:00:00',
        to: '2026-05-21 23:59:59',
      ),
      'sensor|rts|sensor20|2026-05-21 00:00:00|2026-05-21 23:59:59',
    );

    expect(
      buildPrismaCacheKey(
        prismaName: 'P1',
        metric: 'n',
        from: DateTime(2026, 5, 21),
        to: DateTime(2026, 5, 21, 23, 59, 59),
      ),
      'prisma|P1|n|2026-05-21T00:00:00.000|2026-05-21T23:59:59.000',
    );
  });

  test('stores and removes cached analysis values', () {
    final cache = AnalisaDataCache<int>();

    cache.set('a', 12);

    expect(cache.contains('a'), isTrue);
    expect(cache.get('a'), 12);

    cache.remove('a');

    expect(cache.contains('a'), isFalse);
  });
}
