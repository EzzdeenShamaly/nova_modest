import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:nova_modest/core/error/failure.dart';
import 'package:nova_modest/core/error/result.dart';
import 'package:nova_modest/features/cart/domain/entities/cart_item.dart';
import 'package:nova_modest/features/cart/domain/entities/cart_totals.dart';
import 'package:nova_modest/features/cart/domain/repositories/cart_repository.dart';
import 'package:nova_modest/features/catalog/domain/entities/product.dart';

part 'cart_event.dart';
part 'cart_state.dart';

/// Owns the shopper's cart for the whole app.
///
/// App-wide (`@lazySingleton`), unlike `HomeBloc` or `ProductDetailBloc`: the
/// product page writes to it, the bottom navigation badge reads from it, and it
/// has to survive tab switches. That is the shared-across-features case
/// `01-flutter-architecture-guard` reserves app-level state for — and the
/// reason the choices do not live in `ProductDetailBloc`, which is a factory
/// discarded when the product page closes.
@lazySingleton
class CartBloc extends Bloc<CartEvent, CartState> {
  CartBloc(this._repository) : super(const CartInitial()) {
    // droppable: one load in flight is enough; a duplicate is waste.
    on<CartRequested>(_onRequested, transformer: droppable());
    // sequential: every mutation is read-modify-write against one stored list,
    // so two of them interleaving would lose one of the changes.
    on<CartItemAdded>(_onItemAdded, transformer: sequential());
    on<CartQuantityChanged>(_onQuantityChanged, transformer: sequential());
    on<CartItemRemoved>(_onItemRemoved, transformer: sequential());
  }

  final CartRepository _repository;

  Future<void> _onRequested(
    CartRequested event,
    Emitter<CartState> emit,
  ) async {
    emit(const CartLoading());
    _emitCart(await _repository.load(), emit);
  }

  /// Adding does **not** pass through [CartLoading].
  ///
  /// The shopper is usually on the product page when this fires, and blanking
  /// the cart tab behind them would be invisible churn; when they are on the
  /// cart itself, a spinner between two counts is a flicker, not information.
  /// The same holds for the two mutations below.
  Future<void> _onItemAdded(
    CartItemAdded event,
    Emitter<CartState> emit,
  ) async {
    _emitCart(
      await _repository.add(
        product: event.product,
        colourId: event.colourId,
        size: event.size,
        quantity: event.quantity,
      ),
      emit,
    );
  }

  Future<void> _onQuantityChanged(
    CartQuantityChanged event,
    Emitter<CartState> emit,
  ) async {
    // Clamped here rather than only by disabling the stepper's buttons: how
    // many a shopper may take is a rule about the state, and the buttons then
    // reflect it instead of being the rule themselves.
    final clamped = event.quantity.clamp(1, CartItem.maxQuantity);
    _emitCart(await _repository.updateQuantity(event.lineId, clamped), emit);
  }

  Future<void> _onItemRemoved(
    CartItemRemoved event,
    Emitter<CartState> emit,
  ) async {
    _emitCart(await _repository.remove(event.lineId), emit);
  }

  /// The one place a repository result becomes a state.
  ///
  /// No try/catch anywhere in this bloc: the repository returns a `Result` and
  /// this folds it. A catch here would mean the data layer is leaking
  /// (`06-flutter-error-guard.md` §4).
  void _emitCart(Result<List<CartItem>> result, Emitter<CartState> emit) {
    emit(
      result.fold(
        CartError.new,
        (items) => items.isEmpty
            ? const CartEmpty()
            : CartLoaded(items: items, totals: CartTotals.of(items)),
      ),
    );
  }
}
