import 'package:flutter/material.dart';
import 'package:nova_modest/core/theme/app_colors.dart';
import 'package:nova_modest/core/theme/app_dimensions.dart';

/// The page indicator: a stretched pill for the current page, small dots for the
/// rest.
///
/// Laid out in **logical** order with no `textDirection` set, so it mirrors: under
/// the app's Arabic locale the first page's indicator sits on the right. The
/// Figma frames look wrong on this until you account for it — Figma orders
/// children left-to-right physically, so the gold pill appears leftmost on the
/// last slide, which is correct once mirrored.
class OnboardingDots extends StatelessWidget {
  const OnboardingDots({
    required this.count,
    required this.activeIndex,
    super.key,
  });

  final int count;
  final int activeIndex;

  @override
  Widget build(BuildContext context) {
    // Decorative: the action button already says whether there is a next step,
    // and a screen reader announcing three unlabelled dots adds only noise. A
    // localized "page 2 of 3" announcement would need its own ARB key.
    return ExcludeSemantics(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var index = 0; index < count; index++)
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
              width: index == activeIndex ? AppSpacing.xl : AppSpacing.xs,
              height: AppSpacing.xs,
              // xxs on each side gives the design's 8 between neighbours.
              margin: EdgeInsetsDirectional.symmetric(
                horizontal: AppSpacing.xxs,
              ),
              decoration: BoxDecoration(
                color: index == activeIndex
                    ? AppColors.accent
                    : AppColors.subtle,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
            ),
        ],
      ),
    );
  }
}
