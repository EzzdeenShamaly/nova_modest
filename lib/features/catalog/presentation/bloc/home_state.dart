part of 'home_bloc.dart';

/// The four states `06-flutter-error-guard.md` §5 requires of anything that
/// loads, plus an initial one.
///
/// This is the app's first list-shaped feature, so it is the first place the
/// contract can actually be demonstrated — `auth` is submit-shaped and has no
/// meaningful empty case, which is why `progress.md` has been carrying "first
/// list-shaped feature" as an open item since the scaffold.
sealed class HomeState extends Equatable {
  const HomeState();

  @override
  List<Object?> get props => const [];
}

final class HomeInitial extends HomeState {
  const HomeInitial();
}

final class HomeLoading extends HomeState {
  const HomeLoading();
}

/// The catalogue itself came back empty.
///
/// Distinct from a filter that matches nothing: that is a state *within*
/// [HomeLoaded], because the categories must stay on screen so the user can
/// choose a different one. Collapsing the two would strand them.
final class HomeEmpty extends HomeState {
  const HomeEmpty();
}

final class HomeError extends HomeState {
  const HomeError(this.failure);

  final Failure failure;

  @override
  List<Object?> get props => [failure];
}

final class HomeLoaded extends HomeState {
  const HomeLoaded({
    required this.categories,
    required this.products,
    this.selectedCategoryId,
  });

  final List<ProductCategory> categories;

  /// Everything the catalogue returned. The grid shows [visibleProducts].
  final List<Product> products;

  /// `null` is the "All" chip — a UI affordance, not a category the backend
  /// returns.
  final String? selectedCategoryId;

  /// The filter applied. Derived here rather than in the widget: which products
  /// a category contains is a rule about the data, and widgets describe layout
  /// (`01-flutter-architecture-guard.md`).
  List<Product> get visibleProducts => selectedCategoryId == null
      ? products
      : products.where((p) => p.categoryId == selectedCategoryId).toList();

  /// True when the chosen category has nothing in it, while the catalogue does.
  bool get isFilteredEmpty => products.isNotEmpty && visibleProducts.isEmpty;

  @override
  List<Object?> get props => [categories, products, selectedCategoryId];
}
