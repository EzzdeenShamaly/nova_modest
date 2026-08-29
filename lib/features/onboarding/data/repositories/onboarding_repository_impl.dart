import 'package:flutter/services.dart' show PlatformException;
import 'package:injectable/injectable.dart';
import 'package:nova_modest/core/error/failure.dart';
import 'package:nova_modest/core/error/result.dart';
import 'package:nova_modest/features/onboarding/domain/repositories/onboarding_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// `SharedPreferences`-backed flag.
///
/// Plain preferences rather than `flutter_secure_storage`: the flag is not
/// sensitive, and `03-flutter-security-guard` names an onboarding-seen flag as
/// exactly this case. A keystore entry can also be lost on a backup restore,
/// which would replay the onboarding to an existing user.
@LazySingleton(as: OnboardingRepository)
class OnboardingRepositoryImpl implements OnboardingRepository {
  const OnboardingRepositoryImpl(this._preferences);

  static const String _seenKey = 'onboarding.has_seen';

  final SharedPreferences _preferences;

  @override
  Future<Result<bool>> isOnboardingRequired() async {
    try {
      // A missing key is a first launch, which is the whole point of the flag —
      // so absence means "required", not an error.
      final seen = _preferences.getBool(_seenKey) ?? false;
      return Ok(!seen);
    } on PlatformException catch (_) {
      return const Err(CacheFailure('Could not read the onboarding flag.'));
    }
  }

  @override
  Future<Result<void>> markSeen() async {
    try {
      // setBool reports whether the write landed. Ignoring it would let a failed
      // write look like a success and replay the onboarding on the next launch.
      final written = await _preferences.setBool(_seenKey, true);
      if (!written) {
        return const Err(CacheFailure('Could not save the onboarding flag.'));
      }
      return const Ok(null);
    } on PlatformException catch (_) {
      return const Err(CacheFailure('Could not save the onboarding flag.'));
    }
  }
}
