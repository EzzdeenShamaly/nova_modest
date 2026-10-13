# Progress

**Last Updated:** 2026-10-12

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

## Release blockers — settle before the first upload, not after

Not debts. A debt can wait; each of these either stops the upload or cannot be
undone once it has happened. Found 2026-09-20 while preparing the Android run.

- **SETTLED 2026-09-20 — the application id is `com.novamodest.store`.**
  It was `com.example.nova_modest`, which Play rejects outright, and an
  application id **cannot be changed after the first publish**. The owner chose
  a reversed product name rather than a domain — no domain is owned, and an id
  does not require one. Checked before the change: Play answers 404 for that
  id, so nothing is published under it. A 404 does not reserve it; the first
  upload does.

  Changed in one commit: `namespace` and `applicationId` in
  `android/app/build.gradle.kts` (and the scaffold TODO that asked for it),
  the Kotlin package **path on disk** plus the `package` line in
  `MainActivity.kt`, and `PRODUCT_BUNDLE_IDENTIFIER` for both the iOS app and
  its test bundle. The three `AndroidManifest.xml` files needed nothing: they
  carry no `package` attribute, because the namespace comes from Gradle.
  Verified by `flutter clean`, a debug build and a fresh install on the
  emulator, which launched to `/onboarding` with no error. The old app was
  uninstalled first — a new id is a different app, so it would otherwise have
  sat there beside it, and its session and cart are gone with it.

  **Still on `com.example`, deliberately untouched: the desktop targets.**
  `linux/CMakeLists.txt` (`APPLICATION_ID`), `macos/Runner/Configs/AppInfo.xcconfig`
  (bundle id and copyright) and `windows/runner/Runner.rc` (company and
  copyright). They were outside what was asked, this is a mobile app, and none
  of them blocks a Play or App Store upload. They carry the same placeholder
  and should be settled if a desktop build is ever shipped.

- **BLOCKER 7 — SETTLED 2026-10-12. The session check always answers now, and
  answers in bounded time.**

  Two earlier accounts of this were wrong; the history keeps them. What it
  actually was: `currentUser()` did `return _readCurrentUser();` **inside** its
  own `try`, and an `async` function awaits a returned future *outside* the try
  — so the `catch` never saw it. With the host unreachable the `profiles` read
  threw, the error escaped as an uncaught zone error, `AuthBloc` emitted
  nothing, and the router held on the splash for ever. Five sites did this; a
  scan of `lib/` found no sixth.

  **The fix, in three parts:**
  1. `await` at all five.
  2. An **8-second** bound on the profile read, and on the avatar signing that
     follows it on the same path. Not on `initializeSupabase()`, which was
     measured and never blocks on the network.
  3. On a **network failure only**, the shopper stays signed in with what the
     token itself carries — id, email, and a name derived from the address —
     and every screen shows its own error. A refusal does not fall back: a
     policy refusal signs her out, a server error is reported.

  **A library quirk found on the way, which the fix depends on.** An RLS
  refusal through `.maybeSingle()` does **not** arrive as `42501`. postgrest
  builds that exception, hands it to `_handleMaybeSingleError`, which rethrows
  it — into the `catch (_)` wrapped around that same block, which replaces it
  with a generic exception carrying only the HTTP status
  (`postgrest_builder.dart:553-571`). So every policy refusal on a single-row
  read arrived as a `ServerFailure` and **no shopper was ever signed out by
  one**. `mapSupabaseError` now reads a bare `401`/`403` as an authorisation
  failure, with its own tests.

  **Measured on a device, both ways:**
  - Against a host that does not exist: opens in **10.6 s** (the 8-second bound
    plus the DNS attempt), zero uncaught errors, and she is **signed in** — the
    account screen shows the email-derived name, her initial instead of the
    photograph, and no phone line.
  - Against the live project: opens in **6.3 s** with her real name, phone and
    photograph. Zero uncaught errors, zero retries. The fallback does not touch
    the healthy path.

  Seven mutations, seven caught — including the one the owner called the spine:
  widening the fallback to any failure breaks the policy-refusal test. The
  missing `await` is pinned by the **refusal** tests rather than the network
  one, because once a network failure falls back, no error travels that path.

  **Two things deliberately left, both under Not Started:** nothing re-reads the
  profile after startup, and the personal-information form opened while thin is
  pre-filled from the thin identity.

