import 'package:flutter/services.dart' show PlatformException;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:injectable/injectable.dart';
import 'package:nova_modest/core/error/failure.dart';

/// The seam for reading and writing auth tokens.
///
/// Auth tokens are Keychain/Keystore-backed, never plain `SharedPreferences`
/// and never a plaintext file (`03-flutter-security-guard.md`). Depending on
/// this interface rather than on `FlutterSecureStorage` is also what lets tests
/// substitute an in-memory fake without touching a platform channel.
abstract class TokenStorage {
  Future<String?> readAccessToken();

  Future<String?> readRefreshToken();

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  });

  Future<void> clear();
}

/// The only implementation that touches the platform keystore.
///
/// [PlatformException] is mapped to [CacheFailure] here so nothing above this
/// class sees a platform-channel exception, matching how `dio` is contained at
/// the network seam (`06-flutter-error-guard.md` §3).
@LazySingleton(as: TokenStorage)
class SecureTokenStorage implements TokenStorage {
  const SecureTokenStorage(this._storage);

  static const String _accessTokenKey = 'auth.access_token';
  static const String _refreshTokenKey = 'auth.refresh_token';

  final FlutterSecureStorage _storage;

  @override
  Future<String?> readAccessToken() => _read(_accessTokenKey);

  @override
  Future<String?> readRefreshToken() => _read(_refreshTokenKey);

  @override
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    try {
      await _storage.write(key: _accessTokenKey, value: accessToken);
      await _storage.write(key: _refreshTokenKey, value: refreshToken);
    } on PlatformException catch (_) {
      // Deliberately does not include the exception detail: on some platforms
      // it echoes the value being written (03-flutter-security-guard.md).
      throw const CacheFailure('Could not persist the session.');
    }
  }

  @override
  Future<void> clear() async {
    try {
      await _storage.delete(key: _accessTokenKey);
      await _storage.delete(key: _refreshTokenKey);
    } on PlatformException catch (_) {
      throw const CacheFailure('Could not clear the session.');
    }
  }

  Future<String?> _read(String key) async {
    try {
      return await _storage.read(key: key);
    } on PlatformException catch (_) {
      throw const CacheFailure('Could not read the session.');
    }
  }
}
