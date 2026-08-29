import 'package:nova_modest/core/error/result.dart';

/// Owns the "has this device already seen the onboarding" flag.
///
/// Deliberately independent of [AuthRepository]: the onboarding is a
/// first-launch-on-this-device concern, not a session one. Signing out must
/// never replay it.
abstract class OnboardingRepository {
  /// `true` when the onboarding still needs to be shown on this device.
  Future<Result<bool>> isOnboardingRequired();

  /// Records that the onboarding was completed or skipped. Both end it.
  Future<Result<void>> markSeen();
}
