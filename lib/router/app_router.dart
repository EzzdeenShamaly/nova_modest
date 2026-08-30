import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:nova_modest/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:nova_modest/features/address/presentation/bloc/address_form_bloc.dart';
import 'package:nova_modest/features/address/presentation/bloc/address_list_bloc.dart';
import 'package:nova_modest/features/address/presentation/screens/address_form_screen.dart';
import 'package:nova_modest/features/address/presentation/screens/address_list_screen.dart';
import 'package:nova_modest/features/auth/presentation/screens/auth_method_screen.dart';
import 'package:nova_modest/features/auth/presentation/screens/email_verification_screen.dart';
import 'package:nova_modest/features/cart/presentation/bloc/cart_bloc.dart';
import 'package:nova_modest/features/cart/presentation/screens/cart_screen.dart';
import 'package:nova_modest/features/checkout/presentation/bloc/checkout_bloc.dart';
import 'package:nova_modest/features/checkout/presentation/screens/checkout_screen.dart';
import 'package:nova_modest/features/catalog/presentation/screens/product_detail_screen.dart';
import 'package:nova_modest/features/catalog/presentation/screens/product_list_screen.dart';
import 'package:nova_modest/features/catalog/presentation/screens/search_screen.dart';
import 'package:nova_modest/features/catalog/presentation/screens/home_screen.dart';
import 'package:nova_modest/core/di/injection.dart';
import 'package:nova_modest/features/profile/presentation/screens/personal_info_screen.dart';
import 'package:nova_modest/features/settings/presentation/screens/help_screen.dart';
import 'package:nova_modest/features/settings/presentation/screens/terms_screen.dart';
import 'package:nova_modest/features/settings/presentation/screens/notifications_screen.dart';
import 'package:nova_modest/features/settings/presentation/screens/language_screen.dart';
import 'package:nova_modest/features/profile/presentation/screens/profile_screen.dart';
import 'package:nova_modest/features/onboarding/presentation/bloc/onboarding_bloc.dart';
import 'package:nova_modest/features/orders/presentation/bloc/order_detail_bloc.dart';
import 'package:nova_modest/features/orders/presentation/bloc/orders_bloc.dart';
import 'package:nova_modest/features/orders/presentation/screens/order_detail_screen.dart';
import 'package:nova_modest/features/orders/presentation/screens/orders_screen.dart';
import 'package:nova_modest/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:nova_modest/features/splash/presentation/screens/splash_screen.dart';
import 'package:nova_modest/router/app_shell.dart';
import 'package:nova_modest/router/routes.dart';