- **BLOCKER 5 — the in-app half is SETTLED, proven live 2026-10-12. Only the
  web URL remains.** The dashboard shipped `delete-account` as an **Edge Function**
  rather than the SQL function sketched below (same order and rules: avatar
  first, then the user over the Admin API; admins refused; identity from the
  JWT alone). The storefront calls it from the last row of the account menu,
  behind a dialog that states what goes and what stays **before** the press,
  and on success clears the device's session without relying on the server —
  `signOut(local)` inside a catch for the in-memory half, then the keystore
  cleared explicitly. A 401 is an expired session and signs her out, as every
  lost session does; the other six codes keep their code and reach her in
  Arabic. Eleven mutations, eleven caught. **Still open: the web page where
  deletion can be requested without the app** — it pairs with the privacy
  policy page (blocker 4).

  **Run on the device, 2026-10-12, against the production project.** A throwaway
  account signed in, a photograph uploaded first so the avatar branch was really
  taken, then deletion from the account menu. The app wrote two log lines and
  nothing else — `Signing out user with scope: local`, then the redirect to
  `/login` — with no error, no exception and no refusal code, and showed the
  sign-in screen with no message.

  **The verdict came from the dashboard, not from the device, and it had to.**
  Success and a 401 both end on the sign-in screen, and the log cannot separate
  them either: the success path logs that line from `clearLocalSession()` inside
  `deleteAccount`, the 401 path logs the identical line from `logout()`, because
  gotrue's `signOut` defaults to `SignOutScope.local`
  (`gotrue_client.dart:1075`) — not the global scope this repo's comments had
  assumed. The owner then read the dashboard: **the user is absent from
  Authentication** (five remain, none of them it), and **`avatars` holds exactly
  one folder**, the demo shopper's, with her photograph from 21 September. So
  the avatar and the user went together, the function's contract held, and the
  one state its ordering makes impossible — user gone, avatar left — did not
  appear. A refusal would have left both.

  Three ways of measuring whether the request reached the server were tried
  first and **all three failed**, so none was used: the kernel's per-uid byte
  counters bucket at two hours (`bucketDuration=7200`) and read identically
  before and after a whole photo upload; `supabase.functions` logs its request
  at `finest`, below the `Level.INFO` floor supabase_flutter prints
  (`supabase.dart:113`); and a host-side TCP connection to the project already
  existed and is reused by keep-alive. What does separate cleanly, and was not
  needed: a lost request shows «لا يوجد اتصال بالإنترنت.» and keeps her on the
  account screen.

  Original record follows.

  **BLOCKER 5, found 2026-09-21 — there is no way to delete an account.**
  Google Play requires that any app which creates accounts offers deletion
  **inside the app** *and* a **web URL** where deletion can be requested without
  installing it. "Email us" does not satisfy either half, so the current terms
  draft cannot ship as written. The web URL pairs with the privacy policy page
  (blocker 4) — same GitHub Pages site, second page.

  **This is a feature, not a clause.** The storefront cannot delete an account
  by itself: `auth.users` is not writable from a client session, so the row that
  everything else hangs off can only go through a `security definer` function in
  the database. Migrations are the dashboard repository's to write; what this
  repo needs from it is recorded below, and the app side (a confirm dialog that
  names what goes and what survives, the RPC call, then a local sign-out and
  cart clear) is ours.

  **What the function must do** — the shape to hand the dashboard agent:
  - `public.delete_my_account()`, `security definer`, `set search_path = public`,
    **no arguments**. It acts on `auth.uid()` and nothing else; an id taken from
    the caller would let one shopper delete another.
  - Raise if `auth.uid()` is null rather than deleting nothing silently.
  - **Delete the avatar object first**: `storage.objects` where
    `bucket_id = 'avatars'` and `(storage.foldername(name))[1] = auth.uid()::text`.
    The bucket grants INSERT, SELECT and UPDATE to `authenticated` and **no
    DELETE** (measured 2026-09-20), so a deleted account otherwise leaves its
    photograph behind with nothing able to remove it.
  - Then `delete from auth.users where id = auth.uid()`, which cascades to
    `profiles` and `user_addresses`. **`orders.user_id` is ON DELETE SET NULL**,
    so the orders survive with their snapshot of name, phone and address — the
    shop keeps its records, and that is worth saying plainly in the terms.
  - `grant execute on function public.delete_my_account() to authenticated`
    only — never `anon`.
  - Confirm on the way back: whether any table other than `profiles`,
    `user_addresses` and `orders` references `auth.users`, and that
    `order_items` is untouched because it hangs off `orders`.

- **BLOCKER 6, found 2026-09-21 — the Google sign-in button cannot work in any
  build this repo produces.** It is the first control on the first screen, it
  looks live, and a tap ends in a generic server-error message. Three layers are
  missing, and the first fires before the other two matter:
  1. `GOOGLE_WEB_CLIENT_ID` is read by `SupabaseAuthRepository` and **defined
     nowhere** — not in `config/prod.json`, not in `config/dev.json`, not in the
     committed example. `String.fromEnvironment` yields `''`, and the method
     returns `ServerFailure` before the plugin is touched.
  2. No `google-services.json` and no Google Services Gradle plugin on Android,
     and no scheme registered in the manifest.
  3. The Google provider in Supabase Auth, and the signing certificate's SHA-1
     in Google Cloud — neither verifiable from here, and the SHA-1 **cannot be
     settled before blocker 2**, because it is the upload key's.

  By the standing rule that a control either works or goes, this is a decision
  for the owner: remove the button for the first release, or finish all three
  layers after the keystore exists. **The terms draft says nothing about Google
  sign-in** until it is settled.

- **The release build is signed with the debug keystore.**
  `android/app/build.gradle.kts` still carries Flutter's scaffold TODO —
  `signingConfig = signingConfigs.getByName("debug")` in the `release` block.
  A debug-signed artifact cannot be published, and the upload key, once chosen,
  is equally permanent. Adjacent to the id, and found with it.

- **Blocker 3's keystore session, measured on a device 2026-09-21.** Until
  that day the secure session had only ever been proven by unit tests. On the
  emulator, a **new build installed over the old app** (same application id, so
  app data survives) launched straight into the signed-in account: the profile
  loaded, `/profile` was reachable, and no sign-in code was needed. That is the
  migration and the keystore read working on a real Android keystore rather
  than a mock — the first time either has been measured off a test.

- **PARTLY SETTLED 2026-09-20 — the support address is real; the privacy policy
  is not written.** Play requires **a real support email** on the listing and
  **a privacy policy at a public URL**; both are mandatory. The email is now
  `ezzdeenshamali@gmail.com` (owner, 2026-09-20), in `help_screen.dart`.

  **The support phone number was removed, not replaced** (owner): the
  placeholder `+966 50 000 0000` is gone and no number is shown. An invented
  number on a support screen is worse than none, because a shopper dials it.

  **Still open:** the privacy policy, to be published on GitHub Pages, and the
  terms and conditions text (`termsPlaceholder`), which are *not* mandatory for
  Play. The policy must describe what the app actually collects — email, name,
  phone, address — why, that it is stored in Supabase, and who can read it.

