import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;

/// Build-time Supabase coordinates.
///
/// Supplied with `--dart-define` / `--dart-define-from-file`. The Android
/// emulator cannot reach the host's loopback, so `127.0.0.1` / `localhost` are
/// rewritten to `10.0.2.2` on that platform only.
class SupabaseEnv {
  const SupabaseEnv._();

  static const String urlFromDefine = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'http://127.0.0.1:55321',
  );

  static const String anonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  static String get url {
    if (!kIsWeb && Platform.isAndroid) {
      return urlFromDefine
          .replaceFirst('127.0.0.1', '10.0.2.2')
          .replaceFirst('localhost', '10.0.2.2');
    }
    return urlFromDefine;
  }
}
