import 'package:flutter/material.dart';
// hide TextDirection: intl exports a class of the same name, which shadows
// dart:ui's and silently breaks every directional literal in this file.
import 'package:intl/intl.dart' hide TextDirection;
import 'package:nova_modest/core/theme/app_colors.dart';
import 'package:nova_modest/core/theme/app_dimensions.dart';
import 'package:nova_modest/core/widgets/product_thumbnail.dart';
import 'package:nova_modest/core/widgets/quantity_stepper.dart';
import 'package:nova_modest/features/cart/domain/entities/cart_item.dart';
import 'package:nova_modest/l10n/app_localizations.dart';

/// One line of the cart, as the design draws it: artwork at the start, then the
/// name and the choices, with the stepper and the line price beneath.
class CartItemTile extends StatelessWidget {
  const CartItemTile({
    required this.item,
    required this.onQuantityChanged,
    required this.onRemove,
    super.key,
  });

  final CartItem item;
  final ValueChanged<int> onQuantityChanged;
  final VoidCallback onRemove;

  /// The design's 96x144 thumbnail. Fixed by the artwork's aspect ratio, not
  /// part of the spacing rhythm, and used nowhere else.
  static const double _imageWidth = 96;
  static const double _imageHeight = 144;

  /// Sized to the thumbnail above rather than to the font scale, so it is a
  /// property of that box and not a value on the type scale.
  static const double _placeholderIcon = 32;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;

    final price = NumberFormat.currency(
      locale: Localizations.localeOf(context).toLanguageTag(),
      symbol: l10n.currencySymbol,
      decimalDigits: 0,
    ).format(item.lineTotal);

    // IntrinsicHeight so the details column knows the artwork's height and can
    // push the stepper row to the bottom, as the design does. A stretched Row
    // cannot: inside a scrollable its height constraint is unbounded.
    //
    // The rule beneath each line and the space around it belong to the list, not
    // to the tile — see the Divider in the cart screen's body.
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ProductThumbnail(
            images: item.product.images,
            width: _imageWidth,
            height: _imageHeight,
            iconSize: _placeholderIcon,
          ),
          SizedBox(width: AppSpacing.s),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.product.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.bodyLarge,
                          ),
                          if (_variantLine(l10n) case final line?) ...[
                            SizedBox(height: AppSpacing.xxs),
                            Text(
                              line,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: textTheme.bodyMedium?.copyWith(
                                color: AppColors.mutedStrong,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: onRemove,
                      icon: const Icon(Icons.close),
                      iconSize: AppFontSize.l,
                      color: AppColors.mutedStrong,
                      tooltip: l10n.cartRemoveItem,
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
                Row(
                  children: [
                    QuantityStepper(
                      value: item.quantity,
                      min: 1,
                      max: CartItem.maxQuantity,
                      variant: QuantityStepperVariant.outlined,
                      onChanged: onQuantityChanged,
                    ),
                    SizedBox(width: AppSpacing.s),
                    // The design puts the price at the far end of the line,
                    // away from the artwork. Expanded rather than a Spacer:
                    // a Spacer would claim the free space the price needs.
                    Expanded(
                      child: Text(
                        price,
                        maxLines: 1,
                        textAlign: TextAlign.end,
                        overflow: TextOverflow.ellipsis,
                        // The design's 20/w500 price.
                        style: textTheme.headlineMedium?.copyWith(
                          color: AppColors.accent,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// The "colour | size" line, composed from whichever choices the product
  /// actually offers.
  ///
  /// Three ARB entries rather than joining translated fragments in code: the
  /// separator and the word order belong to the translator
  /// (`11-flutter-l10n-guard` §1).
  String? _variantLine(AppLocalizations l10n) {
    final colour = item.colour?.name;
    final size = item.size;
    return switch ((colour, size)) {
      (final c?, final s?) => l10n.cartVariant(c, s),
      (final c?, null) => l10n.cartVariantColour(c),
      (null, final s?) => l10n.cartVariantSize(s),
      (null, null) => null,
    };
  }
}
