part of 'sign_in_bloc.dart';

sealed class SignInEvent extends Equatable {
  const SignInEvent();

  @override
  List<Object?> get props => const [];
}

final class SignInGoogleRequested extends SignInEvent {
  const SignInGoogleRequested();
}

/// The shopper acknowledged a failure and wants the form back.
///
/// The screen replaces itself with a `FailureView` when sign-in fails, and its
/// retry used to re-dispatch the Google flow — which was the only other thing
/// the screen could do. With that control gone (`progress.md`, blocker 6),
/// "retry" means returning to the email form rather than repeating a request
/// the shopper never made.
final class SignInDismissed extends SignInEvent {
  const SignInDismissed();
}

/// The user submitted an address and wants a code sent to it.
final class SignInEmailSubmitted extends SignInEvent {
  const SignInEmailSubmitted(this.email);

  final String email;

  @override
  List<Object?> get props => [email];
}

/// The user entered the six digits.
final class SignInCodeSubmitted extends SignInEvent {
  const SignInCodeSubmitted({required this.email, required this.code});

  final String email;
  final String code;

  @override
  List<Object?> get props => [email, code];
}

final class SignInCodeResendRequested extends SignInEvent {
  const SignInCodeResendRequested(this.email);

  final String email;

  @override
  List<Object?> get props => [email];
}
