---
name: platform-init
description: "Decide and lock this project's stack conventions once: state management (Riverpod / Bloc / Cubit), and everything derived from it (error-handling shape, DI, state folder, test style). Writes memory-bank/techContext.md + architecture.md and installs the matching state-guard rule. Run this FIRST, before any other skill, in every new or newly-adopted repo. Invoked as /platform-init."
---

# Skill: platform-init

**Invocation:** `/platform-init`

**Category:** Bootstrap — runs once per repository, before anything else.

---

## Overview

This kit deliberately supports three state-management styles, but **any
single project commits to exactly one**. `platform-init` is where that
commitment is made and written down, so every generator afterwards reads a
decided answer instead of re-deciding per invocation.

It asks the user **one** question. Everything else is either detected from
the repo or derived from that answer.

**Memory references:** writes `memory-bank/techContext.md` and
`memory-bank/architecture.md`; reads `pubspec.yaml` and `lib/`.

**Guard rules:** `10-evidence-and-dependency-guard.md` — detect before
asking, never assume.

---

## Steps

### Step 1 — Detect before asking

Read `pubspec.yaml` and glob `lib/` first. Establish:

| Signal | Look for |
|---|---|
| State management already in use | `flutter_bloc`, `flutter_riverpod`, `hooks_riverpod`, `riverpod_annotation` in `pubspec.yaml`; `extends Cubit`, `extends Bloc`, `@riverpod`, `AsyncNotifier` in `lib/` |
| Bloc vs Cubit (if `flutter_bloc`) | `extends Bloc<` → Bloc; only `extends Cubit<` → Cubit |
| Codegen | `build_runner` + `freezed` + `json_serializable` |
| Routing | `go_router` |
| Data source | `dio`/`http` → REST; `firebase_core`/`cloud_firestore`/`firebase_auth` → Firebase; `supabase_flutter` → Supabase. **More than one can be true.** |
| Locales | `flutter_localizations` + `lib/l10n/*.arb`; count the ARB files |
| DI | `get_it`, `injectable` |
| Layout | `lib/features/` → feature-first; `lib/presentation|domain|data/` → layered |
| Project age | count of `.dart` files under `lib/` (≤ 3 → treat as new project) |

### Step 2 — Ask, in one round

**If nothing was detected** (new project), ask:

```markdown
## State management for this project?

| Option | Use when |
|---|---|
| **A — Cubit** | Default choice. Simplest of the three; a class with methods that emit states. Covers the large majority of screens. |
| **B — Bloc** | Same package as Cubit, event-driven. Choose when flows are complex enough that an explicit event log is worth the extra boilerplate. |
| **C — Riverpod** | Compile-safe DI built in, no `get_it` needed, `AsyncValue` handles loading/error/data for you. |

Bloc and Cubit can coexist later (Cubit for simple screens, Bloc for complex
flows) — pick the one that will be the default here.
```

Ask the two questions below in the **same message**, then wait once. Three
separate round-trips for what is one setup decision is a worse experience than
one block of three questions.

```markdown
## Data sources for this project? (tick all that apply)

| Option | Use when |
|---|---|
| **A — REST API** | Your own backend. `dio` behind an `ApiClient` seam. **This is the common case; if unsure, this is the answer.** |
| **B — Firebase** | Auth / Firestore / Storage via the FlutterFire SDKs. |
| **C — Supabase** | Postgres + RLS + Storage via `supabase_flutter`. |

More than one is normal — Firebase Auth with a REST data API is a very common
split. If you tick more than one, say which owns the **primary domain data**.

## How many locales will this app ship?

| Option | Cost |
|---|---|
| **A — English only (or one language)** | Nothing extra. Direction-neutral layout APIs are used either way. |
| **B — Multiple, including an RTL language** | Adds the ARB pipeline, `AppLocalizations`, and bidirectional golden tests. |

Answering A does **not** close the door: `07-flutter-direction-guard` is on
regardless, so the codebase stays one locale away from B rather than one
rewrite away.
```

Wait for the answers. Do not proceed on a guess.

**If a convention WAS detected**, do not ask an open question — state the
finding and ask only for confirmation:

> Detected: `flutter_bloc` 9.1.1, 14 `Cubit` subclasses, no `Bloc` subclasses,
> feature-first layout under `lib/features/`. Locking this project to
> **Cubit**. Say so now if that's wrong.

### Step 3 — Derive everything else

Nothing below is a question. It follows from Step 2.

| | Riverpod | Bloc | Cubit |
|---|---|---|---|
| Packages | `flutter_riverpod`, `riverpod_annotation`, `riverpod_generator` | `flutter_bloc`, `equatable`, `get_it` | `flutter_bloc`, `equatable`, `get_it` |
| State folder | `features/<f>/application/` | `features/<f>/presentation/bloc/` | `features/<f>/presentation/cubit/` |
| Error shape | `sealed Failure` thrown as exception, caught by `AsyncValue.guard` | `Result<Failure, T>` returned, resolved with `fold` | `Result<Failure, T>` returned, resolved with `fold` |
| DI | providers only — **never add `get_it`** | `get_it` + `injectable` | `get_it` + `injectable` |
| Test style | `ProviderContainer` / `ProviderScope` overrides | `bloc_test` + `mocktail` | `bloc_test` + `mocktail` |
| State-guard rule | `02-state-guard-riverpod.md` | `02-state-guard-bloc.md` | `02-state-guard-cubit.md` |

