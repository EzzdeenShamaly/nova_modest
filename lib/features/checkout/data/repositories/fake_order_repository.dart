// hide Order: injectable exports an `Order` annotation for ordering its own
// registrations, which shadows this feature's entity — the same collision the
// cart hits between intl's TextDirection and dart:ui's.
import 'package:injectable/injectable.dart' hide Order;
import 'package:nova_modest/core/error/failure.dart';
import 'package:nova_modest/core/error/result.dart';
import 'package:nova_modest/features/checkout/domain/entities/checkout_draft.dart';
import 'package:nova_modest/features/checkout/domain/entities/order.dart';
import 'package:nova_modest/features/checkout/domain/repositories/order_repository.dart';

/// Stands in for the orders backend.
///
/// Registered in the `test` environment. The running app uses
/// `SupabaseOrderRepository`.
///
/// Holds nothing: a placed order is handed back and forgotten. There is no
/// orders screen to read it from yet, and persisting a shopper's order history
/// to plaintext preferences is the PII call `03-flutter-security-guard` already
/// settled for addresses and profile edits.
@LazySingleton(as: OrderRepository, env: [Environment.test])
class FakeOrderRepository implements OrderRepository {
  FakeOrderRepository();

  /// Long enough for the placing state to be real, short enough not to worry
  /// someone who has just committed to paying.
  static const Duration _latency = Duration(milliseconds: 900);

  /// Counts within the process, not within the day.
  ///
  /// A real backend numbers orders centrally; nothing a phone can do makes a
  /// number unique across devices, so this is deliberately not pretending to.
  int _sequence = 0;

  @override
  Future<Result<Order>> place(CheckoutDraft draft) async {
    // Checked before the latency: a refusal the caller could have avoided
    // should not take a second to arrive.
    final totals = draft.totals;
    if (draft.contact?.isComplete != true ||
        draft.address == null ||
        totals == null) {
      return const Err(ValidationFailure('Order is missing required details.'));
    }

    await Future<void>.delayed(_latency);

    final placedAt = DateTime.now();
    return Ok(
      Order(
        number: orderNumber(placedAt, ++_sequence),
        placedAt: placedAt,
        totals: totals,
      ),
    );
  }

  /// `ORD-YYMMDD-NNNN`, the format `1:2137` quotes as `ORD-260818-0001`.
  ///
  /// Public so a test can state the format once instead of re-deriving it from
  /// a regex, and so the real repository has something to be checked against
  /// the day it replaces this one.
  static String orderNumber(DateTime placedAt, int sequence) {
    final yy = _twoDigits(placedAt.year % 100);
    final mm = _twoDigits(placedAt.month);
    final dd = _twoDigits(placedAt.day);
    return 'ORD-$yy$mm$dd-${sequence.toString().padLeft(4, '0')}';
  }

  static String _twoDigits(int value) => value.toString().padLeft(2, '0');
}
