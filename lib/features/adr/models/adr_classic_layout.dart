import 'adr_dashboard_metric.dart';

class AdrClassicMetricRow {
  final String label;
  final String value;
  final String analysisParam;

  const AdrClassicMetricRow({
    required this.label,
    required this.value,
    required this.analysisParam,
  });
}

List<AdrClassicMetricRow> buildAdrPrismaRows({
  num? northing,
  num? easting,
  num? elevation,
}) {
  return [
    AdrClassicMetricRow(
      label: 'Northing Y',
      value: _formatPrismaValue(northing),
      analysisParam: 'n',
    ),
    AdrClassicMetricRow(
      label: 'Easting X',
      value: _formatPrismaValue(easting),
      analysisParam: 'e',
    ),
    AdrClassicMetricRow(
      label: 'Elevation',
      value: _formatPrismaValue(elevation),
      analysisParam: 'z',
    ),
  ];
}

List<AdrClassicMetricRow> buildAdrLoggerRows({
  num? humidity,
  num? battery,
  num? temperature,
  num? powerRts,
}) {
  return [
    AdrClassicMetricRow(
      label: 'Humidity Logger',
      value: formatAdrMetric(humidity, unit: '%'),
      analysisParam: 'sensor20',
    ),
    AdrClassicMetricRow(
      label: 'Battery Logger',
      value: formatAdrMetric(battery, unit: 'Volt'),
      analysisParam: 'sensor21',
    ),
    AdrClassicMetricRow(
      label: 'Temperature Logger',
      value: formatAdrMetric(temperature, unit: 'C'),
      analysisParam: 'sensor22',
    ),
    AdrClassicMetricRow(
      label: 'Power RTS',
      value: formatAdrMetric(powerRts, unit: 'Volt'),
      analysisParam: 'sensor23',
    ),
  ];
}

String _formatPrismaValue(num? value) {
  if (value == null) return '000';
  return value.toDouble().toStringAsFixed(3);
}
