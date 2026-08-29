import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:nova_modest/features/cart/domain/entities/cart_totals.dart';
import 'package:nova_modest/features/checkout/domain/entities/payment_method.dart';
import 'package:nova_modest/features/checkout/domain/entities/shipping_method.dart';

part 'order_totals.freezed.dart';

/// The four figures `1:2059` ends on: subtotal, shipping, payment fee, total.
///
/// Separate from `CartTotals` rather than a field added to it. The cart has no
/// payment fee to show and no method chosen to produce one, and the two are
/// drawn differently — the cart's is a tinted card, this is a ruled block. One
/// class serving both would carry a field that is meaningless in half its uses.
///
/// A domain value: the arithmetic lives here, not in a `build()`
/// (`01-flutter-architecture-guard`).
@freezed
abstract class OrderTotals with _$OrderTotals {
  const OrderTotals._();

  const factory OrderTotals({
    required num subtotal,
    required num shipping,
    required num paymentFee,
  }) = _OrderTotals;

  /// Prices [cart]'s contents under the chosen [shipping] and [payment].
  ///
  /// Takes only the **subtotal** from [cart]. Its own `shipping` is the quote
  /// made before a method was picked; once one is, the method decides. They
  /// agree today because both are 35, and this is written so they still agree
  /// when a second method makes them differ.
  static OrderTotals of(
    CartTotals cart, {
    required ShippingMethod shipping,
    required PaymentMethod payment,
  }) => OrderTotals(
    subtotal: cart.subtotal,
    shipping: shipping.cost,
    paymentFee: payment.fee,
  );

  num get total => subtotal + shipping + paymentFee;
}
