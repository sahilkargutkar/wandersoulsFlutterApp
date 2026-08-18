import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  static const _accessTokenKey = 'access_token';

  final FlutterSecureStorage _storage;
  String? _cachedAccessToken;

  TokenStorage(this._storage);

  Future<void> saveToken(String token) async {
    _cachedAccessToken = token;
    try {
      await _storage.write(key: _accessTokenKey, value: token).timeout(
        const Duration(seconds: 2),
        onTimeout: () {
          debugPrint("Secure storage write timed out!");
        },
      );
    } catch (e) {
      debugPrint("Secure storage write error: $e");
    }
  }

  Future<String?> getToken() async {
    if (_cachedAccessToken != null) return _cachedAccessToken;

    try {
      _cachedAccessToken = await _storage.read(key: _accessTokenKey).timeout(
        const Duration(seconds: 2),
        onTimeout: () {
          debugPrint("Secure storage read timed out!");
          return null;
        },
      );
    } catch (e) {
      debugPrint("Secure storage read error: $e");
      return null;
    }
    return _cachedAccessToken;
  }

  Future<void> clearToken() async {
    _cachedAccessToken = null;
    try {
      await _storage.delete(key: _accessTokenKey).timeout(
        const Duration(seconds: 2),
        onTimeout: () {
          debugPrint("Secure storage delete timed out!");
        },
      );
    } catch (e) {
      debugPrint("Secure storage delete error: $e");
    }
  }
}
