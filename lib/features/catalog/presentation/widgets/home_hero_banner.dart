import 'package:flutter/material.dart';
import 'package:nova_modest/core/theme/app_colors.dart';
import 'package:nova_modest/core/theme/app_dimensions.dart';
import 'package:nova_modest/l10n/app_localizations.dart';

/// The banner at the top of Home.
///
/// Artwork with a gradient scrim, a tagline and a call to action. No photograph
/// exists yet, so it renders the same palette placeholder the onboarding slides
/// use; passing an image later is the only change.
class HomeHeroBanner extends StatelessWidget {
  const HomeHeroBanner({this.onShopNow, this.image, super.key});

  final VoidCallback? onShopNow;
  final Widget? image;

  /// The design's 350x530. A ratio, so the banner fits whatever width it gets.
  static const double _aspect = 350 / 530;

  static const double _placeholderIcon = 56;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return AspectRatio(
      aspectRatio: _aspect,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.m),
        child: Stack(
          fit: StackFit.expand,
          children: [
            image ??
                ColoredBox(
                  color: AppColors.secondary,
                  child: Center(
                    child: Icon(
                      Icons.checkroom_outlined,
                      size: _placeholderIcon,
                      color: AppColors.subtle,
                      semanticLabel: '',
                    ),
                  ),
                ),
            // A scrim so the copy stays legible whatever photograph lands here.
            // Ratios only, no measurements.
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, AppColors.primaryText],
                  stops: [0.45, 1],
                ),
              ),
            ),
            Align(
              alignment: AlignmentDirectional.bottomCenter,
              child: Padding(
                padding: EdgeInsetsDirectional.all(AppSpacing.l),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      l10n.homeHeroTagline,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        // On the scrim, not on the page — the one place the
                        // background colour is used as a foreground.
                        color: AppColors.background,
                      ),
                    ),
                    SizedBox(height: AppSpacing.l),
                    FilledButton(
                      onPressed: onShopNow,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.background,
                        foregroundColor: AppColors.primaryText,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                      ),
                      child: Text(l10n.homeHeroCta),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
