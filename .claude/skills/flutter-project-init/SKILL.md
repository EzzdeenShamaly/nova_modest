---
name: flutter-project-init
description: "Scaffolds a brand-new Flutter app's full structure: lib/core (error, network, theme), the feature-first folder tree, router, app entry, pubspec dependencies, analysis_options, and ONE complete reference feature (model to repository to state to screen to tests) that pattern-scout imitates from then on. Use only on an empty or near-empty project, after /platform-init. Invoked as /flutter-project-init."
---

# Skill: flutter-project-init

**Invocation:** `/flutter-project-init [first feature name]`

**Category:** Bootstrap — runs once, on a new project only.

---

## Overview

Every other skill in this kit assumes there is already code to imitate:
`pattern-scout` looks for "the existing file that proves how this app writes
it today," and the generators follow whatever it finds. On a fresh
`flutter create` there is nothing to find, so the first few features get
generated from generic boilerplate and the conventions drift before they are
ever established.

This skill closes that gap. It produces the folder tree, the shared
infrastructure, and — most importantly — **one complete reference feature**
that becomes the pattern every later feature is matched against.

**Prerequisite:** `/platform-init` must have run. Read
`memory-bank/techContext.md` for the locked state-management choice before
generating anything. If it is missing or still a template, stop and run
`/platform-init` first.

**Guard rules:** all of them, but especially `01-flutter-architecture-guard.md`
(the tree this skill creates *is* the architecture) and
`06-flutter-error-guard.md` (the `Failure` hierarchy it writes is app-wide).

---

## Steps

### Step 1 — Confirm the project is actually new

Count `.dart` files under `lib/`. More than ~5, or an existing `lib/features/`
tree, means this is not a new project: stop and route to `/repo-discovery` +
`/context-sync` instead. Scaffolding over an existing structure is how a
codebase ends up with two conventions.

Confirm the intended first feature with the user before writing anything. If
none was given, ask — the reference feature should be a real one from their
app (`auth`, `orders`, `products`), not a throwaway `example`.

### Step 2 — `pubspec.yaml`

Add only what the locked stack requires. Announce the list and get a
go-ahead; this is the one skill permitted to add packages, and
`10-evidence-and-dependency-guard.md` still applies to anything beyond it.

**Always:**
```yaml
dependencies:
  dio: ^5.7.0
  go_router: ^14.6.0
  freezed_annotation: ^2.4.4
  json_annotation: ^4.9.0
  flutter_secure_storage: ^9.2.2
  intl: ^0.19.0

dev_dependencies:
  build_runner: ^2.4.13
  freezed: ^2.5.7
  json_serializable: ^6.8.0
  mocktail: ^1.0.4
  flutter_lints: ^5.0.0
```

**Cubit / Bloc, add:** `flutter_bloc`, `equatable`, `get_it`, `injectable`;
dev: `bloc_test`, `injectable_generator`.

**Riverpod, add:** `flutter_riverpod`, `riverpod_annotation`; dev:
`riverpod_generator`. **Do not add `get_it`.**

Use the versions actually resolvable for the project's SDK constraint — check
rather than pasting the numbers above verbatim if the SDK differs.

### Step 3 — `lib/core/`

```
lib/core/
  error/
    failure.dart          sealed Failure hierarchy — verbatim from 06-flutter-error-guard.md §1
    result.dart           sealed Result<T> + fold  (Bloc/Cubit only; omit for Riverpod)
  network/
    api_client.dart       abstract ApiClient — the seam
    dio_api_client.dart   the only file in the app that imports dio
    interceptors/
      auth_interceptor.dart
      logging_interceptor.dart
  theme/
    app_theme.dart        light + dark ThemeData, colour scheme, text theme
  widgets/
    failure_view.dart     one error UI for the whole app
  di/
    injection.dart        get_it setup   (Bloc/Cubit only; omit for Riverpod)
  utils/
    extensions.dart
```

Delegate the `network/` contents to `/flutter-network-gen` rather than
duplicating its logic here — that skill owns interceptors, timeouts, and the
`DioException` → `Failure` mapping.

