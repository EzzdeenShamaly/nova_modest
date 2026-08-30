import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
// hide TextDirection: intl exports a class of the same name, which shadows
// dart:ui's and silently breaks every directional literal in this file.
import 'package:intl/intl.dart' hide TextDirection;
import 'package:nova_modest/core/theme/app_colors.dart';
import 'package:nova_modest/core/theme/app_dimensions.dart';
import 'package:nova_modest/core/widgets/failure_view.dart';
import 'package:nova_modest/core/widgets/product_thumbnail.dart';
import 'package:nova_modest/features/orders/domain/entities/order.dart';
import 'package:nova_modest/features/orders/domain/entities/order_status.dart';
import 'package:nova_modest/features/orders/presentation/bloc/orders_bloc.dart';
import 'package:nova_modest/l10n/app_localizations.dart';
import 'package:nova_modest/router/routes.dart';

/// The shopper's order history, from Figma `1:1356`.
///
/// Reached from the account menu and from the confirmation screen's "تتبع
/// الطلب". Pushed inside the account branch, so the bottom bar stays.
class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // The frame titles the page in its own content rather than in a bar, and
      // pairs the title with a count — so the bar carries the brandmark only.
      appBar: AppBar(centerTitle: true, title: const Text(_brand)),
      body: BlocBuilder<OrdersBloc, OrdersState>(
        builder: (context, state) => switch (state) {
          OrdersInitial() ||
          OrdersLoading() => const Center(child: CircularProgressIndicator()),
          OrdersError(:final failure) => FailureView(
            failure: failure,
            onRetry: () =>
                context.read<OrdersBloc>().add(const OrdersRequested()),
          ),
          OrdersEmpty() => const _NoOrders(),
          OrdersLoaded(:final orders) => _OrdersList(orders: orders),
        },
      ),
    );
  }

  /// The wordmark, not a translated string: a brand name is the same in every
  /// locale.
  static const String _brand = 'NOVA MODEST';
}

class _OrdersList extends StatelessWidget {
  const _OrdersList({required this.orders});

  final List<Order> orders;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;

    return ListView(
      padding: EdgeInsetsDirectional.all(AppSpacing.l),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(l10n.ordersTitle, style: textTheme.headlineMedium),
            Text(
              l10n.ordersCount(orders.length),
              style: textTheme.bodyMedium?.copyWith(color: AppColors.muted),
            ),
          ],
        ),
        SizedBox(height: AppSpacing.l),
        for (final order in orders) ...[
          _OrderCard(order: order),
          SizedBox(height: AppSpacing.l),
        ],
      ],
    );
  }
}

