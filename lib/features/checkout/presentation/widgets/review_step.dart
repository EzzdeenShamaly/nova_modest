import 'package:flutter/material.dart';
// hide TextDirection: intl exports a class of the same name, which shadows
// dart:ui's and silently breaks every directional literal in this file.
import 'package:intl/intl.dart' hide TextDirection;
import 'package:nova_modest/core/theme/app_colors.dart';
import 'package:nova_modest/core/theme/app_dimensions.dart';
import 'package:nova_modest/core/widgets/product_thumbnail.dart';
import 'package:nova_modest/features/cart/domain/entities/cart_item.dart';
import 'package:nova_modest/features/checkout/domain/entities/checkout_draft.dart';
import 'package:nova_modest/features/checkout/domain/entities/checkout_step.dart';
import 'package:nova_modest/features/checkout/domain/entities/order_totals.dart';
import 'package:nova_modest/features/checkout/domain/entities/payment_method.dart';
import 'package:nova_modest/features/checkout/domain/entities/shipping_method.dart';
import 'package:nova_modest/l10n/app_localizations.dart';

/// Checkout's last screen before the order exists, from Figma `1:1840`.
///
/// Shows back everything the three steps collected, each card carrying a
/// "تعديل" link to the step that collected it. **Stateless**: there is nothing
/// left to choose here, only to confirm — so unlike the other three steps it
/// needs no `GlobalKey` and no `submit()`. The host's bar dispatches
/// `CheckoutConfirmed` directly.
///
/// **Draws a payment card and a payment-fee row that the frame does not.** The
/// frame's own numbers are internally consistent (2,100 + 35 = 2,135), so it
/// was drawn before cash on delivery carried a fee. Following it literally
/// would show a total 15 short of what the shopper is about to be charged, on
/// the one screen whose entire job is to say what they are about to be charged.
class ReviewStep extends StatelessWidget {
  const ReviewStep({required this.draft, required this.onEdit, super.key});

  final CheckoutDraft draft;

  /// Tapping a card's "تعديل". The host turns it into a step request; the bloc
  /// refuses anything that is not a jump backwards.
  final ValueChanged<CheckoutStep> onEdit;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;

    final money = NumberFormat.currency(
      locale: Localizations.localeOf(context).toLanguageTag(),
      symbol: l10n.currencySymbol,
      decimalDigits: 0,
    );

    return ListView(
      padding: EdgeInsetsDirectional.only(
        start: AppSpacing.l,
        end: AppSpacing.l,
        bottom: AppSpacing.l,
      ),
      children: [
        if (draft.contact case final contact?)
          _SummaryCard(
            title: l10n.reviewContactSection,
            onEdit: () => onEdit(CheckoutStep.contact),
            lines: [
              contact.fullName,
              // A guest has none; the line is dropped rather than left blank.
              ?contact.email,
              contact.phone,
            ],
          ),
        if (draft.address case final address?) ...[
          SizedBox(height: AppSpacing.xs),
          _SummaryCard(
            title: l10n.reviewAddressSection,
            onEdit: () => onEdit(CheckoutStep.address),
            lines: address.reviewLines(l10n.reviewPostalCode),
          ),
        ],
        SizedBox(height: AppSpacing.xs),
        _SummaryCard(
          title: l10n.reviewShippingSection,
          onEdit: () => onEdit(CheckoutStep.payment),
          lines: [_shippingName(draft.shipping, l10n)],
          footnote: l10n.reviewShippingEta(l10n.checkoutShippingStandardEta),
          trailing: Text(
            money.format(draft.shipping.cost),
            style: textTheme.titleSmall,
          ),
        ),
        SizedBox(height: AppSpacing.xs),
        _SummaryCard(
          title: l10n.reviewPaymentSection,
          onEdit: () => onEdit(CheckoutStep.payment),
          lines: [_paymentName(draft.payment, l10n)],
          trailing: draft.payment.fee == 0
              ? null
              : Text(
                  money.format(draft.payment.fee),
                  style: textTheme.titleSmall,
                ),
        ),

        if (draft.items.isNotEmpty) ...[
          SizedBox(height: AppSpacing.l),
          Text(l10n.reviewItems, style: textTheme.headlineMedium),
          SizedBox(height: AppSpacing.m),
          for (final item in draft.items) ...[
            _ItemLine(item: item, money: money),
            SizedBox(height: AppSpacing.m),
          ],
        ],

        if (draft.totals case final totals?) ...[
          SizedBox(height: AppSpacing.xs),
          _PriceBreakdown(totals: totals, money: money),
        ],
      ],
    );
  }

  static String _shippingName(ShippingMethod method, AppLocalizations l10n) =>
      switch (method) {
        ShippingMethod.standard => l10n.checkoutShippingStandard,
      };

  static String _paymentName(PaymentMethod method, AppLocalizations l10n) =>
      switch (method) {
        PaymentMethod.cashOnDelivery => l10n.checkoutPaymentCod,
        PaymentMethod.card => l10n.checkoutPaymentCard,
      };
}

