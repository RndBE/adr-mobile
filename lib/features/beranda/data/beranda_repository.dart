import '../../../core/network/api_client.dart';
import '../../../core/constants/api_constants.dart';

class RtsTempData {
  final String waktu;
  final double humidity;
  final double battery;
  final double temperature;
  final double powerRts;
  final bool isOnline;
  final bool isRunning;

  const RtsTempData({
    required this.waktu,
    required this.humidity,
    required this.battery,
    required this.temperature,
    required this.powerRts,
    required this.isOnline,
    required this.isRunning,
  });

  factory RtsTempData.fromJson(Map<String, dynamic> j) => RtsTempData(
        waktu: j['waktu'] ?? '',
        humidity: (j['sensor20'] as num?)?.toDouble() ?? 0,
        battery: (j['sensor21'] as num?)?.toDouble() ?? 0,
        temperature: (j['sensor22'] as num?)?.toDouble() ?? 0,
        powerRts: (j['sensor23'] as num?)?.toDouble() ?? 0,
        isOnline: (j['sensor14'] as num?)?.toInt() == 1,
        isRunning: (j['sensor16'] as num?)?.toInt() == 1,
      );
}

class PrismaLatest {
  final String nama;
  final double n;
  final double e;
  final double z;
  final String status;

  const PrismaLatest({
    required this.nama,
    required this.n,
    required this.e,
    required this.z,
    required this.status,
  });

  factory PrismaLatest.fromJson(Map<String, dynamic> j) {
    final tembak = j['temp_tembak'] as Map<String, dynamic>? ?? {};
    return PrismaLatest(
      nama: j['nama_prisma'] ?? '',
      n: (tembak['N1'] as num?)?.toDouble() ?? 0,
      e: (tembak['E1'] as num?)?.toDouble() ?? 0,
      z: (tembak['Z1'] as num?)?.toDouble() ?? 0,
      status: j['status'] ?? 'unknown',
    );
  }
}

class BerandaRepository {
  final _client = ApiClient.instance;

  Future<RtsTempData?> getRtsTempData() async {
    try {
      final res = await _client.get(ApiConstants.dataTerakhir);
      final data = res.data;
      if (data == null) return null;
      return RtsTempData.fromJson(data as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<List<PrismaLatest>> getPrismaLatest() async {
    try {
      final res = await _client.get(ApiConstants.prismaData);
      final list = res.data as List<dynamic>? ?? [];
      return list
          .map((e) => PrismaLatest.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }
}
