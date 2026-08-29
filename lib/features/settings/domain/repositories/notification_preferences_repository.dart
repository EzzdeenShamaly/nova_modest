import 'package:nova_modest/core/error/result.dart';
import 'package:nova_modest/features/settings/domain/entities/notification_preferences.dart';

/// Remembers which notifications the shopper wants.
///
/// A device preference, stored beside the onboarding flag and the language
/// choice rather than with anything the account owns.
///
/// [saved] fills in [NotificationPreferences.defaults] for anything never
/// chosen, so a caller never has to distinguish "off" from "not set" — the
/// defaults already encode that distinction.
abstract class NotificationPreferencesRepository {
  Future<Result<NotificationPreferences>> saved();

  Future<Result<void>> save(NotificationPreferences preferences);
}
