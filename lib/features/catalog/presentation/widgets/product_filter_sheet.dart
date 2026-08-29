import 'package:flutter/material.dart';
// hide TextDirection: intl exports a class of the same name, which shadows
// dart:ui's and silently breaks every directional literal in this file.
import 'package:intl/intl.dart' hide TextDirection;
import 'package:nova_modest/core/theme/app_colors.dart';
import 'package:nova_modest/core/theme/app_dimensions.dart';
import 'package:nova_modest/features/catalog/domain/entities/product.dart';
import 'package:nova_modest/features/catalog/domain/entities/product_filter.dart';
import 'package:nova_modest/features/catalog/domain/entities/product_filter_options.dart';
import 'package:nova_modest/features/catalog/presentation/widgets/colour_swatch_row.dart';
import 'package:nova_modest/l10n/app_localizations.dart';

/// Opens the shared filter sheet, built from Figma frame `1:1180`.
///
/// Returns the filter the shopper applied, or `null` if they dismissed the
/// sheet — so a caller can tell "cleared everything" from "changed nothing".
///
/// One sheet serves both the product listing and search. Each facet draws only
/// when [ProductFilterOptions] has more than one value for it, so a
/// single-category listing shows just its tags and a search across the whole
/// catalogue shows everything, with no special case in either caller.
Future<ProductFilter?> showProductFilterSheet({
  required BuildContext context,
  required List<Product> products,
  required ProductFilterOptions options,
  required ProductFilter filter,
}) => showModalBottomSheet<ProductFilter>(
  context: context,
  backgroundColor: AppColors.background,
  // The design's sheet is most of the screen and its content scrolls; the
  // default sheet caps at half and would clip the footer.
  isScrollControlled: true,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadiusDirectional.only(
      topStart: Radius.circular(AppRadius.l),
      topEnd: Radius.circular(AppRadius.l),
    ),
  ),
  builder: (sheetContext) =>
      _ProductFilterSheet(products: products, options: options, filter: filter),
);

class _ProductFilterSheet extends StatefulWidget {
  const _ProductFilterSheet({
    required this.products,
    required this.options,
    required this.filter,
  });

  final List<Product> products;
  final ProductFilterOptions options;
  final ProductFilter filter;

  @override
  State<_ProductFilterSheet> createState() => _ProductFilterSheetState();
}

class _ProductFilterSheetState extends State<_ProductFilterSheet> {
  /// The pending filter.
  ///
  /// `setState` is right here and nowhere else in this feature: nothing outside
  /// the sheet may see a facet the shopper has not applied yet, and the draft
  /// dies with the sheet (`02-flutter-state-guard.md`).
  late ProductFilter _draft = widget.filter;

  /// The design's sheet is 751 of 904 — a little over four fifths of the
  /// screen. Expressed as a fraction so it adapts instead of pinning a height.
  static const double _heightFraction = 0.83;

  void _update(ProductFilter next) => setState(() => _draft = next);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final options = widget.options;
    final matches = _draft.apply(widget.products).length;

    final money = NumberFormat.currency(
      locale: Localizations.localeOf(context).toLanguageTag(),
      symbol: l10n.currencySymbol,
      decimalDigits: 0,
    );

