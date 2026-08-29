part of 'onboarding_bloc.dart';

sealed class OnboardingEvent extends Equatable {
  const OnboardingEvent();

  @override
  List<Object?> get props => const [];
}

/// Dispatched once at startup to resolve whether this device has seen the
/// onboarding.
final class OnboardingStatusRequested extends OnboardingEvent {
  const OnboardingStatusRequested();
}

/// The user reached the end or tapped skip. Both finish it identically.
final class OnboardingFinished extends OnboardingEvent {
  const OnboardingFinished();
}
