import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nova_modest/core/error/failure.dart';
import 'package:nova_modest/core/error/result.dart';
import 'package:nova_modest/features/auth/data/repositories/supabase_auth_repository.dart';
import 'package:nova_modest/features/auth/domain/entities/user.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;

/// The session check, which runs once at launch and decides whether the app
/// opens at all.
///
/// Measured on a device 2026-10-11: with the host unreachable, the `profiles`
/// read threw, the error escaped `currentUser()`'s own try as an uncaught zone
/// error, `AuthBloc` emitted nothing, and the router held on the splash for
/// ever — because it waits on `AuthInitial` and `AuthCheckInProgress`. An
/// ordinary wobbly network is enough to reach that: re-measuring DNS the next
/// day, two of three resolvers needed a retry on a healthy machine.
///
/// So the contract here is: **this call always answers, and it answers in a
/// bounded time**. A network failure leaves her signed in with what the token
/// itself carries; a refusal does not.
void main() {
  const uid = 'u1';
  const email = 'sara@example.com';

  late HttpServer server;
  late SupabaseClient client;

  /// What the fake PostgREST does with the profile read.
  late void Function(HttpRequest) answer;

  /// Requests held open on purpose, so the "never answers" case stays open for
  /// the duration of the test rather than being closed by a stray GC.
  final held = <HttpRequest>[];

  setUp(() async {
    held.clear();
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((req) => answer(req));
    client = SupabaseClient('http://127.0.0.1:${server.port}', 'anon-key');
    answer = (req) async {
      req.response
        ..statusCode = 200
        ..headers.contentType = ContentType.json
        ..write(
          jsonEncode({
            'id': uid,
            'email': email,
            'display_name': 'سارة',
            'phone': '+966500000000',
            'avatar_url': null,
          }),
        );
      await req.response.close();
    };
  });

  tearDown(() async {
    await client.dispose();
    await server.close(force: true);
  });

  void answersWith(int status, Object body) {
    answer = (req) async {
      req.response
        ..statusCode = status
        ..headers.contentType = ContentType.json
        ..write(jsonEncode(body));
      await req.response.close();
    };
  }

  /// A client pointed at a port nothing is listening on: connection refused,
  /// which is the shape a dead network takes once DNS has already failed.
  Future<SupabaseClient> unreachable() async {
    final dead = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final port = dead.port;
    await dead.close();
    return SupabaseClient('http://127.0.0.1:$port', 'anon-key');
  }

  group('the profile is readable', () {
    test('answers with the full profile', () async {
      final result = await _Repository(client).currentUser();

      final user = (result as Ok<User?>).value!;
      expect(user.displayName, 'سارة');
      expect(user.phone, '+966500000000');
    });

    test('no session at all is "signed out", not a failure', () async {
      final result = await _Repository(client, uid: null).currentUser();

      expect((result as Ok<User?>).value, isNull);
    });
  });

  group('the network is gone', () {
    test('answers, rather than throwing past its own try', () async {
      final dead = await unreachable();
      addTearDown(dead.dispose);

      // The contract, bluntly: this call answers. On the device it did not —
      // it threw, nothing was emitted, and the splash stayed.
      //
      // What pins the missing `await` is the pair in "the server refuses"
      // below, not this: once a network failure falls back to the session, no
      // error travels this path at all, and only a *refusal* still has to pass
      // through `currentUser`'s catch to be caught.
      await expectLater(_Repository(dead).currentUser(), completes);
    });

    test('leaves her signed in with what the token itself carries', () async {
      final dead = await unreachable();
      addTearDown(dead.dispose);

      final result = await _Repository(dead).currentUser();

      // Not signed out: the session is valid, only unreadable. Going guest here
      // would lie to her silently — the account tab would send a signed-in
      // shopper to the sign-in screen (owner, 2026-10-12).
      final user = (result as Ok<User?>).value;
      expect(user, isNotNull);
      expect(user!.id, uid);
      expect(user.email, email);
      // The three fields that live in `profiles` are simply not known yet.
      expect(user.displayName, 'sara');
      expect(user.phone, isNull);
      expect(user.avatarUrl, isNull);
    });

    test('a read that never answers is bounded, not endless', () async {
      // The server accepts and says nothing — a stalled connection rather than
      // a refused one, which is what a captive portal or a dying signal looks
      // like. On the device this cost 59 seconds of splash.
      answer = held.add;

      final result = await _Repository(
        client,
      ).currentUser().timeout(const Duration(seconds: 20));

      expect((result as Ok<User?>).value?.id, uid);
    });
  });

  group('the server refuses', () {
    test('a policy refusal signs her out — it does not fall back', () async {
      // 42501 is what RLS answers with. The fallback is for a network that is
      // gone, never for a session the server will not accept: falling back here
      // would keep a shopper "signed in" on a token the server has rejected.
      answersWith(401, {
        'code': '42501',
        'message': 'permission denied',
        'details': null,
        'hint': null,
      });

      final result = await _Repository(client).currentUser();

      expect((result as Ok<User?>).value, isNull);
    });

    test('a server error is reported, not papered over', () async {
      answersWith(500, {
        'code': 'XX000',
        'message': 'internal error',
        'details': null,
        'hint': null,
      });

      final result = await _Repository(client).currentUser();

      expect((result as Err<User?>).failure, isA<ServerFailure>());
    });
  });
}

/// The live repository with its client and its caller replaced — the seams the
/// avatar and deletion tests already use, plus the email the token carries.
class _Repository extends SupabaseAuthRepository {
  _Repository(this._client, {this.uid = 'u1'});

  final SupabaseClient _client;
  final String? uid;

  @override
  SupabaseClient get client => _client;

  @override
  String? get currentUserId => uid;

  @override
  String? get currentEmail => uid == null ? null : 'sara@example.com';
}
