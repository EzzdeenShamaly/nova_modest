import 'package:freezed_annotation/freezed_annotation.dart';

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
///
/// **Plain.** It used to carry an `of(CartTotals, {shipping, payment})` factory,
/// which made an order-shaped value depend on checkout's two method enums — and
/// once orders became their own feature, that dependency pointed the wrong way.
/// Building one from a cart and a pair of choices is checkout's business, and
/// `CheckoutDraft.totals` does it.
@freezed
abstract class OrderTotals with _$OrderTotals {
  const OrderTotals._();

  const factory OrderTotals({
    required num subtotal,
    required num shipping,
    required num paymentFee,
  }) = _OrderTotals;

  num get total => subtotal + shipping + paymentFee;
}
