import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nova_modest/core/error/failure.dart';
import 'package:nova_modest/core/error/result.dart';
import 'package:nova_modest/features/auth/data/repositories/supabase_auth_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;

/// What reaches the dashboard's `delete-account` function, and what each of its
/// answers becomes.
///
/// The function is the dashboard repository's (`supabase/functions/
/// delete-account/index.ts`), measured live on 2026-09-21. It answers
/// `{"status":"deleted"}` or `{"code", "detail"}` with a status; a fake on
/// loopback answers the same way here. Nothing leaves this process.
void main() {
  late HttpServer server;
  late SupabaseClient client;
  late int status;
  late Object? reply;
  final requests = <({String method, String path, String body})>[];

  setUp(() async {
    requests.clear();
    status = 200;
    reply = {'status': 'deleted'};
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((req) async {
      requests.add((
        method: req.method,
        path: req.uri.path,
        body: await utf8.decoder.bind(req).join(),
      ));
      req.response
        ..statusCode = status
        ..headers.contentType = ContentType.json
        ..write(jsonEncode(reply));
      await req.response.close();
    });
    client = SupabaseClient('http://127.0.0.1:${server.port}', 'anon-key');
  });

  tearDown(() async {
    await client.dispose();
    await server.close(force: true);
  });

  void answers(int code, String refusal) {
    status = code;
    reply = {'code': refusal, 'detail': 'from the fake'};
  }

  group('a deletion that succeeds', () {
    test(
      'posts an empty body to delete-account — identity is the token',
      () async {
        await _Repository(client).deleteAccount();

        final call = requests.single;
        expect(call.method, 'POST');
        expect(call.path, '/functions/v1/delete-account');
        // The function never reads identity from the body, and the app must not
        // offer one: a user id here is how one shopper deletes another.
        expect(jsonDecode(call.body), <String, dynamic>{});
      },
    );

    test('clears the session on this device, and only then answers', () async {
      final repository = _Repository(client);

      final result = await repository.deleteAccount();

      expect(result, isA<Ok<void>>());
      expect(repository.localSessionCleared, 1);
    });
  });

  group('a deletion that is refused', () {
    test('a 401 is an expired session, not a refusal', () async {
      answers(401, 'not_signed_in');
      final repository = _Repository(client);

      final result = await repository.deleteAccount();

      // UnauthorizedFailure, so the screen ends the session the way every other
      // lost session ends, instead of asking her to sign in by hand
      // (owner, 2026-09-21).
      expect((result as Err<void>).failure, isA<UnauthorizedFailure>());
      expect(repository.localSessionCleared, 0);
    });

    for (final (code, refusal) in const [
      (403, 'admin_account'),
      (502, 'avatar_delete_failed'),
      (500, 'account_delete_failed'),
      (500, 'unexpected'),
      (500, 'admin_check_failed'),
      (500, 'not_configured'),
    ]) {
      test(
        '$refusal ($code) keeps its code and leaves the session alone',
        () async {
          answers(code, refusal);
          final repository = _Repository(client);

          final result = await repository.deleteAccount();

          final failure = (result as Err<void>).failure;
          expect(failure, isA<ValidationFailure>());
          expect((failure as ValidationFailure).code, refusal);
          // The account still exists, so the session must too.
          expect(repository.localSessionCleared, 0);
        },
      );
    }

    test('an answer with no readable code invents none', () async {
      status = 500;
      reply = 'gateway exploded';

      final result = await _Repository(client).deleteAccount();

      expect((result as Err<void>).failure, isA<ServerFailure>());
    });
  });
}

/// The live repository with its client replaced, and the device-session step
/// counted rather than run — there is no keystore in a unit test, and what is
/// under test is *whether* it runs, which only the repository decides.
class _Repository extends SupabaseAuthRepository {
  _Repository(this._client);

  final SupabaseClient _client;
  int localSessionCleared = 0;

  @override
  SupabaseClient get client => _client;

  @override
  Future<void> clearLocalSession() async => localSessionCleared++;
}
