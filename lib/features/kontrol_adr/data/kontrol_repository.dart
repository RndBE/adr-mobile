import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/api_constants.dart';

class KontrolRepository {
  final _client = ApiClient.instance;

  Future<bool> verifyAccess(String code) async {
    try {
      final res = await _client.post(
        ApiConstants.kontrolVerifyAccess,
        data: {'code': code},
      );
      return res.data?['valid'] == true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> startMeasurement(String code) async {
    try {
      await _client.post(ApiConstants.kontolStart, data: {'code': code});
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
      await _client.post(ApiConstants.kontrolPower, data: {'on': on});
      return true;
    } on DioException {
      return false;
    }
  }

  Future<Map<String, dynamic>?> getLiveStatus() async {
    try {
      final res = await _client.get(ApiConstants.dataTerakhir);
      return res.data as Map<String, dynamic>?;
    } catch (_) {
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getPrismaLive() async {
    try {
      final res = await _client.get(ApiConstants.prismaData);
      final list = res.data as List<dynamic>? ?? [];
      return list.cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }
}
