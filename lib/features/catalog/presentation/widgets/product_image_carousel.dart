import 'package:flutter/material.dart';
import 'package:nova_modest/core/theme/app_colors.dart';
import 'package:nova_modest/core/theme/app_dimensions.dart';
import 'package:nova_modest/l10n/app_localizations.dart';

/// The product's artwork, with page indicators and the favourite control.
///
/// No photography exists yet, so [images] is empty and a single palette
/// placeholder is drawn — with no indicators, because one page has nothing to
/// indicate. Supplying URLs later turns the carousel on with no other change.
class ProductImageCarousel extends StatefulWidget {
  const ProductImageCarousel({
    required this.images,
    required this.isFavourite,
    this.onFavouriteTap,
    super.key,
  });

  final List<String> images;
  final bool isFavourite;
  final VoidCallback? onFavouriteTap;

  /// The design's 390x530 band, as a ratio so it adapts to the screen.
  static const double _aspect = 390 / 530;

  @override
  State<ProductImageCarousel> createState() => _ProductImageCarouselState();
}

class _ProductImageCarouselState extends State<ProductImageCarousel> {
  final PageController _controller = PageController();
  int _page = 0;

  static const double _placeholderIcon = 72;
  static const double _favouriteSize = 48;
  static const double _dotSize = 8;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final pageCount = widget.images.isEmpty ? 1 : widget.images.length;

    return AspectRatio(
      aspectRatio: ProductImageCarousel._aspect,
      child: ColoredBox(
        color: AppColors.hairline,
        child: Stack(
          children: [
            Positioned.fill(
              child: widget.images.isEmpty
                  ? const _ArtworkPlaceholder(size: _placeholderIcon)
                  : PageView.builder(
                      controller: _controller,
                      itemCount: widget.images.length,
                      onPageChanged: (page) => setState(() => _page = page),
                      itemBuilder: (context, index) => Image.network(
                        widget.images[index],
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stack) =>
                            const _ArtworkPlaceholder(size: _placeholderIcon),
                      ),
                    ),
            ),
            SafeArea(
              child: Align(
                alignment: AlignmentDirectional.topStart,
                child: Padding(
                  padding: EdgeInsetsDirectional.all(AppSpacing.m),
                  child: _FavouriteButton(
                    size: _favouriteSize,
                    selected: widget.isFavourite,
                    onTap: widget.onFavouriteTap,
                  ),
                ),
              ),
            ),
            if (pageCount > 1)
              Align(
                alignment: AlignmentDirectional.bottomCenter,
                child: Padding(
                  padding: EdgeInsetsDirectional.only(bottom: AppSpacing.m),
                  child: Semantics(
                    container: true,
                    label: l10n.productImageCount(_page + 1, pageCount),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (var index = 0; index < pageCount; index++)
                          Padding(
                            padding: EdgeInsetsDirectional.symmetric(
                              horizontal: AppSpacing.xxs,
                            ),
                            child: Container(
                              width: _dotSize,
                              height: _dotSize,
                              decoration: BoxDecoration(
                                // The design fades the inactive dots rather
                                // than recolouring them.
                                color: index == _page
                                    ? AppColors.primaryText
                                    : AppColors.subtle,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ArtworkPlaceholder extends StatelessWidget {
  const _ArtworkPlaceholder({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) => Center(
    child: Icon(
      Icons.checkroom_outlined,
      size: size,
      color: AppColors.subtle,
      semanticLabel: '',
    ),
  );
}

class _FavouriteButton extends StatelessWidget {
  const _FavouriteButton({
    required this.size,
    required this.selected,
    required this.onTap,
  });

  final double size;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      button: true,
      selected: selected,
      label: AppLocalizations.of(context).homeFavourite,
      child: Material(
        color: AppColors.background,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox.square(
            dimension: size,
            child: Icon(
              selected ? Icons.favorite : Icons.favorite_border,
              size: AppFontSize.xxl,
              color: selected ? AppColors.accent : AppColors.primaryText,
              semanticLabel: '',
            ),
          ),
        ),
      ),
    );
  }
}
