import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'models.dart';

/// Tokenul JWT și datele minime ale contului sunt păstrate în stocarea
/// criptată a platformei, nu în preferințe obișnuite.
class TokenStorage {
  TokenStorage({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'auth_user';

  final FlutterSecureStorage _storage;

  Future<String?> read() => _storage.read(key: _tokenKey);

  Future<void> write(String token) =>
      _storage.write(key: _tokenKey, value: token);

  Future<AuthUser?> readUser() async {
    final raw = await _storage.read(key: _userKey);
    if (raw == null) {
      return null;
    }
    try {
      return AuthUser.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> writeUser(AuthUser user) =>
      _storage.write(key: _userKey, value: jsonEncode(user.toJson()));

  Future<void> clear() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _userKey);
  }
}
