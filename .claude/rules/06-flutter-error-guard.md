---
description: One app-wide Failure hierarchy, mapped once at the network seam, resolved once at the state layer — never re-invented per repository or per screen
applies-to: repositories, data sources, state holders, anything that can fail
---

## What This Rule Does

Error handling is the single convention most likely to fragment across a
Flutter codebase: one repository throws `DioException`, another returns
`null`, a third invents its own `OrderNetworkException`, and the UI ends up
with four different ways of showing "something went wrong."

This rule fixes the shape once. Three non-negotiables:

1. **One `Failure` hierarchy for the whole app** — not one per feature, not
   one per repository.
2. **Transport errors are mapped exactly once**, at the network seam. Nothing
   above `lib/core/network/` ever sees a `DioException`.
3. **The state layer is where a failure becomes UI** — widgets never
   `try`/`catch`.

---

## 1. The `Failure` hierarchy — `lib/core/error/failure.dart`

Sealed, app-wide, small. Dart 3 makes `switch` over it exhaustive, so adding
a case forces every handler to be updated at compile time.

```dart
sealed class Failure {
  const Failure(this.message);
  final String message;
}

final class NetworkFailure extends Failure {          // no connectivity, timeout
  const NetworkFailure([super.message = 'No internet connection.']);
}
final class ServerFailure extends Failure {           // 5xx
  const ServerFailure(super.message, {this.statusCode});
  final int? statusCode;
}
final class NotFoundFailure extends Failure {         // 404
  const NotFoundFailure([super.message = 'Not found.']);
}
final class UnauthorizedFailure extends Failure {     // 401 / 403
  const UnauthorizedFailure([super.message = 'Session expired.']);
}
final class ValidationFailure extends Failure {       // 422 + field errors
  const ValidationFailure(super.message, {this.fieldErrors = const {}});
  final Map<String, String> fieldErrors;
}
final class CacheFailure extends Failure {
  const CacheFailure([super.message = 'Local data unavailable.']);
}
final class UnknownFailure extends Failure {
  const UnknownFailure([super.message = 'Something went wrong.']);
}
```

**Do not** add a feature-specific subclass unless the UI genuinely renders it
differently. `OrderNotFoundFailure` and `ProductNotFoundFailure` both render
"Not found" — they are one `NotFoundFailure`.

### `message` is a fallback, not the UI string

`Failure.message` exists so an unhandled case still shows *something*. A
screen that cares about wording switches on the type and uses a localized
string, per `flutter-l10n-gen`. Never surface a raw server message directly
to the user — it leaks implementation detail and is unlocalized.

---

## 2. `Result<T>` — `lib/core/error/result.dart`

Used by **Bloc and Cubit projects**. Riverpod projects skip this file
entirely (see §4).

```dart
sealed class Result<T> {
  const Result();
}

final class Ok<T> extends Result<T> {
  const Ok(this.value);
  final T value;
}

final class Err<T> extends Result<T> {
  const Err(this.failure);
  final Failure failure;
}

extension ResultX<T> on Result<T> {
  R fold<R>(R Function(Failure) onErr, R Function(T) onOk) => switch (this) {
        Ok(:final value) => onOk(value),
        Err(:final failure) => onErr(failure),
      };
}
```

**Do not add `dartz` or `fpdart` for this.** Twenty lines of Dart 3 sealed
classes give the same exhaustiveness with an API the whole team already
reads, and no dependency to keep current. `10-evidence-and-dependency-guard.md`
applies: adding either package needs an explicit request from the user.

---

## 3. Mapping happens once, at the network seam

`lib/core/network/api_client.dart` declares the interface. Only its Dio-backed
implementation imports `dio`, and it is the **only** place `DioException` is
caught in the entire app.

```dart
// lib/core/network/api_client.dart — the seam
abstract class ApiClient {
  Future<T> get<T>(String path, {Map<String, dynamic>? query});
  Future<T> post<T>(String path, {Object? body});
  Future<T> put<T>(String path, {Object? body});
  Future<void> delete(String path);
}
```

```dart
// lib/core/network/dio_api_client.dart — the ONLY file that knows about dio
Never _mapAndThrow(DioException e) {
  throw switch (e.type) {
    DioExceptionType.connectionTimeout ||
    DioExceptionType.receiveTimeout ||
    DioExceptionType.sendTimeout ||
    DioExceptionType.connectionError => const NetworkFailure(),
    DioExceptionType.badResponse => switch (e.response?.statusCode) {
        401 || 403 => const UnauthorizedFailure(),
        404 => const NotFoundFailure(),
        422 => ValidationFailure.fromResponse(e.response),
        final c? when c >= 500 => ServerFailure('Server error.', statusCode: c),
        _ => const UnknownFailure(),
      },
    _ => const UnknownFailure(),
  };
}
```

### Consequences that are checked in review

- ❌ `import 'package:dio/dio.dart'` anywhere under `lib/features/` — a
  repository importing `dio` means the seam has been bypassed.
- ❌ `on DioException catch` outside `lib/core/network/`.
- ❌ A second `Dio` instance constructed anywhere — it escapes the
  interceptors (auth, refresh, logging) and any pinning
  (`03-flutter-security-guard.md`).

`Failure` is thrown by the client and converted to a `Result` by the
repository (Bloc/Cubit), or left to propagate to `AsyncValue.guard`
(Riverpod). Either way, it crosses no layer as a transport-level type.

---

## 4. Resolving a failure — per state-management style

### Bloc / Cubit — repository returns `Result`, cubit folds

