import 'package:flutter/foundation.dart' show debugPrint, visibleForTesting;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:nova_modest/core/supabase/supabase_env.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Where the signed-in session is kept: the platform keystore, not a preference
/// file.
///
/// `supabase_flutter`'s default writes the session through `SharedPreferences`
/// — on Android that is a plaintext XML file in the app's sandbox, on web it is
/// `localStorage`. The refresh token inside it is long-lived, and
/// `03-flutter-security-guard` puts tokens in `flutter_secure_storage`, which
/// this project already depends on and already registers for the REST path
/// nothing uses. This is that storage, handed to `Supabase.initialize`.
///
/// **Nothing here throws.** A failure in the keystore is answered by wiping
/// what is there and starting clean: the shopper signs in again, which is a
/// minor annoyance, where an exception would be a dead screen and keeping the
/// old plaintext session would be the defect this class exists to remove
/// (user, 2026-09-20).
class SecureSessionStorage extends LocalStorage {
  SecureSessionStorage({
    FlutterSecureStorage? secureStorage,
    Future<SharedPreferences> Function()? preferences,
  }) : _secure = secureStorage ?? const FlutterSecureStorage(),
       _preferences = preferences ?? SharedPreferences.getInstance;

  final FlutterSecureStorage _secure;
  final Future<SharedPreferences> Function() _preferences;

  /// Our own key. It need not match the old one — nothing else reads this.
  @visibleForTesting
  static const String key = 'supabase.session';

  /// The key the SDK's default storage used, which is what a session written
  /// before this class existed is sitting under.
  ///
  /// Built the same way the SDK built it —
  /// `sb-<project ref>-auth-token` from the host — so an installed app upgrading
  /// to this version finds its own session rather than a guess at one.
  @visibleForTesting
  static String get legacyKey =>
      'sb-${Uri.parse(SupabaseEnv.url).host.split('.').first}-auth-token';

  @override
  Future<void> initialize() => _migrateFromPlaintext();

  @override
  Future<bool> hasAccessToken() async => await accessToken() != null;

  @override
  Future<String?> accessToken() async {
    try {
      return await _secure.read(key: key);
    } catch (error) {
      // A keystore that cannot be read — a restored backup, a changed lock
      // screen — is answered as "no session" rather than as a crash.
      debugPrint('SecureSessionStorage: unreadable, starting clean ($error)');
      await _wipe();
      return null;
    }
  }

  @override
  Future<void> persistSession(String persistSessionString) async {
    try {
      await _secure.write(key: key, value: persistSessionString);
    } catch (error) {
      debugPrint('SecureSessionStorage: could not persist ($error)');
      await _wipe();
    }
  }

  @override
  Future<void> removePersistedSession() => _wipe();

  /// Moves a session written by the old plaintext storage into the keystore,
  /// once, and deletes the plaintext copy.
  ///
  /// Anything going wrong ends with **both** cleared: half a migration must not
  /// leave a readable token behind, and a shopper signing in again is the
  /// cheapest possible failure.
  Future<void> _migrateFromPlaintext() async {
    try {
      final preferences = await _preferences();
      final plaintext = preferences.getString(legacyKey);
      if (plaintext == null) return;

      // Only if the keystore has nothing: a session written since is newer.
      if (await _secure.read(key: key) == null) {
        await _secure.write(key: key, value: plaintext);
      }
      await preferences.remove(legacyKey);
    } catch (error) {
      debugPrint('SecureSessionStorage: migration failed, wiping ($error)');
      await _wipe();
    }
  }

  /// Clears both stores. Used by every failure path, so a token is never left
  /// behind in the one this class was written to empty.
  Future<void> _wipe() async {
    try {
      await _secure.delete(key: key);
    } catch (_) {
      // Nothing more to try: the keystore is the thing that is failing.
    }
    try {
      final preferences = await _preferences();
      await preferences.remove(legacyKey);
    } catch (_) {
      // Same.
    }
  }
}
