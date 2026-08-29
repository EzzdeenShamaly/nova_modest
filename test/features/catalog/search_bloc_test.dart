import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nova_modest/core/error/failure.dart';
import 'package:nova_modest/core/error/result.dart';
import 'package:nova_modest/features/catalog/domain/entities/product.dart';
import 'package:nova_modest/features/catalog/domain/entities/product_category.dart';
import 'package:nova_modest/features/catalog/domain/entities/product_filter.dart';
import 'package:nova_modest/features/catalog/domain/entities/product_sort.dart';
import 'package:nova_modest/features/catalog/domain/entities/product_tag.dart';
import 'package:nova_modest/features/catalog/domain/repositories/catalog_repository.dart';
import 'package:nova_modest/features/catalog/domain/repositories/search_history_repository.dart';
import 'package:nova_modest/features/catalog/presentation/bloc/search_bloc.dart';

class _MockCatalog extends Mock implements CatalogRepository {}

class _MockHistory extends Mock implements SearchHistoryRepository {}

void main() {
  late _MockCatalog catalog;
  late _MockHistory history;

  const daily = ProductTag(id: 'daily', name: 'يومي');

  const abaya = Product(
    id: 'p1',
    name: 'عباية كتان يومية',
    price: 450,
    categoryId: 'abayas',
    tags: [daily],
    sizes: ['S', 'M'],
  );
  const gown = Product(
    id: 'p2',
    name: 'عباية رسمية كحلية',
    price: 950,
    categoryId: 'abayas',
    sizes: ['L'],
  );

  const categories = [
    ProductCategory(id: 'abayas', name: 'عبايات'),
    ProductCategory(id: 'sets', name: 'أطقم'),
  ];

  const trending = ['عبايات', 'مناسبات'];
  const recent = ['وشاح'];

  /// Long enough for the debounce to elapse inside a `blocTest`.
  final settled = SearchBloc.debounce + const Duration(milliseconds: 100);

  SearchBloc build() => SearchBloc(catalog, history);

  void givenDiscovery({
    Result<List<String>> historyResult = const Ok(recent),
    Result<List<String>> trendingResult = const Ok(trending),
    Result<List<ProductCategory>> categoriesResult = const Ok(categories),
  }) {
    when(() => history.recent()).thenAnswer((_) async => historyResult);
    when(
      () => catalog.trendingSearches(),
    ).thenAnswer((_) async => trendingResult);
    when(() => catalog.categories()).thenAnswer((_) async => categoriesResult);
  }

  void givenSearch(Result<List<Product>> result) =>
      when(() => catalog.searchProducts(any())).thenAnswer((_) async => result);

  setUp(() {
    catalog = _MockCatalog();
    history = _MockHistory();
    givenDiscovery();
    givenSearch(const Ok([abaya, gown]));
    when(() => history.record(any())).thenAnswer((_) async => const Ok(recent));
    when(() => history.remove(any())).thenAnswer((_) async => const Ok([]));
    when(() => history.clear()).thenAnswer((_) async => const Ok([]));
  });

  group('opening', () {
    blocTest<SearchBloc, SearchState>(
      'shows discovery content, not an empty result',
      build: build,
      act: (bloc) => bloc.add(const SearchOpened()),
      // Idle is its own state: nothing has been asked yet, which is a
      // different screen from a query that matched nothing.
      expect: () => const [
        SearchLoading(),
        SearchIdle(history: recent, trending: trending, categories: categories),
      ],
    );

    blocTest<SearchBloc, SearchState>(
      'an unreadable history costs that section, not the screen',
      setUp: () => givenDiscovery(historyResult: const Err(CacheFailure())),
      build: build,
      act: (bloc) => bloc.add(const SearchOpened()),
      // A shopper came here to type. Failing the whole screen over a local
      // shortlist would stop them doing the thing they came for.
      expect: () => const [
        SearchLoading(),
        SearchIdle(trending: trending, categories: categories),
      ],
    );
  });

  group('typing', () {
    blocTest<SearchBloc, SearchState>(
      'a fast typist produces one search, not one per keystroke',
      build: build,
      act: (bloc) => bloc
        ..add(const SearchQueryChanged('ع'))
        ..add(const SearchQueryChanged('عب'))
        ..add(const SearchQueryChanged('عباية')),
      wait: settled,
      verify: (_) {
        verify(() => catalog.searchProducts('عباية')).called(1);
        verifyNever(() => catalog.searchProducts('ع'));
        verifyNever(() => catalog.searchProducts('عب'));
      },
    );

    blocTest<SearchBloc, SearchState>(
      'typing does not fill the history with prefixes',
      build: build,
      act: (bloc) => bloc.add(const SearchQueryChanged('عباية')),
      wait: settled,
      verify: (_) => verifyNever(() => history.record(any())),
    );

    blocTest<SearchBloc, SearchState>(
      'emptying the field returns to discovery without a spinner',
      build: build,
      act: (bloc) async {
        bloc.add(const SearchOpened());
        await Future<void>.delayed(Duration.zero);
        bloc.add(const SearchSubmitted('عباية'));
        await Future<void>.delayed(settled);
        bloc.add(const SearchQueryChanged('   '));
      },
      wait: settled,
      // Skips [Loading, Idle] from opening and [Loading, Results] from the
      // search. Exactly one state follows, and it is the discovery screen with
      // its content intact — no Loading, because nothing has to be fetched
      // again.
      skip: 4,
      expect: () => const [
        SearchIdle(history: recent, trending: trending, categories: categories),
      ],
    );
  });

  group('submitting', () {
    blocTest<SearchBloc, SearchState>(
      'records what was actually searched for and runs at once',
      build: build,
      act: (bloc) => bloc.add(const SearchSubmitted('  عباية  ')),
      wait: settled,
      verify: (_) {
        // Trimmed, and recorded exactly once.
        verify(() => history.record('عباية')).called(1);
        verify(() => catalog.searchProducts('عباية')).called(1);
      },
    );

    blocTest<SearchBloc, SearchState>(
      'results carry the query and the categories the sheet needs',
      build: build,
      act: (bloc) async {
        bloc.add(const SearchOpened());
        await Future<void>.delayed(Duration.zero);
        bloc.add(const SearchSubmitted('عباية'));
      },
      wait: settled,
      verify: (bloc) {
        final state = bloc.state as SearchResults;
        expect(state.query, 'عباية');
        expect(state.products, [abaya, gown]);
        // Products know only a categoryId; the sheet has to name it.
        expect(state.categories, categories);
        expect(state.visibleProducts, [abaya, gown]);
      },
    );

    blocTest<SearchBloc, SearchState>(
      'a query matching nothing is empty, not an error',
      setUp: () => givenSearch(const Ok(<Product>[])),
      build: build,
      act: (bloc) => bloc.add(const SearchSubmitted('حذاء')),
      wait: settled,
      expect: () => const [SearchLoading(), SearchEmpty('حذاء')],
    );

    blocTest<SearchBloc, SearchState>(
      'a failed search is an error state',
      setUp: () => givenSearch(const Err(NetworkFailure())),
      build: build,
      act: (bloc) => bloc.add(const SearchSubmitted('عباية')),
      wait: settled,
      expect: () => const [SearchLoading(), SearchError(NetworkFailure())],
    );

    blocTest<SearchBloc, SearchState>(
      'an empty submission goes back to discovery instead of searching',
      build: build,
      act: (bloc) => bloc.add(const SearchSubmitted('   ')),
      expect: () => const [SearchIdle()],
      verify: (_) => verifyNever(() => catalog.searchProducts(any())),
    );
  });

  group('narrowing the results', () {
    blocTest<SearchBloc, SearchState>(
      'a filter applies locally, without searching again',
      build: build,
      act: (bloc) async {
        bloc.add(const SearchSubmitted('عباية'));
        await Future<void>.delayed(Duration.zero);
        bloc.add(const SearchFilterChanged(ProductFilter(sizes: {'L'})));
      },
      wait: settled,
      verify: (bloc) {
        final state = bloc.state as SearchResults;
        expect(state.visibleProducts, [gown]);
        // The products are already in hand; a round trip would add latency and
        // a failure mode for nothing.
        verify(() => catalog.searchProducts('عباية')).called(1);
      },
    );

    blocTest<SearchBloc, SearchState>(
      'a filter matching nothing stays inside Results',
      build: build,
      act: (bloc) async {
        bloc.add(const SearchSubmitted('عباية'));
        await Future<void>.delayed(Duration.zero);
        bloc.add(const SearchFilterChanged(ProductFilter(sizes: {'XXL'})));
      },
      wait: settled,
      verify: (bloc) {
        final state = bloc.state as SearchResults;
        // Not SearchEmpty: the filter controls have to stay reachable or the
        // shopper has no way to widen it again.
        expect(state.isFilteredEmpty, isTrue);
        expect(state.visibleProducts, isEmpty);
      },
    );

    blocTest<SearchBloc, SearchState>(
      'sorting reorders without losing the original order',
      build: build,
      act: (bloc) async {
        bloc.add(const SearchSubmitted('عباية'));
        await Future<void>.delayed(Duration.zero);
        bloc.add(const SearchSortChanged(ProductSort.priceDescending));
      },
      wait: settled,
      verify: (bloc) {
        final state = bloc.state as SearchResults;
        expect(state.visibleProducts, [gown, abaya]);
        // The catalogue's own order survives, so relevance is recoverable.
        expect(state.products, [abaya, gown]);
      },
    );

    blocTest<SearchBloc, SearchState>(
      'a filter arriving before any results is ignored',
      build: build,
      act: (bloc) => bloc.add(const SearchFilterChanged(ProductFilter())),
      expect: () => const <SearchState>[],
    );
  });

  group('history', () {
    blocTest<SearchBloc, SearchState>(
      'removing one term re-shows discovery without it',
      setUp: () => when(
        () => history.remove(any()),
      ).thenAnswer((_) async => const Ok(<String>[])),
      build: build,
      act: (bloc) async {
        bloc.add(const SearchOpened());
        await Future<void>.delayed(Duration.zero);
        bloc.add(const SearchHistoryEntryRemoved('وشاح'));
      },
      skip: 2,
      expect: () => const [
        SearchIdle(trending: trending, categories: categories),
      ],
    );

    blocTest<SearchBloc, SearchState>(
      'a failed write surfaces instead of silently doing nothing',
      setUp: () => when(
        () => history.clear(),
      ).thenAnswer((_) async => const Err(CacheFailure())),
      build: build,
      act: (bloc) async {
        bloc.add(const SearchOpened());
        await Future<void>.delayed(Duration.zero);
        bloc.add(const SearchHistoryCleared());
      },
      skip: 2,
      expect: () => const [SearchError(CacheFailure())],
    );
  });

  group('state', () {
    test('only a committed state carries a query', () {
      expect(const SearchIdle().query, isEmpty);
      expect(const SearchLoading().query, isEmpty);
      expect(const SearchEmpty('عباية').query, 'عباية');
    });

    test('Results compares by query, products, filter and sort', () {
      const a = SearchResults(query: 'عباية', products: [abaya]);
      const same = SearchResults(query: 'عباية', products: [abaya]);
      const filtered = SearchResults(
        query: 'عباية',
        products: [abaya],
        filter: ProductFilter(sizes: {'M'}),
      );
      const sorted = SearchResults(
        query: 'عباية',
        products: [abaya],
        sort: ProductSort.priceAscending,
      );

      expect(a, same);
      // Without these in props, changing a filter or a sort would emit a state
      // equal to the previous one and the grid would never update.
      expect(a, isNot(filtered));
      expect(a, isNot(sorted));
    });
  });
}
