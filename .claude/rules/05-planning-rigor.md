---
description: Force rigorous, options-driven elicitation before any plan or task board is produced
applies-to: planning and breakdown requests
---

## What This Rule Does

Whenever the agent is about to produce a plan, a task board, or any
"here's what I'll build" output — whether triggered by `/work-breakdown` or
by an ad-hoc request like "how should I architect the offline sync for this
feature" — it must run a structured elicitation pass first. A plan produced
without this pass is invalid and must be redone.

This rule exists because the expensive mistakes in a mobile app are the ones
baked into structure early — wrong state-management boundary, wrong
navigation shape, wrong offline/caching strategy — that are cheap to get
right during planning and expensive to undo after three more screens depend
on the wrong shape.

---

## Triggers

**Skill invocations:** `/work-breakdown`, `/flutter-screen-gen` when the
screen has non-trivial state or navigation implications, `/release-safety`.

**Natural-language patterns** (partial match, case-insensitive): "plan",
"approach", "how should I structure", "architecture for", "what's the best
way to", "options for", "should I use provider/notifier for", "which
pattern".

---

## Mandatory Elicitation Protocol

### Rule 1 — Scale Question Count to Complexity

| Feature Scope | Minimum Questions |
|---|---|
| Small widget/screen, no new state | 3 |
| Standard feature (screen + provider + repository) | 5 |
| Cross-cutting (auth, offline sync, navigation restructure) | 7 |

### Rule 2 — Every Question Must Be Options-Driven

```
Q[n]: [the decision to be made]

Option A — [short label]:
  [1-2 sentence description]
  Trade-off: [what you gain | what you give up]

Option B — [short label]:
  [1-2 sentence description]
  Trade-off: [what you gain | what you give up]

Recommended: Option [X] — [reasoning tied to memory-bank/architecture.md if
a precedent exists, otherwise to techContext.md's stated constraints]

(You can also specify your own approach instead of A/B.)
```

Options must be genuinely mutually exclusive with a real trade-off each —
never a strawman option that exists only to make another look obviously
right.

### Rule 3 — Never Bundle Two Decisions Into One Question

```
❌ BAD: "Q2: Should this use a Notifier and also persist to secure storage?"
✅ GOOD: Q2: State management approach for this screen?
         Q3: Does this data need to persist across app restarts?
```

### Rule 4 — Recap Before Advancing

```markdown
## Decisions Recap — [Feature Name]

| # | Question | Choice | Option |
|---|---|---|---|
| Q1 | State holder | Feature-scoped, per the locked style | Option A |
| Q2 | Persistence | flutter_secure_storage (contains a token) | Option B |

Ready to generate. Please confirm with "yes" or "go ahead", or correct any
decision above.
```

The agent waits for explicit confirmation before generating files or writing
the task board.

### Rule 5 — `work-breakdown` Must Offer Slicing Variants

After clarification, `/work-breakdown` presents 2-3 named slicing options
(e.g. vertical by screen, horizontal by layer, risk-first) with a trade-off
table before writing the task board — mirroring the plan-variant step other
platforms in this repo use. The board is never written until the user picks
a variant.

---

## Violations

### ❌ Violation — Open-Ended Question With No Options

**Trigger:** Agent asks: *"Q2: How do you want to manage state for this?"*

**What's wrong:** The user now has to think through the option space from
scratch — precisely what they came to the agent to avoid.

**Correct form:**
```
Q2: State management approach for the search results screen?

Option A — Reuse the existing search state holder, add a results field:
  One holder owns the whole search screen. Matches how product-list is
  already structured.
  Trade-off: Consistent with the rest of the app, fewer moving parts |
  The state class grows; a change to either concern rebuilds both

Option B — A second holder scoped to results only:
  Results are independent of the query input and can be tested alone.
  Trade-off: Narrower rebuilds, isolated tests | One more holder to wire
  and provide, diverges from product-list

Recommended: Option A — memory-bank/architecture.md records one state holder
per screen as the standing convention; a second one here would be the only
place in the codebase that splits.
```
