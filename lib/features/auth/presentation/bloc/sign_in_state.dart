part of 'sign_in_bloc.dart';

sealed class SignInState extends Equatable {
  const SignInState();

  @override
  List<Object?> get props => const [];
}

/// Nothing in flight — the method screen's resting state.
final class SignInIdle extends SignInState {
  const SignInIdle();
}

/// A request is in flight. Every button on the flow disables on this.
final class SignInSubmitting extends SignInState {
  const SignInSubmitting();
}

/// A code was emailed. The screen moves to the verification step on this.
final class SignInCodeSent extends SignInState {
  const SignInCodeSent(this.email);

  final String email;

  @override
  List<Object?> get props => [email];
}

/// Signed in. The screen hands the user to `AuthBloc`, which owns the session.
final class SignInSucceeded extends SignInState {
  const SignInSucceeded(this.user);

  final User user;

  @override
  List<Object?> get props => [user];
}

final class SignInFailureState extends SignInState {
  const SignInFailureState(this.failure);

  final Failure failure;

  @override
  List<Object?> get props => [failure];
}
