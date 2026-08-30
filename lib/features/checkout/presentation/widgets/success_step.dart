import 'package:flutter/material.dart';
import 'package:nova_modest/core/theme/app_colors.dart';
import 'package:nova_modest/core/theme/app_dimensions.dart';
import 'package:nova_modest/features/orders/domain/entities/order.dart';
import 'package:nova_modest/l10n/app_localizations.dart';

/// The end of checkout, from Figma `1:2137`.
///
/// **Terminal.** It draws no app bar, no step indicator and no sticky bar — its
/// two actions are in the content, and there is nothing left to go back to. The
/// host suppresses its own chrome for this step rather than this widget hiding
/// under it.
///
/// Stateless and self-contained: everything it shows comes from the order the
/// repository handed back.
class SuccessStep extends StatelessWidget {
  const SuccessStep({
    required this.order,
    required this.onTrackOrder,
    required this.onKeepShopping,
    super.key,
  });

  /// The placed order. Null only in a state that should not exist — the step is
  /// reached by a successful `place` and nothing else — so the number is simply
  /// omitted rather than the screen refusing to draw.
  final Order? order;

  /// Null for a guest, who has no account to track an order through. The frame
  /// draws the button unconditionally; showing it to a guest would send them to
  /// a sign-in screen moments after they paid.
  final VoidCallback? onTrackOrder;

  final VoidCallback onKeepShopping;

  /// The frame's circles: a 96pt badge over two decorative discs. Component
  /// measurements, not values on the spacing scale
  /// (`12-flutter-design-system-guard.md` §5).
  static const double _badgeSize = 96;
  static const double _checkSize = 40;
  static const double _decorSmall = 156;
  static const double _decorLarge = 195;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;

    return Stack(
      alignment: AlignmentDirectional.topCenter,
      children: [
        const _AmbientDecoration(),
        SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsetsDirectional.all(AppSpacing.l),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: _badgeSize,
                    height: _badgeSize,
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withValues(alpha: 0.20),
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.accent),
                    ),
                    child: const Icon(
                      Icons.check,
                      size: _checkSize,
                      color: AppColors.accent,
                      // The heading beside it says the same thing in words.
                      semanticLabel: '',
                    ),
                  ),
                  SizedBox(height: AppSpacing.xxl),
                  Text(
                    l10n.successTitle,
                    textAlign: TextAlign.center,
                    style: textTheme.headlineLarge,
                  ),
                  if (order case final placed?) ...[
                    SizedBox(height: AppSpacing.xs),
                    _OrderNumberChip(number: placed.number),
                  ],
                  SizedBox(height: AppSpacing.xs),
                  Text(
                    l10n.successBody,
                    textAlign: TextAlign.center,
                    style: textTheme.bodyLarge?.copyWith(
                      color: AppColors.muted,
                    ),
                  ),
                  SizedBox(height: AppSpacing.xl),
                  if (onTrackOrder case final track?) ...[
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: track,
                        child: Text(l10n.successTrackOrder),
                      ),
                    ),
                    SizedBox(height: AppSpacing.m),
                  ],
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: onKeepShopping,
                      child: Text(l10n.successKeepShopping),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// The order number, set apart the way the frame sets it apart.
class _OrderNumberChip extends StatelessWidget {
  const _OrderNumberChip({required this.number});

  final String number;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.secondary.withValues(alpha: 0.30),
        borderRadius: BorderRadius.circular(AppRadius.s),
        border: Border.all(color: AppColors.secondary),
      ),
      padding: EdgeInsetsDirectional.symmetric(
        horizontal: AppSpacing.l,
        vertical: AppSpacing.s,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            l10n.successOrderNumber,
            style: textTheme.titleSmall?.copyWith(color: AppColors.muted),
          ),
          SizedBox(width: AppSpacing.xxs),
          Text(
            number,
            // direction-fixed: an order number is read left to right in every
            // locale, like a dialling code
            textDirection: TextDirection.ltr,
            style: textTheme.titleSmall,
          ),
        ],
      ),
    );
  }
}

/// Two soft discs behind the badge.
///
/// Drawn **without a blur**. The frame blurs them, and `ImageFiltered` would
/// match it — at the cost of a full raster layer on a screen whose whole job is
/// to sit still and be read. Low-opacity discs of the same two colours read the
/// same from arm's length (user, 2026-08-29).
class _AmbientDecoration extends StatelessWidget {
  const _AmbientDecoration();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: ExcludeSemantics(
        child: Stack(
          alignment: AlignmentDirectional.center,
          children: [
            _Disc(
              size: SuccessStep._decorLarge,
              colour: AppColors.accent.withValues(alpha: 0.08),
            ),
            _Disc(
              size: SuccessStep._decorSmall,
              colour: AppColors.secondary.withValues(alpha: 0.30),
            ),
          ],
        ),
      ),
    );
  }
}

class _Disc extends StatelessWidget {
  const _Disc({required this.size, required this.colour});

  final double size;
  final Color colour;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: colour, shape: BoxShape.circle),
    );
  }
}
