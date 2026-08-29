## What This Rule Does

Applies to any widget, screen, or theme code. This project has a **closed**
design system: a fixed colour palette and fixed spacing, radius and font-size
scales. This rule keeps generated and hand-written UI inside it.

The failure mode it prevents is not ugly code — it is a design system that stops
being one. Each individual `Color(0xFF9B8B7A)` or `SizedBox(height: 18)` looks
harmless and defensible in isolation. Thirty of them across twelve screens, and
there is no system left: no way to restyle the app, no consistency to review
against, and no answer to "what is our spacing scale" other than "whatever each
screen happened to use."

**Numbering note:** this rule sits at 12, outside the 00–08 domain block the
numbering convention would otherwise assign. 08 is the only free slot in that
block and is reserved for `08-flutter-baas-security-guard.md`, which
`/platform-init` reinstalls if a Firebase or Supabase source is ever added.
Taking 08 here would collide with that.

---

## The Tokens

| Need | Source | File |
|---|---|---|
| Colour | `AppColors` | `lib/core/theme/app_colors.dart` |
| Spacing, padding, gaps | `AppSpacing` | `lib/core/theme/app_dimensions.dart` |
| Corner radius | `AppRadius` | `lib/core/theme/app_dimensions.dart` |
| Font size | `AppFontSize` | `lib/core/theme/app_dimensions.dart` |

Read those two files before writing widget code. Do not rely on a remembered
list — the palette is short enough that guessing feels safe and is not.

`AppSpacing` / `AppRadius` / `AppFontSize` resolve through `flutter_screenutil`
against the 375x812 baseline set in `main.dart`. They are getters, not
constants, so they cannot appear in a `const` expression:
`EdgeInsetsDirectional.all(AppSpacing.m)` **without** `const` is correct.

Anything reading a token must be inside the `ScreenUtilInit` subtree. In tests
that means `pumpApp` (`test/helpers/pump_app.dart`), which wraps it already —
a widget test that builds a token-reading widget outside it throws.

---

## Non-Negotiables

### 1. No literal colour in widget or screen code

```dart
// ❌ A fifth palette entry, introduced by accident
Container(color: const Color(0xFFF5F0E8))

// ❌ Material's palette is not this project's palette
Icon(Icons.close, color: Colors.grey.shade400)

// ✓
Container(color: AppColors.secondary)
```

`Colors.*` counts as a literal colour. So does `Colors.transparent`'s cousins —
though `Colors.transparent` itself is fine, since it is the absence of a colour
rather than a new one.

### 2. No raw number for a spacing, radius, or font size

```dart
// ❌
const SizedBox(height: 16),
padding: const EdgeInsetsDirectional.all(24),
borderRadius: BorderRadius.circular(12),
style: TextStyle(fontSize: 18),

// ✓
SizedBox(height: AppSpacing.m),
padding: EdgeInsetsDirectional.all(AppSpacing.l),
borderRadius: BorderRadius.circular(AppRadius.m),
style: Theme.of(context).textTheme.headlineSmall,
```

For text, prefer reading `Theme.of(context).textTheme` over building a
`TextStyle` with `AppFontSize` directly — the theme already applies the family,
weight and colour. Reach for `AppFontSize` only when a style genuinely has no
`TextTheme` slot.

Numbers that are **not** measurements are unaffected: `maxLines: 2`,
`flex: 3`, `itemCount`, `duration`, `strokeWidth`, an opacity of `0.5`.

### 3. A colour not in the palette: derive, or stop and ask

In order:

1. **Is it a lighter or translucent version of an existing colour?** Derive it:
   `AppColors.primaryText.withValues(alpha: 0.5)`. Use `withValues`, not the
   deprecated `withOpacity`.
2. **Is it a colour the theme already assigns a role to?** Read it from
   `Theme.of(context).colorScheme` instead.
3. **Otherwise: stop and ask the user.** Do not add a constant to `AppColors`
   and continue.

The one legitimate way the palette grows is an explicit human decision — as
`AppColors.error` did, carried over from the existing admin "cancelled" state
rather than invented to unblock a screen.

### 4. A measurement not on the scale: use the nearest

