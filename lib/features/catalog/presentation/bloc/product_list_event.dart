part of 'product_list_bloc.dart';

sealed class ProductListEvent extends Equatable {
  const ProductListEvent();

  @override
  List<Object?> get props => const [];
}

/// The screen opened for a category and needs its products.
final class ProductListRequested extends ProductListEvent {
  const ProductListRequested(this.categoryId);

  final String categoryId;

  @override
  List<Object?> get props => [categoryId];
}

/// Pull-to-refresh, or a retry from the error state.
final class ProductListRefreshed extends ProductListEvent {
  const ProductListRefreshed(this.categoryId);

  final String categoryId;

  @override
  List<Object?> get props => [categoryId];
}

/// A secondary chip was tapped. `null` is the "All" chip.
///
/// Kept alongside [ProductListFilterChanged] rather than folded into it: the
/// chip row edits exactly one facet and should not have to assemble a whole
/// filter value to say so.
final class ProductListTagSelected extends ProductListEvent {
  const ProductListTagSelected(this.tagId);

  final String? tagId;

  @override
  List<Object?> get props => [tagId];
}

/// The shared filter sheet was applied, carrying every facet at once.
final class ProductListFilterChanged extends ProductListEvent {
  const ProductListFilterChanged(this.filter);

  final ProductFilter filter;

  @override
  List<Object?> get props => [filter];
}
