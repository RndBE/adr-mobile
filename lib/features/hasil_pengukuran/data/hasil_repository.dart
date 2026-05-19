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

  factory PrismaDeformasi.fromJson(Map<String, dynamic> j) {
    final t = j['temp_tembak'] as Map<String, dynamic>? ?? {};
    final d = j['daily'] as Map<String, dynamic>? ?? {};
    final sp = d['status_pergeseran'] as Map<String, dynamic>? ?? {};
    final sk = d['status_kecepatan'] as Map<String, dynamic>? ?? {};

    return PrismaDeformasi(
      idPrisma: j['id_prisma']?.toString() ?? '',
      namaPrisma: j['nama_prisma'] ?? '',
      n0: (t['N0'] as num?)?.toDouble() ?? 0,
      e0: (t['E0'] as num?)?.toDouble() ?? 0,
      z0: (t['Z0'] as num?)?.toDouble() ?? 0,
      n1: (t['N1'] as num?)?.toDouble() ?? 0,
      e1: (t['E1'] as num?)?.toDouble() ?? 0,
      z1: (t['Z1'] as num?)?.toDouble() ?? 0,
      dn: double.tryParse(t['DN']?.toString() ?? '0') ?? 0,
      de: double.tryParse(t['DE']?.toString() ?? '0') ?? 0,
      dz: double.tryParse(t['DZ']?.toString() ?? '0') ?? 0,
      linear: (t['linear'] as num?)?.toDouble() ?? 0,
      arahPergeseran: t['arah_pergeseran']?.toString() ?? '-',
      status: j['status'] ?? 'unknown',
      pergeseranMm: (d['pergeseran_mm'] as num?)?.toDouble() ?? 0,
      kecepatanMmd: (d['kecepatan_mmd'] as num?)?.toDouble() ?? 0,
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
      final list = res.data as List<dynamic>? ?? [];
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
      final list = res.data as List<dynamic>? ?? [];
      return list
          .map((e) => PrismaDeformasi.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }
}
