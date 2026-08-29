import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:nova_modest/core/di/injection.dart';
import 'package:nova_modest/core/theme/app_theme.dart';
import 'package:nova_modest/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:nova_modest/features/cart/presentation/bloc/cart_bloc.dart';
import 'package:nova_modest/features/onboarding/presentation/bloc/onboarding_bloc.dart';
import 'package:nova_modest/features/settings/presentation/bloc/locale_bloc.dart';
import 'package:nova_modest/l10n/app_localizations.dart';
import 'package:nova_modest/router/app_router.dart';

/// The app shell.
///
/// [AuthBloc], [OnboardingBloc], [CartBloc] and [LocaleBloc] are the app-wide
/// blocs, so they are provided here rather than per-route: the router's
/// redirect guard reads the first two, the cart is written by the product page
/// and read by the navigation badge, and the locale is written by the language
/// screen and read by `MaterialApp` itself — so all four must outlive any
/// single screen (`01-flutter-architecture-guard.md`).
///
/// The first two are dispatched together at startup and resolve independently —
/// the router holds on the splash until both have. The cart loads alongside
/// them and holds nothing up: an empty or unread cart is not a reason to keep
/// anyone on the splash.
///
/// The router is built once in [initState], not in `build` — rebuilding it would
/// reset the navigation stack on every theme or locale change.
class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  late final AuthBloc _authBloc;
  late final OnboardingBloc _onboardingBloc;
  late final CartBloc _cartBloc;
  late final LocaleBloc _localeBloc;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _authBloc = sl<AuthBloc>()..add(const AuthCheckRequested());
    _onboardingBloc = sl<OnboardingBloc>()
      ..add(const OnboardingStatusRequested());
    _cartBloc = sl<CartBloc>()..add(const CartRequested());
    _localeBloc = sl<LocaleBloc>()..add(const LocaleRequested());
    _router = createRouter(_authBloc, _onboardingBloc);
  }

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>.value(value: _authBloc),
        BlocProvider<OnboardingBloc>.value(value: _onboardingBloc),
        BlocProvider<CartBloc>.value(value: _cartBloc),
        BlocProvider<LocaleBloc>.value(value: _localeBloc),
      ],
      // Only the locale is watched: rebuilding MaterialApp.router with a new
      // one re-renders the whole tree in that language, and because `_router`
      // was built once in initState the navigation stack is untouched. That is
      // what makes the switch immediate and restart-free.
      child: BlocBuilder<LocaleBloc, LocaleState>(
        builder: (context, localeState) => MaterialApp.router(
          routerConfig: _router,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          // Pinned to light: AppColors is a closed warm light palette, so there is
          // no dark scheme to switch to. Following the device into dark mode
          // without a dark palette would leave Material guessing at colours the
          // palette deliberately does not define.
          themeMode: ThemeMode.light,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          // Bloc state, not a pin and never a global
          // (`11-flutter-l10n-guard.md` §8). It still defaults to Arabic when
          // nothing has been chosen — following the device is what made an
          // English handset render the whole product in English, which is why
          // this was pinned from the onboarding until the language screen
          // existed.
          locale: localeState.locale,

          onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
        ),
      ),
    );
  }
}
