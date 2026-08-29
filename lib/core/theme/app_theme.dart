import 'package:flutter/material.dart';
import 'package:nova_modest/core/theme/app_colors.dart';
import 'package:nova_modest/core/theme/app_dimensions.dart';

/// The single [ThemeData] for the app.
///
/// Every colour comes from [AppColors] and every measurement from
/// [AppSpacing] / [AppRadius] / [AppFontSize]. There is no seed colour and no
/// literal `Color(0x...)` in this file: the previous `_seed` +
/// `ColorScheme.fromSeed` pair is gone, because a generated scheme would pull in
/// dozens of tonal colours from outside the closed palette.
///
/// **Light only.** [AppColors] is a warm light palette, and a correct dark
/// scheme cannot be derived from it without new colours the palette forbids. A
/// dark theme needs its own palette decision rather than an invented one.
///
/// The scales read `.h` / `.sp` / `.r`, so this must be built inside the
/// `ScreenUtilInit` subtree. `App.build` satisfies that.
abstract final class AppTheme {
  /// The bundled family declared in `pubspec.yaml`. Covers Arabic and Latin, so
  /// the `ar` template locale needs no platform-fallback face.
  static const String fontFamily = 'IBM Plex Sans Arabic';

  /// Minimum accessible tap target: an accessibility floor, not a design-scale
  /// value, so it is a local constant here rather than an [AppSpacing] entry.
  static const double _minTapTarget = 48;

  static ThemeData get light {
    final scheme = _scheme;
    final textTheme = _textTheme;

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: fontFamily,
      textTheme: textTheme,
      scaffoldBackgroundColor: AppColors.background,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.primaryText,
        surfaceTintColor: AppColors.background,
        centerTitle: false,
        elevation: 0,
        titleTextStyle: textTheme.titleLarge,
      ),
      dividerTheme: DividerThemeData(
        color: AppColors.secondary,
        space: AppSpacing.m,
        thickness: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.background,
        labelStyle: textTheme.bodyMedium,
        hintStyle: textTheme.bodyMedium?.copyWith(
          // A muted hint derived from the palette rather than added to it.
          color: AppColors.primaryText.withValues(alpha: 0.5),
        ),
        // Directional so padding mirrors under RTL
        // (07-flutter-direction-guard.md).
        contentPadding: EdgeInsetsDirectional.symmetric(
          horizontal: AppSpacing.m,
          // Nearest scale value to the 14 this previously used, taking the
          // taller neighbour so the field clears the tap-target floor.
          vertical: AppSpacing.m,
        ),
        border: _inputBorder(AppColors.secondary),
        enabledBorder: _inputBorder(AppColors.secondary),
        focusedBorder: _inputBorder(AppColors.accent, width: 2),
        errorBorder: _inputBorder(scheme.error),
        focusedErrorBorder: _inputBorder(scheme.error, width: 2),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: AppColors.primaryText,
          disabledBackgroundColor: AppColors.secondary,
          disabledForegroundColor: AppColors.primaryText.withValues(alpha: 0.4),
          minimumSize: const Size.fromHeight(_minTapTarget),
          padding: EdgeInsetsDirectional.symmetric(horizontal: AppSpacing.l),
          textStyle: textTheme.labelLarge,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.m),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryText,
          side: const BorderSide(color: AppColors.secondary),
          minimumSize: const Size.fromHeight(_minTapTarget),
          padding: EdgeInsetsDirectional.symmetric(horizontal: AppSpacing.l),
          textStyle: textTheme.labelLarge,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.m),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primaryText,
          textStyle: textTheme.labelLarge,
          padding: EdgeInsetsDirectional.symmetric(horizontal: AppSpacing.s),
        ),
      ),
      iconTheme: const IconThemeData(color: AppColors.primaryText),
      cardTheme: CardThemeData(
        color: AppColors.background,
        surfaceTintColor: AppColors.background,
        elevation: 0,
        margin: EdgeInsetsDirectional.all(AppSpacing.xs),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.l),
          side: const BorderSide(color: AppColors.secondary),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.secondary,
        labelStyle: textTheme.labelMedium,
        padding: EdgeInsetsDirectional.symmetric(horizontal: AppSpacing.xs),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
      ),
      // Material 3 derives a switch's OFF state from the ColorScheme: the track
      // from surfaceContainerHighest, and both the track outline and the thumb
      // from outline. This palette maps all three to AppColors.secondary, which
      // left the off state one solid block at 1.00:1 — not readable as a switch.
      // Stated here rather than at a call site so every switch inherits it.
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.accent
              // 7.14:1 against the track.
              : AppColors.mutedStrong,
        ),
        // The same track either way: the thumb's colour and its position are
        // what say which state it is in.
        trackColor: const WidgetStatePropertyAll(AppColors.secondary),
        trackOutlineColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.accent
              : AppColors.muted,
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.accent,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.primaryText,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: AppColors.background,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.s),
        ),
      ),
    );
  }

  /// Built explicitly, not from a seed: `fromSeed` would generate a full tonal
  /// palette of colours that are not in [AppColors].
  ///
  /// Measured contrast against [AppColors.primaryText] - background 16.3:1,
  /// secondary 13.3:1, accent 7.5:1 - so every pairing below clears WCAG AA.
  /// [AppColors.error] sits at 4.60:1 on background, which is AA for normal
  /// text; it is never drawn on accent, where it would fail.
  static ColorScheme get _scheme => const ColorScheme(
    brightness: Brightness.light,
    primary: AppColors.accent,
    onPrimary: AppColors.primaryText,
    secondary: AppColors.secondary,
    onSecondary: AppColors.primaryText,
    surface: AppColors.background,
    onSurface: AppColors.primaryText,
    surfaceContainerHighest: AppColors.secondary,
    outline: AppColors.secondary,
    outlineVariant: AppColors.secondary,
    // Muted terracotta, carried over from the existing admin "cancelled"
    // decision rather than invented here. 4.60:1 on background either way, so
    // error text on the page and background text on an error fill both clear
    // WCAG AA.
    error: AppColors.error,
    onError: AppColors.background,
  );

  static TextTheme get _textTheme => TextTheme(
    displayLarge: _style(AppFontSize.display, FontWeight.w600),
    displayMedium: _style(AppFontSize.xxxl, FontWeight.w600),
    displaySmall: _style(AppFontSize.xxl, FontWeight.w600),
    headlineLarge: _style(AppFontSize.xxxl, FontWeight.w600),
    headlineMedium: _style(AppFontSize.xxl, FontWeight.w600),
    headlineSmall: _style(AppFontSize.xl, FontWeight.w500),
    titleLarge: _style(AppFontSize.xl, FontWeight.w600),
    titleMedium: _style(AppFontSize.l, FontWeight.w500),
    titleSmall: _style(AppFontSize.m, FontWeight.w500),
    bodyLarge: _style(AppFontSize.l, FontWeight.w400),
    bodyMedium: _style(AppFontSize.m, FontWeight.w400),
    bodySmall: _style(AppFontSize.s, FontWeight.w400),
    labelLarge: _style(AppFontSize.m, FontWeight.w500),
    labelMedium: _style(AppFontSize.s, FontWeight.w500),
    labelSmall: _style(AppFontSize.xs, FontWeight.w400),
  );

  static TextStyle _style(double size, FontWeight weight) => TextStyle(
    fontFamily: fontFamily,
    fontSize: size,
    fontWeight: weight,
    color: AppColors.primaryText,
  );

  static OutlineInputBorder _inputBorder(Color color, {double width = 1}) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.m),
        borderSide: BorderSide(color: color, width: width),
      );
}
