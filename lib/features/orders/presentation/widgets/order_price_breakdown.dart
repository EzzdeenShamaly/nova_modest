import 'package:flutter/material.dart';
// hide TextDirection: intl exports a class of the same name, which shadows
// dart:ui's and silently breaks every directional literal in this file.
import 'package:intl/intl.dart' hide TextDirection;
import 'package:nova_modest/core/theme/app_colors.dart';
import 'package:nova_modest/core/theme/app_dimensions.dart';
import 'package:nova_modest/features/orders/domain/entities/order_totals.dart';
import 'package:nova_modest/l10n/app_localizations.dart';

/// What each part of an order costs, and what it comes to.
///
/// Drawn by checkout's review step (`1:1840`) before the order exists and by
/// the details screen (`1:1480`) long after — the same four figures both times,
/// so the same widget. Lifted out of the review when the second caller arrived.
///
/// **Both frames omit the payment fee**, and both were drawn before cash on
/// delivery carried one: `1:1840`'s own arithmetic is 2,100 + 35 = 2,135. The
/// row is drawn whenever the fee is not zero, because a screen that reports an
/// order must report what was charged for it.
///
/// [tinted] is the review's card; the details screen draws the same figures
/// with a rule above them and no fill, as its frame does.
class OrderPriceBreakdown extends StatelessWidget {
  const OrderPriceBreakdown({
    required this.totals,
    required this.money,
    this.tinted = true,
    super.key,
  });

  final OrderTotals totals;
  final NumberFormat money;
  final bool tinted;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;

    final rows = Column(
      children: [
        _Row(label: l10n.cartSubtotal, value: money.format(totals.subtotal)),
        SizedBox(height: AppSpacing.s),
        _Row(label: l10n.cartShipping, value: money.format(totals.shipping)),
        if (totals.paymentFee != 0) ...[
          SizedBox(height: AppSpacing.s),
          _Row(
            label: l10n.checkoutPaymentFee,
            value: money.format(totals.paymentFee),
          ),
        ],
        const Divider(),
        _Row(
          label: l10n.checkoutOrderTotal,
          value: money.format(totals.total),
          labelStyle: textTheme.headlineMedium,
          valueStyle: textTheme.headlineMedium?.copyWith(
            color: AppColors.accent,
          ),
        ),
      ],
    );

    if (!tinted) return rows;

    return Material(
      // The same derived tint the cart's summary uses: primaryText at 8% over
      // the background is the design's #F7F3F2.
      color: AppColors.hairline,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.m),
      ),
      child: Padding(
        padding: EdgeInsetsDirectional.all(AppSpacing.l),
        child: rows,
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.label,
    required this.value,
    this.labelStyle,
    this.valueStyle,
  });

  final String label;
  final String value;
  final TextStyle? labelStyle;
  final TextStyle? valueStyle;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: labelStyle ?? textTheme.bodyMedium),
        Text(value, style: valueStyle ?? textTheme.bodyMedium),
      ],
    );
  }
}
