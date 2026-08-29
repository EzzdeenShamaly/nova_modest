import 'package:flutter/material.dart';
import 'package:nova_modest/core/theme/app_colors.dart';
import 'package:nova_modest/core/theme/app_dimensions.dart';

/// One row of the account menu, from Figma `1:1645`.
///
/// Hand-built rather than a `ListTile`, for the same reason `AppBottomNav` is:
/// the design's row carries a value beside the chevron on one entry and drops
/// the chevron entirely on another, and styling around Material's tile would
/// have cost more than describing the row.
class ProfileMenuTile extends StatelessWidget {
  const ProfileMenuTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.value,
    this.destructive = false,
    super.key,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  /// Shown before the chevron — the current language, on the one row that has
  /// something to report.
  final String? value;

  /// Sign out. Drawn in the palette's error colour and without a chevron: it
  /// acts here rather than leading anywhere.
  final bool destructive;

  /// The design's 56pt row. Above the 48pt accessible minimum, and specific to
  /// this component rather than a value on the spacing scale
  /// (`12-flutter-design-system-guard.md` §5).
  static const double _rowHeight = 56;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final foreground = destructive ? AppColors.error : AppColors.primaryText;

    return Semantics(
      button: true,
      label: label,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: _rowHeight,
          child: Padding(
            padding: EdgeInsetsDirectional.symmetric(horizontal: AppSpacing.m),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: AppFontSize.xl,
                  color: destructive ? AppColors.error : AppColors.mutedStrong,
                  semanticLabel: '',
                ),
                SizedBox(width: AppSpacing.m),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodyLarge?.copyWith(color: foreground),
                    // The label is on the Semantics above, so the glyphs would
                    // otherwise be announced twice.
                    semanticsLabel: '',
                  ),
                ),
                if (value case final current?) ...[
                  SizedBox(width: AppSpacing.xs),
                  Text(
                    current,
                    maxLines: 1,
                    style: textTheme.bodyMedium?.copyWith(
                      color: AppColors.muted,
                    ),
                  ),
                  SizedBox(width: AppSpacing.xs),
                ],
                if (!destructive)
                  Icon(
                    // chevron_right is declared with matchTextDirection, so it
                    // mirrors to point at the end of the row in either
                    // direction — no physical override needed.
                    Icons.chevron_right,
                    size: AppFontSize.xl,
                    color: AppColors.subtle,
                    semanticLabel: '',
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
