---
name: flutter-l10n-gen
description: "Adds localization keys to every .arb locale file with ICU placeholders and metadata, flags locales needing human translation, replaces literal strings with generated AppLocalizations accessors, and verifies the affected widgets survive an RTL locale. Use when asked to localize or internationalize new user-facing strings. Invoked as /flutter-l10n-gen."
---

# Skill: flutter-l10n-gen

**Invocation:** `/flutter-l10n-gen [strings to add/screen]`

---

## Overview

`flutter-l10n-gen` adds localization entries for new user-facing strings
using Flutter's `intl`/ARB-file localization pipeline
(`flutter_localizations` + `.arb` files + generated `AppLocalizations`) —
the standard approach for a Flutter app that ships in more than one
language. Adds the key to every existing `.arb` locale file (flagging
untranslated locales rather than inventing a translation) and replaces the
literal string in the widget with the generated accessor.

**Memory references:** `memory-bank/techContext.md` — confirm `intl` /
`flutter_localizations` and the ARB pipeline are set up, and read the
`Locales:` lock. If it records a single locale, this skill is the wrong tool:
say so and point the user at `/platform-init` to change the lock first, since
adding a pipeline is a project-level decision rather than a per-string one.

**Guard rules:** `11-flutter-l10n-guard.md` (pipeline),
`07-flutter-direction-guard.md` (layout APIs, always on).

**Guard rules:** `10-evidence-and-dependency-guard.md` (don't add the l10n
pipeline to a repo that doesn't have it without asking).

---

## Steps

**Step 0 — Confirm the l10n pipeline exists.** Check for
`lib/l10n/*.arb` (or wherever `l10n.yaml` points), `flutter_localizations`
in `pubspec.yaml`, and `flutter_gen`/generated `AppLocalizations`. If it
doesn't exist, this is a repo-level setup decision, not something to
introduce unilaterally — flag it and ask.

**Step 1 — Add the key to the base ARB file** (usually
`lib/l10n/app_en.arb`), with an ICU placeholder for anything interpolated
and a `@key` metadata block describing it:

```json
{
  "orderConfirmedTitle": "Order confirmed",
  "@orderConfirmedTitle": {
    "description": "Title shown after a successful checkout"
  },
  "orderTotal": "Total: {amount}",
  "@orderTotal": {
    "description": "Order total shown on the confirmation screen",
    "placeholders": {
      "amount": { "type": "String", "example": "$42.00" }
    }
  }
}
```

**Step 2 — Add the same key to every other locale's ARB file**, with the
value left as the English source string and flagged rather than machine-
translated silently:

```json
"orderConfirmedTitle": "Order confirmed",
"@@x-needs-translation": true
```

State explicitly in the response which locales still need a human
translation — never present a guessed translation as final.

**Step 3 — Use format strings correctly for pluralization/gender** if the
string needs it — ICU `plural`/`select` syntax in the ARB entry, not string
concatenation in Dart:

```json
"itemCount": "{count, plural, =0{No items} =1{1 item} other{{count} items}}"
```

**Step 4 — Replace the literal string in the widget.**

```dart
// ❌
Text('Order confirmed')
// ✓
Text(AppLocalizations.of(context)!.orderConfirmedTitle)
```

**Step 5 — Note the codegen step.** ARB changes require regenerating
`AppLocalizations` (`flutter gen-l10n`, run automatically on build if
`generate: true` is set in `pubspec.yaml`, or manually otherwise) — state
this so the user knows the accessor won't exist until that runs.

**Step 6 — Verify the screen under RTL** if any locked locale is right-to-left
(Arabic, Hebrew, Farsi, Urdu).

Adding a translation does not make a screen work in that language. Three
things break, and none of them are caught by adding the ARB key:

1. **Physical layout APIs.** Any untagged `EdgeInsets.only(left:)`,
   `Alignment.centerLeft`, `Positioned(left:)` or `TextAlign.left` in the
   widgets you just touched. Fix them to the directional form per
   `07-flutter-direction-guard` — but only in the widgets this task already
   touches (`09-minimal-changes`).
2. **Overflow.** Translations are routinely 30–50% longer than English. A row
   that fits in English overflows in German or Arabic.
3. **Fonts.** Confirm the theme's font family has glyphs for the script. A
   missing glyph renders as an empty box and no test catches it.

Add or extend a golden test covering both directions, per
`11-flutter-l10n-guard` §6. If the screen has no golden test at all, a
`Directionality` smoke test is the minimum:

```dart
testWidgets('OrderCard survives RTL', (tester) async {
  await tester.pumpWidget(const Directionality(
    textDirection: TextDirection.rtl,
    child: MaterialApp(home: OrderCard(order: fakeOrder)),
  ));
  expect(tester.takeException(), isNull);
});
```

**Step 7 — Number/date formatting.** Any date or number shown to the user
goes through `intl`'s locale-aware formatters (`DateFormat`,
`NumberFormat`) rather than a hand-rolled string format, so it adapts to
the active locale automatically.

---

## Example

Request: "Add localized strings for the order confirmation screen."

Output: keys added to every `.arb` file under `lib/l10n/`, non-English
locales flagged as needing translation, widget updated to use
`AppLocalizations.of(context)!.orderConfirmedTitle`, and a note to run
`flutter gen-l10n` (or rebuild) before the accessor compiles.