/// The single [GoRouter] for the app.
///
/// One top-level `redirect` decides everything, reading two app-wide blocs:
/// [OnboardingBloc] for "is this the first launch on this device" and [AuthBloc]
/// for "is there a session". The two are independent on purpose — signing out
/// must never replay the onboarding.
///
/// Screens never navigate on state changes themselves; they emit state and this
/// guard moves the user, so exactly one place decides where anyone may be.
GoRouter createRouter(
  AuthBloc authBloc,
  OnboardingBloc onboardingBloc,
) => GoRouter(
  initialLocation: Routes.splashPath,
  debugLogDiagnostics: kDebugMode,
  // Re-evaluates `redirect` when either concern changes.
  refreshListenable: _BlocRefreshListenable([
    authBloc.stream,
    onboardingBloc.stream,
  ]),
  redirect: (context, state) => resolveRedirect(
    auth: authBloc.state,
    onboarding: onboardingBloc.state,
    location: state.matchedLocation,
    uri: state.uri,
  ),
  routes: [
    GoRoute(
      path: Routes.splashPath,
      name: Routes.splashName,
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: Routes.onboardingPath,
      name: Routes.onboardingName,
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: Routes.loginPath,
      name: Routes.loginName,
      builder: (context, state) => const AuthMethodScreen(),
    ),
    GoRoute(
      path: Routes.verifyEmailPath,
      name: Routes.verifyEmailName,
      builder: (context, state) => EmailVerificationScreen(
        email: state.uri.queryParameters[Routes.emailQueryParam] ?? '',
      ),
    ),
    // Above the shell: checkout owns the whole display, and the ShellRoute
    // around it provides CheckoutBloc so the draft lives exactly as long as
    // the flow. One route for all of its steps — the step is bloc state,
    // not a path segment, so nobody can land on the review with an empty
    // draft.
    ShellRoute(
      builder: (context, state, child) => MultiBlocProvider(
        providers: [
          BlocProvider<CheckoutBloc>(
            create: (_) => sl<CheckoutBloc>()
              ..add(
                CheckoutStarted(
                  // Pre-fills the contact step for a signed-in shopper and
                  // leaves it empty for a guest. Read here rather than
                  // inside the bloc, so checkout does not depend on the
                  // session to be testable.
                  user: switch (context.read<AuthBloc>().state) {
                    AuthAuthenticated(:final user) => user,
                    _ => null,
                  },
                  // What the cart holds, on the same terms: a snapshot handed
                  // in, not a dependency the bloc reaches for. The cart cannot
                  // be edited from inside the flow, so it cannot go stale
                  // while the flow is open.
                  cart: switch (context.read<CartBloc>().state) {
                    CartLoaded(:final totals) => totals,
                    _ => null,
                  },
                  // The lines the review lists, from the same read.
                  items: switch (context.read<CartBloc>().state) {
                    CartLoaded(:final items) => items,
                    _ => const [],
                  },
                ),
              ),
          ),
          // The address step reuses the address feature rather than
          // defining a second notion of an address. Its own instances, not
          // the account section's: those live under `/profile`, which a
          // guest never reaches — and checkout is open to guests.
          //
          // Loaded here rather than by the step, so the list is ready by
          // the time the shopper finishes typing their name.
          BlocProvider<AddressListBloc>(
            create: (_) =>
                sl<AddressListBloc>()..add(const AddressesRequested()),
          ),
          // Provided above the step for the same reason `AddressListBloc`
          // is: a bloc created inside the widget that reads it is not its
          // own ancestor.
          BlocProvider<AddressFormBloc>(create: (_) => sl<AddressFormBloc>()),
        ],
        child: child,
      ),
      routes: [
        GoRoute(
          path: Routes.checkoutPath,
          name: Routes.checkoutName,
          builder: (context, state) => const CheckoutScreen(),
        ),
      ],
    ),
    // Above the shell, so it covers the bottom bar as the design shows.
    GoRoute(
      path: Routes.productPath,
      name: Routes.productName,
      builder: (context, state) => ProductDetailScreen(
        productId: state.pathParameters['productId'] ?? '',
      ),
    ),
    // The four tabs. One branch each, so switching keeps every tab's stack
    // and scroll position instead of rebuilding it.
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          AppShell(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: Routes.homePath,
              name: Routes.homeName,
              builder: (context, state) => const HomeScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: Routes.categoriesPath,
              name: Routes.categoriesName,
              // The branch root IS a listing: the design treats this tab
              // and Home's "see all" as one destination, so an
              // intermediate picker would be a screen the design does not
              // have. Rendered directly rather than through a `redirect`,
              // which would also have to be kept from swallowing the
              // `search` and `:categoryId` children beneath it.
              builder: (context, state) =>
                  const ProductListScreen(categoryId: Routes.entryCategoryId),
              routes: [
                // Before the :categoryId route below: go_router matches in
                // declaration order, so a literal segment has to come first
                // or "search" would be read as a category id.
                GoRoute(
                  path: Routes.searchPath,
                  name: Routes.searchName,
                  builder: (context, state) => const SearchScreen(),
                ),
                // Nested, so the bottom bar stays put and back pops to the
                // categories root rather than leaving the branch.
                GoRoute(
                  path: Routes.productListPath,
                  name: Routes.productListName,
                  builder: (context, state) => ProductListScreen(
                    categoryId: state.pathParameters['categoryId'] ?? '',
                  ),
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: Routes.cartPath,
              name: Routes.cartName,
              builder: (context, state) => const CartScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: Routes.profilePath,
              name: Routes.profileName,
              builder: (context, state) => const ProfileScreen(),
              // Nested and pushed, so the bottom bar stays put and back
              // pops to the account root rather than leaving the branch.
              // Every one is a placeholder; building one for real replaces
              // a single builder.
              routes: [
                // The first of the account menu's destinations to become a
                // real screen; it left _accountPlaceholders below.
                GoRoute(
                  path: Routes.personalInfoPath,
                  name: Routes.personalInfoName,
                  builder: (context, state) => const PersonalInfoScreen(),
                ),
                GoRoute(
                  path: Routes.languagePath,
                  name: Routes.languageName,
                  builder: (context, state) => const LanguageScreen(),
                ),
                GoRoute(
                  path: Routes.helpPath,
                  name: Routes.helpName,
                  builder: (context, state) => const HelpScreen(),
                ),
                GoRoute(
                  path: Routes.termsPath,
                  name: Routes.termsName,
                  builder: (context, state) => const TermsScreen(),
                ),
                GoRoute(
                  path: Routes.notificationsPath,
                  name: Routes.notificationsName,
                  builder: (context, state) => const NotificationsScreen(),
                ),
                // A ShellRoute, and it has to be: nesting a GoRoute under
                // another gives it a path and a place in the back stack —
                // **not** a place in the widget tree. A bloc provided
                // inside the list screen's own builder is therefore not an
                // ancestor of the form pushed "under" it, which is exactly
                // how the form came to throw
                // `Could not find the correct Provider<AddressListBloc>`.
                // A ShellRoute is the one thing that does wrap its
                // children, so the list and the form share one bloc and
                // the form's post-save refresh reaches the real list.
                //
                // It consumes no path segment, so `addresses` stays
                // relative to `/profile` and the sign-in gate still covers
                // everything under it by prefix.
                ShellRoute(
                  builder: (context, state, child) =>
                      BlocProvider<AddressListBloc>(
                        create: (_) =>
                            sl<AddressListBloc>()
                              ..add(const AddressesRequested()),
                        child: child,
                      ),
                  routes: [
                    GoRoute(
                      path: Routes.addressesPath,
                      name: Routes.addressesName,
                      builder: (context, state) => const AddressListScreen(),
                      routes: [
                        // Declared before the :addressId route: go_router
                        // matches in order, and "new" would otherwise be
                        // read as an address id.
                        GoRoute(
                          path: Routes.addressNewPath,
                          name: Routes.addressNewName,
                          builder: (context, state) =>
                              const AddressFormScreen(),
                        ),
                        GoRoute(
                          path: Routes.addressEditPath,
                          name: Routes.addressEditName,
                          builder: (context, state) => AddressFormScreen(
                            addressId: state.pathParameters['addressId'],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            // Absolute, because `/orders` is protected under its own prefix
            // rather than under `/profile`. Same branch, so the bar shows
            // the account tab as active.
            GoRoute(
              path: Routes.ordersPath,
              name: Routes.ordersName,
              builder: (context, state) => BlocProvider<OrdersBloc>(
                create: (_) => sl<OrdersBloc>()..add(const OrdersRequested()),
                child: const OrdersScreen(),
              ),
              routes: [
                // A plain nested GoRoute, not a ShellRoute: the details screen
                // fetches its own order by number, so it needs nothing from the
                // list's bloc — which is the whole reason a link can open it.
                GoRoute(
                  path: Routes.orderDetailPath,
                  name: Routes.orderDetailName,
                  builder: (context, state) {
                    final number = state.pathParameters['number'] ?? '';
                    return BlocProvider<OrderDetailBloc>(
                      create: (_) =>
                          sl<OrderDetailBloc>()..add(OrderRequested(number)),
                      child: OrderDetailScreen(number: number),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ],
    ),
  ],
);

/// Bridges one or more bloc [Stream]s to the single [Listenable] `GoRouter`
/// expects.
class _BlocRefreshListenable extends ChangeNotifier {
  _BlocRefreshListenable(Iterable<Stream<Object?>> streams) {
    for (final stream in streams) {
      _subscriptions.add(
        stream.asBroadcastStream().listen((_) => notifyListeners()),
      );
    }
  }

  final List<StreamSubscription<Object?>> _subscriptions =
      <StreamSubscription<Object?>>[];

  @override
  void dispose() {
    for (final subscription in _subscriptions) {
      unawaited(subscription.cancel());
    }
    super.dispose();
  }
}

/// The whole routing decision, as a pure function of the two startup concerns.
///
/// Extracted from the `GoRouter` closure deliberately. The splash screen was
/// once skipped on a real device because this logic treated the startup check as
/// "decided" — and thirteen widget-level router tests missed it, because pinning
/// a bloc to a fixed state cannot express a transition. As a plain function the
/// entire state matrix can be enumerated directly, which is where a mistake in
/// it actually shows up.
@visibleForTesting
String? resolveRedirect({
  required AuthState auth,
  required OnboardingState onboarding,
  required String location,
  required Uri uri,
}) {
  // 1. Undecided. Hold on the splash rather than guessing, which would
  //    flash the wrong screen at someone who turns out to be signed in or
  //    to have seen the onboarding already.
  //
  //    AuthCheckInProgress belongs here and AuthLoading deliberately does not:
  //    the startup check leaves AuthInitial within microseconds, so holding
  //    only on AuthInitial dismissed the splash instantly — while holding on
  //    every wait would throw the user back to the splash the moment they
  //    submitted the login form.
  if (auth is AuthInitial ||
      auth is AuthCheckInProgress ||
      onboarding is OnboardingInitial) {
    return location == Routes.splashPath ? null : Routes.splashPath;
  }

  // 2. First launch on this device: the onboarding owns the app until it
  //    is finished. A read failure (OnboardingFailureState) deliberately
  //    does NOT land here — missing the intro once beats trapping someone
  //    behind a disk error.
  if (onboarding is OnboardingRequired) {
    return location == Routes.onboardingPath ? null : Routes.onboardingPath;
  }

  final isSignedIn = auth is AuthAuthenticated;

  // 3. Onboarding resolved, so the splash and the onboarding route are
  //    both dead ends. Home is public, so this holds for guests too.
  if (location == Routes.splashPath || location == Routes.onboardingPath) {
    return Routes.homePath;
  }

  // 4. Guests may browse. Only the protected areas need a session, and the
  //    attempted path rides along so sign-in can return to it.
  if (!isSignedIn && Routes.isProtected(location)) {
    return Uri(
      path: Routes.loginPath,
      queryParameters: {Routes.fromQueryParam: location},
    ).toString();
  }

  // 5. Signed in but still inside the sign-in flow — continue to wherever the
  //    gate interrupted them, or Home if they came on their own. This covers the
  //    verification step too: without it a user who just entered a valid code
  //    would sit on the OTP screen after succeeding.
  if (isSignedIn && Routes.authPaths.contains(location)) {
    final from = uri.queryParameters[Routes.fromQueryParam];
    return (from == null || from.isEmpty) ? Routes.homePath : from;
  }

  return null;
}
