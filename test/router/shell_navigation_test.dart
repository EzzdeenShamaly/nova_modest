import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nova_modest/core/theme/app_theme.dart';
import 'package:nova_modest/core/widgets/app_bottom_nav.dart';
import 'package:nova_modest/core/widgets/placeholder_tab.dart';
import 'package:nova_modest/features/profile/presentation/widgets/profile_menu_tile.dart';
import 'package:nova_modest/features/address/presentation/screens/address_list_screen.dart';
import 'package:nova_modest/features/auth/domain/entities/user.dart';
import 'package:nova_modest/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:nova_modest/features/cart/presentation/bloc/cart_bloc.dart';
import 'package:nova_modest/features/cart/presentation/screens/cart_screen.dart';
import 'package:nova_modest/features/catalog/presentation/screens/home_screen.dart';
import 'package:nova_modest/features/catalog/presentation/screens/product_list_screen.dart';
import 'package:nova_modest/features/catalog/presentation/screens/search_screen.dart';
import 'package:nova_modest/features/onboarding/presentation/bloc/onboarding_bloc.dart';
import 'package:nova_modest/features/profile/presentation/screens/profile_screen.dart';
import 'package:nova_modest/features/settings/presentation/screens/notifications_screen.dart';
import 'package:nova_modest/l10n/app_localizations.dart';
import 'package:nova_modest/router/app_router.dart';
import 'package:nova_modest/router/app_shell.dart';
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

  setUpAll(loadAppFonts);

  setUp(() {
    authBloc = _MockAuthBloc();
    onboardingBloc = _MockOnboardingBloc();

    registerScreenBlocs();
  });

  tearDown(unregisterScreenBlocs);

  Future<GoRouter> boot(WidgetTester tester, {required bool signedIn}) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final auth = signedIn
        ? const AuthAuthenticated(user)
        : const AuthUnauthenticated();
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
            // App-wide in `app.dart` too: the shell's badge reads it and the
            // cart tab renders from it.
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

  String locationOf(GoRouter router) =>
      router.routerDelegate.currentConfiguration.uri.toString();

  Future<void> tapTab(WidgetTester tester, String label) async {
    await tester.tap(find.text(label));
    await tester.pumpAndSettle();
  }

  testWidgets('the bar wraps every tab and starts on Home', (tester) async {
    final router = await boot(tester, signedIn: true);

    expect(find.byType(AppBottomNav), findsOneWidget);
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(locationOf(router), Routes.homePath);
    for (final label in ['الرئيسية', 'الفئات', 'السلة', 'حسابي']) {
      expect(find.text(label), findsWidgets, reason: 'missing tab $label');
    }
  });

  testWidgets('switching tabs moves the route and the screen', (tester) async {
    final router = await boot(tester, signedIn: true);

    await tapTab(tester, 'الفئات');
    expect(locationOf(router), Routes.categoriesPath);
    // The branch root is the listing itself — there is no picker screen.
    expect(find.byType(ProductListScreen), findsOneWidget);

    await tapTab(tester, 'السلة');
    expect(locationOf(router), Routes.cartPath);
    expect(find.byType(CartScreen), findsOneWidget);

    await tapTab(tester, 'حسابي');
    expect(locationOf(router), Routes.profilePath);
    expect(find.byType(ProfileScreen), findsOneWidget);
  });

  testWidgets('the bar stays visible on every tab', (tester) async {
    await boot(tester, signedIn: true);

    for (final label in ['الفئات', 'السلة', 'حسابي', 'الرئيسية']) {
      await tapTab(tester, label);
      expect(find.byType(AppBottomNav), findsOneWidget);
    }
  });

  testWidgets('the categories tab opens a listing, not an empty page', (
    tester,
  ) async {
    // There is no separate "pick a category" design: the frame treats the tab
    // and Home's "see all" as one destination, the product listing.
    final router = await boot(tester, signedIn: true);

    await tapTab(tester, 'الفئات');

    expect(locationOf(router), Routes.categoriesPath);
    expect(find.byType(ProductListScreen), findsOneWidget);
    expect(find.byType(PlaceholderTab), findsNothing);

    // Still the categories branch, so the bar keeps that tab active.
    final shell = tester.widget<AppShell>(find.byType(AppShell));
    expect(
      shell.navigationShell.currentIndex,
      Routes.shellBranches.indexOf(Routes.categoriesPath),
    );
  });

  testWidgets('search is a literal segment, not a category id', (tester) async {
    // Both are children of /categories and go_router matches in declaration
    // order, so this only holds while the literal route is declared first.
    // Getting it wrong routes here to the listing for a category called
    // "search", which fails at run time and not at compile time.
    final router = await boot(tester, signedIn: true);

    router.go(Routes.search);
    await tester.pumpAndSettle();

    expect(find.byType(SearchScreen), findsOneWidget);
    expect(find.byType(ProductListScreen), findsNothing);
  });

  testWidgets('search keeps the bottom bar, with Categories active', (
    tester,
  ) async {
    final router = await boot(tester, signedIn: true);

    router.go(Routes.search);
    await tester.pumpAndSettle();

    // The results frame draws the bar with Categories active, which is why
    // search is nested in that branch rather than living above the shell.
    expect(find.byType(AppBottomNav), findsOneWidget);
    final shell = tester.widget<AppShell>(find.byType(AppShell));
    expect(
      shell.navigationShell.currentIndex,
      Routes.shellBranches.indexOf(Routes.categoriesPath),
    );
  });

  testWidgets('an indexed stack keeps each tab alive across switches', (
    tester,
  ) async {
    // The point of a shell route: Home stays mounted while Categories shows, so
    // returning to it does not rebuild from scratch.
    await boot(tester, signedIn: true);

    await tapTab(tester, 'الفئات');

    expect(find.byType(ProductListScreen), findsOneWidget);
    expect(
      find.byType(HomeScreen, skipOffstage: false),
      findsOneWidget,
      reason: 'Home was disposed instead of being kept offstage',
    );
  });

  testWidgets('a guest tapping the account tab is sent to sign in', (
    tester,
  ) async {
    // /profile is in Routes.protectedPrefixes, so the gate applies to a tab as
    // much as to a deep link.
    final router = await boot(tester, signedIn: false);

    await tapTab(tester, 'حسابي');

    expect(locationOf(router), contains(Routes.loginPath));
    expect(locationOf(router), contains(Routes.fromQueryParam));
    expect(find.byType(ProfileScreen), findsNothing);
  });

  testWidgets('a guest may still browse the public tabs', (tester) async {
    final router = await boot(tester, signedIn: false);

    await tapTab(tester, 'الفئات');
    expect(locationOf(router), Routes.categoriesPath);

    await tapTab(tester, 'السلة');
    expect(locationOf(router), Routes.cartPath);
  });

  testWidgets('an account menu row pushes without leaving the branch', (
    tester,
  ) async {
    await boot(tester, signedIn: true);

    await tapTab(tester, 'حسابي');
    await tester.tap(find.text('الإشعارات'));
    await tester.pumpAndSettle();

    // Asserted on what rendered, not on the router's location: an imperative
    // push inside a shell branch leaves `currentConfiguration.uri` reporting
    // the branch root, so a location check here would fail against a
    // navigation that plainly worked.
    expect(find.byType(NotificationsScreen), findsOneWidget);
    expect(find.byType(ProfileMenuTile), findsNothing);

    // Pushed inside the branch, so the bar stays and the account tab is still
    // the active one.
    expect(find.byType(AppBottomNav), findsOneWidget);
    final shell = tester.widget<AppShell>(find.byType(AppShell));
    expect(
      shell.navigationShell.currentIndex,
      Routes.shellBranches.indexOf(Routes.profilePath),
    );
  });

  testWidgets('the addresses row opens the real screen, not a placeholder', (
    tester,
  ) async {
    await boot(tester, signedIn: true);

    await tapTab(tester, 'حسابي');
    await tester.tap(find.text('العناوين'));
    await tester.pumpAndSettle();

    expect(find.byType(AddressListScreen), findsOneWidget);
    expect(find.byType(PlaceholderTab), findsNothing);
    final shell = tester.widget<AppShell>(find.byType(AppShell));
    expect(
      shell.navigationShell.currentIndex,
      Routes.shellBranches.indexOf(Routes.profilePath),
    );
  });

  testWidgets('orders is protected under its own prefix, in the same branch', (
    tester,
  ) async {
    // `/orders` is not under `/profile`, so it is an absolute sibling route —
    // but it belongs to the account branch, or the bar would jump tabs.
    await boot(tester, signedIn: true);

    await tapTab(tester, 'حسابي');
    await tester.tap(find.text('طلباتي'));
    await tester.pumpAndSettle();

    expect(find.byType(PlaceholderTab), findsOneWidget);
    final shell = tester.widget<AppShell>(find.byType(AppShell));
    expect(
      shell.navigationShell.currentIndex,
      Routes.shellBranches.indexOf(Routes.profilePath),
    );
  });

  testWidgets('a guest cannot deep-link into the account menu', (tester) async {
    final router = await boot(tester, signedIn: false);

    router.go(Routes.addresses);
    await tester.pumpAndSettle();

    // Covered by the `/profile` prefix without listing each child.
    expect(locationOf(router), contains(Routes.loginPath));
  });

  testWidgets('the account tab carries the sign-out action', (tester) async {
    await boot(tester, signedIn: true);

    await tapTab(tester, 'حسابي');

    // Sign-out now asks first, so the row alone must not end the session.
    expect(find.text('تسجيل الخروج'), findsOneWidget);
    await tester.tap(find.text('تسجيل الخروج'));
    await tester.pumpAndSettle();
    verifyNever(() => authBloc.add(const AuthLogoutRequested()));

    // The dialog repeats the label on its confirming action.
    await tester.tap(find.text('تسجيل الخروج').last);
    await tester.pumpAndSettle();
    verify(() => authBloc.add(const AuthLogoutRequested())).called(1);
  });
}
