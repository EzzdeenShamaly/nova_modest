# Active Context

**Last Updated:** 2026-08-30 (Supabase merged; the project has a real backend)

What's being worked on right now, updated after every significant task per
`00-memory-think.md`.

## Startup bug fixes (2026-08-19)

Two defects found on an emulator, both now fixed and covered.

**Splash was skipped.** `_onCheckRequested` emits its "waiting" state
immediately and only *then* holds for the 1200ms floor, so `AuthBloc` left
`AuthInitial` within microseconds — and the router's undecided set was
`AuthInitial` alone. The floor worked; the router simply never waited on it.
Fixed by splitting the state: **`AuthCheckInProgress`** for the startup check,
`AuthLoading` for user-initiated waits. Collapsing them is what made the bug
possible in both directions — hold on neither and the splash is skipped, hold on
both and submitting the login form throws the user back to the splash.

**Skip appeared on the left.** Not a code defect: the sweep found *zero* physical
`left`/`right` anywhere in `lib/`, and `GlobalWidgetsLocalizations.delegate` is
present so Directionality does follow the locale. The device was English, where
`topStart` correctly resolves to the left. `locale: const Locale('ar')` is now
pinned in `app.dart` until a language switcher exists.

**The redirect is now a pure function**, `resolveRedirect(...)` in
`app_router.dart`. The widget-level router tests could not express a *transition*
— pinning a bloc to one fixed state hides exactly this class of bug, which is how
thirteen passing tests missed it. `test/router/redirect_logic_test.dart`
enumerates the full state matrix instead, and was verified to fail against the
old condition before being kept.

## Passwordless sign-in (2026-08-19)

Built from Figma `1:2247` (method selection) and `1:2438` (code verification).
The design's older `1:2364` — phone + password + forgot-password — is
deliberately **not** built; the product has no passwords.

- **Contract:** `AuthRepository` is now `signInWithGoogle` / `requestEmailCode` /
  `verifyEmailCode` plus `currentUser` / `logout`. **`FakeAuthRepository` is the
  registered implementation** — always succeeds after 700ms, and writes through
  the real `TokenStorage` so a session survives a restart and sign-out clears
  something. `AuthRepositoryImpl` targets the same interface and is deliberately
  **unregistered**; swapping is one line in `core/di/`.
- **State:** `SignInBloc` (a **factory**, feature-scoped) runs the flow.
  `AuthBloc` stays the app-wide session authority and learns the outcome through
  `AuthSessionEstablished(user)` — no repository round-trip, so sign-in does not
  pay the startup floor's 1.2s.
- **Removed:** `LoginForm`, `LoginScreen`, `AuthLoginSubmitted`, and the
  `passwordLabel` / `passwordTooShort` / `showPassword` / `hidePassword` /
  `loginButton` ARB keys. `password` now appears in `lib/` only inside comments.
- **Routing:** `/login` is the method screen, `/verify-email?email=` the code
  step. `Routes.authPaths` covers both, so a user who has just signed in is moved
  off either.
- The Google mark is an exported PNG at 1x/2x/3x — no SVG package, and the four
  brand colours never appear as literals in Dart.

