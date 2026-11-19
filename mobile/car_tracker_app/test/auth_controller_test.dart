import 'package:car_tracker_app/api_client.dart';
import 'package:car_tracker_app/auth_controller.dart';
import 'package:car_tracker_app/models.dart';
import 'package:car_tracker_app/token_storage.dart';
import 'package:flutter_test/flutter_test.dart';

const _user = AuthUser(id: 1, email: 'a@example.com', role: 'user');

class _MemoryStorage extends TokenStorage {
  _MemoryStorage({this.token, this.user});

  String? token;
  AuthUser? user;

  @override
  Future<String?> read() async => token;

  @override
  Future<void> write(String value) async {
    token = value;
  }

  @override
  Future<AuthUser?> readUser() async => user;

  @override
  Future<void> writeUser(AuthUser value) async {
    user = value;
  }

  @override
  Future<void> clear() async {
    token = null;
    user = null;
  }
}

class _FakeApi extends ApiClient {
  _FakeApi({
    this.meUser,
    this.meError,
    this.loginSession,
    this.loginError,
  });

  AuthUser? meUser;
  ApiException? meError;
  AuthSession? loginSession;
  ApiException? loginError;

  @override
  Future<AuthUser> fetchMe() async {
    final error = meError;
    if (error != null) {
      throw error;
    }
    return meUser!;
  }

  @override
  Future<AuthSession> login(String email, String password) async {
    final error = loginError;
    if (error != null) {
      throw error;
    }
    return loginSession!;
  }

  @override
  Future<AuthUser> register(String email, String password) async => meUser!;
}

void main() {
  test('restaurează sesiunea cu token valid', () async {
    final storage = _MemoryStorage(token: 'token');
    final auth = AuthController(
      api: _FakeApi(meUser: _user),
      storage: storage,
    );

    await auth.initialize();

    expect(auth.status, AuthStatus.authenticated);
    expect(auth.user?.email, 'a@example.com');
    expect(storage.user?.email, 'a@example.com');
  });

  test('tokenul expirat duce la ecranul de login', () async {
    final storage = _MemoryStorage(token: 'token', user: _user);
    final auth = AuthController(
      api: _FakeApi(
        meError: const ApiException('expirat', statusCode: 401),
      ),
      storage: storage,
    );

    await auth.initialize();

    expect(auth.status, AuthStatus.unauthenticated);
    expect(storage.token, isNull);
    expect(storage.user, isNull);
  });

  test('fără internet folosește utilizatorul cache-uit', () async {
    final storage = _MemoryStorage(token: 'token', user: _user);
    final auth = AuthController(
      api: _FakeApi(meError: const ApiException('offline')),
      storage: storage,
    );

    await auth.initialize();

    expect(auth.status, AuthStatus.authenticated);
    expect(auth.user?.email, 'a@example.com');
    expect(storage.token, 'token');
  });

  test('login salvează tokenul și utilizatorul', () async {
    final storage = _MemoryStorage();
    final auth = AuthController(
      api: _FakeApi(
        loginSession: const AuthSession(token: 'new-token', user: _user),
      ),
      storage: storage,
    );

    final error = await auth.login('a@example.com', 'parola12345');

    expect(error, isNull);
    expect(auth.status, AuthStatus.authenticated);
    expect(storage.token, 'new-token');
    expect(storage.user?.email, 'a@example.com');
  });

  test('eroarea de login este returnată', () async {
    final auth = AuthController(
      api: _FakeApi(
        loginError: const ApiException(
          'Email sau parolă incorecte.',
          statusCode: 401,
        ),
      ),
      storage: _MemoryStorage(),
    );

    final error = await auth.login('a@example.com', 'greșită');

    expect(error, 'Email sau parolă incorecte.');
    expect(auth.status, AuthStatus.unknown);
  });

  test('logout șterge sesiunea locală', () async {
    final storage = _MemoryStorage(token: 'token', user: _user);
    final auth = AuthController(api: _FakeApi(), storage: storage);

    await auth.logout();

    expect(auth.status, AuthStatus.unauthenticated);
    expect(storage.token, isNull);
    expect(storage.user, isNull);
  });
}
