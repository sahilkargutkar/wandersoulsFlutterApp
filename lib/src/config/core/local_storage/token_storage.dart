import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  static const _accessTokenKey = 'access_token';

  final FlutterSecureStorage _storage;
  String? _cachedAccessToken;

  TokenStorage(this._storage);

  Future<void> saveToken(String token) async {
    _cachedAccessToken = token;
    await _storage.write(key: _accessTokenKey, value: token);
  }

  Future<String?> getToken() async {
    if (_cachedAccessToken != null) return _cachedAccessToken;

    _cachedAccessToken = await _storage.read(key: _accessTokenKey);
    return _cachedAccessToken;
  }

  Future<void> clearToken() async {
    _cachedAccessToken = null;
    await _storage.delete(key: _accessTokenKey);
  }
}
