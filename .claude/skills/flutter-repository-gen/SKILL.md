---
name: flutter-repository-gen
description: "Generates the data layer for a resource: the abstract repository interface in domain/, its implementation backed by the shared ApiClient with typed Failure mapping, and the DI binding, so the presentation layer only depends on the interface. Use when asked to add a repository, API resource, or data source. Invoked as /flutter-repository-gen."
---

# Skill: flutter-repository-gen

**Invocation:** `/flutter-repository-gen [resource name/description]`

---

## Overview

Generates the data layer for one resource: the abstract interface in
`domain/repositories/`, the implementation in `data/repositories/`, its
remote data source, and the DI binding — so the presentation layer only ever
depends on the interface.

**Memory references:** `memory-bank/techContext.md` (locked stack),
`memory-bank/architecture.md` (placement), `memory-bank/domainRules.md`.

**Guard rules:** `01-flutter-architecture-guard.md` (data stays below
domain), `06-flutter-error-guard.md` (the `Failure` shape — canonical),
`03-flutter-security-guard.md` (use the shared authenticated client).

---

## Steps

### Step 0 — Find the pattern

Run `pattern-scout` for the nearest existing repository. Match its method
naming, return shape, and data-source split. On a scaffolded project the
reference feature is the answer.

### Step 1 — Confirm the network seam exists

The implementation depends on `ApiClient` from `lib/core/network/`. If that
does not exist yet, run `/flutter-network-gen` first — do not construct a
`Dio` here. A second client escapes the interceptors and any pinning, which
is a security finding (`03-flutter-security-guard.md`).

### Step 2 — The interface, in `domain/`

The return type follows the locked state-management style:

```dart
// Cubit / Bloc project — Result<T>
abstract class OrderRepository {
  Future<Result<List<Order>>> getOrders();
  Future<Result<Order>> getOrder(String id);
  Future<Result<void>> cancelOrder(String id);
}

// Riverpod project — plain T; a Failure is thrown and AsyncValue.guard catches it
abstract class OrderRepository {
  Future<List<Order>> getOrders();
  Future<Order> getOrder(String id);
  Future<void> cancelOrder(String id);
}
```

The interface lives in `domain/repositories/` and imports nothing from
`data/`. That direction is the whole point of the layer.

### Step 3 — Errors use the app-wide `Failure` — never a bespoke hierarchy

`06-flutter-error-guard.md` §1 defines one sealed `Failure` hierarchy for the
entire app. Use it.

> ❌ Do **not** generate `OrderRepositoryException`,
> `OrderNotFoundException`, `ProductNotFoundFailure`, or any per-resource
> error type. Twenty resources would mean sixty classes that all render the
> same three screens. `NotFoundFailure` already exists and already covers it.

Add a `Failure` subclass only when the **UI renders it differently**, and add
it to `core/error/failure.dart` where every feature can see it.

### Step 4 — The data source

```dart
class OrderRemoteDataSource {
  OrderRemoteDataSource(this._api);
  final ApiClient _api;                 // the interface — never Dio

  Future<List<Order>> fetchOrders() async {
    final data = await _api.get<List<dynamic>>('/orders');
    return data.map((j) => Order.fromJson(j as Map<String, dynamic>)).toList();
  }
}
```

Its only job is path + parsing. It does not catch transport errors — those
were already mapped to `Failure` at the seam.

### Step 5 — The implementation

```dart
// Cubit / Bloc — convert the thrown Failure into a Result at this boundary
class OrderRepositoryImpl implements OrderRepository {
  OrderRepositoryImpl(this._remote);
  final OrderRemoteDataSource _remote;

  @override
  Future<Result<List<Order>>> getOrders() async {
    try {
      return Ok(await _remote.fetchOrders());
    } on Failure catch (f) {
      return Err(f);
    }
  }
}
```

`on Failure` — not `on DioException`, not bare `catch (e)`. A bare catch
swallows genuine programming errors (a `TypeError` from a bad `fromJson`)
and reports them to the user as a network problem.

For **Riverpod**, there is no wrapper: the implementation returns the data
source's result and lets the `Failure` propagate.

### Step 6 — Bind it

- **Cubit / Bloc:** register in `lib/core/di/injection.dart` — data source
  and repository as lazy singletons, bound to the **interface**
  (`sl.registerLazySingleton<OrderRepository>(() => OrderRepositoryImpl(sl()))`).
- **Riverpod:** a provider returning the interface type.

Binding to the interface, not the concrete class, is what lets a test swap in
a fake with one override.

### Step 7 — Offline / caching, only if asked

If the resource needs a local cache, add a separate local data source and
decide the policy explicitly (cache-first, network-first,
stale-while-revalidate) — do not bolt caching silently into the remote path.
Record the choice in `memory-bank/architecture.md`.

### Step 8 — Tests

`test/features/<f>/data/<f>_repository_impl_test.dart` with a mocked
`ApiClient` (`mocktail`):

| Given | Expect |
|---|---|
| Valid JSON | `Ok` with correctly parsed entities |
| `ApiClient` throws `NetworkFailure` | `Err(NetworkFailure)` |
| `ApiClient` throws `NotFoundFailure` | `Err(NotFoundFailure)` |
| Empty list response | `Ok([])` — the state layer decides that means "empty" |

Mock the `ApiClient` interface, never `Dio`. That is the payoff of the seam.

---

## Example

Request: "Generate a repository for fetching and cancelling orders."

Output: `domain/repositories/order_repository.dart` (abstract),
`data/datasources/order_remote_datasource.dart`,
`data/repositories/order_repository_impl.dart`, the DI binding, and the test
above — with no file importing `dio` and no new exception class.

---

## Rules

- **No `dio` import under `lib/features/`.** Ever.
- **No per-resource error hierarchy.** One app-wide `Failure`.
- **No bare `catch (e)`.** Catch `Failure` specifically.
- **Bind to the interface**, never to the implementation type.
