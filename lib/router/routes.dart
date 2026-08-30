/// Route paths and names as constants — no magic strings at call sites, so a
/// renamed route is a compile error rather than a runtime navigation failure
/// (`10-evidence-and-dependency-guard.md`).
abstract final class Routes {
  static const String splashPath = '/';
  static const String splashName = 'splash';

  static const String onboardingPath = '/onboarding';
  static const String onboardingName = 'onboarding';

  static const String loginPath = '/login';
  static const String loginName = 'login';

  static const String verifyEmailPath = '/verify-email';
  static const String verifyEmailName = 'verify-email';

  /// Carries the address between the two sign-in steps. A query parameter
  /// rather than `extra` so the step survives a process restart.
  static const String emailQueryParam = 'email';

  /// The sign-in flow. A signed-in user has no business on any of them, so the
  /// guard moves them on.
  static const List<String> authPaths = <String>[loginPath, verifyEmailPath];

  // --- The bottom-navigation branches -------------------------------------
  //
  // One `StatefulShellBranch` each, so every tab keeps its own navigation stack
  // and scroll position instead of rebuilding from scratch on each visit.

  static const String homePath = '/home';
  static const String homeName = 'home';

  static const String categoriesPath = '/categories';
  static const String categoriesName = 'categories';

  /// The category the storefront opens on.
  ///
  /// The design has no separate "pick a category" screen — the tab and Home's
  /// "see all" are the same destination, the product listing — so the branch
  /// root shows this one. A catalogue id in the routing layer is an assumption
  /// about the data: it is the first category the catalogue returns today, and
  /// it is what a backend-named "default category" replaces when one exists.
  static const String entryCategoryId = 'abayas';

  /// One category's products. A **child** of the categories branch, not a tab of
  /// its own: the design shows the bottom bar with Categories active, and a
  /// child route keeps the bar in place and lets back pop within the branch.
  static const String productListPath = ':categoryId';
  static const String productListName = 'product-list';

  /// Search, from the icon in Home's app bar.
  ///
  /// A **child of the categories branch**, like the listing: the results frame
  /// draws the bottom bar with Categories active, and nesting keeps the bar in
  /// place while back pops to the categories root.
  ///
  /// Declared **before** [productListPath] in the router. Both are children of
  /// `/categories`, and a literal segment only wins over `:categoryId` because
  /// go_router matches in declaration order — reordering them would route
  /// `/categories/search` to the listing for a category called "search".
  static const String searchPath = 'search';
  static const String searchName = 'search';

  /// Absolute location for [searchPath], for `go` calls.
  static const String search = '$categoriesPath/$searchPath';

  /// Absolute location for [productListPath], for `go` calls.
  static String productList(String categoryId) => '$categoriesPath/$categoryId';

  static const String cartPath = '/cart';
  static const String cartName = 'cart';

  static const String profilePath = '/profile';
  static const String profileName = 'profile';

  /// Branch roots in tab order. The index into this list is the shell's branch
  /// index, so the bar and the router cannot disagree about which tab is which.
  static const List<String> shellBranches = <String>[
    homePath,
    categoriesPath,
    cartPath,
    profilePath,
  ];

  /// One product, in full.
  ///
  /// **Top level, outside the shell.** The design replaces the bottom
  /// navigation with a sticky action bar, so the buying screen owns the display
  /// and back returns wherever the shopper came from.
  static const String productPath = '/product/:productId';
  static const String productName = 'product';

  static String product(String productId) => '/product/$productId';

  /// Query parameter carrying where the user was headed when the sign-in gate
  /// interrupted them, so they land there instead of on Home afterwards.
  static const String fromQueryParam = 'from';

  // --- The account tab's destinations ------------------------------------
  //
  // All but `/orders` are real screens now; that one is still a
  // `PlaceholderTab`. Every one is gated already: `/orders` and `/profile` are
  // both in [protectedPrefixes].

  /// The checkout flow — **one** route for all of its steps. The step is bloc
  /// state rather than a path segment, so a shopper cannot land on the review
  /// with nothing collected.
  static const String checkoutPath = '/checkout';
  static const String checkoutName = 'checkout';

  static const String ordersPath = '/orders';
  static const String ordersName = 'orders';

  /// One order, by the number the shopper was quoted. A child of `/orders`, so
  /// the sign-in gate covers it by prefix without a second rule.
  static const String orderDetailPath = ':number';
  static const String orderDetailName = 'orderDetail';

  /// Children of [profilePath], so the sign-in gate covers them by prefix.
  static const String personalInfoPath = 'personal';
  static const String personalInfoName = 'personal-info';

  static const String addressesPath = 'addresses';
  static const String addressesName = 'addresses';

  /// Adding and editing, both children of the addresses list so the sign-in
  /// gate covers them by the `/profile` prefix and back pops to the list.
  static const String addressNewPath = 'new';
  static const String addressNewName = 'address-new';

  static const String addressEditPath = ':addressId';
  static const String addressEditName = 'address-edit';

  static const String languagePath = 'language';
  static const String languageName = 'language';

  static const String notificationsPath = 'notifications';
  static const String notificationsName = 'notifications';

  static const String helpPath = 'help';
  static const String helpName = 'help';

  static const String termsPath = 'terms';
  static const String termsName = 'terms';

  /// Absolute locations for the account menu, for `go` calls.
  static const String personalInfo = '$profilePath/$personalInfoPath';
  static const String addresses = '$profilePath/$addressesPath';
  static const String addressNew = '$addresses/$addressNewPath';

  static String addressEdit(String addressId) => '$addresses/$addressId';

  static String orderDetail(String number) => '$ordersPath/$number';
  static const String language = '$profilePath/$languagePath';
  static const String notifications = '$profilePath/$notificationsPath';
  static const String help = '$profilePath/$helpPath';
  static const String terms = '$profilePath/$termsPath';

  /// Areas that require a session.
  ///
  /// Home and browsing are public — a guest may use the app. Only these need a
  /// signed-in user, and the router redirects a guest attempting one to the
  /// login screen.
  ///
  /// **`/checkout` is deliberately not here**, and it used to be. A guest may
  /// buy: the contact
  /// step opens empty for them and pre-filled for a signed-in shopper, which is
  /// the whole point of collecting a name and a number there. Requiring an
  /// account first is the largest single drop-off in a shopping cart.
  ///
  /// The cost is recorded rather than hidden: the design's step 1 collects no
  /// email, so a guest order has no address to confirm to. See `progress.md`.
  static const List<String> protectedPrefixes = <String>['/orders', '/profile'];

  /// Whether [location] falls inside a protected area. Prefix-matched, so
  /// `/orders/42` is protected by `/orders`.
  static bool isProtected(String location) => protectedPrefixes.any(
    (prefix) => location == prefix || location.startsWith('$prefix/'),
  );
}