Do not add a new entry to `AppSpacing`, `AppRadius` or `AppFontSize`. A Figma
value of 18 becomes `AppSpacing.m` (16) or `AppSpacing.l` (24) — whichever is
nearer; on a tie, prefer the one that keeps a tap target above 48.

The design intent is a rhythm, not thirty exact numbers. A screen that needs a
value between two scale steps almost always reads fine on the nearer step, and
the one time it genuinely does not is rule 5.

### 5. The only exception: one element, one screen, local constant

A measurement specific to a single element on a single screen — a hero image
height, a fixed map viewport, an illustration's aspect box — goes as a private
constant in **that widget's own file**:

```dart
class _ProfileHero extends StatelessWidget {
  /// Fixed by the artwork's aspect ratio, not part of the spacing rhythm, and
  /// used nowhere else.
  static const double _heroHeight = 220;
  ...
}
```

It must be private, it must carry a comment saying why it is off-scale, and it
must not migrate into `app_dimensions.dart` later "since we're using it twice
now" — a second use is the moment to ask whether it belongs on the scale.

### 6. Accessibility floors are not design tokens

48dp minimum tap target and similar platform accessibility minimums are
constraints, not scale values. They live as local constants where they apply
(see `AppTheme._minTapTarget`) and are never expressed as a coincidentally
equal `AppSpacing` entry.

---

## Direction and Localisation Still Apply

This rule is about *which value*; `07-flutter-direction-guard` is about *which
API*. Both hold at once:

```dart
// ✓ directional API, token value
padding: EdgeInsetsDirectional.only(start: AppSpacing.m)

// ❌ token value, physical API
padding: EdgeInsets.only(left: AppSpacing.m)
```

Likewise `11-flutter-l10n-guard`: a tokenised widget with a hardcoded English
string is still a violation of that rule.

---

## Violations

### ❌ Violation 1 — Quietly widening the palette

**Trigger:** A Figma card shows a `#F5F0E8` background, close to but not equal
to `AppColors.background`.

**Bad behaviour:**
> Agent adds `static const Color cardBackground = Color(0xFFF5F0E8);` to
> `AppColors` and uses it. The palette is now five colours plus one, nobody
> reviewed the addition, and the next near-miss adds a seventh.

**Correct behaviour:**
> Agent recognises it as a near-variant of `background`, uses `AppColors.background`
> and reports: *"The card in Figma is `#F5F0E8`, a hair off `background`
> `#FAF7F2`. I used `background`. If the difference is intentional, tell me and
> I'll ask about a palette entry rather than adding one."*

### ❌ Violation 2 — Treating the scale as advisory

**Trigger:** Design specifies 20px vertical spacing between two cards.

**Bad behaviour:**
> `SizedBox(height: 20.h)` — bypassing `AppSpacing` entirely while still using
> screenutil, so it looks conformant in review and is not.

**Correct behaviour:**
> `SizedBox(height: AppSpacing.m)` (16) or `AppSpacing.l` (24), noting the
> substitution if it matters visually. A raw `.h` call in widget code is as much
> a violation as a raw `20`.

### ❌ Violation 3 — A local constant that should be a token, or vice versa

**Trigger:** Three screens each need the same 220px hero height.

**Bad behaviour, both directions:**
> Copying `_heroHeight = 220` into all three files (now it is three constants
> that will drift) — or silently adding `AppSpacing.hero` (now the spacing scale
> contains a component measurement).

**Correct behaviour:**
> Stop and ask. A measurement used by three screens is a shared component
> concern: it probably belongs to a shared `HeroImage` widget that owns the
> constant once, which is a design decision the user should make.

---

## Relationship to Other Rules

- `07-flutter-direction-guard` — which layout API; this rule governs which
  value goes into it.
- `11-flutter-l10n-guard` — user-facing strings, orthogonal and simultaneous.
- `09-minimal-changes` — do **not** sweep existing files onto tokens because you
  noticed them. `lib/features/auth/` predates this rule and still holds raw
  values; migrating it is its own task. Fix only lines the current task touches.
- `10-evidence-and-dependency-guard` — confirm a token exists before using it.
  `AppSpacing.xxl` exists; `AppSpacing.xxxl` does not.
- `01-flutter-architecture-guard` — tokens are presentation-layer. `domain/` and
  `data/` never import `core/theme/`.
