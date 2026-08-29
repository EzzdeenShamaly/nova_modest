part of 'auth_bloc.dart';

/// Sealed, so the `switch` in the UI is exhaustive and a state added later
/// cannot be silently ignored by a trailing `else`.
///
/// Every field appears in `props`. A field omitted there makes two different
/// states compare equal, `emit` becomes a no-op, and the screen silently stops
/// updating — the hardest bug in this stack to find
/// (`02-flutter-state-guard.md`).
sealed class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => const [];
}

/// Before the startup session check resolves. The router treats this as
/// "undecided" and holds on the splash rather than guessing.
final class AuthInitial extends AuthState {
  const AuthInitial();
}

/// The one-time startup session check is in flight.
///
/// Distinct from [AuthLoading] on purpose. Both mean "waiting", but only this one
/// means "the app has not decided who the user is yet", which is what the router
/// holds the splash screen on. Collapsing the two made the router either skip the
/// splash entirely (it treated a startup check as decided) or bounce a user off
/// the login form mid-submit (if it treated every wait as undecided).
final class AuthCheckInProgress extends AuthState {
  const AuthCheckInProgress();
}

/// A sign-in or sign-out the user initiated is in flight.
final class AuthLoading extends AuthState {
  const AuthLoading();
}

/// Signed in.
final class AuthAuthenticated extends AuthState {
  const AuthAuthenticated(this.user);

  final User user;

  @override
  List<Object?> get props => [user];
}

/// Resolved as signed out — a normal state, not an error.
final class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

/// A sign-in attempt or session check failed in a way the user can act on.
final class AuthFailureState extends AuthState {
  const AuthFailureState(this.failure);

  final Failure failure;

  @override
  List<Object?> get props => [failure];
}
