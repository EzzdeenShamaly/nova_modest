import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:nova_modest/core/di/injection.dart';
import 'package:nova_modest/core/theme/app_colors.dart';
import 'package:nova_modest/core/theme/app_dimensions.dart';
import 'package:nova_modest/core/widgets/failure_view.dart';
import 'package:nova_modest/features/catalog/presentation/bloc/home_bloc.dart';
import 'package:nova_modest/features/catalog/presentation/widgets/filter_chip_row.dart';
import 'package:nova_modest/features/catalog/presentation/widgets/home_hero_banner.dart';
import 'package:nova_modest/features/catalog/presentation/widgets/product_card.dart';
import 'package:nova_modest/l10n/app_localizations.dart';
import 'package:nova_modest/router/routes.dart';

/// The storefront.
///
/// Built from Figma frame `1:2469`. The bottom navigation is not here — it
/// belongs to the shell this screen is a branch of, so it survives tab switches
/// instead of being rebuilt per tab.
///
/// Renders all four states explicitly (`06-flutter-error-guard.md` §5): loading,
/// error with a retry, empty, and the catalogue.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<HomeBloc>(
      create: (_) => sl<HomeBloc>()..add(const HomeRequested()),
      child: const _HomeView(),
    );
  }
}

class _HomeView extends StatelessWidget {
  const _HomeView();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          l10n.brandName,
          // direction-fixed: a brandmark's glyph order is fixed by the mark
          // itself, not by the reader's language
          textDirection: TextDirection.ltr,
          style: Theme.of(context).textTheme.headlineLarge,
        ),
        actions: [
          IconButton(
            // Search lives in the categories branch, so this switches tab as
            // well as screen — which is what the design shows: its results
            // frame draws the bottom bar with Categories active.
            onPressed: () => context.go(Routes.search),
            icon: const Icon(Icons.search),
            tooltip: l10n.homeSearch,
          ),
        ],
      ),
      body: BlocBuilder<HomeBloc, HomeState>(
        builder: (context, state) => switch (state) {
          HomeInitial() ||
          HomeLoading() => const Center(child: CircularProgressIndicator()),
          HomeError(:final failure) => FailureView(
            failure: failure,
            onRetry: () => context.read<HomeBloc>().add(const HomeRefreshed()),
          ),
          HomeEmpty() => _EmptyCatalogue(message: l10n.homeEmpty),
          HomeLoaded() => _Catalogue(state: state),
        },
      ),
    );
  }
}

class _EmptyCatalogue extends StatelessWidget {
  const _EmptyCatalogue({required this.message});

  final String message;

  static const double _iconSize = 56;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsetsDirectional.all(AppSpacing.l),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.checkroom_outlined,
              size: _iconSize,
              color: AppColors.subtle,
              semanticLabel: '',
            ),
            SizedBox(height: AppSpacing.m),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: AppColors.mutedStrong),
            ),
          ],
        ),
      ),
    );
  }
}

class _Catalogue extends StatelessWidget {
  const _Catalogue({required this.state});

  final HomeLoaded state;

  /// The design's 169x310 card, as a ratio so the columns adapt.
  static const double _cardAspect = 169 / 310;
  static const int _columns = 2;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final bloc = context.read<HomeBloc>();

    return RefreshIndicator(
      onRefresh: () async => bloc.add(const HomeRefreshed()),
      child: ListView(
        // Always scrollable so pull-to-refresh works even when the content is
        // shorter than the viewport.
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsetsDirectional.only(bottom: AppSpacing.xxl),
        children: [
          Padding(
            padding: EdgeInsetsDirectional.symmetric(horizontal: AppSpacing.l),
            child: HomeHeroBanner(
              // The abayas listing is the storefront's front door today.
              onShopNow: () =>
                  context.go(Routes.productList(Routes.entryCategoryId)),
            ),
          ),
          SizedBox(height: AppSpacing.xxl),
          // Full-bleed: the chips run off the edge of the screen by design, so
          // the row carries its own padding instead of inheriting the page's.
          FilterChipRow(
            options: [
              for (final category in state.categories)
                FilterChipOption(id: category.id, label: category.name),
            ],
            selectedId: state.selectedCategoryId,
            allLabel: l10n.homeCategoryAll,
            onSelected: (id) => bloc.add(HomeCategorySelected(id)),
          ),
          SizedBox(height: AppSpacing.xxl),
          Padding(
            padding: EdgeInsetsDirectional.symmetric(horizontal: AppSpacing.l),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.homeFeaturedTitle,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                TextButton(
                  onPressed: () =>
                      context.go(Routes.productList(Routes.entryCategoryId)),
                  child: Text(l10n.homeSeeAll),
                ),
              ],
            ),
          ),
          SizedBox(height: AppSpacing.l),
          if (state.isFilteredEmpty)
            Padding(
              padding: EdgeInsetsDirectional.all(AppSpacing.l),
              child: Text(
                l10n.homeFilterEmpty,
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: AppColors.mutedStrong),
              ),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsetsDirectional.symmetric(
                horizontal: AppSpacing.l,
              ),
              itemCount: state.visibleProducts.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: _columns,
                crossAxisSpacing: AppSpacing.s,
                mainAxisSpacing: AppSpacing.s,
                childAspectRatio: _cardAspect,
              ),
              itemBuilder: (context, index) {
                final product = state.visibleProducts[index];
                return ProductCard(
                  product: product,
                  // push, not go: the detail sits above the shell, and back
                  // returns to whichever screen opened it.
                  onTap: () => context.push(Routes.product(product.id)),
                );
              },
            ),
        ],
      ),
    );
  }
}