/// One order, as a card that opens its details.
class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order});

  final Order order;

  /// The frame's 64x96 thumbnail. Fixed by this layout, not part of a scale.
  static const double _imageWidth = 64;
  static const double _imageHeight = 96;
  static const double _placeholderIcon = 24;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;

    final money = NumberFormat.currency(
      locale: Localizations.localeOf(context).toLanguageTag(),
      symbol: l10n.currencySymbol,
      decimalDigits: 0,
    );
    final date = DateFormat.yMMMMd(
      Localizations.localeOf(context).toLanguageTag(),
    ).format(order.placedAt);

    return Material(
      color: AppColors.background,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: AppColors.secondary),
        borderRadius: BorderRadius.circular(AppRadius.m),
      ),
      child: InkWell(
        onTap: () => context.push(Routes.orderDetail(order.number)),
        borderRadius: BorderRadius.circular(AppRadius.m),
        child: Padding(
          padding: EdgeInsetsDirectional.all(AppSpacing.m),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _StatusBadge(status: order.status),
                  Flexible(
                    child: Text(
                      '#${order.number}',
                      // direction-fixed: an order number reads left to right in
                      // every locale, like a dialling code
                      textDirection: TextDirection.ltr,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.labelMedium,
                    ),
                  ),
                ],
              ),
              SizedBox(height: AppSpacing.xs),
              const Divider(),
              SizedBox(height: AppSpacing.xs),
              Row(
                children: [
                  if (order.leadItem case final item?) ...[
                    Stack(
                      alignment: AlignmentDirectional.bottomEnd,
                      children: [
                        ProductThumbnail(
                          images: item.product.images,
                          width: _imageWidth,
                          height: _imageHeight,
                          iconSize: _placeholderIcon,
                        ),
                        if (order.hiddenItemCount > 0)
                          _MoreItems(count: order.hiddenItemCount),
                      ],
                    ),
                    SizedBox(width: AppSpacing.m),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          date,
                          style: textTheme.bodyMedium?.copyWith(
                            color: AppColors.muted,
                          ),
                        ),
                        SizedBox(height: AppSpacing.xxs),
                        Text(
                          money.format(order.totals.total),
                          style: textTheme.headlineMedium?.copyWith(
                            color: AppColors.accent,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Icons.chevron_right mirrors with the layout; a physical
                  // arrow would not.
                  Icon(
                    Icons.chevron_right,
                    color: AppColors.muted,
                    semanticLabel: '',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// «+2» over the thumbnail, for the lines it does not show.
class _MoreItems extends StatelessWidget {
  const _MoreItems({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.primaryText.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(AppRadius.s),
      ),
      padding: EdgeInsetsDirectional.symmetric(
        horizontal: AppSpacing.xxs,
        vertical: AppSpacing.xxs,
      ),
      child: Text(
        l10n.ordersMoreItems(count),
        // direction-fixed: "+2" is a signed count, written the same way in
        // every locale
        textDirection: TextDirection.ltr,
        style: Theme.of(
          context,
        ).textTheme.labelSmall?.copyWith(color: AppColors.background),
      ),
    );
  }
}

/// The status pill.
///
/// Three appearances, exactly as `1:1356` draws them: a filled badge for work
/// in progress, an outlined accent one once it is moving, and a quiet unfilled
/// one when it is done. Colour is never the only signal — the word says it.
class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final OrderStatus status;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    final (Color? fill, Color border, Color text) = switch (status) {
      OrderStatus.pending || OrderStatus.confirmed || OrderStatus.processing =>
        (AppColors.secondary, AppColors.secondary, AppColors.mutedStrong),
      OrderStatus.shipped => (null, AppColors.accent, AppColors.accent),
      OrderStatus.delivered => (null, AppColors.subtle, AppColors.muted),
      // The one status the frame never drew, because the frame predates the
      // schema that has it. `error` is the terracotta already carried over from
      // the admin's own cancelled state, so this continues that decision rather
      // than inventing a colour.
      OrderStatus.cancelled => (null, AppColors.error, AppColors.error),
    };

    return Container(
      decoration: BoxDecoration(
        color: fill,
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      padding: EdgeInsetsDirectional.symmetric(
        horizontal: AppSpacing.s,
        vertical: AppSpacing.xxs,
      ),
      child: Text(
        statusLabel(status, l10n),
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: text),
      ),
    );
  }
}

/// The badge wording for [status].
///
/// `delivered` has two strings — «مكتمل» on a badge and «تم التوصيل» on the
/// details tracker — because the two frames word the same stage differently.
/// This is the short one.
String statusLabel(OrderStatus status, AppLocalizations l10n) =>
    switch (status) {
      OrderStatus.pending => l10n.orderStatusPending,
      OrderStatus.confirmed => l10n.orderStatusConfirmed,
      OrderStatus.processing => l10n.orderStatusProcessing,
      OrderStatus.shipped => l10n.orderStatusShipped,
      OrderStatus.delivered => l10n.orderStatusDelivered,
      OrderStatus.cancelled => l10n.orderStatusCancelled,
    };

/// No orders yet.
///
/// A distinct screen rather than an empty list: it invites the shopper to
/// browse, which a list with no cards cannot.
class _NoOrders extends StatelessWidget {
  const _NoOrders();

  /// The illustration stands in for artwork that does not exist yet.
  static const double _iconSize = 72;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: EdgeInsetsDirectional.all(AppSpacing.l),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: _iconSize,
              color: AppColors.subtle,
              semanticLabel: '',
            ),
            SizedBox(height: AppSpacing.l),
            Text(l10n.ordersEmpty, style: textTheme.headlineMedium),
            SizedBox(height: AppSpacing.xs),
            Text(
              l10n.ordersEmptyBody,
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(color: AppColors.muted),
            ),
            SizedBox(height: AppSpacing.l),
            FilledButton(
              onPressed: () => context.go(Routes.homePath),
              child: Text(l10n.ordersEmptyAction),
            ),
          ],
        ),
      ),
    );
  }
}
