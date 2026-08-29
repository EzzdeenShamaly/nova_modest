import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provides the shared-preferences handle to the DI container.
///
/// `@preResolve` because `getInstance()` reads from disk: the instance is awaited
/// once during `configureDependencies()` so nothing downstream has to deal with
/// an async lookup.
@module
abstract class PreferencesModule {
  @preResolve
  Future<SharedPreferences> get preferences => SharedPreferences.getInstance();
}
