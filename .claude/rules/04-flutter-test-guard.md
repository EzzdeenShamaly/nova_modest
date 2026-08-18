---
description: Widget/unit test conventions — pumpWidget with this project's state-management test harness, golden tests where applicable, test behaviour not implementation
applies-to: anything under test/
---

## What This Rule Does

Applies to `_test.dart` files. Keeps tests asserting observable behavior
(rendered output, navigation, provider state as seen by consumers) rather
than internal implementation details that break on harmless refactors.

## Widget Tests: fake the state owner, never the network

A widget test injects a **fake state owner** — it never lets the real
repository- or API-backed one run. The mechanism depends on the locked style
(`memory-bank/techContext.md`); the rule is the same either way.

**Cubit / Bloc** — `MockCubit` + `whenListen` from `bloc_test`:

```dart
testWidgets('shows cart total for two items', (tester) async {
  final cubit = MockCartCubit();
  whenListen(
    cubit,
    Stream.value(CartLoaded([item1, item2])),
    initialState: const CartLoading(),
  );

  await tester.pumpWidget(
    MaterialApp(
      home: BlocProvider<CartCubit>.value(value: cubit, child: const CartScreen()),
    ),
  );
  await tester.pumpAndSettle();

  expect(find.text('\$24.00'), findsOneWidget);
});
```

**Riverpod** — `ProviderScope` with explicit `overrides`:

```dart
await tester.pumpWidget(
  ProviderScope(
    overrides: [cartProvider.overrideWith(() => FakeCart([item1, item2]))],
    child: const MaterialApp(home: CartScreen()),
  ),
);
```

- **All four states get a test**, not just the happy path: loading, error
  (including tapping retry), empty, and populated. A screen test covering
  only `Loaded` is the most common form of false coverage in this stack.
- `pumpAndSettle()` after actions that trigger animations or async state
  changes; plain `pump()` when asserting an intermediate (e.g. loading) state
  before it resolves.
- Never construct a real repository, and never let a widget test make a
  network call — that is a flaky integration test wearing the wrong name.

## Golden Tests

Where the repo already has golden tests set up (a `goldens/` directory and
`matchesGoldenFile` usage present), add a golden test for new visually
significant widgets that have no existing coverage — a card, a custom
button variant, an empty/error state illustration. Do not introduce golden
testing to a repo that doesn't already have it without asking; it's a
noticeably different CI/tooling commitment (font loading, platform-specific
rendering) that the team should opt into deliberately.

## Test Behavior, Not Implementation

- Assert what the user sees or what the app does (`find.text(...)`,
  `find.byIcon(...)`, navigation to a new route, a repository method being
  called with the right arguments) — not a provider's private field or an
  internal method's call count beyond what proves the behavior.
- For state-owner unit tests, assert on the **emitted state sequence**, not on
  internal helper methods.

**Cubit / Bloc** — `bloc_test`, with the full expected sequence:

```dart
blocTest<CartCubit, CartState>(
  'emits [Loading, Loaded] when addItem succeeds',
  setUp: () => when(() => repo.add(any())).thenAnswer((_) async => const Ok(null)),
  build: () => CartCubit(repo),
  act: (cubit) => cubit.addItem(item1),
  expect: () => [const CartLoading(), CartLoaded([item1])],
  verify: (_) => verify(() => repo.add(item1)).called(1),
);

blocTest<CartCubit, CartState>(
  'emits [Loading, Error] when the repository fails',
  setUp: () => when(() => repo.add(any()))
      .thenAnswer((_) async => const Err(NetworkFailure())),
  build: () => CartCubit(repo),
  act: (cubit) => cubit.addItem(item1),
  expect: () => [const CartLoading(), const CartError(NetworkFailure())],
);
```

The `expect` list is the **whole** sequence. Asserting only the final state
hides a missing `Loading` emission, which is exactly the bug that makes a
screen look frozen.

**Riverpod** — `ProviderContainer` with the repository overridden:

```dart
test('addItem appends to cart and persists', () async {
  final container = ProviderContainer(
    overrides: [cartRepositoryProvider.overrideWithValue(fakeRepo)],
  );
  addTearDown(container.dispose);

  await container.read(cartProvider.notifier).addItem(item1);

  expect(container.read(cartProvider).value, [item1]);
  expect(fakeRepo.savedItems, [item1]);
});
```

### Equality is a prerequisite, not a detail

A `bloc_test` `expect` list compares states by value. If a state class extends
`Equatable` and a field is missing from `props`, two different states compare
equal, the test passes, and the UI silently stops updating in production.
When a state assertion behaves inexplicably, check `props` first.

## Mocking

Use `mocktail` or `mockito` (whichever is already in `pubspec.yaml` under
`dev_dependencies` — confirm before generating, per
`10-evidence-and-dependency-guard.md`) for repository/API-client fakes in
unit tests. Prefer a small hand-written fake over a mock when the interface
is small and the test benefits from readable, explicit behavior.

## Integration Tests

End-to-end flows (login, checkout) that need a real device/simulator use
the `integration_test` package, kept separate from `test/` (typically
`integration_test/`) so they don't run as part of the fast unit/widget
suite by default.

## Relationship to Other Rules

`02-flutter-state-guard.md` governs how state is structured; this rule
governs how that state is faked and asserted on in tests.
