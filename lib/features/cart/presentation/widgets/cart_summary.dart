import 'package:flutter/material.dart';
// hide TextDirection: intl exports a class of the same name, which shadows
// dart:ui's and silently breaks every directional literal in this file.
import 'package:intl/intl.dart' hide TextDirection;
import 'package:nova_modest/core/theme/app_colors.dart';
import 'package:nova_modest/core/theme/app_dimensions.dart';
import 'package:nova_modest/features/cart/domain/entities/cart_totals.dart';
import 'package:nova_modest/l10n/app_localizations.dart';

/// The tinted card at the foot of the cart: subtotal, shipping, total.
///
/// Renders values the domain already computed ([CartTotals]) — no arithmetic
/// happens here.
class CartSummary extends StatelessWidget {
  const CartSummary({required this.totals, super.key});

  final CartTotals totals;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;

    final money = NumberFormat.currency(
      locale: Localizations.localeOf(context).toLanguageTag(),
      symbol: l10n.currencySymbol,
      decimalDigits: 0,
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        // A derived tint, not a sixth palette entry: hairline is primaryText at
        // 8% over the background, which is what the design's #F7F3F2 is — a
        // faint wash that separates the card from the page.
        color: AppColors.hairline,
        borderRadius: BorderRadius.circular(AppRadius.m),
      ),
      child: Padding(
        padding: EdgeInsetsDirectional.all(AppSpacing.m),
        child: Column(
          children: [
            _Row(
              label: l10n.cartSubtotal,
              value: money.format(totals.subtotal),
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.mutedStrong,
              ),
            ),
            SizedBox(height: AppSpacing.xs),
            _Row(
              label: l10n.cartShipping,
              value: money.format(totals.shipping),
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.mutedStrong,
              ),
            ),
            const Divider(),
            _Row(
              label: l10n.cartTotal,
              value: money.format(totals.total),
              // The design's 20/w500 emphasis on the total only.
              style: textTheme.headlineMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value, required this.style});

  final String label;
  final String value;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(label, style: style)),
        Text(value, maxLines: 1, style: style),
      ],
    );
  }
}
