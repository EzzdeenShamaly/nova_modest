---
description: Enforce Bloc state-management conventions — sealed events and states, event handlers registered in the constructor, correct transformers, no business logic in widgets
applies-to: state holders, and any widget that reads or emits state
---

## What This Rule Does

This project is locked to **Bloc** (`flutter_bloc`) by `/platform-init`.
The **state** contract is stated in full below — sealed hierarchies,
`Equatable` with complete `props`, four states minimum, exhaustive `switch` in
the UI — and this file then covers what Bloc adds on top: events, handlers,
and transformers.

> A Cubit is still the right choice for a screen with no meaningful event
> semantics. Mixing the two in one project is allowed; mixing them for one
> screen's single concern is not.

---

## Events are sealed and named for what happened

```dart
sealed class OrdersEvent extends Equatable {
  const OrdersEvent();
  @override
  List<Object?> get props => const [];
}

final class OrdersRequested extends OrdersEvent { const OrdersRequested(); }
final class OrdersRefreshed extends OrdersEvent { const OrdersRefreshed(); }

final class OrderCancelled extends OrdersEvent {
  const OrderCancelled(this.orderId);
  final String orderId;
  @override
  List<Object?> get props => [orderId];
}
```

- Name events for **what happened**, past tense (`OrdersRequested`,
  `OrderCancelled`) — not for what the bloc should do (`LoadOrders`,
  `DoCancel`). An event is a fact reported to the bloc; the bloc decides the
  response.
- One event class per distinct user intent. Do not add a `type` enum field to
  one generic event class — it defeats the exhaustive `switch`.

## States: identical rules to Cubit

Sealed, `Equatable`, complete `props`, `const`-constructible, and a distinct
`Empty` state:

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
- **Four states minimum** for anything that loads data: loading, error, empty,
  loaded. `Empty` as a distinct state — not `Loaded([])` — because the UI for
  "no orders yet" is a different design than an empty list.
- `props` must list **every** field. A field omitted from `props` makes two
  different states compare equal and the UI silently stops updating — one of
  the hardest bugs in this stack to find.

---

## Handlers are registered in the constructor

```dart
class OrdersBloc extends Bloc<OrdersEvent, OrdersState> {
  OrdersBloc(this._repository) : super(const OrdersInitial()) {
    on<OrdersRequested>(_onRequested);
    on<OrdersRefreshed>(_onRefreshed, transformer: droppable());
    on<OrderCancelled>(_onCancelled, transformer: sequential());
  }

  final OrderRepository _repository;

  Future<void> _onRequested(OrdersRequested event, Emitter<OrdersState> emit) async {
    emit(const OrdersLoading());
    final result = await _repository.getOrders();
    emit(result.fold(
      (failure) => OrdersError(failure),
      (orders) => orders.isEmpty ? const OrdersEmpty() : OrdersLoaded(orders),
    ));
  }
}
```

- **Every event type gets exactly one `on<T>` registration.** Two handlers for
  one event, or an event with no handler, both fail silently at runtime.
- **No `try`/`catch` in a handler.** The repository returns `Result<T>`, the
  handler folds it (`06-flutter-error-guard.md`).
- **Never `emit` after the handler returns.** Do not store the `Emitter` or
  use it inside an un-awaited callback — use `await emit.forEach(...)` /
  `await emit.onEach(...)` for stream-driven state instead.
- A Bloc does not import `flutter/material.dart`.

## Transformers — pick deliberately

The default is `concurrent()`, which is wrong more often than it is right.

| Transformer | Use for |
|---|---|
| `sequential()` | Mutations that must not interleave (cancel, submit, pay) |
| `droppable()` | Pull-to-refresh, "load" buttons — ignore taps while one is in flight |
| `restartable()` | Search-as-you-type, filter changes — only the newest matters |
| `concurrent()` | Genuinely independent events only |

`restartable()` plus a `debounce` `EventTransformer` is the standard shape
for a search field. Without it, a fast typist produces one request per
keystroke and the responses arrive out of order.

---

## Reading state in widgets

Identical to Cubit: `BlocBuilder` / `BlocListener` / `BlocConsumer` /
`BlocSelector`, with an exhaustive `switch` over the sealed state.

The one difference: widgets dispatch **events**, they do not call methods.

```dart
// ✓
context.read<OrdersBloc>().add(const OrdersRefreshed());

// ❌ — a public method on a Bloc bypasses the event pipeline,
//     the transformer, and the observable transition log
context.read<OrdersBloc>().refresh();
```

A Bloc exposes no public methods other than the inherited API. If a screen
needs to call a method, that screen wanted a Cubit.

---

## Providing a Bloc

Same rules as Cubit: narrowest scope, `get_it` **factory** not singleton,
`BlocProvider.value` when passing to a pushed route, multiple small Blocs
over one large one.

```dart
BlocProvider(
  create: (_) => sl<OrdersBloc>()..add(const OrdersRequested()),
  child: const OrdersView(),
)
```

---

## `setState` Boundaries

Ephemeral, widget-local UI state only — a text field's focus, an expansion
tile's open/closed, an animation controller. Anything the app has a rule about
goes through the Bloc.

---

## Relationship to Other Rules

- `01-flutter-architecture-guard.md` — *where* Blocs and repositories live.
- `06-flutter-error-guard.md` — the `Result`/`Failure` shape handlers fold.
- `04-flutter-test-guard.md` — `bloc_test` conventions: `act` dispatches
  events, `expect` asserts the emitted state sequence.
