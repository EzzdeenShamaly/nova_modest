import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:nova_modest/core/error/failure.dart';
import 'package:nova_modest/core/error/result.dart';
import 'package:nova_modest/features/catalog/domain/entities/product.dart';
import 'package:nova_modest/features/catalog/domain/entities/product_category.dart';
import 'package:nova_modest/features/catalog/domain/entities/product_filter.dart';
import 'package:nova_modest/features/catalog/domain/entities/product_filter_options.dart';
import 'package:nova_modest/features/catalog/domain/entities/product_tag.dart';
import 'package:nova_modest/features/catalog/domain/repositories/catalog_repository.dart';

part 'product_list_event.dart';
part 'product_list_state.dart';

/// Owns one category's products.
///
/// A **factory**, scoped to the listing screen: two categories opened in
/// sequence must not share a filter, and nothing outside the screen reads it.
///
/// Reads the same [CatalogRepository] Home does — there is one catalogue, and
/// this screen queries it differently rather than carrying data of its own.
@injectable
class ProductListBloc extends Bloc<ProductListEvent, ProductListState> {
  ProductListBloc(this._repository) : super(const ProductListInitial()) {
    on<ProductListRequested>(_onRequested, transformer: droppable());
    on<ProductListRefreshed>(_onRefreshed, transformer: droppable());
    // restartable: only the newest tag matters — an older selection resolving
    // late would overwrite what the user actually chose.
    on<ProductListTagSelected>(_onTagSelected, transformer: restartable());
    on<ProductListFilterChanged>(_onFilterChanged, transformer: restartable());
  }

  final CatalogRepository _repository;

  Future<void> _onRequested(
    ProductListRequested event,
    Emitter<ProductListState> emit,
  ) => _load(event.categoryId, emit);

  Future<void> _onRefreshed(
    ProductListRefreshed event,
    Emitter<ProductListState> emit,
  ) => _load(event.categoryId, emit);

  /// Local, like Home's category filter: the products are already in hand, so a
  /// round trip would add latency and a failure mode for nothing.
  void _onTagSelected(
    ProductListTagSelected event,
    Emitter<ProductListState> emit,
  ) {
    final current = state;
    if (current is! ProductListLoaded) return;
    // copyWith, so choosing a tag keeps whatever the sheet set. freezed's
    // copyWith distinguishes "omitted" from "explicitly null", which is what
    // lets the "All" chip clear the tag without clearing the rest.
    _emitFiltered(current, current.filter.copyWith(tagId: event.tagId), emit);
  }

  void _onFilterChanged(
    ProductListFilterChanged event,
    Emitter<ProductListState> emit,
  ) {
    final current = state;
    if (current is! ProductListLoaded) return;
    _emitFiltered(current, event.filter, emit);
  }

  void _emitFiltered(
    ProductListLoaded current,
    ProductFilter filter,
    Emitter<ProductListState> emit,
  ) => emit(
    ProductListLoaded(
      categoryId: current.categoryId,
      categoryName: current.categoryName,
      products: current.products,
      filter: filter,
    ),
  );

  Future<void> _load(String categoryId, Emitter<ProductListState> emit) async {
    emit(const ProductListLoading());

    // Both together: the products and the name of the category they belong to.
    // Sequential calls would make the screen wait twice for no reason, and the
    // title has to come from the catalogue rather than from the raw id in the
    // URL.
    final results = await Future.wait([
      _repository.productsInCategory(categoryId),
      _repository.categories(),
    ]);

    final productsResult = results[0] as Result<List<Product>>;
    final categoriesResult = results[1] as Result<List<ProductCategory>>;

    // No try/catch: the repository returns Results and this folds them. A catch
    // here would mean the data layer is leaking (06-flutter-error-guard.md §4).
    if (productsResult case Err(:final failure)) {
      emit(ProductListError(failure));
      return;
    }

    // A failure naming the category is not worth failing the screen over — the
    // products are what the user came for, and the title falls back to the id.
    final name = categoriesResult.fold(
      (_) => null,
      (categories) => categories
          .where((category) => category.id == categoryId)
          .map((category) => category.name)
          .firstOrNull,
    );

    final products = (productsResult as Ok<List<Product>>).value;

    // Empty is its own state, not Loaded([]): a category with nothing in it is a
    // different screen than a grid with no rows.
    if (products.isEmpty) {
      emit(ProductListEmpty(categoryName: name));
      return;
    }

    emit(
      ProductListLoaded(
        categoryId: categoryId,
        categoryName: name,
        products: products,
      ),
    );
  }
}
