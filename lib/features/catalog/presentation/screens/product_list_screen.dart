import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:nova_modest/core/di/injection.dart';
import 'package:nova_modest/core/theme/app_colors.dart';
import 'package:nova_modest/core/theme/app_dimensions.dart';
import 'package:nova_modest/core/widgets/failure_view.dart';
import 'package:nova_modest/features/catalog/presentation/bloc/product_list_bloc.dart';
import 'package:nova_modest/features/catalog/presentation/widgets/filter_chip_row.dart';
import 'package:nova_modest/features/catalog/presentation/widgets/product_card.dart';
import 'package:nova_modest/features/catalog/presentation/widgets/product_filter_sheet.dart';
import 'package:nova_modest/l10n/app_localizations.dart';
import 'package:nova_modest/router/routes.dart';

/// Every product in one category.
///
/// Built from Figma frame `1:2671`. A child of the categories branch, not a tab
/// of its own — the bottom bar belongs to the shell and stays put, and back pops
/// to the categories root.
///
/// Reads the same `CatalogRepository` Home does; there is one catalogue and this
/// screen queries it differently.
class ProductListScreen extends StatelessWidget {
  const ProductListScreen({required this.categoryId, super.key});

  final String categoryId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ProductListBloc>(
      create: (_) =>
          sl<ProductListBloc>()..add(ProductListRequested(categoryId)),
      child: _ProductListView(categoryId: categoryId),
    );
  }
}

class _ProductListView extends StatelessWidget {
  const _ProductListView({required this.categoryId});

  final String categoryId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        // Only where there is something to go back to. This screen is now the
        // categories tab's own root as well as a pushed destination, and a
        // hardcoded `go(categoriesPath)` there sent the shopper from the
        // listing to the same listing — a dead button in a loop. At a tab root
        // the bottom bar is the way out.
        //
        // Icons.arrow_back mirrors with the layout; arrow_left would not.
        //
        // Navigator, not go_router's `context.canPop()`: asking the router in
        // `build` couples the screen to having one above it, which is what
        // broke sixteen of this screen's own tests the moment it was tried.
        // "Is there a route to pop" is a framework question anyway.
        leading: Navigator.of(context).canPop()
            ? IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back),
                tooltip: MaterialLocalizations.of(context).backButtonTooltip,
              )
            : null,
        title: BlocBuilder<ProductListBloc, ProductListState>(
          builder: (context, state) => Text(
            // The heading is the category's own name, which is data — the
            // backend owns the wording, so it is not an ARB string.
            _titleFor(state),
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        actions: [
          BlocBuilder<ProductListBloc, ProductListState>(
            builder: (context, state) => IconButton(
              // The shared filter sheet, the same one search opens. On a
              // single-category listing it draws only the style facet, because
              // every other facet has one option here and could not narrow
              // anything.
              onPressed: state is ProductListLoaded
                  ? () => _openFilterSheet(context, state)
                  : null,
              icon: const Icon(Icons.tune),
              tooltip: l10n.productListFilter,
            ),
          ),
        ],
      ),
      body: BlocBuilder<ProductListBloc, ProductListState>(
        builder: (context, state) => switch (state) {
          ProductListInitial() || ProductListLoading() => const Center(
            child: CircularProgressIndicator(),
          ),
          ProductListError(:final failure) => FailureView(
            failure: failure,
            onRetry: () => context.read<ProductListBloc>().add(
              ProductListRefreshed(categoryId),
            ),
          ),
          ProductListEmpty() => _EmptyState(message: l10n.productListEmpty),
          ProductListLoaded() => _Grid(state: state, categoryId: categoryId),
        },
      ),
    );
  }

  /// The catalogue's own wording once it arrives; the raw id until then, rather
  /// than an invented label.
  String _titleFor(ProductListState state) => state.categoryName ?? categoryId;

  Future<void> _openFilterSheet(
    BuildContext context,
    ProductListLoaded state,
  ) async {
    final bloc = context.read<ProductListBloc>();

    final applied = await showProductFilterSheet(
      context: context,
      products: state.products,
      options: state.options,
      filter: state.filter,
    );

    // Null means dismissed, which is not the same as applying an empty filter —
    // backing out must leave the chip row exactly as it was.
    if (applied != null) bloc.add(ProductListFilterChanged(applied));
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});

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

class _Grid extends StatelessWidget {
  const _Grid({required this.state, required this.categoryId});

  final ProductListLoaded state;
  final String categoryId;

  /// The design's 169x306 card, as a ratio so the columns adapt.
  static const double _cardAspect = 169 / 306;
  static const int _columns = 2;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final bloc = context.read<ProductListBloc>();

    return RefreshIndicator(
      onRefresh: () async => bloc.add(ProductListRefreshed(categoryId)),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsetsDirectional.only(
          top: AppSpacing.m,
          bottom: AppSpacing.xxl,
        ),
        children: [
          FilterChipRow(
            options: [
              for (final tag in state.availableTags)
                FilterChipOption(id: tag.id, label: tag.name),
            ],
            selectedId: state.selectedTagId,
            allLabel: l10n.homeCategoryAll,
            onSelected: (id) => bloc.add(ProductListTagSelected(id)),
          ),
          SizedBox(height: AppSpacing.l),
          if (state.isFilteredEmpty)
            Padding(
              padding: EdgeInsetsDirectional.all(AppSpacing.l),
              child: Text(
                l10n.productListFilterEmpty,
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
