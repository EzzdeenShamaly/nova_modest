part of 'cart_bloc.dart';

sealed class CartEvent extends Equatable {
  const CartEvent();

  @override
  List<Object?> get props => const [];
}

/// Load the stored cart. Dispatched once at startup and again on a retry.
final class CartRequested extends CartEvent {
  const CartRequested();
}

/// A shopper pressed "add to cart" — on the product page, or anywhere else
/// that ever offers it.
///
/// Carries the choices as values rather than reaching into `ProductDetailBloc`:
/// the cart must not depend on which screen the shopper came from.
final class CartItemAdded extends CartEvent {
  const CartItemAdded({
    required this.product,
    this.colourId,
    this.size,
    this.quantity = 1,
  });

  final Product product;
  final String? colourId;
  final String? size;
  final int quantity;

  @override
  List<Object?> get props => [product, colourId, size, quantity];
}

/// The stepper on one line moved.
final class CartQuantityChanged extends CartEvent {
  const CartQuantityChanged(this.lineId, this.quantity);

  final String lineId;
  final int quantity;

  @override
  List<Object?> get props => [lineId, quantity];
}

/// The × on one line was pressed.
final class CartItemRemoved extends CartEvent {
  const CartItemRemoved(this.lineId);

  final String lineId;

  @override
  List<Object?> get props => [lineId];
}
