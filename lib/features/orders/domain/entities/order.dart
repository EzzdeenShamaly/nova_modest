import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:nova_modest/features/address/domain/entities/address.dart';
import 'package:nova_modest/features/cart/domain/entities/cart_item.dart';
import 'package:nova_modest/features/orders/domain/entities/order_status.dart';
import 'package:nova_modest/features/orders/domain/entities/order_totals.dart';

part 'order.freezed.dart';

/// A placed order.
///
/// **A snapshot, not a set of references.** It carries the lines, the address
/// and the recipient as they were when it was placed — not ids to look up. The
/// cart it came from is emptied moments later and the checkout draft dies with
/// the flow, so an order that pointed at them would point at nothing. A price
/// that changed in the catalogue afterwards must not change what someone was
/// charged either.
///
/// This grew from a number, a date and a total when the orders screens arrived.
/// The comment it replaces said it "does not repeat what the draft holds" —
/// true while nothing outlived the draft, and wrong the moment something did.
///
/// Lives in `features/orders/` rather than in checkout, on the same reasoning
/// as `Address`: two features need it, and the one that *reads* orders must not
/// have to depend on the one that *writes* them.
@freezed
abstract class Order with _$Order {
  const Order._();

  const factory Order({
    /// `ORD-YYMMDD-NNNN`, as `1:2137` and `1:1356` quote it.
    required String number,
    required DateTime placedAt,
    required OrderTotals totals,
    required OrderStatus status,

    /// What was bought, at the price it was bought for.
    @Default(<CartItem>[]) List<CartItem> items,

    /// Where it goes, and who receives it.
    Address? address,

    /// The name and number the shopper gave at checkout, which may differ from
    /// the account's — they may be buying for someone else.
    String? recipientName,
    String? recipientPhone,
  }) = _Order;

  /// Every garment in the order, quantities counted — «المنتجات (٢)».
  int get itemCount => items.fold<int>(0, (sum, item) => sum + item.quantity);

  /// The line whose picture the list card shows.
  CartItem? get leadItem => items.isEmpty ? null : items.first;

  /// How many lines the card's thumbnail does **not** show — the frame's «+2».
  int get hiddenItemCount => items.isEmpty ? 0 : items.length - 1;
}
