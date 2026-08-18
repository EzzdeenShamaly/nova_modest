---
name: flutter-state-gen
description: "Scaffolds the state-owning layer between a screen and a repository, in whichever style this project locked in via /platform-init: a Riverpod Notifier/AsyncNotifier, or a Bloc, or a Cubit with its state class. Use when asked to add state management, a cubit, a bloc, a notifier, or a provider. Invoked as /flutter-state-gen."
---

# Skill: flutter-state-gen

**Invocation:** `/flutter-state-gen [what the state is for]`

---

## Overview

Generates the state-owning layer between a screen and a repository — the
thing that holds what the screen displays and exposes the operations it can
trigger.

**Which shape it generates is not a decision this skill makes.** Read
`memory-bank/techContext.md` for the locked choice and follow it. If
`techContext.md` is missing or still a template, stop and run
`/platform-init` — generating against a guess is how a codebase ends up with
two state-management styles.

**Memory references:** `memory-bank/techContext.md` (locked style),
`memory-bank/architecture.md` (folder placement).

**Guard rules:** `02-flutter-state-guard.md` (primary — this is the installed
variant for this project), `01-flutter-architecture-guard.md` (placement),
`06-flutter-error-guard.md` (how a failure is resolved).

---

## Steps

### Step 0 — Find the pattern

Run `pattern-scout` for the nearest existing state class in the same or an
adjacent feature. Match: naming, state-class shape, how repository failures
are resolved, and folder placement. On a project scaffolded by
`/flutter-project-init`, the reference feature is the answer.

### Step 1 — Read the locked style

| `techContext.md` says | Generate | Into |
|---|---|---|
| Cubit | `Cubit<XState>` + sealed `XState` | `features/<f>/presentation/cubit/` |
| Bloc | `Bloc<XEvent, XState>` + sealed events + sealed states | `features/<f>/presentation/bloc/` |
| Riverpod | `Notifier` / `AsyncNotifier` | `features/<f>/application/` |

### Step 2 — Generate the state class

**Cubit / Bloc** — sealed hierarchy per `02-flutter-state-guard.md`, with
**four states minimum** for anything that loads data: `Loading`, `Error`,
`Empty`, `Loaded`. `Equatable` with **every** field listed in `props`.

```dart
sealed class OrdersState extends Equatable {
  const OrdersState();
  @override
  List<Object?> get props => const [];
}
final class OrdersLoading extends OrdersState { const OrdersLoading(); }
final class OrdersEmpty   extends OrdersState { const OrdersEmpty(); }
final class OrdersError extends OrdersState {
  const OrdersError(this.failure);
  final Failure failure;
  @override List<Object?> get props => [failure];
}
final class OrdersLoaded extends OrdersState {
  const OrdersLoaded(this.orders);
  final List<Order> orders;
  @override List<Object?> get props => [orders];
}
```

**Riverpod** — the `AsyncValue<T>` type argument *is* the state. Choose
`AsyncNotifier` when the initial value requires an async fetch (almost every
data-backed screen) and plain `Notifier` for synchronous state (a filter
selection, a wizard step).

### Step 3 — Generate the state owner

**Cubit:**
```dart
class OrdersCubit extends Cubit<OrdersState> {
  OrdersCubit(this._repository) : super(const OrdersLoading());
  final OrderRepository _repository;      // interface, never the Impl

  Future<void> load() async {
    emit(const OrdersLoading());
    final result = await _repository.getOrders();
    emit(result.fold(
      (failure) => OrdersError(failure),
      (orders) => orders.isEmpty ? const OrdersEmpty() : OrdersLoaded(orders),
    ));
  }
}
```

**Bloc:** the same body, moved into an `on<OrdersRequested>` handler
registered in the constructor, with a transformer chosen deliberately —
`droppable()` for refresh, `sequential()` for mutations, `restartable()` for
search.

**Riverpod:**
```dart
@riverpod
class Orders extends _$Orders {
  @override
  Future<List<Order>> build() => ref.watch(orderRepositoryProvider).getOrders();

  Future<void> cancel(String id) async {
    final repo = ref.read(orderRepositoryProvider);
    state = const AsyncLoading<List<Order>>().copyWithPrevious(state);
    state = await AsyncValue.guard(() async {
      await repo.cancelOrder(id);
      return repo.getOrders();
    });
  }
}
```

`copyWithPrevious` keeps existing data visible during a refresh instead of
flashing a blank spinner.

### Step 4 — Error handling follows the locked style, not preference

| Style | Shape |
|---|---|
| Cubit / Bloc | Repository returns `Result<T>`; the state owner `fold`s it. **No `try`/`catch` here** — a `catch` means the data layer is leaking. |
| Riverpod | Repository throws `Failure`; `AsyncValue.guard` catches it. **No `Result` wrapper** — it would create a second, always-empty error channel. |

See `06-flutter-error-guard.md` §4.

### Step 5 — Depend on the interface

Take `OrderRepository` (abstract) in the constructor, or read
`orderRepositoryProvider`. Never construct `OrderRepositoryImpl()` inside the
state owner — that is exactly what makes it untestable.

### Step 6 — Lifecycle safety

- **Cubit / Bloc:** `if (isClosed) return;` before any `emit` that follows an
  await which can outlive the screen. Register as a **factory** in `get_it`,
  not a singleton, unless the state is genuinely app-global.
- **Riverpod:** `ref.onDispose` for anything needing teardown; prefer
  `ref.invalidateSelf()` over manual re-derivation.

### Step 7 — Generate the test

| Style | Shape |
|---|---|
| Cubit / Bloc | `bloc_test` — `act` triggers, `expect` asserts the **full emitted sequence** (`[Loading, Loaded]`, `[Loading, Error]`) with a mocked repository |
| Riverpod | `ProviderContainer` with the repository provider overridden to a fake; assert the `AsyncValue` sequence |

Cover success **and** at least one failure path per public operation, plus
the empty case. Per `04-flutter-test-guard.md`.

### Step 8 — Update the memory-bank

Note the new state class and its feature in `activeContext.md`.

---

## Example

Request: "Add state for the shopping cart with add/remove."

Output (Cubit project): `lib/features/cart/presentation/cubit/cart_cubit.dart`
and `cart_state.dart` (sealed, four states), plus
`test/features/cart/presentation/cart_cubit_test.dart` asserting the emitted
sequence for load, add, remove, and one failure path.

---

## Rules

- **Never introduce a second state-management style.** If the request implies
  one (`"add a Riverpod provider"` in a Cubit project), stop and ask — that is
  an architecture change, not a generation task.
- **Never put `BuildContext`, navigation, or `SnackBar` inside a state
  owner.** It emits state; the widget reacts.
- **Never omit a field from `props`.** Two unequal states comparing equal is
  among the hardest bugs in this stack to trace.