    return FractionallySizedBox(
      heightFactor: _heightFraction,
      child: Column(
        children: [
          _Header(
            onClear: _draft.isEmpty ? null : () => _update(ProductFilter.none),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsetsDirectional.all(AppSpacing.l),
              children: [
                if (options.hasCategories)
                  _Section(
                    title: l10n.filterCategory,
                    child: _CheckboxList(
                      entries: [
                        for (final category in options.categories)
                          (id: category.id, label: category.name),
                      ],
                      selected: _draft.categoryIds,
                      onToggled: (ids) =>
                          _update(_draft.copyWith(categoryIds: ids)),
                    ),
                  ),
                if (options.hasTags)
                  _Section(
                    title: l10n.filterStyle,
                    child: _PillWrap(
                      entries: [
                        for (final tag in options.tags)
                          (id: tag.id, label: tag.name),
                      ],
                      selected: {?_draft.tagId},
                      // Single-select, unlike the rest: choosing a second style
                      // replaces the first rather than adding to it.
                      onTap: (id) => _update(
                        _draft.copyWith(tagId: _draft.tagId == id ? null : id),
                      ),
                    ),
                  ),
                if (options.hasPriceRange)
                  _Section(
                    title: l10n.filterPriceRange,
                    trailing: Text(
                      l10n.filterPriceRangeValue(
                        money.format(_draft.minPrice ?? options.minPrice!),
                        money.format(_draft.maxPrice ?? options.maxPrice!),
                      ),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.mutedStrong,
                      ),
                    ),
                    child: RangeSlider(
                      min: options.minPrice!.toDouble(),
                      max: options.maxPrice!.toDouble(),
                      activeColor: AppColors.accent,
                      inactiveColor: AppColors.secondary,
                      values: RangeValues(
                        (_draft.minPrice ?? options.minPrice!).toDouble(),
                        (_draft.maxPrice ?? options.maxPrice!).toDouble(),
                      ),
                      onChanged: (range) => _update(
                        _draft.copyWith(
                          minPrice: range.start.roundToDouble(),
                          maxPrice: range.end.roundToDouble(),
                        ),
                      ),
                    ),
                  ),
                if (options.hasSizes)
                  _Section(
                    title: l10n.productSize,
                    child: _PillWrap(
                      entries: [
                        for (final size in options.sizes)
                          (id: size, label: size),
                      ],
                      selected: _draft.sizes,
                      // direction-fixed: size codes are Latin in every locale
                      labelDirection: TextDirection.ltr,
                      onTap: (id) => _update(
                        _draft.copyWith(sizes: _toggled(_draft.sizes, id)),
                      ),
                    ),
                  ),
                if (options.hasColours)
                  _Section(
                    title: l10n.productColour,
                    child: Wrap(
                      spacing: AppSpacing.m,
                      runSpacing: AppSpacing.m,
                      children: [
                        for (final colour in options.colours)
                          ColourSwatch(
                            colour: colour,
                            selected: _draft.colourIds.contains(colour.id),
                            onTap: () => _update(
                              _draft.copyWith(
                                colourIds: _toggled(
                                  _draft.colourIds,
                                  colour.id,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          _Footer(
            matches: matches,
            onReset: () => _update(ProductFilter.none),
            onApply: () => Navigator.of(context).pop(_draft),
          ),
        ],
      ),
    );
  }

  static Set<String> _toggled(Set<String> current, String id) =>
      current.contains(id) ? ({...current}..remove(id)) : {...current, id};
}

class _Header extends StatelessWidget {
  const _Header({required this.onClear});

  /// Null once nothing is set, so the control reflects the state rather than
  /// pretending there is something to clear.
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return DecoratedBox(
      decoration: const BoxDecoration(
        border: BorderDirectional(
          bottom: BorderSide(color: AppColors.secondary),
        ),
      ),
      child: Padding(
        padding: EdgeInsetsDirectional.symmetric(
          horizontal: AppSpacing.m,
          vertical: AppSpacing.xs,
        ),
        child: Row(
          children: [
            IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close),
              iconSize: AppFontSize.xl,
              color: AppColors.primaryText,
              tooltip: l10n.filterClose,
            ),
            Expanded(
              child: Text(
                l10n.filterTitle,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
            TextButton(onPressed: onClear, child: Text(l10n.filterClearAll)),
          ],
        ),
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({
    required this.matches,
    required this.onReset,
    required this.onApply,
  });

  final int matches;
  final VoidCallback onReset;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return DecoratedBox(
      decoration: const BoxDecoration(
        border: BorderDirectional(top: BorderSide(color: AppColors.secondary)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsetsDirectional.all(AppSpacing.m),
          // 1:2, as the design's 116.7 and 233.3 divide the row.
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onReset,
                  child: Text(l10n.filterReset),
                ),
              ),
              SizedBox(width: AppSpacing.s),
              Expanded(
                flex: 2,
                child: FilledButton(
                  onPressed: onApply,
                  child: Text(l10n.filterApply(matches)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A titled facet, with the design's small caps-style heading.
class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child, this.trailing});

  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsetsDirectional.only(bottom: AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(title, style: Theme.of(context).textTheme.labelMedium),
              if (trailing != null) ...[const Spacer(), trailing!],
            ],
          ),
          SizedBox(height: AppSpacing.m),
          child,
        ],
      ),
    );
  }
}

typedef _Entry = ({String id, String label});

class _CheckboxList extends StatelessWidget {
  const _CheckboxList({
    required this.entries,
    required this.selected,
    required this.onToggled,
  });

  final List<_Entry> entries;
  final Set<String> selected;
  final ValueChanged<Set<String>> onToggled;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final entry in entries)
          CheckboxListTile(
            value: selected.contains(entry.id),
            onChanged: (checked) => onToggled(
              (checked ?? false)
                  ? {...selected, entry.id}
                  : ({...selected}..remove(entry.id)),
            ),
            title: Text(
              entry.label,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            // The design's blue tick is Material's default, not this palette;
            // every other selected state in the same frame is the text colour.
            activeColor: AppColors.primaryText,
            checkColor: AppColors.background,
            contentPadding: EdgeInsetsDirectional.zero,
            controlAffinity: ListTileControlAffinity.trailing,
            dense: true,
          ),
      ],
    );
  }
}

/// The design's pill row, wrapping rather than overflowing.
class _PillWrap extends StatelessWidget {
  const _PillWrap({
    required this.entries,
    required this.selected,
    required this.onTap,
    this.labelDirection,
  });

  final List<_Entry> entries;
  final Set<String> selected;
  final ValueChanged<String> onTap;
  final TextDirection? labelDirection;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      children: [
        for (final entry in entries)
          _Pill(
            label: entry.label,
            selected: selected.contains(entry.id),
            labelDirection: labelDirection,
            onTap: () => onTap(entry.id),
          ),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.label,
    required this.selected,
    required this.labelDirection,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final TextDirection? labelDirection;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? AppColors.primaryText : AppColors.background,
        shape: StadiumBorder(
          side: BorderSide(
            color: selected ? AppColors.primaryText : AppColors.muted,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: EdgeInsetsDirectional.symmetric(
              horizontal: AppSpacing.l,
              vertical: AppSpacing.xs,
            ),
            child: Text(
              label,
              textDirection: labelDirection,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: selected ? AppColors.background : AppColors.primaryText,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
