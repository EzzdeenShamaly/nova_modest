import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:nova_modest/core/error/failure.dart';
import 'package:nova_modest/core/error/result.dart';
import 'package:nova_modest/features/auth/domain/entities/user.dart';
import 'package:nova_modest/features/auth/domain/repositories/auth_repository.dart';

part 'sign_in_event.dart';
part 'sign_in_state.dart';

/// Runs the sign-in flow: Google, or an emailed one-time code.
///
/// Registered as a **factory**, not a singleton, and scoped to the sign-in
/// screens. `AuthBloc` is the app-wide session authority; putting "a code was
/// sent to this address" in it would leave that state sitting there the next
/// time the user opened the screen.
///
/// There is no password anywhere in this flow, and so no password reset.
@injectable
class SignInBloc extends Bloc<SignInEvent, SignInState> {
  SignInBloc(this._repository) : super(const SignInIdle()) {
    // droppable everywhere: a second tap while a request is in flight is
    // discarded, not queued. Without it a double-tap sends two requests whose
    // responses can resolve out of order.
    on<SignInGoogleRequested>(_onGoogleRequested, transformer: droppable());
    on<SignInEmailSubmitted>(_onEmailSubmitted, transformer: droppable());
    on<SignInCodeSubmitted>(_onCodeSubmitted, transformer: droppable());
    on<SignInCodeResendRequested>(_onResendRequested, transformer: droppable());
  }

  final AuthRepository _repository;

  Future<void> _onGoogleRequested(
    SignInGoogleRequested event,
    Emitter<SignInState> emit,
  ) async {
    emit(const SignInSubmitting());
    final result = await _repository.signInWithGoogle();
    emit(result.fold(SignInFailureState.new, SignInSucceeded.new));
  }

  Future<void> _onEmailSubmitted(
    SignInEmailSubmitted event,
    Emitter<SignInState> emit,
  ) async {
    emit(const SignInSubmitting());
    final result = await _repository.requestEmailCode(event.email);
    emit(
      result.fold(SignInFailureState.new, (_) => SignInCodeSent(event.email)),
    );
  }

  Future<void> _onCodeSubmitted(
    SignInCodeSubmitted event,
    Emitter<SignInState> emit,
  ) async {
    emit(const SignInSubmitting());
    final result = await _repository.verifyEmailCode(
      email: event.email,
      code: event.code,
    );
    emit(result.fold(SignInFailureState.new, SignInSucceeded.new));
  }

  Future<void> _onResendRequested(
    SignInCodeResendRequested event,
    Emitter<SignInState> emit,
  ) async {
    emit(const SignInSubmitting());
    final result = await _repository.requestEmailCode(event.email);
    // Back to CodeSent either way it is worded: a resend that fails must leave
    // the user on the verification screen with the code they may already have,
    // not throw them back to the method screen.
    emit(
      result.fold(SignInFailureState.new, (_) => SignInCodeSent(event.email)),
    );
  }
}
