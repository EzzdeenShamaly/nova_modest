import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nova_modest/core/theme/app_colors.dart';
import 'package:nova_modest/core/theme/app_dimensions.dart';
import 'package:nova_modest/features/settings/presentation/bloc/locale_bloc.dart';
import 'package:nova_modest/l10n/app_localizations.dart';

/// The language chooser, from Figma frame `1:1818`.
///
/// Reads and writes [LocaleBloc], which `MaterialApp` also reads — so choosing
/// here re-renders the entire interface, direction included, without leaving
/// this screen or restarting anything. That is the explanatory line's promise,
/// and it is why the locale is app-wide state rather than something this screen
/// owns.
class LanguageScreen extends StatelessWidget {
  const LanguageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(centerTitle: true, title: Text(l10n.profileLanguage)),
      body: BlocConsumer<LocaleBloc, LocaleState>(
        listenWhen: (previous, current) =>
            current is LocaleResolved && current.saveFailure != null,
        listener: (context, state) {
          // Looked up from the locale the state carries, not from the build
          // that registered this listener and not from `context` either.
          // Applying the locale and reporting the failed save are two emits in
          // one microtask, so this runs before any rebuild — the enclosing
          // `l10n` and the inherited Localizations both still hold the language
          // the shopper just left. This shows the message in the one they
          // chose.
          final chosen = lookupAppLocalizations(state.locale);
          // The language did change — this only says it will not be remembered.
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(chosen.languageNotSaved)));
        },
        builder: (context, state) => ListView(
          padding: EdgeInsetsDirectional.all(AppSpacing.l),
          children: [
            _OptionCard(selected: state.locale),
            SizedBox(height: AppSpacing.l),
            Text(
              l10n.languageExplanation,
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.mutedStrong,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The design's single card holding one row per supported language.
class _OptionCard extends StatelessWidget {
  const _OptionCard({required this.selected});

  final Locale selected;

  @override
  Widget build(BuildContext context) {
    const locales = AppLocalizations.supportedLocales;

    return Material(
      color: AppColors.secondary,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.m),
      ),
      child: Column(
        children: [
          for (final locale in locales) ...[
            _LanguageOption(
              locale: locale,
              selected: locale.languageCode == selected.languageCode,
              onTap: () => context.read<LocaleBloc>().add(
                LocaleSelected(locale.languageCode),
              ),
            ),
            if (locale != locales.last)
              // height 0: the rule alone, with none of the Divider theme's
              // surrounding space, because the rows carry their own.
              const Divider(height: 0, color: AppColors.secondary),
          ],
        ],
      ),
    );
  }
}

class _LanguageOption extends StatelessWidget {
  const _LanguageOption({
    required this.locale,
    required this.selected,
    required this.onTap,
  });

  final Locale locale;
  final bool selected;
  final VoidCallback onTap;

  /// The design's 56pt row, above the 48pt accessible minimum and specific to
  /// this component rather than a value on the spacing scale
  /// (`12-flutter-design-system-guard.md` §5).
  static const double _rowHeight = 56;

  /// The design's 24pt ring with a 12pt dot.
  static const double _ringSize = 24;
  static const double _dotSize = 12;

  /// Each language names itself, read from **that** locale's ARB rather than
  /// the one in force — so "العربية" stays Arabic while the interface is in
  /// English, which is the only way a chooser is usable to someone who cannot
  /// read the current language.
  String get _endonym => lookupAppLocalizations(locale).languageName;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      // Hand-written because the row is hand-built: this is what a
      // RadioListTile would have given for free, and losing it would make the
      // group unusable with a screen reader.
      inMutuallyExclusiveGroup: true,
      selected: selected,
      label: _endonym,
      child: Material(
        color: AppColors.background,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            height: _rowHeight,
            child: Padding(
              padding: EdgeInsetsDirectional.symmetric(
                horizontal: AppSpacing.m,
              ),
              child: Row(
                children: [
                  _Indicator(
                    selected: selected,
                    ringSize: _ringSize,
                    dotSize: _dotSize,
                  ),
                  SizedBox(width: AppSpacing.m),
                  Expanded(
                    child: Text(
                      _endonym,
                      // No textDirection: each label is one word in one script,
                      // and the engine resolves that per character from the
                      // string itself. Forcing LTR here would have laid
                      // "العربية" out backwards — the opposite of what a
                      // language chooser needs.
                      textAlign: TextAlign.start,
                      style: Theme.of(context).textTheme.bodyLarge,
                      // The label is on the Semantics above, so the glyphs
                      // would otherwise be announced twice.
                      semanticsLabel: '',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Indicator extends StatelessWidget {
  const _Indicator({
    required this.selected,
    required this.ringSize,
    required this.dotSize,
  });

  final bool selected;
  final double ringSize;
  final double dotSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: ringSize,
      height: ringSize,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.fromBorderSide(
          BorderSide(color: selected ? AppColors.accent : AppColors.subtle),
        ),
      ),
      // The frame draws a gold dot inside the *unselected* ring too, which is
      // a mock artefact — an unchosen radio has no dot.
      child: selected
          ? Container(
              width: dotSize,
              height: dotSize,
              decoration: const BoxDecoration(
                color: AppColors.accent,
                shape: BoxShape.circle,
              ),
            )
          : null,
    );
  }
}
