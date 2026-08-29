import 'package:flutter/material.dart';
import 'package:nova_modest/core/theme/app_colors.dart';
import 'package:nova_modest/core/theme/app_dimensions.dart';

/// A screen that exists so navigation is complete, before its feature is built.
///
/// Named for its first use — the empty shell tabs — but it now also stands in
/// for every destination of the account menu, which are pushed routes rather
/// than tabs.
///
/// Deliberately plain and on-palette rather than an error or a "coming soon"
/// splash: it should read as somewhere the app has not gone yet, not as
/// something broken.
class PlaceholderTab extends StatelessWidget {
  const PlaceholderTab({required this.title, required this.icon, super.key});

  final String title;
  final IconData icon;

  /// Big enough to read as an illustration rather than a stray glyph. One
  /// element on one screen, so it stays local
  /// (`12-flutter-design-system-guard.md` §5).
  static const double _iconSize = 56;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Padding(
          padding: EdgeInsetsDirectional.all(AppSpacing.l),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: _iconSize,
                color: AppColors.subtle,
                semanticLabel: '',
              ),
              SizedBox(height: AppSpacing.m),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(color: AppColors.mutedStrong),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
