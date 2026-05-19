import '../../../core/network/api_client.dart';
import '../../../core/constants/api_constants.dart';

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

  Future<List<HeatmapRow>> getHeatmapData({
    required String loggerId,
    required String table,
    required String date,
  }) async {
    try {
      final res = await _client.get(
        ApiConstants.sensorData,
        params: {'logger': loggerId, 'table': table, 'date': date},
      );
      final list = res.data as List<dynamic>? ?? [];
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
        final val = match != null
            ? (match['nilai'] as num?)?.toDouble() ?? 0.0
            : -1.0;
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
