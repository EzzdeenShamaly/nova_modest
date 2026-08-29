part of 'notification_preferences_bloc.dart';

sealed class NotificationPreferencesEvent extends Equatable {
  const NotificationPreferencesEvent();

  @override
  List<Object?> get props => const [];
}

/// The screen opened and needs whatever was stored.
final class NotificationPreferencesRequested
    extends NotificationPreferencesEvent {
  const NotificationPreferencesRequested();
}

/// A switch moved.
///
/// Carries the **whole** value rather than naming which one changed: the screen
/// already holds the current preferences and edits them with `copyWith`, and a
/// per-field event would grow by one every time a topic is added.
final class NotificationPreferencesChanged
    extends NotificationPreferencesEvent {
  const NotificationPreferencesChanged(this.preferences);

  final NotificationPreferences preferences;

  @override
  List<Object?> get props => [preferences];
}
