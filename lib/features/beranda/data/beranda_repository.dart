import '../../../core/network/api_client.dart';
import '../../../core/constants/api_constants.dart';

double _doubleValue(dynamic value) => value is num
    ? value.toDouble()
    : double.tryParse(value?.toString() ?? '') ?? 0;

int _intValue(dynamic value) =>
    value is num ? value.toInt() : int.tryParse(value?.toString() ?? '') ?? 0;

class RtsTempData {
  final String waktu;
  final double humidity;
  final double battery;
  final double temperature;
  final double powerRts;
  final double tiltX;
  final double tiltY;
  final bool isLoggerOnline;
  final bool isOnline;
  final bool isRunning;

  const RtsTempData({
    required this.waktu,
    required this.humidity,
    required this.battery,
    required this.temperature,
    required this.powerRts,
    required this.tiltX,
    required this.tiltY,
    required this.isLoggerOnline,
    required this.isOnline,
    required this.isRunning,
  });

  factory RtsTempData.fromJson(Map<String, dynamic> j) {
    final waktu = j['waktu']?.toString() ?? '';
    final isRunning = _intValue(j['sensor16']) == 1;
    final isPowerOn = _intValue(j['sensor14']) == 1;
    final isLoggerOnline = _isRecent(waktu);

    return RtsTempData(
      waktu: waktu,
      humidity: _doubleValue(j['sensor20']),
      battery: _doubleValue(j['sensor21']),
      temperature: _doubleValue(j['sensor22']),
      powerRts: _doubleValue(j['sensor23']),
      tiltX: _doubleValue(j['sensor24']),
      tiltY: _doubleValue(j['sensor25']),
      isLoggerOnline: isLoggerOnline,
      isOnline: isPowerOn,
      isRunning: isRunning,
    );
  }

  static bool _isRecent(String waktu) {
    if (waktu.isEmpty) return false;
    final normalized = waktu.trim().replaceFirst(' ', 'T');
    final withoutZone = normalized
        .replaceFirst(RegExp(r'Z$'), '')
        .replaceFirst(RegExp(r'\+\d{2}:\d{2}$'), '');
    final parsed = DateTime.tryParse('$withoutZone+07:00');
    if (parsed == null) return false;
    return parsed.isAfter(DateTime.now().subtract(const Duration(hours: 1)));
  }
}

class PrismaLatest {
  final String waktu;
  final String nama;
  final double n;
  final double e;
  final double z;
  final String status;

  const PrismaLatest({
    required this.waktu,
    required this.nama,
    required this.n,
    required this.e,
    required this.z,
    required this.status,
  });

  factory PrismaLatest.fromJson(Map<String, dynamic> j) {
    final tembak = j['temp_tembak'] as Map<String, dynamic>? ?? {};
    final status = (j['status'] ?? 'success').toString().toLowerCase();
    return PrismaLatest(
      waktu: j['waktu']?.toString() ?? '',
      nama: j['nama_prisma']?.toString() ?? '',
      n: _doubleValue(tembak['N1']),
      e: _doubleValue(tembak['E1']),
      z: _doubleValue(tembak['Z1']),
      status: status == 'success' ? 'success' : status,
    );
  }
}

class LoggerInfo {
  final String idLogger;
  final String seri;
  final String sensor;
  final String statusSd;
  final String awalKontrak;
  final String akhirGaransi;
  final String loggerAktif;
  final String noSeluler;

  const LoggerInfo({
    required this.idLogger,
    required this.seri,
    required this.sensor,
    required this.statusSd,
    required this.awalKontrak,
    required this.akhirGaransi,
    required this.loggerAktif,
    required this.noSeluler,
  });

  factory LoggerInfo.fromJson(Map<String, dynamic> detail) {
    final logger = detail['logger'] is Map<String, dynamic>
        ? detail['logger'] as Map<String, dynamic>
        : detail;
    final tempData = detail['tempData'] as List<dynamic>? ?? const [];
    final latest = tempData.isNotEmpty && tempData.first is Map<String, dynamic>
        ? tempData.first as Map<String, dynamic>
        : const <String, dynamic>{};

    return LoggerInfo(
      idLogger: _valueFrom(logger, const ['id_logger', 'id']) ?? '-',
      seri:
          _valueFrom(logger, const [
            'seri',
            'no_seri',
            'serial',
            'serial_number',
            'seri_logger',
            'no_seri_logger',
          ]) ??
          '-',
      sensor:
          _valueFrom(logger, const [
            'sensor',
            'nama_sensor',
            'nama_kategori',
            'temp_data',
          ]) ??
          '-',
      statusSd:
          _statusFromSensor(latest['sensor17']) ??
          _valueFrom(logger, const ['status_sd', 'sd_status']) ??
          '-',
      awalKontrak:
          _valueFrom(logger, const [
            'awal_kontrak',
            'tgl_awal_kontrak',
            'tanggal_awal_kontrak',
            'start_kontrak',
          ]) ??
          '-',
      akhirGaransi:
          _valueFrom(logger, const [
            'akhir_garansi',
            'tgl_akhir_garansi',
            'tanggal_akhir_garansi',
            'end_garansi',
          ]) ??
          '-',
      loggerAktif:
          _activeText(
            logger['logger_aktif'] ??
                logger['is_active'] ??
                logger['aktif'] ??
                logger['status_logger'] ??
                logger['status'],
          ) ??
          (RtsTempData._isRecent(latest['waktu']?.toString() ?? '')
              ? 'Aktif'
              : 'Tidak Aktif'),
      noSeluler:
          _valueFrom(logger, const [
            'no_seluler',
            'nomor_seluler',
            'no_hp',
            'nomor_hp',
            'no_telp',
            'telepon',
            'no_sim',
            'sim_number',
          ]) ??
          '-',
    );
  }
}

