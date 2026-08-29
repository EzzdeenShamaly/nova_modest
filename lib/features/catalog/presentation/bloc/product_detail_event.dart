part of 'product_detail_bloc.dart';

sealed class ProductDetailEvent extends Equatable {
  const ProductDetailEvent();

  @override
  List<Object?> get props => const [];
}

/// The screen opened for a product.
final class ProductDetailRequested extends ProductDetailEvent {
  const ProductDetailRequested(this.productId);

  final String productId;

  @override
  List<Object?> get props => [productId];
}

/// A retry from the error state.
final class ProductDetailRefreshed extends ProductDetailEvent {
  const ProductDetailRefreshed(this.productId);

  final String productId;

  @override
  List<Object?> get props => [productId];
}

final class ProductDetailColourSelected extends ProductDetailEvent {
  const ProductDetailColourSelected(this.colourId);

  final String colourId;

  @override
  List<Object?> get props => [colourId];
}

final class ProductDetailSizeSelected extends ProductDetailEvent {
  const ProductDetailSizeSelected(this.size);

  final String size;

  @override
  List<Object?> get props => [size];
}

/// The stepper moved. The bloc clamps; the event only reports the intent.
final class ProductDetailQuantityChanged extends ProductDetailEvent {
  const ProductDetailQuantityChanged(this.quantity);

  final int quantity;

  @override
  List<Object?> get props => [quantity];
}
