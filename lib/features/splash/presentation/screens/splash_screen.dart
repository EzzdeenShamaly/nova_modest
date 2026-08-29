import 'package:flutter/material.dart';
import 'package:nova_modest/core/theme/app_colors.dart';
import 'package:nova_modest/core/theme/app_dimensions.dart';
import 'package:nova_modest/l10n/app_localizations.dart';

/// The splash screen, shown while `AuthBloc` resolves whether a stored session
/// is still valid.
///
/// Presentation only: it owns no state, makes no call, and does not navigate.
/// The router's redirect guard moves the user off it once `AuthState` leaves
/// `AuthInitial`, and `AuthBloc` holds the resolved state for a minimum
/// duration so this screen is actually seen rather than flashing.
///
/// Built from the Figma frame `Splash` (`14:14`). Vertical rhythm lands exactly
/// on the spacing scale: wordmark → 8 → dot → 24 → tagline.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  /// Tracking for the wordmark, from the design's 4.8 at 24px.
  ///
  /// Off-scale on purpose: letter spacing is a typographic property of this one
  /// element on this one screen, not part of the spacing rhythm, so it is a
  /// private constant here rather than an `AppSpacing` entry
  /// (`12-flutter-design-system-guard.md` §5).
  static const double _wordmarkTracking = 4.8;

  /// The design's Arabic text is weight 300. The bundled family ships a Light
  /// face at that weight, so the design's lightness is matched without adding a
  /// second font family.
  static const FontWeight _lightWeight = FontWeight.w300;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;

    /// The design's `#635E54`. Derived from the palette rather than added to it:
    /// alpha 0.68 over `background` is the closest the five colours reach
    /// (`12-flutter-design-system-guard.md` §3).
    final mutedText = AppColors.muted;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: EdgeInsetsDirectional.symmetric(horizontal: AppSpacing.l),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // The brandmark is Latin in every locale, so it is read LTR
                // regardless of the ambient direction.
                // direction-fixed: a brandmark's glyph order is fixed by the
                // mark itself, not by the reader's language
                Text(
                  l10n.brandName,
                  textDirection: TextDirection.ltr,
                  textAlign: TextAlign.center,
                  style: textTheme.headlineLarge?.copyWith(
                    letterSpacing: _wordmarkTracking,
                  ),
                ),
                // 24 both sides of the dot. The design's 8 sat between the
                // wordmark and an Arabic transliteration of the brand name,
                // which is not rendered here — the brandmark is Latin in every
                // locale. Inheriting that 8 would leave the separator visibly
                // closer to the wordmark than to the tagline.
                SizedBox(height: AppSpacing.l),
                const _AccentDot(),
                SizedBox(height: AppSpacing.l),
                Text(
                  l10n.splashTagline,
                  textAlign: TextAlign.center,
                  style: textTheme.bodyMedium?.copyWith(
                    color: mutedText,
                    fontWeight: _lightWeight,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The 4x4 accent dot separating the wordmark from the tagline.
class _AccentDot extends StatelessWidget {
  const _AccentDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: AppSpacing.xxs,
      height: AppSpacing.xxs,
      decoration: BoxDecoration(
        color: AppColors.accent,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      // Purely decorative: it carries no meaning a screen reader should
      // announce, and an unlabelled node would otherwise be traversed.
      child: const ExcludeSemantics(child: SizedBox.shrink()),
    );
  }
}
