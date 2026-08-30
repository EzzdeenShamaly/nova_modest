import 'package:flutter/material.dart';
import 'package:nova_modest/core/theme/app_colors.dart';
import 'package:nova_modest/core/theme/app_dimensions.dart';
import 'package:nova_modest/features/orders/domain/entities/order_status.dart';
import 'package:nova_modest/l10n/app_localizations.dart';

/// The five stages of an order, from Figma `1:1480`.
///
/// **Derives itself from [OrderStatus].** The enum is declared in the order the
/// stages happen, so `index` *is* the progress and this widget carries no
/// positions of its own — every stage before the current one is behind, the
/// current one is accented and larger, and the rest are ahead.
///
/// The same three-appearance logic as `CheckoutStepIndicator`, and deliberately
/// **not** the same widget: that one is horizontal, three stations wide,
/// unlabelled, and lives inside a flow the shopper is walking. Generalising it
/// to serve both would have coupled two things that only resemble each other.
///
/// Size is a second signal beside colour, so the current stage is not carried
/// by hue alone.
class OrderStatusTracker extends StatelessWidget {
  const OrderStatusTracker({required this.status, super.key});

  final OrderStatus status;

  /// The frame's dots and its 12pt heading — component measurements, not values
  /// on the spacing scale (`12-flutter-design-system-guard.md` §5).
  static const double _dotSize = 12;
  static const double _currentDotSize = 16;

  /// Width of the column the dots sit in, so every label starts on one line
  /// whatever its dot measures.
  static const double _railWidth = 24;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;

    return Material(
      // The same derived tint as the price card: primaryText at 8% over the
      // background is the design's #F7F3F2.
      color: AppColors.hairline,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: AppColors.secondary),
        borderRadius: BorderRadius.circular(AppRadius.m),
      ),
      child: Padding(
        padding: EdgeInsetsDirectional.all(AppSpacing.l),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.orderStatusHeading,
              style: textTheme.labelMedium?.copyWith(
                color: AppColors.mutedStrong,
              ),
            ),
            SizedBox(height: AppSpacing.l),
            // One Semantics for the whole rail: five separate announcements of
            // stages the shopper cannot act on is noise, and the one that
            // matters is where the order actually is.
            Semantics(
              container: true,
              label: l10n.orderStatusCurrent(_label(status, l10n)),
              child: ExcludeSemantics(
                child: Column(
                  children: [
                    // `journey`, not `values`: the enum gained `cancelled`
                    // when the Supabase schema arrived, and that is an outcome
                    // rather than a sixth stage — a rail ending in it would
                    // suggest every order does.
                    for (final stage in OrderStatus.journey) ...[
                      _Stage(stage: stage, current: status),
                      if (stage != OrderStatus.journey.last)
                        SizedBox(height: AppSpacing.xl),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// The tracker's wording. [OrderStatus.delivered] is «تم التوصيل» here and
  /// «مكتمل» on a list badge — the two frames word the same stage differently,
  /// which is why the enum carries two strings for it.
  static String _label(OrderStatus stage, AppLocalizations l10n) =>
      switch (stage) {
        OrderStatus.pending => l10n.orderStatusPending,
        OrderStatus.confirmed => l10n.orderStatusConfirmed,
        OrderStatus.processing => l10n.orderStatusProcessing,
        OrderStatus.shipped => l10n.orderStatusShipped,
        OrderStatus.delivered => l10n.orderStatusDeliveredLong,
        OrderStatus.cancelled => l10n.orderStatusCancelled,
      };
}

class _Stage extends StatelessWidget {
  const _Stage({required this.stage, required this.current});

  final OrderStatus stage;
  final OrderStatus current;

  bool get _isCurrent => stage == current;
  bool get _isPassed => stage.isBefore(current);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;

    final (Color dot, Color text, TextStyle? style) = switch (this) {
      _ when _isCurrent => (
        AppColors.accent,
        AppColors.accent,
        textTheme.headlineMedium,
      ),
      _ when _isPassed => (
        AppColors.primaryText,
        AppColors.primaryText,
        textTheme.bodyLarge,
      ),
      // Ahead: the faintest dot, matching the checkout indicator's own reading
      // that the quieter level is the part that has not happened yet.
      _ => (AppColors.subtle, AppColors.muted, textTheme.bodyLarge),
    };

    return Row(
      children: [
        SizedBox(
          width: OrderStatusTracker._railWidth,
          child: Center(
            child: Container(
              width: _isCurrent
                  ? OrderStatusTracker._currentDotSize
                  : OrderStatusTracker._dotSize,
              height: _isCurrent
                  ? OrderStatusTracker._currentDotSize
                  : OrderStatusTracker._dotSize,
              decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
            ),
          ),
        ),
        SizedBox(width: AppSpacing.m),
        Expanded(
          child: Text(
            OrderStatusTracker._label(stage, l10n),
            style: style?.copyWith(color: text),
          ),
        ),
      ],
    );
  }
}
