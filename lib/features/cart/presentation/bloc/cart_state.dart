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

  /// Whether another **distinct line** may be added.
  ///
  /// A rule about the cart, so it lives on the state and the product page reads
  /// it rather than counting lines in `build()`
  /// (`01-flutter-architecture-guard.md`). False in every state but
  /// [CartLoaded], because a cart that has not loaded cannot be full.
  bool get isFull => false;

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
  bool get isFull => items.length >= CartItem.maxLines;

  @override
  List<Object?> get props => [items, totals];
}

/// The cart is full and one addition was declined. **Not an error state.**
///
/// It carries the cart exactly as [CartLoaded] does, because the cart is
/// unchanged and still correct — the screen keeps rendering the same list, and
/// only a message is new. Folding this into [CartError] would replace a working
/// cart with an error card over something the shopper can simply undo by
/// removing a line.
///
/// The same shape `CheckoutFailed` has, for the same reason.
final class CartAdditionRefused extends CartState {
  const CartAdditionRefused({required this.items, required this.totals});

  final List<CartItem> items;
  final CartTotals totals;

  /// The cart this refusal leaves untouched, for a screen that only wants to
  /// draw it.
  CartLoaded get cart => CartLoaded(items: items, totals: totals);

  @override
  int get itemCount => cart.itemCount;

  @override
  bool get isFull => true;

  @override
  List<Object?> get props => [items, totals];
}
