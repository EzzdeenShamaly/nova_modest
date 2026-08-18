---
name: flutter-test-gen
description: "Backfills widget, state (Cubit/Bloc/Notifier), or repository tests onto existing Flutter code using this project's test convention (bloc_test or ProviderScope overrides) and mocktail/mockito fakes, covering loading/error/empty states and asserting behavior rather than implementation. Use when asked to add test coverage to existing code. Invoked as /flutter-test-gen."
---

# Skill: flutter-test-gen

**Invocation:** `/flutter-test-gen [target file/widget/provider]`

---

## Overview

`flutter-test-gen` scaffolds widget or unit tests for an existing
widget/screen/Notifier/repository that doesn't have coverage yet, following
`04-flutter-test-guard.md`, using the harness that matches the state style
locked in `techContext.md` — fakes and mocks for repositories in every case.
Other `*-gen` skills already generate a test alongside new code; this skill
is for backfilling tests onto existing code, or expanding coverage an audit
flagged as thin.

**Memory references:** `memory-bank/techContext.md` — the locked state
management style **and** mocktail vs mockito. Read the lock before Step 1;
the harness differs per style and guessing wrong wastes the whole pass.

**Guard rules:** `04-flutter-test-guard.md` (primary).

---

## Steps

**Step 0 — Identify what's under test and its dependencies.** Read the
target file. List every provider/repository/service it depends on — each
needs an override or fake in the test.

**Step 1 — Widget under test.** Inject a fake state holder for every one the
widget reads, directly or transitively, using this project's harness:

| Locked style | Harness |
|---|---|
| **Cubit / Bloc** | `BlocProvider.value(value: mockCubit)`, with `whenListen(mockCubit, Stream.fromIterable([...]), initialState: ...)` from `bloc_test` to drive the state sequence |
| **Riverpod** | `ProviderScope(overrides: [...])` for every provider it reads |

Cover, in all styles:
- The happy-path render with representative data
- Loading state, if the widget renders one
- Error state with retry, if the widget has a retry action
- Empty-data state, if meaningfully different from populated

The four states come from the screen's own state contract — the sealed state
class for Cubit/Bloc, `AsyncValue` for Riverpod. Assert on what the user sees,
not on which state object arrived.

**Step 2 — State holder under test.** Fake the repository, then assert the
emitted sequence for each public method — success and at least one failure
path.

| Locked style | Harness |
|---|---|
| **Cubit / Bloc** | `blocTest<OrdersCubit, OrdersState>(...)` with `build`, `act`, `expect` — the emitted list is the assertion |
| **Riverpod** | a `ProviderContainer` with the repository provider overridden; assert the `state` sequence |

For Cubit/Bloc, assert the **emitted list**, not intermediate reads of
`cubit.state` — the list is the behaviour and a missed `emit` is exactly the
bug this catches. Close the holder in `tearDown`, or the next test inherits a
live subscription.

**Step 3 — Repository under test.** Mock whatever the repository talks to —
the HTTP client for a REST project, the BaaS client for Firebase or Supabase
(see the data source lock in `techContext.md`). Use `mocktail`/`mockito`,
whichever is already a dev dependency — confirm, don't add a new one. Assert the success path maps JSON correctly and at
least one error path maps to the correct typed exception.

**Step 4 — Do not test implementation details.** No asserting on a
state holder's private fields, no asserting a `build()` method was called a
specific number of times, no testing that a mock was constructed a certain
way if the test doesn't also assert the resulting behavior. Every
assertion must be able to fail for a real reason — a test that can never
fail (asserting on a constant, or on a value the test itself just set) adds
false coverage.

**Step 5 — Name tests by behavior, not by method.** `'shows retry button
when fetch fails'`, not `'test build method'` — the test name is the
first thing a failing-CI reader sees.

---

## Example

Request: "This repository has no tests, add coverage."

Output: `test/features/orders/data/api_order_repository_test.dart` with
cases for successful fetch, 404 mapped to `OrderNotFoundException`, and
timeout mapped to `OrderNetworkException` — using the mock HTTP client
package already present in `pubspec.yaml`.