/// One tinted card: a heading, an edit link, and the lines it is reporting.
class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.title,
    required this.onEdit,
    required this.lines,
    this.footnote,
    this.trailing,
  });

  final String title;
  final VoidCallback onEdit;
  final List<String> lines;

  /// A second, quieter line under the first — the delivery window.
  final String? footnote;

  /// The price sitting opposite the content, where a card has one.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: AppColors.secondary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.s),
      ),
      child: Padding(
        padding: EdgeInsetsDirectional.all(AppSpacing.m),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: textTheme.titleSmall?.copyWith(
                    color: AppColors.mutedStrong,
                  ),
                ),
                // A TextButton, not bare tappable text: it brings the tap
                // target and the focus ring that a GestureDetector would not.
                TextButton(
                  onPressed: onEdit,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.accent,
                    padding: EdgeInsetsDirectional.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    textStyle: textTheme.bodyMedium,
                  ),
                  // Names what it edits, so a screen reader hears four
                  // different links rather than "تعديل" four times.
                  child: Semantics(
                    label: '${l10n.reviewEdit} $title',
                    child: ExcludeSemantics(child: Text(l10n.reviewEdit)),
                  ),
                ),
              ],
            ),
            SizedBox(height: AppSpacing.xs),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final line in lines)
                        Text(line, style: textTheme.bodyMedium),
                      if (footnote case final note?)
                        Text(
                          note,
                          style: textTheme.bodyMedium?.copyWith(
                            color: AppColors.muted,
                          ),
                        ),
                    ],
                  ),
                ),
                if (trailing case final price?) ...[
                  SizedBox(width: AppSpacing.xs),
                  price,
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// One ordered line, read-only.
///
/// Deliberately **not** `CartItemTile`: that one carries a quantity stepper and
/// a remove button, which is the cart's job. Nothing on this screen may be
/// changed except by going back to the step that set it, so the quantity is
/// text.
class _ItemLine extends StatelessWidget {
  const _ItemLine({required this.item, required this.money});

  final CartItem item;
  final NumberFormat money;

  /// The frame's 80x96 thumbnail — fixed by this layout, not part of a scale.
  static const double _imageWidth = 80;
  static const double _imageHeight = 96;
  static const double _placeholderIcon = 28;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ProductThumbnail(
          images: item.product.images,
          width: _imageWidth,
          height: _imageHeight,
          iconSize: _placeholderIcon,
        ),
        SizedBox(width: AppSpacing.m),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.product.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: textTheme.titleSmall,
              ),
              if (_variantLine(l10n) case final line?) ...[
                SizedBox(height: AppSpacing.xxs),
                Text(
                  line,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodyMedium?.copyWith(color: AppColors.muted),
                ),
              ],
              SizedBox(height: AppSpacing.xs),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    money.format(item.lineTotal),
                    style: textTheme.titleSmall?.copyWith(
                      color: AppColors.accent,
                    ),
                  ),
                  Text(
                    l10n.reviewQuantity(item.quantity),
                    style: textTheme.bodyMedium?.copyWith(
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// The same three shapes the cart line draws, from the same ARB keys — one
  /// phrasing of "colour and size" in the app, not two.
  String? _variantLine(AppLocalizations l10n) =>
      switch ((item.colour?.name, item.size)) {
        (final colour?, final size?) => l10n.cartVariant(colour, size),
        (final colour?, null) => l10n.cartVariantColour(colour),
        (null, final size?) => l10n.cartVariantSize(size),
        _ => null,
      };
}

/// The closing card: what each part costs, and what it comes to.
class _PriceBreakdown extends StatelessWidget {
  const _PriceBreakdown({required this.totals, required this.money});

  final OrderTotals totals;
  final NumberFormat money;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;

    return Material(
      // The same derived tint the cart's summary uses: primaryText at 8% over
      // the background is the design's #F7F3F2.
      color: AppColors.hairline,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.m),
      ),
      child: Padding(
        padding: EdgeInsetsDirectional.all(AppSpacing.l),
        child: Column(
          children: [
            _Row(
              label: l10n.cartSubtotal,
              value: money.format(totals.subtotal),
            ),
            SizedBox(height: AppSpacing.s),
            _Row(
              label: l10n.cartShipping,
              value: money.format(totals.shipping),
            ),
            if (totals.paymentFee != 0) ...[
              SizedBox(height: AppSpacing.s),
              // Not in the frame. Its absence is what would make the total
              // below wrong — see the note on ReviewStep.
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
        ),
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
