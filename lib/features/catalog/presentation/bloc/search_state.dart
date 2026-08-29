part of 'search_bloc.dart';

/// The four-state contract from `06-flutter-error-guard.md` §5, plus the one
/// state a search screen has that a listing does not.
///
/// [SearchIdle] is **not** the empty state. Empty means "this query matched
/// nothing"; idle means "nothing has been asked yet", and the design gives it
/// its own screen — recent searches, trending terms and categories to browse.
/// Collapsing the two would show "no results" to someone who has not typed.
sealed class SearchState extends Equatable {
  const SearchState();

  /// What the field should contain. Empty on every state but a committed one,
  /// so clearing the field and returning to discovery cannot leave stale text
  /// behind.
  String get query => '';

  @override
  List<Object?> get props => const [];
}

final class SearchInitial extends SearchState {
  const SearchInitial();
}

final class SearchLoading extends SearchState {
  const SearchLoading();
}

/// The discovery screen, from Figma `1:1282`.
final class SearchIdle extends SearchState {
  const SearchIdle({
    this.history = const [],
    this.trending = const [],
    this.categories = const [],
  });

  /// This device's own recent searches, newest first.
  final List<String> history;

  /// Terms the catalogue suggests.
  final List<String> trending;

  /// Categories to browse instead of searching.
  final List<ProductCategory> categories;

  SearchIdle copyWith({List<String>? history}) => SearchIdle(
    history: history ?? this.history,
    trending: trending,
    categories: categories,
  );

  @override
  List<Object?> get props => [history, trending, categories];
}

final class SearchError extends SearchState {
  const SearchError(this.failure);

  final Failure failure;

  @override
  List<Object?> get props => [failure];
}

/// The query ran and matched nothing in the catalogue.
final class SearchEmpty extends SearchState {
  const SearchEmpty(this.query);

  @override
  final String query;

  @override
  List<Object?> get props => [query];
}

/// The results screen, from Figma `1:1077`.
final class SearchResults extends SearchState {
  const SearchResults({
    required this.query,
    required this.products,
    this.categories = const [],
    this.filter = ProductFilter.none,
    this.sort = ProductSort.relevance,
  });

  @override
  final String query;

  /// Everything the query matched. The grid shows [visibleProducts].
  final List<Product> products;

  /// The catalogue's categories, carried so the filter sheet can name them —
  /// products know only their `categoryId`, and the name is data the backend
  /// owns rather than an ARB string.
  final List<ProductCategory> categories;

  final ProductFilter filter;
  final ProductSort sort;

  ProductFilterOptions get options =>
      ProductFilterOptions.from(products, categories: categories);

  /// Filtered, then ordered. Both are rules about the data, so neither happens
  /// in a widget (`01-flutter-architecture-guard.md`).
  List<Product> get visibleProducts => sort.apply(filter.apply(products));

  /// True when the filter covers nothing, while the query itself matched
  /// something. Deliberately not [SearchEmpty]: the filter controls have to
  /// stay on screen or the shopper is stranded with no way to widen it — the
  /// same distinction the product listing makes.
  bool get isFilteredEmpty => products.isNotEmpty && visibleProducts.isEmpty;

  SearchResults copyWith({ProductFilter? filter, ProductSort? sort}) =>
      SearchResults(
        query: query,
        products: products,
        categories: categories,
        filter: filter ?? this.filter,
        sort: sort ?? this.sort,
      );

  @override
  List<Object?> get props => [query, products, categories, filter, sort];
}
