import 'package:nova_modest/core/error/result.dart';
import 'package:nova_modest/features/checkout/domain/entities/checkout_draft.dart';
import 'package:nova_modest/features/checkout/domain/entities/order.dart';

/// Places orders. The first write this app makes that is not a local edit.
///
/// Takes the whole [CheckoutDraft] rather than six unpacked arguments: the
/// draft **is** the order request, it is already the shape the three steps
/// build, and a field added to a later step would otherwise change this
/// signature and every caller of it.
abstract class OrderRepository {
  /// Submits [draft] and returns the placed order.
  ///
  /// Returns a `ValidationFailure` for a draft that is not complete. The UI
  /// cannot reach the review step without a contact and an address, so that is
  /// a guard against a future caller rather than something a shopper can
  /// trigger — but an order with no address is worth refusing at the seam, not
  /// discovering at the warehouse.
  Future<Result<Order>> place(CheckoutDraft draft);
}
