# CLAUDE.md

Agent contract for this Flutter repository. Read this before generating or
changing code.

---

## Session start (mandatory)

1. Read `memory-bank/techContext.md` first. **If it has no
   `Locked by: /platform-init` line, stop** — this project has not decided its
   state-management style, and anything generated would be a guess. Run
   `/platform-init`; it asks one question.
2. Then `memory-bank/architecture.md`, `activeContext.md`, `progress.md` (stop
   once you have enough context). The `SessionStart` hook injects a digest of
   these, so this is usually already satisfied.
3. When routing a request to a skill, read `WORKFLOW.md` — the full
   task → skill map.

## The decisions everything hangs off

`/platform-init` asks three questions in one round and derives everything else.

### 1. State management — exclusive

This kit supports **Cubit, Bloc, and Riverpod**; any single project commits to
exactly one:

| | Riverpod | Bloc | Cubit |
|---|---|---|---|
| State folder | `features/<f>/application/` | `presentation/bloc/` | `presentation/cubit/` |
| Errors | thrown `Failure` + `AsyncValue.guard` | `Result<Failure,T>` + `fold` | `Result<Failure,T>` + `fold` |
| DI | providers (**never** `get_it`) | `get_it` + `injectable` | `get_it` + `injectable` |
| Tests | `ProviderContainer` / `ProviderScope` | `bloc_test` | `bloc_test` |

After `/platform-init` runs, `.claude/rules/02-flutter-state-guard.md` holds
the one installed variant. There is no branch left to get wrong.

### 2. Data source — **not** exclusive

REST, Firebase, Supabase — or a combination. Firebase Auth with a REST data
API is a common and correct split; do not treat it as a conflict.

| | REST | Firebase | Supabase |
|---|---|---|---|
| Transport | `dio` behind `core/network/api_client.dart` | SDK behind `core/data/` | SDK behind `core/data/` |
| Failure mapping | `06-flutter-error-guard` §3 | §7 | §7 |
| Security surface | pinning, token storage | Security Rules | RLS policies |
| Generator | `/flutter-network-gen` | `/flutter-backend-gen` | `/flutter-backend-gen` |

Because it is not exclusive, the mechanism differs from state management:
`08-flutter-baas-security-guard` is **installed if it applies** rather than one
variant surviving. **A project with no REST source has no HTTP client — never
add `dio` to it.**

### 3. Locales — single or multi

Multi installs `11-flutter-l10n-guard` and the ARB pipeline. Single installs
nothing extra.

`07-flutter-direction-guard` is on **either way** — direction-neutral layout
APIs render identically in an LTR app and cost nothing, so an English-only
project stays one locale away from RTL instead of one rewrite away.

Fixed regardless of every answer: **`freezed`** models (one class per entity),
**`go_router`**, feature-first with three layers.

---

## How to work

| Situation | Action |
|---|---|
| Stack not locked yet | `/platform-init` — before anything else |
| Empty project | `/flutter-project-init` — builds the tree and one reference feature |
| No networking layer | `/flutter-network-gen` |
| User asks how an existing screen works | `/feature-trace` — never answer from a guess about code you have not read |
| About to change existing code | `/impact-analysis` **before** editing |
| Work too big for one sitting | `/work-breakdown` — never hand-wave a multi-file change into one task |
| New screen / state / repository / model / widget / route / test | The matching `flutter-*-gen` skill — **`pattern-scout` first** |
| Asked to audit or review | The matching `*-audit` skill |
| Asked if something is ready to ship | `/production-readiness-review` — and do not soften a NO-GO |
| Asked how a change reaches users | `/release-safety` — staged rollout, not a big-bang cutover |
| New repo without a memory-bank | `/platform-init` → `/repo-discovery` → `/context-sync` |

**Announcement format (required for every matched skill except housekeeping):**

> **Matched skill:** `skill-name` — [one-line description].

Generators and outer-loop skills (they write files or commit to a plan):
announce, then wait for a go-ahead. Auditors and analysis skills (read-only):
announce, then proceed. Housekeeping (`repo-discovery`, `context-sync`): run
silently.

---

## Rules — `.claude/rules/`

Claude Code has no glob-scoped rule loader, so the always-on four are restated
here and injected by the `SessionStart` hook. **The files remain
authoritative** — read the full file before any non-trivial application.

**Always active:**

- **`00-memory-think`** — read the memory-bank before generating code, writing
  specs, running a skill, or answering any non-trivial question. Never
  re-implement something `progress.md` marks Done.
- **`05-planning-rigor`** — no plan or task board without an elicitation pass
  first. Present options with explicit tradeoffs; never one option presented
  as the only one.
- **`09-minimal-changes`** — change only what the task requires. No unrelated
  `dart format` sweeps, no drive-by refactors. Minimise the diff.
- **`10-evidence-and-dependency-guard`** — confirm classes, cubits, providers,
  routes, and `pubspec.yaml` dependencies **exist** before referencing them
  (grep first). Never add a pub.dev package that is not already in
  `pubspec.yaml` unless the user explicitly asked. The `flutter pub add`
  permission prompt is a signal to stop and ask, not to find a workaround.

