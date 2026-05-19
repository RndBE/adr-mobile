import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/storage/secure_storage.dart';
import '../models/user_model.dart';

class AuthRepository {
  final _client = ApiClient.instance;

  Future<UserModel> login(String username, String password) async {
    try {
      final res = await _client.post(
        ApiConstants.login,
        data: {'username': username, 'password': password},
      );
      final json = res.data as Map<String, dynamic>;
      if (json['success'] == false) {
        throw json['message'] ?? json['error'] ?? 'Login gagal';
      }
      final userJson = (json['data'] as Map<String, dynamic>?) ?? json;
      final user = UserModel.fromJson(userJson);
      await SecureStorage.saveSession(
        token: user.token,
        username: user.username,
        level: user.level,
        nama: user.nama,
      );
      return user;
    } on DioException catch (e) {
      final data = e.response?.data;
      final msg = data is Map<String, dynamic>
          ? data['message'] as String? ?? data['error'] as String?
          : null;
      throw msg ?? 'Terjadi kesalahan jaringan';
    }
  }

  Future<void> logout() => SecureStorage.clearSession();
}
