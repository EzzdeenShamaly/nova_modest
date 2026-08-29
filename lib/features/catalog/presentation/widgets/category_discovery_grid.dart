import 'package:flutter/material.dart';
import 'package:nova_modest/core/theme/app_colors.dart';
import 'package:nova_modest/core/theme/app_dimensions.dart';
import 'package:nova_modest/features/catalog/domain/entities/product_category.dart';

/// The "explore categories" cards on the search screen, from Figma `1:1282`.
///
/// Two columns of artwork with the category name burned over the bottom. There
/// is no photography yet, so each card draws the same palette placeholder every
/// other screen uses; the gradient stays either way, because it is what keeps
/// the name legible once real images arrive.
class CategoryDiscoveryGrid extends StatelessWidget {
  const CategoryDiscoveryGrid({
    required this.categories,
    required this.onSelected,
    super.key,
  });

  final List<ProductCategory> categories;
  final ValueChanged<ProductCategory> onSelected;

  /// The design's 169x202.8 card, as a ratio so it adapts to the screen.
  static const double _cardAspect = 169 / 202.8;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsetsDirectional.zero,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: AppSpacing.s,
        crossAxisSpacing: AppSpacing.s,
        childAspectRatio: _cardAspect,
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) => _CategoryCard(
        category: categories[index],
        onTap: () => onSelected(categories[index]),
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({required this.category, required this.onTap});

  final ProductCategory category;
  final VoidCallback onTap;

  /// Sized to the card above, not to the type scale: it stands in for the
  /// artwork rather than reading as text.
  static const double _placeholderIcon = 40;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: category.name,
      child: Material(
        color: AppColors.hairline,
        borderRadius: BorderRadius.circular(AppRadius.s),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Center(
                child: Icon(
                  Icons.checkroom_outlined,
                  size: _placeholderIcon,
                  color: AppColors.subtle,
                  semanticLabel: '',
                ),
              ),
              // A derived scrim, not a sixth palette entry: the text colour at
              // low alpha, fading to nothing at the top.
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.primaryText.withValues(alpha: 0),
                      AppColors.primaryText.withValues(alpha: 0.55),
                    ],
                  ),
                ),
              ),
              Align(
                alignment: AlignmentDirectional.bottomStart,
                child: Padding(
                  padding: EdgeInsetsDirectional.all(AppSpacing.s),
                  child: Text(
                    category.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      // Reads against the scrim, whatever the artwork behind it
                      // turns out to be.
                      color: AppColors.background,
                    ),
                    // The label is on the Semantics above, so the glyphs would
                    // otherwise be announced twice.
                    semanticsLabel: '',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
