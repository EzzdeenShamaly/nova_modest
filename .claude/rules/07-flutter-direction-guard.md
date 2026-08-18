---
description: Use direction-neutral layout APIs everywhere — start/end instead of left/right — so an English-only app stays one locale away from RTL instead of one rewrite away
applies-to: any widget code, any theme, any layout
---

## What This Rule Does

Flutter ships two parallel sets of layout APIs: **physical** (`left`, `right`)
and **directional** (`start`, `end`). In an LTR app they render identically —
same pixels, same performance, same output. In an RTL locale the directional
set mirrors and the physical set does not.

This rule requires the directional set. Always. Including in projects that will
only ever ship English.

## Why This Is Always On, Even For English-Only Projects

This is not a localisation rule and it is not conditional on
`locales:` in `techContext.md`. It is on for every project because it costs
nothing and buys something.

- `EdgeInsetsDirectional.only(start: 16)` and `EdgeInsets.only(left: 16)`
  produce **the same pixels** in an LTR app. There is no runtime cost, no
  binary-size cost, no readability cost.
- The difference only appears the day someone asks for a second locale. At
  that point the directional codebase needs a locale added; the physical one
  needs every screen rewritten.

An engineer who writes `left` in an app that will never be translated has not
saved anything. They have taken on a liability with no matching benefit. Treat
this the same way you treat `const` constructors: free, so do it.

The **localisation pipeline** — ARB files, `flutter gen-l10n`,
`AppLocalizations`, a language switcher — is a real cost and is governed by
`11-flutter-l10n-guard`, which is only installed when the project is locked to
multiple locales. Do not conflate the two. This rule is about which API you
reach for. That rule is about whether the app speaks more than one language.

## The Substitutions

| Never write | Always write |
|---|---|
| `EdgeInsets.only(left:/right:)` | `EdgeInsetsDirectional.only(start:/end:)` |
| `EdgeInsets.fromLTRB(...)` | `EdgeInsetsDirectional.fromSTEB(...)` |
| `Alignment.centerLeft` / `.centerRight` | `AlignmentDirectional.centerStart` / `.centerEnd` |
| `Alignment.topLeft` / `.bottomRight` | `AlignmentDirectional.topStart` / `.bottomEnd` |
| `Positioned(left:/right:)` | `PositionedDirectional(start:/end:)` |
| `BorderRadius.only(topLeft:...)` | `BorderRadiusDirectional.only(topStart:...)` |
| `Border(left:/right:)` | `BorderDirectional(start:/end:)` |
| `TextAlign.left` / `.right` | `TextAlign.start` / `.end` |
| `MainAxisAlignment` on a `Row` with a hardcoded `textDirection` | leave `textDirection` unset; let it inherit |

`EdgeInsets.all()`, `EdgeInsets.symmetric()` and
`EdgeInsets.only(top:/bottom:)` are direction-neutral already. Use them freely.

## What Already Works And Needs No Attention

Do not add defensive code for these. They mirror automatically:

- `Row`, `Column` — `MainAxisAlignment.start` and `CrossAxisAlignment.start`
  are directional by definition
- `AppBar` — leading, title alignment and the back button all flip
- `ListTile`, `Drawer`, `TabBar`, `Stepper` — flip
- `Icons.arrow_back` — use `Icons.arrow_back` (it flips) rather than
  `Icons.arrow_left` (it does not)
- Text itself — the engine resolves per-character direction from the string

## The Escape Hatch

Some layouts are **physical, not linguistic**. Their direction comes from the
domain, not the reader's language:

- an audio waveform or a video scrubber (time runs one way)
- a chart axis (unless the chart itself is being mirrored deliberately)
- a code or diff view (code is LTR in every locale)
- a piano roll, a timeline, a seek bar
- a logo or brandmark with fixed geometry

For these, physical APIs are **correct**, and a directional API would be the
bug. Use the physical API and tag it:

```dart
// direction-fixed: waveform scrubs left→right in every locale
padding: const EdgeInsets.only(left: 8),
```

The tag is mandatory. An untagged physical API is a violation; a tagged one is
a decision. A rule that admits no exception gets switched off — a rule that
demands a reason gets respected.

Do not use this tag to avoid thinking. "It looked fine on my phone" is not a
reason. If you cannot name the physical quantity that fixes the direction,
use the directional API.

## Enforcement

- **Generators** — `/flutter-screen-gen`, `/flutter-widget-gen` and any skill
  producing widget code emit directional APIs by default. No `left`/`right`
  should appear in generated output without a `// direction-fixed:` tag.
- **Audits** — `/flutter-architecture-audit` and
  `/flutter-accessibility-audit` report untagged physical APIs as findings.
- **Review** — when editing existing code under this rule, fix physical APIs
  **only in the lines the task already touches**. A sweep across untouched
  files is a `09-minimal-changes` violation. If the codebase needs a broad
  migration, say so and let the user schedule it as its own task.

## Verifying

For a project locked to multiple locales, `11-flutter-l10n-guard` requires
golden tests in both directions. For an English-only project, a single
`Directionality` smoke test is enough to prove the widget does not assume LTR:

```dart
testWidgets('renders under RTL without overflow', (tester) async {
  await tester.pumpWidget(
    const Directionality(
      textDirection: TextDirection.rtl,
      child: MaterialApp(home: OrderCard(order: fakeOrder)),
    ),
  );
  expect(tester.takeException(), isNull);
});
```

This costs one test and catches the overflow class of failure early. It is
**optional** for English-only projects — suggest it, do not require it.

## Relationship to Other Rules

- `11-flutter-l10n-guard` — the pipeline. Conditional. This rule is not.
- `01-flutter-architecture-guard` — layout choices live in the widget layer;
  this rule never reaches into state or data code.
- `09-minimal-changes` — no opportunistic direction sweeps.
