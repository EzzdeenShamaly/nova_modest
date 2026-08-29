part of 'checkout_bloc.dart';

/// Where the shopper is, and what has been collected.
///
/// Three members, and the sealing paid for itself: [CheckoutPlacing] and
/// [CheckoutFailed] were added when the review step arrived and every `switch`
/// in the UI was updated by the compiler rather than by memory
/// (`02-flutter-state-guard.md`).
///
/// Not a flag on [CheckoutInProgress]: `isPlacing` alongside a failure is a
/// representable state with no meaning, which is exactly what a sealed
/// hierarchy exists to make impossible.
///
/// No four-state contract: nothing here loads, and a draft always exists.
sealed class CheckoutState extends Equatable {
  const CheckoutState({required this.step, required this.draft, this.returnTo});

  final CheckoutStep step;
  final CheckoutDraft draft;

  /// Where finishing this step should land, when the shopper arrived by a
  /// "تعديل" link rather than by walking forward. Null the rest of the time.
  ///
  /// **In the state, not a private field on the bloc.** It started as one, and
  /// the host promptly popped the shopper out of checkout: the back button asks
  /// the step whether anything is behind it, `CheckoutStep.contact.previous` is
  /// null, and a bloc field the UI cannot see could not say otherwise. Anything
  /// that changes what the UI does belongs in the state
  /// (`02-flutter-state-guard.md`).
  final CheckoutStep? returnTo;

  /// Whether back should move inside the flow rather than leave it.
  bool get canMoveBack => returnTo != null || step.previous != null;

  @override
  List<Object?> get props => [step, draft, returnTo];
}

/// Moving through the steps.
final class CheckoutInProgress extends CheckoutState {
  const CheckoutInProgress({
    super.step = CheckoutStep.contact,
    super.draft = const CheckoutDraft(),
    super.returnTo,
  });

  /// [returnTo] is **not** carried over unless asked for: a pending return is
  /// consumed by the move that honours it, and a `copyWith` that preserved it
  /// silently would send the shopper back to the review from every step after.
  CheckoutInProgress copyWith({
    CheckoutStep? step,
    CheckoutDraft? draft,
    CheckoutStep? returnTo,
  }) => CheckoutInProgress(
    step: step ?? this.step,
    draft: draft ?? this.draft,
    returnTo: returnTo,
  );
}

/// The order is being placed.
///
/// Carries the step and the draft unchanged, so the review stays on screen
/// under its own disabled button rather than being replaced by a spinner —
/// there is nothing to re-read, and a shopper who has just committed to paying
/// should still see what they committed to.
final class CheckoutPlacing extends CheckoutState {
  const CheckoutPlacing({required super.step, required super.draft});
}

/// Placing failed. The draft is intact and the shopper may try again.
final class CheckoutFailed extends CheckoutState {
  const CheckoutFailed({
    required super.step,
    required super.draft,
    required this.failure,
  });

  final Failure failure;

  @override
  List<Object?> get props => [step, draft, failure];
}