```dart
// data layer
@override
Future<Result<List<Order>>> getOrders() async {
  try {
    final data = await _api.get<List<dynamic>>('/orders');
    return Ok(data.map(Order.fromJson).toList());
  } on Failure catch (f) {
    return Err(f);
  }
}
```

```dart
// presentation layer
Future<void> load() async {
  emit(const OrdersLoading());
  final result = await _repository.getOrders();
  emit(result.fold(
    (failure) => OrdersError(failure),
    (orders) => orders.isEmpty ? const OrdersEmpty() : OrdersLoaded(orders),
  ));
}
```

The cubit never has a `try`/`catch`. If it does, the repository is leaking.

### Riverpod — repository throws, `AsyncValue.guard` catches

```dart
// data layer — no Result wrapper; the Failure propagates
@override
Future<List<Order>> getOrders() async {
  final data = await _api.get<List<dynamic>>('/orders');
  return data.map(Order.fromJson).toList();
}
```

```dart
// application layer
state = await AsyncValue.guard(() => _repository.getOrders());
// UI: ordersAsync.when(error: (e, _) => ErrorView(e as Failure), ...)
```

Wrapping a `Result` inside an `AsyncValue` is a defect, not a style choice —
it produces two error channels where one is always empty.

---

## 5. The UI contract

Every screen that can fail renders **four** states explicitly: loading, error
(with a retry action), empty, and data. A screen handling only the happy path
is incomplete — this is also what `flutter-screen-gen` Step 5 and
`production-readiness-review` check.

```dart
// One shared widget renders any Failure — not a bespoke error UI per screen
class FailureView extends StatelessWidget {
  const FailureView({required this.failure, this.onRetry, super.key});
  final Failure failure;
  final VoidCallback? onRetry;
  // switch (failure) { ... } → icon + localized message + retry affordance
}
```

`UnauthorizedFailure` is the one case that is usually **not** rendered
inline — it belongs to the refresh-then-logout flow in the auth interceptor
(`flutter-network-gen`), so the user lands on the login screen instead of an
error card.

---

## 6. What is never acceptable

| ❌ | Why |
|---|---|
| `catch (e) { print(e); }` swallowing a failure | The user sees a frozen screen and nothing is logged upstream |
| Returning `null` to signal an error | Loses the reason; forces null-checks at every call site |
| `try`/`catch` inside a widget's `build()` | Errors are state, not layout (`01-flutter-architecture-guard.md`) |
| A raw `e.toString()` shown to the user | Leaks stack/implementation detail, unlocalized |
| A per-feature `Failure` subclass with no distinct UI | Hierarchy sprawl with no benefit |
| Logging a `Failure` that contains a token or PII | `03-flutter-security-guard.md` |

---

## 7. BaaS sources — Firebase and Supabase

Applies only when `techContext.md` locks a Firebase or Supabase data source.
Everything in §1, §2, §4, §5 and §6 is unchanged: the same `Failure`
hierarchy, the same single mapping point, the same resolution at the state
layer. Only the exception types differ, because there is no `dio`.

The seam moves from `lib/core/network/api_client.dart` to the data-source
class. That class is the **only** file in the project allowed to import
`supabase_flutter` or `cloud_firestore`.

### Supabase

| Caught | Mapped to |
|---|---|
| `PostgrestException` code `42501` | `UnauthorizedFailure` — **RLS policy rejected this**, not a permissions bug in the app |
| `PostgrestException` code `PGRST116` | `NotFoundFailure` — no row matched |
| `PostgrestException` code `23505` | `ValidationFailure` — unique constraint |
| `PostgrestException` code `23503` | `ValidationFailure` — foreign key |
| `AuthException` | `UnauthorizedFailure` |
| `StorageException` | `ServerFailure` |
| `SocketException` / `ClientException` | `NetworkFailure` |
| anything else | `UnknownFailure` — log it, never swallow it |

### Firebase

| Caught | Mapped to |
|---|---|
| `FirebaseException.code == 'permission-denied'` | `UnauthorizedFailure` — **a Security Rule rejected this** |
| `'not-found'` | `NotFoundFailure` |
| `'already-exists'` | `ValidationFailure` |
| `'unavailable'` / `'deadline-exceeded'` | `NetworkFailure` |
| `'unauthenticated'` | `UnauthorizedFailure` |
| `'resource-exhausted'` | `ServerFailure` — quota |
| `FirebaseAuthException` | `UnauthorizedFailure`, with `code` preserved for the UI message |
| anything else | `UnknownFailure` |

### The row that matters

`permission-denied` and `42501` are **authorisation failures, not network
failures**. Mapping either to `NetworkFailure` shows the user "check your
connection" for a missing security rule, and hides a real defect — possibly
for months, because the app looks like it works on the developer's account.

When `/flutter-debug` sees either code, the first hypothesis is the rule set
or policy, not the query. See `08-flutter-baas-security-guard`.

### Offline

Firestore ships offline persistence; Supabase does not. Do not map a queued
offline write to a failure in a Firebase project — it is not one. Do not
assume a Supabase project has any offline behaviour unless it was built.

## Relationship to Other Rules

- `08-flutter-baas-security-guard.md` — the rules that produce §7's
  authorisation failures in the first place.
- `01-flutter-architecture-guard.md` — where each layer lives; this rule
  governs what crosses between them when something goes wrong.
- `02-flutter-state-guard.md` — the state-management style, which determines
  which branch of §4 applies.
- `03-flutter-security-guard.md` — the pinned/authenticated client this
  rule's seam wraps.
- `10-evidence-and-dependency-guard.md` — the reason `dartz`/`fpdart` are not
  introduced by default.
