import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static const _keyToken = 'auth_token';
  static const _keyUsername = 'username';
  static const _keyLevel = 'user_level';
  static const _keyNama = 'nama';

  static Future<void> saveSession({
    required String token,
    required String username,
    required String level,
    required String nama,
  }) async {
    await Future.wait([
      _storage.write(key: _keyToken, value: token),
      _storage.write(key: _keyUsername, value: username),
      _storage.write(key: _keyLevel, value: level),
      _storage.write(key: _keyNama, value: nama),
    ]);
  }

  static Future<String?> getToken() => _storage.read(key: _keyToken);
  static Future<String?> getUsername() => _storage.read(key: _keyUsername);
  static Future<String?> getLevel() => _storage.read(key: _keyLevel);
  static Future<String?> getNama() => _storage.read(key: _keyNama);

  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  static Future<void> clearSession() => _storage.deleteAll();
}
