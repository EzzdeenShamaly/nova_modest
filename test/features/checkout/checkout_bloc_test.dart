import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nova_modest/features/address/domain/entities/address.dart';
import 'package:nova_modest/features/auth/domain/entities/user.dart';
import 'package:nova_modest/features/cart/domain/entities/cart_totals.dart';
import 'package:nova_modest/features/orders/domain/entities/order_totals.dart';
import 'package:nova_modest/features/checkout/domain/entities/payment_method.dart';
import 'package:nova_modest/features/checkout/domain/entities/shipping_method.dart';
import 'package:nova_modest/features/checkout/domain/entities/checkout_draft.dart';
import 'package:nova_modest/features/checkout/domain/entities/checkout_step.dart';
import 'package:nova_modest/features/checkout/domain/entities/contact_details.dart';
import 'package:nova_modest/core/error/failure.dart';
import 'package:nova_modest/core/error/result.dart';
import 'package:nova_modest/features/orders/domain/entities/order.dart';
import 'package:nova_modest/features/orders/domain/entities/order_status.dart';
import 'package:nova_modest/features/orders/domain/repositories/order_repository.dart';
import 'package:nova_modest/features/checkout/presentation/bloc/checkout_bloc.dart';

class _MockOrderRepository extends Mock implements OrderRepository {}

