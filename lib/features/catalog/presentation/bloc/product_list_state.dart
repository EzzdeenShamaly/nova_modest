part of 'product_list_bloc.dart';

/// The same four-state contract Home established
/// (`06-flutter-error-guard.md` §5), plus an initial state.
sealed class ProductListState extends Equatable {
  const ProductListState();

  /// The category's display name once it is known.
  ///
  /// Data, not an ARB string — the backend owns the wording. Null until the
  /// catalogue answers, and the screen falls back to the id rather than
  /// inventing a label.
  String? get categoryName => null;

  @override
  List<Object?> get props => const [];
}

final class ProductListInitial extends ProductListState {
  const ProductListInitial();
}

final class ProductListLoading extends ProductListState {
  const ProductListLoading();
}

/// The category itself holds nothing.
///
/// Distinct from a tag filter that matches nothing: that is a state *within*
/// [ProductListLoaded], because the chips have to stay on screen so another can
/// be chosen. Collapsing the two would strand the user.
final class ProductListEmpty extends ProductListState {
  const ProductListEmpty({this.categoryName});

  @override
  final String? categoryName;

  @override
  List<Object?> get props => [categoryName];
}

final class ProductListError extends ProductListState {
  const ProductListError(this.failure);

  final Failure failure;

  @override
  List<Object?> get props => [failure];
}

final class ProductListLoaded extends ProductListState {
  const ProductListLoaded({
    required this.categoryId,
    required this.products,
    this.categoryName,
    this.filter = ProductFilter.none,
  });

  final String categoryId;

  @override
  final String? categoryName;

  /// Every product in the category. The grid shows [visibleProducts].
  final List<Product> products;

  /// How the grid is narrowed.
  ///
  /// The app-wide [ProductFilter], not a tag of its own: this screen happens to
  /// expose only the tag facet through its chip row, but the sheet it shares
  /// with search can set any of them, and one model means one `apply`.
  final ProductFilter filter;

  /// `null` is the "All" chip. Kept as a name of its own because the chip row
  /// is a single-select affordance and should not have to know about the rest
  /// of the filter.
  String? get selectedTagId => filter.tagId;

  /// What the filter can currently be set to, derived from the products in
  /// hand. Only the tags facet has more than one option on a single-category
  /// listing, which is why the sheet draws only that here.
  ProductFilterOptions get options => ProductFilterOptions.from(products);

  /// The tags present in this category, in first-seen order, de-duplicated.
  List<ProductTag> get availableTags => options.tags;

  /// The filter applied. Derived here rather than in the widget: which products
  /// a filter covers is a rule about the data, and widgets describe layout
  /// (`01-flutter-architecture-guard.md`).
  List<Product> get visibleProducts => filter.apply(products);

  /// True when the filter covers nothing, while the category does.
  bool get isFilteredEmpty => products.isNotEmpty && visibleProducts.isEmpty;

  @override
  List<Object?> get props => [categoryId, categoryName, products, filter];
}
