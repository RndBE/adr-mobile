import 'package:adr_mobile/features/adr/models/adr_classic_layout.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('buildAdrPrismaRows', () {
    test('formats prisma rows for analysis navigation', () {
      final rows = buildAdrPrismaRows(
        northing: 84071.9544,
        easting: 1106500.8822,
        elevation: 0,
      );

      expect(rows.map((row) => row.label), [
        'Northing Y',
        'Easting X',
        'Elevation',
      ]);
      expect(rows.map((row) => row.value), [
        '84071.954',
        '1106500.882',
        '0.000',
      ]);
      expect(rows.map((row) => row.analysisParam), ['n', 'e', 'z']);
    });

    test('uses placeholder values when prisma data is empty', () {
      final rows = buildAdrPrismaRows();

      expect(rows.map((row) => row.value), ['000', '000', '000']);
    });
  });

  group('buildAdrLoggerRows', () {
    test('formats logger sensor rows with two decimals and units', () {
      final rows = buildAdrLoggerRows(
        humidity: 31.756,
        battery: 11.543,
        temperature: 36.384,
        powerRts: -0.031,
      );

      expect(rows.map((row) => row.label), [
        'Humidity Logger',
        'Battery Logger',
        'Temperature Logger',
        'Power RTS',
      ]);
      expect(rows.map((row) => row.value), [
        '31.76 %',
        '11.54 Volt',
        '36.38 C',
        '-0.03 Volt',
      ]);
      expect(rows.map((row) => row.analysisParam), [
        'sensor20',
        'sensor21',
        'sensor22',
        'sensor23',
      ]);
    });

    test('uses dash when logger sensor data is empty', () {
      final rows = buildAdrLoggerRows();

      expect(rows.map((row) => row.value), ['-', '-', '-', '-']);
    });
  });
}
