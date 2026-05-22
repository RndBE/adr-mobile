import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Beranda screen keeps dashboard focused without quick sensor cards', () {
    final source = File(
      'lib/features/beranda/screens/beranda_screen.dart',
    ).readAsStringSync();

    expect(source, isNot(contains("label: 'Humidity'")));
    expect(source, isNot(contains("label: 'Battery'")));
    expect(source, isNot(contains("label: 'Temperature'")));
    expect(source, isNot(contains("label: 'Power RTS'")));
  });
}
