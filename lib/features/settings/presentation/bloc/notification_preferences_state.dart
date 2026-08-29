part of 'notification_preferences_bloc.dart';

/// Always carries usable [preferences] — there is no loading state and no empty
/// one, because two booleans always have a value and the switches have to be
/// drawn from the first frame.
///
/// The four-state contract does not apply, for the same reason it does not
/// apply to `LocaleState` next door or to `ProductDetailBloc`: nothing here is
/// a list, and nothing here can be absent.
sealed class NotificationPreferencesState extends Equatable {
  const NotificationPreferencesState(this.preferences);

  final NotificationPreferences preferences;

  @override
  List<Object?> get props => [preferences];
}

/// Before storage has answered. Holds the defaults, so the screen renders
/// correctly rather than waiting on a disk read.
final class NotificationPreferencesUnresolved
    extends NotificationPreferencesState {
  const NotificationPreferencesUnresolved()
    : super(NotificationPreferences.defaults);
}

/// Read from storage, or just changed by the shopper.
final class NotificationPreferencesResolved
    extends NotificationPreferencesState {
  const NotificationPreferencesResolved(super.preferences, {this.saveFailure});

  /// Set when the change was applied but could not be remembered.
  ///
  /// The switch is already in its new position either way — refusing to move
  /// until the disk agrees reads as broken. This rides along so the screen can
  /// say the choice will not survive a restart.
  final Failure? saveFailure;

  @override
  List<Object?> get props => [preferences, saveFailure];
}
