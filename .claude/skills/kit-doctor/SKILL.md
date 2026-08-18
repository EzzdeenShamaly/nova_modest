---
name: kit-doctor
description: "Verifies that flutter-kit is correctly installed and configured in this project: kit version, the platform-init locks, which rules are present versus expected, whether memory-bank Tier 2 is actually filled in or still holding template placeholders, repo-map freshness, and leftover debug instrumentation. Read-only — reports findings and recommends fixes, changes nothing. Use when the agent seems to be ignoring conventions, after updating the kit, or when picking a project back up after a break. Invoked as /kit-doctor."
---

# Skill: kit-doctor

**Invocation:** `/kit-doctor`

---

## Overview

The kit asserts that this project has a locked convention, filled memory files
and a matching rule set. Nothing verified any of that after installation.

This skill checks. It is **read-only**: it reports and recommends, it does not
repair. The most common way this kit underperforms is not a bug — it is a
correct installation whose `memory-bank/` Tier 2 files were never filled in, so
every skill falls back to generic Flutter defaults while appearing to work.

**Contract:** read-only. Never writes, never runs `/platform-init` on its own.

**Memory references:** all of `memory-bank/`.

---

## Steps

**Step 0 — Version.** Read `.claude/.kit-version` and compare with the
`VERSION` in the kit source if reachable. Report both. A project with no
`.kit-version` was installed by 1.0.0 or copied by hand — note it, since it
means none of the 1.1.0 fixes are present.

**Step 1 — Locks.** Read `memory-bank/techContext.md`. Confirm each is present
and specific, not a placeholder:

- `Locked by: /platform-init`
- State management — one of Cubit / Bloc / Riverpod
- Data sources — REST / Firebase / Supabase / hybrid
- Locales — single / multi

A missing lock means `/platform-init` never ran, or ran and failed to write.
This is the highest-severity finding: every generator branches on these.

**Step 2 — Rules match the locks.** List `.claude/rules/*.md` and check
against what the locks imply:

| Expected | Condition |
|---|---|
| `02-flutter-state-guard.md` present, and **no** `02-state-guard-*.md` variants | always, after `/platform-init` |
| `07-flutter-direction-guard.md` | always |
| `08-flutter-baas-security-guard.md` | present ⇔ a BaaS source is locked |
| `11-flutter-l10n-guard.md` | present ⇔ locales are multi |
| `00`–`06`, `09`, `10` | always |

Report both directions. A rule that should be there and is not is a gap; a rule
that should not be there and is costs context every session and may push the
agent toward a convention this project does not use.

Leftover `02-state-guard-cubit.md` **alongside** `02-flutter-state-guard.md`
means `/platform-init` half-completed — flag it explicitly.

**Step 3 — Tier 2 memory actually filled.** For `memory-bank/architecture.md`,
`domainRules.md` and `securityStandards.md`, check for template residue:

- any `[bracket slot]` still present
- any `> EXAMPLE —` block still present
- file length close to the shipped template's

Report each as `filled` / `partial` / `still template`. **This is the finding
that matters most in practice.** A project with three template files gets
plausible-looking generic output from every skill, with nothing to indicate the
conventions were never recorded.

**Step 4 — repo-map freshness.** Check `.claude/cache/repo-map.json`. Report
its age in days and whether it exists at all. Older than ~14 days, or missing
on a project with more than a handful of Dart files, means `/repo-discovery`
should run before the next generation task.

**Step 5 — Hooks wired.** Read `.claude/settings.json` and confirm
`SessionStart`, `PreToolUse` and `Stop` all point at files that exist in
`.claude/hooks/`. A hook referenced but missing fails silently every session.

**Step 6 — Working-tree hygiene.**

- `grep -rn "DEBUG-TEMP" lib/ test/` — any hit means a `/flutter-debug` session
  was never closed out (`09-minimal-changes`)
- `.gitignore` covers `.claude/settings.local.json` and `.claude/cache/`
- `.claude/settings.local.json`, if present, contains no absolute path from
  another machine
- `.github/workflows/flutter-ci.yml` present, or note that nothing verifies
  this project between the editor and `main`

**Step 7 — Report.**

```markdown
## kit-doctor

**Kit version:** 1.1.0 (`.claude/.kit-version`)

### Locks
| Lock | Value | Status |
|---|---|---|
| State management | Cubit | ✅ |
| Data sources | Firebase (auth) + REST (data) | ✅ |
| Locales | single (en) | ✅ |

### Rules — 10 present, expected 10
✅ 00 01 02 03 04 05 06 07 08 09 10 · `11-l10n` correctly absent (single locale)

### Memory bank
| File | Status |
|---|---|
| architecture.md | ✅ filled |
| domainRules.md | ⚠️ still template — 6 `[bracket slots]` remain |
| securityStandards.md | ✅ filled |

### Hygiene
| Check | Status |
|---|---|
| repo-map.json | ⚠️ 23 days old — run `/repo-discovery` |
| Hooks wired | ✅ 3/3 |
| DEBUG-TEMP | ✅ clean |
| .gitignore | ✅ covers kit entries |
| CI workflow | ❌ absent — nothing checks this repo before `main` |

### Recommended, in order
1. Fill `memory-bank/domainRules.md` — the biggest single lever on output
   quality, and it is currently generic
2. Run `/repo-discovery`
3. Copy `.github/workflows/flutter-ci.yml` from the kit
```

**Step 8 — Regenerate the inventory numbers** if asked. Counts belong in
`README.md` and drift the moment anything is added:

```bash
echo "Skills:    $(ls -d .claude/skills/*/ | wc -l)"
echo "Rules:     $(ls .claude/rules/*.md | wc -l)"
echo "Subagents: $(ls .claude/agents/*.md | wc -l)"
echo "Hooks:     $(ls .claude/hooks/*.mjs | wc -l) files"
```

---

## Rules

- **Read-only.** Never write, never delete a stray rule file, never run
  `/platform-init`. Report and recommend; the user decides.
- **Severity honestly.** A template `domainRules.md` outranks a stale
  repo-map. Order the recommendations by impact on output quality, not by the
  order the checks ran.
- **No false green.** If a check cannot be performed — file unreadable, not a
  git repo — say `unknown`, not `✅`.

---

## Related

`/repo-discovery` · `/context-sync` · `/platform-init`