`error/` is written directly from `06-flutter-error-guard.md`. Do not
paraphrase that file's hierarchy; it is the canonical shape.

### Step 4 — App shell

```
lib/
  main.dart               runZonedGuarded → configureDependencies() → runApp
  app.dart                MaterialApp.router, theme, localizationsDelegates
  router/
    app_router.dart       single GoRouter instance, redirect guard hook
    routes.dart           route name/path constants — no magic strings
```

For Riverpod, `main.dart` wraps the app in `ProviderScope`. For Bloc/Cubit,
`main.dart` calls `configureDependencies()` and the app wraps genuinely
app-wide blocs in a `MultiBlocProvider`.

### Step 5 — The reference feature (the point of this skill)

Generate one feature, complete, following the locked conventions:

```
lib/features/<feature>/
  data/
    datasources/    <feature>_remote_datasource.dart
    repositories/   <feature>_repository_impl.dart
  domain/
    entities/       <entity>.dart              freezed, fromJson, one class
    repositories/   <feature>_repository.dart  abstract
    usecases/       .gitkeep                   empty by design — see below
  presentation/
    cubit/          <feature>_cubit.dart, <feature>_state.dart
                    (bloc/ for Bloc, ../application/ for Riverpod)
    screens/        <feature>_screen.dart
    widgets/        <entity>_tile.dart
```

And the tests, mirroring the tree under `test/`:

```
test/features/<feature>/
  data/          repository_impl_test.dart   success + one Failure mapping path
  presentation/  cubit_test.dart             bloc_test: loading → loaded, loading → error
                 screen_test.dart            all four states rendered
```

**`usecases/` ships empty on purpose.** A use-case class that only forwards to
a repository is boilerplate. Add one when there is real logic: composing more
than one repository, or a domain rule the app enforces. Record that decision
in `memory-bank/domainRules.md` when it happens.

The reference feature must be **genuinely complete and passing** — it is the
file `pattern-scout` will point every future generator at. A half-written
example teaches a half-written convention.

### Step 6 — Tooling

- `analysis_options.yaml` — `flutter_lints` plus `prefer_const_constructors`,
  `require_trailing_commas`, `avoid_print`, and `always_declare_return_types`.
- `.gitignore` — confirm it covers `.dart_tool/`, `build/`, `.env`, `*.jks`,
  `*.keystore`, `**/GoogleService-Info.plist`. Ask whether the team commits
  `*.g.dart`/`*.freezed.dart` before ignoring them — both conventions exist.
- `build.yaml` only if a generator needs non-default options.

### Step 7 — Run codegen and verify

```bash
dart run build_runner build --delete-conflicting-outputs
flutter analyze
flutter test
```

Report the real output. If `analyze` or `test` fails, fix it before
reporting completion — a scaffold that does not compile is worse than none,
because every later generator imitates it.

### Step 8 — Write the memory-bank

- `architecture.md` — the tree **as actually created**, not the template.
  Delete every `[slot]` and `> EXAMPLE —` block.
- `activeContext.md` — project scaffolded, reference feature `<name>` in
  place, next step.
- `progress.md` — reference feature Done; planned features as Not Started.

---

## Completion Report

```markdown
## Scaffolded

- Stack: <Cubit> · dio behind ApiClient · freezed · go_router · get_it
- Reference feature: `lib/features/<name>/` — model → repository → cubit → screen → 4 tests
- Shared: `core/error/`, `core/network/`, `core/theme/`, `core/widgets/failure_view.dart`
- `flutter analyze`: <real result> · `flutter test`: <real result>

## Next

`/flutter-screen-gen "<next screen>"` — it will match the reference feature
via pattern-scout.
```

---

## Rules

- **Never run on a non-empty project.** Step 1 is a gate, not a formality.
- **Never invent a package.** Everything added in Step 2 is on the locked
  list; anything else needs the user to ask for it by name.
- **Never leave generated code unverified.** Step 7 runs, and its real output
  is reported — including failures.
