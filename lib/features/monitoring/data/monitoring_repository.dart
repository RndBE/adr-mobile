import '../../../core/network/api_client.dart';
import '../../../core/constants/api_constants.dart';

double _doubleValue(dynamic value) =>
    value is num ? value.toDouble() : double.tryParse(value?.toString() ?? '') ?? 0;

class HeatmapCell {
  final int hour;
  final double value;
  final String label;

  const HeatmapCell({
    required this.hour,
    required this.value,
    required this.label,
  });
}

class HeatmapRow {
  final String tanggal;
  final List<HeatmapCell> cells;

  const HeatmapRow({required this.tanggal, required this.cells});
}

class MonitoringRepository {
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

  Future<List<HeatmapRow>> getHeatmapData({
    required String loggerId,
    required String table,
    required String date,
  }) async {
    try {
      final resolvedLogger = await _resolveLoggerId(loggerId);
      if (resolvedLogger == null) return [];
      final from = '$date 00:00:00';
      final to = '$date 23:59:59';
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
      return _groupByDay(list);
    } catch (_) {
      return [];
    }
  }

  List<HeatmapRow> _groupByDay(List<dynamic> raw) {
    final Map<String, List<dynamic>> byDay = {};
    for (final item in raw) {
      final map = item as Map<String, dynamic>;
      final waktu = map['waktu'] as String? ?? '';
      final day = waktu.length >= 10 ? waktu.substring(0, 10) : waktu;
      byDay.putIfAbsent(day, () => []).add(map);
    }
    return byDay.entries.map((entry) {
      final cells = List.generate(24, (h) {
        final match = entry.value.firstWhere(
          (e) {
            final w = e['waktu'] as String? ?? '';
            final hour = w.length >= 13 ? int.tryParse(w.substring(11, 13)) : null;
            return hour == h;
          },
          orElse: () => null,
        );
        final val = match != null ? _doubleValue(match['sensor1']) : -1.0;
        return HeatmapCell(
          hour: h,
          value: val,
          label: val < 0 ? '-' : val.toStringAsFixed(1),
        );
      });
      return HeatmapRow(tanggal: entry.key, cells: cells);
    }).toList()
      ..sort((a, b) => b.tanggal.compareTo(a.tanggal));
  }
}
