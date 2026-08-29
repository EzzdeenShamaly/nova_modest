import 'package:flutter/material.dart';

/// The project's colour palette. **Closed, not a starting point.**
///
/// These five are the whole vocabulary. If a Figma screen shows a colour that is
/// not one of them:
///
/// 1. If it reads as a lighter/translucent variant of one of these, derive it
///    with `.withValues(alpha: …)` on the nearest colour.
/// 2. If it cannot be derived, **stop and ask** before implementing the screen.
///    Do not add a fifth constant here.
///
/// Creating a bare `Color(0x…)` inside a screen or widget is prohibited.
abstract final class AppColors {
  /// Page background — warm off-white.
  static const Color background = Color(0xFFFAF7F2);

  /// Primary text and icons — near-black.
  static const Color primaryText = Color(0xFF1A1A1A);

  /// Secondary surfaces, dividers, muted fills — warm sand.
  static const Color secondary = Color(0xFFE8DFD3);

  /// Accent for emphasis and primary actions — muted gold.
  static const Color accent = Color(0xFFC6A75E);

  // --- Derived tints -------------------------------------------------------
  //
  // Translucent [primaryText] shows up constantly: body copy, inactive tabs,
  // hairline rules, placeholder fills. Written inline at each call site the
  // alphas drifted to four different values across five files — the same
  // "thirty near-miss values" failure `12-flutter-design-system-guard.md`
  // exists to stop, just in alpha space instead of hex space. The levels are
  // named here and closed, exactly like the spacing scale.
  //
  // Not `const`: `withValues` is not a const constructor, so these cannot appear
  // in a `const` expression — the same constraint the dimension scales carry.

  /// Body copy, links, inactive navigation. The most legible muted level.
  static final Color mutedStrong = primaryText.withValues(alpha: 0.80);

  /// Secondary copy and hairline borders on a light surface.
  static final Color muted = primaryText.withValues(alpha: 0.68);

  /// Inactive indicators — present but not competing for attention.
  static final Color subtle = primaryText.withValues(alpha: 0.23);

  /// Barely-there fills: image placeholders, empty wells.
  static final Color hairline = primaryText.withValues(alpha: 0.08);

  /// Error and destructive states — muted terracotta.
  ///
  /// Not an arbitrary red: this is the same colour already decided for the
  /// admin "cancelled" state, so it continues an existing decision rather than
  /// widening the palette on a whim. It stays inside the warm identity instead
  /// of importing a saturated system red.
  ///
  /// Contrast against [background] is 4.60:1 — WCAG AA for normal text, and
  /// comfortably past the 3:1 floor for borders and icons. Do **not** pair it
  /// with [accent] (2.13:1, fails); error content belongs on [background].
  static const Color error = Color(0xFFB5524A);
}
