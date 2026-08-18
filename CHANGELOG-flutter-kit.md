# Changelog

All notable changes to flutter-kit. Newest first.

The kit version lives in `VERSION` and is copied into an installed project as
`.claude/.kit-version`. `install.ps1` refuses to downgrade a project silently.

---

## 1.1.0

Audit release. Nine findings from a full file-by-file review of 1.0.0, fixed.

### Added

- **`.claude/rules/07-flutter-direction-guard.md`** — direction-neutral layout
  APIs (`EdgeInsetsDirectional`, `AlignmentDirectional`, `TextAlign.start`).
  Always on, costs an English-only app nothing, and keeps the door open for
  RTL. Carries an explicit `// direction-fixed:` escape hatch for genuinely
  physical layouts (waveforms, chart axes, code views).
- **`.claude/rules/08-flutter-baas-security-guard.md`** — Firestore Security
  Rules / Supabase RLS as first-class security surface. Installed only when
  `/platform-init` locks the project to a BaaS data source.
- **`.claude/rules/11-flutter-l10n-guard.md`** — full localisation pipeline.
  Installed only when the project locks `locales: multi`.
- **`.claude/skills/flutter-debug/SKILL.md`** — structured diagnosis:
  reproduce first, one stated hypothesis at a time, fix at the layer that owns
  the cause, failing test before fix. **Stops after two failed hypotheses**
  instead of guessing a third time.
- **`.claude/skills/kit-doctor/SKILL.md`** — verifies an installed kit:
  version, locks, rule count, memory-bank Tier 2 completion, leftover
  `DEBUG-TEMP`.
- **`.claude/hooks/verify-session.mjs`** + `Stop` hook — runs `dart format`,
  `flutter analyze` and (when tests changed) `flutter test` at the end of any
  session that touched Dart. Feedback in the same session, not after a push.
- **`.github/workflows/flutter-ci.yml`** — format, analyze, test, plus three
  greps that enforce rules `flutter analyze` cannot see: architecture seam
  violations, `service_role` keys in client code, and leftover `DEBUG-TEMP`.
- **`VERSION`**, **`CHANGELOG.md`**, **`.gitignore`**.
- `06-flutter-error-guard` §7 — `FirebaseException` and `PostgrestException`
  to `Failure` mapping tables. §3 (Dio) is untouched and remains primary.
- `09-minimal-changes` — a defined exception for temporary debug
  instrumentation, which previously had no legitimate path.
- `/platform-init` now asks two more questions (locales, data source) in the
  same interrogation round, and derives the rest.

### Fixed

- **`install.ps1`: personal settings leak.** `settings.local.json` was shipped
  in the kit and only deleted when `.claude/` did not already exist — so the
  second install onto any project left the kit author's absolute paths and
  pre-approved commands in place. Deletion is now unconditional and happens
  before the project's own file is restored from backup.
- **`install.ps1`: dead `$preserve` hashtable.** Built, then never read; its
  paths were invalidated two lines later by `Move-Item`. Removed.
- **`flutter-test-gen`: Bloc/Cubit path was missing.** The frontmatter promised
  `bloc_test`; the body gave `ProviderScope` and `ProviderContainer` only.
- **`flutter-performance-audit`: step 2 was Riverpod-only.** `buildWhen`,
  `BlocSelector` and `context.select` added.
- **`feature-trace`: Riverpod-only tracing.** `BlocBuilder` / `context.read`
  path added.
- **`flutter-dependency-audit`: referenced a "stated Riverpod default"** that
  1.0.0 had already removed. Now reads the lock in `techContext.md`.
- **`flutter-model-gen`: framed the project as "Riverpod-based".**
- **`04-flutter-test-guard`: description named `ProviderScope`** regardless of
  the locked style.
- **`platform-init`: "HTTP: `dio`, always".** A Firebase or Supabase project
  has no HTTP client; this line made the agent generate a dead `ApiClient`.
- **`flutter-network-gen`** now refuses when the lock says BaaS instead of
  generating an unusable transport layer.
- Riverpod-only examples in `flutter-screen-gen`, `flutter-architecture-audit`,
  `production-readiness-review` and `work-breakdown` made neutral.
- **`README.md` inventory table** claimed 10 rules (actual: 11 shipped, 9 after
  `/platform-init` prunes) and 2 hooks (3 files, 2 wired in 1.0.0).

### Removed

- **Cursor `.mdc` frontmatter** (`globs:`, `alwaysApply:`) from all 11 rules.
  Claude Code has no glob-scoped rule loader, so these fields described a
  mechanism that does not exist — and `alwaysApply: false` on
  `06-flutter-error-guard` actively understated a rule the kit depends on.
  Replaced with a human-readable `applies-to:` line.
- `.claude/settings.local.json` — personal file, now gitignored, never shipped.

### Rule numbering

1.0.0 left 06, 07 and 08 empty; 1.0.0 filled 06. The scheme is now documented
in `CLAUDE.md` and the sequence is continuous for the first time:

```
00–08  domain rules (Flutter/Dart craft)
09–11  agent-discipline and conditional rules
```

---

## 1.0.0

Initial Claude-only kit, derived from the dual-agent `flutter-platform` by way
of a full audit. Removed the `.cursor` mirror and its sync script, fixed
`warn()` silently blocking, fixed Windows drive-letter case comparison
disabling every guard, unblocked the memory-bank Tier 2 bootstrap deadlock,
added `/platform-init`, `06-flutter-error-guard`, `flutter-project-init`,
`flutter-network-gen`, `WORKFLOW.md` and `install.ps1`.
