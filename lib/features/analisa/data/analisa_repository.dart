import '../../../core/network/api_client.dart';
import '../../../core/constants/api_constants.dart';

class SensorPoint {
  final DateTime waktu;
  final double nilai;
  const SensorPoint({required this.waktu, required this.nilai});
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

class AnalisaRepository {
  final _client = ApiClient.instance;

  Future<SensorStats?> getSensorData({
    required String loggerId,
    required String table,
    required String param,
    required String from,
    required String to,
  }) async {
    try {
      final res = await _client.get(
        ApiConstants.sensorData,
        params: {
          'logger': loggerId,
          'table': table,
          'param': param,
          'from': from,
          'to': to,
        },
      );
      final list = res.data as List<dynamic>? ?? [];
      if (list.isEmpty) return null;

      final points = list.map((e) {
        final map = e as Map<String, dynamic>;
        return SensorPoint(
          waktu: DateTime.tryParse(map['waktu']?.toString() ?? '') ??
              DateTime.now(),
          nilai: (map['nilai'] as num?)?.toDouble() ?? 0,
        );
      }).toList();

      final values = points.map((p) => p.nilai).toList();
      return SensorStats(
        min: values.reduce((a, b) => a < b ? a : b),
        max: values.reduce((a, b) => a > b ? a : b),
        avg: values.fold(0.0, (a, b) => a + b) / values.length,
        points: points,
      );
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
      final res = await _client.get(
        ApiConstants.powerRts,
        params: {
          'logger': loggerId,
          'param': param,
          'date': date,
          'period': period,
        },
      );
      final list = res.data as List<dynamic>? ?? [];
      if (list.isEmpty) return null;

      final points = list.map((e) {
        final map = e as Map<String, dynamic>;
        return SensorPoint(
          waktu: DateTime.tryParse(map['waktu']?.toString() ?? '') ??
              DateTime.now(),
          nilai: (map['avg'] as num?)?.toDouble() ?? 0,
        );
      }).toList();

      final values = points.map((p) => p.nilai).toList();
      return SensorStats(
        min: values.reduce((a, b) => a < b ? a : b),
        max: values.reduce((a, b) => a > b ? a : b),
        avg: values.fold(0.0, (a, b) => a + b) / values.length,
        points: points,
      );
    } catch (_) {
      return null;
    }
  }
}
