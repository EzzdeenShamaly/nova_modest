import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nova_modest/core/theme/app_colors.dart';
import 'package:nova_modest/core/theme/app_dimensions.dart';
import 'package:nova_modest/core/widgets/settings_card.dart';
import 'package:nova_modest/l10n/app_localizations.dart';

/// Help and support.
///
/// **No Figma frame exists for this one.** The closest candidate, `1:2163`
/// "معلومات التواصل", is **checkout step 1** — its indicator layer is named
/// "الخطوة 1 من 3" — not a support screen. (An earlier note here called it step
/// 3 of sign-up: the dots were read left to right, and in RTL the active first
/// one is the rightmost.) The layout below is therefore assembled from the
/// vocabulary the account section already uses: a titled card of rows,
/// hairlines between them.
///
/// Static by design — no bloc, no repository, no request. Everything on it is
/// either a localized string or a constant.
class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(centerTitle: true, title: Text(l10n.profileHelp)),
      body: ListView(
        padding: EdgeInsetsDirectional.all(AppSpacing.l),
        children: [
          Text(l10n.helpFaqTitle, style: textTheme.headlineMedium),
          SizedBox(height: AppSpacing.m),
          SettingsCard(
            children: [for (final entry in _faq(l10n)) _Question(entry: entry)],
          ),
          SizedBox(height: AppSpacing.xl),
          Text(l10n.helpContactTitle, style: textTheme.headlineMedium),
          SizedBox(height: AppSpacing.m),
          SettingsCard(
            children: [
              _ContactRow(
                icon: Icons.mail_outline,
                label: l10n.helpContactEmail,
                value: _supportEmail,
              ),
              _ContactRow(
                icon: Icons.phone_outlined,
                label: l10n.helpContactPhone,
                value: _supportPhone,
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// **Demo values** (user, 2026-08-23) — not a real inbox or a real line.
  /// Replace both before anything ships to a shopper.
  ///
  /// Not ARB strings: an address and a number are the same kind of content as a
  /// product's price, identical in every language, and a translator has no
  /// business editing them.
  static const String _supportEmail = 'support@novamodest.com';
  static const String _supportPhone = '+966 50 000 0000';

  /// The questions this app can answer **truthfully today**.
  ///
  /// Deliberately short. Shipping windows, return policy, payment methods and
  /// order tracking are the ones a shopper actually asks, and every one of them
  /// is a business fact nobody has stated — writing a plausible answer would put
  /// an invented policy in front of a customer as though it were the shop's
  /// (`10-evidence-and-dependency-guard.md`). Each entry below is something the
  /// code demonstrably does.
  static List<({String question, String answer})> _faq(
    AppLocalizations l10n,
  ) => [
    (question: l10n.helpFaqSignInQuestion, answer: l10n.helpFaqSignInAnswer),
    (question: l10n.helpFaqEmailQuestion, answer: l10n.helpFaqEmailAnswer),
    (
      question: l10n.helpFaqLanguageQuestion,
      answer: l10n.helpFaqLanguageAnswer,
    ),
    (question: l10n.helpFaqAddressQuestion, answer: l10n.helpFaqAddressAnswer),
  ];
}

/// The account section's card, hand-built here.
///
/// The **third** near-identical one, after the account menu's and the language
/// chooser's. Kept local on purpose: promoting a shared card means editing two
/// screens that work, in the middle of a change that has nothing to do with
/// them (`09-minimal-changes.md`). Recorded in progress.md as its own task.

class _Question extends StatelessWidget {
  const _Question({required this.entry});

  final ({String question, String answer}) entry;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return ExpansionTile(
      // The card draws the rules between rows, so the tile must not add its
      // own borders on top of them.
      shape: const Border(),
      collapsedShape: const Border(),
      iconColor: AppColors.muted,
      collapsedIconColor: AppColors.muted,
      tilePadding: EdgeInsetsDirectional.symmetric(horizontal: AppSpacing.m),
      childrenPadding: EdgeInsetsDirectional.only(
        start: AppSpacing.m,
        end: AppSpacing.m,
        bottom: AppSpacing.m,
      ),
      expandedCrossAxisAlignment: CrossAxisAlignment.start,
      title: Text(entry.question, style: textTheme.bodyLarge),
      children: [
        Text(
          entry.answer,
          style: textTheme.bodyMedium?.copyWith(color: AppColors.mutedStrong),
        ),
      ],
    );
  }
}

/// A support detail, copied to the clipboard on tap.
///
/// Copying rather than opening: launching a mail app or a dialler needs
/// `url_launcher`, which is not in `pubspec.yaml` and would need to be asked
/// for explicitly (`10-evidence-and-dependency-guard.md`). `Clipboard` ships
/// with Flutter and makes the row genuinely useful today.
class _ContactRow extends StatelessWidget {
  const _ContactRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  /// The same 56pt row the account menu uses.
  static const double _rowHeight = 56;

  Future<void> _copy(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    await Clipboard.setData(ClipboardData(text: value));
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.helpCopied)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;

    return Semantics(
      button: true,
      label: '$label: $value',
      child: InkWell(
        onTap: () => _copy(context),
        child: SizedBox(
          height: _rowHeight,
          child: Padding(
            padding: EdgeInsetsDirectional.symmetric(horizontal: AppSpacing.m),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: AppFontSize.xl,
                  color: AppColors.mutedStrong,
                  semanticLabel: '',
                ),
                SizedBox(width: AppSpacing.m),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        label,
                        style: textTheme.labelMedium?.copyWith(
                          color: AppColors.muted,
                        ),
                        semanticsLabel: '',
                      ),
                      Text(
                        value,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        // direction-fixed: an address and a dialling number read
                        // left to right in every locale
                        textDirection: TextDirection.ltr,
                        textAlign: TextAlign.start,
                        style: textTheme.bodyMedium,
                        semanticsLabel: '',
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.copy_outlined,
                  size: AppFontSize.l,
                  color: AppColors.subtle,
                  semanticLabel: l10n.helpCopy,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
