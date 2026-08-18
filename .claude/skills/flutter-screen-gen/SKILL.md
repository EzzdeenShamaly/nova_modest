---
name: flutter-screen-gen
description: "Generates a full Flutter screen in one pass: the screen widget, its backing state class (Cubit/Bloc/Notifier per this project's convention), and the go_router route registration, handling loading/error/empty/data states explicitly. Use when asked to build a new screen or page. Invoked as /flutter-screen-gen."
---

# Skill: flutter-screen-gen

**Invocation:** `/flutter-screen-gen [screen name/description]`

---

## Overview

`flutter-screen-gen` generates a full screen: the screen widget itself, the
state class backing it, and the `go_router` route registration wiring it in
— in one pass, so the screen is reachable and functional immediately rather
than left as an orphaned widget.

The state shape follows whatever `/platform-init` locked for this project.
Read `memory-bank/techContext.md` before generating; if it is missing or
still a template, stop and run `/platform-init`.

**Memory references:** `memory-bank/architecture.md`,
`memory-bank/techContext.md`, `memory-bank/domainRules.md`

**Guard rules:** `01-flutter-architecture-guard.md`,
`02-flutter-state-guard.md`, `04-flutter-test-guard.md`,
`06-flutter-error-guard.md`.

**Depends on:** `flutter-state-gen` (Step 2), `flutter-route-gen` (Step 4) —
this skill orchestrates both rather than duplicating their logic.

---

## Steps

**Step 0 — Find the pattern.** Run `pattern-scout` for the nearest existing
screen in the same feature area (or the closest structural analog) to match
folder layout, state-class usage, loading/error handling shape, and
`AppBar`/scaffold conventions already established.

**Step 1 — Confirm scope with the user (planning-rigor applies).** If the
screen has non-trivial state or navigation implications, run the elicitation
pass from `05-planning-rigor.md` before generating (data fetched on entry vs
passed in, pagination, what a failure should look like).

**Step 2 — Generate the state owner.** Delegate to `flutter-state-gen` — a
Cubit, a Bloc, or an `AsyncNotifier`, per the locked style. It owns the
screen's data and the operations the screen triggers.

**Step 3 — Generate the screen widget.**

Every screen renders **four** states explicitly: loading, error with a retry
action, empty, and data. A screen that only handles the happy path is
incomplete. Failures render through the shared `FailureView`
(`06-flutter-error-guard.md` §5), not a bespoke error widget per screen.

```dart
// Cubit / Bloc — exhaustive switch over the sealed state, no trailing else
class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Orders')),
        body: BlocBuilder<OrdersCubit, OrdersState>(
          builder: (context, state) => switch (state) {
            OrdersInitial() || OrdersLoading() =>
              const Center(child: CircularProgressIndicator()),
            OrdersEmpty() => const EmptyView(message: 'No orders yet.'),
            OrdersError(:final failure) => FailureView(
                failure: failure,
                onRetry: () => context.read<OrdersCubit>().load(),
              ),
            OrdersLoaded(:final orders) => ListView.builder(
                itemCount: orders.length,
                itemBuilder: (_, i) => OrderTile(order: orders[i]),
              ),
          },
        ),
      );
}
```

```dart
// Riverpod — .when covers three states; the empty case is handled inside data:
final ordersAsync = ref.watch(ordersProvider);
return Scaffold(
  appBar: AppBar(title: const Text('Orders')),
  body: ordersAsync.when(
    loading: () => const Center(child: CircularProgressIndicator()),
    error: (e, _) => FailureView(
      failure: e is Failure ? e : const UnknownFailure(),
      onRetry: () => ref.invalidate(ordersProvider),
    ),
    data: (orders) => orders.isEmpty
        ? const EmptyView(message: 'No orders yet.')
        : ListView.builder(
            itemCount: orders.length,
            itemBuilder: (_, i) => OrderTile(order: orders[i]),
          ),
  ),
);
```

Keep the screen presentational: no repository calls, no business logic in
`build()`, no `try`/`catch` (`01-flutter-architecture-guard.md`). Extract
list items and non-trivial subtrees into `const`-constructible widgets via
`flutter-widget-gen`.

**Step 4 — Register the route.** Delegate to `flutter-route-gen` to add the
`GoRoute` entry, including any path parameters and the `redirect`/guard logic
if the screen requires auth. For Cubit/Bloc, wire the `BlocProvider` at the
route so the Cubit is scoped to the screen and disposed with it.

**Step 5 — Generate tests.** A widget test per `04-flutter-test-guard.md`
covering all four states — loading, error + retry tap, empty, and populated —
with the state owner faked (`MockCubit`/`whenListen`, or `ProviderScope`
overrides). Not just the happy path.

**Step 6 — Update memory-bank.** Note the new screen and its route in
`memory-bank/activeContext.md` per the always-on `00-memory-think` rule.

---

## Example

Request: "Generate an order history screen."

Output: `lib/features/orders/presentation/order_history_screen.dart`, the
state holder in `lib/features/orders/application/` named per the locked style
(`order_history_cubit.dart`, `order_history_bloc.dart` or
`order_history_provider.dart`, plus any `.g.dart`/`.freezed.dart` companion),
a `GoRoute` added to the router config, and
`test/features/orders/order_history_screen_test.dart` covering all four states
of that holder's state contract.
