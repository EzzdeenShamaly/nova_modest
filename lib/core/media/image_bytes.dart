import 'dart:typed_data';

/// The image formats the `avatars` bucket accepts, recognised **from the bytes**.
///
/// Never from the file name. A picker hands back whatever the device called the
/// file, and a `.jpg` that is really a PNG — or a renamed PDF — is rejected by
/// storage with a 400 that says nothing useful to a shopper. The first bytes of
/// a file are the only honest answer, and they are what the bucket's
/// `allowed_mime_types` is checked against server-side anyway.
enum ImageFormat {
  png('image/png'),
  jpeg('image/jpeg'),
  webp('image/webp');

  const ImageFormat(this.mimeType);

  final String mimeType;

  /// The format [bytes] actually are, or null for anything else.
  static ImageFormat? of(Uint8List bytes) {
    // PNG: the 8-byte signature.
    if (_startsWith(bytes, const [
      0x89,
      0x50,
      0x4e,
      0x47,
      0x0d,
      0x0a,
      0x1a,
      0x0a,
    ])) {
      return ImageFormat.png;
    }
    // JPEG: SOI marker.
    if (_startsWith(bytes, const [0xff, 0xd8, 0xff])) return ImageFormat.jpeg;
    // WebP: "RIFF" .... "WEBP" — the size sits between the two, so the second
    // half is checked at its own offset rather than as one run.
    if (_startsWith(bytes, const [0x52, 0x49, 0x46, 0x46]) &&
        bytes.length >= 12 &&
        _startsWith(bytes.sublist(8, 12), const [0x57, 0x45, 0x42, 0x50])) {
      return ImageFormat.webp;
    }
    return null;
  }

  static bool _startsWith(Uint8List bytes, List<int> signature) {
    if (bytes.length < signature.length) return false;
    for (var i = 0; i < signature.length; i++) {
      if (bytes[i] != signature[i]) return false;
    }
    return true;
  }
}
