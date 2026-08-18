---
name: flutter-network-gen
description: "Generates the shared networking layer once per project: the ApiClient interface, its Dio-backed implementation, interceptors (auth token, refresh-on-401, logging), BaseOptions/timeouts, and the DioException-to-Failure mapping. Repositories depend on ApiClient, never on Dio directly. Use when a project has no networking layer yet, or when adding auth/refresh/pinning to an existing one. Invoked as /flutter-network-gen."
---

# Skill: flutter-network-gen

**Invocation:** `/flutter-network-gen`

---

## Overview

Generates `lib/core/network/` — the one place in the app that knows HTTP
exists. Every repository talks to the `ApiClient` interface; only
`dio_api_client.dart` imports `dio`.

This runs **once per project** (usually as part of
`/flutter-project-init`). Re-run it later only to add a capability the layer
does not have yet: token refresh, certificate pinning, a retry policy.

**Memory references:** `memory-bank/techContext.md` (locked stack **and data
source**), `memory-bank/securityStandards.md` (pinning, token storage).

**Guard rules:** `06-flutter-error-guard.md` §3 (this skill *is* the seam),
`03-flutter-security-guard.md` (secrets, token storage).

---

## Precondition — read the data-source lock first

**Step 0, before anything else:** read `Data sources:` in
`memory-bank/techContext.md`.

If the lock records **no REST source** — the project is Firebase-only or
Supabase-only — this skill does not apply. Stop and say so:

> `techContext.md` locks this project to **Supabase** with no REST API. There
> is no HTTP layer to generate: the SDK owns transport, and `dio` would be an
> unused dependency. What you likely want is a data source behind the seam —
> `/flutter-repository-gen`, with `06-flutter-error-guard` §7 for the
> exception mapping.
>
> If you *are* adding a REST API alongside Supabase, re-run `/platform-init`
> to record it first, then call me again.

Do not generate a partial layer, do not add `dio` "just in case", and do not
offer to adapt the `ApiClient` interface to wrap a BaaS SDK — that is a
different seam with a different shape, and conflating them produces a wrapper
nobody can test.

If the lock records a **hybrid** source (Firebase Auth + REST data is the
common case), this skill **does** apply — generate the REST layer normally,
and note in the summary that auth tokens come from the BaaS SDK, so the auth
interceptor reads from there rather than from local storage.

---

## Why the seam exists

Without it, every repository catches `DioException` and the whole app is
welded to one HTTP package. With it, swapping `dio` — or stubbing the network
entirely in tests — is one file.

The seam also gives error handling a single choke point: transport failures
become `Failure` values exactly once, so no repository has to remember to do
it, and no screen ever receives a `DioException`.

---

## Steps

### Step 0 — Check what already exists

Glob `lib/core/network/` and grep for `Dio(` across `lib/`. If a client
already exists, do **not** create a second one — extend the existing one.
A second `Dio` instance silently escapes the interceptors and any pinning,
which is a security finding, not a style issue
(`03-flutter-security-guard.md`).

### Step 1 — The interface

```dart
// lib/core/network/api_client.dart
abstract class ApiClient {
  Future<T> get<T>(String path, {Map<String, dynamic>? query, CancelToken? cancel});
  Future<T> post<T>(String path, {Object? body, Map<String, dynamic>? query});
  Future<T> put<T>(String path, {Object? body});
  Future<T> patch<T>(String path, {Object? body});
  Future<void> delete(String path);
}
```

Keep it in terms of paths and Dart types. No `Response`, no `Options`, no
`Dio` type in the signature — the moment one leaks, callers start depending
on it and the seam is gone.

### Step 2 — Base configuration

```dart
BaseOptions(
  baseUrl: const String.fromEnvironment('API_BASE_URL'),
  connectTimeout: const Duration(seconds: 15),
  receiveTimeout: const Duration(seconds: 20),
  sendTimeout: const Duration(seconds: 20),
  headers: {'Accept': 'application/json'},
)
```

