import 'package:flutter/material.dart';
import 'package:nova_modest/core/theme/app_colors.dart';
import 'package:nova_modest/core/theme/app_dimensions.dart';

/// One destination in [AppBottomNav].
class AppBottomNavItem {
  const AppBottomNavItem({
    required this.icon,
    required this.label,
    this.showBadge = false,
  });

  final IconData icon;
  final String label;

  /// Draws the accent dot the design puts on the cart when it holds something.
  final bool showBadge;
}

/// The app's bottom navigation.
///
/// Hand-built rather than a `NavigationBar`, because the design carries two
/// things Material's bar does not express: a dot under the active label, and a
/// badge on one destination's icon. Reaching for the stock widget would have
/// meant styling around both.
///
/// Laid out in logical order with no `textDirection`, so the first tab sits on
/// the right under the app's Arabic locale.
class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    required this.items,
    required this.currentIndex,
    required this.onTap,
    super.key,
  });

  final List<AppBottomNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: BorderDirectional(top: BorderSide(color: AppColors.secondary)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsetsDirectional.symmetric(vertical: AppSpacing.s),
          child: Row(
            children: [
              for (var index = 0; index < items.length; index++)
                Expanded(
                  child: _NavButton(
                    item: items[index],
                    selected: index == currentIndex,
                    onTap: () => onTap(index),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final AppBottomNavItem item;
  final bool selected;
  final VoidCallback onTap;

  /// The active marker and the cart badge, both from the design.
  static const double _indicatorSize = 4;
  static const double _badgeSize = 8;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.primaryText : AppColors.mutedStrong;

    return Semantics(
      button: true,
      selected: selected,
      label: item.label,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsetsDirectional.symmetric(vertical: AppSpacing.xxs),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  // The label carries the meaning for a screen reader, so the
                  // glyph would only be announced twice.
                  Icon(item.icon, color: color, semanticLabel: ''),
                  if (item.showBadge)
                    PositionedDirectional(
                      top: 0,
                      end: 0,
                      child: Container(
                        width: _badgeSize,
                        height: _badgeSize,
                        decoration: const BoxDecoration(
                          color: AppColors.accent,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
              SizedBox(height: AppSpacing.xxs),
              Text(
                item.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.labelMedium?.copyWith(color: color),
              ),
              SizedBox(height: AppSpacing.xxs),
              // Reserved whether or not it is drawn, so the row does not shift
              // by four pixels every time the tab changes.
              SizedBox(
                height: _indicatorSize,
                child: selected
                    ? Center(
                        child: Container(
                          width: _indicatorSize,
                          height: _indicatorSize,
                          decoration: const BoxDecoration(
                            color: AppColors.primaryText,
                            shape: BoxShape.circle,
                          ),
                        ),
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
