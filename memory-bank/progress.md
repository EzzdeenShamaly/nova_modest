# Progress

**Last Updated:** 2026-08-29

Tracks what's Done, In Progress, and Blocked, per feature.

## Done

- **Stack lock** — `/platform-init`: Bloc · REST only · multi-locale
  (`ar` template + `en`). `02-flutter-state-guard.md` (bloc) and
  `11-flutter-l10n-guard.md` installed; `08-flutter-baas-security-guard.md`
  removed as inapplicable.
- **Project scaffold** — `/flutter-project-init`: `core/` (error, network,
  storage, theme, widgets, di), app shell, `go_router` with the auth redirect
  guard, `analysis_options.yaml`, `.gitignore` hardening, ARB pipeline.
- **auth (reference feature)** — sign-in, startup session check, sign-out.
  freezed entities, `ApiClient`-backed data source, `Result`-returning
  repository, `AuthBloc` with `droppable`/`sequential` transformers, localized
  `LoginScreen`. 26 tests passing; `flutter analyze` clean.

- **Design system** — `flutter_screenutil` (375x812), closed 5-colour `AppColors`,
  closed `AppSpacing`/`AppRadius`/`AppFontSize` scales, `app_theme.dart` rewritten
  onto them (seed colour removed), IBM Plex Sans Arabic bundled from
  `assets/fonts/`. `AppColors.error` `#B5524A` added as an explicit decision
  (carried over from the admin "cancelled" state), wired to `ColorScheme.error`.
  Convention codified as `.claude/rules/12-flutter-design-system-guard.md` and
  registered in CLAUDE.md. 6 theme tests assert the wiring. Suite: 32 passing.

- **splash** — built from Figma `14:14`. Localized tagline, non-translated Latin
  brandmark, palette-derived muted text, bundled Light weight, 1200ms minimum
  display floor in `AuthBloc`. 9 screen tests + 1 bloc-floor test. Suite: 43.

- **splash** — built from Figma `14:14`; 1200ms minimum display floor.
- **onboarding** — three slides via one reusable `OnboardingSlide` in a
  `PageView`, `shared_preferences`-backed per-device flag, two-bloc router guard,
  Home made public with a `?from=` sign-in gate for protected areas. 9 ARB keys.
  38 tests across repository, bloc, router and screen. Suite: **81 passing**,
  `flutter analyze` clean.

- **Startup fixes** — `AuthCheckInProgress` split out from `AuthLoading` so the
  splash is held for the real check; `resolveRedirect` extracted as a pure
  function with a full state-matrix suite (regression-verified against the old
  logic); `locale` pinned to `ar`. Suite: **103 passing**.

- **Passwordless sign-in** — Google + email one-time code, from Figma `1:2247`
  and `1:2438`. New `AuthRepository` contract with `FakeAuthRepository`
  registered and the HTTP one written but unregistered; `SignInBloc` (factory)
  for the flow, `AuthBloc` still the session authority; `OtpInput` with paste,
  advance and backspace handling; 12 ARB keys added, 6 password ones removed.
  Suite: **116 passing**.

- **Home + bottom navigation** - `StatefulShellRoute` with four branches,
  `AppBottomNav`, three placeholder tabs, `FakeCatalogRepository`, `HomeBloc`
  with the full four-state contract, and the Home screen from Figma `1:2469`.
  **149 tests passing.**

- **Product listing** — `/categories/:categoryId` nested in the categories
  branch, `ProductListBloc` with the four states and a tag filter, sold-out card
  state, and `FilterChipRow` unified across Home and the listing. Built on the
  existing `CatalogRepository` — one catalogue, two queries. **181 tests
  passing.**

- **Product details** — top-level `/product/:productId` above the shell, with a
  carousel, colour and size selectors, a quantity stepper and a sticky action
  bar. `Product` extended with the detail fields; `productById` added to the same
  repository. Card taps from Home and the listing now open it. **206 tests
  passing.**