`baseUrl` comes from `--dart-define` / `--dart-define-from-file`, never a
committed constant (`03-flutter-security-guard.md`). If the project has
flavors, read the per-flavor value; do not branch on `kDebugMode` to pick a
production URL.

### Step 3 — The implementation and the mapping

`dio_api_client.dart` is the only file in `lib/` that may
`import 'package:dio/dio.dart'`. It wraps every call and maps
`DioException` → `Failure` using the table in `06-flutter-error-guard.md` §3.
Do not restate a different mapping here — that rule is canonical.

```dart
@override
Future<T> get<T>(String path, {Map<String, dynamic>? query, CancelToken? cancel}) async {
  try {
    final res = await _dio.get<T>(path, queryParameters: query, cancelToken: cancel);
    return res.data as T;
  } on DioException catch (e) {
    _mapAndThrow(e);           // Never — throws a Failure
  }
}
```

A `CancelToken` is threaded through so a screen disposed mid-request can
cancel it; `DioExceptionType.cancel` maps to no user-visible error.

### Step 4 — Interceptors

**`auth_interceptor.dart`** — attaches the access token, and refreshes on
401:

- Read the token from `flutter_secure_storage`, never `SharedPreferences`.
- On 401: refresh **once**, retry the original request, and if the refresh
  itself fails, clear the session and emit an unauthenticated signal the
  router's `redirect` guard reacts to.
- **Serialize concurrent refreshes.** Five parallel 401s must trigger one
  refresh, with the other four awaiting it — otherwise the backend sees five
  refresh attempts and usually invalidates the token. Hold a single
  `Future<String?>?` for the in-flight refresh and await it.
- The refresh call itself goes through a **separate** `Dio` instance without
  this interceptor, or it recurses infinitely on a failing refresh endpoint.
  This is the one legitimate second client — document it in the file.

**`logging_interceptor.dart`** — request/response logging in debug builds
only. Redact `Authorization`, `Cookie`, `Set-Cookie`, and any body field
matching `password|token|secret|otp|pin` before writing. Never log a full
auth response.

**Certificate pinning** — only if `memory-bank/securityStandards.md` calls
for it. Do not add a pinning package unasked
(`10-evidence-and-dependency-guard.md`); flag it as a recommendation instead.

### Step 5 — Binding

- **Bloc / Cubit:** register `Dio` and `ApiClient` as lazy singletons in
  `lib/core/di/injection.dart`.
- **Riverpod:** an `apiClientProvider` returning the interface.

Either way there is exactly **one** `ApiClient` instance for the app.

### Step 6 — Tests

`test/core/network/dio_api_client_test.dart` using `DioAdapter`/a mocked
`HttpClientAdapter`, asserting the mapping — not the happy path alone:

| Given | Expect |
|---|---|
| timeout | `NetworkFailure` |
| 401 | refresh attempted, request retried once |
| 401 then failing refresh | `UnauthorizedFailure`, session cleared |
| 404 | `NotFoundFailure` |
| 500 | `ServerFailure` with `statusCode` |
| 422 with field errors | `ValidationFailure` carrying `fieldErrors` |

The concurrent-401 case deserves its own test: two simultaneous failing
requests must produce exactly one refresh call.

---

## Example

Request: "Set up networking for this project."

Output: `api_client.dart`, `dio_api_client.dart`,
`interceptors/auth_interceptor.dart`, `interceptors/logging_interceptor.dart`,
the DI binding, and `test/core/network/dio_api_client_test.dart` covering the
mapping table and the single-refresh guarantee.

---

## Rules

- **One client.** Never construct a second `Dio` outside the documented
  refresh-only instance.
- **No `dio` import above `core/network/`.** If a repository needs something
  the interface does not expose, widen the interface — do not reach past it.
- **No secrets in source.** `baseUrl`, API keys, and pinning material come
  from `--dart-define` or secure storage.
