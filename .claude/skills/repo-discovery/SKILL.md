---
name: repo-discovery
description: "Scans a Flutter repository's pubspec.yaml, lib/ structure, and actual state-management/routing/testing conventions in use, and writes .claude/cache/repo-map.json - the structural map other skills and context-sync read from. Use at the start of a session in an unmapped repo. Invoked as /repo-discovery."
---

# Skill: repo-discovery

**Invocation:** `/repo-discovery`

**Category:** Housekeeping — runs silently, no announcement.

---

## Overview

`repo-discovery` scans a Flutter repository and builds the structural map
this platform reasons from: `pubspec.yaml` dependencies, `lib/` folder
structure, whether Riverpod (and which style — codegen vs manual) is
already in use, the router package, and the testing setup. Writes
`.claude/cache/repo-map.json` — the machine-owned structural layer
`context-sync` reads to populate the memory-bank's Tier 1 files.

**Memory references:** none read — this skill produces the evidence other
skills and `context-sync` read.

**Guard rules:** none — read-only scan. Never hand-edit
`.claude/cache/repo-map.json`; only this skill writes it.

---

## Steps

**Step 1 — Read `pubspec.yaml`.** Extract: Flutter/Dart SDK constraint,
every `dependencies`/`dev_dependencies` entry and version, and flag the
presence of the packages this kit has conventions for:
`flutter_bloc`, `equatable`, `bloc_test`, `get_it`/`injectable`,
`flutter_riverpod`/`hooks_riverpod`,
`riverpod_generator`/`riverpod_annotation`, `go_router`,
`freezed`/`json_serializable`, `flutter_secure_storage`, `dio`/`http`,
`mocktail`/`mockito`, `integration_test`, `flutter_localizations`/`intl`.

**If both `flutter_bloc` and `flutter_riverpod` are present, stop and report
it.** Two state-management systems in one app is a real defect; recording one
of them silently hides it from the person who has to decide.

**Step 2 — Map `lib/` structure.** Use `readdirSync(dir, {withFileTypes:
true})`-style directory listing (not per-entry `stat`, which is slow on
mounted/network filesystems) to determine: feature-first
(`lib/features/<name>/...`) vs layered (`lib/presentation|domain|data/...`)
at the top level, and the depth/consistency of that pattern across
existing features.

**Step 3 — Detect the state-management convention actually in use.** The
dependency list says what is *available*; grep says what is *used*, and the
two disagree more often than not. Count occurrences of:

| Grep | Means |
|---|---|
| `extends Cubit<` | Cubit |
| `extends Bloc<` | Bloc (a repo with both is normal — record the ratio) |
| `@riverpod`, `AsyncNotifier`, `Notifier<`, `StateProvider` | Riverpod, and which flavour |
| `setState(` | Screens not yet migrated to whatever the convention is |

Also record the **error-handling shape** in use, since it is downstream of
this choice: grep for `Result<`, `Either<`, `\.fold(`, `AsyncValue.guard`,
`on DioException`, and count `Failure`/`Exception` subclasses under
`lib/features/` (per-feature error types are a finding —
`06-flutter-error-guard.md`).

**Step 4 — Detect routing convention.** Find the router configuration file
and note whether routes are flat, nested under a `ShellRoute`, and whether
any route has a `redirect` guard already.

**Step 5 — Detect test setup.** Note whether `test/` mirrors `lib/`'s
structure, whether `ProviderScope` overrides are used consistently in
existing widget tests (or whether tests hit real providers — a finding for
`flutter-architecture-audit` to pick up later), and whether
`integration_test/` exists.

**Step 6 — Write `.claude/cache/repo-map.json`.**

```json
{
  "generatedAt": "2026-08-08T00:00:00Z",
  "sdkConstraint": ">=3.3.0 <4.0.0",
  "stateManagement": {
    "package": "flutter_bloc",
    "style": "cubit",
    "counts": { "cubit": 14, "bloc": 2, "riverpodNotifier": 0, "setState": 3 },
    "conflict": false
  },
  "errorHandling": {
    "shape": "Result+fold",
    "sharedFailureHierarchy": true,
    "perFeatureErrorTypes": 0,
    "dioLeaksAboveCore": 0
  },
  "di": { "package": "get_it", "injectable": true },
  "routing": { "package": "go_router", "shellRoutes": true },
  "layout": "feature-first",
  "features": ["auth", "cart", "checkout", "orders", "profile"],
  "testing": { "blocTest": true, "providerScopeOverridesUsed": false, "integrationTestPresent": false },
  "dependenciesOfInterest": { "freezed": "2.4.6", "dio": "5.4.0", "flutter_secure_storage": "9.0.0" }
}
```

`style` is one of `cubit` / `bloc` / `riverpod`, chosen by the dominant count
— never by the dependency list alone. `dioLeaksAboveCore` counts files
outside `lib/core/network/` importing `dio`; anything above zero is a finding
for `flutter-architecture-audit`.

**Step 7 — Report freshness on future runs.** If `repo-map.json` already
exists, compare `generatedAt` against `pubspec.yaml`'s mtime — if
`pubspec.yaml` changed more recently, note the map is stale and re-scan
rather than trusting it silently.

---

## Example

Request: "Scan this repo before we start." → Silent run, writes
`.claude/cache/repo-map.json`, then hands off to `/context-sync` to
populate the human-readable memory-bank from it.