- **Cart** — app-wide `CartBloc` fed by the product page, a `SharedPreferences`
  cart that stores ids and rehydrates products from `CatalogRepository`, the
  cart screen from Figma `1:2770` with all four states, and a real bottom-nav
  badge. `QuantityStepper` promoted to `core/widgets/` with a variant. **253
  tests passing.**

- **Shared product filter** — `ProductFilter` + `ProductFilterOptions` in the
  catalogue domain, one `showProductFilterSheet` from Figma `1:1180`, and the
  product listing migrated onto it with no change in behaviour. Facets draw only
  where they have more than one option, which is what lets one sheet serve both
  the listing and search.

- **Search** — `/categories/search` from Figma `1:1282` and `1:1077`: one screen
  with a discovery face and a results face, `SearchBloc` with a package-free
  debounce, `searchProducts`/`trendingSearches` on the existing
  `CatalogRepository` with Arabic letter folding, and a
  `SharedPreferences`-backed `SearchHistoryRepository`. Home's search icon now
  leads somewhere. **348 tests passing.**

- **Account** — the main screen from Figma `1:1645`: header card from the
  `AuthBloc` user, an eight-row menu on a reusable `ProfileMenuTile`, a
  confirmed sign-out that goes through `AuthBloc`, and seven placeholder routes
  behind the menu. `User` gained a nullable `phone`. **367 tests passing.**

- **Personal information** — `/profile/personal` from Figma `1:1593`, the first
  writing screen: `updateProfile` on `AuthRepository` with a fake behind it,
  `ProfileEditBloc` reporting to `AuthBloc` via `AuthProfileUpdated`, a locked
  email enforced by the contract rather than the UI, and an unsaved-changes
  guard. `User.phone` is now editable. **396 tests passing.**

- **Addresses** — `features/address/`, its own bounded context so checkout can
  reuse it: `Address` with `kind`/`label` split and its own postal formatters,
  an `AddressRepository` owning the "exactly one default" rule, list and form
  blocs, and `AddressForm` as a **widget** the checkout step will host inline.
  Replaces the second account placeholder. **454 tests passing.**

- **Address form usability + switch contrast** — a failed validation now scrolls
  to the offending field instead of leaving the save button looking dead, and
  `switchTheme` fixes an off state that rendered at 1.00:1 for every switch in
  the app. Both regression-verified against the broken code. **468 tests
  passing.**
- **Address route wiring** — the form routes are wrapped in a `ShellRoute` that
  provides `AddressListBloc` above both screens; nesting a `GoRoute` had given
  them a path but never a shared widget tree. Covered by
  `test/router/address_routes_test.dart`, regression-verified against the broken
  code first. **466 tests passing.**
- **DI smoke test** — `test/core/di/injection_test.dart` exercises the real
  `configureDependencies()` and resolves all 24 registered types. Added after two
  device-only failures passed a clean `analyze` and the whole suite. Regression
  -verified by deleting a registration and watching it fail. **461 tests
  passing.**

- **Language** — `features/settings/` with `LocaleBloc` + a `SharedPreferences`
  repository, the chooser from Figma `1:1818`, and the removal of the
  `Locale('ar')` pin that had stood since the onboarding. Switching is immediate
  and flips direction without restarting or losing the navigation stack, proven
  by a new real-app test harness. **485 tests passing.**

- **Categories tab** — its root now opens the existing product listing instead
  of an empty placeholder, per the design treating the tab and Home's "see all"
  as one destination. `features/categories/` deleted. **486 tests passing.**

- **Help and support** — `/profile/help`, built without a Figma frame: four FAQ
  entries the code can answer truthfully, and copy-to-clipboard contact rows.
  **496 tests passing.**

- **Terms and conditions** — `/profile/terms`, built without a Figma frame: a
  clearly-marked stand-in rather than drafted clauses, with a test that keeps it
  from becoming one. **501 tests passing.**

- **Notifications** — `/profile/notifications`: a preferences entity, a
  `SharedPreferences` repository and a factory bloc beside `LocaleBloc`, with
  two topic switches. Retires `_accountPlaceholders` entirely. The DI smoke test
  now derives its coverage from the generated config instead of a hand-kept
  list. **526 tests passing.**

