import 'package:flutter/material.dart';
import 'package:nova_modest/core/theme/app_colors.dart';
import 'package:nova_modest/core/theme/app_dimensions.dart';
import 'package:nova_modest/l10n/app_localizations.dart';

/// The terms and conditions.
///
/// **No Figma frame exists for this one** — checked against all 38 frames in the
/// file, none of which is a terms, policy or privacy screen. The second such
/// screen after help.
///
/// The body is a **stand-in on purpose**. Real terms are a business decision,
/// not a technical one, and drafting plausible clauses would put invented legal
/// text in front of a customer as though it were the shop's — the same call made
/// for the FAQ's shipping and returns answers
/// (`10-evidence-and-dependency-guard.md`).
///
/// Laid out as flowing prose rather than inside a card: that is what this screen
/// becomes once the real text arrives — paragraphs to read, not rows to scan —
/// and it avoids a fourth copy of the card-of-rows already recorded for
/// promotion.
///
/// Static: no bloc, no repository, no request.
class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  /// The illustration stands in for artwork that does not exist yet.
  static const double _iconSize = 56;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(centerTitle: true, title: Text(l10n.profileTerms)),
      body: ListView(
        padding: EdgeInsetsDirectional.all(AppSpacing.l),
        children: [
          SizedBox(height: AppSpacing.xxl),
          Icon(
            Icons.description_outlined,
            size: _iconSize,
            color: AppColors.subtle,
            // Decorative: the text below carries the meaning.
            semanticLabel: '',
          ),
          SizedBox(height: AppSpacing.l),
          Text(
            l10n.termsPlaceholder,
            textAlign: TextAlign.center,
            style: textTheme.bodyLarge?.copyWith(height: _lineHeight),
          ),
          SizedBox(height: AppSpacing.s),
          Text(
            l10n.termsPlaceholderNote,
            textAlign: TextAlign.center,
            style: textTheme.bodyMedium?.copyWith(
              color: AppColors.muted,
              height: _lineHeight,
            ),
          ),
        ],
      ),
    );
  }

  /// Line spacing for prose. A ratio, not a measurement on the spacing scale —
  /// it multiplies the font size rather than adding to a layout
  /// (`12-flutter-design-system-guard.md` leaves ratios alone).
  static const double _lineHeight = 1.6;
}
