import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nova_modest/core/di/injection.dart';
import 'package:nova_modest/core/error/failure.dart';
import 'package:nova_modest/core/error/result.dart';
import 'package:nova_modest/features/address/presentation/screens/address_list_screen.dart';
import 'package:nova_modest/features/catalog/presentation/screens/home_screen.dart';
import 'package:nova_modest/features/settings/domain/repositories/locale_repository.dart';
import 'package:nova_modest/features/settings/presentation/bloc/locale_bloc.dart';
import 'package:nova_modest/features/settings/presentation/screens/language_screen.dart';
import 'package:nova_modest/router/routes.dart';

import '../../helpers/pump_real_app.dart';
import '../../helpers/screen_blocs.dart';

class _MockLocaleRepository extends Mock implements LocaleRepository {}

/// Drives the **real** `App` and switches the language in it.
///
/// The design's explanatory line promises the interface updates immediately,
/// and everything that makes that true lives outside this screen: the locale is
/// app-wide bloc state, `MaterialApp.router` reads it, and the router is built
/// once in `App.initState` so the navigation stack survives a rebuild. None of
/// that is visible to a screen test — only to one that runs the app.
void main() {
  late _MockLocaleRepository repository;

  setUpAll(loadAppFonts);

  setUp(() {
    repository = _MockLocaleRepository();
    when(
      () => repository.savedLanguageCode(),
    ).thenAnswer((_) async => const Ok(null));
    when(() => repository.save(any())).thenAnswer((_) async => const Ok(null));

    registerScreenBlocs();
    if (sl.isRegistered<LocaleRepository>()) sl.unregister<LocaleRepository>();
    sl.registerLazySingleton<LocaleRepository>(() => repository);
    if (sl.isRegistered<LocaleBloc>()) sl.unregister<LocaleBloc>();
    sl.registerLazySingleton<LocaleBloc>(() => LocaleBloc(repository));
  });

  tearDown(() {
    unregisterScreenBlocs();
    sl
      ..unregister<LocaleBloc>()
      ..unregister<LocaleRepository>();
  });

  testWidgets('the whole interface switches without leaving the screen', (
    tester,
  ) async {
    final router = await bootRealApp(tester);

    router.go(Routes.language);
    await tester.pumpAndSettle();

    // Opens in Arabic, and the chooser names each language in its own script.
    expect(find.text('اللغة'), findsWidgets);
    expect(find.text('العربية'), findsOneWidget);
    expect(find.text('English'), findsOneWidget);
    expect(
      Directionality.of(tester.element(find.byType(LanguageScreen))),
      TextDirection.rtl,
    );

    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();

    // Same screen, new language — no restart, no navigation.
    expect(find.byType(LanguageScreen), findsOneWidget);
    expect(find.text('Language'), findsWidgets);
    expect(
      find.text('The interface updates immediately when you choose.'),
      findsOneWidget,
    );
    // And the direction of the whole tree flipped with it.
    expect(
      Directionality.of(tester.element(find.byType(LanguageScreen))),
      TextDirection.ltr,
    );
    // Each language still names itself, so the chooser stays usable to someone
    // who cannot read the language now in force.
    expect(find.text('العربية'), findsOneWidget);
  });

  testWidgets('the navigation stack survives the switch', (tester) async {
    final router = await bootRealApp(tester);

    // Two pushes deep inside the account branch.
    router.go(Routes.addresses);
    await tester.pumpAndSettle();
    unawaited(router.push(Routes.language));
    await tester.pumpAndSettle();

    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();

    // Rebuilding MaterialApp.router with a new locale must not reset routing —
    // it would if the router were rebuilt in `build` rather than `initState`.
    expect(find.byType(LanguageScreen), findsOneWidget);
    Navigator.of(tester.element(find.byType(LanguageScreen))).pop();
    await tester.pumpAndSettle();
    expect(find.byType(AddressListScreen), findsOneWidget);
  });

  testWidgets('the choice is persisted, not just applied', (tester) async {
    final router = await bootRealApp(tester);

    router.go(Routes.language);
    await tester.pumpAndSettle();
    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();

    verify(() => repository.save('en')).called(1);
  });

  testWidgets('a failed save switches anyway and says it was not remembered', (
    tester,
  ) async {
    when(
      () => repository.save(any()),
    ).thenAnswer((_) async => const Err(CacheFailure()));

    final router = await bootRealApp(tester);
    router.go(Routes.language);
    await tester.pumpAndSettle();

    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();

    expect(find.text('Language'), findsWidgets);
    // In the language the shopper just switched TO, not the one they left:
    // both states land in one microtask, so the listener runs before any
    // rebuild and must read its own context rather than the enclosing build's.
    expect(
      find.text('The language changed, but your choice could not be saved.'),
      findsOneWidget,
    );
  });

  testWidgets('a stored choice is what the app opens in', (tester) async {
    when(
      () => repository.savedLanguageCode(),
    ).thenAnswer((_) async => const Ok('en'));

    await bootRealApp(tester);

    // Home is where the guard lands a signed-in user.
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(
      Directionality.of(tester.element(find.byType(HomeScreen))),
      TextDirection.ltr,
    );
  });

  testWidgets('prices follow the language, not a global default', (
    tester,
  ) async {
    // Every NumberFormat in the app passes Localizations.localeOf explicitly
    // rather than setting Intl.defaultLocale, which `11-flutter-l10n-guard` §8
    // would call a global. This is the assertion that keeps that honest.
    final router = await bootRealApp(tester);

    router.go(Routes.language);
    await tester.pumpAndSettle();
    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();

    router.go(Routes.homePath);
    await tester.pumpAndSettle();

    // The Arabic symbol must not survive into an English render.
    expect(find.textContaining('ر.س'), findsNothing);
  });
}
