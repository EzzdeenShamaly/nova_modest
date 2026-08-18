---
name: flutter-debug
description: "Diagnoses a specific reported failure in a Flutter app — a crash, an exception, a wrong value, a widget that renders incorrectly — by reproducing it, classifying the error signature, forming one falsifiable hypothesis at a time, and fixing at the layer that owns the cause rather than the layer that shows the symptom. Stops and reports after two failed hypotheses instead of guessing again. Use when something is broken and the cause is not yet known. Invoked as /flutter-debug."
---

# Skill: flutter-debug

**Invocation:** `/flutter-debug [what is broken]`

---

## Overview

Every other skill in this kit either writes code or reviews code. This one
investigates a failure. It exists because unstructured debugging is where an
agent does the most damage: guess a cause, change a file, still broken, guess
again — and four rounds later there are five unrelated edits, two new bugs, and
the original defect is untouched.

The discipline is more important than the fix. A wrong hypothesis that is
stated, tested and discarded costs one round. A wrong hypothesis that is
silently patched costs a week.

**Contract:** announce the plan, then wait. This skill modifies code.

---

## Step 0 — Reproduce before theorising

Do not begin until you have **either** a reproduction **or** a stack trace.

Ask for, and record:

- exact steps to trigger it
- platform and device (Android/iOS/web; emulator or physical)
- build mode — `debug`, `profile`, or `release`
- whether it is consistent or intermittent
- when it started, and what changed around then

**If the report is "it doesn't work" with no trace and no steps, stop and ask.**
A vague report produces a vague diagnosis, and a vague diagnosis produces the
guess-and-patch loop this skill exists to prevent.

Build mode matters more than it looks: assertions, `debugPrint`, and most
`FlutterError` messages are stripped in release. A bug that appears only in
release is a different investigation from one that appears everywhere.

Intermittent bugs need one extra question before anything else: **what is
different between the runs that fail and the runs that pass?** Timing, network,
cold start, a specific account. Do not begin bisecting code until that is named.

---

## Step 1 — Classify the signature

Flutter failures fall into families, and the family narrows the search far
faster than reading files does.

| Message | Family | Look at |
|---|---|---|
| `RenderFlex overflowed by N pixels` | layout | the **parent's** constraints, not the child |
| `Vertical viewport was given unbounded height` | layout | a scrollable inside a scrollable |
| `setState() called after dispose()` | lifecycle | a subscription or timer never cancelled |
| `Looking up a deactivated widget's ancestor` | lifecycle | `context` used after an await |
| `Bad state: Cannot emit new states after calling close` | lifecycle (Bloc/Cubit) | `BlocProvider` scope vs navigation |
| `Null check operator used on a null value` | data | a nullable field in the DTO, or a missing API field |
| `type 'X' is not a subtype of type 'Y'` | serialisation | `freezed`/`json_serializable` out of sync with the API |
| `DioException` reaching a widget | **channel leak** | `06-flutter-error-guard` violated — `dio` crossed its seam |
| `Instance of 'Failure'` shown to the user | **channel leak** | `.toString()` used instead of a mapped message |
| `permission-denied` / Postgres `42501` | **authorisation** | the rule set, not the query — see `08-flutter-baas-security-guard` |
| `PlatformException` | native | plugin setup, manifest, entitlements |
| Jank without an exception | performance | hand to `/flutter-performance-audit` instead |

The last four rows matter most in this kit. Three of them are **evidence that a
rule was broken**, not ordinary bugs. When you see them, say which rule, and fix
there — patching the symptom re-hides the violation.

---

## Step 2 — Follow the trace, do not search

Read the stack trace top-down and find the **first frame under `lib/`**. Frames
above it are framework internals; frames below are callers. That first frame is
where the investigation starts.

Do not open files by guessing at names. Do not grep for the error message
across the repo. The trace already knows.

If there is no trace — a wrong value rather than a crash — use
`/feature-trace` on the affected feature first to establish the path from UI to
data source, then pick the narrowest point on that path where the value could
first be wrong.

---

## Step 3 — One hypothesis, stated before any edit

Write it down, in this shape, **before touching a file**:

> **Hypothesis:** the `orders` list is null because the API omits the field for
> new accounts and the DTO marks it non-nullable.
> **If true:** an account with orders reproduces fine; a fresh account crashes.
> **If false:** the fresh account also works, and the null comes from elsewhere.

Three properties are required:

1. **Specific** — names a file, a value, a condition. "Something's wrong with
   the state" is not a hypothesis.
2. **Falsifiable** — says what observation would disprove it.
3. **Singular** — one at a time. Two changes at once means you learn nothing
   from the result.

Announce it. Then test it.

---

## Step 4 — Instrument minimally, and tag it

