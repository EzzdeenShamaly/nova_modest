import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:nova_modest/core/widgets/app_bottom_nav.dart';
import 'package:nova_modest/features/cart/presentation/bloc/cart_bloc.dart';
import 'package:nova_modest/l10n/app_localizations.dart';

/// The frame the four tabs live in.
///
/// Wraps a `StatefulShellRoute`'s [navigationShell], so each tab keeps its own
/// navigator, stack and scroll position — the point of a shell route rather than
/// four screens rebuilt from scratch on every switch.
class AppShell extends StatelessWidget {
  const AppShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      body: navigationShell,
      // BlocSelector, not BlocBuilder: the bar only cares whether the cart is
      // empty, so re-ordering a line or changing a quantity from 2 to 3 must
      // not rebuild it.
      bottomNavigationBar: BlocSelector<CartBloc, CartState, bool>(
        selector: (state) => state.itemCount > 0,
        builder: (context, hasItems) => AppBottomNav(
          currentIndex: navigationShell.currentIndex,
          // Order matches Routes.shellBranches, so the bar and the router cannot
          // disagree about which tab is which.
          items: [
            AppBottomNavItem(icon: Icons.home_outlined, label: l10n.navHome),
            AppBottomNavItem(
              icon: Icons.grid_view_outlined,
              label: l10n.navCategories,
            ),
            AppBottomNavItem(
              icon: Icons.shopping_cart_outlined,
              label: l10n.navCart,
              showBadge: hasItems,
            ),
            AppBottomNavItem(
              icon: Icons.person_outline,
              label: l10n.navProfile,
            ),
          ],
          onTap: (index) => navigationShell.goBranch(
            index,
            // Tapping the tab you are already on returns it to its root, which
            // is the platform convention on both iOS and Android.
            initialLocation: index == navigationShell.currentIndex,
          ),
        ),
      ),
    );
  }
}
