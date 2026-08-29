import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:nova_modest/core/theme/app_colors.dart';
import 'package:nova_modest/core/theme/app_dimensions.dart';
import 'package:nova_modest/core/widgets/failure_view.dart';
import 'package:nova_modest/features/cart/presentation/bloc/cart_bloc.dart';
import 'package:nova_modest/features/cart/presentation/widgets/cart_item_tile.dart';
import 'package:nova_modest/features/cart/presentation/widgets/cart_summary.dart';
import 'package:nova_modest/l10n/app_localizations.dart';
import 'package:nova_modest/router/routes.dart';

/// The cart, built from Figma frame `1:2770`.
///
/// A **shell branch**, so the bottom navigation stays visible — the design's
/// frame omits the bar, but the bar itself carries a cart destination with a
/// badge, and a tab that hides the bar it was tapped from is a broken tab.
///
/// No `BlocProvider` here: [CartBloc] is app-wide and provided in `app.dart`,
/// because the product page writes to it and the navigation badge reads from
/// it.
class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(centerTitle: true, title: Text(l10n.cartTitle)),
      body: BlocBuilder<CartBloc, CartState>(
        builder: (context, state) => switch (state) {
          CartInitial() ||
          CartLoading() => const Center(child: CircularProgressIndicator()),
          CartError(:final failure) => FailureView(
            failure: failure,
            // Re-reads storage from scratch, which is also how a cart pruned of
            // a vanished product recovers.
            onRetry: () => context.read<CartBloc>().add(const CartRequested()),
          ),
          CartEmpty() => const _EmptyCart(),
          CartLoaded() => _Body(state: state),
        },
      ),
      // bottomNavigationBar is the slot that pins: the bar stays put while the
      // list scrolls. It sits above the shell's navigation bar, as the design's
      // sticky bar sits above the bottom of the screen.
      bottomNavigationBar: BlocBuilder<CartBloc, CartState>(
        builder: (context, state) => state is CartLoaded
            ? const _CheckoutBar()
            : const SizedBox.shrink(),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.state});

  final CartLoaded state;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<CartBloc>();

    return ListView(
      padding: EdgeInsetsDirectional.all(AppSpacing.l),
      children: [
        for (final item in state.items) ...[
          CartItemTile(
            // Keyed by the line, so removing one does not make the next row
            // inherit its stepper state.
            key: ValueKey<String>(item.lineId),
            item: item,
            onQuantityChanged: (quantity) =>
                bloc.add(CartQuantityChanged(item.lineId, quantity)),
            onRemove: () => bloc.add(CartItemRemoved(item.lineId)),
          ),
          // 48 tall with the rule centred: the design's 24 above and 24 below,
          // in one widget rather than a divider between two gaps.
          Divider(height: AppSpacing.xxl),
        ],
        CartSummary(totals: state.totals),
      ],
    );
  }
}

class _EmptyCart extends StatelessWidget {
  const _EmptyCart();

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
              Icons.shopping_bag_outlined,
              size: _iconSize,
              color: AppColors.subtle,
              // Decorative: the heading below carries the meaning.
              semanticLabel: '',
            ),
            SizedBox(height: AppSpacing.m),
            Text(l10n.cartEmpty, style: textTheme.headlineMedium),
            SizedBox(height: AppSpacing.xs),
            Text(
              l10n.cartEmptyBody,
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.mutedStrong,
              ),
            ),
            SizedBox(height: AppSpacing.l),
            FilledButton(
              // Switches branch rather than pushing: the catalogue is another
              // tab, not a screen stacked on the cart.
              onPressed: () => context.go(Routes.homePath),
              child: Text(l10n.cartEmptyCta),
            ),
          ],
        ),
      ),
    );
  }
}

/// The sticky bar: one action, to pay.
class _CheckoutBar extends StatelessWidget {
  const _CheckoutBar();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: BorderDirectional(top: BorderSide(color: AppColors.secondary)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsetsDirectional.all(AppSpacing.m),
          child: FilledButton(
            onPressed: () => context.push(Routes.checkoutPath),
            child: Text(l10n.cartCheckout),
          ),
        ),
      ),
    );
  }
}
