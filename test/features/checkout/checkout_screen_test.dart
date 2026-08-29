import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nova_modest/core/error/failure.dart';
import 'package:nova_modest/core/theme/app_colors.dart';
import 'package:nova_modest/core/widgets/failure_view.dart';
import 'package:nova_modest/core/widgets/placeholder_tab.dart';
import 'package:nova_modest/features/address/domain/entities/address.dart';
import 'package:nova_modest/features/address/presentation/bloc/address_form_bloc.dart';
import 'package:nova_modest/features/address/presentation/bloc/address_list_bloc.dart';
import 'package:nova_modest/features/address/presentation/widgets/address_form.dart';
import 'package:nova_modest/features/cart/domain/entities/cart_item.dart';
import 'package:nova_modest/features/cart/domain/entities/cart_totals.dart';
import 'package:nova_modest/features/catalog/domain/entities/product.dart';
import 'package:nova_modest/features/catalog/domain/entities/product_colour.dart';
import 'package:nova_modest/features/checkout/domain/entities/payment_method.dart';
import 'package:nova_modest/features/checkout/domain/entities/shipping_method.dart';
import 'package:nova_modest/features/checkout/domain/entities/checkout_draft.dart';
import 'package:nova_modest/features/checkout/domain/entities/checkout_step.dart';
import 'package:nova_modest/features/checkout/domain/entities/contact_details.dart';
import 'package:nova_modest/features/checkout/presentation/bloc/checkout_bloc.dart';
import 'package:nova_modest/features/checkout/presentation/screens/checkout_screen.dart';
import 'package:nova_modest/features/checkout/presentation/widgets/address_step.dart';
import 'package:nova_modest/features/checkout/presentation/widgets/checkout_step_indicator.dart';
import 'package:nova_modest/features/checkout/presentation/widgets/contact_step.dart';
import 'package:nova_modest/features/checkout/presentation/widgets/payment_step.dart';
import 'package:nova_modest/features/checkout/presentation/widgets/review_step.dart';

import '../../helpers/pump_app.dart';
import '../../helpers/screen_blocs.dart';

class _MockCheckoutBloc extends MockBloc<CheckoutEvent, CheckoutState>
    implements CheckoutBloc {}

