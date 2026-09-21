import 'package:flutter/material.dart';
import 'package:nova_modest/core/theme/app_dimensions.dart';
import 'package:nova_modest/l10n/app_localizations.dart';

/// The terms and conditions.
///
/// **No Figma frame exists for this one** — checked against all 38 frames in the
/// file, none of which is a terms, policy or privacy screen. The second such
/// screen after help.
///
/// The text arrived on 2026-09-21, reviewed and approved clause by clause by the
/// owner. Until then this screen said the terms were not written rather than
/// approximating them, and that was the right call: **nothing here is drafted
/// legal wording**. Every operational clause states what the app and the
/// database actually do — the cart's limits, the fees, what "confirmed" means,
/// who can read an order — and the commercial ones (the seven-day return window,
/// delivery inside the Kingdom, the governing law, the age) are the owner's
/// decisions, given in his words.
///
/// One key per locale rather than a key per section: it is one document, and a
/// translator handed thirteen fragments cannot see how they read together.
///
/// Laid out as flowing prose rather than inside a card — paragraphs to read, not
/// rows to scan.
///
/// Static: no bloc, no repository, no request.
class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(centerTitle: true, title: Text(l10n.profileTerms)),
      body: ListView(
        padding: EdgeInsetsDirectional.all(AppSpacing.l),
        children: [
          Text(
            l10n.termsBody,
            // start, not center: this is a document. Centred prose is unreadable
            // past a couple of lines, and it mirrors with the locale.
            textAlign: TextAlign.start,
            style: textTheme.bodyLarge?.copyWith(height: _lineHeight),
          ),
          // Clear of the gesture bar, so the last clause is not the one line
          // nobody can read comfortably.
          SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }

  /// Line spacing for prose. A ratio, not a measurement on the spacing scale —
  /// it multiplies the font size rather than adding to a layout
  /// (`12-flutter-design-system-guard.md` leaves ratios alone).
  static const double _lineHeight = 1.6;
}