Diagnosis needs temporary changes that `09-minimal-changes` would otherwise
forbid. That rule carries an explicit exception for this skill, with two
conditions:

**Every temporary line is tagged:**

```dart
// DEBUG-TEMP: checking whether orders is null before the mapper
debugPrint('orders raw: ${json['orders']}');
```

**No tagged line survives to a commit.** Step 7 removes them; CI fails the
build if any remain.

Prefer, in order:

1. **Narrow the input** — call the repository directly from a test with the
   exact payload. Fastest, no UI, and it becomes the regression test in step 6.
2. **Isolate the widget** — render it alone in a test with fake data. If it
   renders, the bug is upstream.
3. **`debugPrint` at the seam** — one print at the boundary the value crosses,
   not five scattered through the call chain.
4. **DevTools** — the widget inspector for layout, the network tab for
   payloads, the memory view for leaks.

Do not add a logging package, do not restructure code "to make it debuggable",
and do not refactor while investigating. Both of those are separate tasks.

---

## Step 5 — Fix at the layer that owns the cause

This is the step that separates a fix from a cover-up.

A symptom in a widget usually has its cause further down:

| Symptom | Wrong fix | Right fix |
|---|---|---|
| Null crash in a widget | `?? []` in the widget | make the DTO field nullable and give the domain a default |
| `DioException` in the UI | `try/catch` in the widget | map it at the network seam — `06-flutter-error-guard` |
| Raw error text on screen | `.toString()` prettified | map `Failure` to a message in the presentation layer |
| Overflow on one device | `SingleChildScrollView` wrapper | fix the constraint the parent imposes |
| `permission-denied` | retry logic | write the missing policy — `08-flutter-baas-security-guard` |

A defensive `?? []` in a widget makes the red screen go away and leaves the
real defect — an API contract mismatch — in place, now invisible. Ask: **if I
fix it here, does the same class of bug still reach every other screen?** If
yes, this is the wrong layer.

State the layer and why, then apply the smallest change that removes the cause.

---

## Step 6 — Failing test first, then fix

Write a test that **fails for the reported reason**, and run it to confirm it
fails. Then apply the fix. Then run it again.

This is not ceremony. A test written after the fix proves the code passes; a
test written before proves the code was broken and is now not. Only the second
tells you the fix addressed the actual cause rather than moving it.

Follow `04-flutter-test-guard` and this project's harness — `/flutter-test-gen`
conventions apply. Put it beside the existing tests for that feature; do not
create a `bug_fixes_test.dart` graveyard.

If the bug genuinely cannot be tested — a device-specific rendering issue, a
platform channel — say so explicitly and describe the manual verification
instead. Do not skip silently.

---

## Step 7 — Clean up and record

1. **Remove every `DEBUG-TEMP` line.** Grep to confirm:
   `grep -rn "DEBUG-TEMP" lib/ test/`
2. **Revert incidental edits** — anything not part of the fix or its test.
3. **Update `memory-bank/activeContext.md`** with the root cause in one or two
   lines, not the narrative of the investigation. If the cause was a broken
   convention, note which rule and whether the rule needs sharpening.
4. **Summarise:** what was wrong, which layer owned it, what changed, what the
   new test covers.

---

## Stop Condition

**After two failed hypotheses, stop. Do not try a third.**

Return to the user with:

- what has been **ruled out**, and the observation that ruled it out
- what remains plausible
- **what information would discriminate** between the remaining options —
  a log from a failing device, the API response body, the exact account

This is the most important rule in this skill. The third guess is where
unstructured debugging starts destroying a codebase: by then the agent has
usually left two abandoned edits behind and is pattern-matching rather than
reasoning. Stopping is not failure. It is the correct output when the available
evidence does not determine the answer.

If the user pushes for another attempt without new information, say plainly
that more guessing will produce more edits and no more certainty, and name the
one piece of evidence that would change that.

---

## Observability

If the investigation stalls because there is **no diagnostic trail at all** —
no logs, no crash reporting, nothing recorded from the failing device — say so
and name it as the blocker.

A durable logging policy is a real improvement, but it is a separate task with
its own design decisions. Do not introduce a logging package mid-diagnosis.
Finish or stop the investigation first, then propose it.

---

## Out Of Scope

- **Jank and frame drops with no exception** → `/flutter-performance-audit`
- **"How does this feature work?"** → `/feature-trace`
- **"What breaks if I change this?"** → `/impact-analysis`
- **Failing CI on code that was never working** → that is unfinished work, not
  a bug; use the relevant generator

---

## Related Rules

`09-minimal-changes` (and its DEBUG-TEMP exception) · `10-evidence-and-dependency-guard`
· `06-flutter-error-guard` · `08-flutter-baas-security-guard` · `04-flutter-test-guard`
