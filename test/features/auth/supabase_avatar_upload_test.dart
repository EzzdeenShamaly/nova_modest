import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:nova_modest/core/error/failure.dart';
import 'package:nova_modest/core/error/result.dart';
import 'package:nova_modest/features/auth/data/repositories/supabase_auth_repository.dart';
import 'package:nova_modest/features/auth/domain/entities/user.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;

/// The write itself: what actually reaches storage and `profiles`.
///
/// Every assertion here is a rule the live project enforces and a unit test
/// cannot otherwise reach — the object's path, the content type, the overwrite,
/// and the fact that the column ends up holding a path rather than a link. A
/// fake Supabase on loopback answers; nothing leaves this process.
void main() {
  const uid = 'u1';

  final png = Uint8List.fromList([
    0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a, //
    ...List.filled(64, 0),
  ]);

  late HttpServer server;
  late SupabaseClient client;
  final calls = <_Call>[];

  setUp(() async {
    calls.clear();
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((req) async {
      final body = await _bytesOf(req);
      calls.add(
        _Call(
          method: req.method,
          path: req.uri.path,
          query: req.uri.query,
          headers: {
            for (final name in const ['content-type', 'x-upsert'])
              name: req.headers.value(name),
          },
          body: body,
        ),
      );

      req.response.headers.contentType = ContentType.json;
      if (req.uri.path.contains('/storage/v1/object/sign/')) {
        req.response.write(
          jsonEncode({'signedURL': '${req.uri.path}?token=a-signature'}),
        );
      } else if (req.uri.path.contains('/storage/')) {
        req.response.write(jsonEncode({'Key': 'avatars/$uid/avatar'}));
      } else if (req.method == 'GET') {
        // The profile as it stands after the write.
        req.response.write(
          jsonEncode({
            'id': uid,
            'email': 'sara@example.com',
            'display_name': 'سارة',
            'phone': null,
            'avatar_url': '$uid/avatar',
          }),
        );
      } else {
        req.response.write(jsonEncode(<dynamic>[]));
      }
      await req.response.close();
    });
    client = SupabaseClient('http://127.0.0.1:${server.port}', 'anon-key');
  });

  tearDown(() async {
    await client.dispose();
    await server.close(force: true);
  });

  _Call callTo(String fragment) =>
      calls.firstWhere((c) => c.path.contains(fragment));

  group('a picture that is accepted', () {
    test('lands at <uid>/avatar, which is what the policies require', () async {
      await _Repository(client, uid).uploadAvatar(png);

      // All three storage policies read `(storage.foldername(name))[1] =
      // auth.uid()`. Any other shape is refused as 42501 — an authorisation
      // failure that would reach the shopper as something unrelated.
      expect(callTo('/storage/').path, endsWith('/avatars/$uid/avatar'));
    });

    test('declares the content type the bytes say, not a file name', () async {
      await _Repository(client, uid).uploadAvatar(png);

      // The SDK posts the object as multipart, so the type travels inside the
      // part rather than on the request. The bucket lists png, jpeg and webp
      // and checks exactly this value.
      final upload = callTo('/storage/');
      expect(upload.headers['content-type'], startsWith('multipart/form-data'));
      expect(
        utf8.decode(upload.body, allowMalformed: true),
        contains('image/png'),
      );
    });

    test('overwrites the previous one instead of adding another', () async {
      await _Repository(client, uid).uploadAvatar(png);

      // There is no DELETE policy on this bucket, so upsert is the only way a
      // picture can be replaced. Without it the second upload fails with
      // "already exists" and the shopper is stuck with her first photograph.
      expect(callTo('/storage/').headers['x-upsert'], 'true');
    });

    test('stores the path in profiles, not a link that will expire', () async {
      await _Repository(client, uid).uploadAvatar(png);

      final write = calls.firstWhere((c) => c.method == 'PATCH');
      expect(jsonDecode(utf8.decode(write.body)), {
        'avatar_url': '$uid/avatar',
      });
      expect(write.query, contains('id=eq.$uid'));
    });

    test('answers with the user, its picture already signed', () async {
      final result = await _Repository(client, uid).uploadAvatar(png);

      final user = (result as Ok<User>).value;
      expect(user.avatarUrl, contains('token=a-signature'));
      expect(user.displayName, 'سارة');
    });
  });

  group('a picture that is refused', () {
    test('never reaches the network, and says which rule it broke', () async {
      // A PDF the device happened to call "photo.jpg".
      final notAnImage = Uint8List.fromList([0x25, 0x50, 0x44, 0x46, 0x2d]);

      final result = await _Repository(client, uid).uploadAvatar(notAnImage);

      final failure = (result as Err<User>).failure as ValidationFailure;
      expect(failure.code, 'avatar_unsupported_format');
      expect(calls, isEmpty, reason: 'refused before anything was sent');
    });

    test('too large is refused here rather than as a bare 413', () async {
      // The bucket's ceiling is 2 MiB, read live on 2026-09-20.
      final huge = Uint8List(2 * 1024 * 1024 + 1)
        ..setRange(0, 3, const [0xff, 0xd8, 0xff]);

      final result = await _Repository(client, uid).uploadAvatar(huge);

      expect((result as Err<User>).failure, isA<ValidationFailure>());
      expect(((result).failure as ValidationFailure).code, 'avatar_too_large');
      expect(calls, isEmpty);
    });

    test('a signed-out caller is told to sign in, not shown a crash', () async {
      final result = await _Repository(client, null).uploadAvatar(png);

      expect((result as Err<User>).failure, isA<UnauthorizedFailure>());
      expect(calls, isEmpty);
    });
  });
}

Future<Uint8List> _bytesOf(HttpRequest request) async {
  final chunks = <int>[];
  await for (final chunk in request) {
    chunks.addAll(chunk);
  }
  return Uint8List.fromList(chunks);
}

class _Call {
  _Call({
    required this.method,
    required this.path,
    required this.query,
    required this.headers,
    required this.body,
  });

  final String method;
  final String path;
  final String query;
  final Map<String, String?> headers;
  final Uint8List body;
}

/// The live repository with its client and its caller replaced — the two seams,
/// and nothing else.
class _Repository extends SupabaseAuthRepository {
  _Repository(this._client, this._uid);

  final SupabaseClient _client;
  final String? _uid;

  @override
  SupabaseClient get client => _client;

  @override
  String? get currentUserId => _uid;
}
