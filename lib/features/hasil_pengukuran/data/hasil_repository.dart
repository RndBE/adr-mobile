import '../../../core/network/api_client.dart';
import '../../../core/constants/api_constants.dart';

class LogKontrol {
  final String idLog;
  final String datetime;
  final String site;
  final bool isBaseline;

  const LogKontrol({
    required this.idLog,
    required this.datetime,
    required this.site,
    required this.isBaseline,
  });

  factory LogKontrol.fromJson(Map<String, dynamic> j) => LogKontrol(
        idLog: j['id_log']?.toString() ?? '',
        datetime: j['datetime'] ?? '',
        site: j['site'] ?? '',
        isBaseline: (j['r0'] as num?)?.toInt() == 1,
      );
}

class PrismaDeformasi {
  final String idPrisma;
  final String namaPrisma;
  final double n0, e0, z0;
  final double n1, e1, z1;
  final double dn, de, dz;
  final double linear;
  final String arahPergeseran;
  final String status;
  // Daily
  final double pergeseranMm;
  final double kecepatanMmd;
  final String statusPergeseran;
  final String statusKecepatan;
  final List<Map<String, dynamic>> series;

  const PrismaDeformasi({
    required this.idPrisma,
    required this.namaPrisma,
    required this.n0, required this.e0, required this.z0,
    required this.n1, required this.e1, required this.z1,
    required this.dn, required this.de, required this.dz,
    required this.linear,
    required this.arahPergeseran,
    required this.status,
    required this.pergeseranMm,
    required this.kecepatanMmd,
    required this.statusPergeseran,
    required this.statusKecepatan,
    required this.series,
  });

  static double _doubleValue(dynamic value) => value is num
      ? value.toDouble()
      : double.tryParse(value?.toString() ?? '') ?? 0;

  factory PrismaDeformasi.fromJson(Map<String, dynamic> j) {
    final t = j['temp_tembak'] as Map<String, dynamic>? ?? {};
    final d = j['daily'] as Map<String, dynamic>? ?? {};
    final sp = d['status_pergeseran'] as Map<String, dynamic>? ?? {};
    final sk = d['status_kecepatan'] as Map<String, dynamic>? ?? {};

    return PrismaDeformasi(
      idPrisma: j['id_prisma']?.toString() ?? '',
      namaPrisma: j['nama_prisma'] ?? '',
      n0: _doubleValue(t['N0']),
      e0: _doubleValue(t['E0']),
      z0: _doubleValue(t['Z0']),
      n1: _doubleValue(t['N1']),
      e1: _doubleValue(t['E1']),
      z1: _doubleValue(t['Z1']),
      dn: _doubleValue(t['DN']),
      de: _doubleValue(t['DE']),
      dz: _doubleValue(t['DZ']),
      linear: _doubleValue(t['linear']),
      arahPergeseran: t['arah_pergeseran']?.toString() ?? '-',
      status: j['status'] ?? 'unknown',
      pergeseranMm: _doubleValue(d['pergeseran_mm']),
      kecepatanMmd: _doubleValue(d['kecepatan_mmd']),
      statusPergeseran: sp['label']?.toString() ?? '-',
      statusKecepatan: sk['label']?.toString() ?? '-',
      series: (d['series'] as List<dynamic>? ?? [])
          .map((e) => e as Map<String, dynamic>)
          .toList(),
    );
  }
}

class HasilRepository {
  final _client = ApiClient.instance;

  Future<List<LogKontrol>> getLogList({int limit = 50}) async {
    try {
      final res = await _client.get(
        ApiConstants.logKontrol,
        params: {'limit': limit},
      );
      final list = _client.unwrapList(res);
      return list
          .map((e) => LogKontrol.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<PrismaDeformasi>> getDeformasi(String idLog) async {
    try {
      final res = await _client.get(
        ApiConstants.deformasi,
        params: {'id_log': idLog},
      );
      final data = _client.unwrapMap(res);
      final list = data?['data_pengukuran'] as List<dynamic>? ?? const [];
      return list
          .map((e) => PrismaDeformasi.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }
}
