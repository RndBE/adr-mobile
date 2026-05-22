import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/api_constants.dart';

class KontrolRepository {
  final _client = ApiClient.instance;

  Future<String?> _getActiveRtsLoggerId() async {
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

  Future<bool> verifyAccess(String code) async {
    try {
      final res = await _client.post(
        ApiConstants.kontrolVerifyAccess,
        data: {'kode_akses': code},
      );
      return res.data?['success'] == true || res.data?['valid'] == true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> startMeasurement(String code) async {
    try {
      await _client.post(ApiConstants.kontolStart, data: {'kode_akses': code});
      return true;
    } on DioException {
      return false;
    }
  }

  Future<bool> stopMeasurement() async {
    try {
      await _client.post(ApiConstants.kontrolStop);
      return true;
    } on DioException {
      return false;
    }
  }

  Future<bool> setPower(bool on) async {
    try {
      await _client.post(
        ApiConstants.kontrolPower,
        data: {'action': on ? 'on' : 'off'},
      );
      return true;
    } on DioException {
      return false;
    }
  }

  Future<Map<String, dynamic>?> getLiveStatus() async {
    try {
      final idLogger = await _getActiveRtsLoggerId();
      if (idLogger == null) return null;

      final res = await _client.get(ApiConstants.loggerDetail(idLogger));
      final detail = _client.unwrapMap(res);
      final tempData = detail?['tempData'] as List<dynamic>? ?? const [];
      return tempData.isEmpty ? null : tempData.first as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getPrismaLive() async {
    try {
      final res = await _client.get(ApiConstants.prismaData);
      final list = _client.unwrapList(res);
      return list.cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }
}
