import '../../../core/network/api_client.dart';
import '../../../core/constants/api_constants.dart';
import '../models/analisa_power_rts_query.dart';

double _doubleValue(dynamic value) => value is num
    ? value.toDouble()
    : double.tryParse(value?.toString() ?? '') ?? 0;

double? _optionalDouble(dynamic value) =>
    value is num ? value.toDouble() : double.tryParse(value?.toString() ?? '');

class SensorPoint {
  final DateTime waktu;
  final double nilai;
  final double low;
  final double high;
  const SensorPoint({
    required this.waktu,
    required this.nilai,
    required this.low,
    required this.high,
  });

  factory SensorPoint.fromJson(Map<String, dynamic> map, String valueKey) {
    final nilai = _doubleValue(map[valueKey] ?? map['rerata'] ?? map['avg']);
    return SensorPoint(
      waktu:
          DateTime.tryParse(map['waktu']?.toString() ?? '') ?? DateTime.now(),
      nilai: nilai,
      low: _optionalDouble(map['low'] ?? map['min']) ?? nilai,
      high: _optionalDouble(map['high'] ?? map['max']) ?? nilai,
    );
  }
}

DateTime _hourBucket(DateTime value) =>
    DateTime(value.year, value.month, value.day, value.hour);

List<SensorPoint> _aggregateSensorHourly(List<SensorPoint> points) {
  final buckets = <DateTime, List<SensorPoint>>{};
  for (final point in points) {
    buckets.putIfAbsent(_hourBucket(point.waktu), () => []).add(point);
  }

  final aggregated = buckets.entries.map((entry) {
    final values = entry.value;
    final avg =
        values.fold(0.0, (sum, point) => sum + point.nilai) / values.length;
    final low = values
        .map((point) => point.low)
        .reduce((current, next) => current < next ? current : next);
    final high = values
        .map((point) => point.high)
        .reduce((current, next) => current > next ? current : next);
    return SensorPoint(waktu: entry.key, nilai: avg, low: low, high: high);
  }).toList();

  aggregated.sort((a, b) => a.waktu.compareTo(b.waktu));
  return aggregated;
}

List<PrismaPoint> _aggregatePrismaHourly(List<PrismaPoint> points) {
  final buckets = <DateTime, List<PrismaPoint>>{};
  for (final point in points) {
    buckets.putIfAbsent(_hourBucket(point.waktu), () => []).add(point);
  }

  final aggregated = buckets.entries.map((entry) {
    final values = entry.value;
    final avg =
        values.fold(0.0, (sum, point) => sum + point.nilai) / values.length;
    return PrismaPoint(waktu: entry.key, nilai: avg);
  }).toList();

  aggregated.sort((a, b) => a.waktu.compareTo(b.waktu));
  return aggregated;
}

class SensorStats {
  final double min;
  final double max;
  final double avg;
  final List<SensorPoint> points;

  const SensorStats({
    required this.min,
    required this.max,
    required this.avg,
    required this.points,
  });
}

class PrismaPoint {
  final DateTime waktu;
  final double nilai;

  const PrismaPoint({required this.waktu, required this.nilai});
}

class PrismaStats {
  final List<PrismaPoint> points;

  const PrismaStats({required this.points});
}

class AnalisaRepository {
  final _client = ApiClient.instance;

  Future<String?> _resolveLoggerId(String fallback) async {
    if (fallback != '1') return fallback;
    final res = await _client.get(ApiConstants.loggers);
    final loggers = _client.unwrapList(res);
    for (final item in loggers) {
      final logger = item as Map<String, dynamic>;
      final category = logger['nama_kategori']?.toString().toUpperCase() ?? '';
      final tempData = logger['temp_data']?.toString() ?? '';
      if (category.contains('RTS') ||
          category.contains('ADR') ||
          tempData == 'temp_rts') {
        return logger['id_logger']?.toString();
      }
    }
    if (loggers.isNotEmpty) {
      return (loggers.first as Map<String, dynamic>)['id_logger']?.toString();
    }
    return null;
  }

  String _powerParam(String param) {
    switch (param) {
      case 'sensor20':
        return 'humidity';
      case 'sensor21':
        return 'battery';
      case 'sensor22':
        return 'temperature';
      case 'sensor23':
        return 'power_rts';
      default:
        return param;
    }
  }

