import '../data/analisa_repository.dart';

class SensorAnalysisSummary {
  final double latest;
  final double average;
  final double minimum;
  final double maximum;

  const SensorAnalysisSummary({
    required this.latest,
    required this.average,
    required this.minimum,
    required this.maximum,
  });

  factory SensorAnalysisSummary.fromStats(SensorStats stats) {
    return SensorAnalysisSummary(
      latest: stats.points.last.nilai,
      average: stats.avg,
      minimum: stats.min,
      maximum: stats.max,
    );
  }
}

class PrismaAnalysisSummary {
  final double latest;
  final double first;
  final double delta;

  const PrismaAnalysisSummary({
    required this.latest,
    required this.first,
    required this.delta,
  });

  factory PrismaAnalysisSummary.fromPoints(List<PrismaPoint> points) {
    final first = points.first.nilai;
    final latest = points.last.nilai;
    return PrismaAnalysisSummary(
      latest: latest,
      first: first,
      delta: latest - first,
    );
  }

  String get trendLabel {
    if (delta > 0.0005) return 'Naik';
    if (delta < -0.0005) return 'Turun';
    return 'Stabil';
  }
}

String formatAnalysisValue(
  num? value, {
  String unit = '',
  int fractionDigits = 2,
}) {
  if (value == null) return '-';
  final formatted = value.toDouble().toStringAsFixed(fractionDigits);
  if (unit.trim().isEmpty) return formatted;
  return '$formatted ${unit.trim()}';
}
