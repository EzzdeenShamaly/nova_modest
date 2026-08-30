import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nova_modest/core/di/injection.dart';
import 'package:nova_modest/core/theme/app_theme.dart';
import 'package:nova_modest/features/address/domain/entities/address.dart';
import 'package:nova_modest/features/address/presentation/bloc/address_list_bloc.dart';
import 'package:nova_modest/features/auth/domain/entities/user.dart';
import 'package:nova_modest/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:nova_modest/features/cart/domain/entities/cart_item.dart';
import 'package:nova_modest/features/cart/domain/entities/cart_totals.dart';
import 'package:nova_modest/features/cart/presentation/bloc/cart_bloc.dart';
import 'package:nova_modest/features/catalog/domain/entities/product.dart';
import 'package:nova_modest/features/orders/data/repositories/fake_order_repository.dart';
import 'package:nova_modest/features/checkout/presentation/bloc/checkout_bloc.dart';
import 'package:nova_modest/features/checkout/presentation/screens/checkout_screen.dart';
import 'package:nova_modest/features/checkout/presentation/widgets/address_step.dart';
import 'package:nova_modest/features/checkout/presentation/widgets/contact_step.dart';
import 'package:nova_modest/features/checkout/presentation/widgets/payment_step.dart';
import 'package:nova_modest/features/checkout/presentation/widgets/review_step.dart';
import 'package:nova_modest/features/checkout/presentation/widgets/success_step.dart';
import 'package:nova_modest/features/orders/presentation/bloc/orders_bloc.dart';
import 'package:nova_modest/features/orders/presentation/screens/orders_screen.dart';
import 'package:nova_modest/features/onboarding/presentation/bloc/onboarding_bloc.dart';
import 'package:nova_modest/l10n/app_localizations.dart';
import 'package:nova_modest/router/app_router.dart';
import 'package:nova_modest/router/routes.dart';

import '../helpers/pump_app.dart';
import '../helpers/screen_blocs.dart';

class _MockAuthBloc extends MockBloc<AuthEvent, AuthState>
    implements AuthBloc {}

class _MockOnboardingBloc extends MockBloc<OnboardingEvent, OnboardingState>
    implements OnboardingBloc {}