  Future<SensorStats?> getSensorData({
    required String loggerId,
    required String table,
    required String param,
    required String from,
    required String to,
  }) async {
    try {
      final resolvedLogger = await _resolveLoggerId(loggerId);
      if (resolvedLogger == null) return null;
      final res = await _client.get(
        ApiConstants.sensorData,
        params: {
          'logger': resolvedLogger,
          'table': table,
          'from': from,
          'to': to,
          'limit': 5000,
        },
      );
      final list = _client.unwrapList(res);
      if (list.isEmpty) return null;

      final rawPoints = list
          .map((e) => SensorPoint.fromJson(e as Map<String, dynamic>, param))
          .toList();
      final points = _aggregateSensorHourly(rawPoints);
      return _statsFromPoints(points);
    } catch (_) {
      return null;
    }
  }

  Future<SensorStats?> getPowerRts({
    required String loggerId,
    required String param,
    required String date,
    required String period,
  }) async {
    try {
      final resolvedLogger = await _resolveLoggerId(loggerId);
      if (resolvedLogger == null) return null;
      final res = await _client.get(
        ApiConstants.powerRts,
        params: {
          'logger': resolvedLogger,
          'param': _powerParam(param),
          'date': date,
          'period': period,
        },
      );
      final list = _client.unwrapList(res);
      if (list.isEmpty) return null;

      final rawPoints = list
          .map((e) => SensorPoint.fromJson(e as Map<String, dynamic>, 'rerata'))
          .toList();
      final points = _aggregateSensorHourly(rawPoints);
      return _statsFromPoints(points);
    } catch (_) {
      return null;
    }
  }

  Future<SensorStats?> getPowerRtsQueries({
    required String loggerId,
    required String param,
    required List<PowerRtsQuery> queries,
  }) async {
    final points = <SensorPoint>[];
    for (final query in queries) {
      final stats = await getPowerRts(
        loggerId: loggerId,
        param: param,
        date: query.date,
        period: query.period,
      );
      if (stats != null) points.addAll(stats.points);
    }

    return _statsFromPoints(_aggregateSensorHourly(points));
  }

  Future<PrismaStats?> getPrismaSeries({
    required String prismaName,
    required String metric,
    required DateTime from,
    required DateTime to,
  }) async {
    try {
      final logRes = await _client.get(
        ApiConstants.logKontrol,
        params: {'limit': 120, 'with_prisma': false},
      );
      final logs = _client.unwrapList(logRes);
      if (logs.isEmpty) return null;

      final points = <PrismaPoint>[];
      for (final item in logs) {
        final log = item as Map<String, dynamic>;
        final rawTime =
            log['datetime']?.toString() ?? log['waktu']?.toString() ?? '';
        final waktu = DateTime.tryParse(rawTime.replaceFirst(' ', 'T'));
        if (waktu == null || waktu.isBefore(from) || waktu.isAfter(to)) {
          continue;
        }

        final idLog = log['id_log']?.toString();
        if (idLog == null || idLog.isEmpty) continue;

        final deformasiRes = await _client.get(
          ApiConstants.deformasi,
          params: {'id_log': idLog},
        );
        final deformasi = _client.unwrapMap(deformasiRes);
        final list =
            deformasi?['data_pengukuran'] as List<dynamic>? ?? const [];
        for (final row in list) {
          final map = row as Map<String, dynamic>;
          final name =
              map['nama_prisma']?.toString() ??
              map['id_prisma']?.toString() ??
              '';
          if (prismaName.isNotEmpty && name != prismaName) continue;

          final tembak = map['temp_tembak'] as Map<String, dynamic>? ?? {};
          final key = switch (metric) {
            'e' => 'E1',
            'z' => 'Z1',
            _ => 'N1',
          };
          points.add(
            PrismaPoint(waktu: waktu, nilai: _doubleValue(tembak[key])),
          );
          break;
        }
      }

      final aggregated = _aggregatePrismaHourly(points);
      return aggregated.isEmpty ? null : PrismaStats(points: aggregated);
    } catch (_) {
      return null;
    }
  }
}

SensorStats? _statsFromPoints(List<SensorPoint> points) {
  if (points.isEmpty) return null;

  final values = points.map((p) => p.nilai).toList();
  return SensorStats(
    min: values.reduce((a, b) => a < b ? a : b),
    max: values.reduce((a, b) => a > b ? a : b),
    avg: values.fold(0.0, (a, b) => a + b) / values.length,
    points: points,
  );
}
