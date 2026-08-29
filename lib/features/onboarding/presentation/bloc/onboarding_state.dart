part of 'onboarding_bloc.dart';

sealed class OnboardingState extends Equatable {
  const OnboardingState();

  @override
  List<Object?> get props => const [];
}

/// The flag has not been read yet. The router holds on the splash while this is
/// the state, rather than guessing and flashing the wrong screen.
final class OnboardingInitial extends OnboardingState {
  const OnboardingInitial();
}

/// First launch on this device.
final class OnboardingRequired extends OnboardingState {
  const OnboardingRequired();
}

/// Already seen — or finished just now.
final class OnboardingNotRequired extends OnboardingState {
  const OnboardingNotRequired();
}

/// The flag could not be read.
///
/// Kept as a distinct state rather than folded into [OnboardingNotRequired] so
/// the failure stays inspectable, but the router treats it as "let them in":
/// missing the intro once is better than trapping someone behind a disk error.
final class OnboardingFailureState extends OnboardingState {
  const OnboardingFailureState(this.failure);

  final Failure failure;

  @override
  List<Object?> get props => [failure];
}
