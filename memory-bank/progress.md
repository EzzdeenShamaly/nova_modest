# Progress

**Last Updated:** 2026-09-17

Tracks what's Done, In Progress, and Blocked, per feature.

> **A line in this file is a record, not a measurement.** It was true on the day
> it was written and nothing re-checks it afterwards. Before repeating one as
> fact — especially a "not yet done" — either re-verify it or hand it over
> marked with its date: *"as of 2026-08-31, progress.md recorded X"*.
>
> This is here because of a real failure on 2026-09-17: the line below saying
> `place_order` was unproven against a live server was 16 days old, and a real
> order had been placed in production the day it was written. It was repeated
> as current fact in an audit deliverable. The record was not wrong — reading
> it as present tense was.

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

- **The confirmation screen** (`1:2137`) — `SuccessStep`, terminal: the host
  drops its app bar, indicator and sticky bar for this step, and back leaves for
  the shop front. **`CartRepository.clear()` added** — there was none, so the
  cart survived a purchase intact — dispatched as `CartCleared` to `CartBloc` on
  the transition into success. "تتبع الطلب" is hidden from a guest, who would
  otherwise be sent to sign-in moments after paying. **Checkout is complete end
  to end**, and a router test walks all five steps through the real bloc and
  repository. **642 tests passing.**

- **Order history — the list** (`1:1356`) — `features/orders/` is its own
  feature now, and `Order`, `OrderTotals` and the repository moved into it so
  the feature that reads orders does not depend on the one that writes them.
  `OrderStatus` reconciles the two frames' three badges and five tracker stages.
  **`FakeOrderRepository` remembers now** — in memory, like addresses — and
  seeds the three orders the frame draws. `OrdersBloc` + `OrdersScreen` replace
  **the last `PlaceholderTab` in the app**. **671 tests passing.**

- **Order details** (`1:1480`) — `OrderDetailBloc` fetching by number,
  `/orders/:number` as a nested `GoRoute`, and the list card tappable at last.
  `OrderStatusTracker` derives its five stages from `OrderStatus.index`.
  `OrderItemLine` and `OrderPriceBreakdown` moved out of `review_step.dart` now
  that two screens draw them. **The orders feature is complete.**
  **694 tests passing.**

- **`SettingsCard`** — `core/widgets/`, replacing four hand-rolled copies:
  `_MenuCard` (account), `_Card` (help), `_Card` (notifications) — byte-for-byte
  identical — and `_OptionCard` (language), which differed only in its fill.
  Two variants, `outlined` and `filled`. **The four screens' 87 existing tests
  passed without a single edit**, which is the proof the refactor changed no
  behaviour. **701 tests passing.**

