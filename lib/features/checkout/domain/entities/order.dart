import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:nova_modest/features/checkout/domain/entities/order_totals.dart';

part 'order.freezed.dart';

/// A placed order — what comes back once the shopper confirms.
///
/// Carries **what the confirmation screen needs and no more**: the number to
/// quote, when it was placed, and what it came to. It does not repeat the
/// contact, the address or the lines: the draft still holds those for as long
/// as the flow lives, and a second copy of them here would be a second thing to
/// keep true (`10-evidence-and-dependency-guard.md`). A real orders API will
/// return far more, and this grows to meet it when there is one to meet.
@freezed
abstract class Order with _$Order {
  const factory Order({
    /// `ORD-YYMMDD-NNNN`, as `1:2137` quotes it.
    required String number,
    required DateTime placedAt,
    required OrderTotals totals,
  }) = _Order;
}
