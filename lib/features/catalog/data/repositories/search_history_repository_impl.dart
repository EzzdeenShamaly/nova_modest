import 'package:flutter/services.dart' show PlatformException;
import 'package:injectable/injectable.dart';
import 'package:nova_modest/core/error/failure.dart';
import 'package:nova_modest/core/error/result.dart';
import 'package:nova_modest/features/catalog/domain/repositories/search_history_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// `SharedPreferences`-backed history.
///
/// Plain preferences rather than `flutter_secure_storage`, on the same reading
/// as the onboarding flag and the cart: a list of things someone typed into a
/// shop's search box is not a credential, and `03-flutter-security-guard`
/// reserves the keystore for tokens and PII.
///
/// A plain string list, not JSON — `setStringList` is exactly this shape, and
/// wrapping it in an encoder would add a parse failure for nothing.
@LazySingleton(as: SearchHistoryRepository)
class SearchHistoryRepositoryImpl implements SearchHistoryRepository {
  const SearchHistoryRepositoryImpl(this._preferences);

  static const String _key = 'search.history';

  /// A shortlist, not an archive. The design shows three chips on one screen;
  /// beyond this the section stops being a shortcut and becomes a list to read.
  static const int maxEntries = 8;

  final SharedPreferences _preferences;

  @override
  Future<Result<List<String>>> recent() async => _read();

  @override
  Future<Result<List<String>>> record(String term) async {
    final trimmed = term.trim();
    // Nothing to remember, and no reason to call it a failure either.
    if (trimmed.isEmpty) return _read();

    final stored = _read();
    if (stored is Err<List<String>>) return stored;

    final existing = (stored as Ok<List<String>>).value;
    // Re-searching something moves it to the front instead of stacking a
    // second copy, which is what makes the list a shortlist rather than a log.
    final next = <String>[
      trimmed,
      for (final entry in existing)
        if (entry != trimmed) entry,
    ].take(maxEntries).toList();

    return _write(next);
  }

  @override
  Future<Result<List<String>>> remove(String term) async {
    final stored = _read();
    if (stored is Err<List<String>>) return stored;

    return _write([
      for (final entry in (stored as Ok<List<String>>).value)
        if (entry != term) entry,
    ]);
  }

  @override
  Future<Result<List<String>>> clear() async => _write(const []);

  Result<List<String>> _read() {
    try {
      return Ok(_preferences.getStringList(_key) ?? const <String>[]);
    } on PlatformException catch (_) {
      return const Err(CacheFailure('Could not read the search history.'));
    } on TypeError catch (_) {
      // The key exists holding something that is not a string list — an older
      // or hand-edited value.
      return const Err(CacheFailure('Could not read the search history.'));
    }
  }

  Future<Result<List<String>>> _write(List<String> terms) async {
    try {
      // setStringList reports whether the write landed; ignoring it would let a
      // failed save look like a success until the next launch.
      final written = await _preferences.setStringList(_key, terms);
      if (!written) {
        return const Err(CacheFailure('Could not save the search history.'));
      }
      return Ok(terms);
    } on PlatformException catch (_) {
      return const Err(CacheFailure('Could not save the search history.'));
    }
  }
}