- **Supabase merged** (omar.ismail's `8ffd2ef`, ported 2026-08-30) — the live
  backend for auth, catalogue, addresses and orders. Bindings are
  environment-scoped, so the suite still runs entirely on the fakes.
  `SupabaseOrderRepository` ported to `features/orders/` against the grown
  `Order`, with every line of his Supabase logic kept. Two migrations add
  `processing` to `order_status` and make `place_order` report the status it
  wrote. **`/platform-init` re-locked: Supabase + REST, and
  `08-flutter-baas-security-guard.md` installed.** **710 tests passing.**

## In Progress

- _(none)_

## Not Started

- **Artwork** — onboarding, hero banner and product cards all draw a palette
  stand-in. Blocked on real photography; the Figma sources are 286x512, below 1x
  for their slots.
- **Size guide** — the link on a product page is inert; the chart screen is
  unbuilt.
- **Search relevance ordering** — `ProductSort.relevance` is whatever the
  catalogue returned. Now that Supabase is the catalogue, ranking is a query
  change rather than a missing backend.
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
- **Token refresh** — `/flutter-network-gen`; see gap 1 in `activeContext.md`.
- **Crash reporting** — release blocker per `/production-readiness-review`.

## Decisions taken, not tasks

- **Guest checkout is refused outright — decided against, not deferred** (user,
  2026-09-17). `/checkout` is now in `Routes.protectedPrefixes`; a signed-out
  shopper who opens it is sent to sign-in and returns to `/cart`.

  **The reason is visibility, not conversion.** A guest order was a black hole:
  the row had no `user_id`, so `orders_select_own` hid it from the buyer who
  had just paid, and no admin read policy exists either. Nobody on either side
  could see it. The database reached the same conclusion first and
  independently — M1 (2026-09-16) revoked `EXECUTE` on `place_order` from
  `anon`, so the anonymous call answers `401` / `42501` regardless of what the
  app does.

  It also removed a guard that only worked by accident: nothing stopped a guest
  reaching `place_order`; the address step happened to fail first, because every
  `SupabaseAddressRepository` method needs a user id. Three unrelated facts
  intersecting is not a control.

  Consequences, so they are not rediscovered: `SuccessStep.onTrackOrder` is
  non-nullable — reaching that step implies a session. The 2026-08-24 decision
  below that a guest order carries no email is **moot**, kept only because code
  written against it may still be read. Do not reintroduce a guest path; if the
  business ever wants one, it needs a way for the buyer to see the order, and
  that is a server change first.

- ~~**A guest order has no email — accepted, not outstanding**~~ (user,
  2026-08-24; **superseded 2026-09-17** by the entry above — there are no guest
  orders). Checkout step 1 collects a name and a phone only, as the frame draws
  it. The phone is still what an order is tracked by; the fields did not change,
  only who may reach them.

- **The owner-cancel path of `transition_order_status` is measured only in the
  negative direction** (user, 2026-09-17). Deferred check D2 in the dashboard's
  `customer.md` wants both halves. The **negative** half is what was at stake:
  an owner attempting a move the graph forbids must be refused with
  `transition_not_allowed`, **not** `not_authorised` — the first means the
  database recognised them as the owner and evaluated the graph, the second
  means the ownership check failed and any signed-in stranger could cancel
  someone else's order. That is the security question, and it is answered
  without spending anything.

  The **positive** half — an owner actually cancelling their own pending
  order — is **deliberately not measured**, and this is not a gap to close
  later on its own. Measuring it needs an order to destroy, and the storefront
  has no cancel button at all, so it would be proving a path no shopper can
  take. It gets measured when the feature exists, as part of building it.

- **No first-launch language chooser** (user, 2026-08-30). `1:2304` draws a
  full-screen "اختر لغتك" with the brandmark and large option cards. **It will
  not be built.** Arabic is the default and the language is switchable from the
  account section, which is enough — and asking before the shopper has seen
  anything is friction in front of the app rather than a service to them. This
  is settled, not deferred: do not re-raise it as outstanding work.

## Open after the Supabase merge

- **Email sign-in works end to end against the live stack** (2026-08-31), after
  three fixes: `AuthFlowType.implicit` (PKCE cannot redeem a typed code),
  `mapSupabaseError` reading `error.code` before `statusCode`, and `OtpInput`
  pinned LTR so the six boxes do not mirror under Arabic. The catalogue reads
  and the RLS policies were verified live too — `42501` from
  `order_number_sequences` is the authorisation refusal rule 08 describes.
- **The signed-in customer path is proven end to end, in production**
  (established 2026-09-17 from evidence dated 2026-08-31). Order
  `ORD-260831-0001` exists in the cloud project, placed 2026-08-31 13:28 UTC
  from a real account. That one row exercises the whole chain the merge ported:
  sign-in → cart → address (`user_addresses` write) → `place_order` → an order
  row with its lines. **It was placed from the app**, not by a script: no
  session transcript contains a REST call to `rpc/place_order`, every `psql` ran
  as `docker exec supabase_db_nova_modest` against the local stack that was
  already shut down, and at 13:28 UTC the agent session was running `git commit`
  and `git push`.

  **The account was an ordinary customer at the time** — the `admins` row was
  written 2026-09-02 12:04 UTC, two days later. So this is not an admin
  bypassing anything; it is the customer path, and it is the strongest evidence
  this storefront has. It stayed hidden for sixteen days behind the "unproven"
  line this bullet replaces.

  The timestamps close it completely (read 2026-09-17): `as92@smail.ucas.edu.ps`
  was created in `auth.users` at **2026-08-31 13:23:07 UTC** and the order was
  placed at **13:28** — five minutes later, on the first sign-in that ever
  worked against the cloud. It became an admin on 2026-09-02.

  **That is also why the dashboard's deferred checks D1 and D2 were born
  deferred.** Both need one thing: an order owned by an account that is not an
  admin. Such an order was placed on day one and *was* that, for two days —
  then its owner was promoted and the only qualifying row stopped qualifying.
  Nothing was overlooked and no check was written wrong; a promotion two days
  later retroactively disqualified the evidence. Worth remembering as a shape:
  **a measurement can be invalidated by a change to something it never
  measured.**

  **A second live order, `ORD-260917-0001`** (placed 2026-09-17 12:51 UTC).
  Read back from the database on 2026-09-19.

  > **Corrected 2026-09-19.** This entry first said the order was placed by
  > `as92+shopper@smail.ucas.edu.ps`. That was written **before** the owner was
  > measured, and it was wrong: the run signed in with the main address by
  > mistake, and the row's owner is **`as92@smail.ucas.edu.ps` — the admin**.
  > It is the exact failure the note at the top of this file warns about, made
  > by the agent that wrote the note. Only what a query returned belongs in this
  > file as fact.

  What the row **does** prove, measured:

  - **Defect 1f is closed, with evidence.** The counter row for the day is
    `2026-09-17 → 1`, and `(placed_at at time zone 'Asia/Riyadh')::date` is
    also `2026-09-17` (12:51 UTC = 15:51 Riyadh). Before M5 those two
    expressions diverged — the counter keyed on the UTC day, the printed number
    on the session's zone. They are now one value. The number
    `ORD-260917-0001` was predicted before the order was placed and matched.
  - `total` = **430** = 380 + 35 + 15. A `GENERATED ALWAYS` column, so the
    server computed it; one line; `orders_total` went 1 → 2.
  - `orders()` ran against the live server and the storefront's orders screen
    listed the order. **`orderByNumber()` is not established** — nobody opened
    the detail screen — and was wrongly claimed here before.

  What it does **not** prove: anything about a customer. It is the admin's
  order, so D1 and D2 stay deferred — the same trap `ORD-260831-0001` fell
  into, for a different reason.

  **Also measured from the storefront side for the first time, 2026-09-19:**
  - Contract rule 5: reading `orders` with no session answers `42501`,
    *permission denied for table orders* — not `200 []`.
  - `contract_version()` answered `version 2`, `schema_digest
    a892643ec4bde3567fd435900e75dfe5` — both equal to the contract's lines, so
    the contract described the database on that date. The first time the
    freshness check has actually been run rather than planned.

  Still unexercised: `integration_test/` does not exist, so none of this is
  repeatable without a person driving it.
- **SECURITY DEBT — untested, deliberately: `claude_reader` can probably read
  any customer's rows by impersonating them** (recorded 2026-09-19; the owner
  decides whether and how to test it — on a separate project, never on
  production).

  *The claim.* `claude_reader` — the read-only role the dashboard's agent uses,
  whose connection string sits in `nova_modest_admin/.claude_db_url` — was
  measured to see **zero** rows in `orders`, `order_items`, `auth.users` and
  `order_number_sequences`. That is probably true only until it sets one
  variable.

  *The mechanism.* The own-row policies on `orders`, `order_items`, `profiles`
  and `user_addresses` apply **`to public`** and test `auth.uid()`, which reads
  the `request.jwt.claims` setting. PostgREST sets that setting itself from a
  verified JWT, and an API client cannot touch it. A role that connects to
  Postgres **directly** can: `set local request.jwt.claims =
  '{"sub":"<uuid>"}'` makes `auth.uid()` return whatever it chose, and every
  `to public` own-row policy then admits that customer's rows. `claude_reader`
  holds SELECT on all four tables through `pg_read_all_data`, and does not need
  to be a member of `authenticated`, because the policies are not restricted to
  it.

  *What limits it.* It needs the target's UUID, and `auth.users` is invisible
  to the role. The admin-read policies are `to authenticated`, so impersonation
  would not reach them.

  *Scope.* Not a storefront defect — the storefront never connects directly. It
  is a property of any direct-login role against these policies, and the
  dashboard's agent uses exactly such a role.

  *Why it was not tested.* Testing it means impersonating a real customer to
  read their name, phone and address on production. That is not a probe to run
  because a hypothesis is interesting.

  *A candidate fix, not decided:* restrict the own-row policies `to
  authenticated`. A role outside `authenticated` would then match no policy at
  all, whatever it sets. Whether that is right is the owner's call.

