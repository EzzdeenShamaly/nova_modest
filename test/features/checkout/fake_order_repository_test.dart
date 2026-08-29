import 'package:flutter_test/flutter_test.dart';
import 'package:nova_modest/core/error/failure.dart';
import 'package:nova_modest/core/error/result.dart';
import 'package:nova_modest/features/address/domain/entities/address.dart';
import 'package:nova_modest/features/cart/domain/entities/cart_totals.dart';
import 'package:nova_modest/features/checkout/data/repositories/fake_order_repository.dart';
import 'package:nova_modest/features/checkout/domain/entities/checkout_draft.dart';
import 'package:nova_modest/features/checkout/domain/entities/contact_details.dart';
import 'package:nova_modest/features/checkout/domain/entities/order.dart';

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