void main() {
  late _MockCheckoutBloc bloc;
  late MockAddressListBloc addressList;
  late MockAddressFormBloc addressForm;

  const home = Address(
    id: 'a1',
    kind: AddressKind.home,
    label: 'المنزل',
    recipientName: 'السيد أحمد عبدالله',
    phone: '+966 50 123 4567',
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
    recipientName: 'السيد أحمد عبدالله',
    phone: '+966 11 987 6543',
    country: 'المملكة العربية السعودية',
    region: 'حي الشاطئ',
    city: 'جدة',
    street: 'طريق الكورنيش، برج الأعمال',
  );

  const seeded = ContactDetails(
    fullName: 'سارة',
    phone: '+966 50 123 4567',
    email: 'sara@example.com',
  );

  setUpAll(() {
    registerFallbackValue(const CheckoutBackRequested());
    registerFallbackValue(const AddressFormSubmitted(home));
    return loadAppFonts();
  });

  setUp(() {
    bloc = _MockCheckoutBloc();
    // The default is Empty rather than Loading: a spinner animates forever and
    // every pump here ends in pumpAndSettle.
    addressList = stubAddressListBloc(const AddressListEmpty());
    addressForm = stubAddressFormBloc();
  });

  /// Provides the two address blocs the way the checkout `ShellRoute` does —
  /// above the screen, not inside it. Hand-wrapping them inside the step is the
  /// mistake that let the addresses screen ship a provider the pushed form
  /// could not see.
  Future<void> pump(
    WidgetTester tester,
    CheckoutState state, {
    Locale? locale,
    AddressListState? addresses,
    Stream<CheckoutState>? states,
    bool settle = true,
  }) async {
    whenListen(
      bloc,
      states ?? Stream<CheckoutState>.value(state),
      initialState: state,
    );
    if (addresses != null) addressList = stubAddressListBloc(addresses);

    await tester.pumpApp(
      MultiBlocProvider(
        providers: [
          BlocProvider<CheckoutBloc>.value(value: bloc),
          BlocProvider<AddressListBloc>.value(value: addressList),
          BlocProvider<AddressFormBloc>.value(value: addressForm),
        ],
        child: CheckoutScreen(key: UniqueKey()),
      ),
      locale: locale ?? const Locale('ar'),
    );
    // A spinner animates forever, so a placing state cannot be settled.
    if (settle) {
      await tester.pumpAndSettle();
    } else {
      await tester.pump();
    }
  }

  /// The one control that carries the flow forward, whatever it is called on
  /// the step being tested.
  Future<void> tapForward(WidgetTester tester) async {
    await tester.tap(find.byType(FilledButton).last);
    await tester.pumpAndSettle();
  }

  CheckoutAddressSelected capturedSelection() =>
      verify(
            () => bloc.add(captureAny(that: isA<CheckoutAddressSelected>())),
          ).captured.single
          as CheckoutAddressSelected;

  Finder fieldWith(String value) => find.widgetWithText(TextFormField, value);

  group('the contact step', () {
    testWidgets('opens pre-filled for a signed-in shopper', (tester) async {
      await pump(
        tester,
        const CheckoutInProgress(draft: CheckoutDraft(contact: seeded)),
      );

      expect(find.text('معلومات التواصل'), findsWidgets);
      expect(fieldWith('سارة'), findsOneWidget);
      // The dialling code lives in its own control, so it is not repeated in
      // the number field.
      expect(fieldWith('50 123 4567'), findsOneWidget);
    });

    testWidgets('opens empty for a guest', (tester) async {
      await pump(
        tester,
        const CheckoutInProgress(
          draft: CheckoutDraft(contact: ContactDetails()),
        ),
      );

      final fields = tester.widgetList<TextFormField>(
        find.byType(TextFormField),
      );
      expect(fields, hasLength(2));
      expect(find.text('سارة'), findsNothing);
    });

    testWidgets('refuses to advance while a field is empty', (tester) async {
      await pump(
        tester,
        const CheckoutInProgress(
          draft: CheckoutDraft(contact: ContactDetails()),
        ),
      );

      await tester.tap(find.text('التالي'));
      await tester.pumpAndSettle();

      expect(find.text('الاسم مطلوب'), findsWidgets);
      verifyNever(() => bloc.add(any(that: isA<CheckoutContactSubmitted>())));
    });

    testWidgets('submits the name and the number with its code', (
      tester,
    ) async {
      await pump(
        tester,
        const CheckoutInProgress(
          draft: CheckoutDraft(contact: ContactDetails()),
        ),
      );

      await tester.enterText(find.byType(TextFormField).at(0), 'ليلى أحمد');
      await tester.enterText(find.byType(TextFormField).at(1), '550001111');
      await tester.pumpAndSettle();
      await tester.tap(find.text('التالي'));
      await tester.pumpAndSettle();

      final captured =
          verify(
                () =>
                    bloc.add(captureAny(that: isA<CheckoutContactSubmitted>())),
              ).captured.single
              as CheckoutContactSubmitted;

      expect(captured.contact.fullName, 'ليلى أحمد');
      expect(captured.contact.phone, '+966 550001111');
    });

    testWidgets('carries a signed-in email through untouched', (tester) async {
      // The frame has no email field; it rides along so the review screen can
      // show it.
      await pump(
        tester,
        const CheckoutInProgress(draft: CheckoutDraft(contact: seeded)),
      );

      await tester.tap(find.text('التالي'));
      await tester.pumpAndSettle();

      final captured =
          verify(
                () =>
                    bloc.add(captureAny(that: isA<CheckoutContactSubmitted>())),
              ).captured.single
              as CheckoutContactSubmitted;

      expect(captured.contact.email, 'sara@example.com');
    });

    testWidgets('a guest submits with no email at all', (tester) async {
      await pump(
        tester,
        const CheckoutInProgress(
          draft: CheckoutDraft(contact: ContactDetails()),
        ),
      );

      await tester.enterText(find.byType(TextFormField).at(0), 'ليلى');
      await tester.enterText(find.byType(TextFormField).at(1), '550001111');
      await tester.pumpAndSettle();
      await tester.tap(find.text('التالي'));
      await tester.pumpAndSettle();

      final captured =
          verify(
                () =>
                    bloc.add(captureAny(that: isA<CheckoutContactSubmitted>())),
              ).captured.single
              as CheckoutContactSubmitted;

      // The recorded gap: nothing to confirm a guest order to.
      expect(captured.contact.email, isNull);
    });
  });

  group('a seed that arrives after the first frame', () {
    // The bloc is created with `..add(CheckoutStarted(...))`, and an event is
    // handled one microtask later — so the first frame the app renders always
    // carries an empty draft, whatever the account holds. Pumping a seeded
    // state, as every other test here does, skips that frame entirely.
    Future<StreamController<CheckoutState>> open(WidgetTester tester) async {
      final states = StreamController<CheckoutState>();
      addTearDown(states.close);
      await pump(tester, const CheckoutInProgress(), states: states.stream);
      return states;
    }

    testWidgets('fills the fields it left empty', (tester) async {
      final states = await open(tester);

      expect(fieldWith('سارة'), findsNothing);

      states.add(
        const CheckoutInProgress(draft: CheckoutDraft(contact: seeded)),
      );
      await tester.pumpAndSettle();

      expect(fieldWith('سارة'), findsOneWidget);
      expect(fieldWith('50 123 4567'), findsOneWidget);
    });

    testWidgets('leaves alone anything the shopper has already typed', (
      tester,
    ) async {
      final states = await open(tester);

      await tester.enterText(find.byType(TextFormField).at(0), 'ليلى');
      await tester.pumpAndSettle();

      states.add(
        const CheckoutInProgress(draft: CheckoutDraft(contact: seeded)),
      );
      await tester.pumpAndSettle();

      // A shopper may be buying for someone else, which is why the frame lets
      // these be edited at all.
      expect(fieldWith('ليلى'), findsOneWidget);
      expect(fieldWith('سارة'), findsNothing);
      // The field they did not touch still takes the seed.
      expect(fieldWith('50 123 4567'), findsOneWidget);
    });
  });

  group('the step indicator', () {
    testWidgets('marks the first of three on the contact step', (tester) async {
      await pump(tester, const CheckoutInProgress());

      expect(find.byType(CheckoutStepIndicator), findsOneWidget);
      expect(
        tester
            .widget<CheckoutStepIndicator>(find.byType(CheckoutStepIndicator))
            .step
            .indicatorIndex,
        0,
      );
    });

    /// station, rail, station, rail, station — logical order, which the Row
    /// mirrors for an RTL reader.
    List<Color?> marks(WidgetTester tester) => tester
        .widgetList<Container>(
          find.descendant(
            of: find.byType(CheckoutStepIndicator),
            matching: find.byType(Container),
          ),
        )
        .map((container) => (container.decoration! as BoxDecoration).color)
        .toList();

    test('the fainter level is the part that has not happened yet', () {
      // The polarity itself, pinned independently of any one step. Swapping the
      // two back — which is how this shipped — fails here and in all three
      // tests below.
      expect(AppColors.subtle.a, greaterThan(AppColors.hairline.a));
    });

    testWidgets('step 2 draws one passed, one current, one ahead', (
      tester,
    ) async {
      await pump(tester, const CheckoutInProgress(step: CheckoutStep.address));

      // Measured from `1:1944` by absolute x, because the frames are RTL and
      // the rightmost child is step one: rightmost 8pt `#CEC5BA` (step 1,
      // passed), 12pt `#C6A75E` in the middle, leftmost 8pt `#EBE7E6` (step 3,
      // ahead) — each rail taking the colour of the side behind it.
      expect(marks(tester), [
        AppColors.subtle,
        AppColors.subtle,
        AppColors.accent,
        AppColors.hairline,
        AppColors.hairline,
      ]);
    });

    testWidgets('step 3 draws both earlier steps as passed', (tester) async {
      await pump(tester, const CheckoutInProgress(step: CheckoutStep.payment));

      // `1:2059` draws its two earlier steps in `#CEC5BA` and nothing ahead —
      // the frame that proved this file had the two levels the wrong way round.
      expect(marks(tester), [
        AppColors.subtle,
        AppColors.subtle,
        AppColors.subtle,
        AppColors.subtle,
        AppColors.accent,
      ]);
    });

    testWidgets('step 1 draws nothing as passed', (tester) async {
      await pump(tester, const CheckoutInProgress());

      expect(marks(tester), [
        AppColors.accent,
        AppColors.hairline,
        AppColors.hairline,
        AppColors.hairline,
        AppColors.hairline,
      ]);
    });

    testWidgets('is centred, as all three frames centre it', (tester) async {
      await pump(tester, const CheckoutInProgress());

      final row = tester.widget<Row>(
        find.descendant(
          of: find.byType(CheckoutStepIndicator),
          matching: find.byType(Row),
        ),
      );
      expect(row.mainAxisAlignment, MainAxisAlignment.center);
    });

    testWidgets('the current station is the largest, not only the brightest', (
      tester,
    ) async {
      await pump(tester, const CheckoutInProgress());

      final sizes = tester
          .widgetList<Container>(
            find.descendant(
              of: find.byType(CheckoutStepIndicator),
              matching: find.byType(Container),
            ),
          )
          .map((container) => tester.getSize(find.byWidget(container)).width)
          .toList();

      // Size is a second signal, so the step in progress is not carried by
      // colour alone.
      expect(sizes.first, greaterThan(sizes[2]));
    });

    testWidgets('draws nothing on review, which the design gives none', (
      tester,
    ) async {
      await pump(tester, const CheckoutInProgress(step: CheckoutStep.review));

      expect(find.byType(SizedBox), findsWidgets);
      expect(
        tester
            .widget<CheckoutStepIndicator>(find.byType(CheckoutStepIndicator))
            .step
            .indicatorIndex,
        isNull,
      );
    });
  });

  group('the address step', () {
    const onAddress = CheckoutInProgress(step: CheckoutStep.address);

    testWidgets('offers the addresses the account already holds', (
      tester,
    ) async {
      await pump(
        tester,
        onAddress,
        addresses: const AddressListLoaded([home, work]),
      );

      expect(find.byType(AddressStep), findsOneWidget);
      expect(find.text('العناوين المحفوظة'), findsOneWidget);
      expect(find.text('المنزل'), findsOneWidget);
      expect(find.text('العمل'), findsOneWidget);
      // The card draws the entity's own summary, not a second composition of
      // the same fields.
      expect(find.text(home.shortSummary), findsOneWidget);
    });

    testWidgets('marks exactly one card, and it is the default', (
      tester,
    ) async {
      // Default second on purpose. The repository sorts it first, so a step
      // that simply took `addresses.first` would pass against a realistic list
      // while depending on a sort it does not own.
      await pump(
        tester,
        onAddress,
        addresses: const AddressListLoaded([work, home]),
      );

      expect(find.byIcon(Icons.check_circle), findsOneWidget);

      // Asserted through what the step submits rather than through the tick:
      // the tick is how it looks, the dispatched address is what it does.
      await tapForward(tester);
      expect(capturedSelection().address, home);
    });

    testWidgets('tapping a card changes what is submitted', (tester) async {
      await pump(
        tester,
        onAddress,
        addresses: const AddressListLoaded([home, work]),
      );

      await tester.tap(find.text('العمل'));
      await tester.pumpAndSettle();
      await tapForward(tester);

      expect(capturedSelection().address, work);
    });

    testWidgets('reopening the step shows what the draft already chose', (
      tester,
    ) async {
      // Not the default: the shopper picked the other one before walking back.
      await pump(
        tester,
        const CheckoutInProgress(
          step: CheckoutStep.address,
          draft: CheckoutDraft(address: work),
        ),
        addresses: const AddressListLoaded([home, work]),
      );

      await tapForward(tester);
      expect(capturedSelection().address, work);
    });

    testWidgets('with nothing saved it opens the form, not an empty state', (
      tester,
    ) async {
      await pump(tester, onAddress, addresses: const AddressListEmpty());

      expect(find.byType(AddressForm), findsOneWidget);
      expect(find.text('عنوان جديد'), findsOneWidget);
      // No list to head, and no button to open a form that is already open.
      expect(find.text('العناوين المحفوظة'), findsNothing);
      expect(find.text('إضافة عنوان جديد'), findsNothing);
    });

    testWidgets('the form is closed until asked for, when there is a list', (
      tester,
    ) async {
      await pump(
        tester,
        onAddress,
        addresses: const AddressListLoaded([home, work]),
      );

      expect(find.byType(AddressForm), findsNothing);

      await tester.tap(find.text('إضافة عنوان جديد'));
      await tester.pumpAndSettle();

      expect(find.byType(AddressForm), findsOneWidget);
    });

    testWidgets('a new address is saved to the address book and chosen', (
      tester,
    ) async {
      // Driven through a controller rather than a fixed state, because the
      // save resolves after the tap.
      final saves = StreamController<AddressFormState>();
      addTearDown(saves.close);
      addressForm = MockAddressFormBloc();
      whenListen(
        addressForm,
        saves.stream,
        initialState: const AddressFormIdle(),
      );
      when(addressForm.close).thenAnswer((_) async {});

      await pump(tester, onAddress, addresses: const AddressListEmpty());

      const values = [
        'بيت أمي',
        'سارة أحمد',
        '+966550001111',
        'حي الشاطئ',
        'جدة',
        '',
        'طريق الكورنيش',
      ];
      for (var i = 0; i < values.length; i++) {
        await tester.enterText(find.byType(TextFormField).at(i), values[i]);
      }
      await tester.pumpAndSettle();
      await tapForward(tester);

      final submitted =
          verify(
                () => addressForm.add(
                  captureAny(that: isA<AddressFormSubmitted>()),
                ),
              ).captured.single
              as AddressFormSubmitted;
      // An empty id is how the repository is told this is new; the step never
      // mints one itself.
      expect(submitted.address.id, isEmpty);
      expect(submitted.address.city, 'جدة');
      // Nothing is chosen yet — the address has no id to be chosen by.
      verifyNever(() => bloc.add(any(that: isA<CheckoutAddressSelected>())));

      const saved = Address(
        id: 'a3',
        kind: AddressKind.other,
        label: 'بيت أمي',
        recipientName: 'سارة أحمد',
        phone: '+966550001111',
        country: 'المملكة العربية السعودية',
        region: 'حي الشاطئ',
        city: 'جدة',
        street: 'طريق الكورنيش',
        isDefault: true,
      );
      saves.add(const AddressFormSucceeded([saved]));
      await tester.pumpAndSettle();

      // It went into the address book, so the account screen will show it too.
      verify(() => addressList.add(const AddressesRequested())).called(1);
      expect(capturedSelection().address, saved);
    });

    testWidgets('a failed read offers a retry rather than a dead step', (
      tester,
    ) async {
      await pump(
        tester,
        onAddress,
        addresses: const AddressListError(NetworkFailure()),
      );

      expect(find.byType(FailureView), findsOneWidget);

      clearInteractions(addressList);
      await tester.tap(
        find.descendant(
          of: find.byType(FailureView),
          matching: find.byType(FilledButton),
        ),
      );
      await tester.pump();

      verify(() => addressList.add(const AddressesRequested())).called(1);
    });

    testWidgets('the forward button says it saves as well as advances', (
      tester,
    ) async {
      await pump(tester, onAddress);
      expect(find.text('حفظ ومتابعة'), findsOneWidget);

      await pump(tester, const CheckoutInProgress());
      expect(find.text('التالي'), findsOneWidget);
    });
  });

  group('the shipping and payment step', () {
    // The frame's own figures: 450 + 35 shipping + 15 cash fee = 500.
    const onPayment = CheckoutInProgress(
      step: CheckoutStep.payment,
      draft: CheckoutDraft(cart: CartTotals(subtotal: 450, shipping: 35)),
    );

    CheckoutPaymentSubmitted capturedSubmission() =>
        verify(
              () => bloc.add(captureAny(that: isA<CheckoutPaymentSubmitted>())),
            ).captured.single
            as CheckoutPaymentSubmitted;

    testWidgets('draws both sections and the summary', (tester) async {
      await pump(tester, onPayment);

      expect(find.byType(PaymentStep), findsOneWidget);
      expect(find.text('طريقة الشحن'), findsOneWidget);
      expect(find.text('التوصيل القياسي'), findsOneWidget);
      expect(find.text('طريقة الدفع'), findsOneWidget);
      expect(find.text('الدفع عند الاستلام'), findsOneWidget);
      expect(find.text('البطاقة الائتمانية'), findsOneWidget);
    });

    testWidgets('opens with the selections the frame already made', (
      tester,
    ) async {
      await pump(tester, onPayment);

      await tester.tap(find.byType(FilledButton).last);
      await tester.pumpAndSettle();

      final submitted = capturedSubmission();
      expect(submitted.shipping, ShippingMethod.standard);
      expect(submitted.payment, PaymentMethod.cashOnDelivery);
    });

    testWidgets('totals subtotal, shipping and the payment fee', (
      tester,
    ) async {
      await pump(tester, onPayment);

      expect(find.text('رسوم الدفع'), findsOneWidget);
      expect(find.textContaining('450'), findsWidgets);
      expect(find.textContaining('500'), findsOneWidget);
    });

    testWidgets('the card option is drawn, labelled and not selectable', (
      tester,
    ) async {
      await pump(tester, onPayment);

      expect(find.text('قريباً'), findsOneWidget);

      await tester.tap(find.text('البطاقة الائتمانية'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(FilledButton).last);
      await tester.pumpAndSettle();

      // Tapping it changed nothing: cash is still what gets submitted.
      expect(capturedSubmission().payment, PaymentMethod.cashOnDelivery);
    });

    testWidgets('exactly one option is ticked in each section', (tester) async {
      await pump(tester, onPayment);

      // One for shipping, one for payment — and none for the card.
      expect(find.byIcon(Icons.check), findsNWidgets(2));
    });

    testWidgets('reopening the step shows what the draft already holds', (
      tester,
    ) async {
      await pump(
        tester,
        const CheckoutInProgress(
          step: CheckoutStep.payment,
          draft: CheckoutDraft(
            cart: CartTotals(subtotal: 450, shipping: 35),
            payment: PaymentMethod.cashOnDelivery,
          ),
        ),
      );

      await tester.tap(find.byType(FilledButton).last);
      await tester.pumpAndSettle();

      expect(capturedSubmission().payment, PaymentMethod.cashOnDelivery);
    });

    testWidgets('the forward button names the step it leads to', (
      tester,
    ) async {
      await pump(tester, onPayment);
      expect(find.text('مراجعة الطلب'), findsOneWidget);
    });

    testWidgets('shows no summary before the cart is known', (tester) async {
      // A total of nothing would be worse than no total at all.
      await pump(tester, const CheckoutInProgress(step: CheckoutStep.payment));

      expect(find.byType(PaymentStep), findsOneWidget);
      expect(find.text('رسوم الدفع'), findsNothing);
    });

    testWidgets('survives both directions', (tester) async {
      for (final locale in const [Locale('ar'), Locale('en')]) {
        await pump(tester, onPayment, locale: locale);
        expect(find.byType(PaymentStep), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
    });
  });

  group('the review step', () {
    const dress = Product(
      id: 'p1',
      name: 'فستان سهرة حريري',
      price: 450,
      categoryId: 'dresses',
      colours: [ProductColour(id: 'navy', name: 'أزرق ليلي', hex: '#1F2A44')],
      sizes: ['S', 'M'],
    );

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

    const reviewing = CheckoutInProgress(
      step: CheckoutStep.review,
      draft: CheckoutDraft(
        contact: ContactDetails(
          fullName: 'سارة أحمد',
          phone: '+966550001111',
          email: 'sara@example.com',
        ),
        address: address,
        cart: CartTotals(subtotal: 450, shipping: 35),
        items: [CartItem(product: dress, colourId: 'navy', size: 'M')],
      ),
    );

    testWidgets('reports back everything the three steps collected', (
      tester,
    ) async {
      await pump(tester, reviewing);

      expect(find.byType(ReviewStep), findsOneWidget);
      expect(find.text('سارة أحمد'), findsOneWidget);
      expect(find.text('sara@example.com'), findsOneWidget);
      expect(find.text('شارع التحلية، مبنى 45، حي العليا'), findsOneWidget);
      expect(find.textContaining('12241'), findsOneWidget);
      expect(find.text('التوصيل القياسي'), findsOneWidget);
      expect(find.text('الدفع عند الاستلام'), findsOneWidget);
    });

    testWidgets('lists the ordered lines, read-only', (tester) async {
      await pump(tester, reviewing);

      expect(find.text('فستان سهرة حريري'), findsOneWidget);
      expect(find.text('اللون: أزرق ليلي | المقاس: M'), findsOneWidget);
      expect(find.text('الكمية: 1'), findsOneWidget);
      // Nothing here may be changed except by going back to the step that set
      // it, so no stepper and no remove button.
      expect(find.byIcon(Icons.close), findsNothing);
    });

    testWidgets('totals what will actually be charged, fee included', (
      tester,
    ) async {
      await pump(tester, reviewing);

      expect(find.text('طريقة الدفع'), findsOneWidget);

      // Scrolled to, not merely searched for: the body is a ListView, which
      // builds only what is near the viewport — so an off-screen row is absent
      // from the element tree rather than present and invisible. That is the
      // opposite of the SingleChildScrollView trap the address form hit, and it
      // makes a bare `find.text` here a false negative rather than a false
      // positive.
      await tester.scrollUntilVisible(find.text('رسوم الدفع'), 200);
      await tester.pumpAndSettle();

      // The frame draws neither a payment card nor this row; without them the
      // review would promise 485 and the shopper would pay 500.
      expect(find.text('رسوم الدفع'), findsOneWidget);
      expect(find.textContaining('500'), findsOneWidget);
    });

    testWidgets('a guest shows no email line rather than a blank one', (
      tester,
    ) async {
      await pump(
        tester,
        const CheckoutInProgress(
          step: CheckoutStep.review,
          draft: CheckoutDraft(
            contact: ContactDetails(fullName: 'ليلى', phone: '+966550001111'),
            address: address,
            cart: CartTotals(subtotal: 450, shipping: 35),
          ),
        ),
      );

      expect(find.text('ليلى'), findsOneWidget);
      expect(find.textContaining('@'), findsNothing);
    });

    testWidgets('each edit link asks for its own step', (tester) async {
      await pump(tester, reviewing);

      final links = find.text('تعديل');
      expect(links, findsNWidgets(4));

      // Contact, address, shipping, payment — the last two both edit step 3.
      const expected = [
        CheckoutStep.contact,
        CheckoutStep.address,
        CheckoutStep.payment,
        CheckoutStep.payment,
      ];

      for (var index = 0; index < expected.length; index++) {
        clearInteractions(bloc);
        await tester.tap(links.at(index));
        await tester.pump();

        final requested =
            verify(
                  () =>
                      bloc.add(captureAny(that: isA<CheckoutStepRequested>())),
                ).captured.single
                as CheckoutStepRequested;
        expect(requested.step, expected[index]);
      }
    });

    testWidgets('the bar confirms rather than advancing', (tester) async {
      await pump(tester, reviewing);

      expect(find.text('تأكيد الطلب'), findsOneWidget);
      await tester.tap(find.byType(FilledButton).last);
      await tester.pump();

      verify(() => bloc.add(const CheckoutConfirmed())).called(1);
    });

    testWidgets('placing locks the button and spins in it', (tester) async {
      await pump(
        tester,
        CheckoutPlacing(step: CheckoutStep.review, draft: reviewing.draft),
        settle: false,
      );

      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNull);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      // The reviewed order stays on screen under it.
      expect(find.byType(ReviewStep), findsOneWidget);
    });

    testWidgets('a failure keeps the order on screen and says why', (
      tester,
    ) async {
      await pump(
        tester,
        CheckoutFailed(
          step: CheckoutStep.review,
          draft: reviewing.draft,
          failure: const NetworkFailure(),
        ),
      );

      expect(find.byType(SnackBar), findsOneWidget);
      // Not a FailureView: a whole collected order is still on screen and still
      // correct.
      expect(find.byType(FailureView), findsNothing);
      expect(find.byType(ReviewStep), findsOneWidget);

      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNotNull, reason: 'retry must be possible');
    });

    testWidgets('survives both directions', (tester) async {
      for (final locale in const [Locale('ar'), Locale('en')]) {
        await pump(tester, reviewing, locale: locale);
        expect(find.byType(ReviewStep), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
    });
  });

  group('moving back', () {
    testWidgets('an edited first step goes back to the review, not out', (
      tester,
    ) async {
      // Reached by a "تعديل" link, so there is somewhere to go back to even
      // though `CheckoutStep.contact.previous` is null. Asking the step rather
      // than the state popped the shopper out of checkout entirely.
      await pump(
        tester,
        const CheckoutInProgress(returnTo: CheckoutStep.review),
      );

      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pump();

      verify(() => bloc.add(const CheckoutBackRequested())).called(1);
    });

    testWidgets('a later step walks back inside the flow', (tester) async {
      await pump(tester, const CheckoutInProgress(step: CheckoutStep.address));

      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pump();

      verify(() => bloc.add(const CheckoutBackRequested())).called(1);
    });

    testWidgets('the first step leaves checkout rather than emitting', (
      tester,
    ) async {
      await pump(tester, const CheckoutInProgress());

      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pump();

      // Nothing to move back to inside the flow, so the host pops instead.
      verifyNever(() => bloc.add(const CheckoutBackRequested()));
    });
  });

  group('the unbuilt steps', () {
    testWidgets('are named rather than blank, and cannot advance', (
      tester,
    ) async {
      // Success is the last one left, and the next batch builds it.
      await pump(tester, const CheckoutInProgress(step: CheckoutStep.success));

      expect(find.byType(PlaceholderTab), findsOneWidget);
      expect(find.byType(ContactStep), findsNothing);

      final next = tester.widget<FilledButton>(
        find.ancestor(
          of: find.text('التالي'),
          matching: find.byType(FilledButton),
        ),
      );
      expect(next.onPressed, isNull);
    });
  });

  group('direction and locale', () {
    testWidgets('renders without overflow in ar and en', (tester) async {
      for (final locale in const [Locale('ar'), Locale('en')]) {
        await pump(
          tester,
          const CheckoutInProgress(draft: CheckoutDraft(contact: seeded)),
          locale: locale,
        );
        expect(find.byType(ContactStep), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('the chrome follows the locale', (tester) async {
      await pump(
        tester,
        const CheckoutInProgress(),
        locale: const Locale('en'),
      );

      expect(find.text('Contact information'), findsWidgets);
      expect(find.text('Full name'), findsOneWidget);
      expect(find.text('Next'), findsOneWidget);
    });

    testWidgets('the address step survives both directions', (tester) async {
      // The longest strings in the file: a five-part address summary inside a
      // card that also carries a tick.
      for (final locale in const [Locale('ar'), Locale('en')]) {
        await pump(
          tester,
          const CheckoutInProgress(step: CheckoutStep.address),
          addresses: const AddressListLoaded([home, work]),
          locale: locale,
        );
        expect(find.byType(AddressStep), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('lays out RTL under Arabic', (tester) async {
      await pump(tester, const CheckoutInProgress());

      expect(
        Directionality.of(tester.element(find.byType(ContactStep))),
        TextDirection.rtl,
      );
    });
  });
}
