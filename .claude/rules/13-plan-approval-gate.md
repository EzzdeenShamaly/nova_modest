## What This Rule Does

Before writing **any** code for a new screen or a new feature, the agent presents
an implementation plan and **waits for the user to approve it in words**. No file
is created or edited until that approval arrives.

This is a hard gate, not a preference. It applies even when the task looks small,
even when the design is unambiguous, even when the agent is confident, and even
when the plan turns out to be exactly right. "It was simple" and "the plan was
correct anyway" are not exemptions — the user's ability to redirect the work
*before* it exists is the point, and a correct guess still removes that chance.

`05-planning-rigor` Rule 4 already required a confirmation step. This rule exists
because that requirement was violated in practice: a plan was presented,
clarifying questions were asked and answered, and the answers were treated as
approval. They are not. This file states what approval is and is not, so the
distinction cannot be blurred again.

---

## Scope

**Gated — plan and wait:**

- a new screen or page
- a new feature, or a new layer added to one (bloc, repository, data source)
- a new reusable widget that other screens will adopt
- any change spanning more than one existing file
- any change to routing, DI wiring, the theme, or the design tokens

**Not gated — proceed normally:**

- read-only investigation of any depth (see below)
- a single-file fix the user described concretely and asked for directly
- housekeeping the user asked for by name (`/context-sync`, `/repo-discovery`)
- a follow-up the user explicitly ordered in the same breath ("fix the overflow
  you just introduced")

When unsure whether something is gated, it is gated. The cost of an unnecessary
plan is one message; the cost of unwanted code is a review, a revert, and lost
trust.

---

## What Is NOT Approval

This list is the substance of the rule. Every entry has been mistaken for
approval at least once.

| Not approval | Why it isn't |
|---|---|
| **Answers to clarifying questions** (including `AskUserQuestion` responses) | They settle decisions *inside* the plan. Deciding which colour to use is not agreeing that the work should start. |
| **Sending a design link, screenshot, or spec** | That is input for the plan, not consent to build from it. |
| **"continue"** after a tool interruption or a truncated turn | That resumes the *current* activity. If the current activity was planning, it means keep planning. |
| **Silence, or a message on another topic** | Absence of objection is not consent. |
| **Approval given for a previous screen** | Approval is per unit of work and does not carry forward. |
| **Approving one decision inside the plan** ("use the terracotta") | Scoped to that decision only. |
| **The agent's own judgement that the plan is obviously right** | Confidence is not permission. |
| **A user instruction that merely names the task** ("the splash screen is first") | Naming the work is what starts the *planning*, not the building. |

## What IS Approval

An explicit affirmative from the user, in reply to the presented plan:
"موافق" · "تمام نفّذ" · "ابدأ" · "yes" · "go ahead" · "approved" · "ship it".

A qualified approval is an approval, scoped to the qualification: "موافق بس
استخدم اللون التاني" means start, with that change applied.

If what arrived is genuinely ambiguous, treat it as not approved and ask one
short question: *"Is that a go-ahead to implement?"* One extra message is the
whole cost of getting this right.

---

## Sequence

1. **Investigate** — read the design, trace the existing code, measure, delegate
   to `pattern-scout`. All read-only, no gate.
2. **Present the plan** in the shape below.
3. **If decisions are still open, ask them** — then **re-present the finalized
   plan as a recap and wait again.** Answers to questions never collapse into
   approval; the recap is what gets approved. This is the exact step whose
   omission created this rule.
4. **Wait.** End the turn. Do not pre-emptively start "the safe part".
5. **Implement** only after an explicit affirmative.

### Plan shape

Scale the detail to the work, per the user's standing instruction: a simple
screen with no state or network gets one or two steps; a complex one gets phases.

```markdown
## Plan — <unit of work>

**Complexity:** <simple | moderate | complex> — <why, in one line>

**Files:**
- new: <paths>
- edited: <paths>

**Steps:**
1. …
2. …

**Open decisions:** <or "none">

Waiting for your go-ahead before writing anything.
```

That last line is mandatory. It makes the gate visible to the user rather than
something only the agent is tracking.

---

## What May Be Done Before Approval

Read-only work is encouraged — a plan built on a real reading of the design and
the code is the plan worth approving.

**Allowed:** reading files, `Grep`/`Glob`, reading a Figma node, computing
contrast ratios or measurements, listing dependency versions, running read-only
`git` commands, delegating to a read-only subagent.

**Not allowed:** `Write`, `Edit`, `NotebookEdit`, creating directories, adding a
dependency, running a generator, running `dart format`, or any shell command that
mutates the working tree — including "just" a scratch file inside the repo.

A temporary file inside the **scratchpad** directory is fine; it is outside the
repo and mutates nothing the user owns.

---

## Violations

### ❌ Violation 1 — Treating answered questions as approval (the real incident)

**Trigger:** User sends a Figma link: *"first screen, it's the splash — work per
the instructions."*

**Bad behaviour (what actually happened):**
> Agent read the design, assessed complexity, presented a two-step plan, then
> asked four questions about colour, font, localization and timing. The user
> answered all four. The agent read those answers as consent and implemented the
> whole screen, tests included. The user never said "موافق" — and had to stop the
> work afterwards to point that out.

**Correct behaviour:**
> After the four answers arrive, the agent posts a recap — the decisions as
> settled, the file list, the two steps — ending with *"Waiting for your go-ahead
> before writing anything."* Then it stops. It writes the first line of code only
> after an explicit affirmative.

### ❌ Violation 2 — Starting the "obvious" part while waiting

**Trigger:** Plan presented; the user has not replied yet.

**Bad behaviour:**
> Agent adds the ARB keys and creates the feature folder, reasoning that these
> are needed under any variant of the plan and cost nothing to undo.

**Correct behaviour:**
> Nothing is written. "Needed under any variant" is the agent's assumption about
> a plan the user has not accepted — and the user may reject the feature outright,
> leaving orphan keys and folders behind.

### ❌ Violation 3 — Reusing the last approval

**Trigger:** The user approved the splash screen yesterday. Today they send a
link to the login screen.

**Bad behaviour:**
> Agent treats the established workflow as blanket consent and builds it.

**Correct behaviour:**
> A new unit of work needs its own plan and its own approval. The workflow being
> familiar makes the plan shorter, not optional.

---

## Relationship to Other Rules

- `05-planning-rigor` — supplies the elicitation and options-with-tradeoffs
  requirements. This rule hardens its Rule 4 into an explicit gate and defines
  what does not count as confirmation.
- `09-minimal-changes` — governs how much to write once approved; this rule
  governs whether writing may begin at all.
- `00-memory-think` — the memory-bank read happens during investigation, before
  the plan, and is not gated.
- Generator skills (`/flutter-screen-gen`, `/flutter-widget-gen`,
  `/flutter-state-gen`, …) already announce and wait. This rule applies equally
  when no skill was invoked and the agent is building directly — which is the
  case the announcement convention did not cover.