- **Checkout structure + step 1** — `features/checkout/`: `CheckoutStep`,
  `CheckoutDraft`, `ContactDetails` and a `CheckoutBloc` provided by a
  `ShellRoute` around `/checkout`; the contact step pre-filled from `AuthBloc`
  or empty for a guest. `/checkout` left `protectedPrefixes` so guests can buy,
  and the cart's checkout button is live.

- **Checkout step 2 — delivery address** (`1:1944`) — `AddressStep`, hosting the
  existing `AddressForm` and reading the existing `AddressListBloc`; selection
  defaults to the address the repository marks default; a new address is saved
  into the address book and becomes the selection. `CheckoutDraft` gained
  `Address? address`. The step indicator was rebuilt from this frame with rails
  and three appearances (passed / current / ahead), and the forward button is
  now named per step. `test/router/checkout_route_test.dart` proves the
  `ShellRoute` supplies the two address blocs — the assertion no screen test can
  make.

- **The contact step's pre-fill reaching its fields** — found by that router
  test and fixed the same day. `CheckoutStarted` always seeded the draft, but
  `ContactStep` built its controllers on the first frame, which renders the
  bloc's initial state. `didUpdateWidget` now re-seeds a field whose value the
  shopper has not changed.

- **Checkout step 3 — shipping and payment** (`1:2059`) — `PaymentStep`,
  `ShippingMethod` and `PaymentMethod` as enums carrying their own money, and
  `OrderTotals` for the four figures. Cash on delivery is chosen; the card is
  drawn under "قريباً" and cannot be selected, with nothing stubbed behind it.
  The cart arrives as a snapshot in `CheckoutStarted`, read from `CartBloc` by
  the route. **`CartTotals.shippingFee` moved from a flat 30 onto
  `ShippingMethod.standard.cost` (35)** so the total no longer jumps between the
  cart and checkout. The step indicator was corrected — its two levels were
  backwards and it was not centred — and its tests now compare to the measured
  frame rather than to the constants the widget uses.

- **Checkout review + the order seam** (`1:1840`) — `ReviewStep` reports back
  all three steps with a "تعديل" link each, lists the ordered lines, and totals
  what will actually be charged. **First `OrderRepository` in the project**,
  with `FakeOrderRepository` minting `ORD-YYMMDD-NNNN` and refusing an
  incomplete draft. `CheckoutPlacing` / `CheckoutFailed` added; confirming is
  `droppable()`. `CheckoutState.returnTo` carries where an edit should return
  to. `_Artwork` extracted to `core/widgets/product_thumbnail.dart`.
  **The review draws a payment card and a payment-fee row the frame does not**
  — without them it would promise a total 15 short of the charge.
  **630 tests passing.**

## In Progress

- **The confirmation screen** (`1:2137`) — reached now: confirming lands on
  `CheckoutStep.success`, which still renders a named `PlaceholderTab`. It shows
  «رقم الطلب: ORD-260818-0001» and two actions, and `CheckoutDraft.order`
  already holds the number it needs.

## Not Started

- **Artwork** — onboarding, hero banner and product cards all draw a palette
  stand-in. Blocked on real photography; the Figma sources are 286x512, below 1x
  for their slots.
- **Orders** — the last account destination still a `PlaceholderTab`, and the
  only remaining user of that widget. Two Figma frames exist: `1:1356` (طلباتي)
  and `1:1480` (تفاصيل الطلب).
  Building one replaces a single entry in `_accountPlaceholders` with a
  `GoRoute`, as personal information, addresses and language have.
- **First-launch language chooser** (`1:2304`) — a full-screen "اختر لغتك" with
  the brandmark and large option cards, belonging to the onboarding flow rather
  than the account. Unbuilt; it would sit on the same `LocaleBloc` with no new
  state. Whether the app should ask before the onboarding at all is its own
  decision.
- **Size guide** — the link on a product page is inert; the chart screen is
  unbuilt.
