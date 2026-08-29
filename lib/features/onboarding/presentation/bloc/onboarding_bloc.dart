import 'dart:developer' as developer;

import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:nova_modest/core/error/failure.dart';
import 'package:nova_modest/core/error/result.dart';
import 'package:nova_modest/features/onboarding/domain/repositories/onboarding_repository.dart';

part 'onboarding_event.dart';
part 'onboarding_state.dart';

/// Owns whether the onboarding still has to be shown.
///
/// App-wide (`@lazySingleton`) because the router's redirect reads it, so it must
/// outlive the onboarding screen itself — the same reason `AuthBloc` is a
/// singleton while a per-screen bloc would be a factory.
///
/// Entirely separate from `AuthBloc`: signing out must never replay the
/// onboarding.
@lazySingleton
class OnboardingBloc extends Bloc<OnboardingEvent, OnboardingState> {
  OnboardingBloc(this._repository) : super(const OnboardingInitial()) {
    // droppable: reading the flag is idempotent, so a duplicate is pure waste.
    on<OnboardingStatusRequested>(_onStatusRequested, transformer: droppable());
    // sequential: finishing writes to disk and must not interleave with itself.
    on<OnboardingFinished>(_onFinished, transformer: sequential());
  }

  final OnboardingRepository _repository;

  Future<void> _onStatusRequested(
    OnboardingStatusRequested event,
    Emitter<OnboardingState> emit,
  ) async {
    final result = await _repository.isOnboardingRequired();
    emit(
      result.fold(
        OnboardingFailureState.new,
        (required) => required
            ? const OnboardingRequired()
            : const OnboardingNotRequired(),
      ),
    );
  }

  Future<void> _onFinished(
    OnboardingFinished event,
    Emitter<OnboardingState> emit,
  ) async {
    final result = await _repository.markSeen();

    // The user is done either way, so they are let through even if the write
    // failed. Not swallowed: it is logged, and the consequence of a failed write
    // is simply that the next launch shows the onboarding again.
    if (result case Err(:final failure)) {
      developer.log(
        'onboarding flag not persisted: ${failure.runtimeType}',
        name: 'onboarding',
      );
    }

    emit(const OnboardingNotRequired());
  }
}
