import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:nova_modest/core/di/injection.dart';
import 'package:nova_modest/core/theme/app_colors.dart';
import 'package:nova_modest/core/theme/app_dimensions.dart';
import 'package:nova_modest/core/widgets/failure_view.dart';
import 'package:nova_modest/features/catalog/presentation/bloc/search_bloc.dart';
import 'package:nova_modest/features/catalog/presentation/widgets/category_discovery_grid.dart';
import 'package:nova_modest/features/catalog/presentation/widgets/product_card.dart';
import 'package:nova_modest/features/catalog/presentation/widgets/product_filter_sheet.dart';
import 'package:nova_modest/features/catalog/presentation/widgets/product_sort_sheet.dart';
import 'package:nova_modest/features/catalog/presentation/widgets/search_field.dart';
import 'package:nova_modest/features/catalog/presentation/widgets/search_term_chips.dart';
import 'package:nova_modest/l10n/app_localizations.dart';
import 'package:nova_modest/router/routes.dart';

/// Search, built from Figma `1:1282` (browsing) and `1:1077` (results).
///
/// **One screen, two faces.** The field is present in both frames and an empty
/// query is what separates them, so this is a state change rather than a route
/// change — clearing the field returns to the discovery content instantly
/// instead of navigating.
///
/// A child of the categories branch, like the product listing: the results
/// frame draws the bottom bar with Categories active, and nesting keeps the bar
/// in place while back pops to the categories root.
///
/// Reads the same `CatalogRepository` every other catalogue screen does; the
/// search runs over the catalogue that is already there.
class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<SearchBloc>(
      create: (_) => sl<SearchBloc>()..add(const SearchOpened()),
      child: const _SearchView(),
    );
  }
}

class _SearchView extends StatefulWidget {
  const _SearchView();

