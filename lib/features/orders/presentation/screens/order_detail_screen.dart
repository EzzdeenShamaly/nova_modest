import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
// hide TextDirection: intl exports a class of the same name, which shadows
// dart:ui's and silently breaks every directional literal in this file.
import 'package:intl/intl.dart' hide TextDirection;
import 'package:nova_modest/core/theme/app_colors.dart';
import 'package:nova_modest/core/theme/app_dimensions.dart';
import 'package:nova_modest/core/widgets/failure_view.dart';
import 'package:nova_modest/features/address/domain/entities/address.dart';
import 'package:nova_modest/features/orders/domain/entities/order.dart';
import 'package:nova_modest/features/orders/presentation/bloc/order_detail_bloc.dart';
import 'package:nova_modest/features/orders/presentation/widgets/order_item_line.dart';
import 'package:nova_modest/features/orders/presentation/widgets/order_price_breakdown.dart';
import 'package:nova_modest/features/orders/presentation/widgets/order_status_tracker.dart';
import 'package:nova_modest/l10n/app_localizations.dart';

/// One order in full, from Figma `1:1480`.
///
/// **Read-only.** Everything on it was recorded when the order was placed;
/// nothing here can be changed, and nothing tries to.
class OrderDetailScreen extends StatelessWidget {
  const OrderDetailScreen({required this.number, super.key});

  /// The number from the route. The order is fetched by it rather than handed
  /// in, so a link or a notification opens this screen as well as a tap does.
  final String number;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(centerTitle: true, title: Text(l10n.orderDetailTitle)),
      body: BlocBuilder<OrderDetailBloc, OrderDetailState>(
        builder: (context, state) => switch (state) {
          OrderDetailInitial() || OrderDetailLoading() => const Center(
            child: CircularProgressIndicator(),
          ),
          // No empty state: an order exists or it does not, and "it does not"
          // is a NotFoundFailure with a reason, which the shared view renders.
          OrderDetailError(:final failure) => FailureView(
            failure: failure,
            onRetry: () =>
                context.read<OrderDetailBloc>().add(OrderRequested(number)),
          ),
          OrderDetailLoaded(:final order) => _Order(order: order),
        },
      ),
    );
  }
}

class _Order extends StatelessWidget {
  const _Order({required this.order});

  final Order order;

  /// This frame's thumbnail, taller than the review's 80x96. Each frame fixes
  /// its own, so neither is a value on a shared scale.
  static const double _imageWidth = 96;
  static const double _imageHeight = 144;
  static const double _placeholderIcon = 32;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final locale = Localizations.localeOf(context).toLanguageTag();

    final money = NumberFormat.currency(
      locale: locale,
      symbol: l10n.currencySymbol,
      decimalDigits: 0,
    );

    return ListView(
      padding: EdgeInsetsDirectional.all(AppSpacing.l),
      children: [
        Text(
          l10n.orderPlacedOn(DateFormat.yMMMMd(locale).format(order.placedAt)),
          style: textTheme.bodyMedium?.copyWith(color: AppColors.muted),
        ),
        SizedBox(height: AppSpacing.xs),
        Text(
          l10n.orderNumberHeading(order.number),
          style: textTheme.titleMedium,
        ),

        SizedBox(height: AppSpacing.xxl),
        OrderStatusTracker(status: order.status),

        if (order.items.isNotEmpty) ...[
          SizedBox(height: AppSpacing.xxl),
          _SectionHeading(l10n.orderItemsHeading(order.itemCount)),
          SizedBox(height: AppSpacing.l),
          for (final item in order.items) ...[
            OrderItemLine(
              item: item,
              money: money,
              imageWidth: _imageWidth,
              imageHeight: _imageHeight,
              placeholderIcon: _placeholderIcon,
            ),
            SizedBox(height: AppSpacing.l),
          ],
        ],

        if (order.address case final address?) ...[
          SizedBox(height: AppSpacing.m),
          _DeliveryAddress(address: address, order: order),
        ],

        SizedBox(height: AppSpacing.xxl),
        // Untinted here: the frame gives this screen a rule above the figures
        // rather than the review's filled card.
        OrderPriceBreakdown(totals: order.totals, money: money, tinted: false),
      ],
    );
  }
}

/// A small heading with the rule the frame draws under it.
class _SectionHeading extends StatelessWidget {
  const _SectionHeading(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          text,
          style: Theme.of(
            context,
          ).textTheme.labelMedium?.copyWith(color: AppColors.mutedStrong),
        ),
        SizedBox(height: AppSpacing.xs),
        const Divider(height: 0),
      ],
    );
  }
}

/// Where the order went, and who received it.
class _DeliveryAddress extends StatelessWidget {
  const _DeliveryAddress({required this.address, required this.order});

  final Address address;
  final Order order;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;

    return Material(
      // The frame draws this card pure white, which this warm palette does not
      // contain and cannot derive. `background` on a bordered card reads the
      // same and keeps the palette closed (user, 2026-08-29).
      color: AppColors.background,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: AppColors.secondary),
        borderRadius: BorderRadius.circular(AppRadius.m),
      ),
      child: Padding(
        padding: EdgeInsetsDirectional.all(AppSpacing.l),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.location_on_outlined,
                  size: AppFontSize.m,
                  color: AppColors.mutedStrong,
                  semanticLabel: '',
                ),
                SizedBox(width: AppSpacing.xxs),
                Text(
                  l10n.orderDeliveryAddress,
                  style: textTheme.labelMedium?.copyWith(
                    color: AppColors.mutedStrong,
                  ),
                ),
              ],
            ),
            SizedBox(height: AppSpacing.m),
            // The recipient as **typed at checkout**, not as saved in the
            // address book: the contact step is editable precisely because a
            // shopper may be buying for someone else.
            Text(
              order.recipientName ?? address.recipientName,
              style: textTheme.titleSmall,
            ),
            for (final line in address.reviewLines(l10n.reviewPostalCode))
              Text(line, style: textTheme.bodyMedium),
            SizedBox(height: AppSpacing.xs),
            Text(
              order.recipientPhone ?? address.phone,
              // direction-fixed: a dialling number reads left to right in every
              // locale
              textDirection: TextDirection.ltr,
              textAlign: TextAlign.start,
              style: textTheme.bodyMedium?.copyWith(color: AppColors.muted),
            ),
          ],
        ),
      ),
    );
  }
}
