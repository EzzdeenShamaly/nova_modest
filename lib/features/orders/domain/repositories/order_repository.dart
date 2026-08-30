import 'package:nova_modest/core/error/result.dart';
import 'package:nova_modest/features/checkout/domain/entities/checkout_draft.dart';
import 'package:nova_modest/features/orders/domain/entities/order.dart';

/// Places orders and reads them back.
///
/// The one place in this app that writes something which is not a local edit.
abstract class OrderRepository {
  /// Submits [draft] and returns the placed order.
  ///
  /// Takes the whole draft rather than six unpacked arguments: the draft **is**
  /// the order request, it is already the shape the checkout steps build, and a
  /// field added by a later step would otherwise change this signature and
  /// every caller of it.
  ///
  /// Returns a `ValidationFailure` for a draft that is not complete. The UI
  /// cannot reach the review step without a contact and an address, so that is
  /// a guard against a future caller rather than something a shopper can
  /// trigger — but an order with no address is worth refusing at the seam, not
  /// discovering at the warehouse.
  Future<Result<Order>> place(CheckoutDraft draft);

  /// Every order the shopper has placed, **newest first** — the order `1:1356`
  /// lists them in.
  Future<Result<List<Order>>> orders();

  /// One order by its number, or a `NotFoundFailure`.
  ///
  /// By number rather than a separate id: the number is what the shopper sees,
  /// what the confirmation quotes and what a support conversation would use, so
  /// a second identifier would be one more thing to keep in step.
  Future<Result<Order>> orderByNumber(String number);
}
