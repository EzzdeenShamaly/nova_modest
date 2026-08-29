import 'package:flutter/material.dart';
import 'package:nova_modest/core/theme/app_colors.dart';
import 'package:nova_modest/core/theme/app_dimensions.dart';
import 'package:nova_modest/l10n/app_localizations.dart';

/// A wrap of search terms as pills.
///
/// One widget for both sections of the discovery screen: recent searches carry
/// a remove control, trending terms do not. The design draws them identically
/// otherwise, and [onRemoved] being null is the whole difference — two widgets
/// would be the same file twice.
class SearchTermChips extends StatelessWidget {
  const SearchTermChips({
    required this.terms,
    required this.onSelected,
    this.onRemoved,
    super.key,
  });

  final List<String> terms;
  final ValueChanged<String> onSelected;

  /// Null for a list that cannot be edited.
  final ValueChanged<String>? onRemoved;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.s,
      runSpacing: AppSpacing.s,
      children: [
        for (final term in terms)
          _TermChip(
            term: term,
            onTap: () => onSelected(term),
            onRemove: onRemoved == null ? null : () => onRemoved!(term),
          ),
      ],
    );
  }
}

class _TermChip extends StatelessWidget {
  const _TermChip({
    required this.term,
    required this.onTap,
    required this.onRemove,
  });

  final String term;
  final VoidCallback onTap;
  final VoidCallback? onRemove;

  /// The design's 8x8 glyph. Smaller than anything on the font scale, because
  /// it is a mark on a chip rather than text.
  static const double _removeIcon = 12;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Material(
      color: AppColors.secondary,
      shape: StadiumBorder(side: BorderSide(color: AppColors.muted)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsetsDirectional.symmetric(
            horizontal: AppSpacing.m,
            vertical: AppSpacing.xs,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(term, style: Theme.of(context).textTheme.bodyMedium),
              if (onRemove != null) ...[
                SizedBox(width: AppSpacing.xs),
                // A separate tap target inside the chip: tapping the word runs
                // the search, tapping the mark forgets it.
                InkWell(
                  onTap: onRemove,
                  customBorder: const CircleBorder(),
                  child: Semantics(
                    button: true,
                    label: l10n.searchRemoveTerm,
                    child: Icon(
                      Icons.close,
                      size: _removeIcon,
                      color: AppColors.mutedStrong,
                      semanticLabel: '',
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
