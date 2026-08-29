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
import 'package:nova_modest/features/catalog/domain/entities/product_sort.dart';
import 'package:nova_modest/features/catalog/domain/repositories/catalog_repository.dart';
import 'package:nova_modest/features/catalog/domain/repositories/search_history_repository.dart';

part 'search_event.dart';
part 'search_state.dart';

/// Owns the search screen — both of its faces.
///
/// A **factory**, scoped to the screen: a query, a filter and a sort are one
/// visit's business, and nothing outside the screen reads them.
///
/// Reads the same [CatalogRepository] every other catalogue screen does. The
/// history is a second repository because it is a different concern: what this
/// device has looked for is local and personal, the catalogue is shared and
/// remote.
@injectable
class SearchBloc extends Bloc<SearchEvent, SearchState> {
  SearchBloc(this._catalog, this._history) : super(const SearchInitial()) {
    on<SearchOpened>(_onOpened, transformer: droppable());
    // restartable, and this is what makes the debounce below work: a new
    // keystroke cancels the handler still waiting out the pause.
    on<SearchQueryChanged>(_onQueryChanged, transformer: restartable());
    on<SearchSubmitted>(_onSubmitted, transformer: restartable());
    on<SearchCleared>(_onCleared, transformer: restartable());
    on<SearchFilterChanged>(_onFilterChanged, transformer: restartable());
    on<SearchSortChanged>(_onSortChanged, transformer: restartable());
    // sequential: both are read-modify-write against one stored list.
    on<SearchHistoryEntryRemoved>(_onHistoryRemoved, transformer: sequential());
    on<SearchHistoryCleared>(_onHistoryCleared, transformer: sequential());
  }

  /// How long typing must pause before a query runs.
  ///
  /// A debounce with no extra package: [restartable] cancels the pending
  /// handler on the next keystroke, so this delay only ever elapses once the
  /// shopper stops. `02-flutter-state-guard` names debounced-restartable as the
  /// standard shape for a search field, and `bloc_concurrency` ships no
  /// debounce transformer to reach for.
  static const Duration debounce = Duration(milliseconds: 300);

  final CatalogRepository _catalog;
  final SearchHistoryRepository _history;

  /// The discovery screen as it was last loaded.
  ///
  /// Held so that clearing the field returns to it instantly instead of
  /// flashing a spinner over content that has not changed. It is a previously
  /// emitted state, not state of its own — every field on it came from
  /// [_onOpened].
  SearchIdle _idle = const SearchIdle();

  Future<void> _onOpened(SearchOpened event, Emitter<SearchState> emit) async {
    emit(const SearchLoading());

    // All three together: they are independent, and running them in sequence
    // would make the screen wait three times for no reason.
    final results = await Future.wait([
      _history.recent(),
      _catalog.trendingSearches(),
      _catalog.categories(),
    ]);

    final historyResult = results[0] as Result<List<String>>;
    final trendingResult = results[1] as Result<List<String>>;
    final categoriesResult = results[2] as Result<List<ProductCategory>>;

    // No try/catch: the repositories return Results and this folds them. A
    // catch here would mean the data layer is leaking
    // (`06-flutter-error-guard.md` §4).
    //
    // None of the three is worth failing the screen over on its own — a
    // shopper came here to type, and an unreadable history should not stop
    // them. Each section simply does not draw.
    _idle = SearchIdle(
      history: historyResult.fold((_) => const <String>[], (terms) => terms),
      trending: trendingResult.fold((_) => const <String>[], (terms) => terms),
      categories: categoriesResult.fold(
        (_) => const <ProductCategory>[],
        (categories) => categories,
      ),
    );
    emit(_idle);
  }

  Future<void> _onQueryChanged(
    SearchQueryChanged event,
    Emitter<SearchState> emit,
  ) async {
    if (event.query.trim().isEmpty) {
      emit(_idle);
      return;
    }

    await Future<void>.delayed(debounce);
    // The pause was interrupted by another keystroke, so this handler was
    // cancelled and its emitter closed. Without the guard the cancelled run
    // would throw on the emit below.
    if (emit.isDone) return;

    await _run(event.query, emit);
  }

  Future<void> _onSubmitted(
    SearchSubmitted event,
    Emitter<SearchState> emit,
  ) async {
    final trimmed = event.query.trim();
    if (trimmed.isEmpty) {
      emit(_idle);
      return;
    }

    // Recorded here and not on every keystroke: history should hold what was
    // actually searched for, not every prefix of it.
    final recorded = await _history.record(trimmed);
    _idle = _idle.copyWith(
      history: recorded.fold((_) => _idle.history, (terms) => terms),
    );

    if (emit.isDone) return;
    await _run(trimmed, emit);
  }

  void _onCleared(SearchCleared event, Emitter<SearchState> emit) =>
      emit(_idle);

  void _onFilterChanged(SearchFilterChanged event, Emitter<SearchState> emit) {
    final current = state;
    if (current is! SearchResults) return;
    emit(current.copyWith(filter: event.filter));
  }

  void _onSortChanged(SearchSortChanged event, Emitter<SearchState> emit) {
    final current = state;
    if (current is! SearchResults) return;
    emit(current.copyWith(sort: event.sort));
  }

  Future<void> _onHistoryRemoved(
    SearchHistoryEntryRemoved event,
    Emitter<SearchState> emit,
  ) async => _updateHistory(await _history.remove(event.term), emit);

  Future<void> _onHistoryCleared(
    SearchHistoryCleared event,
    Emitter<SearchState> emit,
  ) async => _updateHistory(await _history.clear(), emit);

  /// Applies a history change and re-shows the discovery screen if that is
  /// where the shopper is. Editing history from a results screen is not
  /// possible, but a failed write must not be silent either way.
  void _updateHistory(Result<List<String>> result, Emitter<SearchState> emit) {
    if (result case Err(:final failure)) {
      emit(SearchError(failure));
      return;
    }

    _idle = _idle.copyWith(history: (result as Ok<List<String>>).value);
    if (state is SearchIdle) emit(_idle);
  }

  Future<void> _run(String query, Emitter<SearchState> emit) async {
    emit(const SearchLoading());

    final result = await _catalog.searchProducts(query);
    if (emit.isDone) return;

    emit(
      result.fold(SearchError.new, (products) {
        // Empty is its own state, not Results([]): "nothing matched" is a
        // different screen from a grid that happens to have no rows.
        if (products.isEmpty) return SearchEmpty(query);
        return SearchResults(
          query: query,
          products: products,
          categories: _idle.categories,
        );
      }),
    );
  }
}
