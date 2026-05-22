import 'package:adr_mobile/features/beranda/models/beranda_metric_formatter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('formats beranda sensor cards with two decimals', () {
    expect(formatBerandaSensorMetric(31.7), '31.70');
    expect(formatBerandaSensorMetric(11.735), '11.73');
    expect(formatBerandaSensorMetric(36), '36.00');
    expect(formatBerandaSensorMetric(-0.0), '-0.00');
  });
}