- **"طلباتي" shows an admin every customer's orders.** Production carries
  `orders_admin_read` and `order_items_admin_read` (M3): `permissive`,
  `for select to authenticated using (is_admin())`. Permissive policies are
  OR'd, so for an admin's session RLS returns **every** row.
  `SupabaseOrderRepository.orders()` has no user predicate — deliberately, per
  `08-flutter-baas-security-guard.md` §1 — so an admin signed into the
  storefront sees other people's orders under "My orders", and
  `orderByNumber()` opens any customer's order by number.

  **Not a breach**: the admin is authorised to read those rows; that is what M3
  is for, in the dashboard. It is a storefront screen that says "mine" and
  means "everything this session may read". Invisible until 2026-09-17 because
  every order belonged to the admin.

  **The customer side is measured, and it is correct** (2026-09-19, by the
  user, before the shopper's first order): signed in as
  `as92+shopper@smail.ucas.edu.ps`, "طلباتي" showed **"لا توجد طلبات بعد"** —
  zero orders — while the database held two, both the admin's. So
  `orders_select_own` filters exactly as intended for a customer: the negative
  direction is proven, with no predicate in Dart. It is also the first time the
  orders screen's empty state rendered against a live server rather than a fake.

  That pins the defect down precisely: it exists **only in an admin's
  session**, where `orders_admin_read` is OR'd in. For every customer the
  predicate-free query is correct today.

  Two consequences, flagged 2026-09-19, **neither fixed**:
  1. The storefront needs `.eq('user_id', <uid>)` on both reads — as a
     statement of *meaning*, not as protection. RLS stays the control.
  2. **Rule 08 §1 is now stale.** It says `orders()` "selects from `orders`
     with no `where`, and that is correct". It was correct before M3 added a
     second SELECT policy. The rule's principle stands (never treat a Dart
     filter as the boundary); its example no longer does.

