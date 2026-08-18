---
description: Enforce Cubit state-management conventions — sealed state classes, one Cubit per screen concern, no business logic in widgets, setState only for ephemeral UI
applies-to: state holders, and any widget that reads or emits state
---

## What This Rule Does

This project is locked to **Cubit** (`flutter_bloc`) by `/platform-init`.
This rule keeps state management consistent: how state classes are shaped,
what belongs in a Cubit versus a widget, and how a Cubit reaches the data
layer.

> Cubit and Bloc share a package. Introducing a `Bloc` for a genuinely
> event-driven flow later is allowed, but it is a deliberate decision to
> record in `memory-bank/architecture.md` — not something a generator does on
> its own.

---

## State classes are sealed, not boolean soup

```dart
// ❌ One class with flags — every widget re-derives what the state actually is
class OrdersState {
  final bool isLoading;
  final List<Order>? orders;
  final String? error;      // isLoading && error != null is representable
}                           // and meaningless. So is orders == null && !isLoading.

// ✓ Sealed hierarchy — illegal states are unrepresentable, switch is exhaustive
sealed class OrdersState extends Equatable {
  const OrdersState();
  @override
  List<Object?> get props => const [];
}

final class OrdersInitial extends OrdersState { const OrdersInitial(); }
final class OrdersLoading extends OrdersState { const OrdersLoading(); }
final class OrdersEmpty   extends OrdersState { const OrdersEmpty(); }

final class OrdersLoaded extends OrdersState {
  const OrdersLoaded(this.orders);
  final List<Order> orders;
  @override
  List<Object?> get props => [orders];
}

final class OrdersError extends OrdersState {
  const OrdersError(this.failure);
  final Failure failure;
  @override
  List<Object?> get props => [failure];
}
```

- Every state class is `const`-constructible and extends `Equatable` (or uses
  `freezed`, if the repo already does so for states — check
  `memory-bank/techContext.md`). Without value equality, `emit` of an equal
  state still rebuilds the tree.
- **Four states minimum** for anything that loads data: loading, error,
  empty, loaded. `Empty` as a distinct state — not `Loaded([])` — because the
  UI for "no orders yet" is a different design than an empty list.
- `props` must list **every** field. A field omitted from `props` makes two
  different states compare equal and the UI silently stops updating — one of
  the hardest bugs in this stack to find.

---

## The Cubit owns logic; the widget owns layout

```dart
class OrdersCubit extends Cubit<OrdersState> {
  OrdersCubit(this._repository) : super(const OrdersInitial());
  final OrderRepository _repository;   // the interface, never the Impl

  Future<void> load() async {
    emit(const OrdersLoading());
    final result = await _repository.getOrders();
    emit(result.fold(
      (failure) => OrdersError(failure),
      (orders) => orders.isEmpty ? const OrdersEmpty() : OrdersLoaded(orders),
    ));
  }

  Future<void> cancel(String orderId) async {
    final current = state;
    if (current is! OrdersLoaded) return;      // guard against illegal transitions
    final result = await _repository.cancelOrder(orderId);
    result.fold(
      (failure) => emit(OrdersError(failure)),
      (_) => load(),
    );
  }
}
```

- **No `try`/`catch` in a Cubit.** The repository returns `Result<T>` and the
  Cubit folds it (`06-flutter-error-guard.md`). A `catch` here means the data
  layer is leaking exceptions.
- **Depend on the abstract repository**, never construct
  `OrderRepositoryImpl()` inside the Cubit — that is what makes it testable.
- **Never emit after close.** For a Cubit whose work can outlive its screen,
  guard with `if (isClosed) return;` before `emit` in an async continuation.
- A Cubit does not import `flutter/material.dart`. No `BuildContext`, no
  navigation, no `SnackBar` from inside a Cubit — it emits a state and the
  widget reacts.

---

## Reading state in widgets

| Need | Use |
|---|---|
| Rebuild UI when state changes | `BlocBuilder<OrdersCubit, OrdersState>` |
| Side effect only (snackbar, navigation, dialog) | `BlocListener` |
| Both | `BlocConsumer` |
| Call a method, no rebuild | `context.read<OrdersCubit>().load()` |
| Rebuild on one derived field only | `BlocSelector` |

```dart
BlocBuilder<OrdersCubit, OrdersState>(
  builder: (context, state) => switch (state) {
    OrdersInitial() || OrdersLoading() => const Center(child: CircularProgressIndicator()),
    OrdersEmpty() => const EmptyOrdersView(),
    OrdersError(:final failure) => FailureView(
        failure: failure,
        onRetry: () => context.read<OrdersCubit>().load(),
      ),
    OrdersLoaded(:final orders) => ListView.builder(
        itemCount: orders.length,
        itemBuilder: (_, i) => OrderTile(order: orders[i]),
      ),
  },
)
```

- Use an **exhaustive `switch`** over the sealed state, never a chain of
  `if (state is X)` with a trailing `else`. The `else` is what silently
  swallows a state added six months later.
- ❌ `context.watch()` inside a callback, or `context.read()` in `build()`
  when the widget should rebuild — the two are not interchangeable.
- ❌ Business logic inside `builder:` — computing a total, deciding
  eligibility, filtering a list. That belongs in the Cubit or a domain
  usecase (`01-flutter-architecture-guard.md`).

---

## Providing a Cubit

- Scope a Cubit to the **narrowest** widget that needs it — usually the
  screen, via `BlocProvider(create: (_) => sl<OrdersCubit>()..load())`. A
  Cubit registered app-wide keeps stale state alive between visits.
- Register the Cubit as a **factory** in `get_it`, not a singleton, unless
  the state is genuinely app-global (auth, theme). A singleton Cubit behind a
  screen is the usual cause of "the previous user's data flashed for a
  moment."
- `BlocProvider.value` when passing an existing Cubit to a pushed route —
  never `create:` again, which would build a second instance.
- Multiple Cubits on one screen is fine and usually better than one Cubit
  with six unrelated concerns.

---

## `setState` Boundaries

`setState` is acceptable only for state that is:

- Local to a single widget (never read by a sibling or ancestor), and
- Ephemeral (does not need to survive a rebuild, does not need testing
  independently of the widget)

Fine: a password field's obscure toggle, an `ExpansionTile`'s open flag, an
`AnimationController` listener.

Not fine: form validation results, anything persisted, data fetched from a
repository, anything another widget reacts to. Those go through the Cubit.

---

## Relationship to Other Rules

- `01-flutter-architecture-guard.md` — *where* Cubits and repositories live.
- `06-flutter-error-guard.md` — the `Result`/`Failure` shape this rule folds.
- `04-flutter-test-guard.md` — `bloc_test` conventions for asserting the
  emitted state sequence.
