# Memory Bank

This folder is the agent's persistent context for this Flutter project. It
is split into two tiers because they change at different rates and are
owned by different processes.

There's also a machine-readable layer underneath both tiers —
`.claude/cache/repo-map.json`, owned by `/repo-discovery`. It is the
structural source of truth `/context-sync` reads to produce Tier 1's prose.
Don't hand-edit `repo-map.json` — it's regenerated, not authored.

## Tier 1 — Dynamic (regenerated from the live codebase)

These files describe **the actual state of this specific repo right now**.
They are written by `/context-sync` on first run and kept current by
`00-memory-think.md` after every significant change. Edit
`activeContext.md` freely — it's meant to be touched constantly.

| File | Owner | Refresh trigger |
|---|---|---|
| `techContext.md` | `/context-sync` | New package, SDK upgrade, state-management convention change |
| `progress.md` | `/context-sync`, `00-memory-think.md` | Task completed/started |
| `activeContext.md` | `00-memory-think.md` | Every session |

## Tier 2 — Static reference (written once by the team, rarely regenerated)

These are **standards and conventions**, not a snapshot of code. A human
decides what they say; skills and rules read them as ground truth to check
generated code against. Regenerating these automatically would be wrong —
"what's our folder convention" is a decision, not an observation.

| File | Read by |
|---|---|
| `architecture.md` | `01-flutter-architecture-guard.md`, all `flutter-*-gen` skills, `pattern-scout` |
| `domainRules.md` | all `flutter-*-gen` skills, `feature-trace`, `impact-analysis` |
| `securityStandards.md` | `03-flutter-security-guard.md`, `mobile-security-auditor` |

## The lock line

`techContext.md` carries one line nothing else may rewrite:

```
**Locked by:** `/platform-init`
```

It records that a human chose this project's state-management style. Until it
is present, every `flutter-*-gen` skill refuses to generate state code, and
the `SessionStart` hook says so loudly. `/context-sync` refreshes everything
*around* that line on each sync and never touches the line itself.

## First run

1. `/platform-init` — one question (Cubit / Bloc / Riverpod). Writes the lock
   into `techContext.md` and the decided structure into `architecture.md`.
2. **New project:** `/flutter-project-init` builds the tree and one reference
   feature. **Existing project:** `/repo-discovery` scans the codebase into
   `.claude/cache/repo-map.json`, then `/context-sync` populates Tier 1 from
   that scan.
3. Fill the remaining Tier 2 files. They ship with `> EXAMPLE —` blocks so the
   format is clear, but the *content* is a starting point, not your project's
   truth. Replace them and delete the `> EXAMPLE —` blocks.

> The write guard permits exactly **one** agent write to each Tier 2 file,
> while it is still the shipped template — that is how step 1 and 2 bootstrap
> them. Once filled, they are blocked and later changes get proposed to you in
> chat instead.

## Why "domainRules.md" and not "businessRules.md"

A to-do app and a fintech app both have domain rules, but "business rules"
carries a regulated-industry connotation this kit does not assume. Same role,
more neutral name.