String? _valueFrom(Map<String, dynamic> data, List<String> keys) {
  for (final key in keys) {
    final value = data[key];
    if (value == null) continue;
    final text = value.toString().trim();
    if (text.isNotEmpty && text.toLowerCase() != 'null') return text;
  }
  return null;
}

String? _activeText(dynamic value) {
  if (value == null) return null;
  if (value is bool) return value ? 'Aktif' : 'Tidak Aktif';
  if (value is num) return value == 1 ? 'Aktif' : 'Tidak Aktif';
  final text = value.toString().trim();
  if (text.isEmpty) return null;
  final normalized = text.toLowerCase();
  if ([
    '1',
    'true',
    'aktif',
    'active',
    'online',
    'running',
  ].contains(normalized)) {
    return 'Aktif';
  }
  if ([
    '0',
    'false',
    'nonaktif',
    'inactive',
    'offline',
    'stopped',
  ].contains(normalized)) {
    return 'Tidak Aktif';
  }
  return text;
}

String? _statusFromSensor(dynamic value) {
  if (value == null) return null;
  final intValue = _intValue(value);
  if (intValue == 1) return 'OK';
  if (intValue == 0) return 'Error';
  final text = value.toString().trim();
  return text.isEmpty ? null : text;
}

class BerandaRepository {
  final _client = ApiClient.instance;

  Future<String?> _getActiveRtsLoggerId() async {
    final res = await _client.get(ApiConstants.loggers);
    final loggers = _client.unwrapList(res);
    if (loggers.isEmpty) return null;

    Map<String, dynamic>? active;
    for (final item in loggers) {
      final logger = item as Map<String, dynamic>;
      final category = logger['nama_kategori']?.toString().toUpperCase() ?? '';
      final tempData = logger['temp_data']?.toString() ?? '';
      if (category.contains('RTS') ||
          category.contains('ADR') ||
          tempData == 'temp_rts') {
        active = logger;
        break;
      }
    }

    active ??= loggers.first as Map<String, dynamic>;
    return active['id_logger']?.toString();
  }

  Future<RtsTempData?> getRtsTempData() async {
    try {
      final idLogger = await _getActiveRtsLoggerId();
      if (idLogger == null) return null;

      final res = await _client.get(ApiConstants.loggerDetail(idLogger));
      final detail = _client.unwrapMap(res);
      final tempData = detail?['tempData'] as List<dynamic>? ?? const [];
      if (tempData.isEmpty) return null;
      return RtsTempData.fromJson(tempData.first as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<List<PrismaLatest>> getPrismaLatest() async {
    try {
      final logRes = await _client.get(
        ApiConstants.logKontrol,
        params: {'limit': 30, 'with_prisma': false},
      );
      final logs = _client.unwrapList(logRes);
      if (logs.isEmpty) return [];

      final latestLog = logs.first as Map<String, dynamic>;
      final idLog = latestLog['id_log']?.toString();
      if (idLog == null || idLog.isEmpty) return [];

      final deformasiRes = await _client.get(
        ApiConstants.deformasi,
        params: {'id_log': idLog},
      );
      final deformasi = _client.unwrapMap(deformasiRes);
      final list = deformasi?['data_pengukuran'] as List<dynamic>? ?? const [];
      return list
          .map((e) => PrismaLatest.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<String>> getAllPrismaNames() async {
    try {
      final res = await _client.get(ApiConstants.prismaData);
      final list = _client.unwrapList(res);
      return list
          .map(
            (e) => (e as Map<String, dynamic>)['id_prisma']?.toString() ?? '',
          )
          .where((name) => name.isNotEmpty)
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<LoggerInfo?> getLoggerInfo() async {
    try {
      final idLogger = await _getActiveRtsLoggerId();
      if (idLogger == null) return null;

      final res = await _client.get(ApiConstants.loggerDetail(idLogger));
      final detail = _client.unwrapMap(res);
      if (detail == null) return null;
      return LoggerInfo.fromJson(detail);
    } catch (_) {
      return null;
    }
  }
}
