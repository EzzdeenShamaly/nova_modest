import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:nova_modest/core/error/failure.dart';
import 'package:nova_modest/core/error/result.dart';
import 'package:nova_modest/features/catalog/domain/entities/product.dart';
import 'package:nova_modest/features/catalog/domain/entities/product_category.dart';
import 'package:nova_modest/features/catalog/domain/repositories/catalog_repository.dart';

part 'home_event.dart';
part 'home_state.dart';

/// Owns the Home screen's catalogue.
///
/// A **factory**, scoped to the screen: unlike `AuthBloc` nothing outside Home
/// reads it, and a singleton would show the previous visitor's filter on
/// re-entry.
@injectable
class HomeBloc extends Bloc<HomeEvent, HomeState> {
  HomeBloc(this._repository) : super(const HomeInitial()) {
    // droppable: the screen only ever needs one load in flight, and a duplicate
    // request is waste.
    on<HomeRequested>(_onRequested, transformer: droppable());
    on<HomeRefreshed>(_onRefreshed, transformer: droppable());
    // restartable: only the newest filter matters — an older one resolving late
    // would overwrite the user's actual choice.
    on<HomeCategorySelected>(_onCategorySelected, transformer: restartable());
  }

  final CatalogRepository _repository;

  Future<void> _onRequested(HomeRequested event, Emitter<HomeState> emit) =>
      _load(emit);

  Future<void> _onRefreshed(HomeRefreshed event, Emitter<HomeState> emit) =>
      _load(emit);

  /// Filtering is local: the catalogue is already in hand, so a round trip would
  /// add latency and a failure mode for nothing.
  void _onCategorySelected(
    HomeCategorySelected event,
    Emitter<HomeState> emit,
  ) {
    final current = state;
    if (current is! HomeLoaded) return;
    emit(
      HomeLoaded(
        categories: current.categories,
        products: current.products,
        selectedCategoryId: event.categoryId,
      ),
    );
  }

  Future<void> _load(Emitter<HomeState> emit) async {
    emit(const HomeLoading());

    // Both together: they are independent, and running them in sequence would
    // make the screen wait twice for no reason.
    final results = await Future.wait([
      _repository.categories(),
      _repository.featuredProducts(),
    ]);

    final categoriesResult = results[0] as Result<List<ProductCategory>>;
    final productsResult = results[1] as Result<List<Product>>;

    // No try/catch: the repository returns Results and this folds them. A catch
    // here would mean the data layer is leaking (06-flutter-error-guard.md §4).
    final failure =
        categoriesResult.fold((f) => f, (_) => null) ??
        productsResult.fold((f) => f, (_) => null);
    if (failure != null) {
      emit(HomeError(failure));
      return;
    }

    final categories = (categoriesResult as Ok<List<ProductCategory>>).value;
    final products = (productsResult as Ok<List<Product>>).value;

    // Empty is its own state, not Loaded([]) — "no products yet" is a different
    // screen than a grid that happens to have no rows.
    if (products.isEmpty) {
      emit(const HomeEmpty());
      return;
    }

    emit(HomeLoaded(categories: categories, products: products));
  }
}
