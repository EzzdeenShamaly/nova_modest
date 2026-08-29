part of 'cart_bloc.dart';

/// The four states from `06-flutter-error-guard.md` §5, all of them reachable.
///
/// [CartEmpty] is a distinct state rather than `CartLoaded([])` because "your
/// cart is empty" is a different screen from a list that happens to have no
/// rows — it has no summary, no checkout button, and an invitation to browse.
///
/// [CartError] is reachable because the cart is stored on disk and rehydrated
/// through the catalogue: either read can fail. An in-memory cart would have
/// made this state unreachable, which is why it was not built that way.
sealed class CartState extends Equatable {
  const CartState();

  /// How many garments the cart holds, counting quantities — what the bottom
  /// navigation badge reflects. Zero in every state but [CartLoaded].
  int get itemCount => 0;

  @override
  List<Object?> get props => const [];
}

final class CartInitial extends CartState {
  const CartInitial();
}

final class CartLoading extends CartState {
  const CartLoading();
}

final class CartEmpty extends CartState {
  const CartEmpty();
}

final class CartError extends CartState {
  const CartError(this.failure);

  final Failure failure;

  @override
  List<Object?> get props => [failure];
}

final class CartLoaded extends CartState {
  const CartLoaded({required this.items, required this.totals});

  final List<CartItem> items;

  /// Computed when the state is built, not in a widget: a `fold` over prices
  /// inside `build()` is business logic in the widget layer.
  final CartTotals totals;

  @override
  int get itemCount => items.fold<int>(0, (sum, item) => sum + item.quantity);

  @override
  List<Object?> get props => [items, totals];
}
