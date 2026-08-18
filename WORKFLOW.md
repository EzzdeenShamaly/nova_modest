# WORKFLOW

How to actually work with this kit, start to finish. This is the file to read
when you forget what the next command is — everything else is reference.

---

## 0 · Install into a project

Copy four things into the repo root:

```
.claude/        skills, rules, agents, hooks, settings
memory-bank/    the agent's persistent context
CLAUDE.md       the contract
WORKFLOW.md     this file
```

All four. `.claude/` alone is not enough — `CLAUDE.md` is what the agent reads
first, and `memory-bank/` is where every decision gets written down.

---

## 1 · New project

```bash
flutter create my_app && cd my_app
# copy the four items above into the root
```

Then, in Claude Code:

| Step | Command | What happens |
|---|---|---|
| 1 | `/platform-init` | **Asks one question:** Cubit, Bloc, or Riverpod. Derives errors, DI, folders, tests. Writes `techContext.md` + `architecture.md`, installs the matching state rule, deletes the other two. |
| 2 | `/flutter-project-init auth` | Builds `lib/core/` (error, network, theme, DI), the router, the app shell, `pubspec.yaml`, `analysis_options.yaml`, and **one complete reference feature**. Runs `build_runner`, `analyze`, `test`. |

You are now ready to build. Step 2's reference feature matters more than it
looks: every later generator matches against it via `pattern-scout`, so the
conventions are set by real working code rather than by generic boilerplate.

---

## 2 · Existing project

| Step | Command | What happens |
|---|---|---|
| 1 | `/platform-init` | Detects what you already use, states its finding, asks only for confirmation |
| 2 | `/repo-discovery` | Scans `pubspec.yaml` + `lib/` → `.claude/cache/repo-map.json` |
| 3 | `/context-sync` | Fills Tier 1 (`techContext`, `progress`, `activeContext`) from the scan |
| 4 | *(with the agent)* | Fill the three Tier 2 files — it asks, you answer, it writes |

**Do not skip step 4.** `architecture.md`, `domainRules.md`, and
`securityStandards.md` ship as templates. Left unfilled, roughly half of this
kit's value never activates — every generator reads them as ground truth.
The write guard allows exactly one agent write to each while it is still the
template, then locks them.

Run **`/kit-doctor`** when you are done. It reports which Tier 2 files are
genuinely filled versus still holding placeholders, whether the installed rules
match your locks, and whether anything else drifted. An unfilled Tier 2 file is
the single most common reason this kit underperforms, and it looks identical to
a working setup from the outside.

---

## 3 · Daily work — one screen

You describe the screen. That is the whole input.

> "Order history screen — fetches `/orders`, pull-to-refresh, cancel an order."

| | What happens | Who |
|---|---|---|
| 1 | Memory digest + always-on rules injected | hook, automatic |
| 2 | `Matched skill: flutter-screen-gen` announced | agent |
| 3 | Options offered — fetch on entry vs passed in, pagination, what a failure looks like | agent |
| 4 | You pick | **you** |
| 5 | `pattern-scout` finds the nearest existing screen, returns a pattern report | subagent |
| 6 | Generates: entity → repository → cubit/notifier → screen → route → 4 tests | agent |
| 7 | `activeContext.md` + `progress.md` updated | agent |
| 8 | You review the diff and run the app | **you** |

One sentence in, one approval, one review. That is the loop.

### Individual generators

Use these when you want one piece rather than a whole screen:

| Need | Command |
|---|---|
| Reusable widget (card, tile, button variant) | `/flutter-widget-gen` |
| Cubit / Bloc / Notifier | `/flutter-state-gen` |
| Repository + data source | `/flutter-repository-gen` |
| freezed entity | `/flutter-model-gen` |
| go_router route | `/flutter-route-gen` |
| Networking layer (once per project) | `/flutter-network-gen` |
| Backfill tests onto existing code | `/flutter-test-gen` |
| Localize strings | `/flutter-l10n-gen` |
| Something is broken and you don't know why | `/flutter-debug` |
| The kit seems to be ignoring conventions | `/kit-doctor` |

---

## 4 · Bigger than one screen

```
/work-breakdown "checkout flow"
```

Offers three slicing options — vertical (by screen), horizontal (by layer),
risk-first — with tradeoffs. You pick; it produces a task board where every
task is **≤ 8 files, ≤ 2 layers, with a Verify command**. Then work the board
one task at a time.

Vertical slicing is the default recommendation for screen-by-screen review:
each task is a complete, demoable screen rather than a layer that does nothing
on its own.

---

## 5 · Understanding code before changing it

| Question | Command |
|---|---|
| How does this screen work today? | `/feature-trace "checkout"` |
| What breaks if I change this? | `/impact-analysis "rename OrderStatus.pending"` |

Run `/impact-analysis` **before** editing shared code, not after something
breaks. It classifies every reference as breaking / behavioural / cosmetic and
includes generated-code and golden-test fallout.

---

## 6 · Before you merge

| Command | Checks |
|---|---|
| `/flutter-architecture-audit` | Layering violations, logic in widgets, `dio` above core |
| `/flutter-performance-audit` | Missing `const`, over-broad state subscriptions, `ListView` vs `.builder` |
| `/flutter-accessibility-audit` | Semantics labels, 48×48 tap targets, unlabeled fields |
| `/flutter-dependency-audit` | Unused, stale, duplicate-purpose packages |

## 7 · Before you ship

| Command | Purpose |
|---|---|
| `/production-readiness-review` | GO / NO-GO: crash reporting live in release builds, offline handling per screen, store submission checklist |
| `/release-safety` | Staged rollout plan, feature flags with an owner and expiry, and what a store rollback does **not** undo |

---

## What runs without you typing anything

- **Session start** — memory-bank digest injected; a missing `/platform-init`
  lock is flagged loudly
- **Every message** — the four always-on rules: read memory, offer options,
  minimal diff, verify existence before referencing
- **Every write** — secrets blocked, `repo-map.json` protected, filled Tier 2
  files protected
- **`flutter pub add`, `git push`, `flutter build`** — permission prompt first

---

## Rules of thumb

1. **`/platform-init` before anything.** A generator running against an
   unlocked stack is guessing, and guesses become two conventions.
2. **Fill the Tier 2 files.** The single most common way this kit
   underperforms is templates left unfilled.
3. **Let `pattern-scout` run.** It is the difference between code that matches
   your app and code that matches a tutorial.
4. **Review screen by screen.** The kit is built to produce reviewable
   increments; a 40-file diff is a failure of `/work-breakdown`, not of you.
5. **If a hook blocks something, read why.** It is enforcing a rule you set.

---

## Command index

**Bootstrap** — `platform-init`, `flutter-project-init`, `repo-discovery`,
`context-sync`

**Generate** — `flutter-screen-gen`, `flutter-widget-gen`, `flutter-state-gen`,
`flutter-repository-gen`, `flutter-model-gen`, `flutter-route-gen`,
`flutter-network-gen`, `flutter-test-gen`, `flutter-l10n-gen`

**Understand** — `feature-trace`, `impact-analysis`, `work-breakdown`

**Diagnose** — `flutter-debug`

**Audit** — `flutter-architecture-audit`, `flutter-performance-audit`,
`flutter-accessibility-audit`, `flutter-dependency-audit`

**Ship** — `production-readiness-review`, `release-safety`

**Maintain** — `kit-doctor`
