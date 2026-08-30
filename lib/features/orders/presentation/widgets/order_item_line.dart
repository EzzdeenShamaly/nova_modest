import 'package:flutter/material.dart';
// hide TextDirection: intl exports a class of the same name, which shadows
// dart:ui's and silently breaks every directional literal in this file.
import 'package:intl/intl.dart' hide TextDirection;
import 'package:nova_modest/core/theme/app_colors.dart';
import 'package:nova_modest/core/theme/app_dimensions.dart';
import 'package:nova_modest/core/widgets/product_thumbnail.dart';
import 'package:nova_modest/features/cart/domain/entities/cart_item.dart';
import 'package:nova_modest/l10n/app_localizations.dart';

/// One ordered line, read-only: what was bought, in which colour and size, how
/// many, and for how much.
///
/// Drawn twice — by checkout's review step (`1:1840`, 80x96) and by the order
/// details screen (`1:1480`, 96x144). Started private to the review; lifted out
/// when the second caller arrived, for the reason `ProductThumbnail` was:
/// "how this app draws an ordered line" is one answer, and two copies of it
/// drift the first time anything changes.
///
/// Deliberately **not** `CartItemTile`: that one carries a quantity stepper and
/// a remove button, which is the cart's job. Nothing here may be changed, so
/// the quantity is text.
///
/// [imageWidth] and [imageHeight] are the caller's: each frame fixes its own,
/// and neither is a value on a shared scale.
class OrderItemLine extends StatelessWidget {
  const OrderItemLine({
    required this.item,
    required this.money,
    required this.imageWidth,
    required this.imageHeight,
    required this.placeholderIcon,
    super.key,
  });

  final CartItem item;
  final NumberFormat money;
  final double imageWidth;
  final double imageHeight;
  final double placeholderIcon;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ProductThumbnail(
          images: item.product.images,
          width: imageWidth,
          height: imageHeight,
          iconSize: placeholderIcon,
        ),
        SizedBox(width: AppSpacing.m),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.product.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: textTheme.titleSmall,
              ),
              if (_variantLine(l10n) case final line?) ...[
                SizedBox(height: AppSpacing.xxs),
                Text(
                  line,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodyMedium?.copyWith(color: AppColors.muted),
                ),
              ],
              SizedBox(height: AppSpacing.xs),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    money.format(item.lineTotal),
                    style: textTheme.titleSmall?.copyWith(
                      color: AppColors.accent,
                    ),
                  ),
                  Text(
                    l10n.reviewQuantity(item.quantity),
                    style: textTheme.bodyMedium?.copyWith(
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// The same three shapes the cart line draws, from the same ARB keys — one
  /// phrasing of "colour and size" in the app, not two.
  String? _variantLine(AppLocalizations l10n) =>
      switch ((item.colour?.name, item.size)) {
        (final colour?, final size?) => l10n.cartVariant(colour, size),
        (final colour?, null) => l10n.cartVariantColour(colour),
        (null, final size?) => l10n.cartVariantSize(size),
        _ => null,
      };
}