Fixed for every project regardless of the answer:

- **Transport:** whatever the data-source answer implies, always behind a
  seam. For REST that is `dio` behind the `ApiClient` interface; for Firebase
  or Supabase it is the SDK behind a data-source class. **A project with no
  REST source has no HTTP client — do not add `dio` to it.** Repositories
  never import `dio` or a BaaS SDK directly (`06-flutter-error-guard.md`).
- **Models:** `freezed` + `json_serializable`, one class serving both domain
  and DTO roles.
- **Routing:** `go_router`.
- **Architecture:** feature-first, three layers (`data` / `domain` /
  `presentation`), `usecases/` present but empty until a real one is needed.

### Step 4 — Install the matching rules

**State management — keep one, delete two.** `.claude/rules/` ships all three
variants:

```bash
cd .claude/rules
mv 02-state-guard-<chosen>.md 02-flutter-state-guard.md
rm -f 02-state-guard-riverpod.md 02-state-guard-bloc.md 02-state-guard-cubit.md
```

This is the point of the design: after this step the repo contains exactly
one state convention, and no generator has a branch left to get wrong.

**Data source and locales — selective install, not deletion.** These two are
not exclusive the way state management is, so the mechanism differs: keep what
applies, remove what cannot:

```bash
# Data source: no BaaS ticked → the BaaS security rule does not apply
[ "$BAAS" = "none" ] && rm -f 08-flutter-baas-security-guard.md

# Locales: single locale → the l10n pipeline rule does not apply
[ "$LOCALES" = "single" ] && rm -f 11-flutter-l10n-guard.md
```

`07-flutter-direction-guard` is **never removed** — it is on for every project
and costs a single-locale app nothing.

A project that ticked both Firebase and REST keeps `08` and keeps `dio`; both
are correct at once. Do not treat a hybrid as a conflict to resolve.

### Step 5 — Write `memory-bank/techContext.md`

Replace the whole file — no placeholder slots, no `> EXAMPLE` block:

```markdown
# Tech Context

**Last Updated:** <today>
**Locked by:** `/platform-init`

- Flutter/Dart SDK: <from pubspec.yaml>
- State management: **<Cubit|Bloc|Riverpod>** — state lives in `<folder>`
- Error handling: **<Result<Failure,T> + fold | sealed Failure + AsyncValue.guard>**
- DI: **<get_it + injectable | Riverpod providers>**
- Data sources: **<REST | Firebase | Supabase | hybrid — name the split>**
  - REST → `dio` behind `lib/core/network/api_client.dart`
  - Firebase → SDK behind `lib/core/data/firebase_*_source.dart`
  - Supabase → SDK behind `lib/core/data/supabase_*_source.dart`
- Failure mapping: `06-flutter-error-guard` §3 (Dio) and/or §7 (BaaS)
- Models: `freezed` + `json_serializable`, one class per entity
- Routing: `go_router`
- Testing: **<bloc_test + mocktail | ProviderContainer + mocktail>**
- Locales: **<single | multi — list them>**
- Direction: `07-flutter-direction-guard` (always on)
```

### Step 6 — Write `memory-bank/architecture.md`

Fill it with the concrete decided structure (see `flutter-project-init` for
the canonical tree). Delete every `[bracket slot]` and every `> EXAMPLE —`
block. A Tier 2 file left holding placeholders is the single most common way
this kit fails.

> **Note on the write guard:** `guard-write.mjs` blocks agent writes to Tier 2
> files, but allows the **first** write while the file is still the unfilled
> template. This skill is that first write. Any later change to
> `architecture.md` is proposed to the user in chat, not written.

### Step 7 — Report and hand off

```markdown
## Locked

- State management: **Cubit**
- Error handling: `Result<Failure, T>` + `fold`
- DI: `get_it` + `injectable`
- Data sources: **Firebase (auth) + REST (primary data)**
- Locales: **single (en)**
- State-guard rule installed: `02-flutter-state-guard.md` (cubit variant)
- BaaS security rule installed: `08-flutter-baas-security-guard.md`
- l10n rule: not installed (single locale)
- Written: `memory-bank/techContext.md`, `memory-bank/architecture.md`

## Next

- New/empty project → `/flutter-project-init`
- Existing codebase → `/repo-discovery` then `/context-sync`
```

---

## Rules

- **Runs once.** If `techContext.md` already says `Locked by: /platform-init`,
  do not silently re-run. Report the current lock and ask what the user wants
  to change. The three locks have very different weights:
  - **State management** — changing it is a migration, not a re-init. It
    invalidates existing state holders, tests and DI. Say so, and require an
    explicit confirmation.
  - **Data source** — *adding* one (Supabase Storage to a Firebase app, a REST
    API to either) is normal evolution. Record it, install `08` if this is the
    first BaaS source, and continue. No warning needed.
  - **Locales** — going single → multi installs `11` and adds the pipeline. It
    is additive and does not invalidate existing code, because `07` was
    already enforced.
- **Never mix.** If detection finds both `flutter_bloc` and
  `flutter_riverpod` in `pubspec.yaml`, stop and report it. That is a real
  problem in the repo and picking one silently hides it.
- **Never install packages here.** This skill writes documentation and moves
  a rule file. `flutter-project-init` is what edits `pubspec.yaml`, and only
  on a new project.
