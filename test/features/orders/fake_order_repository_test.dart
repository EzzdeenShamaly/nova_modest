import 'package:flutter_test/flutter_test.dart';
import 'package:nova_modest/core/error/failure.dart';
import 'package:nova_modest/core/error/result.dart';
import 'package:nova_modest/features/address/domain/entities/address.dart';
import 'package:nova_modest/features/cart/domain/entities/cart_totals.dart';
import 'package:nova_modest/features/orders/data/repositories/fake_order_repository.dart';
import 'package:nova_modest/features/checkout/domain/entities/checkout_draft.dart';
import 'package:nova_modest/features/checkout/domain/entities/contact_details.dart';
import 'package:nova_modest/features/orders/domain/entities/order.dart';
import 'package:nova_modest/features/orders/domain/entities/order_status.dart';

void main() {
  const address = Address(
    id: 'a1',
    kind: AddressKind.home,
    label: 'المنزل',
    recipientName: 'سارة أحمد',
    phone: '+966550001111',
    country: 'المملكة العربية السعودية',
    region: 'حي العليا',
    city: 'الرياض',
    street: 'شارع التحلية، مبنى 45',
    postalCode: '12241',
  );

  const complete = CheckoutDraft(
    contact: ContactDetails(fullName: 'سارة أحمد', phone: '+966550001111'),
    address: address,
    cart: CartTotals(subtotal: 450, shipping: 35),
  );

  late FakeOrderRepository repository;

  setUp(() => repository = FakeOrderRepository());

  Future<List<Order>> allOrders() async {
    final result = await repository.orders();
    return switch (result) {
      Ok(:final value) => value,
      Err(:final failure) => fail('expected orders, got $failure'),
    };
  }

  Future<Order> place(CheckoutDraft draft) async {
    final result = await repository.place(draft);
    return switch (result) {
      Ok(:final value) => value,
      Err(:final failure) => fail('expected an order, got $failure'),
    };
  }

  group('the order number', () {
    test('is ORD-YYMMDD-NNNN, as the confirmation screen quotes it', () {
      final number = FakeOrderRepository.orderNumber(DateTime(2026, 8, 18), 1);
      // `1:2137` shows exactly this.
      expect(number, 'ORD-260818-0001');
    });

    test('pads a single-digit month and day', () {
      expect(
        FakeOrderRepository.orderNumber(DateTime(2026, 1, 5), 42),
        'ORD-260105-0042',
      );
    });

    test('carries the date the order was placed', () async {
      final order = await place(complete);
      final today = DateTime.now();

      expect(
        order.number,
        FakeOrderRepository.orderNumber(today, 1),
        reason: 'the number is stamped with placedAt, not a fixed date',
      );
      expect(order.placedAt.day, today.day);
    });

    test('a second order does not reuse the first number', () async {
      final first = await place(complete);
      final second = await place(complete);

      expect(first.number, isNot(second.number));
    });
  });

  group('the history it keeps', () {
    test('starts with the three orders the list frame draws', () async {
      final orders = await allOrders();

      // `1:1356` draws exactly these, one per badge appearance.
      expect(orders.map((order) => order.number), [
        'ORD-260818-0001',
        'ORD-150724-0042',
        'ORD-020624-0018',
      ]);
      expect(orders.map((order) => order.status), [
        OrderStatus.processing,
        OrderStatus.shipped,
        OrderStatus.delivered,
      ]);
    });

    test('newest first, so a fresh order leads the list', () async {
      final placed = await place(complete);
      final orders = await allOrders();

      expect(orders.first.number, placed.number);
      expect(orders, hasLength(4));
    });

    test(
      'a placed order records what was ordered, not a reference to it',
      () async {
        // The cart is emptied moments later and the draft dies with the flow, so
        // an order holding ids would hold nothing.
        final placed = await place(complete);

        expect(placed.address, address);
        expect(placed.recipientName, 'سارة أحمد');
        expect(placed.recipientPhone, '+966550001111');
        expect(placed.totals, complete.totals);
      },
    );

    test('a new order starts as processing and stays there', () async {
      final placed = await place(complete);

      // Nothing on a phone moves an order along; a backend does.
      expect(placed.status, OrderStatus.processing);
    });

    test(
      'one order can be found by the number the shopper was quoted',
      () async {
        final placed = await place(complete);

        final found = await repository.orderByNumber(placed.number);
        expect(switch (found) {
          Ok(:final value) => value.number,
          Err() => null,
        }, placed.number);
      },
    );

    test(
      'an unknown number is a NotFoundFailure, not an empty order',
      () async {
        final result = await repository.orderByNumber('ORD-000000-9999');

        expect(switch (result) {
          Err(:final failure) => failure,
          Ok() => null,
        }, isA<NotFoundFailure>());
      },
    );

    test('the seeded three carry lines, so the cards have a picture', () async {
      final orders = await allOrders();

      expect(orders.every((order) => order.items.isNotEmpty), isTrue);
      // The middle one has three lines, which is what draws the frame's «+2».
      final threeLines = orders.firstWhere(
        (order) => order.number == 'ORD-150724-0042',
      );
      expect(threeLines.hiddenItemCount, 2);
      expect(threeLines.itemCount, 3);
    });
  });

  group('what comes back', () {
    test('the totals are the ones the draft worked out', () async {
      final order = await place(complete);

      // 450 + 35 shipping + 15 cash-on-delivery fee.
      expect(order.totals, complete.totals);
      expect(order.totals.total, 500);
    });
  });

  group('an incomplete draft is refused at the seam', () {
    Future<Failure> failureFor(CheckoutDraft draft) async {
      final result = await repository.place(draft);
      return switch (result) {
        Err(:final failure) => failure,
        Ok() => fail('expected a refusal'),
      };
    }

    test('with no address', () async {
      // Unreachable through the UI, which cannot show the review without one.
      // Refused here rather than discovered at the warehouse.
      expect(
        await failureFor(complete.copyWith(address: null)),
        isA<ValidationFailure>(),
      );
    });

    test('with an empty contact', () async {
      expect(
        await failureFor(complete.copyWith(contact: const ContactDetails())),
        isA<ValidationFailure>(),
      );
    });

    test('with no cart behind it', () async {
      expect(
        await failureFor(complete.copyWith(cart: null)),
        isA<ValidationFailure>(),
      );
    });

    test('and refusing does not consume a number', () async {
      await repository.place(complete.copyWith(address: null));
      final order = await place(complete);

      expect(order.number, endsWith('-0001'));
    });
  });
}