/// Opens checkout through the **real** router.
///
/// Step 2 reads `AddressListBloc` and `AddressFormBloc` from the widget tree,
/// and whether the tree supplies them is a property of how `/checkout` is
/// declared — invisible to `checkout_screen_test.dart`, which wraps the screen
/// in those providers by hand and so encodes the assumption instead of checking
/// it. That is precisely how the addresses screen shipped a form no provider
/// reached: a `GoRoute` nested under another gets a path and a back-stack
/// position, not a place in the widget tree.
///
/// A guest is used deliberately. Checkout is the one flow above the sign-in
/// gate that a guest may walk, and the address blocs it needs are otherwise
/// only provided under `/profile`, which a guest never reaches.
void main() {
  late _MockAuthBloc authBloc;
  late _MockOnboardingBloc onboardingBloc;
  late MockCartBloc cartBloc;
  late FakeOrderRepository orders;

  const dress = Product(
    id: 'p1',
    name: 'فستان سهرة حريري',
    price: 450,
    categoryId: 'dresses',
  );

  const loadedCart = CartLoaded(
    items: [CartItem(product: dress)],
    totals: CartTotals(subtotal: 450, shipping: 35),
  );

  const user = User(
    id: 'u1',
    email: 'sara@example.com',
    displayName: 'سارة',
    phone: '+966 50 123 4567',
  );

  const home = Address(
    id: 'a1',
    kind: AddressKind.home,
    label: 'المنزل',
    recipientName: 'سارة',
    phone: '+966 50 123 4567',
    country: 'المملكة العربية السعودية',
    region: 'حي العليا',
    city: 'الرياض',
    street: 'شارع الملك فهد، مبنى ٤٥',
    isDefault: true,
  );

  setUpAll(loadAppFonts);

  setUp(() {
    authBloc = _MockAuthBloc();
    onboardingBloc = _MockOnboardingBloc();
    cartBloc = stubCartBloc(loadedCart);

    registerScreenBlocs();
    // The real one: this file is about what the route provides, so the bloc
    // that decides the step has to be the bloc that actually decides it. It
    // takes no dependencies.
    if (sl.isRegistered<CheckoutBloc>()) sl.unregister<CheckoutBloc>();
    // One repository shared by the flow that writes orders and the screen that
    // reads them — the app registers it as a lazy singleton for exactly this
    // reason, and two instances would let a placed order vanish.
    orders = FakeOrderRepository();
    sl.registerFactory<CheckoutBloc>(() => CheckoutBloc(orders));
    if (sl.isRegistered<OrdersBloc>()) sl.unregister<OrdersBloc>();
    sl.registerFactory<OrdersBloc>(() => OrdersBloc(orders));

    // A saved address, so the address step has a default to preselect and
    // advances on one tap. `registerScreenBlocs` leaves the list empty, which
    // opens the form instead.
    sl.unregister<AddressListBloc>();
    sl.registerFactory<AddressListBloc>(
      () => stubAddressListBloc(const AddressListLoaded([home])),
    );
  });

  tearDown(() {
    unregisterScreenBlocs();
    if (sl.isRegistered<CheckoutBloc>()) sl.unregister<CheckoutBloc>();
  });

  /// A stocked cart, so the totals the route hands into the flow are visible
  /// rather than null.

  Future<GoRouter> boot(WidgetTester tester, {required AuthState auth}) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    whenListen(authBloc, Stream<AuthState>.value(auth), initialState: auth);
    whenListen(
      onboardingBloc,
      Stream<OnboardingState>.value(const OnboardingNotRequired()),
      initialState: const OnboardingNotRequired(),
    );

    final router = createRouter(authBloc, onboardingBloc);
    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(375, 812),
        builder: (_, _) => MultiBlocProvider(
          providers: [
            BlocProvider<AuthBloc>.value(value: authBloc),
            BlocProvider<OnboardingBloc>.value(value: onboardingBloc),
            BlocProvider<CartBloc>.value(value: cartBloc),
          ],
          child: MaterialApp.router(
            routerConfig: router,
            theme: AppTheme.light,
            locale: const Locale('ar'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return router;
  }

  testWidgets('a guest reaches checkout without being sent to sign in', (
    tester,
  ) async {
    final router = await boot(tester, auth: const AuthUnauthenticated());

    router.go(Routes.checkoutPath);
    await tester.pumpAndSettle();

    expect(find.byType(CheckoutScreen), findsOneWidget);
    expect(find.byType(ContactStep), findsOneWidget);
  });

  /// The regression this file was written to catch, and did.
  ///
  /// The pre-fill reached `CheckoutDraft` and stopped there: `ContactStep`
  /// builds its controllers on its first frame, which renders the bloc's
  /// *initial* state because `CheckoutStarted` is handled one microtask later.
  /// `checkout_screen_test.dart` could not see it — it pumps an already-seeded
  /// state, so the first frame it renders is the seeded one. Only going through
  /// the real router reproduces the order the app actually runs in.
  testWidgets('the account pre-fill reaches the fields, not just the draft', (
    tester,
  ) async {
    final router = await boot(tester, auth: const AuthAuthenticated(user));

    router.go(Routes.checkoutPath);
    await tester.pumpAndSettle();

    final draft = BlocProvider.of<CheckoutBloc>(
      tester.element(find.byType(ContactStep)),
    ).state.draft;
    expect(draft.contact?.fullName, 'سارة');
    expect(draft.contact?.email, 'sara@example.com');

    // And the fields the shopper actually sees.
    expect(find.widgetWithText(TextFormField, 'سارة'), findsOneWidget);
    // The dialling code is its own control, so it is not repeated here.
    expect(find.widgetWithText(TextFormField, '50 123 4567'), findsOneWidget);
  });

  testWidgets('the cart the route hands in reaches the payment step', (
    tester,
  ) async {
    // `CartBloc` is read in the `ShellRoute`'s builder, one layer above the
    // screen — so whether the money ever arrives is a property of the route,
    // and `checkout_screen_test.dart` pumps a draft that already holds it.
    final router = await boot(tester, auth: const AuthAuthenticated(user));

    router.go(Routes.checkoutPath);
    await tester.pumpAndSettle();

    // Contact, then address: the default address is preselected, so each step
    // advances on one tap.
    await tester.tap(find.text('التالي'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('حفظ ومتابعة'));
    await tester.pumpAndSettle();

    expect(find.byType(PaymentStep), findsOneWidget);
    // 450 + 35 shipping + 15 cash fee.
    expect(find.textContaining('500'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the whole flow reaches a placed order', (tester) async {
    // End to end through the real router, the real CheckoutBloc and the real
    // FakeOrderRepository. Every step's own test fakes something this one does
    // not, which is the point: nothing here proves a step works, and only this
    // proves the four of them are actually connected.
    final router = await boot(tester, auth: const AuthAuthenticated(user));

    router.go(Routes.checkoutPath);
    await tester.pumpAndSettle();

    await tester.tap(find.text('التالي'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('حفظ ومتابعة'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('مراجعة الطلب'));
    await tester.pumpAndSettle();

    expect(find.byType(ReviewStep), findsOneWidget);
    // The line the cart handed in, carried through three steps.
    expect(find.text('فستان سهرة حريري'), findsOneWidget);

    await tester.tap(find.text('تأكيد الطلب'));
    await tester.pumpAndSettle();

    // The real FakeOrderRepository minted this, through the real bloc.
    expect(find.byType(SuccessStep), findsOneWidget);
    expect(find.textContaining('ORD-'), findsOneWidget);
    // Chrome gone: nothing to title, and nothing to walk back into.
    expect(find.byType(AppBar), findsNothing);

    // The order holds what the cart held, so the cart must not.
    verify(() => cartBloc.add(const CartCleared())).called(1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('keep shopping leaves checkout for the shop front', (
    tester,
  ) async {
    final router = await boot(tester, auth: const AuthAuthenticated(user));

    router.go(Routes.checkoutPath);
    await tester.pumpAndSettle();
    await tester.tap(find.text('التالي'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('حفظ ومتابعة'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('مراجعة الطلب'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('تأكيد الطلب'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('متابعة التسوق'));
    await tester.pumpAndSettle();

    // Home, not a pop back to the cart the order has just emptied.
    expect(
      router.routerDelegate.currentConfiguration.uri.path,
      Routes.homePath,
    );
    expect(find.byType(SuccessStep), findsNothing);
  });

  testWidgets('a guest is not offered order tracking after paying', (
    tester,
  ) async {
    // `/orders` is behind the sign-in gate, so the button would send someone
    // who has just paid to a login screen.
    final router = await boot(tester, auth: const AuthUnauthenticated());

    router.go(Routes.checkoutPath);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), 'ليلى');
    await tester.enterText(find.byType(TextFormField).at(1), '550001111');
    await tester.pumpAndSettle();
    await tester.tap(find.text('التالي'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('حفظ ومتابعة'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('مراجعة الطلب'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('تأكيد الطلب'));
    await tester.pumpAndSettle();

    expect(find.byType(SuccessStep), findsOneWidget);
    expect(find.text('تتبع الطلب'), findsNothing);
    expect(find.text('متابعة التسوق'), findsOneWidget);
  });

  testWidgets('a placed order shows up in the order history', (tester) async {
    // The seam end to end: checkout writes through the real repository and the
    // orders screen reads the same one back, through the real router.
    final router = await boot(tester, auth: const AuthAuthenticated(user));

    router.go(Routes.checkoutPath);
    await tester.pumpAndSettle();
    await tester.tap(find.text('التالي'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('حفظ ومتابعة'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('مراجعة الطلب'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('تأكيد الطلب'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('تتبع الطلب'));
    await tester.pumpAndSettle();

    expect(find.byType(OrdersScreen), findsOneWidget);
    // Newest first, so the order just placed leads — above the three the
    // repository seeds from the frame.
    expect(find.textContaining('ORD-'), findsWidgets);
    expect(find.text('قيد التحضير'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('an edit link returns to the review, not one step onward', (
    tester,
  ) async {
    final router = await boot(tester, auth: const AuthAuthenticated(user));

    router.go(Routes.checkoutPath);
    await tester.pumpAndSettle();
    await tester.tap(find.text('التالي'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('حفظ ومتابعة'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('مراجعة الطلب'));
    await tester.pumpAndSettle();

    // The first card's link is the contact step.
    await tester.tap(find.text('تعديل').first);
    await tester.pumpAndSettle();
    expect(find.byType(ContactStep), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    // Straight back, rather than through address and payment again.
    expect(find.byType(ReviewStep), findsOneWidget);
  });

  testWidgets('the address step finds the blocs the route is meant to supply', (
    tester,
  ) async {
    final router = await boot(tester, auth: const AuthAuthenticated(user));

    router.go(Routes.checkoutPath);
    await tester.pumpAndSettle();

    // Pre-filled from the account, so one tap validates and advances. The real
    // CheckoutBloc moves the step; nothing here fakes it.
    await tester.tap(find.text('التالي'));
    await tester.pumpAndSettle();

    expect(find.byType(AddressStep), findsOneWidget);
    // The assertion that only a router test can make: no
    // `Could not find the correct Provider<AddressListBloc>`.
    expect(tester.takeException(), isNull);
  });
}