- **Debt: the cart's total is always 15 short of what the shopper pays**
  (reported by the user 2026-09-19, during the live run: the cart showed 555,
  the order came to 570). `CartTotals.total` is `subtotal + shipping`
  (`cart_totals.dart:40`); the cash-on-delivery fee of 15
  (`payment_method.dart:13`) joins only at checkout, via
  `CheckoutDraft` (`checkout_draft.dart:78`). Cash on delivery is the only
  method that can place an order — card is refused with
  `payment_not_available` — so the fee is never optional, and the cart
  understates every order by exactly 15. The same shape the shipping comment in
  `cart_totals.dart` already warns about: a total that jumps mid-purchase with
  nothing on screen to explain it. Not blocking; not fixed.

- **FIXED 2026-09-19 — the "added to cart" snack bar never went away, and
  blocked checkout.** Found live: it sat over the cart's checkout button for
  minutes. Cause, from the code: not `duration` (the default 4 s), not a
  listener re-showing it — the call is in `onPressed`, once per tap. The
  snack bar carries a `SnackBarAction`, and `SnackBar` sets
  `persist = persist ?? action != null`, so it never timed out; the app-wide
  `ScaffoldMessenger` carried it from the product page onto the cart. It was
  the **only** one of eleven snack bars in the app with an action. Fixed with an
  explicit `persist: false`. The existing test only asserted that the
  confirmation *appears*, which is why it passed throughout; two tests now
  assert it *leaves*, and that one tap queues nothing behind it — both failed
  against the old code on behaviour.

  **Still open, a UI decision:** the user finds four seconds too long for a
  plain confirmation.
  It is not the 4-second default running long. The snack bar in
  `product_detail_screen.dart` carries a `SnackBarAction` ("عرض السلة"), and
  Flutter's `SnackBar` sets `persist = persist ?? action != null`
  (`snack_bar.dart:303`) — **a snack bar with an action does not auto-dismiss
  at all**; it stays until the action or the close icon is tapped. So setting
  `duration: 2s` alone would change nothing.

  The user's intent — a simple confirmation should be gone in a second or two —
  runs into a real accessibility reason: Flutter persists action snack bars
  because an action that times out is unreachable for someone navigating by
  screen reader or switch. The choice to make later, not now:
  - drop the action and let the cart badge be the route to the cart — then a
    short `duration` is right and costs nobody anything; or
  - keep the action with `persist: false` and a duration long enough to reach
    it — which a one-to-two-second window is not.

  The cart-full refusal snack bar added on 2026-09-17 has no action, so it
  already dismisses after the default four seconds.

- **Three screens read a field nothing fills.** `Product` carries **two**
  places for artwork: `imageUrl` (`@JsonKey(name: 'image_url')`) and
  `images` (`@Default(<String>[])`). `SupabaseCatalogRepository` fills
  **`imageUrl` only** (`supabase_catalog_repository.dart:175`); `images` is
  left empty on every product the server returns.

  So `product_card.dart:63` shows a picture once `products.image_url` is set,
  while `cart_item_tile.dart:57`, `orders_screen.dart:149` and
  `order_item_line.dart:51` read `images` and therefore draw the palette
  placeholder **forever**, whatever is uploaded.

  Nothing crashes — `ProductThumbnail` handles an empty list and a broken URL
  alike — which is exactly why this is easy to miss: the cart and the order
  screens look deliberate rather than wrong. Found 2026-09-17 while checking
  whether a live order run could proceed with no artwork. **Not fixed**: the
  run does not depend on it, and the right fix is one field rather than a
  patch at three call sites. Expect the order-detail screen to look
  artwork-free during the run and do not read that as a defect in the run.

- **Google sign-in is untried** and needs a web client ID plus the provider
  enabled, per the teammate's README.
- **The cart is still device-local** while everything around it is server-backed
  — the recorded "server-side cart" gap, now more visible.
- **`supabase_bootstrap.dart` uses the deprecated `anonKey`.** One analyzer
  info; the rename to `publishableKey` is omar's call, not a merge fix.
- **`config/dev.json` is required to run the app at all.** `initializeSupabase()`
  throws without it, deliberately — but it means a fresh clone cannot launch
  until someone copies the example.

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