**Read on demand:**

| Touching | Read first |
|---|---|
| widgets, screens, feature `.dart` files | `01-flutter-architecture-guard.md` |
| cubits, blocs, notifiers, any state | `02-flutter-state-guard.md` |
| repositories, data sources, anything that can fail | `06-flutter-error-guard.md` |
| any source or config file | `03-flutter-security-guard.md` |
| `_test.dart` files | `04-flutter-test-guard.md` |
| any layout or widget code | `07-flutter-direction-guard.md` |
| Firestore Rules, RLS policies, BaaS data sources | `08-flutter-baas-security-guard.md` *(BaaS projects)* |
| `.arb` files, user-facing strings | `11-flutter-l10n-guard.md` *(multi-locale projects)* |

### Rule numbering

```
00–08   domain rules (Flutter/Dart craft)
09–11   agent discipline, and conditional rules
```

A new rule takes **the first free number in its block**. Never skip to a higher
number — 1.0.0 left 06/07/08 empty and the gap took a full audit to explain.
If a block is full, that is a signal to merge two related rules rather than to
break the sequence.

### Non-negotiables

- **Architecture:** feature-first, three layers (`data` / `domain` /
  `presentation`). No business logic inside widgets. Dependencies point one
  way; `domain/` imports neither of the other two.
- **State:** one style per project, whatever `/platform-init` locked. Sealed
  state classes with complete `Equatable` `props`. Four states minimum for
  anything that loads: loading, error, empty, data. `setState` is for
  ephemeral widget-local UI only.
- **Errors:** one app-wide sealed `Failure` hierarchy in `core/error/`. Never
  a per-repository exception type. `dio` is caught **once**, at
  `core/network/`; a BaaS SDK is caught **once**, at its data source. Nothing
  under `lib/features/` imports either.
- **Direction:** `start`/`end`, never `left`/`right`, in every project.
  `EdgeInsetsDirectional`, `AlignmentDirectional`, `TextAlign.start`. A
  physical API needs a `// direction-fixed:` tag naming why.
- **Security:** no secrets in source; tokens through `flutter_secure_storage`,
  never plaintext `SharedPreferences`; no unvalidated input crossing a
  platform channel.
- **Tests:** fake the state owner, never the network. Cover all four states,
  not just the happy path. Assert behaviour and the full emitted state
  sequence, not internals.

---

## Subagents — use them, they protect the context window

`.claude/agents/` holds read-only specialists. Delegating keeps widget trees,
provider graphs, and generated boilerplate **out of the main conversation** —
only findings come back.

| Subagent | Delegate when |
|---|---|
| `pattern-scout` | Before any `flutter-*-gen` skill — finds the canonical local example to imitate |
| `flutter-auditor` | Architecture, state, or performance review spanning more than ~5 files |
| `repo-cartographer` | Structural mapping / `repo-discovery` / `context-sync` refreshes |
| `mobile-security-auditor` | Secrets, secure storage, platform channels, permissions |

Do **not** delegate file-writing work — these are read-only by design.
Generation stays in the main thread where the guard rules apply.

---

## Memory-bank

| Layer | Location | Owner |
|---|---|---|
| Machine (structure) | `.claude/cache/repo-map.json` | `/repo-discovery` — never hand-edit |
| Tier 1 (dynamic) | `techContext.md`, `progress.md`, `activeContext.md` | `/platform-init` (the lock) + `/context-sync` |
| Tier 2 (standards) | `architecture.md`, `domainRules.md`, `securityStandards.md` | Human — ask if undocumented |

**After significant work**, update `activeContext.md` and `progress.md` with
what changed and the next logical step.

---

## Hooks — what is enforced mechanically

`.claude/settings.json` wires:

| Event | Effect |
|---|---|
| `SessionStart` | `session-start.mjs` — injects the memory-bank digest, flags a missing `/platform-init` lock, restates the always-on rules |
| `PreToolUse` (Write/Edit) | `guard-write.mjs` — blocks hand-edits to `repo-map.json`, writes to `.env`/secret files, edits to **already-filled** Tier 2 files, and hardcoded credentials in content |
| `Stop` | `verify-session.mjs` — if the session changed Dart, runs `dart format`, `flutter analyze`, `flutter test` (when tests changed) and greps for leftover `DEBUG-TEMP`. Reports; never blocks |

Tier 2 files are writable **once**, while still the shipped template — that is
how `/platform-init` bootstraps them. After that first fill they are blocked.

If a hook blocks you, **stop and tell the user why.** Do not route around it
with a different tool.

---

## Using this kit in another Flutter repo

Run `install.ps1 -Target <path>` — it copies `.claude/`, `memory-bank/`,
`CLAUDE.md`, `WORKFLOW.md`, the CI workflow, stamps `.claude/.kit-version` and
merges `.gitignore` entries. Copying only `.claude/` by hand is the most common
installation mistake. Then `/platform-init`, then either
`/flutter-project-init` (new project) or `/repo-discovery` + `/context-sync`
(existing codebase). `WORKFLOW.md` has the full walkthrough, and `/kit-doctor`
verifies the result at any point afterwards.
