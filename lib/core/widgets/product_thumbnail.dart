import 'package:flutter/material.dart';
import 'package:nova_modest/core/theme/app_colors.dart';
import 'package:nova_modest/core/theme/app_dimensions.dart';

/// A product's picture at a fixed size, or the palette placeholder standing in
/// for photography that does not exist yet.
///
/// Lifted out of `CartItemTile`, where it started as a private `_Artwork`, when
/// the review step needed the same box at a different size. Two copies of "how
/// this app draws a product image, and what it draws when there isn't one"
/// would have drifted the first time a real URL arrived.
///
/// [width] and [height] are the caller's: the cart draws 96x144 and the review
/// 80x96, both fixed by their own layout rather than by a shared scale.
class ProductThumbnail extends StatelessWidget {
  const ProductThumbnail({
    required this.images,
    required this.width,
    required this.height,
    required this.iconSize,
    super.key,
  });

  final List<String> images;
  final double width;
  final double height;

  /// Sized to the box above rather than to the type scale, so it is a property
  /// of that box and not a value on the font scale.
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final placeholder = Center(
      child: Icon(
        Icons.checkroom_outlined,
        size: iconSize,
        color: AppColors.subtle,
        semanticLabel: '',
      ),
    );

    return SizedBox(
      width: width,
      height: height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.s),
        child: ColoredBox(
          color: AppColors.hairline,
          // No photography exists yet, so the palette placeholder stands in.
          // Supplying URLs later turns the image on with no other change.
          child: images.isEmpty
              ? placeholder
              : Image.network(
                  images.first,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stack) => placeholder,
                ),
        ),
      ),
    );
  }
}
