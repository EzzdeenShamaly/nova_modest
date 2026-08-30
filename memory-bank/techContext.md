# Tech Context

**Last Updated:** 2026-08-30
Locked by: `/platform-init` — data source **re-locked 2026-08-30** (user
approval) when Supabase arrived. Everything else is the original 2026-08-18
lock, unchanged.

> This file is **Tier 1**. `/platform-init` wrote the locked stack once;
> `/context-sync` refreshes the observed reality around it on every sync and
> never rewrites the lock.

## Locked stack

- Flutter/Dart SDK: `^3.12.2`
- State management: **Bloc** (`flutter_bloc`) — state lives in
  `features/<f>/presentation/bloc/`
- Error handling: **`Result<Failure, T>` returned by repositories, resolved
  with `fold` in the Bloc handler** — one sealed hierarchy in
  `lib/core/error/failure.dart`
- DI: **`get_it` + `injectable`**
- Data sources: **Supabase + REST** — not exclusive, as `CLAUDE.md` states for
  this axis
  - Supabase → `supabase_flutter` behind `lib/core/supabase/` and the
    `supabase_*_repository.dart` files. **The live backend.**
  - REST → `dio` behind `lib/core/network/api_client.dart`. Retained and still
    registered; nothing routes through it today.
- Failure mapping: `06-flutter-error-guard` **§7 (Supabase)** via
  `core/supabase/supabase_error_mapper.dart`. §3 (Dio) still applies to the
  `dio` seam.
- Models: `freezed` + `json_serializable`, one class per entity
- Routing: `go_router`
- Testing: **`bloc_test` + `mocktail`**
- Locales: **multi, including an RTL language**
- Direction: `07-flutter-direction-guard` (always on)

## Rules installed by this lock

| Rule | Status |
|---|---|
| `02-flutter-state-guard.md` | installed — **bloc** variant |
| `07-flutter-direction-guard.md` | installed — always on, every project |
| `11-flutter-l10n-guard.md` | installed — multi-locale |
| `08-flutter-baas-security-guard.md` | **installed 2026-08-30** — Supabase |

08 was reserved and empty from 2026-08-18 to 2026-08-29, exactly as the
numbering convention says such a slot should be: held for the conditional BaaS
rule rather than claimed by an unrelated one. Adding Supabase is the evolution
that file was waiting for, and `12-flutter-design-system-guard.md` sitting
outside the domain block is what kept the slot free for it.

## Observed reality (refreshed by `/context-sync`)

Scaffolded by `/flutter-project-init` on 2026-08-18. The locked decisions above
are now implemented in code.

- Layout: feature-first under `lib/features/`, shared code in `lib/core/`
- Reference feature: `lib/features/auth/` — the canonical example for
  `pattern-scout`. Catalogue browsing lives in `lib/features/catalog/`.
- Resolved versions: `flutter_bloc` 9.1.1 · `bloc_concurrency` 0.3.0 ·
  `equatable` 2.1.0 · `get_it` 9.2.1 · `injectable` 3.0.0 · `go_router` 17.5.0 ·
  `dio` 5.11.0 · `freezed` 3.2.6-dev.1 · `json_serializable` 6.14.1 ·
  `flutter_secure_storage` 11.0.0 · `intl` 0.20.2 · `bloc_test` 10.0.0 ·
  `mocktail` 1.0.5. Flutter 3.44.8 / Dart 3.12.2.
- Shell routes: **no** — three flat routes (`/`, `/login`, `/home`). Add a
  `StatefulShellRoute` when a bottom nav appears.
- Secure storage: `flutter_secure_storage` behind `core/storage/token_storage.dart`,
  auth tokens only
- HTTP client: `dio`, confined to `lib/core/network/`; leaks above it: **0**
- Backend: **Supabase**, local stack under `supabase/` — 13 tables, RLS enabled
  on every one, `place_order` as a `security definer` RPC. `supabase_flutter`
  imports are confined to `lib/core/supabase/` and the four
  `supabase_*_repository.dart` files; leaks above them: **0**
- Repository bindings are **environment-scoped**: `Environment.dev` binds the
  Supabase implementations, `Environment.test` binds the fakes. The whole suite
  runs on `test` and never touches a network.
- Live today: `AuthRepository`, `CatalogRepository`, `AddressRepository`,
  `OrderRepository`. Still local: the cart, onboarding, locale, search history
  and notification preferences — all `SharedPreferences`.
- Localization: `lib/l10n/`, template `app_ar.arb` + `app_en.arb`, generated
  `AppLocalizations` committed alongside
- Generated code (`*.g.dart`, `*.freezed.dart`, `*.config.dart`) is **committed**
  and excluded from analysis
- `integration_test`: no
- Tests: 26 passing (repository, bloc, screen, RTL). `flutter analyze` clean.

## Toolchain constraints

`freezed` is on the prerelease `^3.2.6-dev.1` and `build_runner` is capped at
`^2.15.1` — stable freezed 3.2.5 requires `analyzer <11` while
`injectable_generator` 3.1.3 requires `^12`. See `progress.md` → Toolchain notes.
