import 'package:adr_mobile/features/beranda/data/beranda_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maps tilt x and tilt y from sensor24 and sensor25', () {
    final data = RtsTempData.fromJson({
      'waktu': '2026-05-21 10:30:00',
      'sensor14': 1,
      'sensor16': 0,
      'sensor20': 31.8,
      'sensor21': 12.0,
      'sensor22': 36.4,
      'sensor23': -0.03,
      'sensor24': 1.25,
      'sensor25': -2.5,
    });

    expect(data.tiltX, 1.25);
    expect(data.tiltY, -2.5);
  });
}
