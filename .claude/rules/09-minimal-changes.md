---
description: Enforce minimal-change discipline — only modify what the task requires, minimize git diff, never introduce unrelated changes
applies-to: every edit, every file type
---

## What This Rule Does

Prevents the single most common way AI-generated changes introduce
unintended regressions and reviewer fatigue: making changes *beyond* what
the task requires. A request to fix a bug in one widget shouldn't reformat
the whole file, rename unrelated providers, reorder imports, or fix an
adjacent lint warning the developer didn't ask about. Each of those is a
separate change, and bundling them makes the PR diff harder to review and
regressions harder to bisect.

This rule has no glob restriction — it applies to every file type, `.dart`,
`.yaml`, `.arb`, `.gradle`, `.md` alike.

---

## What Gets Refused

- **Unrelated reformatting.** The task touches one method inside a widget;
  the rest of the file's formatting is left alone even if `dart format`
  would change it, unless the task is specifically a formatting pass.
- **Opportunistic renames.** A provider or file that's poorly named but not
  directly related to the task is not renamed inline. Flag it instead.
- **Implicit scope creep.** Adding a field to a model doesn't implicitly
  mean updating every screen that displays that model, or adding a missing
  null check on a neighboring widget — unless the task explicitly covers
  those, they're separate work and should be called out as such.
- **Import reordering.** Do not sort or clean up existing `import`
  statements unless the task requires adding one.
- **Unrelated `build_runner` regeneration.** Do not regenerate `.g.dart` /
  `.freezed.dart` files for models the task didn't touch.

## What's Explicitly Allowed

- Removing an `import` that the current task's change makes genuinely
  unused — a direct consequence of the change, not unrelated cleanup.
- Regenerating the specific `.g.dart`/`.freezed.dart` file for a model the
  task did change.
- Adding a brief inline comment explaining a non-obvious aspect of *the
  changed code*.

## Exception: Diagnostic Instrumentation

Diagnosis requires temporary changes that this rule would otherwise refuse —
a `debugPrint` at a seam, a widget rendered in isolation, a hardcoded payload
to narrow an input. Without a defined path for these, an agent either violates
this rule silently or diagnoses by guesswork. Both are worse than the
exception.

During a `/flutter-debug` session, temporary instrumentation is **allowed**
under two conditions:

1. **Every line is tagged** with a `// DEBUG-TEMP:` comment that says what is
   being checked.
2. **No tagged line reaches a commit.** Step 7 of `/flutter-debug` removes
   them; `.github/workflows/flutter-ci.yml` fails the build if any survive.

```dart
// DEBUG-TEMP: is orders null before the mapper, or after?
debugPrint('orders raw: ${json['orders']}');
```

A file carrying `DEBUG-TEMP` that is ready to commit means a debugging session
was never closed out.

This exception does **not** extend to: adding a logging package, restructuring
code to make it easier to debug, or refactoring noticed along the way. Those
are separate tasks and this rule applies to them in full.

## When to Flag Instead of Refuse

If a clearly broken or dangerous thing is noticed in adjacent code (a
plaintext-stored token, a missing `mounted` check before `setState` after an
`await`): **flag it**, don't silently fix it alongside the task. "I noticed
X while making this change — flagging it separately so it can be addressed
explicitly" is the correct behavior.

## Relationship to Other Rules

This rule says nothing about *what* to generate — that's `01`/`02`/`03`/
`04`. It says only *how much* to generate. A change can be architecturally
correct, secure, and pattern-conformant and still violate this rule by
modifying more than was asked for.