void main() {
  late _MockOrderRepository orders;

  /// Every test builds through this, so adding a dependency to the bloc is one
  /// edit rather than one per `blocTest`.
  CheckoutBloc buildBloc() => CheckoutBloc(orders);

  setUpAll(() => registerFallbackValue(const CheckoutDraft()));

  setUp(() => orders = _MockOrderRepository());

  const user = User(
    id: 'u1',
    email: 'sara@example.com',
    displayName: 'سارة',
    phone: '+966 50 123 4567',
  );

  const typed = ContactDetails(fullName: 'سارة أحمد', phone: '+966550001111');

  const home = Address(
    id: 'a1',
    kind: AddressKind.home,
    label: 'المنزل',
    recipientName: 'سارة أحمد',
    phone: '+966550001111',
    country: 'المملكة العربية السعودية',
    region: 'حي العليا',
    city: 'الرياض',
    street: 'شارع التحلية، مبنى 45',
    isDefault: true,
  );

  const work = Address(
    id: 'a2',
    kind: AddressKind.work,
    label: 'العمل',
    recipientName: 'سارة أحمد',
    phone: '+966550001111',
    country: 'المملكة العربية السعودية',
    region: 'حي الشاطئ',
    city: 'جدة',
    street: 'طريق الكورنيش، برج الأعمال',
  );

  group('the step order', () {
    test('the design counts three, and review is not one of them', () {
      // 1:2163, 1:1944 and 1:2059 each carry an indicator; 1:1840 does not.
      expect(CheckoutStep.indicatorCount, 3);
      expect(CheckoutStep.contact.indicatorIndex, 0);
      expect(CheckoutStep.address.indicatorIndex, 1);
      expect(CheckoutStep.payment.indicatorIndex, 2);
      expect(CheckoutStep.review.indicatorIndex, isNull);
      expect(CheckoutStep.success.indicatorIndex, isNull);
    });

    test('runs contact to success', () {
      expect(CheckoutStep.contact.next, CheckoutStep.address);
      expect(CheckoutStep.address.next, CheckoutStep.payment);
      expect(CheckoutStep.payment.next, CheckoutStep.review);
      expect(CheckoutStep.review.next, CheckoutStep.success);
      expect(CheckoutStep.success.next, isNull);
    });

    test('the first step has nowhere back, and success is terminal', () {
      // Null is what tells the host to leave checkout rather than move inside
      // it — and going "back" from success would offer to place the order
      // again.
      expect(CheckoutStep.contact.previous, isNull);
      expect(CheckoutStep.success.previous, isNull);
      expect(CheckoutStep.address.previous, CheckoutStep.contact);
      expect(CheckoutStep.review.previous, CheckoutStep.payment);
    });
  });

  group('opening', () {
    blocTest<CheckoutBloc, CheckoutState>(
      'a signed-in shopper starts pre-filled, email included',
      build: buildBloc,
      act: (bloc) => bloc.add(const CheckoutStarted(user: user)),
      expect: () => const [
        CheckoutInProgress(
          draft: CheckoutDraft(
            contact: ContactDetails(
              fullName: 'سارة',
              phone: '+966 50 123 4567',
              // Not a field on the form: it rides along from the account so the
              // review screen can show it.
              email: 'sara@example.com',
            ),
          ),
        ),
      ],
    );

    blocTest<CheckoutBloc, CheckoutState>(
      'a guest starts empty, with no email at all',
      build: buildBloc,
      act: (bloc) => bloc.add(const CheckoutStarted()),
      expect: () => const [
        CheckoutInProgress(draft: CheckoutDraft(contact: ContactDetails())),
      ],
    );

    blocTest<CheckoutBloc, CheckoutState>(
      'opening twice does not overwrite what was already typed',
      build: buildBloc,
      act: (bloc) => bloc
        ..add(const CheckoutStarted(user: user))
        ..add(const CheckoutStarted(user: user)),
      // droppable: a second start would re-seed the fields over the shopper's
      // edits.
      expect: () => const [
        CheckoutInProgress(
          draft: CheckoutDraft(
            contact: ContactDetails(
              fullName: 'سارة',
              phone: '+966 50 123 4567',
              email: 'sara@example.com',
            ),
          ),
        ),
      ],
    );

    test('opens on the first step', () {
      expect(buildBloc().state.step, CheckoutStep.contact);
    });
  });

  group('moving through', () {
    blocTest<CheckoutBloc, CheckoutState>(
      'submitting contact keeps what was typed and advances',
      build: buildBloc,
      act: (bloc) => bloc.add(const CheckoutContactSubmitted(typed)),
      expect: () => const [
        CheckoutInProgress(
          step: CheckoutStep.address,
          draft: CheckoutDraft(contact: typed),
        ),
      ],
    );

    blocTest<CheckoutBloc, CheckoutState>(
      'edits replace what the account seeded',
      build: buildBloc,
      act: (bloc) => bloc
        ..add(const CheckoutStarted(user: user))
        ..add(const CheckoutContactSubmitted(typed)),
      skip: 1,
      verify: (bloc) {
        final contact = bloc.state.draft.contact!;
        expect(contact.fullName, 'سارة أحمد');
        expect(contact.phone, '+966550001111');
      },
    );

    blocTest<CheckoutBloc, CheckoutState>(
      'choosing an address keeps the contact and advances to payment',
      build: buildBloc,
      act: (bloc) => bloc
        ..add(const CheckoutContactSubmitted(typed))
        ..add(const CheckoutAddressSelected(home)),
      skip: 1,
      expect: () => const [
        CheckoutInProgress(
          step: CheckoutStep.payment,
          draft: CheckoutDraft(contact: typed, address: home),
        ),
      ],
    );

    blocTest<CheckoutBloc, CheckoutState>(
      'the whole address is carried, not its id',
      build: buildBloc,
      act: (bloc) => bloc
        ..add(const CheckoutContactSubmitted(typed))
        ..add(const CheckoutAddressSelected(home)),
      verify: (bloc) {
        // The review screen draws the address in full; holding an id would
        // make it fetch the list it does not otherwise need.
        expect(bloc.state.draft.address?.city, 'الرياض');
        expect(bloc.state.draft.address?.shortSummary, home.shortSummary);
      },
    );

    blocTest<CheckoutBloc, CheckoutState>(
      'walking back and choosing again replaces the address',
      build: buildBloc,
      act: (bloc) => bloc
        ..add(const CheckoutContactSubmitted(typed))
        ..add(const CheckoutAddressSelected(home))
        ..add(const CheckoutBackRequested())
        ..add(const CheckoutAddressSelected(work)),
      verify: (bloc) {
        expect(bloc.state.draft.address, work);
        expect(bloc.state.step, CheckoutStep.payment);
      },
    );

    blocTest<CheckoutBloc, CheckoutState>(
      'a step-submit advances from wherever the flow is, not to a fixed step',
      build: buildBloc,
      // Both submit events share this shape. It is why the step lives in bloc
      // state and the UI dispatches only from the step that owns the event —
      // `AddressStep` renders on `CheckoutStep.address` and nowhere else.
      act: (bloc) => bloc.add(const CheckoutAddressSelected(home)),
      expect: () => const [
        CheckoutInProgress(
          step: CheckoutStep.address,
          draft: CheckoutDraft(address: home),
        ),
      ],
    );

    blocTest<CheckoutBloc, CheckoutState>(
      'back from the address step keeps the address it collected',
      build: buildBloc,
      act: (bloc) => bloc
        ..add(const CheckoutContactSubmitted(typed))
        ..add(const CheckoutAddressSelected(home))
        ..add(const CheckoutBackRequested()),
      verify: (bloc) {
        // Returning to the step must show the card already chosen.
        expect(bloc.state.step, CheckoutStep.address);
        expect(bloc.state.draft.address, home);
      },
    );

    blocTest<CheckoutBloc, CheckoutState>(
      'back moves within the flow',
      build: buildBloc,
      act: (bloc) => bloc
        ..add(const CheckoutContactSubmitted(typed))
        ..add(const CheckoutBackRequested()),
      skip: 1,
      expect: () => const [
        CheckoutInProgress(
          step: CheckoutStep.contact,
          draft: CheckoutDraft(contact: typed),
        ),
      ],
    );

    blocTest<CheckoutBloc, CheckoutState>(
      'back at the first step emits nothing, so the host can leave',
      build: buildBloc,
      act: (bloc) => bloc.add(const CheckoutBackRequested()),
      expect: () => const <CheckoutState>[],
    );

    blocTest<CheckoutBloc, CheckoutState>(
      'going back does not discard what a later step collected',
      build: buildBloc,
      act: (bloc) => bloc
        ..add(const CheckoutStarted(user: user))
        ..add(const CheckoutContactSubmitted(typed))
        ..add(const CheckoutBackRequested()),
      verify: (bloc) {
        // Returning to a step must show what was entered, not an empty form.
        expect(bloc.state.step, CheckoutStep.contact);
        expect(bloc.state.draft.contact, typed);
      },
    );
  });

  group('shipping and payment', () {
    // The frame's own figures: 450 + 35 + 15 = 500.
    const cart = CartTotals(subtotal: 450, shipping: 35);

    test('a draft opens with both already chosen', () {
      // `1:2059` draws them selected, there is one shipping method and one
      // available payment method — so "nothing chosen yet" is a state the flow
      // never has, and the fields are not nullable.
      const draft = CheckoutDraft();
      expect(draft.shipping, ShippingMethod.standard);
      expect(draft.payment, PaymentMethod.cashOnDelivery);
    });

    test('the totals are the four figures the frame ends on', () {
      const draft = CheckoutDraft(cart: cart);
      final totals = draft.totals!;

      expect(totals.subtotal, 450);
      expect(totals.shipping, 35);
      expect(totals.paymentFee, 15);
      expect(totals.total, 500);
    });

    test('there are no totals before the cart is known', () {
      // A guest opening checkout on an empty cart, or a test that does not
      // care about money.
      expect(const CheckoutDraft().totals, isNull);
    });

    test('the chosen method decides the shipping, not the cart quote', () {
      // They agree today because both are 35. Written so they still agree when
      // a second method makes them differ.
      const draft = CheckoutDraft(
        cart: CartTotals(subtotal: 450, shipping: 999),
      );
      expect(draft.totals!.shipping, ShippingMethod.standard.cost);
    });

    test('the card charges no fee, and cannot be chosen', () {
      // Drawn by the frame under "قريباً", so it exists as an unavailable
      // option rather than being dropped.
      expect(PaymentMethod.card.isAvailable, isFalse);
      expect(PaymentMethod.cashOnDelivery.isAvailable, isTrue);
      expect(PaymentMethod.card.fee, 0);
    });

    blocTest<CheckoutBloc, CheckoutState>(
      'submitting the step keeps both choices and advances to review',
      build: buildBloc,
      act: (bloc) => bloc
        ..add(const CheckoutStarted(cart: cart))
        ..add(const CheckoutContactSubmitted(typed))
        ..add(const CheckoutAddressSelected(home))
        ..add(
          const CheckoutPaymentSubmitted(
            shipping: ShippingMethod.standard,
            payment: PaymentMethod.cashOnDelivery,
          ),
        ),
      verify: (bloc) {
        expect(bloc.state.step, CheckoutStep.review);
        expect(bloc.state.draft.payment, PaymentMethod.cashOnDelivery);
        expect(bloc.state.draft.totals?.total, 500);
      },
    );

    blocTest<CheckoutBloc, CheckoutState>(
      'opening carries the cart into the draft',
      build: buildBloc,
      act: (bloc) => bloc.add(const CheckoutStarted(user: user, cart: cart)),
      verify: (bloc) => expect(bloc.state.draft.cart, cart),
    );

    blocTest<CheckoutBloc, CheckoutState>(
      'back from review keeps what the step collected',
      build: buildBloc,
      act: (bloc) => bloc
        ..add(const CheckoutStarted(cart: cart))
        ..add(const CheckoutContactSubmitted(typed))
        ..add(const CheckoutAddressSelected(home))
        ..add(
          const CheckoutPaymentSubmitted(
            shipping: ShippingMethod.standard,
            payment: PaymentMethod.cashOnDelivery,
          ),
        )
        ..add(const CheckoutBackRequested()),
      verify: (bloc) {
        expect(bloc.state.step, CheckoutStep.payment);
        expect(bloc.state.draft.shipping, ShippingMethod.standard);
      },
    );
  });

  group('editing from the review', () {
    const cart = CartTotals(subtotal: 450, shipping: 35);

    /// Walks the three steps, leaving the bloc on the review.
    void walkToReview(CheckoutBloc bloc) => bloc
      ..add(const CheckoutStarted(cart: cart))
      ..add(const CheckoutContactSubmitted(typed))
      ..add(const CheckoutAddressSelected(home))
      ..add(
        const CheckoutPaymentSubmitted(
          shipping: ShippingMethod.standard,
          payment: PaymentMethod.cashOnDelivery,
        ),
      );

    blocTest<CheckoutBloc, CheckoutState>(
      'a link jumps back to its own step, keeping everything collected',
      build: buildBloc,
      act: (bloc) {
        walkToReview(bloc);
        bloc.add(const CheckoutStepRequested(CheckoutStep.contact));
      },
      verify: (bloc) {
        expect(bloc.state.step, CheckoutStep.contact);
        expect(bloc.state.draft.address, home);
        expect(bloc.state.draft.payment, PaymentMethod.cashOnDelivery);
      },
    );

    blocTest<CheckoutBloc, CheckoutState>(
      'finishing the edit returns to the review, not one step forward',
      build: buildBloc,
      act: (bloc) {
        walkToReview(bloc);
        bloc
          ..add(const CheckoutStepRequested(CheckoutStep.contact))
          ..add(const CheckoutBackRequested());
      },
      verify: (bloc) => expect(bloc.state.step, CheckoutStep.review),
    );

    blocTest<CheckoutBloc, CheckoutState>(
      'the return happens once, then back walks normally again',
      build: buildBloc,
      act: (bloc) {
        walkToReview(bloc);
        bloc
          ..add(const CheckoutStepRequested(CheckoutStep.address))
          ..add(const CheckoutBackRequested())
          ..add(const CheckoutBackRequested());
      },
      // Review, then back one step the ordinary way.
      verify: (bloc) => expect(bloc.state.step, CheckoutStep.payment),
    );

    blocTest<CheckoutBloc, CheckoutState>(
      'a jump forward is dropped, because it would skip a step',
      build: buildBloc,
      act: (bloc) => bloc
        ..add(const CheckoutStarted(cart: cart))
        ..add(const CheckoutStepRequested(CheckoutStep.review)),
      // Only the opening state; the jump emitted nothing.
      verify: (bloc) => expect(bloc.state.step, CheckoutStep.contact),
    );

    blocTest<CheckoutBloc, CheckoutState>(
      'a jump to the step already showing is dropped too',
      build: buildBloc,
      act: (bloc) => bloc
        ..add(const CheckoutStarted(cart: cart))
        ..add(const CheckoutStepRequested(CheckoutStep.contact)),
      verify: (bloc) => expect(bloc.state.step, CheckoutStep.contact),
    );
  });

  group('placing the order', () {
    const cart = CartTotals(subtotal: 450, shipping: 35);

    final placed = Order(
      number: 'ORD-260818-0001',
      placedAt: DateTime(2026, 8, 18),
      totals: const OrderTotals(subtotal: 450, shipping: 35, paymentFee: 15),
      status: OrderStatus.processing,
    );

    const ready = CheckoutInProgress(
      step: CheckoutStep.review,
      draft: CheckoutDraft(contact: typed, address: home, cart: cart),
    );

    blocTest<CheckoutBloc, CheckoutState>(
      'shows the order being placed, then lands on success',
      build: buildBloc,
      seed: () => ready,
      setUp: () =>
          when(() => orders.place(any())).thenAnswer((_) async => Ok(placed)),
      act: (bloc) => bloc.add(const CheckoutConfirmed()),
      expect: () => [
        // The whole sequence: asserting only the last state would hide a
        // missing placing emission, which is what makes a button look dead.
        CheckoutPlacing(step: CheckoutStep.review, draft: ready.draft),
        CheckoutInProgress(
          step: CheckoutStep.success,
          draft: ready.draft.copyWith(order: placed),
        ),
      ],
    );

    blocTest<CheckoutBloc, CheckoutState>(
      'a failure keeps the draft and stays on the review',
      build: buildBloc,
      seed: () => ready,
      setUp: () => when(
        () => orders.place(any()),
      ).thenAnswer((_) async => const Err(NetworkFailure())),
      act: (bloc) => bloc.add(const CheckoutConfirmed()),
      expect: () => [
        CheckoutPlacing(step: CheckoutStep.review, draft: ready.draft),
        CheckoutFailed(
          step: CheckoutStep.review,
          draft: ready.draft,
          failure: const NetworkFailure(),
        ),
      ],
    );

    blocTest<CheckoutBloc, CheckoutState>(
      'confirming twice places one order',
      build: buildBloc,
      seed: () => ready,
      setUp: () => when(() => orders.place(any())).thenAnswer((_) async {
        // Latency, or nothing overlaps and droppable is never exercised.
        await Future<void>.delayed(const Duration(milliseconds: 50));
        return Ok(placed);
      }),
      act: (bloc) => bloc
        ..add(const CheckoutConfirmed())
        ..add(const CheckoutConfirmed()),
      wait: const Duration(milliseconds: 120),
      verify: (_) => verify(() => orders.place(any())).called(1),
    );

    blocTest<CheckoutBloc, CheckoutState>(
      'the draft carries the placed order afterwards',
      build: buildBloc,
      seed: () => ready,
      setUp: () =>
          when(() => orders.place(any())).thenAnswer((_) async => Ok(placed)),
      act: (bloc) => bloc.add(const CheckoutConfirmed()),
      verify: (bloc) {
        // The confirmation screen reads its number from here.
        expect(bloc.state.draft.order?.number, 'ORD-260818-0001');
      },
    );

    test('success is terminal, so back leaves checkout', () {
      expect(CheckoutStep.success.previous, isNull);
    });
  });

  group('the draft', () {
    test('carries only what a built step fills in', () {
      // Shipping and payment gain fields when their steps are built; a
      // placeholder now would guess a shape only the frame can settle.
      const draft = CheckoutDraft(contact: typed, address: home);
      expect(draft.contact, typed);
      expect(draft.address, home);
      expect(draft, const CheckoutDraft(contact: typed, address: home));
      expect(draft, isNot(const CheckoutDraft(contact: typed)));
      expect(draft, isNot(const CheckoutDraft()));
    });

    test('completeness is about the two collected fields', () {
      expect(const ContactDetails().isComplete, isFalse);
      expect(const ContactDetails(fullName: 'سارة').isComplete, isFalse);
      expect(const ContactDetails(phone: '0500000000').isComplete, isFalse);
      expect(typed.isComplete, isTrue);
      // Whitespace is not an answer.
      expect(
        const ContactDetails(fullName: '  ', phone: '  ').isComplete,
        isFalse,
      );
    });
  });
}
