import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:nova_modest/core/media/image_bytes.dart';

/// What the app will hand to the `avatars` bucket, and what it refuses first.
///
/// The bucket allows `image/png`, `image/jpeg` and `image/webp` and checks the
/// content type server-side, so anything this misses comes back as a bare 400
/// with nothing a shopper could act on. Deciding here, from the bytes, is what
/// makes the refusal sayable in Arabic.
void main() {
  Uint8List bytes(List<int> head, {int pad = 32}) =>
      Uint8List.fromList([...head, ...List.filled(pad, 0)]);

  group('recognises', () {
    test('a PNG by its 8-byte signature', () {
      expect(
        ImageFormat.of(
          bytes(const [0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]),
        ),
        ImageFormat.png,
      );
    });

    test('a JPEG by its SOI marker', () {
      expect(
        ImageFormat.of(bytes(const [0xff, 0xd8, 0xff, 0xe0])),
        ImageFormat.jpeg,
      );
    });

    test('a WebP by RIFF plus the tag four bytes later', () {
      // "RIFF" + a 4-byte length + "WEBP". The length is arbitrary, which is
      // exactly why the tag cannot be checked as one continuous run.
      expect(
        ImageFormat.of(
          bytes(const [
            0x52, 0x49, 0x46, 0x46, // RIFF
            0x24, 0x10, 0x00, 0x00, // size, whatever it happens to be
            0x57, 0x45, 0x42, 0x50, // WEBP
          ]),
        ),
        ImageFormat.webp,
      );
    });
  });

  group('refuses', () {
    test('a PDF, whatever the file was called', () {
      // The case the rule exists for: a device reports a name, and a name is
      // not evidence. `%PDF`.
      expect(ImageFormat.of(bytes(const [0x25, 0x50, 0x44, 0x46])), isNull);
    });

    test('a GIF — a real image, and still not one this bucket accepts', () {
      expect(
        ImageFormat.of(bytes(const [0x47, 0x49, 0x46, 0x38, 0x39, 0x61])),
        isNull,
      );
    });

    test('a RIFF container that is not WebP', () {
      // A WAV file opens with the same four bytes. Matching on RIFF alone would
      // upload audio as a profile picture.
      expect(
        ImageFormat.of(
          bytes(const [
            0x52, 0x49, 0x46, 0x46, //
            0x24, 0x10, 0x00, 0x00, //
            0x57, 0x41, 0x56, 0x45, // WAVE
          ]),
        ),
        isNull,
      );
    });

    test('an empty file', () {
      expect(ImageFormat.of(Uint8List(0)), isNull);
    });

    test('a truncated signature, without reading past the end', () {
      // Three of PNG's eight bytes. The check must answer "no", not throw.
      expect(
        ImageFormat.of(Uint8List.fromList(const [0x89, 0x50, 0x4e])),
        isNull,
      );
      // Four bytes of a RIFF header with nothing behind it: the WebP branch
      // reads offset 8..12, which does not exist here.
      expect(
        ImageFormat.of(Uint8List.fromList(const [0x52, 0x49, 0x46, 0x46])),
        isNull,
      );
    });
  });

  test('every format carries the mime type the bucket lists', () {
    // These three strings are the bucket's `allowed_mime_types`, read from the
    // live project on 2026-09-20. A typo here is a 400 at upload time.
    expect(
      ImageFormat.values.map((f) => f.mimeType),
      containsAll(<String>['image/png', 'image/jpeg', 'image/webp']),
    );
  });
}
