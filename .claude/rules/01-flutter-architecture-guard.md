---
description: Enforce layered/feature-first architecture boundaries in Flutter apps — no business logic in widgets, correct state-holder placement
applies-to: any file under lib/
---

## What This Rule Does

Applies whenever `.dart` files are in context. Keeps the widget tree as a
rendering layer only, keeps business/domain logic out of widgets, and keeps
providers placed at the layer they belong to instead of being declared
wherever is convenient.

## Layering

Two conventions are common in Flutter apps this platform generates for —
detect which one the repo already uses (`memory-bank/architecture.md`) and
follow it; do not introduce a second convention alongside the first:

**Layered (presentation / domain / data):**
```
lib/
  presentation/   screens, widgets, providers that only read state
  domain/         entities, use-cases, repository interfaces
  data/           repository implementations, API clients, DTOs
```

**Feature-first:**
```
lib/
  features/
    <feature>/
      presentation/   screens, widgets
      application/    providers/notifiers
      domain/         entities
      data/           repository, API client
  shared/            cross-feature widgets, utilities
```

Whichever is in use, the dependency direction is one-way: presentation
depends on application/domain, application/domain depends on data through
an interface, never the reverse. A repository implementation must not import
a widget; a widget must not construct a repository directly — it goes
through a provider.

## No Business Logic in Widgets

A widget's `build()` method should describe layout and delegate everything
else. Concretely, a widget must not:

- Call a repository or API client directly
- Contain a `switch`/branching block that encodes a business rule (e.g. tax
  calculation, eligibility check, retry logic)
- Perform data transformation beyond simple formatting (date/number display)

That logic belongs in the **state holder** (state + orchestration) or a domain
use-case (pure business rule), which the widget then reads. The state holder is
whatever `/platform-init` locked — a Cubit, a Bloc, or a Notifier. The rule is
identical in all three; only the read syntax differs.

**Cubit / Bloc**

```dart
// ❌ Business logic in a widget
class CartTotalText extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final items = context.watch<CartCubit>().state.items;
    final total = items.fold(0.0, (sum, i) => sum + i.price * (1 - i.discount));
    return Text('\$${total.toStringAsFixed(2)}');
  }
}

// ✓ Widget reads a value the state already carries
class CartTotalText extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final total = context.select((CartCubit c) => c.state.total);
    return Text('\$${total.toStringAsFixed(2)}');
  }
}
```

**Riverpod**

```dart
// ❌ Business logic in a widget
class CartTotalText extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(cartProvider);
    final total = items.fold(0.0, (sum, i) => sum + i.price * (1 - i.discount));
    return Text('\$${total.toStringAsFixed(2)}');
  }
}

// ✓ Widget reads a derived value; the calculation lives in the provider
class CartTotalText extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final total = ref.watch(cartTotalProvider);
    return Text('\$${total.toStringAsFixed(2)}');
  }
}
```

The `fold` is the violation in both. Moving it one layer down is the fix in
both.

## State-Holder Placement

Read as "Cubit", "Bloc" or "provider" per the locked style — the placement rule
is the same for all three.

- A state holder used by exactly one feature lives with that feature
  (`features/<feature>/application/` or `presentation/cubit/` per the lock),
  not in a global folder.
- One genuinely shared across features (auth state, theme, locale) lives in
  `shared/` or the app-level folder — confirm this split against
  `memory-bank/architecture.md` before adding a new "shared" one; most are
  not actually shared.
- Repository bindings depend on an abstract interface (`AuthRepository`),
  with the concrete implementation (`AuthRepositoryImpl`,
  `RemoteAuthRepository`) bound in exactly one place — a `get_it` registration
  or a provider override, per the lock. This keeps the data layer swappable
  for tests.

## Relationship to Other Rules

`02-flutter-state-guard.md` governs *how* state is managed once it's
correctly placed by this rule; this rule governs *where* it lives and what
may not touch it directly.
