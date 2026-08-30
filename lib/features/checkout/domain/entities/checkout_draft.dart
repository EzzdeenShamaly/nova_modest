import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:nova_modest/features/address/domain/entities/address.dart';
import 'package:nova_modest/features/cart/domain/entities/cart_item.dart';
import 'package:nova_modest/features/cart/domain/entities/cart_totals.dart';
import 'package:nova_modest/features/checkout/domain/entities/contact_details.dart';
import 'package:nova_modest/features/orders/domain/entities/order.dart';
import 'package:nova_modest/features/orders/domain/entities/order_totals.dart';
import 'package:nova_modest/features/checkout/domain/entities/payment_method.dart';
import 'package:nova_modest/features/checkout/domain/entities/shipping_method.dart';

part 'checkout_draft.freezed.dart';

/// Everything checkout has collected so far.
///
/// Carries **only what a built step fills in**.
///
/// [shipping] and [payment] are the exception, and deliberately so: they are
/// **not** nullable. `1:2059` opens with both already chosen, and there is one
/// shipping method and one available payment method — so "nothing selected yet"
/// is a state the flow never has. A nullable field would invent it, and every
/// reader would then have to handle it.
///
/// It lives for the length of the flow and no longer: `CheckoutBloc` is provided
/// by the `ShellRoute` around `/checkout`, so leaving checkout discards a
/// half-finished draft rather than showing it to whoever opens the flow next.
@freezed
abstract class CheckoutDraft with _$CheckoutDraft {
  const CheckoutDraft._();

  const factory CheckoutDraft({
    ContactDetails? contact,

    /// The whole address, not its id. The review screen draws it in full, and
    /// holding the id would make every later step look it up again in a list
    /// it does not otherwise need. Editing an address inside the flow goes
    /// through the same step that set this, so the copy cannot go stale
    /// (user, 2026-08-29).
    Address? address,

    /// Preselected, as the frame draws them.
    @Default(ShippingMethod.standard) ShippingMethod shipping,
    @Default(PaymentMethod.cashOnDelivery) PaymentMethod payment,

    /// What the cart held when checkout opened.
    ///
    /// A snapshot, handed in by the route the way the signed-in user is. The
    /// cart cannot be edited from inside this flow, so it cannot go stale
    /// while the flow is open — and the bloc stays testable without a cart.
    CartTotals? cart,

    /// The lines the review screen lists. Handed in beside [cart] rather than
    /// replacing it: step 3's totals plumbing works and is covered, and
    /// deriving one from the other would mean rebuilding it
    /// (`09-minimal-changes.md`).
    @Default(<CartItem>[]) List<CartItem> items,

    /// Set once the order is placed. Null for the whole flow before that.
    Order? order,
  }) = _CheckoutDraft;

  /// The four figures step 3 and the review screen show, or null before the
  /// cart is known.
  ///
  /// Built here rather than by a factory on `OrderTotals`: pricing a cart under
  /// a chosen shipping and payment method is **checkout's** business, and a
  /// constructor that knew those two enums would point the orders feature at
  /// this one.
  ///
  /// Takes only the **subtotal** from the cart. The cart's own shipping is the
  /// quote made before a method was picked; once one is, the method decides.
  /// They agree today because both are 35, and this is written so they still
  /// agree when a second method makes them differ.
  OrderTotals? get totals => cart == null
      ? null
      : OrderTotals(
          subtotal: cart!.subtotal,
          shipping: shipping.cost,
          paymentFee: payment.fee,
        );
}
