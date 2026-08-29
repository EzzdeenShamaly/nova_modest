import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:nova_modest/core/error/failure.dart';
import 'package:nova_modest/features/auth/domain/entities/user.dart';
import 'package:nova_modest/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:nova_modest/features/cart/presentation/bloc/cart_bloc.dart';
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

void main() {
  late _MockAuthBloc authBloc;
  late _MockOnboardingBloc onboardingBloc;

  const user = User(id: 'u1', email: 'a@b.com', displayName: 'Sara');

  // These tests render real screens, so they need real font metrics — the
  // stand-in test font makes every glyph a square and inflates text width.
  setUpAll(loadAppFonts);

  setUp(() {
    authBloc = _MockAuthBloc();
    onboardingBloc = _MockOnboardingBloc();

    registerScreenBlocs();
  });

  tearDown(unregisterScreenBlocs);

  void given({required AuthState auth, required OnboardingState onboarding}) {
    whenListen(authBloc, Stream<AuthState>.value(auth), initialState: auth);
    whenListen(
      onboardingBloc,
      Stream<OnboardingState>.value(onboarding),
      initialState: onboarding,
    );
  }

  /// Pumps the real router so the redirect guard is exercised end to end rather
  /// than re-implemented in the test.
  Future<GoRouter> pumpRouter(WidgetTester tester, {String? initial}) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final router = createRouter(authBloc, onboardingBloc);
    if (initial != null) router.go(initial);

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(375, 812),
        builder: (_, _) => MultiBlocProvider(
          providers: [
            BlocProvider<AuthBloc>.value(value: authBloc),
            BlocProvider<OnboardingBloc>.value(value: onboardingBloc),
            // App-wide in `app.dart` too: the shell's badge reads it, so any
            // route that lands inside the shell needs one in the tree.
            BlocProvider<CartBloc>.value(value: stubCartBloc()),
          ],
          child: MaterialApp.router(
            routerConfig: router,
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

  String locationOf(GoRouter router) =>
      router.routerDelegate.currentConfiguration.uri.toString();

  testWidgets('holds on the splash while either concern is undecided', (
    tester,
  ) async {
    given(auth: const AuthInitial(), onboarding: const OnboardingInitial());

    final router = await pumpRouter(tester);

    expect(locationOf(router), Routes.splashPath);
  });

  testWidgets('holds on the splash through the whole startup check', (
    tester,
  ) async {
    // The state the real AuthBloc occupies for the 1.2s after launch. Holding
    // only on AuthInitial dismissed the splash within microseconds on a device.
    given(
      auth: const AuthCheckInProgress(),
      onboarding: const OnboardingNotRequired(),
    );

    final router = await pumpRouter(tester);

    expect(locationOf(router), Routes.splashPath);
  });

  testWidgets('holds on the splash when only onboarding is undecided', (
    tester,
  ) async {
    given(
      auth: const AuthUnauthenticated(),
      onboarding: const OnboardingInitial(),
    );

    final router = await pumpRouter(tester);

    expect(locationOf(router), Routes.splashPath);
  });

  testWidgets('a first launch goes to the onboarding', (tester) async {
    given(
      auth: const AuthUnauthenticated(),
      onboarding: const OnboardingRequired(),
    );

    final router = await pumpRouter(tester);

    expect(locationOf(router), Routes.onboardingPath);
  });

  testWidgets('a first launch goes to the onboarding even when signed in', (
    tester,
  ) async {
    // The onboarding is a per-device concern, so a signed-in user on a fresh
    // install still sees it.
    given(
      auth: const AuthAuthenticated(user),
      onboarding: const OnboardingRequired(),
    );

    final router = await pumpRouter(tester);

    expect(locationOf(router), Routes.onboardingPath);
  });

  testWidgets('a returning guest lands on Home, not the login screen', (
    tester,
  ) async {
    given(
      auth: const AuthUnauthenticated(),
      onboarding: const OnboardingNotRequired(),
    );

    final router = await pumpRouter(tester);

    expect(locationOf(router), Routes.homePath);
  });

  testWidgets('a signed-out user never sees the onboarding again', (
    tester,
  ) async {
    // Signing out must not replay it: the flag is per device, not per session.
    given(
      auth: const AuthUnauthenticated(),
      onboarding: const OnboardingNotRequired(),
    );

    final router = await pumpRouter(tester, initial: Routes.onboardingPath);

    expect(locationOf(router), Routes.homePath);
  });

  testWidgets('a failed flag read lets the user in rather than trapping them', (
    tester,
  ) async {
    given(
      auth: const AuthUnauthenticated(),
      onboarding: const OnboardingFailureState(CacheFailure()),
    );

    final router = await pumpRouter(tester);

    expect(locationOf(router), Routes.homePath);
  });

  testWidgets('a guest reaching a protected area is sent to sign in, with the '
      'attempted path carried along', (tester) async {
    given(
      auth: const AuthUnauthenticated(),
      onboarding: const OnboardingNotRequired(),
    );

    final router = await pumpRouter(tester);
    router.go('/orders');
    await tester.pumpAndSettle();

    expect(
      locationOf(router),
      '${Routes.loginPath}?${Routes.fromQueryParam}=%2Forders',
    );
  });

  testWidgets('a guest may sit on the login screen without being bounced', (
    tester,
  ) async {
    given(
      auth: const AuthUnauthenticated(),
      onboarding: const OnboardingNotRequired(),
    );

    final router = await pumpRouter(tester, initial: Routes.loginPath);

    expect(locationOf(router), Routes.loginPath);
  });

  testWidgets('a signed-in user on the login screen is moved to Home', (
    tester,
  ) async {
    given(
      auth: const AuthAuthenticated(user),
      onboarding: const OnboardingNotRequired(),
    );

    final router = await pumpRouter(tester, initial: Routes.loginPath);

    expect(locationOf(router), Routes.homePath);
  });

  group('Routes.isProtected', () {
    test('matches a protected area and everything under it', () {
      expect(Routes.isProtected('/orders'), isTrue);
      expect(Routes.isProtected('/orders/42'), isTrue);
      expect(Routes.isProtected('/profile'), isTrue);
    });

    test('leaves the public areas alone', () {
      // Checkout is deliberately among them: a guest may buy, and the contact
      // step opens empty for them. It was protected until the flow was built.
      expect(Routes.isProtected(Routes.checkoutPath), isFalse);
      expect(Routes.isProtected(Routes.homePath), isFalse);
      expect(Routes.isProtected(Routes.loginPath), isFalse);
      expect(Routes.isProtected(Routes.splashPath), isFalse);
      expect(Routes.isProtected(Routes.onboardingPath), isFalse);
    });

    test('does not match a path that merely starts with the same letters', () {
      expect(Routes.isProtected('/ordersomething'), isFalse);
    });
  });
}
