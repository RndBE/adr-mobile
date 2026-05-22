import '../data/analisa_repository.dart';

class AnalisaSensorSummary {
  final double latest;
  final double avg;
  final double min;
  final double max;

  const AnalisaSensorSummary({
    required this.latest,
    required this.avg,
    required this.min,
    required this.max,
  });

  factory AnalisaSensorSummary.fromStats(SensorStats stats) {
    final latest = stats.points.isEmpty ? stats.avg : stats.points.last.nilai;
    return AnalisaSensorSummary(
      latest: latest,
      avg: stats.avg,
      min: stats.min,
      max: stats.max,
    );
  }
}

class AnalisaPrismaSummary {
  final double first;
  final double latest;
  final double delta;

  const AnalisaPrismaSummary({
    required this.first,
    required this.latest,
    required this.delta,
  });

  factory AnalisaPrismaSummary.fromStats(PrismaStats stats) {
    final first = stats.points.isEmpty ? 0.0 : stats.points.first.nilai;
    final latest = stats.points.isEmpty ? 0.0 : stats.points.last.nilai;
    return AnalisaPrismaSummary(
      first: first,
      latest: latest,
      delta: latest - first,
    );
  }

  String get directionLabel {
    if (delta.abs() < 0.0005) return 'Stabil';
    return delta > 0 ? 'Naik' : 'Turun';
  }
}

class HourlySensorPoint {
  final DateTime waktu;
  final double? nilai;
  final double? low;
  final double? high;

  const HourlySensorPoint({
    required this.waktu,
    required this.nilai,
    required this.low,
    required this.high,
  });

  bool get hasData => nilai != null;
}

class HourlyPrismaPoint {
  final DateTime waktu;
  final double? nilai;

  const HourlyPrismaPoint({required this.waktu, required this.nilai});

  bool get hasData => nilai != null;
}

List<HourlySensorPoint> buildHourlySensorSeries({
  required List<SensorPoint> points,
  required DateTime day,
  DateTime? now,
}) {
  final normalizedDay = DateTime(day.year, day.month, day.day);
  return buildHourlySensorRangeSeries(
    points: points,
    start: normalizedDay,
    end: normalizedDay,
    now: now,
  );
}

List<HourlySensorPoint> buildHourlySensorRangeSeries({
  required List<SensorPoint> points,
  required DateTime start,
  required DateTime end,
  DateTime? now,
}) {
  final startHour = DateTime(start.year, start.month, start.day);
  final endHour = _lastDateTimeHourFor(end, now ?? DateTime.now());
  final byHour = {
    for (final point in points)
      DateTime(
        point.waktu.year,
        point.waktu.month,
        point.waktu.day,
        point.waktu.hour,
      ): point,
  };
  final hourCount = endHour.difference(startHour).inHours + 1;

  return List.generate(hourCount < 0 ? 0 : hourCount, (index) {
    final waktu = startHour.add(Duration(hours: index));
    final point = byHour[waktu];
    return HourlySensorPoint(
      waktu: waktu,
      nilai: point?.nilai,
      low: point?.low,
      high: point?.high,
    );
  });
}

List<HourlyPrismaPoint> buildHourlyPrismaSeries({
  required List<PrismaPoint> points,
  required DateTime day,
  DateTime? now,
}) {
  final normalizedDay = DateTime(day.year, day.month, day.day);
  return buildHourlyPrismaRangeSeries(
    points: points,
    start: normalizedDay,
    end: normalizedDay,
    now: now,
  );
}

List<HourlyPrismaPoint> buildHourlyPrismaRangeSeries({
  required List<PrismaPoint> points,
  required DateTime start,
  required DateTime end,
  DateTime? now,
}) {
  final startHour = DateTime(start.year, start.month, start.day);
  final endHour = _lastDateTimeHourFor(end, now ?? DateTime.now());
  final byHour = {
    for (final point in points)
      DateTime(
        point.waktu.year,
        point.waktu.month,
        point.waktu.day,
        point.waktu.hour,
      ): point,
  };
  final hourCount = endHour.difference(startHour).inHours + 1;

  return List.generate(hourCount < 0 ? 0 : hourCount, (index) {
    final waktu = startHour.add(Duration(hours: index));
    final point = byHour[waktu];
    return HourlyPrismaPoint(waktu: waktu, nilai: point?.nilai);
  });
}

DateTime _lastDateTimeHourFor(DateTime day, DateTime now) {
  final normalizedDay = DateTime(day.year, day.month, day.day);
  final today = DateTime(now.year, now.month, now.day);
  if (normalizedDay == today) {
    return DateTime(today.year, today.month, today.day, now.hour);
  }
  if (normalizedDay.isAfter(today)) {
    return DateTime(today.year, today.month, today.day, now.hour);
  }
  return DateTime(
    normalizedDay.year,
    normalizedDay.month,
    normalizedDay.day,
    23,
  );
}

String formatAnalysisValue(num? value, {String unit = '', int digits = 2}) {
  if (value == null) return '-';
  final formatted = value.toDouble().toStringAsFixed(digits);
  if (unit.trim().isEmpty) return formatted;
  return '$formatted ${unit.trim()}';
}
