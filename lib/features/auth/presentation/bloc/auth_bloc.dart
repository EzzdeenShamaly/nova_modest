import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:nova_modest/core/error/failure.dart';
import 'package:nova_modest/core/error/result.dart';
import 'package:nova_modest/features/auth/domain/entities/user.dart';
import 'package:nova_modest/features/auth/domain/repositories/auth_repository.dart';

part 'auth_event.dart';
part 'auth_state.dart';

/// Owns the app-wide session.
///
/// Registered as a **lazy singleton** rather than a factory: the router's
/// redirect guard reads it, so it must outlive any one screen. That is the
/// documented exception to the factory default — a per-screen bloc registered
/// as a singleton is what makes the previous user's data flash on re-entry
/// (`01-flutter-architecture-guard.md`).
///
/// No `flutter/material.dart` import, no `BuildContext`, no navigation: this
/// emits states and the widget layer reacts.
@lazySingleton
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc(this._repository) : super(const AuthInitial()) {
    // sequential: establishing a session must not interleave with a sign-out.
    on<AuthSessionEstablished>(
      _onSessionEstablished,
      transformer: sequential(),
    );

    // droppable: the startup check is idempotent, so a duplicate is waste.
    on<AuthCheckRequested>(_onCheckRequested, transformer: droppable());

    // sequential: an edit landing between a sign-out and its result would
    // resurrect a session that has just ended.
    on<AuthProfileUpdated>(_onProfileUpdated, transformer: sequential());

    // sequential: sign-out must not interleave with anything else touching the
    // stored token.
    on<AuthLogoutRequested>(_onLogoutRequested, transformer: sequential());
  }

  final AuthRepository _repository;

  /// Floor on how long the startup session check can appear to take.
  ///
  /// Reading a token from secure storage can resolve in well under 100ms, which
  /// would make the splash screen flash and vanish. Holding the resolved state
  /// until this has elapsed keeps the brand moment visible. It is a floor, not a
  /// fixed delay: a check that takes longer adds nothing on top.
  ///
  /// Lives here rather than in the splash widget because the router's redirect
  /// guard navigates off the splash the moment this bloc leaves `AuthInitial` —
  /// a timer in the widget could not hold it.
  static const Duration minimumSessionCheckDuration = Duration(
    milliseconds: 1200,
  );

  Future<void> _onCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    // Not AuthLoading: the router distinguishes "startup has not decided yet"
    // from "the user is waiting on an action they took".
    emit(const AuthCheckInProgress());

    final stopwatch = Stopwatch()..start();
    final result = await _repository.currentUser();
    final remaining = minimumSessionCheckDuration - stopwatch.elapsed;
    if (remaining > Duration.zero) {
      await Future<void>.delayed(remaining);
    }

    emit(
      result.fold(
        AuthFailureState.new,
        (user) => user == null
            ? const AuthUnauthenticated()
            : AuthAuthenticated(user),
      ),
    );
  }

  void _onSessionEstablished(
    AuthSessionEstablished event,
    Emitter<AuthState> emit,
  ) {
    // No repository call: SignInBloc already established the session and the
    // token is stored. Re-checking here would add the startup floor's delay to
    // every sign-in for nothing.
    emit(AuthAuthenticated(event.user));
  }

  void _onProfileUpdated(AuthProfileUpdated event, Emitter<AuthState> emit) {
    // Only while there is a session to update. An edit arriving after a
    // sign-out must not sign the user back in.
    if (state is! AuthAuthenticated) return;
    emit(AuthAuthenticated(event.user));
  }

  Future<void> _onLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    final result = await _repository.logout();
    emit(result.fold(AuthFailureState.new, (_) => const AuthUnauthenticated()));
  }
}
