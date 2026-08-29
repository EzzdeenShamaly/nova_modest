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
import 'package:nova_modest/features/address/presentation/screens/address_form_screen.dart';
import 'package:nova_modest/features/address/presentation/screens/address_list_screen.dart';
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

class _MockAddressListBloc extends MockBloc<AddressListEvent, AddressListState>
    implements AddressListBloc {}

/// Opens the address routes through the **real** router.
///
/// The form screen reads `AddressListBloc` from the widget tree, and whether
/// the tree actually supplies it is a property of how the routes are declared —
/// something no screen test can see, because a screen test builds whatever tree
/// it was told to. `address_form_screen_test.dart` wraps the screen in the
/// provider by hand and so encodes the assumption rather than checking it;
/// this file checks it.
void main() {
  late _MockAuthBloc authBloc;
  late _MockOnboardingBloc onboardingBloc;

  const user = User(id: 'u1', email: 'a@b.com', displayName: 'Sara');

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

    registerScreenBlocs();

    // A stocked list, so the edit route has a row to open on.
    if (sl.isRegistered<AddressListBloc>()) sl.unregister<AddressListBloc>();
    sl.registerFactory<AddressListBloc>(() {
      final bloc = _MockAddressListBloc();
      whenListen(
        bloc,
        Stream<AddressListState>.value(const AddressListLoaded([home])),
        initialState: const AddressListLoaded([home]),
      );
      when(bloc.close).thenAnswer((_) async {});
      return bloc;
    });
  });

  tearDown(unregisterScreenBlocs);

  Future<GoRouter> boot(WidgetTester tester) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const auth = AuthAuthenticated(user);
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

  testWidgets('the addresses list renders at its own route', (tester) async {
    final router = await boot(tester);

    router.go(Routes.addresses);
    await tester.pumpAndSettle();

    expect(find.byType(AddressListScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the add route renders the form', (tester) async {
    final router = await boot(tester);

    router.go(Routes.addressNew);
    await tester.pumpAndSettle();

    // Nesting a GoRoute under another affects the path and the back stack, not
    // the widget tree — so a bloc provided inside the parent's builder is NOT
    // an ancestor here. Only a ShellRoute wraps its children.
    expect(find.byType(AddressFormScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the edit route renders the form for the named address', (
    tester,
  ) async {
    final router = await boot(tester);

    router.go(Routes.addressEdit('a1'));
    await tester.pumpAndSettle();

    expect(find.byType(AddressFormScreen), findsOneWidget);
    // Opened on the row the list holds, not an empty form.
    expect(find.widgetWithText(TextFormField, 'المنزل'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('"new" is a literal segment, not an address id', (tester) async {
    // Both are children of /profile/addresses and go_router matches in
    // declaration order, so this only holds while the literal route is
    // declared first. Getting it wrong opens the edit form for an address
    // called "new", which fails at run time and not at compile time.
    final router = await boot(tester);

    router.go(Routes.addressNew);
    await tester.pumpAndSettle();

    expect(find.byType(AddressFormScreen), findsOneWidget);
    // Empty, so it was read as "add" rather than as editing id "new".
    expect(find.widgetWithText(TextFormField, 'المنزل'), findsNothing);
  });

  testWidgets('a guest cannot deep-link into either form route', (
    tester,
  ) async {
    const guest = AuthUnauthenticated();
    whenListen(authBloc, Stream<AuthState>.value(guest), initialState: guest);
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

    router.go(Routes.addressNew);
    await tester.pumpAndSettle();

    // Covered by the /profile prefix without listing each child.
    expect(
      router.routerDelegate.currentConfiguration.uri.toString(),
      contains(Routes.loginPath),
    );
    expect(find.byType(AddressFormScreen), findsNothing);
  });
}