- **Search relevance ordering** — `ProductSort.relevance` is whatever the
  catalogue returned. A real backend would rank; the fake matches in list order.
- **Share** — the product page's share action is disabled: a platform share
  sheet needs a package that is not in `pubspec.yaml`.
- **Push notifications** — the preferences screen records choices that **nothing
  reads**. No push package is in `pubspec.yaml` and no backend consumes them.
  The screen says the phone's own settings decide whether anything arrives,
  because the app cannot query that permission either.
- **Real terms text** — the screen states plainly that the policy is not there
  yet. Supplying it is a business task, not a technical one.
- **Terms behind the sign-in gate** — `/profile/terms` is protected by prefix. A
  sign-up flow linking to it (`1:2026`, `1:2407`) would need the route moved
  above the shell first.
- **Real FAQ and support copy** — the help screen answers only what the code
  demonstrably does. Shipping windows, returns, payment methods and order
  tracking need copy from the client before they can be added, and the demo
  contact details need replacing with a real inbox and line.
- **A shared settings card** — `_MenuCard` (account), `_OptionCard` (language),
  `_Card` (help) and `_Card` (notifications) are **four** near-identical cards of
  rows. Promoting one costs edits to four screens and belongs in its own task.
- **A guest order has no email — accepted, not outstanding** (user,
  2026-08-24). Checkout step 1 collects a name and a phone only, as the frame
  draws it, and a guest has no account to borrow one from. **The phone is
  enough to track an order by**, and adding an email field or SMS confirmation
  is a real client decision to make when there is a real client to make it. Do
  not "fix" this by adding a third field.
- **Placing an order** — no `OrderRepository` and no order number. The success
  frame (`1:2137`) shows `ORD-260818-0001`; nothing generates it yet.
- **Token refresh** — `/flutter-network-gen`; see gap 1 in `activeContext.md`.
- **Crash reporting** — release blocker per `/production-readiness-review`.
- **`.claude/cache/repo-map.json`** — run `/repo-discovery`.

## Blocked

- _(nothing new — the error-colour and dark-mode questions were both resolved
  on 2026-08-19; see `activeContext.md`)_

- **Server-side cart** — the cart is local to the device: it is not tied to an
  account, does not merge on sign-in, and does not sync across devices.
  `CartRepository` is the seam a server cart would replace.
- **Real API integration** — `FakeAuthRepository` is what runs today. The HTTP
  `AuthRepositoryImpl` assumes `/auth/email-code`, `/auth/email-code/verify`,
  `/auth/me`, `/auth/logout` and the `AuthSession` JSON shape; none is confirmed.
  `signInWithGoogle` and `updateProfile` there both throw `UnimplementedError`
  on purpose — the first needs a native sign-in package to obtain an ID token,
  which is not in `pubspec.yaml`; the second needs a confirmed endpoint and
  payload. Unreachable while the fake is registered.
- **Saved addresses do not survive a restart**, for the same reason and on the
  same terms as the profile edit below.
- **Profile edits do not survive a restart.** `FakeAuthRepository` holds the
  edited user in memory; persisting real PII locally needs secure storage and a
  deliberate decision, and the backend will own it. Accepted knowingly
  (user, 2026-08-22) — see `activeContext.md`.
- **Superseded** — every endpoint (`/auth/login`, `/auth/me`,
  `/auth/logout`) and the `AuthSession` JSON shape (`access_token`,
  `refresh_token`, `display_name`, `avatar_url`) is assumed, not confirmed
  against a real backend. `API_BASE_URL` is still the placeholder. Confirm the
  contract before treating the auth feature as integration-ready.

## Toolchain notes

- `freezed` is pinned to the **prerelease** `^3.2.6-dev.1`: stable 3.2.5 caps
  `analyzer` at `<11`, and `injectable_generator` 3.1.3 requires `^12`. Revisit
  when a stable freezed supports analyzer 12+.
- `build_runner` is capped at `^2.15.1` for the same reason (>=2.15.2 wants
  analyzer >=13.3).
- `intl` is held at `^0.20.2` by `flutter_localizations` from the SDK.
