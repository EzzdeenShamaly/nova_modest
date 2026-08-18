# Architecture

**Tier 2 — human-authored.** Read by `01-flutter-architecture-guard.md`, every
`flutter-*-gen` skill, and `pattern-scout`. Not auto-regenerated: "what is our
folder convention" is a decision, not an observation.

`/platform-init` and `/flutter-project-init` fill this once on a new project.
After that first fill the write guard blocks agent edits — later changes get
proposed to you in chat instead.

---

## Layout convention

`[feature-first | layered (presentation/domain/data)]`

## Folder structure

```
[paste the actual lib/ tree shape here]
```

## Layer rules

`[what may import what; the one-way dependency direction]`

## State placement

`[where feature-local state lives vs genuinely app-wide state]`

## Error handling

`[Result<Failure,T> + fold, or thrown Failure + AsyncValue.guard — see
06-flutter-error-guard.md. Note where the shared Failure hierarchy lives.]`

## Networking

`[the ApiClient seam; which file is allowed to import dio]`

## Routing convention

`[go_router file location, shell route usage, guard/redirect pattern for auth]`

## Use-cases

`[whether this project uses a usecases/ layer, and the bar for adding one]`

---

> EXAMPLE — what a filled-in version looks like (delete this block once filled):
>
> ## Layout convention
> Feature-first, three layers. Each feature under `lib/features/<name>/` has
> `data/`, `domain/`, `presentation/`. Shared infrastructure in `lib/core/`.
>
> ## Folder structure
> ```
> lib/
>   core/
>     error/      failure.dart, result.dart
>     network/    api_client.dart, dio_api_client.dart, interceptors/
>     theme/      app_theme.dart
>     widgets/    failure_view.dart, empty_view.dart
>     di/         injection.dart
>   features/
>     orders/
>       data/         datasources/, repositories/
>       domain/       entities/, repositories/, usecases/
>       presentation/ cubit/, screens/, widgets/
>   app.dart
>   main.dart
>   router/       app_router.dart, routes.dart
> ```
>
> ## Layer rules
> `presentation → domain → data`, one way only. A widget never imports from
> `data/`. A repository implementation never imports a widget. `domain/`
> imports nothing from the other two.
>
> ## State placement
> One Cubit per screen concern, in that feature's `presentation/cubit/`.
> Registered as a `get_it` **factory**, provided at the route via
> `BlocProvider`. Only `AuthCubit` and `ThemeCubit` are app-wide singletons.
>
> ## Error handling
> `Result<Failure, T>` returned by repositories, folded in the Cubit. One
> sealed `Failure` hierarchy in `core/error/failure.dart` for the whole app —
> no per-feature error types. Rendered by the shared `FailureView`.
>
> ## Networking
> `core/network/dio_api_client.dart` is the only file permitted to import
> `dio`. Everything above it depends on the `ApiClient` interface. One client
> instance, plus a second interceptor-free one used solely by token refresh.
>
> ## Routing convention
> Single `GoRouter` in `lib/router/app_router.dart`; paths and names as
> constants in `routes.dart`. Authenticated screens nest under a
> `StatefulShellRoute` for the bottom nav. Auth guard is a top-level
> `redirect` reading `AuthCubit`.
>
> ## Use-cases
> `usecases/` exists but is empty by default. Add one only when logic spans
> more than one repository or encodes a real domain rule — never as a
> pass-through wrapper around a single repository call.
