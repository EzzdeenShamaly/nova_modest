import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:injectable/injectable.dart';

/// Provides the platform secure-storage handle to the DI container.
///
/// Kept beside [TokenStorage] rather than in `core/di/` so `core/di/injection.dart`
/// stays free of third-party imports.
@module
abstract class StorageModule {
  /// v11 defaults are already AES-GCM data encryption with RSA-OAEP key
  /// wrapping on Android and Keychain on Apple platforms — the
  /// `encryptedSharedPreferences` flag older guides pass was removed because
  /// its behaviour is now the default. Passing no options is the secure choice.
  @lazySingleton
  FlutterSecureStorage get secureStorage => const FlutterSecureStorage();
}
