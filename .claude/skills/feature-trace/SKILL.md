---
name: feature-trace
description: "Traces how an existing screen or user flow actually works today - route to screen widget, state objects involved, repository calls, and the underlying API/data source - so changes are based on the real code, not a guess. Use when asked how a screen or flow works. Invoked as /feature-trace."
---

# Skill: feature-trace

**Invocation:** `/feature-trace "[screen/flow name]"`

---

## Overview

`feature-trace` answers "how does this screen/flow actually work today" by
tracing the real widget tree, provider graph, and repository calls behind
it — from route entry to data source — rather than guessing from file
names. In a mobile app the equivalent of a .NET request trace is: route →
screen widget → providers it watches → Notifiers those providers wrap →
repositories those Notifiers call → the API/local data source underneath,
plus any navigation the flow triggers.

**Memory references:** `memory-bank/architecture.md`.

**Guard rules:** none — read-only tracing.

---

## Steps

**Step 0 — Locate the entry point.** Find the route (`go_router`
`GoRoute`) or the widget that starts the flow. If the request names a
screen, Glob for its file directly; if it names a user-facing flow
("checkout"), start from the route table and follow forward.

**Step 1 — Trace the widget tree.** Read the screen widget. List every state
holder it subscribes to, every child widget that subscribes independently, and
every navigation call (`context.go`/`push`) it can trigger and where each
leads. What you grep for depends on the lock in `techContext.md`:

| Locked style | Subscriptions look like |
|---|---|
| **Cubit / Bloc** | `BlocBuilder`, `BlocSelector`, `BlocListener`, `BlocConsumer`, `context.watch<T>()`, `context.select`; actions via `context.read<T>().method()` |
| **Riverpod** | `ref.watch`, `ref.listen`; actions via `ref.read(p.notifier).method()` |

**Step 2 — Trace each state holder.** Read the backing Cubit/Bloc/Notifier.
List its public methods — for Bloc, its events and their handlers — note which
user action triggers each, and what each does.

**Step 3 — Trace each method to its repository call(s).** List which repository
methods are called, in what order, and what happens on success vs failure
(re-fetch, optimistic update, rollback). Note how failure travels: an emitted
error state for Cubit/Bloc, `AsyncValue.error` for Riverpod — per
`06-flutter-error-guard`, there should be exactly one such channel.

**Step 4 — Trace the repository to its data source.** API endpoint(s) hit,
local cache/database involved (if any), and how errors are mapped.

**Step 5 — Produce the trace report.**

```markdown
## Feature Trace — Checkout Flow

**Entry:** `GoRoute('/checkout')` → `CheckoutScreen`
(`lib/features/checkout/presentation/checkout_screen.dart`)

**Widget tree → state holders:**
- `CheckoutScreen` subscribes to `CheckoutCubit` (state: `CheckoutState`)
- `PromoCodeField` subscribes to `PromoValidationCubit`, calls
  `applyPromo(code)` on the checkout holder on submit

**State holder → repository:**
- `CheckoutCubit.submitOrder()` calls
  `OrderRepository.createOrder(cart, paymentMethod)`, then on success calls
  `CartNotifier.clear()` and navigates to `/orders/:id/confirmation`
- `CheckoutNotifier.applyPromo()` calls `PromoRepository.validate(code)`,
  updates `CheckoutState.discount` on success, leaves state unchanged +
  surfaces a `SnackBar` on `PromoInvalidException`

**Repository → data source:**
- `OrderRepository` → `POST /orders` via the shared pinned `Dio` client
- `PromoRepository` → `GET /promos/:code/validate`

**Files touched by this flow (8):** [list]
```

---

## Example

Request: `/feature-trace "checkout"` — produces the report above, giving
the caller everything needed before making a change (`/impact-analysis`
next) without re-deriving it from scratch.
