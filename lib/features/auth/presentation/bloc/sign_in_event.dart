part of 'sign_in_bloc.dart';

sealed class SignInEvent extends Equatable {
  const SignInEvent();

  @override
  List<Object?> get props => const [];
}

final class SignInGoogleRequested extends SignInEvent {
  const SignInGoogleRequested();
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
