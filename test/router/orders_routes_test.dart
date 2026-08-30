import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:nova_modest/core/di/injection.dart';
import 'package:nova_modest/core/theme/app_theme.dart';
import 'package:nova_modest/features/auth/domain/entities/user.dart';
import 'package:nova_modest/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:nova_modest/features/auth/presentation/screens/auth_method_screen.dart';
import 'package:nova_modest/features/cart/presentation/bloc/cart_bloc.dart';
import 'package:nova_modest/features/onboarding/presentation/bloc/onboarding_bloc.dart';
import 'package:nova_modest/features/orders/data/repositories/fake_order_repository.dart';
import 'package:nova_modest/features/orders/presentation/bloc/order_detail_bloc.dart';
import 'package:nova_modest/features/orders/presentation/bloc/orders_bloc.dart';
import 'package:nova_modest/features/orders/presentation/screens/order_detail_screen.dart';
import 'package:nova_modest/features/orders/presentation/screens/orders_screen.dart';
import 'package:nova_modest/l10n/app_localizations.dart';
import 'package:nova_modest/router/app_router.dart';
import 'package:nova_modest/router/routes.dart';

import '../helpers/pump_app.dart';
import '../helpers/screen_blocs.dart';

class _MockAuthBloc extends MockBloc<AuthEvent, AuthState>
    implements AuthBloc {}

class _MockOnboardingBloc extends MockBloc<OnboardingEvent, OnboardingState>
    implements OnboardingBloc {}

/// Opens the order routes through the **real** router, with the real blocs and
/// the real `FakeOrderRepository`.
///
/// Tapping a card is a screen property and is asserted there; **where the tap
/// goes**, whether `/orders/:number` resolves, and whether the gate covers it
/// are properties of the route declaration, which no screen test can see.
void main() {
  late _MockAuthBloc authBloc;
  late _MockOnboardingBloc onboardingBloc;
  late FakeOrderRepository orders;

  const user = User(id: 'u1', email: 'sara@example.com', displayName: 'سارة');

  /// The newest order the repository seeds, from `1:1356`.
  const seeded = 'ORD-260818-0001';

  setUpAll(loadAppFonts);

  setUp(() {
    authBloc = _MockAuthBloc();
    onboardingBloc = _MockOnboardingBloc();

    registerScreenBlocs();

    // The real ones, sharing a single repository — the app registers it as a
    // lazy singleton for the same reason.
    orders = FakeOrderRepository();
    if (sl.isRegistered<OrdersBloc>()) sl.unregister<OrdersBloc>();
    sl.registerFactory<OrdersBloc>(() => OrdersBloc(orders));
    if (sl.isRegistered<OrderDetailBloc>()) sl.unregister<OrderDetailBloc>();
    sl.registerFactory<OrderDetailBloc>(() => OrderDetailBloc(orders));
  });

  tearDown(() {
    unregisterScreenBlocs();
    if (sl.isRegistered<OrdersBloc>()) sl.unregister<OrdersBloc>();
    if (sl.isRegistered<OrderDetailBloc>()) sl.unregister<OrderDetailBloc>();
  });

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
            BlocProvider<CartBloc>.value(value: stubCartBloc()),
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

  testWidgets('the history renders at its own route', (tester) async {
    final router = await boot(tester, auth: const AuthAuthenticated(user));

    router.go(Routes.ordersPath);
    await tester.pumpAndSettle();

    expect(find.byType(OrdersScreen), findsOneWidget);
    expect(find.textContaining(seeded), findsOneWidget);
  });

  testWidgets('tapping a card opens that order, not another', (tester) async {
    // Asserted by what renders rather than by the URL: `push` inside a
    // StatefulShellRoute leaves `currentConfiguration` on the branch's own
    // path, so the location would be testing go_router rather than this app.
    final router = await boot(tester, auth: const AuthAuthenticated(user));

    router.go(Routes.ordersPath);
    await tester.pumpAndSettle();

    await tester.tap(find.textContaining(seeded));
    await tester.pumpAndSettle();

    expect(find.byType(OrderDetailScreen), findsOneWidget);
    expect(find.text('الطلب #$seeded'), findsOneWidget);
    // The one tapped, not whichever the screen happened to fetch: the other two
    // seeded orders are gone from the tree.
    expect(find.textContaining('ORD-150724-0042'), findsNothing);
    expect(find.textContaining('ORD-020624-0018'), findsNothing);
  });

  testWidgets('the details route resolves without the list above it', (
    tester,
  ) async {
    // The reason it fetches by number rather than reading `OrdersBloc`: a link
    // or a notification arrives with no list loaded.
    final router = await boot(tester, auth: const AuthAuthenticated(user));

    router.go(Routes.orderDetail(seeded));
    await tester.pumpAndSettle();

    expect(find.byType(OrderDetailScreen), findsOneWidget);
    expect(find.byType(OrdersScreen), findsNothing);
    expect(find.text('الطلب #$seeded'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('an unknown number lands on a failure, not a blank screen', (
    tester,
  ) async {
    final router = await boot(tester, auth: const AuthAuthenticated(user));

    router.go(Routes.orderDetail('ORD-000000-9999'));
    await tester.pumpAndSettle();

    expect(find.byType(OrderDetailScreen), findsOneWidget);
    expect(find.byType(FilledButton), findsOneWidget, reason: 'a retry');
  });

  testWidgets('a guest cannot deep-link into one order', (tester) async {
    // Covered by prefix: `/orders/:number` is a child of a protected path, so
    // it needs no rule of its own.
    final router = await boot(tester, auth: const AuthUnauthenticated());

    router.go(Routes.orderDetail(seeded));
    await tester.pumpAndSettle();

    expect(find.byType(OrderDetailScreen), findsNothing);
    expect(find.byType(AuthMethodScreen), findsOneWidget);
  });

  testWidgets('back returns to the history, keeping the account tab', (
    tester,
  ) async {
    final router = await boot(tester, auth: const AuthAuthenticated(user));

    router.go(Routes.ordersPath);
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining(seeded));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    expect(find.byType(OrdersScreen), findsOneWidget);
  });
}
