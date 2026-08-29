part of 'checkout_bloc.dart';

sealed class CheckoutEvent extends Equatable {
  const CheckoutEvent();

  @override
  List<Object?> get props => const [];
}

/// Checkout opened.
///
/// Carries the signed-in [user] so the contact step opens pre-filled, or null
/// for a guest. The bloc is handed the user rather than reading `AuthBloc`
/// itself: the session is the account's concern, and a checkout that depended
/// on it could not be tested without one.
final class CheckoutStarted extends CheckoutEvent {
  const CheckoutStarted({
    this.user,
    this.cart,
    this.items = const <CartItem>[],
  });

  final User? user;

  /// What the cart holds, read by the route from the app-wide `CartBloc`. Null
  /// only in a test that does not care about money.
  final CartTotals? cart;

  /// The lines the review screen lists, from the same read.
  final List<CartItem> items;

  @override
  List<Object?> get props => [user, cart, items];
}

/// The contact step was submitted, having already validated.
final class CheckoutContactSubmitted extends CheckoutEvent {
  const CheckoutContactSubmitted(this.contact);

  final ContactDetails contact;

  @override
  List<Object?> get props => [contact];
}

/// A delivery address was chosen — picked from the saved list, or just saved.
///
/// One event either way: by the time it is raised the address exists in the
/// address book with a real id, so the step it came from makes no difference
/// to the draft.
final class CheckoutAddressSelected extends CheckoutEvent {
  const CheckoutAddressSelected(this.address);

  final Address address;

  @override
  List<Object?> get props => [address];
}

/// The shipping and payment step was submitted.
///
/// Both travel together because the frame collects them on one page and the
/// order total depends on both.
final class CheckoutPaymentSubmitted extends CheckoutEvent {
  const CheckoutPaymentSubmitted({
    required this.shipping,
    required this.payment,
  });

  final ShippingMethod shipping;
  final PaymentMethod payment;

  @override
  List<Object?> get props => [shipping, payment];
}

/// A "تعديل" link on the review was tapped.
///
/// **Backwards only.** The review is reachable only by walking the three steps,
/// so a jump forward would mean skipping one — the thing the single-route
/// design exists to prevent. The bloc drops an event naming a later step rather
/// than trusting the caller.
final class CheckoutStepRequested extends CheckoutEvent {
  const CheckoutStepRequested(this.step);

  final CheckoutStep step;

  @override
  List<Object?> get props => [step];
}

/// The order was confirmed on the review step.
final class CheckoutConfirmed extends CheckoutEvent {
  const CheckoutConfirmed();
}

/// Back, within the flow.
///
/// At the first step there is nothing to go back to, and the bloc emits
/// nothing — the host pops out of checkout instead.
final class CheckoutBackRequested extends CheckoutEvent {
  const CheckoutBackRequested();
}
