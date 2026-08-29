import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:nova_modest/features/cart/domain/entities/cart_item.dart';
import 'package:nova_modest/features/checkout/domain/entities/shipping_method.dart';

part 'cart_totals.freezed.dart';

/// What the summary card shows: subtotal, shipping, and their sum.
///
/// A domain value, not a widget calculation — a `fold` over prices inside a
/// `build()` is exactly the business logic `01-flutter-architecture-guard`
/// keeps out of the widget layer.
@freezed
abstract class CartTotals with _$CartTotals {
  const CartTotals._();

  const factory CartTotals({required num subtotal, required num shipping}) =
      _CartTotals;

  /// The quote shown before a shipping method has been chosen.
  ///
  /// Still a placeholder for a real shipping API — no threshold, no zones, no
  /// free-over-X rule. But no longer a number of its own: it is
  /// `ShippingMethod.standard.cost`, because the cart quoting 30 and checkout
  /// charging 35 made the total jump mid-purchase with nothing on screen
  /// explaining it (user, 2026-08-29).
  ///
  /// The cart reads checkout's domain for this one value, rather than checkout
  /// reading a number the cart happened to own. A second method makes this the
  /// cheapest or the default; it does not make it two numbers again.
  /// A getter, not a `const`: an enum's field cannot be read in a constant
  /// expression.
  static num get shippingFee => ShippingMethod.standard.cost;

  /// Totals for [items]. An empty cart is charged nothing to ship.
  static CartTotals of(List<CartItem> items) => CartTotals(
    subtotal: items.fold<num>(0, (sum, item) => sum + item.lineTotal),
    shipping: items.isEmpty ? 0 : shippingFee,
  );

  num get total => subtotal + shipping;
}