  @override
  State<_SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends State<_SearchView> {
  /// Owned here rather than driven from state.
  ///
  /// A listener that wrote the state's query back into the field would fight
  /// the shopper mid-word: while the debounce is still pending the state
  /// carries the *previous* query. Instead the two places that legitimately
  /// change the text — a chip tap and the clear control — set it directly.
  final TextEditingController _controller = TextEditingController();

  /// The design's 48x48 filter button. A tap-target square, not a value on the
  /// spacing scale (`12-flutter-design-system-guard.md` §6).
  static const double _filterButton = 48;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit(String term) {
    _controller.text = term;
    context.read<SearchBloc>().add(SearchSubmitted(term));
  }

  void _clear() {
    _controller.clear();
    context.read<SearchBloc>().add(const SearchCleared());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final bloc = context.read<SearchBloc>();

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
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsetsDirectional.all(AppSpacing.l),
            child: BlocBuilder<SearchBloc, SearchState>(
              builder: (context, state) => Row(
                children: [
                  Expanded(
                    child: SearchField(
                      controller: _controller,
                      onChanged: (query) => bloc.add(SearchQueryChanged(query)),
                      onSubmitted: _submit,
                      onCleared: _clear,
                    ),
                  ),
                  // Only once there are results to narrow. The browsing frame
                  // has no filter button because there is nothing to filter.
                  if (state is SearchResults) ...[
                    SizedBox(width: AppSpacing.s),
                    _FilterButton(
                      size: _filterButton,
                      activeCount: state.filter.activeCount,
                      onTap: () => _openFilterSheet(context, state),
                    ),
                  ],
                ],
              ),
            ),
          ),
          Expanded(
            child: BlocBuilder<SearchBloc, SearchState>(
              builder: (context, state) => switch (state) {
                SearchInitial() || SearchLoading() => const Center(
                  child: CircularProgressIndicator(),
                ),
                SearchError(:final failure) => FailureView(
                  failure: failure,
                  onRetry: () => bloc.add(const SearchOpened()),
                ),
                SearchIdle() => _Discovery(state: state, onTerm: _submit),
                SearchEmpty(:final query) => _NoResults(query: query),
                SearchResults() => _Results(
                  state: state,
                  onSort: () => _openSortSheet(context, state),
                ),
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openFilterSheet(
    BuildContext context,
    SearchResults state,
  ) async {
    final bloc = context.read<SearchBloc>();

    final applied = await showProductFilterSheet(
      context: context,
      products: state.products,
      options: state.options,
      filter: state.filter,
    );

    // Null means dismissed, which is not the same as applying an empty filter:
    // backing out must leave the results exactly as they were.
    if (applied != null) bloc.add(SearchFilterChanged(applied));
  }

  Future<void> _openSortSheet(BuildContext context, SearchResults state) async {
    final bloc = context.read<SearchBloc>();

    final chosen = await showProductSortSheet(
      context: context,
      sort: state.sort,
    );
    if (chosen != null) bloc.add(SearchSortChanged(chosen));
  }
}

/// The design's filled square beside the field.
class _FilterButton extends StatelessWidget {
  const _FilterButton({
    required this.size,
    required this.activeCount,
    required this.onTap,
  });

  final double size;
  final int activeCount;
  final VoidCallback onTap;

  /// The same dot the bottom navigation puts on the cart. A mark, not a
  /// measurement on the spacing scale.
  static const double _badge = 8;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Semantics(
      button: true,
      label: l10n.productListFilter,
      child: Material(
        color: AppColors.primaryText,
        borderRadius: BorderRadius.circular(AppRadius.s),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox.square(
            dimension: size,
            child: Stack(
              children: [
                Center(
                  child: Icon(
                    Icons.tune,
                    size: AppFontSize.xl,
                    color: AppColors.background,
                    semanticLabel: '',
                  ),
                ),
                // A dot, not a number: how many facets are set matters less
                // than that some are, and the design has no counter here.
                if (activeCount > 0)
                  PositionedDirectional(
                    top: AppSpacing.xxs,
                    end: AppSpacing.xxs,
                    child: Container(
                      width: _badge,
                      height: _badge,
                      decoration: const BoxDecoration(
                        color: AppColors.accent,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Recent searches, trending terms and categories to browse.
class _Discovery extends StatelessWidget {
  const _Discovery({required this.state, required this.onTerm});

  final SearchIdle state;
  final ValueChanged<String> onTerm;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final bloc = context.read<SearchBloc>();

    return ListView(
      padding: EdgeInsetsDirectional.only(
        start: AppSpacing.l,
        end: AppSpacing.l,
        bottom: AppSpacing.xxl,
      ),
      children: [
        // Each section draws only when it has something. A heading over an
        // empty wrap is three lines of nothing on first launch, when the
        // history is necessarily empty.
        if (state.history.isNotEmpty)
          _Section(
            title: l10n.searchRecent,
            action: TextButton(
              onPressed: () => bloc.add(const SearchHistoryCleared()),
              child: Text(l10n.filterClearAll),
            ),
            child: SearchTermChips(
              terms: state.history,
              onSelected: onTerm,
              onRemoved: (term) => bloc.add(SearchHistoryEntryRemoved(term)),
            ),
          ),
        if (state.trending.isNotEmpty)
          _Section(
            title: l10n.searchTrending,
            action: Icon(
              Icons.trending_up,
              size: AppFontSize.xl,
              color: AppColors.accent,
              semanticLabel: '',
            ),
            child: SearchTermChips(terms: state.trending, onSelected: onTerm),
          ),
        if (state.categories.isNotEmpty)
          _Section(
            title: l10n.searchExploreCategories,
            child: CategoryDiscoveryGrid(
              categories: state.categories,
              onSelected: (category) =>
                  context.go(Routes.productList(category.id)),
            ),
          ),
      ],
    );
  }
}

/// The count, the sort control and the grid.
class _Results extends StatelessWidget {
  const _Results({required this.state, required this.onSort});

  final SearchResults state;
  final VoidCallback onSort;

  /// The design's 169x305.5 cell.
  static const double _cellAspect = 169 / 305.5;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final products = state.visibleProducts;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsetsDirectional.symmetric(horizontal: AppSpacing.l),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  l10n.searchResultCount(products.length, state.query),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ),
              TextButton.icon(
                onPressed: onSort,
                icon: const Icon(Icons.expand_more),
                label: Text(l10n.searchSort),
              ),
            ],
          ),
        ),
        SizedBox(height: AppSpacing.m),
        Expanded(
          child: state.isFilteredEmpty
              // Inside the results, not SearchEmpty: the filter controls above
              // have to stay reachable or the shopper cannot widen it again.
              ? _Message(text: l10n.searchFilterEmpty)
              : GridView.builder(
                  padding: EdgeInsetsDirectional.only(
                    start: AppSpacing.l,
                    end: AppSpacing.l,
                    bottom: AppSpacing.xxl,
                  ),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: AppSpacing.l,
                    crossAxisSpacing: AppSpacing.s,
                    childAspectRatio: _cellAspect,
                  ),
                  itemCount: products.length,
                  itemBuilder: (context, index) => ProductCard(
                    product: products[index],
                    onTap: () =>
                        context.push(Routes.product(products[index].id)),
                  ),
                ),
        ),
      ],
    );
  }
}

class _NoResults extends StatelessWidget {
  const _NoResults({required this.query});

  final String query;

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
              Icons.search_off_outlined,
              size: _iconSize,
              color: AppColors.subtle,
              semanticLabel: '',
            ),
            SizedBox(height: AppSpacing.m),
            Text(l10n.searchEmptyTitle, style: textTheme.headlineMedium),
            SizedBox(height: AppSpacing.xs),
            Text(
              l10n.searchEmptyBody(query),
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.mutedStrong,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsetsDirectional.all(AppSpacing.l),
    child: Text(
      text,
      textAlign: TextAlign.center,
      style: Theme.of(
        context,
      ).textTheme.bodyMedium?.copyWith(color: AppColors.mutedStrong),
    ),
  );
}

/// A titled block on the discovery screen.
class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child, this.action});

  final String title;
  final Widget child;

  /// The design puts "clear all" opposite one heading and a trending mark
  /// opposite another.
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsetsDirectional.only(bottom: AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(title, style: Theme.of(context).textTheme.headlineMedium),
              if (action != null) ...[const Spacer(), action!],
            ],
          ),
          SizedBox(height: AppSpacing.m),
          child,
        ],
      ),
    );
  }
}
