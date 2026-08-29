# Architecture

**Tier 2 — human-authored.** Read by `01-flutter-architecture-guard.md`, every
`flutter-*-gen` skill, and `pattern-scout`. Not auto-regenerated: "what is our
folder convention" is a decision, not an observation.

Filled once by `/platform-init` on 2026-08-18. The write guard now blocks agent
edits — later changes get proposed in chat instead.

---

## Layout convention

Feature-first, three layers. Each feature under `lib/features/<name>/` has
`data/`, `domain/`, `presentation/`. Shared infrastructure in `lib/core/`.

## Folder structure

```
lib/
  core/
    error/      failure.dart  (sealed Failure hierarchy)
                result.dart   (sealed Result<T> + fold)
    network/    api_client.dart      (the abstract seam)
                dio_api_client.dart  (the only file that imports dio)
                interceptors/  auth_interceptor.dart, logging_interceptor.dart
    theme/      app_theme.dart
    widgets/    failure_view.dart
    di/         injection.dart       (get_it + injectable setup)
    utils/      extensions.dart
  features/
    <feature>/
      data/         datasources/, repositories/
      domain/       entities/, repositories/, usecases/
      presentation/ bloc/, screens/, widgets/
  l10n/         app_<locale>.arb     (template + one file per locale)
  router/       app_router.dart, routes.dart
  app.dart
  main.dart
```

`usecases/` ships present-but-empty. `l10n/` holds authored ARB only;
generated `AppLocalizations` is never hand-edited.

## Layer rules

`presentation → domain → data`, one way only.

- A widget never imports from `data/`, and never constructs a repository — it
  goes through a Bloc obtained from `BlocProvider`.
- A repository implementation never imports a widget.
- `domain/` imports neither of the other two.
- `AppLocalizations` is presentation-layer. `domain/` and `data/` never import
  it — a `Failure` carries a type, and the widget maps that type to a
  translated message (`11-flutter-l10n-guard`).
- No cross-feature imports. Anything two features both need moves to `core/`.

## State placement

One Bloc per screen concern, in that feature's `presentation/bloc/`, with its
sealed events and sealed states beside it.

- Registered as a `get_it` **factory**, not a singleton — a singleton behind a
  screen is what makes the previous user's data flash on re-entry.
- Provided at the narrowest scope that needs it, normally the route:
  `BlocProvider(create: (_) => sl<XBloc>()..add(const XRequested()))`.
- `BlocProvider.value` when handing an existing Bloc to a pushed route.
- Genuinely app-wide state only (auth, theme, **locale**) is an app-level
  singleton wrapped in `MultiBlocProvider` in `app.dart`. The selected locale
  is Bloc state and persisted — never a top-level mutable variable.
- A Cubit is acceptable for a screen with no meaningful event semantics; that
  is a per-screen judgement call, and this project's default is Bloc.

## Error handling

Repositories return `Result<Failure, T>`; the Bloc handler resolves it with
`fold` and emits a state. One sealed `Failure` hierarchy in
`lib/core/error/failure.dart` for the whole app — no per-feature error types,
and no `dartz`/`fpdart`.

- No `try`/`catch` in a Bloc handler. A `catch` there means the data layer is
  leaking.
- No `try`/`catch` in a widget's `build()`. Errors are state, not layout.
- Rendered by the shared `core/widgets/failure_view.dart`, not a bespoke error
  UI per screen.
- `UnauthorizedFailure` is the exception: it belongs to the
  refresh-then-logout flow in the auth interceptor, so the user lands on login
  rather than an inline error card.
- Every screen that can fail renders **four** states explicitly: loading,
  error with retry, empty, and data. `Empty` is a distinct state, not
  `Loaded([])`.

## Networking

REST only. `core/network/dio_api_client.dart` is the sole file permitted to
import `dio`, and the sole place `DioException` is caught and mapped to
`Failure`. Everything above depends on the `ApiClient` interface.

One `Dio` instance behind the interceptor chain. A second instance is
permitted only for token refresh, deliberately interceptor-free to avoid a
refresh loop; any other second instance escapes auth, logging and pinning and
is a defect.

There is no BaaS SDK in this project. Do not add one without re-running
`/platform-init`.

## Routing convention

Single `GoRouter` in `lib/router/app_router.dart`; paths and names as
constants in `routes.dart` — no magic strings at call sites. The auth guard is
a top-level `redirect` reading the app-wide auth Bloc.

Shell-route usage is undecided until the first navigation shape is real —
`/flutter-project-init` decides it and records it here.

## Localization and direction

Multi-locale, including an RTL language, so both rules are live:

- `11-flutter-l10n-guard` — no user-facing string literal in a widget; ARB is
  the source; ICU for plurals; `intl` for dates, numbers and currency; every
  locale complete before release; LTR **and** RTL goldens on any screen that
  has goldens; the theme font must cover every locked script.
- `07-flutter-direction-guard` — `start`/`end` everywhere, never
  `left`/`right`. `EdgeInsetsDirectional`, `AlignmentDirectional`,
  `PositionedDirectional`, `TextAlign.start`. A physical API is allowed only
  with a `// direction-fixed:` tag naming the physical quantity that fixes the
  direction.

## Testing

`bloc_test` + `mocktail`. Fake the state owner, never the network. Bloc tests
assert the **whole** emitted state sequence, not just the final state — and
every `Equatable` state lists every field in `props`, or the assertions pass
while the UI silently stops updating.

## Use-cases

`usecases/` exists but is empty by default. Add one only when logic spans more
than one repository or encodes a real domain rule — never as a pass-through
wrapper around a single repository call.
