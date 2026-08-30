import 'package:flutter/material.dart';
// hide TextDirection: intl exports a class of the same name, which shadows
// dart:ui's and silently breaks every directional literal in this file.
import 'package:intl/intl.dart' hide TextDirection;
import 'package:nova_modest/core/theme/app_colors.dart';
import 'package:nova_modest/core/theme/app_dimensions.dart';
import 'package:nova_modest/features/orders/domain/entities/order_totals.dart';
import 'package:nova_modest/features/checkout/domain/entities/payment_method.dart';
import 'package:nova_modest/features/checkout/domain/entities/shipping_method.dart';
import 'package:nova_modest/l10n/app_localizations.dart';

/// Checkout step 3, from Figma `1:2059`: how it ships, how it is paid for, and
/// what that comes to.
///
/// A **widget, not a screen**, like the two steps before it — the host owns the
/// app bar, the indicator and the sticky bar, and submits this through a
/// `GlobalKey<PaymentStepState>`.
///
/// Both selections live here rather than in the bloc while the step is open, so
/// the summary re-totals as the shopper taps without a round trip through the
/// flow's state. They reach the draft on submit, together, because the frame
/// collects them on one page and the total depends on both.
class PaymentStep extends StatefulWidget {
  const PaymentStep({
    required this.shipping,
    required this.payment,
    required this.totalsFor,
    required this.onSubmit,
    super.key,
  });

  /// What the draft already holds — preselected, and re-shown unchanged when
  /// the shopper walks back into this step.
  final ShippingMethod shipping;
  final PaymentMethod payment;

  /// The four figures for a given pair of selections, or null before the cart
  /// is known. The arithmetic belongs to `OrderTotals`; this widget only asks.
  final OrderTotals? Function(ShippingMethod, PaymentMethod) totalsFor;

  final void Function(ShippingMethod shipping, PaymentMethod payment) onSubmit;

  @override
  State<PaymentStep> createState() => PaymentStepState();
}

/// Public so the checkout host's sticky bar can submit a step that lives
/// outside it — the arrangement `ContactStep` and `AddressStep` use.
class PaymentStepState extends State<PaymentStep> {
  late ShippingMethod _shipping = widget.shipping;
  late PaymentMethod _payment = widget.payment;

  /// Always succeeds: there is nothing to validate. Both selections have a
  /// value from the moment the step opens, which is why the draft holds them
  /// non-nullable.
  bool submit() {
    widget.onSubmit(_shipping, _payment);
    return true;
  }

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
        Text(l10n.checkoutShippingMethod, style: textTheme.headlineMedium),
        SizedBox(height: AppSpacing.xs),
        for (final method in ShippingMethod.values)
          _OptionCard(
            title: _shippingName(method, l10n),
            subtitle: l10n.checkoutShippingStandardEta,
            trailing: Text(
              money.format(method.cost),
              style: textTheme.titleMedium,
            ),
            selected: method == _shipping,
            onTap: () => setState(() => _shipping = method),
          ),

        SizedBox(height: AppSpacing.xxl),

        Text(l10n.checkoutPaymentMethod, style: textTheme.headlineMedium),
        SizedBox(height: AppSpacing.xs),
        for (final method in PaymentMethod.values) ...[
          _OptionCard(
            title: _paymentName(method, l10n),
            subtitle: switch (method) {
              // The frame states the surcharge under the option itself, not
              // only in the summary — it is the reason to choose otherwise.
              PaymentMethod.cashOnDelivery => l10n.checkoutPaymentCodFee(
                money.format(method.fee),
              ),
              PaymentMethod.card => l10n.checkoutComingSoon,
            },
            leading: Icon(
              switch (method) {
                PaymentMethod.cashOnDelivery => Icons.payments_outlined,
                PaymentMethod.card => Icons.credit_card,
              },
              size: _OptionCard.iconSize,
              color: method.isAvailable ? AppColors.accent : AppColors.muted,
              semanticLabel: '',
            ),
            selected: method == _payment,
            enabled: method.isAvailable,
            onTap: () => setState(() => _payment = method),
          ),
          if (method != PaymentMethod.values.last)
            SizedBox(height: AppSpacing.xs),
        ],

        SizedBox(height: AppSpacing.xxl),

        if (widget.totalsFor(_shipping, _payment) case final totals?)
          _OrderSummary(totals: totals, money: money),
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

/// One selectable option — a shipping method or a payment method.
///
/// The frame gives the **chosen** card a `secondary` fill on top of the accent
/// border, where step 2's address cards changed only their border. Followed as
/// drawn: an option is a commitment to a price, and the design says so louder
/// than it does for an address.
class _OptionCard extends StatelessWidget {
  const _OptionCard({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
    this.leading,
    this.trailing,
    this.enabled = true,
  });

  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;
  final Widget? leading;
  final Widget? trailing;

