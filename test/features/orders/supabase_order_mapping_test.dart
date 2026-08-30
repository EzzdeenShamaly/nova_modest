import 'package:flutter_test/flutter_test.dart';
import 'package:nova_modest/features/address/domain/entities/address.dart';
import 'package:nova_modest/features/cart/domain/entities/cart_item.dart';
import 'package:nova_modest/features/cart/domain/entities/cart_totals.dart';
import 'package:nova_modest/features/catalog/domain/entities/product.dart';
import 'package:nova_modest/features/checkout/domain/entities/checkout_draft.dart';
import 'package:nova_modest/features/checkout/domain/entities/contact_details.dart';
import 'package:nova_modest/features/orders/data/repositories/supabase_order_repository.dart';
import 'package:nova_modest/features/orders/domain/entities/order_status.dart';

/// Covers the half of `SupabaseOrderRepository` that can break without a
/// server: turning rows and RPC payloads into an [Order].
///
/// The queries themselves are not tested here — they need a live Postgres, and
/// none of the other Supabase repositories has unit tests either. What is
/// tested is every place a column name, a status string or a numeric type can
/// be wrong, which is where this class will actually fail.
void main() {
  const coat = Product(
    id: 'p1',
    name: 'معطف كلاسيكي خفيف',
    price: 1200,
    categoryId: 'sets',
  );

  const address = Address(
    id: 'a1',
    kind: AddressKind.home,
    label: 'المنزل',
    recipientName: 'أحمد عبدالله',
    phone: '+966 11 000 0000',
    country: 'المملكة العربية السعودية',
    region: 'حي العليا',
    city: 'الرياض',
    street: 'شارع التحلية، مبنى 45',
    postalCode: '12241',
  );

  const draft = CheckoutDraft(
    contact: ContactDetails(fullName: 'سارة أحمد', phone: '+966550001111'),
    address: address,
    cart: CartTotals(subtotal: 1200, shipping: 35),
    items: [CartItem(product: coat, size: 'M')],
  );

  Map<String, dynamic> rpcResponse({String status = 'pending'}) => {
    'number': 'ORD-260818-0001',
    'placed_at': '2026-08-18T09:30:00.000Z',
    'status': status,
    'totals': {'subtotal': 1200, 'shipping': 35, 'payment_fee': 15},
  };

  Map<String, dynamic> orderRow({
    String status = 'processing',
    List<Map<String, dynamic>>? items,
  }) => {
    'number': 'ORD-260818-0001',
    'placed_at': '2026-08-18T09:30:00.000Z',
    'status': status,
    'subtotal': 1200,
    'shipping': 35,
    'payment_fee': 15,
    'contact_full_name': 'سارة أحمد',
    'contact_phone': '+966550001111',
    'contact_email': null,
    'address_kind': 'home',
    'address_label': 'المنزل',
    'address_recipient_name': 'أحمد عبدالله',
    'address_phone': '+966 11 000 0000',
    'address_country': 'المملكة العربية السعودية',
    'address_region': 'حي العليا',
    'address_city': 'الرياض',
    'address_street': 'شارع التحلية، مبنى 45',
    'address_postal_code': '12241',
    'address_notes': null,
    'order_items':
        items ??
        [
          {
            'product_id': 'p1',
            'product_name': 'معطف كلاسيكي خفيف',
            'unit_price': 1200,
            'colour_id': 'beige',
            'colour_name': 'بيج رمادي',
            'size': 'M',
            'quantity': 1,
          },
        ],
  };

  group('what place() returns', () {
    test('takes the server figures and completes them from the draft', () {
      final order = SupabaseOrderRepository.orderFromRpc(rpcResponse(), draft);

      // Only the server can know these four.
      expect(order.number, 'ORD-260818-0001');
      expect(order.placedAt.toUtc().hour, 9);
      expect(order.totals.total, 1250);
      expect(order.status, OrderStatus.pending);

      // These were just sent; the draft is still in hand, so no second read.
      expect(order.items, draft.items);
      expect(order.address, address);
      expect(order.recipientName, 'سارة أحمد');
      expect(order.recipientPhone, '+966550001111');
    });

    test('the status is the server one, never assumed', () {
      // `orders.status` carries a default. Hardcoding `processing` here — which
      // is what the fake mints — would show the shopper a stage the row is not
      // actually in.
      expect(
        SupabaseOrderRepository.orderFromRpc(
          rpcResponse(status: 'confirmed'),
          draft,
        ).status,
        OrderStatus.confirmed,
      );
    });
  });

  group('reading an order back', () {
    test('maps every column the select asks for', () {
      final order = SupabaseOrderRepository.orderFromRow(orderRow());

      expect(order.number, 'ORD-260818-0001');
      expect(order.status, OrderStatus.processing);
      expect(order.totals.subtotal, 1200);
      expect(order.totals.paymentFee, 15);
      expect(order.recipientName, 'سارة أحمد');
      expect(order.address?.city, 'الرياض');
      expect(order.address?.postalCode, '12241');
      expect(order.address?.kind, AddressKind.home);
    });

    test('rebuilds a line from what the order recorded, not the catalogue', () {
      final order = SupabaseOrderRepository.orderFromRow(orderRow());
      final line = order.items.single;

      // `order_items` stores the name and the price precisely so history does
      // not move when the shop re-prices.
      expect(line.product.name, 'معطف كلاسيكي خفيف');
      expect(line.product.price, 1200);
      expect(line.size, 'M');
      expect(line.quantity, 1);
      // The colour is named because the order named it — the swatch is not
      // recorded and no order screen draws one.
      expect(line.colour?.name, 'بيج رمادي');
    });

    test('a line with no colour or size still maps', () {
      final order = SupabaseOrderRepository.orderFromRow(
        orderRow(
          items: [
            {
              'product_id': 'p2',
              'product_name': 'وشاح حرير',
              'unit_price': 800,
              'colour_id': null,
              'colour_name': null,
              'size': null,
              'quantity': 2,
            },
          ],
        ),
      );

      final line = order.items.single;
      expect(line.colour, isNull);
      expect(line.size, isNull);
      expect(line.quantity, 2);
      expect(line.lineTotal, 1600);
    });

    test('numeric columns arrive as strings from Postgres and still parse', () {
      // `numeric` comes over the wire as a string often enough that assuming
      // `num` is how this class would break first.
      final order = SupabaseOrderRepository.orderFromRow({
        ...orderRow(),
        'subtotal': '1200.00',
        'shipping': '35',
        'payment_fee': '15',
      });

      expect(order.totals.total, 1250);
    });
  });

  group('the status strings', () {
    test('every value of public.order_status has a counterpart', () {
      // The SQL enum, in its own order. A value with no mapping would render
      // as the wrong stage on a screen the shopper is looking at.
      const fromSql = {
        'pending': OrderStatus.pending,
        'confirmed': OrderStatus.confirmed,
        'processing': OrderStatus.processing,
        'shipped': OrderStatus.shipped,
        'delivered': OrderStatus.delivered,
        'cancelled': OrderStatus.cancelled,
      };

      fromSql.forEach((value, expected) {
        expect(SupabaseOrderRepository.statusFrom(value), expected);
      });
      // And the map covers the whole Dart enum, so neither side can grow alone.
      expect(fromSql.values.toSet(), OrderStatus.values.toSet());
    });

    test('an unknown stage falls back rather than throwing', () {
      // A server that gains a stage before the app ships should leave the
      // shopper looking at the earliest one, not at a crash.
      expect(
        SupabaseOrderRepository.statusFrom('refunded'),
        OrderStatus.pending,
      );
      expect(SupabaseOrderRepository.statusFrom(null), OrderStatus.pending);
    });
  });
}
