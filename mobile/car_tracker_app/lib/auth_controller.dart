import 'dart:async';

import 'package:flutter/foundation.dart';

import 'api_client.dart';
import 'models.dart';
import 'token_storage.dart';

enum AuthStatus { unknown, unauthenticated, authenticated }

/// Ține sesiunea curentă și restaurează tokenul la pornire.
class AuthController extends ChangeNotifier {
  AuthController({required this.api, required this.storage}) {
    api.onUnauthorized = _handleUnauthorized;
  }

  final ApiClient api;
  final TokenStorage storage;

  AuthStatus _status = AuthStatus.unknown;
  AuthUser? _user;
  bool _busy = false;
  bool _disposed = false;

  AuthStatus get status => _status;
  AuthUser? get user => _user;
  bool get isBusy => _busy;

  Future<void> initialize() async {
    final token = await storage.read();
    if (token == null || token.isEmpty) {
      _status = AuthStatus.unauthenticated;
      _notify();
      return;
    }

    api.setToken(token);
    try {
      final user = await api.fetchMe();
      await storage.writeUser(user);
      _user = user;
      _status = AuthStatus.authenticated;
    } on ApiException catch (error) {
      if (error.statusCode == 401) {
        await _clearSession();
      } else {
        // Fără internet păstrăm sesiunea și datele cache-uite.
        final cached = await storage.readUser();
        if (cached != null) {
          _user = cached;
          _status = AuthStatus.authenticated;
        } else {
          await _clearSession();
        }
      }
    } catch (_) {
      final cached = await storage.readUser();
      if (cached != null) {
        _user = cached;
        _status = AuthStatus.authenticated;
      } else {
        await _clearSession();
      }
    }
    _notify();
  }

  Future<String?> login(String email, String password) async {
    if (_busy) {
      return null;
    }
    _busy = true;
    _notify();
    try {
      final session = await api.login(email.trim(), password);
      await _applySession(session);
      return null;
    } on ApiException catch (error) {
      return error.message;
    } finally {
      _busy = false;
      _notify();
    }
  }

  Future<String?> register(String email, String password) async {
    if (_busy) {
      return null;
    }
    _busy = true;
    _notify();
    try {
      await api.register(email.trim(), password);
      final session = await api.login(email.trim(), password);
      await _applySession(session);
      return null;
    } on ApiException catch (error) {
      return error.message;
    } finally {
      _busy = false;
      _notify();
    }
  }

  Future<void> _applySession(AuthSession session) async {
    api.setToken(session.token);
    await storage.write(session.token);
    await storage.writeUser(session.user);
    _user = session.user;
    _status = AuthStatus.authenticated;
  }

  Future<void> logout() async {
    await _clearSession();
    _notify();
  }

  Future<void> _clearSession() async {
    api.setToken(null);
    await storage.clear();
    _user = null;
    _status = AuthStatus.unauthenticated;
  }

  void _handleUnauthorized() {
    if (_status == AuthStatus.authenticated) {
      unawaited(logout());
    }
  }

  void _notify() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    api.onUnauthorized = null;
    super.dispose();
  }
}