  /// False for an option the design draws but the app cannot offer.
  final bool enabled;

  /// The frame's 22pt radio and its 20pt option glyph — component
  /// measurements, not values on the spacing scale
  /// (`12-flutter-design-system-guard.md` §5).
  static const double _radioSize = 22;
  static const double iconSize = 20;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Semantics(
      // Not `button`: these are one-of-a-set, and a screen reader should say so
      // rather than offer three unrelated buttons.
      inMutuallyExclusiveGroup: true,
      checked: selected,
      enabled: enabled,
      child: Material(
        color: selected ? AppColors.secondary : AppColors.background,
        shape: RoundedRectangleBorder(
          side: BorderSide(
            color: selected ? AppColors.accent : AppColors.subtle,
          ),
          borderRadius: BorderRadius.circular(AppRadius.s),
        ),
        child: InkWell(
          // A null callback is what makes the ink itself dead, so a disabled
          // option does not splash under a finger and promise something.
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(AppRadius.s),
          child: Padding(
            padding: EdgeInsetsDirectional.all(AppSpacing.m),
            child: Row(
              children: [
                _Radio(selected: selected, enabled: enabled),
                SizedBox(width: AppSpacing.m),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: enabled
                            ? textTheme.titleMedium
                            : textTheme.titleMedium?.copyWith(
                                color: AppColors.muted,
                              ),
                      ),
                      SizedBox(height: AppSpacing.xxs),
                      Text(
                        subtitle,
                        style: textTheme.bodyMedium?.copyWith(
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                if (leading != null) ...[
                  SizedBox(width: AppSpacing.xs),
                  leading!,
                ],
                if (trailing != null) ...[
                  SizedBox(width: AppSpacing.xs),
                  trailing!,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The filled disc with a tick, or an empty ring.
///
/// Drawn rather than a `Radio`: Material's control brings its own palette and
/// its own tap target, and this one sits inside a card that is already the tap
/// target.
class _Radio extends StatelessWidget {
  const _Radio({required this.selected, required this.enabled});

  final bool selected;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _OptionCard._radioSize,
      height: _OptionCard._radioSize,
      decoration: BoxDecoration(
        color: selected ? AppColors.accent : AppColors.background,
        shape: BoxShape.circle,
        border: Border.all(
          // The frame outlines the empty ring in a cool grey (#747878) that is
          // not derivable from this warm palette. `muted` is the nearest thing
          // the palette already names for a control that is present but not
          // offering itself.
          color: selected
              ? AppColors.primaryText
              : (enabled ? AppColors.subtle : AppColors.muted),
        ),
      ),
      child: selected
          ? const Icon(
              Icons.check,
              size: _OptionCard.iconSize,
              color: AppColors.background,
              semanticLabel: '',
            )
          : null,
    );
  }
}

/// Subtotal, shipping, payment fee, total — `1:2059`'s closing block.
///
/// A ruled block, not the cart's tinted card: the frame draws a single rule
/// above it and nothing else, and the total is the only figure in accent.
class _OrderSummary extends StatelessWidget {
  const _OrderSummary({required this.totals, required this.money});

  final OrderTotals totals;
  final NumberFormat money;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        border: BorderDirectional(top: BorderSide(color: AppColors.subtle)),
      ),
      padding: EdgeInsetsDirectional.only(top: AppSpacing.l),
      child: Column(
        children: [
          _SummaryRow(
            label: l10n.cartSubtotal,
            value: money.format(totals.subtotal),
          ),
          SizedBox(height: AppSpacing.m),
          _SummaryRow(
            label: l10n.cartShipping,
            value: money.format(totals.shipping),
          ),
          SizedBox(height: AppSpacing.m),
          _SummaryRow(
            label: l10n.checkoutPaymentFee,
            value: money.format(totals.paymentFee),
          ),
          SizedBox(height: AppSpacing.l),
          _SummaryRow(
            label: l10n.checkoutOrderTotal,
            value: money.format(totals.total),
            labelStyle: textTheme.headlineMedium,
            valueStyle: textTheme.headlineLarge?.copyWith(
              color: AppColors.accent,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
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
        Text(
          label,
          style:
              labelStyle ??
              textTheme.bodyLarge?.copyWith(color: AppColors.muted),
        ),
        Text(value, style: valueStyle ?? textTheme.bodyLarge),
      ],
    );
  }
}
