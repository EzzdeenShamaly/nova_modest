part of 'auth_bloc.dart';

/// Events name **what happened**, past tense — not what the bloc should do.
/// `OrdersRequested`, not `LoadOrders`: an event is a fact reported to the bloc,
/// and the bloc decides the response (`02-flutter-state-guard.md`).
sealed class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => const [];
}

/// Dispatched once at startup to resolve whether a stored session is still good.
final class AuthCheckRequested extends AuthEvent {
  const AuthCheckRequested();
}

/// A sign-in flow completed and produced a user.
///
/// `AuthBloc` owns the *session*, not the sign-in flow — `SignInBloc` runs
/// Google and the email-code exchange, then reports the result here. That keeps
/// transient flow state out of an app-wide singleton, where it would still be
/// sitting there the next time the user opened the sign-in screen.
final class AuthSessionEstablished extends AuthEvent {
  const AuthSessionEstablished(this.user);

  final User user;

  @override
  List<Object?> get props => [user];
}

/// The signed-in user edited their profile and it was saved.
///
/// Same shape as [AuthSessionEstablished] and for the same reason:
/// `ProfileEditBloc` runs the form and reports the outcome here, so the
/// transient "saving" state never enters an app-wide singleton. No repository
/// call follows — the write already happened.
final class AuthProfileUpdated extends AuthEvent {
  const AuthProfileUpdated(this.user);

  final User user;

  @override
  List<Object?> get props => [user];
}

final class AuthLogoutRequested extends AuthEvent {
  const AuthLogoutRequested();
}

/// The shopper's account was deleted, and the device's session already
/// cleared by the repository that deleted it.
///
/// Not [AuthLogoutRequested]: that one calls the repository to end a session,
/// and there is nothing left to end — the account is gone on the server and
/// the local session with it. This only moves the app's own state to signed
/// out, which is what sends the router to sign-in. Reported by
/// `AccountDeletionBloc`, the same way `ProfileEditBloc` reports an edit.
final class AuthAccountDeleted extends AuthEvent {
  const AuthAccountDeleted();
}
