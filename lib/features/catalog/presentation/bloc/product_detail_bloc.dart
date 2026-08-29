import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:nova_modest/core/error/failure.dart';
import 'package:nova_modest/core/error/result.dart';
import 'package:nova_modest/features/catalog/domain/entities/product.dart';
import 'package:nova_modest/features/catalog/domain/repositories/catalog_repository.dart';

part 'product_detail_event.dart';
part 'product_detail_state.dart';

/// Owns one product and the choices the shopper is making about it.
///
/// A **factory**, scoped to the screen: two products opened in sequence must not
/// share a size or a quantity.
///
/// Reads the same [CatalogRepository] the rest of the catalogue does.
///
/// The colour, size and quantity live here rather than in widget `setState`
/// because they are the inputs to "add to cart" — decisions the app has a rule
/// about, not ephemeral decoration (`02-flutter-state-guard.md`).
@injectable
class ProductDetailBloc extends Bloc<ProductDetailEvent, ProductDetailState> {
  ProductDetailBloc(this._repository) : super(const ProductDetailInitial()) {
    on<ProductDetailRequested>(_onRequested, transformer: droppable());
    on<ProductDetailRefreshed>(_onRefreshed, transformer: droppable());
    // restartable: only the newest choice matters.
    on<ProductDetailColourSelected>(
      _onColourSelected,
      transformer: restartable(),
    );
    on<ProductDetailSizeSelected>(_onSizeSelected, transformer: restartable());
    on<ProductDetailQuantityChanged>(
      _onQuantityChanged,
      transformer: restartable(),
    );
  }

  /// A sane ceiling for a stepper. The real limit is stock, which the backend
  /// will supply; until then this stops the counter running away.
  static const int maxQuantity = 10;

  final CatalogRepository _repository;

  Future<void> _onRequested(
    ProductDetailRequested event,
    Emitter<ProductDetailState> emit,
  ) => _load(event.productId, emit);

  Future<void> _onRefreshed(
    ProductDetailRefreshed event,
    Emitter<ProductDetailState> emit,
  ) => _load(event.productId, emit);

  void _onColourSelected(
    ProductDetailColourSelected event,
    Emitter<ProductDetailState> emit,
  ) {
    final current = state;
    if (current is! ProductDetailLoaded) return;
    emit(current.copyWith(selectedColourId: event.colourId));
  }

  void _onSizeSelected(
    ProductDetailSizeSelected event,
    Emitter<ProductDetailState> emit,
  ) {
    final current = state;
    if (current is! ProductDetailLoaded) return;
    emit(current.copyWith(selectedSize: event.size));
  }

  void _onQuantityChanged(
    ProductDetailQuantityChanged event,
    Emitter<ProductDetailState> emit,
  ) {
    final current = state;
    if (current is! ProductDetailLoaded) return;
    // Clamped in the bloc, not by disabling buttons alone: the rule about how
    // many a shopper may take belongs with the state, and the buttons then just
    // reflect it.
    final clamped = event.quantity.clamp(1, maxQuantity);
    emit(current.copyWith(quantity: clamped));
  }

  Future<void> _load(String productId, Emitter<ProductDetailState> emit) async {
    emit(const ProductDetailLoading());

    // No try/catch: the repository returns a Result and this folds it. A catch
    // here would mean the data layer is leaking (06-flutter-error-guard.md §4).
    final result = await _repository.productById(productId);

    emit(
      result.fold(
        ProductDetailError.new,
        (product) => ProductDetailLoaded(
          product: product,
          // Preselect, as the design shows: a shopper should not have to pick a
          // colour before the screen looks complete.
          selectedColourId: product.colours.isEmpty
              ? null
              : product.colours.first.id,
          selectedSize: product.sizes.isEmpty ? null : product.sizes.first,
        ),
      ),
    );
  }
}
