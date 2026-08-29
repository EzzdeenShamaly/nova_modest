import 'package:flutter/material.dart';
import 'package:nova_modest/core/theme/app_colors.dart';
import 'package:nova_modest/core/theme/app_dimensions.dart';
import 'package:nova_modest/features/catalog/domain/entities/product_sort.dart';
import 'package:nova_modest/l10n/app_localizations.dart';

/// Opens the ordering options, returning the chosen one or null if dismissed.
///
/// The design names the control ("ترتيب") but does not draw the menu behind it,
/// so this borrows the filter sheet's chrome rather than inventing a third
/// surface — one sheet shape for both controls on the same row.
Future<ProductSort?> showProductSortSheet({
  required BuildContext context,
  required ProductSort sort,
}) => showModalBottomSheet<ProductSort>(
  context: context,
  backgroundColor: AppColors.background,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadiusDirectional.only(
      topStart: Radius.circular(AppRadius.l),
      topEnd: Radius.circular(AppRadius.l),
    ),
  ),
  builder: (sheetContext) {
    final l10n = AppLocalizations.of(sheetContext);
    final textTheme = Theme.of(sheetContext).textTheme;

    String labelFor(ProductSort option) => switch (option) {
      ProductSort.relevance => l10n.searchSortRelevance,
      ProductSort.priceAscending => l10n.searchSortPriceAscending,
      ProductSort.priceDescending => l10n.searchSortPriceDescending,
    };

    return SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsetsDirectional.all(AppSpacing.l),
            child: Text(l10n.searchSort, style: textTheme.headlineMedium),
          ),
          for (final option in ProductSort.values)
            ListTile(
              title: Text(labelFor(option), style: textTheme.bodyLarge),
              trailing: option == sort
                  ? Icon(
                      Icons.check,
                      size: AppFontSize.xl,
                      color: AppColors.accent,
                      semanticLabel: '',
                    )
                  : null,
              selected: option == sort,
              onTap: () => Navigator.of(sheetContext).pop(option),
            ),
          SizedBox(height: AppSpacing.m),
        ],
      ),
    );
  },
);
