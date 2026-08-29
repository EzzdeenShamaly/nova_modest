import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:nova_modest/core/theme/app_colors.dart';
import 'package:nova_modest/core/theme/app_dimensions.dart';
import 'package:nova_modest/features/catalog/domain/entities/product.dart';
import 'package:nova_modest/l10n/app_localizations.dart';

/// One product in the featured grid.
///
/// Built from the design's 169x310 card: a 169x254 artwork well with the
/// favourite control pinned to its top start corner, then the name and price.
///
/// Shared by Home and the product listing. A sold-out product swaps the
/// favourite control for a scrim and a badge, and stops responding to taps —
/// driven by `Product.isSoldOut`, so both screens agree without either knowing
/// about the other.
class ProductCard extends StatelessWidget {
  const ProductCard({
    required this.product,
    this.onTap,
    this.onFavouriteTap,
    super.key,
  });

  final Product product;
  final VoidCallback? onTap;
  final VoidCallback? onFavouriteTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;

    // Locale-aware placement: Arabic puts the symbol after the amount and adds a
    // right-to-left mark, English puts it before. intl does **not** substitute
    // Arabic-Indic digits here — CLDR's default numbering for `ar` is Latin, and
    // Gulf commerce follows it.
    final price = NumberFormat.currency(
      locale: Localizations.localeOf(context).toLanguageTag(),
      symbol: l10n.currencySymbol,
      decimalDigits: 0,
    ).format(product.price);

    return InkWell(
      // A sold-out product is not openable: offering a tap that leads to a page
      // you cannot buy from is worse than no tap.
      onTap: product.isSoldOut ? null : onTap,
      borderRadius: BorderRadius.circular(AppRadius.s),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Expanded, not AspectRatio: the artwork takes whatever the grid cell
          // leaves after the text, so the card cannot overflow at any cell
          // ratio or text scale. Fixing the artwork's ratio instead left Home
          // clearing its cell by 0.2pt and this screen overflowing by 3.5 —
          // the same card, two grids, one of them wrong.
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.s),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _Artwork(imageUrl: product.imageUrl),
                  if (product.isSoldOut)
                    _SoldOutOverlay(label: l10n.productSoldOut)
                  else
                    PositionedDirectional(
                      top: AppSpacing.xs,
                      start: AppSpacing.xs,
                      child: _FavouriteButton(
                        selected: product.isFavourite,
                        label: l10n.homeFavourite,
                        onTap: onFavouriteTap,
                      ),
                    ),
                ],
              ),
            ),
          ),
          SizedBox(height: AppSpacing.xs),
          Text(
            product.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: textTheme.bodyMedium,
          ),
          SizedBox(height: AppSpacing.xxs),
          Text(
            price,
            // The price is the one accent-coloured element on the card, exactly
            // as the design has it.
            style: textTheme.bodyMedium?.copyWith(color: AppColors.accent),
          ),
        ],
      ),
    );
  }
}

/// The artwork well, or its stand-in.
///
/// [imageUrl] is null throughout the fake catalogue: there is no photography
/// yet. Supplying a URL later is the only change needed — the well keeps its
/// size either way, so nothing relayouts.
class _Artwork extends StatelessWidget {
  const _Artwork({this.imageUrl});

  final String? imageUrl;

  static const double _placeholderIcon = 32;

  @override
  Widget build(BuildContext context) {
    if (imageUrl != null) {
      return Image.network(
        imageUrl!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stack) => const _ArtworkPlaceholder(),
      );
    }
    return const _ArtworkPlaceholder();
  }
}

class _ArtworkPlaceholder extends StatelessWidget {
  const _ArtworkPlaceholder();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      // The design's #EBE7E6 — derived from the palette rather than added to it.
      color: AppColors.hairline,
      child: Center(
        child: Icon(
          Icons.checkroom_outlined,
          size: _Artwork._placeholderIcon,
          color: AppColors.subtle,
          semanticLabel: '',
        ),
      ),
    );
  }
}

/// The heart control in the artwork's corner.
class _FavouriteButton extends StatelessWidget {
  const _FavouriteButton({
    required this.selected,
    required this.label,
    required this.onTap,
  });

  final bool selected;
  final String label;
  final VoidCallback? onTap;

  /// The design's 36x41 pill, kept as a local constant: one element on one
  /// widget (`12-flutter-design-system-guard.md` §5).
  static const double _size = 36;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      // container: the heart is a control in its own right. Without this its
      // label merges into the card's node and a screen reader announces one
      // blurred string instead of a product and a button.
      container: true,
      button: true,
      selected: selected,
      label: label,
      child: Material(
        color: AppColors.background,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox.square(
            dimension: _size,
            child: Icon(
              selected ? Icons.favorite : Icons.favorite_border,
              size: AppFontSize.xl,
              color: selected ? AppColors.accent : AppColors.primaryText,
              semanticLabel: '',
            ),
          ),
        ),
      ),
    );
  }
}

/// The scrim and badge a sold-out product wears.
class _SoldOutOverlay extends StatelessWidget {
  const _SoldOutOverlay({required this.label});

  final String label;

  /// The design washes the artwork out rather than hiding it.
  static const double _scrimAlpha = 0.6;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(color: AppColors.background.withValues(alpha: _scrimAlpha)),
        Center(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.secondary,
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: Padding(
              padding: EdgeInsetsDirectional.symmetric(
                horizontal: AppSpacing.s,
                vertical: AppSpacing.xxs,
              ),
              child: Text(
                label,
                style: Theme.of(
                  context,
                ).textTheme.labelMedium?.copyWith(color: AppColors.muted),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
