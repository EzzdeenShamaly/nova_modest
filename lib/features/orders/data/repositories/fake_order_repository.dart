// hide Order: injectable exports an `Order` annotation for ordering its own
// registrations, which shadows this feature's entity — the same collision the
// cart hits between intl's TextDirection and dart:ui's.
import 'package:injectable/injectable.dart' hide Order;
import 'package:nova_modest/core/error/failure.dart';
import 'package:nova_modest/core/error/result.dart';
import 'package:nova_modest/features/address/domain/entities/address.dart';
import 'package:nova_modest/features/cart/domain/entities/cart_item.dart';
import 'package:nova_modest/features/catalog/domain/entities/product.dart';
import 'package:nova_modest/features/catalog/domain/entities/product_colour.dart';
import 'package:nova_modest/features/checkout/domain/entities/checkout_draft.dart';
import 'package:nova_modest/features/orders/domain/entities/order.dart';
import 'package:nova_modest/features/orders/domain/entities/order_status.dart';
import 'package:nova_modest/features/orders/domain/entities/order_totals.dart';
import 'package:nova_modest/features/orders/domain/repositories/order_repository.dart';

/// Stands in for the orders backend.
///
/// Registered in the `test` environment. The running app uses
/// `SupabaseOrderRepository`, bound to `dev` — the two coexist rather than one
/// replacing the other, which is what keeps the whole suite running against
/// predictable data with no server.
///
/// **It remembers now, and it did not.** The first version handed an order back
/// and forgot it, on the stated grounds that no screen read orders. That screen
/// exists, so the decision expired with it.
///
/// Held **in memory**, not in `SharedPreferences`: an order carries a
/// recipient's name, their phone number and where they live — the PII
/// `03-flutter-security-guard` reserves the keystore for, and the same call
/// already made for addresses and profile edits. History survives navigation,
/// not a restart.
@LazySingleton(as: OrderRepository, env: [Environment.test])
class FakeOrderRepository implements OrderRepository {
  FakeOrderRepository();

  /// Long enough for the placing state to be real, short enough not to worry
  /// someone who has just committed to paying.
  static const Duration _latency = Duration(milliseconds: 900);

  /// Newest last, as they were placed; [orders] reverses for the screen.
  late final List<Order> _orders = List<Order>.of(_seed);

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
    final contact = draft.contact;
    if (contact?.isComplete != true ||
        draft.address == null ||
        totals == null) {
      return const Err(ValidationFailure('Order is missing required details.'));
    }

    await Future<void>.delayed(_latency);

    final placedAt = DateTime.now();
    final order = Order(
      number: orderNumber(placedAt, ++_sequence),
      placedAt: placedAt,
      totals: totals,
      // Every new order starts here and stays here. Nothing on a phone moves an
      // order along — a backend does — and inventing a timer that "ships" it
      // would be inventing server behaviour (`10-evidence-and-dependency-guard`).
      status: OrderStatus.processing,
      items: draft.items,
      address: draft.address,
      recipientName: contact!.fullName,
      recipientPhone: contact.phone,
    );

    _orders.add(order);
    return Ok(order);
  }

  @override
  Future<Result<List<Order>>> orders() async {
    await Future<void>.delayed(_latency);
    return Ok(_orders.reversed.toList());
  }

  @override
  Future<Result<Order>> orderByNumber(String number) async {
    await Future<void>.delayed(_latency);

    final match = _orders.where((order) => order.number == number).firstOrNull;
    return match == null ? const Err(NotFoundFailure()) : Ok(match);
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

  // --- Seeded history ------------------------------------------------------
  //
  // The three orders `1:1356` draws, with their own numbers, dates, totals and
  // the three different badges — so the screen can be reviewed as designed
  // rather than against an empty list. The same call `FakeAddressRepository`
  // made with the two addresses its frame draws.
  //
  // Their products are **literals, not catalogue lookups**, and that is the
  // correct shape rather than a shortcut: an order records what was bought at
  // the price it was bought for. A line that re-read today's catalogue would
  // rewrite history every time the shop re-priced.

  static const Address _seedAddress = Address(
    id: 'a1',
    kind: AddressKind.home,
    label: 'المنزل',
    recipientName: 'سارة أحمد',
    phone: '+966 50 123 4567',
    country: 'المملكة العربية السعودية',
    region: 'حي العليا',
    city: 'الرياض',
    street: 'شارع التحلية، مبنى ٤٥',
    postalCode: '١٢٢١١',
    isDefault: true,
  );

  /// `final`, not `const`: `DateTime` has no const constructor, so a dated
  /// order cannot be one.
  static final List<Order> _seed = [
    Order(
      number: 'ORD-020624-0018',
      placedAt: DateTime(2024, 6, 2),
      totals: const OrderTotals(subtotal: 800, shipping: 35, paymentFee: 15),
      status: OrderStatus.delivered,
      items: const [
        CartItem(
          product: Product(
            id: 'seed-scarf',
            name: 'وشاح حرير زيتوني',
            price: 800,
            categoryId: 'hijab-shawls',
          ),
        ),
      ],
      address: _seedAddress,
      recipientName: 'سارة أحمد',
      recipientPhone: '+966 50 123 4567',
    ),
    Order(
      number: 'ORD-150724-0042',
      placedAt: DateTime(2024, 7, 15),
      totals: const OrderTotals(subtotal: 3370, shipping: 35, paymentFee: 15),
      status: OrderStatus.shipped,
      // Three lines, so the card shows one thumbnail and «+2».
      items: const [
        CartItem(
          product: Product(
            id: 'seed-abaya',
            name: 'عباية كريب سوداء',
            price: 1600,
            categoryId: 'abayas',
          ),
          size: 'M',
        ),
        CartItem(
          product: Product(
            id: 'seed-dress',
            name: 'فستان سهرة حريري',
            price: 1250,
            categoryId: 'dresses',
          ),
          size: 'S',
        ),
        CartItem(
          product: Product(
            id: 'seed-bag',
            name: 'حقيبة يد جلدية',
            price: 520,
            categoryId: 'accessories',
          ),
        ),
      ],
      address: _seedAddress,
      recipientName: 'سارة أحمد',
      recipientPhone: '+966 50 123 4567',
    ),
    Order(
      number: 'ORD-260818-0001',
      placedAt: DateTime(2024, 8, 26),
      totals: const OrderTotals(subtotal: 1200, shipping: 35, paymentFee: 15),
      status: OrderStatus.processing,
      items: const [
        CartItem(
          product: Product(
            id: 'seed-coat',
            name: 'معطف كلاسيكي خفيف',
            price: 1200,
            categoryId: 'sets',
            colours: [
              ProductColour(id: 'beige', name: 'بيج رمادي', hex: '#C9C0B2'),
            ],
          ),
          colourId: 'beige',
          size: 'M',
        ),
      ],
      address: _seedAddress,
      recipientName: 'سارة أحمد',
      recipientPhone: '+966 50 123 4567',
    ),
  ];
}
