import 'package:flutter/services.dart' show PlatformException;
import 'package:injectable/injectable.dart';
import 'package:nova_modest/core/error/failure.dart';
import 'package:nova_modest/core/error/result.dart';
import 'package:nova_modest/features/settings/domain/repositories/locale_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// `SharedPreferences`-backed language choice.
///
/// Plain preferences, and here that is the *right* answer rather than a
/// compromise: `03-flutter-security-guard` names an interface preference as
/// exactly the non-sensitive case. Addresses and the profile went to memory
/// instead because they carry PII; a language code carries none.
@LazySingleton(as: LocaleRepository)
class LocaleRepositoryImpl implements LocaleRepository {
  const LocaleRepositoryImpl(this._preferences);

  static const String _key = 'settings.language_code';

  final SharedPreferences _preferences;

  @override
  Future<Result<String?>> savedLanguageCode() async {
    try {
      // A missing key means "never chosen", which the bloc answers with the
      // default. Absence is not an error.
      return Ok(_preferences.getString(_key));
    } on PlatformException catch (_) {
      return const Err(CacheFailure('Could not read the saved language.'));
    }
  }

  @override
  Future<Result<void>> save(String languageCode) async {
    try {
      // setString reports whether the write landed; ignoring it would let a
      // failed save look like a success until the next launch.
      final written = await _preferences.setString(_key, languageCode);
      if (!written) {
        return const Err(CacheFailure('Could not save the language.'));
      }
      return const Ok(null);
    } on PlatformException catch (_) {
      return const Err(CacheFailure('Could not save the language.'));
    }
  }
}