## Done

- **A thin identity can no longer overwrite a real profile** (2026-10-12).
  Raised as a debt and overruled by the owner the same day: *not* a debt but a
  data-loss defect, because the flaky DNS proved a thin identity arrives without
  anyone switching off a network, and its damage is the only part that survives
  closing the app.

  The form was pre-filled from the session-only user — derived name, empty phone
  — and `String? phone` cannot carry "leave it alone" as well as "clear it", so
  editing the name and saving wrote `phone: null` over a real number. Clearing
  the number *is* a real edit (`personal_info_screen_test.dart:159`), so the
  sentinel route would have cost the domain contract, the repository, the fake
  and the bloc, and broken that edit.

  What shipped is the smallest thing that prevents the write: `User.fromSession`
  — set only by `_userFromSession`, excluded from JSON in both directions — and
  one branch in `PersonalInfoScreen` that shows an explanation instead of the
  form. No field to type in, no save bar, no avatar control. Measured: the only
  write that could lose data is `profiles.update({display_name, phone})`
  (`supabase_auth_repository.dart:151`); the avatar write touches `avatar_url`
  alone and addresses never read from `User`.

  The test failed first on the real defect, naming it:
  `_MockProfileEditBloc.add(ProfileEditSubmitted(سارة أحمد, null))`. Three
  mutations, three caught — the guard removed, the guard inverted so it locks a
  *real* profile, and the flag not set by the fallback (which only the
  session-check test can see, since the screen tests build the thin user
  themselves).

  **One string depends on an unbuilt decision:** `personalInfoUnavailable` tells
  her to reopen the app, which is literally what is required today because
  nothing re-reads the profile until relaunch. It needs rewording the day the
  resume hook lands.

  **Seen live the same day, on the production project, with nothing switched
  off** (2026-10-12, during the deletion run's setup): the first launch showed
  the thin identity — `as92+shopper` and her initial, no phone — because the
  `profiles` read exceeded the 8-second bound on a degraded link. A clean
  restart read everything. So this guard was not precautionary: without it the
  form that opens in that state was one edit away from erasing a real number,
  and the state arrives on an ordinary flaky connection rather than an airplane
  mode nobody switches on.

- **Checkout's contact prefill reads the same thin identity, and that is fine**
  (measured 2026-10-12). `checkout_bloc.dart:71` fills the contact phone from
  `user?.phone ?? ''`, so while thin it opens empty — but the field is visible,
  validated and hers to type, and `place_order` refuses an empty contact. Loss
  needs a silent write over existing data, and there is none here.

- **The keystore session survived 21 days, unplanned** (2026-09-21 → 2026-10-12).
  `SecureSessionStorage` was built and unit-tested on 2026-09-20 and proven on a
  device the next day; nobody set out to test how long it lasts. Three weeks
  later — across an app reinstall and an emulator shut down in between — the
  same shopper was still signed in, with her photograph drawn from a freshly
  signed link. Refresh-token rotation, keystore persistence and the migration
  all held with nothing touching them. An accidental test, and the kind that
  cannot be written.

- **The voice test guarded twenty words and looked as though it guarded the
  file** (found and closed 2026-09-21). `orderErrorTechnical` said «وإذا تكرر
  **تواصل** معنا» — masculine — and passed, because «تواصل» was not on the
  hand-kept list. The test now also **derives** its watch-list from the app's
  own copy: every feminine imperative `app_ar.arb` speaks (a word ending in «ي»
  that opens a clause and takes a complement, never one carrying «ال») becomes a
  guarded masculine form, so a new «جرّبي» guards «جرّب» without anyone editing
  the test. Proven on the unfixed file first — it failed naming exactly that
  string, with no false alarms — then the word was made feminine.

  The ambiguous uses («حدث» as past tense, «تسوق» as a noun) moved from a
  **global** exclusion to an allow-list **keyed by string**: each covers one
  sentence someone read. Checked both ways: removing an entry fails, and
  «تسوّق الآن» as a command fails even though «تسوق» is allowed in
  `onboardingBody3` — which the old global exclusion would have let through.

  **The limit, stated:** telling an imperative from the same letters as a noun
  or a past tense needs the sentence, which a pattern cannot parse; and a
  masculine imperative whose feminine form the app never uses is invisible to
  the derived check. The original list stays for that residue.

- **SETTLED 2026-09-21 — the disc is no longer blank while a picture loads.**
  Found on the emulator, not by a test: between `avatarUrl` becoming non-null
  and the first decoded frame, `AvatarCircle` showed neither the letter nor the
  picture. `Image` hands `loadingBuilder` a null `loadingProgress` until the
  first chunk arrives, and reading that null as "loaded" returns a `RawImage`
  holding no image. Fixed by moving the decision to `frameBuilder`, whose
  `frame == null` is the honest "nothing to paint yet"; `errorBuilder` stays as
  it was.

- **Two kinds of "no picture" — failure and loading — and a broken provider
  only shows the first.** This is why the blank disc above shipped with
  33 tests around it. In `flutter_test` every network image fails immediately,
  so a test that supplies a bad URL lands in `errorBuilder`, finds the
  fallback, and proves nothing about the window before the bytes arrive.
  Reproducing that window needs a provider that is **slow**, not broken:
  `debugNetworkImageHttpClientProvider` returning a client whose response body
  is a stream held open (`test/core/widgets/avatar_circle_loading_test.dart`).
  **Every network image added to this app from here on is tested both ways.**

  Two mechanics worth keeping, both learned the hard way on 2026-09-21:
  `debugNetworkImageHttpClientProvider` must be cleared **inside** the test
  body, because the framework checks painting's debug variables the moment the
  body returns and before any `tearDown`; and a real decode cannot be driven to
  completion under the fake clock at all — the codec is an engine call whose
  continuation is posted to a zone that never runs — so the "picture replaces
  the letter" half is pinned at the builder, with the emulator run as its
  end-to-end evidence.

- **Profile picture (task أ, 2026-09-20)** — a shopper can set her own photo.
  `AvatarCircle` (`core/widgets/`) draws it in the account header and on the
  personal-information screen, with the first letter of her name standing in
  whenever there is no picture *or* the link cannot be drawn. The picture lives
  at `<uid>/avatar` in the private `avatars` bucket, written with **upsert**,
  and `profiles.avatar_url` holds that **path**, never a link. The repository
  signs it for one hour on every profile read — one link per read, not per
  widget — and a signature that cannot be minted leaves `avatarUrl` null, which
  falls through to the letter.

  Measured live on 2026-09-20 rather than assumed: `avatars` is private,
  2 MiB, `png/jpeg/webp`, and its policies are INSERT, SELECT and UPDATE for
  `authenticated`, each `(storage.foldername(name))[1] = auth.uid()`, with
  **no DELETE** — which is why the design is a fixed path plus upsert, and why
  `AuthRepository` has no `removeAvatar`. The format is decided from the
  **bytes** (`core/media/image_bytes.dart`), never from a file name, and an
  oversized or unsupported picture is refused in Arabic before anything is
  sent.

  33 new tests, all of which were mutation-checked: ten deliberate breakages
  (upsert off, path segments swapped, content type dropped, TTL shortened,
  signing failure rethrown, `http` passthrough removed, the WebP tag
  unchecked, cancel treated as a failure, the image `errorBuilder` removed,
  the letter left in semantics) were each caught by the test that claims to
  pin them. An eleventh survived — removing `container: true` from the avatar's
  `Semantics` changed nothing — which showed the line was redundant once the
  fallback letter was excluded from semantics. It was deleted rather than kept
  as untested ceremony with a comment claiming it was load-bearing.

- **`image_picker` on Android is not `image_picker` on the web** — recorded so
  the dashboard's web experience is not carried over by analogy. On Android
  `maxWidth`/`maxHeight`/`imageQuality` are applied **natively**, before the
  bytes reach Dart, so 512x512 at quality 85 is a real resize and not a hint;
  on web those arguments are ignored and the full-size file arrives. Android
  alone can **destroy the activity** while the gallery is open, which loses the
  result unless `retrieveLostData` is called — `PersonalInfoScreen` dispatches
  `ProfileAvatarRecoveryRequested` on open for exactly that. And Android's
  system Photo Picker is opt-in below Android 15 through
  `ImagePickerAndroid.useAndroidPhotoPicker`; with it, no storage permission is
  needed at any level this app supports (minSdk 24 falls back to
  `ACTION_OPEN_DOCUMENT`, which also needs none), so `AndroidManifest.xml`
  stays as it is. `image_picker_android` and `image_picker_platform_interface`
  are declared in `pubspec.yaml` because that opt-in requires reaching the
  implementation directly; both were already in the tree as `image_picker`'s
  own dependencies.

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

- **Probe accounts are accumulating in production `auth.users`** (seen
  2026-10-12 in the dashboard by the owner). `as92+deltest-1789983178@...`
  survives from the dashboard side's `probe_delete_account.py`. The suffix is a
  Unix timestamp and decodes to **2026-09-21 09:32:58 UTC** — the same day the
  admin repo records that *"email OTP hit a daily send limit on 2026-09-21, so
  probe sign-ins could not always get a code"*.

  So this is not a forgetful script: `delete-account` takes its identity **from
  the caller's JWT alone**, deliberately, so a probe run that cannot obtain a
  code never gets a session and **cannot delete the account it just created by
  any path the function offers**. Any run that fails before sign-in strands one,
  however carefully the probe is written. The durable fix is a cleanup that does
  not need a session — delete by user id over the Admin API in a `finally`,
  where `service_role` already lives — and it belongs to the dashboard side:
  the probe is not in either repository on this machine, and the admin repo is
  read-only here.

  Whether the stranded account is safe to delete could **not** be checked from
  here: `claude_reader` returned 0 for `auth.users`, `profiles` *and* `orders`,
  and a control proved that is blindness behind RLS, not emptiness. What the
  schema guarantees regardless: `orders.user_id` is ON DELETE SET NULL, so
  deleting it would unlink any order rather than destroy it — the same end state
  as any shopper deleting her own account.

- **BLOCKER 8 — 2026-10-13: two and a half of the three are built; one half
  waits on a decision** (found by sweep 2026-10-12, scoped by the owner the same
  day).

  **Built:** the guest button is never disabled; account deletion has a
  twenty-second ceiling, an abstaining message and a spinner on its own row
  instead of over the tab; and all three product images carry a `frameBuilder`.
  Every assertion failed first on the old code — the guest button came back
  null, the menu came back empty, the deletion hung for the full 45-second test
  timeout — and eight mutations were all caught (`857c4e2`).

  **Open: the ceiling on `requestEmailCode`.** Two things found while writing
  its test changed the question the owner asked.

  1. `requestEmailCode` **always returns `Ok`**, deliberately — a distinct
     answer for an unknown address would be an account-enumeration oracle
     (`supabase_auth_repository.dart:132`). So a ceiling there has a third
     option the plan did not consider: give up waiting and move her to the
     code-entry screen, where *resend* already exists, rather than report
     anything. That keeps one code path and the anti-enumeration intent; its
     cost is that she is asked for a code that may never arrive.
  2. The loopback test cannot reach the network at all: `signInWithOtp` calls
     `_generatePKCECodeChallenge()` **before** the request, and a bare
     `SupabaseClient` has no async storage, so it throws an `AssertionError` in
     3 ms with zero requests sent. Testing this needs a client given a stub
     `pkceAsyncStorage`.

  The side effect the owner asked about is real: GoTrue sends the email before
  it answers, so a lost reply means the code may well be in her inbox while the
  app says the request failed.

  The rest of the original scoping follows.

  The sweep below found that **two timeouts exist in the whole app and both are
  on the session check**. The owner's criterion for what that makes a blocker
  rather than a debt is one question: *does she have a way out other than
  closing the app?* Where back still works she is not trapped, so it is a debt.
  Three places fail that test:

  1. **`requestEmailCode` — a ceiling, and «المتابعة كزائر» must never be
     disabled.** While the request is in flight `auth_method_screen.dart:159`
     disables the guest button along with the form, so a hang here closes the
     *exit* as well as the entrance: she can neither sign in nor browse.
     Locking the only way out is worse than locking the way in.
  2. **`deleteAccount` — a ceiling, and it must stop replacing the whole tab.**
     `profile_screen.dart:56-59` swaps the entire account menu for a centred
     spinner, so a hang takes her orders, her addresses and her sign-out with
     it. A spinner on the row itself, or in the dialog, keeps the rest
     reachable.
  3. **Product images need `frameBuilder`, as `AvatarCircle` already has.** The
     three `Image.network` call sites carry an `errorBuilder` only, so "nothing
     has arrived yet" paints *nothing*. This one is not really about hanging:
     the catalogue is images, and a storefront with white gaps is something a
     Play reviewer rejects before ever thinking about the network. The pattern
     exists in `core/widgets/avatar_circle.dart:176` — copy it.

- **DEBT — every other network read is unbounded, but she can always leave**
  (sweep 2026-10-12; recorded by the owner's instruction as the documentation of
  record). Only the two session-check ceilings exist
  (`supabase_auth_repository.dart:310`, `:374`).

  | Screen | Read | Ceiling | While it hangs |
  |---|---|---|---|
  | Splash / router | `currentUser()` → `profiles` | **8 s** | falls back to the session identity, the app opens — the only guarded one |
  | Splash / router | `withSignedAvatar()` → signing | **8 s** | returns without a picture, her initial instead |
  | Home | `categories()` + `featuredProducts()` | none | a spinner for ever, no error and no retry. **Measured 2026-10-12: 4+ minutes, and it survived switching tabs and coming back** |
  | Product list | `productsInCategory()` | none | spinner; back works |
  | Search | `searchProducts()` / `trendingSearches()` | none | spinner; back works |
  | Product detail | `productById()` | none | spinner; back works |
  | Orders / order detail | `orders()` / `orderByNumber()` | none | spinner; back works |
  | Addresses (and the checkout step) | `addresses()` | none | spinner; back works |
  | Address form | `save()` | none | fields locked, button spinning; back offers the discard dialog |
  | Personal information | `updateProfile()` | none | same; what she typed is kept and back works |
  | Personal information | `uploadAvatar()` | none | the disc dims under a spinner and **the form stays usable** — the kindest of them |
  | Checkout | `place()` → `place_order` | none | button spinning; `droppable` stops a second tap; back walks the steps |
  | Sign in | `requestEmailCode()` | none | field and button locked — **and the guest button with them** → blocker 8 |
  | Code entry | `verifyEmailCode()` | none | field, submit and resend all locked; back works |
  | Delete account | `deleteAccount()` | none | **the whole account menu is replaced by a spinner** → blocker 8 |
  | Sign out | `logout()` | none | **never visible** — gotrue clears locally and announces `signedOut` *before* the server call, so the router moves her at once |
  | Product images | `Image.network` ×3 | none | **a white gap with no stand-in** — `errorBuilder` only → blocker 8 |
  | Account picture | `AvatarCircle` | none | her initial — the only one already handled |

- **RISK, not an observation — a second order is reachable while the first is in
  flight** (2026-10-12, recorded at the owner's instruction without measuring
  it). `CheckoutConfirmed` is `droppable()`, so tapping twice cannot place two
  orders. But `place()` has no ceiling, and leaving checkout and re-entering
  builds a **new** `CheckoutBloc`, whose `droppable` knows nothing about the
  call still outstanding on the old one. `place_order` carries no idempotency
  key. Nobody has seen this happen; it is written down so that it is not
  rediscovered as a surprise.

- **Probe accounts are accumulating in production `auth.users`** (seen
  2026-10-12 in the dashboard by the owner). `as92+deltest-1789983178@...`
  survives from the dashboard side's `probe_delete_account.py`. The suffix is a
  Unix timestamp and decodes to **2026-09-21 09:32:58 UTC** — the same day the
  admin repo records that *"email OTP hit a daily send limit on 2026-09-21, so
  probe sign-ins could not always get a code"*.

  So this is not a forgetful script: `delete-account` takes its identity **from
  the caller's JWT alone**, deliberately, so a probe run that cannot obtain a
  code never gets a session and **cannot delete the account it just created by
  any path the function offers**. Any run that fails before sign-in strands one,
  however carefully the probe is written. The durable fix is a cleanup that does
  not need a session — delete by user id over the Admin API in a `finally`,
  where `service_role` already lives — and it belongs to the dashboard side:
  the probe is not in either repository on this machine, and the admin repo is
  read-only here.

  Whether the stranded account is safe to delete could **not** be checked from
  here: `claude_reader` returned 0 for `auth.users`, `profiles` *and* `orders`,
  and a control proved that is blindness behind RLS, not emptiness. What the
  schema guarantees regardless: `orders.user_id` is ON DELETE SET NULL, so
  deleting it would unlink any order rather than destroy it — the same end state
  as any shopper deleting her own account.

- **CANDIDATE BLOCKER — the session check is bounded and nothing else is**
  (2026-10-12, measured on the device during the deletion run's setup). The home
  screen's product read spun for **more than four minutes** with no error, no
  retry and no affordance, against a link whose 1500-byte packets were being
  dropped entirely (MTU black hole on the emulator's path; Windows reached the
  same host in 9 ms and a full HTTPS request answered in 2.05 s). This is
  blocker 7's shape in a place it was never checked: `_profileReadTimeout`
  guards the session check, and **no other network read in the app carries a
  ceiling**. On a link like that the shop does not fail, it stalls — which reads
  as "slow" rather than "broken", and the shopper is given nothing to press.

  **Not built, by the owner's instruction.** What he asked for after the live
  run: a sweep of *every* network read in the app — bounded or not, and what the
  shopper sees while it hangs — and the decision then on whether this travels
  with the two leftovers above or becomes a blocker of its own.

- **A thin identity never fills itself in** (2026-10-12). `AuthCheckRequested`
  is dispatched **once**, from `app.dart:46`, and nothing re-reads the profile
  afterwards — not on resume, not when a later request succeeds. So a shopper
  who launched on a dead network keeps the email-derived name and no photograph
  until she closes and reopens the app. The smallest thing that would fix it is
  a lifecycle hook: re-dispatch `AuthCheckRequested` on
  `AppLifecycleState.resumed`. The most precise is to listen for the SDK's own
  `AuthChangeEvent.tokenRefreshed`, which fires exactly when the network returns
  and the token is good — at the cost of `AuthBloc` gaining a subscription it
  does not have today. **Not built: the owner decides.**

- **DEBT — no central handler for an expired session in the presentation
  layer** (observed 2026-09-21; recorded, not built, by the owner's decision).
  The automatic sign-out lives in `SupabaseAuthRepository.currentUser()` at the
  session check, and account deletion does it explicitly
  (`AuthLogoutRequested`). **Two places are not a pattern yet. The third place
  that needs it is the trigger to build one listener** — on `AuthBloc` or at the
  app root — and move all three onto it, rather than a third hand-written copy.

- **The country field is free text while the terms say Saudi Arabia only**
  (2026-09-21). `Address.country` is a plain `TextFormField`, so a shopper can
  type anything and the order is accepted; the terms about to ship restrict
  delivery to the Kingdom. One of the two has to move: either the field becomes
  a fixed value or a short list in the form, or `place_order` refuses an address
  outside the allowed set — the second is the real boundary, the first is only
  the courtesy (`08-flutter-baas-security-guard` §1). Until then the app and its
  own terms disagree.

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

- **Working-method note (user, 2026-09-19), recorded in the user's words:**
  "Our decision was *no crop, four images*, and you cropped and came out with
  seven. The result is better and I accept it — but you went against an
  explicit decision without coming back to ask." **The rule:** when a decision
  of the owner's would lose a better result, come back with one line *before*
  executing; delivering the deviation and explaining it afterwards does not
  count. (The agent's reading of the transcript differed and was put once; the
  user reaffirmed their account, which settles the record.)

- **p3 keeps its generated image — decided, not pending** (user, 2026-09-19).
  No category change to fit a photo, and no search for a shawl photo. The
  catalogue-photo work is closed.

- **The home banner is a bundled asset, not content** (user, 2026-09-20).
  Read before deciding: the banner's copy is `homeHeroTagline`, an ARB string
  compiled into the app, and `HomeHeroBanner.image` is a widget parameter the
  home screen simply never passed — hence the empty hanger. Production has no
  banners table and no column named like one; its fourteen tables were read on
  2026-09-20. So a database-driven picture would have been editable while the
  words over it were not. `assets/images/home/hero.jpg` is one of the catalogue
  photographs, already cropped and resized (195 KB at 1165x1800, the widest the
  banner is drawn). **Changing the banner is a release, like changing its
  words.** The alternatives, if that ever stops being acceptable: a banners
  table with a dashboard screen, or drawing a `products.is_featured` row, which
  needs no new table.

- **A payment receipt is deferred, and why** (user, 2026-09-20). Cash on
  delivery is the only method that can place an order — `place_order` refuses
  `card` with `payment_not_available` — so **no money changes hands before
  delivery and there is no receipt to upload.** Building one now would be a
  feature with no payer.

  It becomes real the day a bank transfer is offered, and then it is a whole
  feature rather than a field: a column on `orders`, a storage bucket with its
  policies, an upload screen in the storefront and a review screen in the
  dashboard. Recorded so the deferral is read as a consequence of having one
  payment method, not as an oversight.

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

- **THE LIVE END-TO-END RUN IS CLOSED — 2026-09-19. Its done-condition is met:**
  a real order was placed from the storefront by a signed-in customer who is
  not an admin, it appeared in the dashboard, and its status was changed from
  there. The first time the storefront and the dashboard worked on the same
  order. Every line below is a measurement, with how it was taken.

  **The order.** `ORD-260919-0001`, placed 2026-09-19 09:00:30 UTC (12:00
  Riyadh) by `as92+shopper@smail.ucas.edu.ps`. Its number was predicted before
  it was placed, from the Riyadh day and that day's empty counter, and matched.

  **Measured through REST with the customer's own session — 14/14 passed**
  (`verify_order2.py`, run by the agent from a token file outside the repo):
  - the session is the customer's, and `is_admin()` answers **false** in it;
  - **sign-up ran in this run:** the account was created at 08:08:01 UTC by the
    storefront's first sign-in, and `handle_new_user` created its profile
    (`display_name` fell back to `as92+shopper`, the part before `@`);
  - the customer sees **exactly one** order, and its `user_id` is theirs;
  - status `pending` on arrival;
  - **1f on a second day:** the number's date equals the Riyadh date of
    `placed_at`, and the counter reads `0001`;
  - 380 + 35 + 15 = **430**, the total generated by the server; one line,
    carrying the product's name and price as snapshots, summing to the
    subtotal;
  - **the path fingerprint:** the customer's one saved `user_addresses` row
    matches the order's address snapshot field for field, `label` and `kind`
    included. The storefront saves the address before calling `place_order`,
    and `place_order` never writes that table, so this is physical evidence the
    order came through the form rather than a direct RPC call;
  - `contract_version()` = 2 / `a892643ec4bde3567fd435900e75dfe5`.

  **Measured in the storefront by the user:** "طلباتي" listed exactly one
  order, and opening it logged `pushing /orders/ORD-260919-0001` — **the first
  live run of `orderByNumber()`**, which the entry above rightly said was not
  yet established.

  **D1 — measured by the user in the dashboard:** signed in as the admin, it
  showed the customer's order in full — customer, address, and the line with
  product, colour, size and price. So `orders_admin_read` and
  `order_items_admin_read` both work, and the embed works in the UI as it did
  over REST. The status controls offered only «تأكيد» and «إلغاء», the two
  edges out of `pending` — the panel shows what the graph allows, not every
  status. The order was then confirmed from there.

  **D2 — measured by the agent, negative direction only, as decided:** with
  the order `confirmed`, the customer's session asked for `cancelled` and got
  `HTTP 400 transition_not_allowed` — *"confirmed to cancelled is not permitted
  for this caller"* — and the status stayed `confirmed`. In the function's body
  the ownership test comes first and fails with `not_authorised`, so reaching
  `transition_not_allowed` means the database recognised the customer as the
  owner and then refused by the graph. Both guards in
  `d2_owner_negative.py` (the token is the customer's; the order is
  `confirmed`) passed before the call was made.

  **Read afterwards in the SQL Editor:** `orders_total` 3; counter rows
  `2026-08-31 → 1`, `2026-09-17 → 1`, `2026-09-19 → 1`; the customer is not
  in `admins` and owns one order; the newest order is `ORD-260919-0001`,
  `confirmed`.

  **Kept, deliberately:** all three orders stay in the database. Each is
  evidence, and deleting one would leave a gap in a day's counter for nothing.

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

- **FIXED 2026-09-19 — "طلباتي" showed an admin every customer's orders.** Closed by an explicit `.eq('user_id', uid)` on `orders()` and `orderByNumber()`, on top of RLS, not instead of it; rule 08 §1's example rewritten to match. Proved against a fake PostgREST that answers like an admin session (every row when unfiltered): deleting the predicate fails three tests on behaviour. The record as found: Production carries
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

- **FIXED 2026-09-19 — the cart's total was always 15 short of what the shopper paid.** Closed by option A (user): `CartTotals` carries the default method's fee and shows it as its own "رسوم الدفع" line; a test states it against `CheckoutDraft.totals` itself, so the cart and checkout cannot drift apart again. The record as found:
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

- **Catalogue photographs prepared for the dashboard to upload — 2026-09-19.**
  The eight Pillow-generated images read as placeholders beside a real product
  photograph. The agent's own search found no usable open-licensed source
  (Openverse and Wikimedia hold museum garments in the wrong colours; Unsplash
  search answers 401 to anything but a browser, though its image host is
  reachable). The user downloaded nine Unsplash photographs (Unsplash License)
  into `E:\repo\catalogue-photos\` — outside both repositories.

  Processed by the agent, originals untouched: every photo cropped **from the
  neck down** — the licence does not cover the models' publicity rights, so no
  identifiable face goes on a product page — and resized to fit 1200x1800
  (138–244 KB each, down from ~3 MB; no EXIF). Seven survived, in
  `E:\repo\catalogue-photos\ready\`: `p1 p2 p4 p5 p6 p7 p8`. Excluded: the
  seated shot (a neck-down crop left it either landscape or without its
  embroidered sleeve), and one duplicate of the same garment. **p3 keeps its
  generated image** (decided — see *Decisions*).

  Names proposed for the dashboard to apply, prices unchanged: p1 → «عباءة
  سوداء بتطريز زهري», p4 → «طقم عباءة سوداء بفستان وردي», p7 → «عباءة سوداء
  رسمية بخطوط ساتان». Uploading, renaming and deleting the eight old `webp`
  objects are the dashboard's, under its recorded seeding exception.

- **FIXED 2026-09-20 — `Product.images` was a field with no source anywhere.**
  Closed by **removing it**: one artwork field, `imageUrl`, matching the one
  column the database has. Deriving it in the mapper was the alternative and
  was rejected — it would have kept two copies of one fact in step forever,
  for a gallery the schema cannot supply. `ProductThumbnail` now takes a
  single nullable URL (it only ever drew the first of the list);
  `ProductImageCarousel` keeps its list API, because a gallery is a widget
  shape, and the product page converts at the seam. The product page, the
  cart line and the checkout review each have a test that the photograph
  renders — all three failed against the old code with *Found 0 widgets with
  type "Image"*, which is the shopper's placeholder.

  **Still a debt, unchanged and by decision: the order screens.** Their
  `Product` is rebuilt by `SupabaseOrderRepository._itemFromRow` from an
  `order_items` snapshot, which has no image column and no foreign key to
  `products`, so they draw the placeholder under any option. Closing them
  needs either a lookup by `product_id` (today's photo, not the one at
  purchase) or an `image_url` snapshotted into `order_items` — a schema
  change, so the dashboard owner's. The record as found:
 *(Reworded
  2026-09-19. The first version, of 2026-09-17, said the repository "fills
  `imageUrl` only" and left `images` empty, as if it had forgotten one. That
  framing was wrong, and so was its count of three screens.)*

  **There is nothing to fill it from.** Production has **one** image field per
  product: `products.image_url` (text). Read as `claude_reader` on 2026-09-19:
  `products` has no `images` column, no table in any user schema has "image" in
  its name, and `products.image_url` is the only such column in `public`. The
  dashboard's entity has a single image field, and so does the contract.
  `Product.images` (`@Default(<String>[])`, `product.dart:41`) is an app-side
  field with no column behind it, so it is `[]` on every product for ever. The
  repository did not forget anything; there is nothing for it to read.

  `imageUrl` (`@JsonKey(name: 'image_url')`) is the field that has a source.
  As of 2026-09-19 all eight products have one (uploaded from the dashboard,
  served `200 image/webp` from the public URL).

  **Who reads which field:**

  | Surface | Reads | Where the `Product` comes from |
  |---|---|---|
  | Catalogue card | `imageUrl` | the catalogue — **shows the photo** |
  | Product page carousel | `images` | the catalogue (`product_detail_screen.dart:117`) |
  | Cart line | `images` | the catalogue, via cart hydration (`cart_item_tile.dart:57`) |
  | Checkout review | `images` | the catalogue, via the draft (`review_step.dart:109` → `order_item_line.dart:51`) |
  | Orders list | `images` | **an `order_items` snapshot** (`orders_screen.dart:149`) |
  | Order detail | `images` | **an `order_items` snapshot** (`order_detail_screen.dart:97` → `order_item_line.dart:51`) |

  Nothing crashes — `ProductThumbnail` and the carousel draw a placeholder for
  an empty list — which is why it reads as deliberate rather than broken.

  **The two options, not decided, not fixed:**

  1. **Derive it in the mapper.** `SupabaseCatalogRepository` sets
     `images: [if (imageUrl != null) imageUrl]`. The screens stay as they are,
     and the carousel keeps a list-shaped API in case the schema ever grows a
     gallery. The cost: one fact now lives in two fields, and something has to
     keep them in step.
  2. **Remove `images`, and the screens read `imageUrl`.** One field, matching
     the database, the dashboard and the contract. The cost: the carousel
     becomes a single image or a one-page carousel, and a real gallery later
     means bringing a list back.

  **Neither option reaches the order screens alone.** Their `Product` is built
  by `SupabaseOrderRepository._itemFromRow` from an `order_items` row, which
  has no image column. It also has no foreign key to `products`, because a line
  is a snapshot, so PostgREST cannot embed the product's picture. The orders
  list and order detail stay artwork-free under either option. Closing them is
  its own decision: look the current picture up by `product_id` (showing
  today's photo, not the one at purchase), or snapshot `image_url` into
  `order_items` at order time (a schema change, so the dashboard's owner's).
  That method's own comment — "nothing on an order screen asks for those" — is
  no longer true: both order screens draw a thumbnail.

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


- **2026-10-11 — a DNS scare, and the correction.** For one afternoon
  `ydreyrxzilrmynapsgpi.supabase.co` would not resolve: 8.8.8.8 answered
  NXDOMAIN and `curl` could not resolve it, while `supabase.co` itself
  resolved. **That was written up as a likely free-tier pause, and it was
  wrong on both counts.**

  The owner checked the dashboard — the project reads the database, `main` is
  PRODUCTION, and there is no restore button — and pointed out the weakness in
  the measurement: 1.1.1.1 had not answered NXDOMAIN, it had **timed out**, so
  exactly one resolver said "does not exist" and the conclusion was stronger
  than the evidence.

  Re-measured the next morning, each resolver separately:
  - **8.8.8.8** — resolves at once: `172.64.149.246`, `104.18.38.10`.
  - **1.1.1.1** (15 s, 2 retries) — one `DNS request timed out`, then the same
    two addresses.
  - **system resolver** — one `DNS request timed out`, then the same addresses.
  - **A real HTTPS request** — `401` from `104.18.38.10`, which is the correct
    answer for `/rest/v1/` with no `apikey` header. The project is alive.

  And the URL the app uses was read rather than assumed:
  `'https://ydreyrxzilrmynapsgpi.supabase.co'`, 40 characters, no stray
  whitespace, and `SupabaseEnv` rewrites only `127.0.0.1`/`localhost`.

  **What this leaves:** two of three resolvers needed a retry even on the good
  morning, so **DNS on this machine is intermittent** — which explains the
  emulator's `errno = 7` without any theory about the project. A lesson worth
  more than the incident: one resolver's NXDOMAIN is one resolver's answer, and
  a second resolver timing out is not corroboration.

## Toolchain notes

- `freezed` is pinned to the **prerelease** `^3.2.6-dev.1`: stable 3.2.5 caps
  `analyzer` at `<11`, and `injectable_generator` 3.1.3 requires `^12`. Revisit
  when a stable freezed supports analyzer 12+.
- `build_runner` is capped at `^2.15.1` for the same reason (>=2.15.2 wants
  analyzer >=13.3).
- `intl` is held at `^0.20.2` by `flutter_localizations` from the SDK.
