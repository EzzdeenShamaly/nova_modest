import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nova_modest/core/error/failure.dart';
import 'package:nova_modest/core/error/result.dart';
import 'package:nova_modest/features/auth/data/repositories/supabase_auth_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;

/// Deleting an account is one of two requests a shopper cannot walk away from
/// (blocker 8): while it is in flight the account tab has nothing else on it.
/// Everywhere else a hung read still leaves the back button working.
///
/// **A ceiling cuts the waiting, not the work.** The function does not stop
/// because we stopped listening — the account may well be deleted after we give
/// up. So the failure may not claim otherwise: `NetworkFailure` renders as "no
/// internet connection", which would be the app telling her that her account is
/// still there when it may be gone. That is the worst sentence available to it.
void main() {
  late HttpServer server;
  late SupabaseClient client;

  /// Requests accepted and deliberately never answered. A refused connection
  /// fails fast by itself and would prove nothing about a ceiling.
  final held = <HttpRequest>[];

  /// What the fake endpoint does. Swapped per test rather than re-listening:
  /// an `HttpServer` is a single-subscription stream, so a second `listen`
  /// throws.
  late void Function(HttpRequest) answer;

  setUp(() async {
    held.clear();
    answer = held.add;
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((req) => answer(req));
    client = SupabaseClient('http://127.0.0.1:${server.port}', 'anon-key');
  });

  /// Answers every request with [status] and [body], for the one case that
  /// needs the server to refuse rather than to stall.
  void answersWith(int status, Object body) {
    answer = (req) async {
      req.response
        ..statusCode = status
        ..headers.contentType = ContentType.json
        ..write(jsonEncode(body));
      await req.response.close();
    };
  }

  tearDown(() async {
    await client.dispose();
    await server.close(force: true);
  });

  test('answers instead of hanging', () async {
    final result = await _Repository(client).deleteAccount();

    expect(result, isA<Err<void>>());
  });

  test('says it does not know, rather than that it failed', () async {
    final result = await _Repository(client).deleteAccount();

    final failure = (result as Err<void>).failure;
    expect(failure, isA<ValidationFailure>());
    expect((failure as ValidationFailure).code, 'account_delete_timeout');
  });

  test('does not clear the session on a timeout', () async {
    final repository = _Repository(client);

    await repository.deleteAccount();

    // Clearing it would sign her out of an account that may still exist, and
    // leave her needing a fresh code to get back in. The session is cleared on
    // a known success; on the 401 a later attempt would end it anyway.
    expect(repository.sessionCleared, isFalse);
  });

  group('the sign-in code request', () {
    /// `signInWithOtp` builds a PKCE challenge **before** it sends anything, and
    /// a bare `SupabaseClient` has no async storage to build it with — it throws
    /// an `AssertionError` in 3 ms with zero requests sent (measured
    /// 2026-10-12). Without this stub the test never reaches the network and
    /// proves nothing about a ceiling.
    SupabaseClient withStorage() => SupabaseClient(
      'http://127.0.0.1:${server.port}',
      'anon-key',
      authOptions: const AuthClientOptions(pkceAsyncStorage: _MemoryStorage()),
    );

    test('answers instead of hanging', () async {
      final client = withStorage();
      addTearDown(client.dispose);

      final result = await _Repository(
        client,
      ).requestEmailCode('s@example.com');

      expect(result, isA<Err<void>>());
    });

    test('says it does not know, rather than blaming the connection', () async {
      final client = withStorage();
      addTearDown(client.dispose);

      final result = await _Repository(
        client,
      ).requestEmailCode('s@example.com');

      // GoTrue sends the email before it answers, so a lost reply does not mean
      // a lost code: it may be in her inbox already. "No internet connection"
      // would send her looking for a fault that is not there.
      final failure = (result as Err<void>).failure;
      expect(failure, isA<ValidationFailure>());
      expect((failure as ValidationFailure).code, 'email_code_timeout');
    });

    test('a refusal is still swallowed, because that oracle is real', () async {
      // **The two rules are orthogonal, and this is what keeps them so.** The
      // always-`Ok` contract exists to stop an attacker telling a registered
      // address from an unregistered one; a *refusal* can carry that
      // difference, so it is still swallowed. A timeout cannot — it falls the
      // same way for both — which is why the branch above may report it.
      answersWith(400, {'error_code': 'validation_failed'});
      final client = withStorage();
      addTearDown(client.dispose);

      final result = await _Repository(
        client,
      ).requestEmailCode('s@example.com');

      expect(result, isA<Ok<void>>());
    });
  });

  test('the ceiling is twenty seconds in a real build', () {
    // Pinned because the value is a judgement, not an implementation detail: a
    // live deletion measured at over five seconds on a degraded link
    // (2026-10-12), and a ceiling near that reports failure on success.
    expect(
      SupabaseAuthRepository().interactiveTimeout,
      const Duration(seconds: 20),
    );
  });
}

/// Enough storage for the PKCE challenge, held in memory for one test.
class _MemoryStorage extends GotrueAsyncStorage {
  const _MemoryStorage();

  static final Map<String, String> _items = {};

  @override
  Future<String?> getItem({required String key}) async => _items[key];

  @override
  Future<void> setItem({required String key, required String value}) async =>
      _items[key] = value;

  @override
  Future<void> removeItem({required String key}) async => _items.remove(key);
}

/// The live repository with its client replaced and its ceiling shortened, so
/// the suite does not spend twenty seconds proving a twenty-second bound. The
/// value itself is pinned by the test above.
class _Repository extends SupabaseAuthRepository {
  _Repository(this._client);

  final SupabaseClient _client;

  bool sessionCleared = false;

  @override
  SupabaseClient get client => _client;

  @override
  Duration get interactiveTimeout => const Duration(milliseconds: 300);

  @override
  Future<void> clearLocalSession() async => sessionCleared = true;
}
