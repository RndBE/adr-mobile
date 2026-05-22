import 'package:adr_mobile/features/adr/models/adr_dashboard_metric.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('formatAdrMetric', () {
    test('formats values with two decimals and unit spacing', () {
      expect(formatAdrMetric(31.756, unit: '%'), '31.76 %');
      expect(formatAdrMetric(11.6, unit: 'Volt'), '11.60 Volt');
    });

    test('uses dash for missing values', () {
      expect(formatAdrMetric(null, unit: 'Volt'), '-');
    });
  });

  group('AdrDashboardStatus', () {
    test('normalizes healthy and warning labels', () {
      expect(AdrDashboardStatus.fromText('success').label, 'Normal');
      expect(AdrDashboardStatus.fromText('Tidak Aktif').label, 'Perlu Cek');
    });
  });
}
