part of 'product_detail_bloc.dart';

/// Loading, error and data — the contract from `06-flutter-error-guard.md` §5,
/// minus the empty case.
///
/// **There is deliberately no `Empty` state.** Empty means "the query succeeded
/// and matched nothing", which a single-entity screen cannot be in: a product
/// either exists or it does not, and "does not" is a `NotFoundFailure` carried
/// by [ProductDetailError]. Adding an empty state here would create one nothing
/// could ever emit.
sealed class ProductDetailState extends Equatable {
  const ProductDetailState();

  @override
  List<Object?> get props => const [];
}

final class ProductDetailInitial extends ProductDetailState {
  const ProductDetailInitial();
}

final class ProductDetailLoading extends ProductDetailState {
  const ProductDetailLoading();
}

final class ProductDetailError extends ProductDetailState {
  const ProductDetailError(this.failure);

  final Failure failure;

  @override
  List<Object?> get props => [failure];
}

final class ProductDetailLoaded extends ProductDetailState {
  const ProductDetailLoaded({
    required this.product,
    this.selectedColourId,
    this.selectedSize,
    this.quantity = 1,
  });

  final Product product;

  /// Null only when the product offers no colours at all.
  final String? selectedColourId;

  /// Null only when the product offers no sizes at all.
  final String? selectedSize;

  final int quantity;

  /// Whether the shopper has made every choice the product requires.
  ///
  /// A product with no colours or no sizes needs no choice for them, so the
  /// button is enabled — the check is "nothing outstanding", not "everything
  /// picked".
  bool get isSelectionComplete =>
      (product.colours.isEmpty || selectedColourId != null) &&
      (product.sizes.isEmpty || selectedSize != null);

  ProductDetailLoaded copyWith({
    String? selectedColourId,
    String? selectedSize,
    int? quantity,
  }) => ProductDetailLoaded(
    product: product,
    selectedColourId: selectedColourId ?? this.selectedColourId,
    selectedSize: selectedSize ?? this.selectedSize,
    quantity: quantity ?? this.quantity,
  );

  @override
  List<Object?> get props => [
    product,
    selectedColourId,
    selectedSize,
    quantity,
  ];
}