Two real layout defects were caught by rendering the screens and looking:
the OTP row overflowed by 9pt at the design width (six 48pt boxes do not fit
327pt; the design's own row leaves 2pt of slack), and the Google button
overflowed by 16pt with a longer label. Both are now impossible at any width.

## Home + bottom navigation (2026-08-19)

Built from Figma `1:2469` in five phases.

**Phase 1 - shell.** `StatefulShellRoute.indexedStack` with four branches
(`/home`, `/categories`, `/cart`, `/profile`) behind `AppShell` + `AppBottomNav`.
Each tab keeps its own navigator and scroll position; a test asserts Home stays
mounted offstage while another tab shows. `/profile` was already in
`Routes.protectedPrefixes`, so the sign-in gate now applies to a tab as well as a
deep link — also tested. Categories and Cart are `PlaceholderTab`s; Profile
carries the sign-out action that used to sit in Home's app bar.

**Phase 2 - data.** `Product` / `ProductCategory` (freezed) and
`FakeCatalogRepository`, registered exactly as `FakeAuthRepository` is. Its rows
are the design's own copy and prices, generated from the Figma node rather than
retyped. Product and category names are **data**, so they are deliberately not in
the ARB files — which is why they stay Arabic under an English UI.

**Phase 3 - state.** `HomeBloc`, and with it **the four-state contract finally
lands**: loading, error, empty and data are all reachable and all asserted.
`auth` is submit-shaped and never could demonstrate it, which is why
`progress.md` carried "first list-shaped feature" as an open item from the
scaffold onward. A filter that matches nothing is deliberately *not* `HomeEmpty`
— the chips have to stay on screen or the user is stranded.

**Phase 4 - UI.** `HomeScreen`, `HomeHeroBanner`, `CategoryChipRow`,
`ProductCard`. Artwork is the same palette placeholder the onboarding uses;
passing an image is the only change needed later.

**Phase 5 - verification.** 15 screen tests, 11 bloc tests, 7 shell tests.
Rendered in both locales and inspected.

### Notes worth keeping
- **The alpha levels are now named.** `AppColors.mutedStrong` / `muted` /
  `subtle` / `hairline` replaced four ad-hoc `withValues(alpha:)` values scattered
  across five files — the same drift rule 12 exists to stop, in alpha space
  instead of hex space. Only `app_theme.dart` still holds inline alphas, for
  disabled-state tints that are Material's concern rather than the palette's.
- **intl does not give Arabic-Indic digits for `ar`.** CLDR's default numbering
  there is Latin. What it does localise is symbol placement and the direction
  mark, which is what the price test now pins.
- `test/helpers/screen_blocs.dart` registers stand-ins for blocs that screens
  resolve from the container themselves. Two navigation suites broke on this
  twice; centralising it means the next such screen breaks one file.

## Product listing (2026-08-19)

Built from Figma `1:2671` in three phases, on the catalogue that already existed.

**Phase 1 — data.** `CatalogRepository` gained **one** method,
`productsInCategory`. `Product` gained `isSoldOut` and `tags`, and `ProductTag`
joined the entities. `FakeCatalogRepository` kept its single product list and
grew the design's four abayas into it — no second fake. `featuredProducts` now
takes a slice, so Home did not change when the listing's rows arrived; a test
pins that.

**Phase 2 — state and routing.** `ProductListBloc` (factory) with the same
four-state contract, plus a tag filter derived from the products in hand.
`/categories/:categoryId` is a **child of the categories branch**, not a tab: the
design shows the bar with Categories active, and nesting keeps the bar in place
and lets back pop within the branch. Home's hero and "see all" now open it.

**Phase 3 — UI.** `ProductListScreen`, and `CategoryChipRow` became
`FilterChipRow` — one component serving both screens, since Home filters by
category and the listing by tag. `ProductCard` gained the sold-out state: scrim,
badge, no favourite control, and no tap.

### Notes worth keeping
- **`ProductCard` no longer fixes its artwork ratio.** It used `AspectRatio`, so
  the card's height depended on the grid's cell ratio: Home cleared its cell by
  0.2pt and the listing overflowed by 3.5pt — the same card, two grids, one of
  them wrong. The artwork is now `Expanded` and takes whatever the text leaves,
  so no cell ratio or text scale can overflow it.
- **The listing title is data.** It comes from the category the catalogue names,
  falling back to the raw id rather than an invented label. A failure fetching
  the name does not fail the screen — the products are what the user came for.
- The filter (tune) button opens the same tags as a sheet. The design's separate
  filters screen (`1:1180`) is not built.
- **`features/home/` was renamed to `features/catalog/`** once it owned Home,
  the listing, and the shared card and chip row — the folder is the bounded
  context, so it is named for the catalogue rather than for one of its screens.
  `HomeScreen` and `HomeBloc` keep their names: Home is still a screen inside it.

## Product details (2026-08-19)

Built from Figma `1:2584` in four phases, on the catalogue that already existed.

**Not a shell branch.** The design replaces the bottom navigation with a sticky
action bar, so this is a **top-level** route `/product/:productId` above the
shell — unlike the listing, which stays inside the categories branch. `push`, so
back returns to whichever screen opened it. `ProductCard.onTap` had existed
unused since Home; this is what it was for, and both Home and the listing now
pass it.

- **Domain:** `Product` gained `description`, `images`, `colours`, `sizes`,
  `features`. Two new entities, `ProductColour` and `ProductFeature`. One method
  on the contract, `productById` — an unknown id is a `NotFoundFailure`, not an
  empty result. Same fake, same product list.
- **State:** `ProductDetailBloc` holds the colour, size and quantity, because
  they are the inputs to "add to cart" rather than decoration. Quantity is
  clamped in the bloc; the buttons only reflect the rule.
- **No `Empty` state, deliberately.** A single-entity screen cannot be in one: a
  product exists or it does not, and "does not" is a failure. Adding one would
  create a state nothing could emit.

### Notes worth keeping
- **Product colours are content, not palette.** The swatches paint the garment's
  own hex, parsed at run time from what the catalogue supplies. The one
  `Color(0x…)` left in `lib/` outside `app_colors.dart` is that parser's alpha
  mask — every other colour in the app still comes from a token.
- **`intl` exports its own `TextDirection`**, which shadows `dart:ui`'s and
  silently breaks every directional literal in a file that imports both. The
  detail screen imports it `hide TextDirection`.
- **The size chips share their row** instead of taking the design's fixed 78pt.
  Four fixed chips clear the design's 350pt by two pixels and wrapped at our page
  padding — the third time that knife-edge has appeared, after the product card
  and the OTP row.
- A stale listing test asserted `ProductCard.onTap` was null for a sold-out
  product. It only passed because nothing had ever passed a handler; now that the
  detail screen does, the assertion moved to the `InkWell`, which is where the
  behaviour actually lives.

## Cart (2026-08-22)

Built from Figma `1:2770` in five phases. The first feature whose state is
**shared between two screens**, which is what shaped every decision in it.

**How the selection travels.** The product page dispatches
`CartItemAdded(product, colourId, size, quantity)` to an app-wide `CartBloc`.
It does **not** hand over `ProductDetailBloc`, and the cart never reads it:
that bloc is a factory that dies with the screen, and a cart has to outlive
the page it was filled from. Everything crosses as values.

**Storage keeps ids, not products.** `CartLineDto` persists
`(product_id, colour_id, size, quantity)` in `SharedPreferences`, and every
load re-reads each `Product` from `CatalogRepository`. A price change or a
sold-out flag therefore reaches a cart that was saved before it — storing the
product itself would have frozen whatever it cost the day it was added. Two
consequences worth knowing:

- A product that has left the catalogue **drops out** of the cart and is pruned
  from storage. Any other catalogue failure propagates instead — showing an
  empty cart for a network error would tell the shopper their cart was cleared.
- `CartError` is genuinely reachable, because both the disk read and the
  catalogue lookup can fail. An in-memory cart would have made the four-state
  contract's error state dead code, which is the argument that decided it.

**Line identity is the product plus every choice on it** —
`lineId = 'productId|colourId|size'`. The same garment in two sizes is two
lines; the same garment in the same size is one line with a higher count,
capped at `CartItem.maxQuantity` (10).

**Mutations do not pass through `CartLoading`.** Adding usually happens while
the shopper is on the product page, so a spinner would blank a tab behind them;
on the cart itself it would flicker the list between two counts. A `blocTest`
pins the emitted sequence to exactly one state.

**Still a shell branch.** The Figma frame is a transactional one — back button,
no bottom bar — but the bar itself carries a cart destination with a badge, and
a tab that hides the bar it was tapped from is a broken tab. The bar stays; the
frame's missing bar is treated as an omission. The badge is now real:
`BlocSelector` on `itemCount > 0`, replacing the hardcoded `showBadge: true`.

### Notes worth keeping
- **`QuantityStepper` moved to `core/widgets/`** and gained
  `QuantityStepperVariant`. The second user is the moment to promote a widget,
  and the cart's design draws the same control outlined rather than filled —
  one behaviour, two skins, instead of two steppers that drift.
- **`CartTotals` is a domain value**, not a `fold` inside `build()`. Shipping is
  a flat `CartTotals.shippingFee` (30, from the design), named as a placeholder:
  no threshold and no zones were specified, so none were invented.
- **The snack bar outlives the screen.** Its "عرض السلة" action resolves the
  router at **tap** time behind a `context.mounted` check, not in `build`.
  Calling `GoRouter.of(context)` during build coupled the product page to having
  a router above it and broke twenty of its widget tests.
- **"Add to cart" is gated on `isSelectionComplete` as well as stock.** The bloc
  preselects a colour and a size, so the gate is a backstop rather than a state
  a shopper reaches — kept deliberately (user, 2026-08-22) because the button
  now has a consequence, and adding a sized garment with no size would be a real
  defect. Do not remove it as dead logic.
- **The design prices in `د.إ`; the app prices in `ر.س`.** Every other screen
  uses `currencySymbol`, so the cart does too. Changing the currency is an
  app-wide decision, not a cart one.
- `#F7F3F2` (summary card) and `#F1EDEC` (thumbnail well) both resolve to
  `AppColors.hairline`. `background` is nearer to `#F7F3F2` numerically (ΔE 2.4)
  but identical to the page, so the card would have vanished.
- **Checkout is disabled.** `/checkout` is in `Routes.protectedPrefixes` but has
  no `GoRoute` and no screen, so the sticky bar's button is inert rather than
  leading nowhere — the same call the product page's share action makes.
- `test/helpers/` gained `stubCartBloc()` and a `cartBloc:` parameter on
  `pumpApp`. Unlike the stand-ins in `screen_blocs.dart`, `CartBloc` is not
  resolved from the container by its screens — `app.dart` provides it — so tests
  pass one in rather than registering it.

Verified: `flutter analyze` clean, **253 tests passing** (17 repository, 14 bloc,
15 screen, plus the existing suites updated for the new provider).

## Search (2026-08-22)

Built from Figma `1:1282` (browsing), `1:1077` (results) and `1:1180` (filters),
in five phases. The first phase was **not** new code — it was extracting a
filter concept that already existed in one screen so a second could share it.

### The filter is now one thing, app-wide

The listing narrowed by tag; the design's search filter narrows by category,
price, size and colour. Different facets, but "apply a filter to products
already in hand, with options derived from those products" is the *same*
operation — and writing it twice is how two screens drift into two ideas of
what filtering means.

- **`ProductFilter`** (`catalog/domain/entities/`) holds all six facets,
  including `tagId`, which is what made the listing's migration lossless:
  `selectedTagId` became `filter.tagId`, `visibleProducts` became
  `filter.apply(products)`. `apply` is pure and tested directly, not through a
  bloc.
- **`ProductFilterOptions.from(products, categories:)`** derives what the filter
  can be set to. Its `hasCategories` / `hasTags` / `hasSizes` / `hasColours` /
  `hasPriceRange` are the reason **one sheet serves both screens with no special
  case**: a facet with fewer than two options cannot narrow anything, so a
  single-category listing simply draws the style section and nothing else.
- **`showProductFilterSheet`** replaced the listing's ad-hoc tag sheet. It
  returns the applied filter or **null when dismissed** — backing out must not
  read as "cleared everything". The inline `FilterChipRow` stays and writes into
  the same value through `ProductListTagSelected`.
- Phase 1 ended with the listing behaving *identically* and its suite green.
  That was the acceptance condition, not an afterthought.

### The search screen is one screen with two faces

The field is in both frames and an empty query is what separates them, so this
is a state change, not a route change. `SearchIdle` is **not** the empty state:
empty means "this query matched nothing", idle means "nothing has been asked",
and the design gives it its own screen. Clearing the field re-shows the
discovery content from `_idle`, the last-emitted idle state the bloc holds —
so there is no spinner over content that has not changed.

### Notes worth keeping
- **Arabic search folds the letters people actually type.** `FakeCatalogRepository`
  normalises alef forms, taa marbuta/haa, alef maqsura, harakat and tatweel
  before matching. Without it "عبايه" returns nothing while "عباية" returns
  eight rows, and the screen looks broken to whoever typed it the ordinary way.
  It lives behind the repository seam because that is what a backend's search
  index does.
- **Debounce with no new package.** `restartable()` plus a `Future.delayed` at
  the top of the handler: a keystroke cancels the handler still waiting out the
  pause. `bloc_concurrency` ships no debounce transformer, and `rxdart` /
  `stream_transform` are not in `pubspec.yaml`. The handler guards on
  `emit.isDone` after the await — without it the cancelled run throws.
- **History records on submit, never on a keystroke**, or the recent list fills
  with every prefix of what was actually searched for.
- **Trending terms are drawn from the catalogue's own categories and tags**, not
  from the design's five invented phrases. A term that reads well and matches
  nothing is a worse fake than a duller one that always lands; a test asserts
  every trending term returns products.
- **`/categories/search` is declaration-order dependent.** Both it and
  `:categoryId` are children of `/categories`, and go_router matches in order,
  so the literal has to be declared first. A router test pins it, because
  getting it wrong fails at run time and not at compile time.
- **`ColourSwatch` was made public** out of `ColourSwatchRow`. The product page
  offers colours one-of-many, the filter sheet many-of-many; the hex parsing,
  the fallback and the luminance-aware tick are the part that must not be
  written twice, the layout around them is not.
- **`#2563EB` in the filter mock is Material's default blue**, not this palette
  — every other selected state in the same frame is black. The checkbox uses
  `AppColors.primaryText`.
- The design prices the filter range in **د.إ** again; the app stays on `ر.س`.
- **The result count is a real ICU plural** with Arabic's `=0/=1/=2/few/many/other`
  branches (`11-flutter-l10n-guard` §3). A ternary is wrong in four of them.

### A test-infrastructure defect this surfaced
Two widget tests pumped the same screen twice in one test — once per locale, and
once per state. Flutter reused the element, so `BlocProvider.create` never re-ran
and the **second pump silently kept showing the first state**: "renders in ar and
en" was asserting Arabic twice, and passing. Both suites now pump with a fresh
`UniqueKey`, and the filter sheet's locale loop asserts the sheet is actually on
screen before checking for exceptions. The same false-coverage shape as the
sold-out `onTap` assertion from the product listing.

Verified: `flutter analyze` clean, **348 tests passing**.

## Account (2026-08-22)

Built from Figma `1:1645` in three phases. The main screen only — personal
information, addresses and language each have their own frame and are their own
piece of work.

**No repository and no state machine of its own.** The screen reads `AuthBloc`,
which already owns the signed-in user app-wide; a second source for the same
person would be one that could disagree. It follows that there is **no
four-state contract here**, for the same reason `ProductDetailBloc` has no
`Empty`: nothing loads. `/profile` is in `Routes.protectedPrefixes`, so anyone
who reaches the screen already has a resolved session, and the only other state
it can be caught in is the instant between requesting sign-out and the router
moving them on. The `switch` lists every remaining `AuthState` explicitly rather
than using a wildcard, so a state added later is a compile error here.

### What changed outside the screen
- **`User` gained `String? phone`.** Nullable on purpose: sign-in is Google or
  an email code, so a shopper can genuinely have an account and no number. The
  header omits the line rather than drawing an empty one.
- **Seven placeholder routes** — `/orders` plus six under `/profile`. All are
  `PlaceholderTab`, driven from one `_accountPlaceholders` table in
  `app_router.dart` rather than seven near-identical `GoRoute` blocks; the day
  one becomes real it leaves the table. `/orders` is an **absolute sibling**
  inside the account branch because it is protected under its own prefix, not
  under `/profile` — same branch, so the bar keeps the account tab active.
- `PlaceholderTab`'s doc no longer claims to be tab-only; it now stands in for
  pushed routes too.

### Notes worth keeping
- **`Icons.chevron_right` is declared with `matchTextDirection: true`** — checked
  in the SDK source, not assumed — so it mirrors to point at the end of the row
  in either direction. No `// direction-fixed:` tag, and no physical override.
- **Sign-out asks first.** The design draws it as one more row in a scrolling
  list, which makes it the easiest thing on the screen to hit by accident. The
  dialog is the only addition to the frame. The screen still never navigates:
  it emits `AuthLogoutRequested` and the router's guard moves the user, because
  `/profile` is protected and the session is now gone.
- **`#BA1A1A` is Material's default error red**, ΔE 28.9 from `AppColors.error`.
  Decided (user, 2026-08-22): keep the terracotta — "signing out is reversible,
  not dangerous", and the palette already carries a destructive role added by an
  explicit decision. The third mock-artefact colour after `#2563EB` in the filter
  sheet.
- **`#747878` maps to `AppColors.muted` at ΔE 9.2**, the largest gap accepted so
  far. The design's grey is neutral and the token is warm — but that warmth *is*
  the palette, and every other screen's secondary text already uses it.
- **The language row names the language in force**, via a `languageName` ARB key
  whose value is each locale's own endonym (`العربية` in ar, `English` in en).
  No lookup table to go stale when a third locale arrives.
- The avatar draws the first **code point** of the name, not `substring(0, 1)`,
  so a name starting outside the basic plane is not cut in half. `avatarUrl` is
  already on the entity, so real artwork later needs no new field.
- **`Material` asserts if given both `borderRadius` and `shape`.** The menu card
  needs a border, so it takes the shape. And `AppColors.subtle` is a derived
  alpha — `final`, not `const` — so neither the card's `BorderSide` nor the
  hairline `Divider` between rows can be a const expression.

### A test-assertion defect this surfaced
A router test asserted `router.routerDelegate.currentConfiguration.uri` after
tapping a menu row, and failed against a navigation that plainly worked: an
**imperative `push` inside a shell branch leaves that uri reporting the branch
root**. Instrumented under `/flutter-debug`'s exception, confirmed the pushed
screen was rendered, and moved the assertion onto what the user sees. The
`DEBUG-TEMP` line was removed before the run that passed.

Verified: `flutter analyze` clean, **367 tests passing**.

## Personal information (2026-08-22)

Built from Figma `1:1593`. The **first writing screen in the app** — everything
before it either read the catalogue or held state locally — and the first of the
account menu's seven destinations to stop being a placeholder.

### Where an edit goes
Decided with the user, and the shape matters more than the screen:

- **`AuthRepository.updateProfile({displayName, phone})`**, with a fake
  implementation — not a local-only edit, and not a second `ProfileRepository`.
  Every other data path in this app has a seam with a registered fake; a screen
  that wrote to state without one would be the only one.
- **The email is not a parameter.** "The address cannot be changed" is stated in
  the contract, so no caller can express the change — the disabled field in the
  UI merely reflects it rather than being the rule.
- **`ProfileEditBloc`** (factory) runs the form and reports the result to
  `AuthBloc` through the new **`AuthProfileUpdated`** event. Exactly the path
  `SignInBloc` takes with `AuthSessionEstablished`, and for the same reason: a
  transient "saving" state must not live in an app-wide singleton. `AuthBloc`
  ignores the event unless a session is open, so an edit landing after a
  sign-out cannot sign anyone back in.
- It lives in `features/auth/presentation/bloc/` beside `SignInBloc`, though the
  screen it serves is a profile screen: both are factories over `AuthRepository`
  reporting to `AuthBloc`, and the profile feature already reads `AuthBloc` from
  auth.

### The known, accepted divergence
`FakeAuthRepository` holds the edited profile **in memory**. The token still
goes through real secure storage, so a *session* survives a restart — but an
edited name does not, and the account reverts to the seeded user on the next
launch. Persisting it would mean either plaintext preferences, which
`03-flutter-security-guard` forbids for a name and a phone number, or widening
the `TokenStorage` seam for the sake of a stand-in. Accepted until the backend
owns this (user, 2026-08-22). Do not "fix" it with `SharedPreferences`.

### Notes worth keeping
- **`failureMessage(failure, l10n)` was extracted** out of `FailureView`. A form
  that fails to save reports it in a snack bar rather than replacing the fields —
  what was typed is still correct — and writing that `switch` twice is how two
  surfaces end up disagreeing about what a `CacheFailure` says.
- **An emptied phone field is a clear, not "unchanged".** `null` travels all the
  way to the repository, and both the bloc test and the fake test pin it.
- **Save is disabled until something actually differs.** The controllers have
  listeners so "nothing to save" is visible rather than discovered by tapping.
- **Leaving with unsaved edits asks first**, via `PopScope`. The second addition
  to a frame after the sign-out dialog, and for the same reason: losing typed
  work to one back gesture is worse than an extra tap.
- **`PopScope` is explicitly `PopScope<Object?>`.** Untyped it is
  `PopScope<dynamic>`, which a test cannot name in `find.byType` to read
  `canPop`.
- Phone validation is deliberately loose — digits, `+`, spaces, brackets and
  dashes, at least seven digits. No country format was specified, and an E.164
  rule would turn away valid local numbers.
- `AuthRepositoryImpl` (still unregistered) gained `updateProfile` throwing
  `UnimplementedError`, like `signInWithGoogle`: the endpoint is not confirmed
  and guessing it would put a fiction behind a compiling method.

### A test that passed for the wrong reason
The `droppable()` test asserted a double tap writes once — and it did not: the
mocked repository returned instantly, so nothing overlapped and both events went
through. `droppable` only drops while the previous handler is *still running*.
The stub now carries 50ms of latency, which is what makes the assertion mean
anything. Third instance of this shape after the sold-out `onTap` and the
double-pumped locale loops.

Verified: `flutter analyze` clean, **396 tests passing**.

## Addresses (2026-08-23)

Built from Figma `1:1767` (the list) and the form card inside `1:1944` (the
checkout step, which holds the only address-form design in the file). The second
account destination to stop being a placeholder.

### Built for two features from the start
`features/address/` is its own bounded context, not part of `features/profile/`.
Checkout will pick a delivery address from the same repository, and building it
inside the account feature would have left checkout depending on the profile
screen to ask for one. Three consequences, all deliberate:

- **`AddressForm` is a widget, not a screen.** The account section hosts it on a
  pushed page; checkout will host it inline, which is exactly how `1:1944` draws
  it. Its host owns the save button and reaches it through a
  `GlobalKey<AddressFormFieldsState>`, so a sticky bar outside the form can
  submit it.
- **"Exactly one default, always" is the repository's rule**, not a screen's.
  Saving one as default clears the rest in the same operation, the first address
  saved is default whatever it claims, and removing the default promotes the
  next. Checkout inherits all of that for free.
- **`Address` carries its own formatters.** The two frames render the same
  address two different ways — a five-line postal block ending in the country,
  and a one-line summary starting with it — so the entity exposes `postalLines`
  and `shortSummary` rather than either widget composing them. Both assume one
  country's postal convention; a second country makes this a per-country
  formatter, not a longer getter.

### Notes worth keeping
- **`kind` and `label` are separate fields.** The glyph comes from the enum, the
  name from whatever the shopper typed, so "بيت أمي" still gets a house. Deriving
  the icon by matching the label would break the moment the language changed.
- **Held in memory, like the edited profile** and for the same reason: an address
  carries a recipient, a phone number and where someone lives, which
  `03-flutter-security-guard` keeps out of plain preferences. Accepted knowingly
  (user, 2026-08-22) — do not "fix" it with `SharedPreferences`.
- **`AddressFormState` collided with itself.** The bloc state and the form
  widget's `State` had the same name, and the screen that uses both stopped
  compiling. The widget's is now `AddressFormFieldsState`.
- **A `BlocProvider(create:)` closes the bloc it made.** Both address screens
  create theirs, unlike the cart and profile screens which receive one through
  `.value` and never own it — so their tests must stub `close()`, or the widget
  tree fails to finalise with `type 'Null' is not a subtype of type
  'Future<void>'`.
- The country control is the design's dropdown with **one** entry. A list rather
  than a constant so adding a country is one line, but not an invented world
  list either.
- The add bar is a solid bar with a top rule, as on the cart and the profile
  form — the frame fades the list out behind a gradient, which no other screen
  here does. It stays visible in the empty state: the frame offers no other way
  in, and an empty list with no way to fill it is a dead end.

### The hot-reload defect this surfaced
The app threw `NoSuchMethodError: No top-level method '_addresses' declared` on
opening Addresses, while `flutter analyze` was clean and 439 tests passed —
including one that opens the real screen through the router.

`_addresses` was never an ARB key (they cannot begin with `_`); it was a private
tear-off in the `_accountPlaceholders` table. That table was a **top-level
`final`**, which Dart initialises once and hot reload never re-evaluates: the
list in memory still held a pointer to a function the reload had deleted. The
error came from the `title(...)` call, and its argument — `Instance of
'AppLocalizationsAr'` — is what identifies it as the record field rather than a
localisation lookup.

Hot restart was the fix. The table is now a **getter**, so the next destination
to leave it survives a reload (user-approved, 2026-08-23).

### The coverage gap both device defects came through
A second runtime failure followed — `GetIt: Object/factory with type
AddressListBloc is not registered` — against a source tree where the
registration was present, unconditional, and correct. That one was a stale
process: `build_runner` rewrote `injection.config.dart` while `flutter run` was
live, and the reload did not pick it up. A full stop and re-run, not a hot
restart, is the reliable move after regeneration.

What matters is why **neither** defect was caught first: **no test touched the
real container.** Every screen test registers its own stand-in with
`sl.registerFactory`, so a missing `@injectable`, a file that failed to
regenerate, or an unresolvable dependency stays invisible while `analyze` is
clean and 450-odd tests pass.

`test/core/di/injection_test.dart` closes it: it calls the real
`configureDependencies()` and resolves every registered repository, data source,
infrastructure type and bloc — resolution *is* the assertion, since `get_it`
constructs the whole graph beneath each one. It also pins scope (factories hand
out new instances, app-wide blocs do not) and that the **fakes** are still what
is wired, so an accidental swap to an HTTP implementation shows up here.

**Verified to fail before being kept**: the `AddressListBloc` registration was
temporarily deleted from the generated config and the suite reported
`AddressListBloc does not resolve from the real container`, then the file was
restored. A container test that has never failed is the same false coverage it
exists to remove.

### Nesting a GoRoute is not nesting a widget
A third device-only failure followed: `Could not find the correct
Provider<AddressListBloc> above this AddressFormScreen`.

The address form routes were declared inside the list route's `routes:`, with a
comment claiming the form therefore "sits under" the list's bloc. **It does
not.** In `go_router`, nesting a `GoRoute` gives a child a path and a place in
the back stack — not a place in the widget tree. The child is a separate page
stacked over the parent, so a `BlocProvider` created inside the parent screen's
own `build` is never its ancestor. `ShellRoute` / `StatefulShellRoute` are the
only routes that wrap their children, which is why the tabs work and this did
not.

Fixed by wrapping the address routes in a **`ShellRoute`** that provides
`AddressListBloc` above both screens (user-approved, 2026-08-23). It consumes no
path segment, so `addresses` stays relative to `/profile` and the sign-in gate
still covers everything beneath it. `AddressListScreen` no longer creates the
bloc; the shell owns it, which is also what makes the form's post-save refresh
reach the real list.

**Why nothing caught it, again.** `address_form_screen_test.dart` wraps the
screen in `BlocProvider<AddressListBloc>.value` by hand — it encoded the same
wrong belief the router did, so it could only ever agree with it. A screen test
builds whatever tree it is told to; whether the **app** builds that tree is a
routing property, and nothing was asserting it.

`test/router/address_routes_test.dart` closes that: it drives the real router to
`/profile/addresses`, `/new` and `/:addressId`, and asserts the screens render.
**Verified to fail first** — run against the pre-fix code it reproduced the
device's exact `ProviderNotFoundException` on three of its five cases.

The standing lesson from all three defects in one session: a screen test proves
a screen works *given a tree*; only a router test proves the app builds that
tree, and only the DI test proves the container fills it.

### A save button that read as dead
Adding an address did nothing on tap while editing one worked perfectly — which
is the whole diagnosis in one sentence: **an edit opens pre-filled, so
validation passes.** Adding leaves required fields empty, and the form is ~934pt
tall in an ~668pt viewport, so "العنوان بالتفصيل" and its error message sit
under the fold. `Form.validate()` does not move to the first error, and
`submit()`'s `false` return was discarded, so nothing happened anywhere the
shopper could see.

Fixed by scrolling to the first field actually in error, plus
`AutovalidateMode.onUserInteraction` **after** the first submit — help once they
have been told something is wrong, nagging before that.

**And the fourth false-positive of the session.** A test for this already
existed and passed:

```dart
expect(find.text('هذا الحقل مطلوب'), findsWidgets);   // green, and meaningless
```

`find.text` searches the **element tree**, and a `SingleChildScrollView` builds
every child whether or not it is on screen. The message was in the tree and 80pt
below the viewport. The replacement fills every visible field, leaves one
below-fold field empty, and asserts the error's `getRect` is **inside** the
375x812 surface — verified failing first at `bottom: 892.0`.

Standing rule this adds: **asserting a widget exists is not asserting anyone can
see it.** For anything below a fold, measure the rect.

### A switch nobody could see was a switch
Material 3 takes a switch's off state from the `ColorScheme` — track from
`surfaceContainerHighest`, and **both** the track outline and the thumb from
`outline`. This palette maps all three to `AppColors.secondary`, so an unthemed
switch off was one solid `#E8DFD3` block at **1.00:1**.

Fixed in `app_theme.dart` with a `switchTheme`, not at the call site, so every
future switch inherits it: off thumb `mutedStrong` (**7.14:1** against the
track), off outline `muted`, one track colour throughout. The on thumb stays
`accent` at 1.75:1 by decision (user, 2026-08-23) — position and colour are two
signals, and the on state is not the one that was unreadable. `activeThumbColor`
left the address form, since the theme now states it once.

Verified: `flutter analyze` clean, **468 tests passing**.

Verified: `flutter analyze` clean, **454 tests passing**.

## Language (2026-08-23)

Built from Figma `1:1818`. Small screen, and the **first app-wide state that
re-renders everything** — including the writing direction.

### The pin is gone
`locale: const Locale('ar')` had been hardcoded in `app.dart` since the
onboarding, as an explicitly temporary answer to an English emulator rendering
the whole Arabic-first product in English. `LocaleBloc` (`@lazySingleton`)
replaces it, satisfying `11-flutter-l10n-guard` §8 — the selected locale is
state, persisted, read by `MaterialApp`, never a global.

**Still defaults to Arabic, deliberately.** Following the device is exactly what
the pin existed to prevent; removing the pin must not reintroduce it. English is
two taps away.

**Immediate, no restart** — the design's explanatory line is a promise the
architecture keeps: `_router` is built once in `App.initState`, so rebuilding
`MaterialApp.router` with a new locale re-renders the tree and flips its
direction while leaving the navigation stack exactly where it was.

### Notes worth keeping
- **`features/settings/`** is the new home, matching `features/onboarding/` in
  shape — both are device preferences, not session state. Notifications will
  join it.
- **`SharedPreferences`, and here that is the right answer** rather than a
  compromise: `03-flutter-security-guard` names an interface preference as the
  non-sensitive case. Addresses and the profile went to memory because they
  carry PII; a language code carries none.
- **A failed save still switches the language.** The failure rides along on
  `LocaleResolved.saveFailure` so the screen can say the choice will not survive
  a restart — refusing a language change over a disk error would be a poor
  trade.
- **Each language names itself**, via `lookupAppLocalizations(locale)` against
  that locale's own `languageName` key. A chooser that labelled Arabic in
  English would be unusable to the person who needs it.
- The account menu's language row already read `l10n.languageName`, so it went
  live with no change at all.
- The frame draws a gold dot inside the **unselected** ring too — a mock
  artefact, like `#2563EB`, `#BA1A1A`, `#513C00` and `#6B7280` before it. An
  unchosen radio has no dot.

### Two bugs caught while building it
**A forced `TextDirection.ltr` on the endonyms.** Written into the option row,
it would have laid "العربية" out backwards — in the one screen whose whole job
is to be readable to someone who cannot read the current language. Removed: each
label is a single word in a single script, and the engine resolves that from the
string itself.

**A snack bar in the language the shopper had just left.** Applying the locale
and reporting a failed save are two emits in **one microtask**, so the listener
runs before any rebuild: the enclosing build's `l10n` still held the old
language, and so did `AppLocalizations.of(context)` — the inherited
`Localizations` had not been rebuilt either. Instrumented with a `DEBUG-TEMP`
line that printed which string was present (`AR: 1, EN: 0`), which is what named
the cause; the line was removed before the passing run. Fixed by looking the
message up from the locale **the state carries**,
`lookupAppLocalizations(state.locale)` — deterministic, and no frame-timing
games.

### A new kind of test
`test/helpers/pump_real_app.dart` boots the **real** `App`: its own
`MaterialApp.router`, its own router built in `initState`, its own providers.
Almost every other test pumps one screen inside scaffolding it controls, which
by construction cannot see how the app is assembled — the same blind spot that
produced the `_addresses` tear-off, the stale DI graph and the missing
`AddressListBloc` provider.

`language_switch_test.dart` uses it to assert what only exists once the app is
running: the interface switches language **and direction** without leaving the
screen, the navigation stack survives two pushes deep, a stored choice is what
the app opens in, and a price stops showing `ر.س` under English — that last one
guarding the decision to keep `intl` locales explicit at each call site instead
of setting a global `Intl.defaultLocale`.

Verified: `flutter analyze` clean, **485 tests passing**.

## Categories tab (2026-08-23)

The tab opened an empty `PlaceholderTab`. It now opens the product listing
directly: there is no separate "pick a category" design, because the frames
treat this tab and Home's "see all" as **one destination** — the listing that
already existed on `/categories/:categoryId`.

A routing change, not a screen. `/categories` builds
`ProductListScreen(categoryId: Routes.entryCategoryId)`; the `search` and
`:categoryId` children are untouched. Rendered directly rather than through a
`redirect`, which would have had to be kept from swallowing those children.

- **`Routes.entryCategoryId`** is `_entryCategory` promoted out of
  `home_screen.dart`, where it already existed privately for "shop now" and
  "see all" — the second use is the moment to promote, as with `QuantityStepper`
  and `ColourSwatch`. It is a catalogue id living in the routing layer, which is
  an assumption about the data; the comment says so and names what replaces it.
- `features/categories/` is gone. It held nothing but the placeholder.
- The content is now reachable at two URLs (`/categories` and
  `/categories/abayas`). Harmless, and cheaper than the redirect it avoids.

### The consequence that was not optional
`ProductListScreen`'s back button was a hardcoded `go(Routes.categoriesPath)`.
Once the branch root *is* that listing, back sent the shopper from the listing
to the same listing — a dead button in a loop. It is now shown only when there
is something to pop, and at a tab root the bottom bar is the way out.

**And `context.canPop()` was the wrong way to ask.** go_router's extension calls
`GoRouter.of` in `build`, which couples the screen to having a router above it —
sixteen of this screen's own tests failed instantly. `Navigator.of(context)`
answers the same question without the coupling. Same lesson as the product
page's snack bar: **do not ask the router anything during `build`.**

`screen_blocs.dart` gained a `ProductListBloc` stand-in, since every navigation
suite now reaches this screen through the tab.

Verified: `flutter analyze` clean, **486 tests passing**, with the new tab test
confirmed failing first.

## Help and support (2026-08-23)

**No Figma frame exists for this screen.** The closest candidate in the file,
`1:2163` "معلومات التواصل", is not a support screen — but the reading recorded
here was wrong twice over. It is **checkout step 1**, not sign-up step 3: the
indicator layer is named "الخطوة 1 من 3", and the active gold dot looked like
the third only because the dots were read left to right. In RTL the first one is
the rightmost. Corrected 2026-08-24 when checkout was built; the lesson is that
"checked before assuming" still needs the check to account for direction. The layout is therefore assembled
from the account section's own vocabulary: a titled card of rows with hairlines
between them.

Static by design: no bloc, no repository, no request.

### The content decision is the whole screen
Shipping windows, returns, payment methods and order tracking are what a shopper
actually asks — and every one is a business fact nobody has stated. A plausible
answer would put an **invented policy** in front of a customer as if it were the
shop's, which is `10-evidence-and-dependency-guard` in its most consequential
form: not a hallucinated symbol that fails to compile, but a hallucinated promise
that ships.

So the FAQ carries **four questions the code can answer truthfully**: passwordless
sign-in, the unchangeable email (the update contract genuinely has no field for
it), the language screen's immediate switch, and the addresses screen's
one-default rule. Everything else waits for real copy from the client, recorded
in `progress.md`.

### Notes worth keeping
- **Contact details are demo values** (user, 2026-08-23):
  `support@novamodest.com` and `+966 50 000 0000`, marked as such in the source.
  Not ARB strings — an address and a number are content, identical in every
  language, and a translator has no business editing them.
- **Tapping copies rather than opens.** Launching a mail app or a dialler needs
  `url_launcher`, which is not in `pubspec.yaml`; `Clipboard` ships with Flutter
  and makes the row useful today. The upgrade is one package away if asked for.
- The test intercepts `SystemChannels.platform` — that is both how the clipboard
  call survives a test and how the assertion is made.

### A duplication now at three
`_Card` here is the **third** near-identical card-of-rows, after the account
menu's `_MenuCard` and the language chooser's `_OptionCard`. Left local
deliberately: promoting a shared one means editing two working screens in the
middle of an unrelated change (`09-minimal-changes`). Recorded in `progress.md`
as its own task — three is where this stops being a coincidence.

### A process note on my own edits
Two scripted router edits failed their assertions because I wrote the expected
source text **from memory of how I had formatted it**, not from reading it — the
indentation had shifted two levels when the addresses `ShellRoute` was added, and
`dart format` reflowed it. The assertions caught it, so nothing was written
wrong; but the fix is to read the block first, as with any other claim about the
repository.

Verified: `flutter analyze` clean, **496 tests passing**.

## Terms and conditions (2026-08-23)

The smallest screen in the project: one icon, two lines, no bloc, no repository,
no interaction.

**No Figma frame exists** — verified against all 38 frames in the file, none of
which is a terms, policy or privacy screen. Second such screen after help, and
checked rather than assumed both times.

**The body is a stand-in on purpose** (user, 2026-08-23). Real terms are a
business decision; drafting plausible clauses would put invented legal text in
front of a customer as though it were the shop's — the same call the FAQ makes
about shipping and returns. A test asserts the screen carries **no** clause-like
wording, so the stand-in cannot quietly grow into a draft policy.

Flowing prose rather than a card: that is what the screen becomes when the real
text arrives — paragraphs to read, not rows to scan — and it avoids a fourth copy
of the card-of-rows already queued for promotion.

**Still behind the sign-in gate**, at `/profile/terms`. Terms are normally linked
from a sign-up flow, which would need them public; that flow is not built
(`1:2026`, `1:2407`), so moving the route is deferred rather than done for a need
that has not arrived. Recorded in `progress.md` so it is not discovered late.

With this one, `_accountPlaceholders` holds a **single** entry: notifications —
the only account destination that needs real state rather than static text.

Verified: `flutter analyze` clean, **501 tests passing**.

## Notifications (2026-08-23)

The **last** entry in `_accountPlaceholders` — the table is now gone, along with
its `_Placeholder` typedef and tear-offs. `PlaceholderTab` survives: `/orders`
still uses it, checked rather than assumed before deleting.

**No Figma frame exists** — checked against all 38, none is a notifications or
settings screen. Third such screen after help and terms.

Built beside `LocaleBloc` in `features/settings/` and shaped like it on purpose:
`NotificationPreferencesUnresolved` holds the defaults so the switches draw from
the first frame, `Resolved` carries what storage said plus an optional
`saveFailure`. No four-state contract — two booleans always have a value and
nothing here is a list. The one difference from its neighbour is scope: this
bloc is a **factory** because only its screen reads it, while `MaterialApp`
reads the locale on every build.

### What this screen honestly is
**Nothing consumes these preferences.** There is no push package in
`pubspec.yaml` and no backend to read them — the app records the choice and will
honour it when notifications exist. That is a real difference from every earlier
stand-in: a disabled checkout button *looks* disabled, while these switches look
like they work. Two things follow:

- The screen says plainly that **the phone's settings decide whether anything
  arrives at all**. The app cannot read the OS permission — no permission
  package is a dependency — so it must not let two switches imply a guarantee it
  cannot make. A test asserts that line is present.
- Recorded in `progress.md` as unbuilt plumbing rather than a finished feature.

### Notes worth keeping
- **Split by topic, not channel.** "Offers" and "marketing" as separate toggles
  were the same thing said twice; an email channel is one more field on the
  entity when a mailing list exists to address.
- **Defaults: orders on, promotions off.** Marketing is opt-in — the convention,
  and the direction regulation keeps moving in.
- **The change is applied before the write**, like `LocaleBloc`: a switch that
  waits for the disk before it moves reads as broken, and a `saveFailure` rides
  along so the screen can say the choice will not survive a restart rather than
  the app forgetting it silently later.
- `SharedPreferences` here is the *right* answer, not a compromise — an
  interface preference is what `03-flutter-security-guard` names as the
  non-sensitive case, unlike addresses and the profile.
- `_Card` is the **fourth** near-identical card of rows. Still local, still
  queued in `progress.md`.

### The DI smoke test had drifted
Adding these registrations showed that `test/core/di/injection_test.dart` was
covering 24 of 28 registered types — the settings feature had added four
(`LocaleBloc`, `LocaleRepository`, and this feature's two) that nothing resolved.
The file written to catch missing registrations had itself gone stale.

It now **reads `injection.config.dart` at test time**, extracts every `gh.…<T>()`
registration and asserts each one is resolved somewhere in the file. The first
attempt was a hardcoded `28 == 28`, which is a tautology that agrees with itself
— replaced before it was kept. **Verified to fail**: removing one `resolves<>`
call produced `Actual: Set:['NotificationPreferencesBloc']`.

Verified: `flutter analyze` clean, **526 tests passing**.

## Checkout — structure and step 1 (2026-08-24)

Built from `1:2163`, with `1:1944`, `1:2059`, `1:1840` and `1:2137` read to
settle the shape before writing any of it.

### What the frames actually say
**Three steps, not four.** Contact, address, and shipping-and-payment each carry
a step indicator; "مراجعة الطلب" carries none. Review is a confirmation *after*
the three, and success is the outcome — `CheckoutStep.indicatorIndex` returns
null for both.

**And `1:2163` is checkout step 1** — not, as this file previously recorded,
step 3 of sign-up. The indicator layer is named "الخطوة 1 من 3"; the gold dot
looked like the third only because the dots were read left to right, and in RTL
the first is the rightmost. Corrected here and in `help_screen.dart`.

### The shape
- **One route, one screen**, body switching on `state.step`. A route per step
  would let someone land on the review with an empty draft — a state every
  screen would then have to guard. The step is bloc state, so it cannot be
  skipped.
- **`CheckoutBloc` is a factory provided by the `ShellRoute` around
  `/checkout`**, so a half-finished draft dies with the flow instead of greeting
  whoever opens checkout next. `CartBloc` is a singleton because the badge reads
  it; nothing outside this flow reads a draft.
- **`CheckoutDraft` carries only what a built step fills in.** Address, shipping
  and payment gain fields when their frames are built; a placeholder now would
  guess a shape only the frame can settle.
- The bloc is handed the `User` rather than reading `AuthBloc`: the session is
  the account's concern, and checkout stays testable without one.

### Guests can buy now
`/checkout` was **removed from `Routes.protectedPrefixes`** (user, 2026-08-24).
The contact step opens pre-filled for a signed-in shopper and empty for a guest,
which is the whole point of collecting a name and a number there.

**The cost is recorded, not hidden:** the frame collects no email, so a guest
order has no address to confirm to. Raised with the user and **accepted as it
stands** (2026-08-24) — the phone number is enough to track an order by, and an
email field or SMS confirmation is a client decision for when there is a client
to make it. A test pins the behaviour by asserting a guest submits with
`email: null`; it is a recorded choice, not an oversight to tidy away.

### A layout defect, and three wrong hypotheses before the right move
The phone row's country-code control overflowed. I guessed three times — widen
the box to 112, split the row by flex, widen to 200 — and the inner constraint
stayed at **exactly 27.8pt every time**. That constant is the finding: the outer
width was never the variable, and Material's input decorator was fixing its own
inner row regardless.

`/flutter-debug`'s rule is to stop after two failed hypotheses and change the
mechanism rather than keep tuning it. The dropdown went: there is **one**
dialling code, so a selector chooses nothing, and a control that cannot be used
is not worth a layout fight. It is now a plain decorated segment sized to its
content, with the number field absorbing the rest — so the row cannot overflow
at any width. A second code turns it back into a selector.

A second, unrelated layout fault followed and was diagnosed properly first: the
unbuilt steps render `PlaceholderTab`, which fills its parent, and it sat inside
a `ListView` — an unbounded height. The body is now a fixed indicator over an
`Expanded` step, with the contact form scrollable in its own right.

### Notes worth keeping
- `ContactStep` is a **widget**, submitted by the host through a
  `GlobalKey<ContactStepState>` — the same arrangement `AddressForm` uses, and
  for the same reason: the host owns the app bar, the indicator and the sticky
  bar, and every step slots into that one frame.
- It carries `_revealFirstError` from the start. The address form shipped
  without it and a save button that silently did nothing was the result.
- **The design's `+970` is the odd one out** — every other number in the file,
  and the seeded account, are `+966`. The code segment uses `+966`.
- The cart's "متابعة الدفع" is **live**, after being disabled since the cart was
  built.
- The DI drift guard fired on cue: `CheckoutBloc` was registered and unresolved,
  and the suite named it.

Verified: `flutter analyze` clean, **554 tests passing**.

## Checkout step 2 — the delivery address (2026-08-29, `1:1944`)

Built on the seven decisions the user approved. It adds almost no address code,
which was the point: `Address`, `AddressForm`, `AddressListBloc`,
`AddressFormBloc`, `Address.shortSummary` and the repository's "exactly one
default" rule were all built for this and all reused as they stand.

### The shape
- **`AddressStep` is a widget**, submitted through a
  `GlobalKey<AddressStepState>`, like `ContactStep`.
- **The saved list is `AddressListBloc`**, not a second loader. Its four states
  are all live here: spinner, `FailureView` with retry, empty, and the cards.
- **Empty opens the form and only the form** — no list heading, no add button.
  An empty state in the middle of a purchase is one more thing to get past
  before the step can do what it is for.
- **The draft carries the whole `Address`, not its id.** The review screen draws
  it in full, and an id would make every later step look it up again.
- **Preselection is the default address**, and the widget finds it by
  `isDefault` rather than taking `addresses.first` — the repository sorts
  default-first, so a test with a realistic list could not tell those apart. The
  test deliberately passes an unsorted list.
- **A new address goes into the address book.** It is saved through
  `AddressFormBloc`, so the shopper finds it later under حسابي ← العناوين, and
  the step identifies the one just added by diffing ids against the set it held
  when the save was dispatched.

### The indicator was wrong, and step 1's frame is why
`1:2163` draws three plain dots, so that is what was built. `1:1944` draws the
same indicator with **rails between the stations and three appearances**:
passed (`hairline`), current (accent, 12pt not 8pt), still ahead (`subtle`).
Step 1 looked like equal dots only because nothing is behind it yet — its two
upcoming stations already carry the colour this rebuild gives them. The frames
never disagreed; reading one of them alone did.

Rebuilt, and the first version was wrong in a way a test caught: the rail
**after** the active station took the station's own colour, painting the road
ahead in accent — two steps in progress at once. A rail is only ever passed or
ahead, never current. The test compares all five colours against the frame.

### The forward button is named per step
«التالي» → «حفظ ومتابعة» → «مراجعة الطلب» → «تأكيد الطلب». Only step 2's is
wired, from its own frame; `1:1840` and `1:2137` draw no bottom bar at all, so
inventing copy for them would be a guess.

### Two things the frame says and the app does not
- The frame's add button has a **black** border; the app's `OutlinedButton`
  theme assigns that role to `secondary`. Followed the theme — one screen
  overriding a shared button style is how a button style stops being shared.
- The frame draws the saved list **and** the form open together. Treated as the
  expanded state: the form is behind «إضافة عنوان جديد», and tapping a saved
  card closes it.

### A `DecoratedBox` that Flutter refuses
The form card started as a `DecoratedBox` with a background colour. `AddressForm`
contains a `ListTile` for the default switch, and a coloured box between a
`ListTile` and its nearest `Material` swallows the ink — which Flutter asserts
on rather than merely drawing wrong. It is a `Material` with a
`RoundedRectangleBorder` now, as the choice cards already were.

### The router test that found a shipped defect
`test/router/checkout_route_test.dart` opens `/checkout` through the **real**
router and walks to step 2 — the only test that can prove the `ShellRoute`
actually supplies `AddressListBloc` and `AddressFormBloc`, since the screen test
wraps them by hand. Proven by removing them: 47 screen tests still passed and
only this one failed.

It also caught a shipped defect in step 1 — below.

## The contact pre-fill never reached the fields (found and fixed 2026-08-29)

`CheckoutStarted` seeded `CheckoutDraft` correctly all along — through the real
router with an authenticated user, the draft held the name, phone and email. The
fields were empty anyway.

`ContactStep` builds its `TextEditingController`s from `widget.initial` on its
first frame, and **that frame renders the bloc's initial state**: `BlocProvider`
adds `CheckoutStarted` when it creates the bloc, and a bloc handles an event one
microtask later. The seeded state then arrived, `_CheckoutView` rebuilt, and
`ContactStep`'s `State` was retained with the empty controllers it was born
with. A signed-in shopper saw an empty contact form — the thing step 1 exists to
avoid.

**Why no test saw it:** `checkout_screen_test.dart` pumps an already-seeded
state, so the first frame it renders is the seeded one. The broken ordering only
exists when the bloc is created by the route, which is what
`checkout_route_test.dart` does.

**The fix (user chose A):** `didUpdateWidget` re-seeds a field when
`widget.initial` changes — and **only** if the field still holds what this
widget last put there, so nothing the shopper typed is overwritten. They may be
buying for someone else, which is why the frame lets these be edited.

Not a key derived from the draft (option B): that rebuilds the whole `State` to
work around the staleness, and would drop a caret if the draft ever changed
mid-typing. This updates the one thing that is actually stale.

**And the first version of the fix did nothing**, for a reason worth keeping:
the seeds were `late String _seededName = widget.initial.fullName`. A `late`
initialiser runs on first **read**, and the first read is inside
`didUpdateWidget` — where `widget` is already the *new* one. The seed recorded a
value the field had never held, so every comparison failed and the re-seed never
fired. They are assigned in `initState` now. `late` is lazy; when the value
depends on *when* it is read, that matters.

Verified: `flutter analyze` clean, **576 tests passing**.

## Checkout step 3 — shipping and payment (2026-08-29, `1:2059`)

The last step before the review. Seven decisions, all approved as proposed.

### The indicator was shipped wrong, and this frame is what proved it
Reading `1:2059` meant reading all three indicators together, by **absolute x**
rather than child order — the frames are RTL, so the rightmost child is step one.

| | `1:2163` | `1:1944` | `1:2059` |
|---|---|---|---|
| shape | three 10pt dots | 8pt dots + 48x4 rails, active 12pt | 32x8 pill + two 8pt dots |
| passed | — | `#CEC5BA` | `#CEC5BA` |
| ahead | `#CEC5BA` | `#EBE7E6` | — |

**Three frames, three shapes**, and `#CEC5BA` means "ahead" in one and "passed"
in another. Only `1:1944` shows both at once, so it is the reference.

Two defects in what shipped with step 2:

1. **The two levels were backwards.** `hairline` was drawn for passed and
   `subtle` for ahead; the frames say the opposite — the *fainter* level is the
   part that has not happened yet. The same left-to-right misreading that once
   filed `1:2163` as "step 3 of sign-up", in a file whose own comment warns
   about it.
2. **It was start-aligned.** All three frames centre it.

**The test I wrote to protect this froze the bug instead**, because it compared
the widget's colours to the constants the widget used. It compares to the
measured frame now, and one test pins the polarity on its own
(`subtle.a > hairline.a`) so a swap fails whatever any single step draws.

The user directed keeping the rails rather than adopting this frame's pill.

### The shape
- **`ShippingMethod` and `PaymentMethod` are enums carrying money** —
  `standard.cost = 35`, `cashOnDelivery.fee = 15`, `card.fee = 0`. On the method
  rather than as checkout constants, so changing the choice moves the total by
  itself.
- **`card.isAvailable` is false.** The frame draws it under "قريباً" with an
  empty radio, so it exists as an unavailable option rather than being dropped —
  the design is telling the shopper something, and omitting it would omit that.
  Nothing is stubbed behind it: no form, no token, no gateway.
- **`OrderTotals` is its own value**, not a field added to `CartTotals`: the cart
  has no payment fee and no method to produce one, and the two summaries are
  drawn differently (tinted card vs ruled block).
- **`shipping` and `payment` on the draft are not nullable.** The frame opens
  with both chosen, and there is one of each — "nothing selected yet" is a state
  the flow never has, and a nullable field would invent it.
- **The cart arrives as a snapshot** in `CheckoutStarted`, read from `CartBloc`
  by the route — the same terms as the signed-in `User`. The cart cannot be
  edited from inside the flow, so it cannot go stale while the flow is open.
- Selections live in `PaymentStepState` while the step is open, so the summary
  re-totals on each tap without a round trip; they reach the draft together on
  submit, because the total depends on both.

### The cart quoted 30 and checkout charged 35
`CartTotals.shippingFee` is now `ShippingMethod.standard.cost`, so the total a
shopper sees in the cart is the total they see at checkout. A figure that moves
between the two with nothing on screen explaining it is how a checkout loses a
sale. It is a **getter**, not a `const`: an enum's field cannot be read in a
constant expression.

### What the frame says and the app does not
- **`#747878`** outlines the empty radio — a cool grey this warm palette cannot
  derive. Used `AppColors.muted`, the nearest thing the palette already names
  for a control that is present but not offering itself.
- The bottom button is 20/w500 in the frame; the app's `FilledButton` theme
  decides that, and one screen overriding it is how a button style stops being
  shared.
- The **chosen** card here gets a `secondary` fill on top of the accent border,
  where step 2's address cards changed only their border. Followed as drawn: an
  option is a commitment to a price.

### The router test earned its keep again
`CartBloc` is read in the `ShellRoute`'s builder, one layer above the screen, so
whether the money ever reaches the step is a property of the route.
`checkout_route_test.dart` now walks contact → address → payment and asserts the
total. Proven by removing the wiring: only that test failed.

Verified: `flutter analyze` clean, **599 tests passing**.

## Checkout review (2026-08-29, `1:1840`)

The last screen before an order exists, and the first time this app writes
anything that is not a local edit.

### The frame is missing the payment method, and its total is wrong because of it
`1:1840` draws three cards — contact, address, shipping — and a two-line
breakdown. Its own arithmetic is consistent (2,100 + 35 = 2,135), so it was
drawn **before** cash on delivery carried a 15 fee.

Followed literally, the one screen whose entire job is to state what the shopper
is about to be charged would state 15 less than the charge. So the review draws
a **fourth card and a fourth row that the frame does not** (user, approved). A
test asserts the total includes the fee, and removing the row fails it.

### The order seam
- **`OrderRepository.place(CheckoutDraft)`** takes the whole draft: the draft
  *is* the order request, already in the shape the three steps build, and a
  field added by a later step would otherwise change this signature and every
  caller.
- **`FakeOrderRepository`** is the registered implementation, like every other
  repository here. It mints `ORD-YYMMDD-NNNN` — the format `1:2137` quotes —
  and **refuses an incomplete draft** with a `ValidationFailure` before the
  simulated latency. Unreachable through the UI, which cannot show the review
  without a contact and an address; refused at the seam rather than discovered
  at the warehouse.
- **It holds nothing.** A placed order is handed back and forgotten: there is no
  orders screen to read it from, and persisting order history to plaintext
  preferences is the PII call already settled for addresses and profile edits.
- `injectable` exports its own `Order` annotation, so every file naming this
  entity imports it with `hide Order` — the same collision the cart has between
  `intl`'s `TextDirection` and `dart:ui`'s.

### `CheckoutPlacing` and `CheckoutFailed`
Added exactly as `checkout_state.dart` predicted when it was first sealed, and
the sealing paid for itself: the compiler found every `switch` rather than
memory doing it. `droppable()` on `CheckoutConfirmed` — placing an order is the
one action in this app that must not happen twice — and the failure is a snack
bar over the intact review, not a `FailureView` that would throw away what the
shopper is about to confirm.

### A bloc field the UI could not see
"تعديل" jumps back to a step and finishing the edit returns straight to the
review. That return point started as a **private field on the bloc** — and the
back button promptly popped the shopper out of checkout entirely: it asks
whether anything is behind the current step, `CheckoutStep.contact.previous` is
null, and a field the UI cannot read could not say otherwise.

It is `CheckoutState.returnTo` now, with `canMoveBack` beside it. **Anything
that changes what the UI does belongs in the state** — which is what
`02-flutter-state-guard` says, and what a private field quietly opted out of.
The forward button honours it too, so finishing an edit returns to the review
whichever control the shopper uses.

Found by the router test walking contact → address → payment → review → edit →
back. No screen test could have: they pump a state directly and never exercise
the host's own decision about where back goes. A screen test pins it now as
well, and reverting either line fails both.

### A `ListView` hides what a `SingleChildScrollView` would have shown
Asserting the price breakdown failed at first because the body is a `ListView`,
which builds only what is near the viewport — an off-screen row is **absent from
the element tree**, not present and invisible. The exact opposite of the address
form's trap, where `SingleChildScrollView` built everything and a test passed on
a field the shopper could not reach. The test scrolls to it.

### Reuse rather than a fifth near-identical thing
- `_Artwork` left `CartItemTile` and became `core/widgets/product_thumbnail.dart`
  — two copies of "how this app draws a product image, and what it draws when
  there isn't one" would have drifted the first time a real URL arrived.
- The line's colour/size phrasing is `l10n.cartVariant` and its two siblings, the
  same keys the cart uses.
- `Address.reviewLines` joins `postalLines` and `shortSummary` as a third
  arrangement of the same fields, in the domain where the other two already are.

### What the frame says and the app does not
The confirm button is a pill (radius 9999); every other button in the app takes
its radius from the theme, and one screen overriding that is how a button style
stops being shared.

Verified: `flutter analyze` clean, **630 tests passing**.

## The confirmation screen (2026-08-29, `1:2137`) — checkout is complete

The shortest frame in the flow (528pt) and the one with the most that the frame
does not say.

### It is terminal, so the host drops its own chrome
`1:2137` draws no app bar, no indicator and no sticky bar; its two actions sit
in the content. `CheckoutScreen` suppresses all three for `CheckoutStep.success`
rather than this widget hiding underneath them — still one route, still "the
step is bloc state", so nobody can land on a confirmation with no order.

`canPop` is false throughout now, and the confirmation's back **leaves for the
shop front**. Popping would land on whatever opened checkout, which is the cart
the order has just emptied.

### Three things the frame does not show, all fixed

**The cart stayed full after a purchase.** There was no `clear` in
`CartRepository` at all — a shopper bought, tapped "متابعة التسوق", and found
the same items waiting to be bought again. `CartRepository.clear()` exists now,
wipes the stored ids as well as the state, and `CartCleared` is `sequential`
like every other mutation.

**Who clears it:** the screen dispatches `CartCleared` to the app-wide
`CartBloc` on the *transition into* success — not `CheckoutBloc` writing to
`CartRepository` itself. Two writers to one store would leave the navigation
badge disagreeing with storage until something re-read it. `CartBloc` stays the
single owner of cart state.

The listener is guarded on `previous.step != success`, not on
`current.step == success`: the second fires for any later state on that step. A
test emits a redundant success state and asserts nothing is cleared twice —
removing the guard fails it.

**A guest was thrown out right after paying.** `/orders` is behind the sign-in
gate by prefix, so "تتبع الطلب" would send someone who had just paid to a login
screen. The button is **not shown to a guest at all** — they have no account to
track an order through — and opens `/orders` for a signed-in shopper, where a
`PlaceholderTab` still waits.

### Notes
- The two ambient discs are drawn **without blur** (approved): `ImageFiltered`
  would match the frame at the cost of a raster layer on a screen whose whole
  job is to sit still and be read.
- The order number is `direction-fixed` LTR, like the dialling code.
- `#747878` appears a third time as the outlined button's border; the theme
  assigns that role to `secondary`, as it did for step 3's radio.
- The copy says "نتواصل معك", not "نرسل بريدًا" — which is the only honest
  wording while a guest order carries a phone number and nothing else.

Verified: `flutter analyze` clean, **642 tests passing**. The router test now
walks the entire flow — contact, address, payment, review, confirm — through the
real router, the real `CheckoutBloc` and the real `FakeOrderRepository`, and
asserts the cart was emptied at the end of it.

## Order history — the list (2026-08-29, `1:1356`)

Batch 1 of two. The last `PlaceholderTab` in the app is gone.

### `features/orders/` is now its own feature, and the order domain moved into it
`Order`, `OrderTotals`, `OrderRepository` and `FakeOrderRepository` lived under
`features/checkout/`. Leaving them there would have made the feature that
**reads** orders depend on the one that **writes** them — the exact inversion
`Address`'s own comment warns about, which is why `Address` sits in
`features/address/` and not in the profile screen that manages it.

Dependencies now point one way: `orders → {cart, address}`, `checkout → orders`.

`OrderTotals` lost its `of(CartTotals, {shipping, payment})` factory in the
move — it made an order-shaped value depend on checkout's two method enums.
Pricing a cart under a chosen pair is checkout's business, and
`CheckoutDraft.totals` does it now.

**This was a structural call made inside the approved work, not something the
plan spelled out.** Flagging it here because it moved four files.

### The repository remembers, reversing a decision recorded three batches ago
`FakeOrderRepository` was written to hand an order back and forget it, on the
stated grounds that no screen read orders. That screen is this one, so the
decision expired. It keeps them **in memory**, like `FakeAddressRepository` and
for the same reason: an order carries a recipient, a phone and an address, which
is the PII `03-flutter-security-guard` keeps out of plaintext preferences.
History survives navigation, not a restart.

It also **seeds the three orders `1:1356` draws** — one per badge appearance —
so the screen can be reviewed as designed. Their products are literals rather
than catalogue lookups, and that is the right shape rather than a shortcut: an
order records what was bought at the price it was bought for, and a line that
re-read today's catalogue would rewrite history every time the shop re-priced.

### The two frames disagreed about how many statuses there are
`1:1356` shows three badges and calls the last one «مكتمل»; `1:1480` draws a
five-stage tracker and calls it «تم التوصيل». One `OrderStatus` with five values
serves both, and `delivered` carries **two strings** — the short one for a badge,
the long one for the tracker. Declared in order, so `index` *is* the progress and
the tracker (next batch) needs no positions of its own.

**Status never advances.** A new order is `processing` and stays there; a backend
moves an order along, and a timer that "shipped" it after a minute would be
inventing server behaviour.

### Notes
- `Order` grew from three fields to eight. Its old comment said it "does not
  repeat what the draft holds" — true while nothing outlived the draft, and
  wrong the moment something did: the cart is emptied moments later and the
  draft dies with the flow.
- The card is **not tappable** yet. The details route arrives in batch 2, and
  tapping into a route that does not exist is worse than a card that does not
  respond. A test pins it.
- `ordersCount` is an ICU plural with `=1`, `=2`, `few` and `many` — Arabic has a
  dual and two plural bands, and «طلبان» is not something a ternary can produce.
- `ProductThumbnail`, extracted last batch, has its third caller.
- The DI drift guard fired on cue for `OrdersBloc`, as it did for `CheckoutBloc`
  and `OrderRepository` before it.
- **`PlaceholderTab` is now unused in `lib/`.** Left in place — deleting it is
  its own decision, and it is a useful scaffold for the next unbuilt screen.

Verified: `flutter analyze` clean, **671 tests passing**. A router test buys and
then opens the history through the real router and one shared repository, and
finds the order it just placed at the top.

## Order details (2026-08-29, `1:1480`)

Batch 2 of two, and the end of the orders feature. Read-only throughout: `Order`
already carried `status`, `items`, `address` and the recipient from batch 1, so
nothing new about the data itself.

### The tracker derives itself from the enum
`OrderStatus` is declared in the order the stages happen, so `index` **is** the
progress and `OrderStatusTracker` carries no positions of its own — behind,
current, ahead, in one comparison. The same three-appearance reading as
`CheckoutStepIndicator`, deliberately **not** the same widget: that one is
horizontal, three stations wide, unlabelled and lives inside a flow the shopper
is walking. Generalising it would have coupled two things that only resemble
each other.

Its polarity is drawn from `1:1480` directly — done stages are `primaryText`,
the current one accent and larger, the rest `subtle`. A test compares all five
against the frame, and swapping the passed colour fails it.

### Fetching, not reading the list
`OrderDetailBloc` asks `orderByNumber`. The address form reads
`AddressListBloc` because it is always pushed as a child of the list; **an order
number can arrive from a link or a notification with no list loaded above it**,
which is why this one fetches and why `/orders/:number` is a plain nested
`GoRoute` rather than a `ShellRoute`. A router test opens it cold and asserts the
list is not in the tree.

**Three states, not four.** There is no empty: one order exists or it does not,
and "it does not" is a `NotFoundFailure` with a reason that an `Empty` state
would throw away.

### Two widgets left the review step
`OrderItemLine` and `OrderPriceBreakdown` were private to `review_step.dart`.
The second caller arrived, so they moved to
`features/orders/presentation/widgets/` — the same call `ProductThumbnail` got,
and the same reason: two copies of "how this app draws an ordered line" drift the
first time anything changes. Each caller passes its own thumbnail size (80x96
review, 96x144 details), and `tinted` picks between the review's filled card and
this frame's ruled block.

### Three deliberate departures from the frame
- **Shipping comes from the order**, not the frame's ٥٠ ر.س — the fourth
  different shipping figure in the file, and exactly what unifying `shippingFee`
  was for.
- **The payment-fee row is drawn.** `1:1480` omits it, as `1:1840` did, and both
  predate cash on delivery carrying a fee.
- **The address card uses `background`, not the frame's `#FFFFFF`.** Pure white
  is not in this warm palette and cannot be derived from it; on a bordered card
  the difference is invisible, and the palette stays closed.

### The recipient shown is the one typed at checkout
`Order` carries both `address.recipientName` and its own `recipientName`. The
card shows the order's, because the contact step is editable **precisely** so a
shopper can buy for someone else — showing the address book's would quietly undo
that. A test seeds the two differently and asserts which one appears.

### A URL assertion that was testing go_router, not this app
The tap test first asserted `currentConfiguration.uri.path`. `push` inside a
`StatefulShellRoute` leaves that on the branch's own path (`/orders`) while the
pushed page renders correctly — so the assertion was about the library. It
asserts what renders instead, including that the *other two* seeded orders are
absent, which is what "opens that order, not another" actually means.

Verified: `flutter analyze` clean, **694 tests passing**.

## SettingsCard (2026-08-30)

The recorded card debt, paid. **Four hand-rolled copies became one widget in
`core/widgets/`** — and three of them were byte-for-byte identical, down to the
comment: `_MenuCard` in the account screen, `_Card` in help, `_Card` in
notification preferences. The fourth, `_OptionCard` in the language screen,
differed only in its fill and the colour of its rules, so it is the `filled`
variant rather than a fifth thing.

Each was defensible alone; together they were a card that had stopped being one.
The same failure `12-flutter-design-system-guard` exists to prevent, in layout
instead of colour.

**The proof it changed no behaviour: the four screens' 87 existing tests passed
without a single edit.** That was the point of taking the whole scope rather
than the three identical copies — if a test had needed changing, that would have
been the signal that a refactor had quietly become a rewrite.

A note on what the old tests did *not* cover: collapsing the `filled` variant
into `outlined` breaks only the new `settings_card_test.dart`, not the language
screen's own test, which never asserted the card's fill. The card's appearance
is that widget's business now, and it is tested there.

## The first-launch language chooser will not be built (user, 2026-08-30)

`1:2304` exists in the file and stays unbuilt. Arabic is the default and the
language is switchable from the account section; asking before the shopper has
seen anything is friction in front of the app rather than a service.

Recorded in `progress.md` under **"Decisions taken, not tasks"**, a section
added for it — and the accepted guest-email gap moved there too, since it said
"accepted, not outstanding" while sitting under Not Started, which is where a
reader goes to find outstanding work.

Verified: `flutter analyze` clean, **701 tests passing**.

## Supabase merged (2026-08-30)

A teammate (omar.ismail) pushed `8ffd2ef` **straight to `master`** — no branch,
which is why a first look for one found nothing. It integrates Supabase as the
live backend: `lib/core/supabase/`, four `supabase_*_repository.dart` files, and
a `supabase/` stack of 13 tables with RLS on every one.

**His integration is compatible with the repository pattern as written.** It
touches no bloc and no screen. Rather than swapping registrations it scopes
them, which is cleaner than the swap this project had assumed:

```dart
@LazySingleton(as: OrderRepository, env: [Environment.test])   // the fake
@LazySingleton(as: OrderRepository, env: [Environment.dev])    // Supabase
```

Live now: auth, catalogue, addresses, orders. Still local `SharedPreferences`:
the cart, onboarding, locale, search history, notification preferences.

### The one real conflict, and why it was cheap
`SupabaseOrderRepository` was written against the `Order` that lived in
`checkout/` — three fields, one method — while this session had grown it to
eight fields with `OrderStatus` and moved the whole feature to
`features/orders/`. His file was ported: **every line of Supabase logic kept
verbatim** (the `place_order` RPC name, the payload shape, the method encodings,
`mapSupabaseError`, the pre-flight guards), with the mapping rewritten and
`orders()` / `orderByNumber()` added as plain PostgREST selects.

**His schema was ahead of his Dart**, which is what made this cheap: `orders`
already stores the status, the contact and the flattened address, and
`order_items` stores `product_name` and `unit_price`. Only the RPC's return
shape was behind. So reading an order back needed no new SQL, and `place`
needed one key.

### The status enums each lacked what the other had
| SQL | Dart |
|---|---|
| pending · confirmed · shipped · delivered · **cancelled** | pending · confirmed · **processing** · shipped · delivered |

`processing` is drawn in two frames; `cancelled` exists server-side and would
have failed to parse. Both sides gained the missing value. `cancelled` is **not**
on `OrderStatus.journey` — it is an outcome, not a stage, and a rail ending in it
would suggest every order does. The tracker walks `journey`, not `values`.

### Two migrations, not an edit
A migration that has run is history. `20260830090000` adds `processing` to the
enum; `20260830090100` replaces `place_order` to return the status it wrote.
They are separate files because `alter type … add value` cannot be used in the
same transaction that uses the new value. The second is his function with
exactly three lines changed — verified by diffing it against his original.

### `8ffd2ef` did not compile
Two pre-existing name collisions, in his files, unchanged by the merge:
- `supabase_auth_repository.dart` — gotrue exports `User` through
  `supabase_flutter`, shadowing this app's entity.
- `injection_test.dart` — injectable exports a `test` constant, shadowing
  `flutter_test`'s `test()`.

Both fixed with this codebase's own remedy, the one already used for
`hide Order` and `hide TextDirection`.

### The lock was re-opened (user approval)
`techContext.md` said **REST only**, and `08-flutter-baas-security-guard.md` was
not installed. The data source is now **Supabase + REST** — not exclusive, as
`CLAUDE.md` says for that axis — and **08 is installed**, written against this
project's actual policies rather than generically. The slot had been held empty
since 2026-08-18 for exactly this.

### What the merge did not resolve
- `supabase_bootstrap.dart` uses `anonKey`, deprecated in favour of
  `publishableKey`. One `info` from the analyzer, in his file, left alone: it is
  a working API and the rename is his call.
- `google_sign_in` is used, by `SupabaseAuthRepository.signInWithGoogle()`. An
  earlier note here said it was unused; that was written before reading that
  file.
- Nothing has been run against a live Supabase. The suite proves the mapping and
  the wiring, not the queries.

Verified: `flutter analyze` — 1 info, 0 errors. **710 tests passing.**

## Current focus

Startup flow is complete: Splash resolves both concerns, first launch shows the
three onboarding slides, everything after lands on Home. **Home is now public** —
guests browse freely and only `/checkout`, `/orders`, `/profile` require a
session.

## Onboarding (2026-08-19)

Built from Figma frames `22:78` / `22:104` / `22:52`, normalised onto `22:104`.

- `features/onboarding/` — repository (`shared_preferences`), `OnboardingBloc`
  (app-wide, independent of `AuthBloc` so signing out never replays it),
  `OnboardingSlide` (**one** reusable widget for all three pages),
  `OnboardingDots`, `OnboardingScreen` (`PageView`).
- `router/` — two-bloc guard. Splash holds while either concern is undecided;
  `OnboardingRequired` owns the app; a failed flag read lets the user **in**
  rather than trapping them; guests are gated only on `Routes.protectedPrefixes`,
  carrying the attempted path in `?from=` so sign-in returns to it.
- 9 ARB keys, extracted straight from the Figma nodes rather than retyped.

### Decisions
- `#635E54`-style off-palette colours all **derived**, never added: body text is
  `primaryText @ 0.80`, inactive dots `@ 0.23`. Palette still five colours.
- Theme's gold `FilledButton`, not the design's black one.
- Skip == finish. Skip sits at `AlignmentDirectional.topStart` — all three frames
  put it at the right edge of an Arabic screen, which is the *start* in RTL.
- **No artwork.** The design's photos are 286x512, below 1x for a 390pt slot.
  `OnboardingSlide.image` is null and a palette placeholder renders; passing a
  widget is the only change needed when real assets arrive.

### Known gap
`/checkout`, `/orders`, `/profile` are protected by the guard but have **no
`GoRoute` yet**. The gate is live and tested; the screens are not built.

## Previous focus

Splash screen shipped from the Figma frame `Splash` (`14:14`). Next screen is
whatever the user sends; the first **list-shaped** one still has to establish the
four-state pattern from `06-flutter-error-guard` §5 directly.

## Splash screen (2026-08-19)

`lib/features/splash/presentation/screens/splash_screen.dart` replaces the bare
spinner that used to live as `_SplashScreen` inside `app_router.dart`.

Decisions taken with the user:
- **`#635E54` derived, not added** — `primaryText.withValues(alpha: 0.68)`.
  Palette stays at five. ΔE 5.3 from the Figma value, accepted.
- **One font family only** — no Tajawal. `IBMPlexSansArabic-Light.ttf` (weight
  300) was bundled so the design's Light weight is matched inside the locked
  family. `pubspec.yaml` now declares weights 300/400/500/600/700.
- **`brandName` is never translated or transliterated** — "NOVA MODEST" is Latin
  in every locale, forced `TextDirection.ltr` with a `direction-fixed:` tag. It
  lives in the ARB (same value in both locales, `@description` says do not
  translate) so no literal sits in a widget.
  **Consequence: the design's Arabic brand transliteration «نوفا مودست» is not
  rendered.** Only the tagline is localized.
- **Spacing corrected against the design** — Figma has 8 between the wordmark and
  the Arabic name, then 24 to the dot. With the Arabic name gone, the dot uses
  24 on both sides so the separator stays centred. Asserted by a test.
- **`AuthBloc.minimumSessionCheckDuration` = 1200ms** — a floor, not a delay, so
  a fast local token read does not make the splash flash. It lives in the bloc
  because the router's redirect navigates the moment the bloc leaves
  `AuthInitial`, which a widget-side timer could not hold.

Two test-infrastructure fixes this surfaced, both in `test/helpers/pump_app.dart`:
1. The test surface is now pinned to 375x812. It defaulted to 800x600, so
   screenutil scaled `.sp` by 2.13 and every layout measurement was fictional.
2. `loadAppFonts()` loads the bundled faces. Without it `flutter_test` renders
   with a stand-in font whose every glyph is a square, so Arabic and English
   strings of similar length measured identically. Call it from `setUpAll` in any
   test that measures layout.

Verified: `flutter analyze` clean, **43 tests passing**. Rendered to PNG in both
locales and inspected; the preview scaffolding was removed afterwards rather than
committed, since `04-flutter-test-guard` says not to introduce golden testing
without asking.

## Previous focus

Design system is in place and enforced by the theme. Next screens must be built
from the tokens only — see "Design system rules" below.

## Previous focus

Project scaffolding is complete. `auth` is the reference feature — the file set
`pattern-scout` should point every future generator at.

## Last change

`/flutter-project-init` scaffolded the app against the Bloc + REST + multi-locale
lock. 32 authored Dart files plus 8 generated (build_runner reports 14 outputs;
the extra 6 are `.injectable.json` intermediates that are not written to source).

- **Shared:** `core/error/` (sealed `Failure` + `Result`), `core/network/`
  (`ApiClient` seam, `DioApiClient`, auth + logging interceptors, `NetworkModule`),
  `core/storage/` (`TokenStorage` over `flutter_secure_storage`),
  `core/theme/`, `core/widgets/failure_view.dart`, `core/di/injection.dart`
- **Shell:** `main.dart` (runZonedGuarded → `configureDependencies`), `app.dart`,
  `router/app_router.dart` + `routes.dart` with the auth redirect guard
- **Reference feature:** `lib/features/auth/` — `User`/`AuthSession` (freezed) →
  `AuthRemoteDataSource` → `AuthRepositoryImpl` → `AuthBloc` → `LoginScreen`
- **Placeholder:** a bare landing screen, so the guard has somewhere to redirect.
  (Since replaced: it grew into `lib/features/catalog/`.)
- **l10n:** `lib/l10n/app_ar.arb` (template) + `app_en.arb`, `l10n.yaml`
- **Tests:** 26 passing across repository, bloc and screen, including RTL

Verified: `dart run build_runner build` clean, `flutter analyze` → **No issues
found**, `flutter test` → **26 passed**.

## Next step

Build the first **list-shaped** screen with `/flutter-screen-gen`. It must
implement the four-state contract (loading / error / empty / data) from
`06-flutter-error-guard.md` §5 directly — `auth` is submit-shaped and has no
`Empty` state, so copying its state set would carry that gap forward.

Then run `/repo-discovery` to populate `.claude/cache/repo-map.json`, which is
still missing.

## Design system (2026-08-19)

`flutter_screenutil` 5.9.3, design baseline **375x812**, initialised in
`main.dart` above `App` so the theme and every token resolve inside the
`ScreenUtilInit` subtree.

- `core/theme/app_colors.dart` — five colours, **closed**: `background`
  `#FAF7F2`, `primaryText` `#1A1A1A`, `secondary` `#E8DFD3`, `accent` `#C6A75E`,
  `error` `#B5524A` (muted terracotta, carried over from the admin "cancelled"
  decision — the palette grows only by explicit decision like this one)
- `core/theme/app_dimensions.dart` — `AppSpacing` (`.h`), `AppRadius` (`.r`),
  `AppFontSize` (`.sp`), all **closed** scales
- `core/theme/app_theme.dart` — fully rewritten. `_seed` /
  `ColorScheme.fromSeed` removed; `ColorScheme`, `TextTheme` and every component
  theme read `AppColors` + the scales. Verified by
  `test/core/theme/app_theme_test.dart` (5 tests).
- Font **IBM Plex Sans Arabic**, bundled from `assets/fonts/` (4 weights, SIL
  OFL in `assets/fonts/OFL.txt`) rather than via `google_fonts` — a runtime
  download would show a fallback face on first launch and fail offline, which
  matters for an Arabic-primary app.

### Design system rules — binding on all new screens and widgets

Enforced by `.claude/rules/12-flutter-design-system-guard.md`, registered in
CLAUDE.md's read-on-demand table. It sits at 12, not in the 00–08 domain block,
because 08 is reserved for the BaaS rule `/platform-init` would reinstall.

1. No bare `Color(0x…)` and no raw spacing number in widget code. Only
   `AppColors` / `AppSpacing` / `AppRadius` / `AppFontSize`.
2. A colour not in the palette: derive with `.withValues(alpha: …)` from the
   nearest, or **stop and ask**. Never add one unilaterally.
3. A spacing not on the scale: use the nearest existing value. Never extend the
   shared class.
4. One-element-one-screen measurements go as a private constant in that widget's
   own file.

## Known gaps, deliberate

1. **No refresh-on-401.** `AuthInterceptor` attaches the token but does not
   refresh it; a 401 becomes `UnauthorizedFailure` and the guard sends the user
   to login. `/flutter-network-gen` owns the refresh flow (it needs a second
   interceptor-free `Dio` plus single-flight queueing).
2. **No certificate pinning.** Flagged, not added — `03-flutter-security-guard`
   does not require adding it unilaterally.
3. **No language switcher.** The system locale resolves against
   `supportedLocales`. When a switcher is added, the selected locale becomes
   bloc state, never a global (`11-flutter-l10n-guard` §8).
4. **Crash reporting not wired.** `main.dart` has both error hooks but they log
   to console. `/production-readiness-review` treats this as a release blocker.
5. **No custom font.** Arabic renders via platform fallback. Verify Arabic
   coverage before adopting any brand font.
6. **`API_BASE_URL` is a placeholder** (`https://api.example.com`). Supply the
   real value with `--dart-define`.
7. **No dark theme — confirmed intentional.** The MVP is light-mode only
   (user, 2026-08-19). `themeMode` is pinned to `ThemeMode.light` and
   `AppTheme.dark` is gone. If dark mode is wanted later it is an independent
   palette decision, never derived from the light palette.
8. **Existing `auth` widgets still use raw values** (`SizedBox(height: 16)`,
   `EdgeInsetsDirectional.all(24)` in `login_form.dart` / `login_screen.dart`).
   Left untouched under `09-minimal-changes`; the token rule binds new code.
   Migrate as its own task if wanted.
