import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nova_modest/features/auth/data/repositories/supabase_auth_repository.dart';
import 'package:nova_modest/features/auth/domain/entities/user.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;

/// What the shopper's `profiles.avatar_url` becomes on its way to a screen.
///
/// The column holds a **path** into a private bucket, which no `Image.network`
/// can open; the repository signs it. The three cases below are the whole of
/// that step, and the last one is a constraint the user set: a link that cannot
/// be minted — expired session, no network — must leave her with the letter,
/// never an error screen or a broken-image glyph (2026-09-20).
///
/// A fake storage endpoint on loopback stands in for Supabase. No network, and
/// nothing outside this process.
void main() {
  const user = User(
    id: 'u1',
    email: 'sara@example.com',
    displayName: 'سارة',
    avatarUrl: 'u1/avatar',
  );

  late HttpServer server;
  late SupabaseClient client;
  late int status;
  final signed = <String>[];

  setUp(() async {
    signed.clear();
    status = 200;
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((req) async {
      signed.add(req.uri.path);
      req.response.statusCode = status;
      req.response.headers.contentType = ContentType.json;
      req.response.write(
        status == 200
            // The shape storage answers with: a relative URL the SDK joins to
            // the project's own.
            ? jsonEncode({'signedURL': '${req.uri.path}?token=a-signature'})
            : jsonEncode({'statusCode': '$status', 'error': 'nope'}),
      );
      await req.response.close();
    });
    client = SupabaseClient('http://127.0.0.1:${server.port}', 'anon-key');
  });

  tearDown(() async {
    await client.dispose();
    await server.close(force: true);
  });

  test('a stored path becomes a signed link the app can draw', () async {
    final result = await _Repository(client).withSignedAvatar(user);

    expect(result.avatarUrl, isNot('u1/avatar'));
    expect(result.avatarUrl, contains('token=a-signature'));
    // Signed under the caller's own folder — the shape all three storage
    // policies require.
    expect(signed.single, contains('/avatars/u1/avatar'));
  });

  test('the link is asked to live one hour', () async {
    // Long enough that it does not expire while she is looking at the screen,
    // short enough that it dies with the session it was minted in.
    final requested = <Map<String, dynamic>>[];
    await server.close(force: true);
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((req) async {
      requested.add(
        jsonDecode(await utf8.decoder.bind(req).join()) as Map<String, dynamic>,
      );
      req.response
        ..statusCode = 200
        ..headers.contentType = ContentType.json
        ..write(jsonEncode({'signedURL': '${req.uri.path}?token=t'}));
      await req.response.close();
    });
    await client.dispose();
    client = SupabaseClient('http://127.0.0.1:${server.port}', 'anon-key');

    await _Repository(client).withSignedAvatar(user);

    expect(requested.single['expiresIn'], 3600);
  });

  test('a value that is already a URL is passed through untouched', () async {
    // Nothing writes one today, but a row written by anything else must not be
    // handed to the signer, which would fail and lose a picture that worked.
    const withUrl = User(
      id: 'u1',
      email: 'sara@example.com',
      displayName: 'سارة',
      avatarUrl: 'https://cdn.example.com/face.jpg',
    );

    final result = await _Repository(client).withSignedAvatar(withUrl);

    expect(result.avatarUrl, 'https://cdn.example.com/face.jpg');
    expect(signed, isEmpty);
  });

  test('a shopper with no picture is left exactly as she was', () async {
    const none = User(id: 'u1', email: 'sara@example.com', displayName: 'سارة');

    expect(
      (await _Repository(client).withSignedAvatar(none)).avatarUrl,
      isNull,
    );
    expect(signed, isEmpty);
  });

  test('a refused signature leaves the letter, not an error', () async {
    status = 401;

    final result = await _Repository(client).withSignedAvatar(user);

    // Null is what the avatar widget falls back on. The alternative — letting
    // this throw — would take down a profile read over a decoration.
    expect(result.avatarUrl, isNull);
    expect(result.displayName, 'سارة');
  });
}

/// The live repository with its client replaced, exactly as the orders scope
/// test does. Nothing else is stubbed.
class _Repository extends SupabaseAuthRepository {
  _Repository(this._client);

  final SupabaseClient _client;

  @override
  SupabaseClient get client => _client;
}
