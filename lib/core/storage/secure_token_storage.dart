import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureTokenStorage {
  SecureTokenStorage(this._storage);
  final FlutterSecureStorage _storage;

  static const _accessKey = 'yb_access_token';
  static const _refreshKey = 'yb_refresh_token';

  Future<void> save(String accessToken, String refreshToken) async {
    await _storage.write(key: _accessKey, value: accessToken);
    await _storage.write(key: _refreshKey, value: refreshToken);
  }

  Future<String?> accessToken() => _storage.read(key: _accessKey);
  Future<String?> refreshToken() => _storage.read(key: _refreshKey);

  Future<void> clear() async {
    await _storage.delete(key: _accessKey);
    await _storage.delete(key: _refreshKey);
  }
}
