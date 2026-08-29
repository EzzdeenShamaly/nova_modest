import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nova_modest/core/error/failure.dart';
import 'package:nova_modest/core/error/result.dart';
import 'package:nova_modest/features/catalog/domain/entities/product.dart';
import 'package:nova_modest/features/catalog/domain/entities/product_category.dart';
import 'package:nova_modest/features/catalog/domain/repositories/catalog_repository.dart';
import 'package:nova_modest/features/catalog/presentation/bloc/home_bloc.dart';

class _MockCatalogRepository extends Mock implements CatalogRepository {}

/// The app's first list-shaped feature, so the first place the four-state
/// contract from `06-flutter-error-guard.md` §5 can be demonstrated end to end:
/// loading, error, empty and data all reachable and all asserted.
void main() {
  late _MockCatalogRepository repository;

  const categories = [
    ProductCategory(id: 'abayas', name: 'عبايات'),
    ProductCategory(id: 'sets', name: 'أطقم'),
  ];
  const abaya = Product(
    id: 'p1',
    name: 'عباءة كلاسيكية',
    price: 450,
    categoryId: 'abayas',
  );
  const set = Product(
    id: 'p2',
    name: 'طقم مريح',
    price: 380,
    categoryId: 'sets',
  );

  setUp(() => repository = _MockCatalogRepository());

  void givenCatalogue({
    List<ProductCategory> cats = categories,
    List<Product> products = const [abaya, set],
  }) {
    when(() => repository.categories()).thenAnswer((_) async => Ok(cats));
    when(
      () => repository.featuredProducts(),
    ).thenAnswer((_) async => Ok(products));
  }

  group('the four states', () {
    blocTest<HomeBloc, HomeState>(
      'loading then data',
      setUp: givenCatalogue,
      build: () => HomeBloc(repository),
      act: (bloc) => bloc.add(const HomeRequested()),
      expect: () => const [
        HomeLoading(),
        HomeLoaded(categories: categories, products: [abaya, set]),
      ],
    );

    blocTest<HomeBloc, HomeState>(
      'loading then empty when the catalogue has no products',
      setUp: () => givenCatalogue(products: const []),
      build: () => HomeBloc(repository),
      act: (bloc) => bloc.add(const HomeRequested()),
      // Empty is its own state, not Loaded([]): "no products yet" is a different
      // screen than a grid with no rows.
      expect: () => const [HomeLoading(), HomeEmpty()],
    );

    blocTest<HomeBloc, HomeState>(
      'loading then error when the products call fails',
      setUp: () {
        when(
          () => repository.categories(),
        ).thenAnswer((_) async => const Ok(categories));
        when(
          () => repository.featuredProducts(),
        ).thenAnswer((_) async => const Err(NetworkFailure()));
      },
      build: () => HomeBloc(repository),
      act: (bloc) => bloc.add(const HomeRequested()),
      expect: () => const [HomeLoading(), HomeError(NetworkFailure())],
    );

    blocTest<HomeBloc, HomeState>(
      'a failure in either call is enough to fail the screen',
      setUp: () {
        when(
          () => repository.categories(),
        ).thenAnswer((_) async => const Err(ServerFailure('down')));
        when(
          () => repository.featuredProducts(),
        ).thenAnswer((_) async => const Ok([abaya]));
      },
      build: () => HomeBloc(repository),
      act: (bloc) => bloc.add(const HomeRequested()),
      expect: () => const [HomeLoading(), HomeError(ServerFailure('down'))],
    );
  });

  group('category filter', () {
    blocTest<HomeBloc, HomeState>(
      'narrows the visible products without another round trip',
      setUp: givenCatalogue,
      build: () => HomeBloc(repository),
      act: (bloc) async {
        bloc.add(const HomeRequested());
        await Future<void>.delayed(Duration.zero);
        bloc.add(const HomeCategorySelected('abayas'));
      },
      skip: 2,
      expect: () => const [
        HomeLoaded(
          categories: categories,
          products: [abaya, set],
          selectedCategoryId: 'abayas',
        ),
      ],
      verify: (bloc) {
        final state = bloc.state as HomeLoaded;
        expect(state.visibleProducts, const [abaya]);
        // The full catalogue is retained, so clearing the filter is free.
        expect(state.products, const [abaya, set]);
        // Filtering must not hit the repository again.
        verify(() => repository.featuredProducts()).called(1);
      },
    );

    blocTest<HomeBloc, HomeState>(
      'the All chip clears the filter',
      setUp: givenCatalogue,
      build: () => HomeBloc(repository),
      act: (bloc) async {
        bloc.add(const HomeRequested());
        await Future<void>.delayed(Duration.zero);
        bloc
          ..add(const HomeCategorySelected('abayas'))
          ..add(const HomeCategorySelected(null));
      },
      skip: 3,
      verify: (bloc) {
        final state = bloc.state as HomeLoaded;
        expect(state.selectedCategoryId, isNull);
        expect(state.visibleProducts, const [abaya, set]);
      },
    );

    test('a filter matching nothing stays inside Loaded', () {
      // Not HomeEmpty: the chips have to remain on screen or the user is
      // stranded with no way to choose a different category.
      const state = HomeLoaded(
        categories: categories,
        products: [abaya],
        selectedCategoryId: 'sets',
      );

      expect(state.visibleProducts, isEmpty);
      expect(state.isFilteredEmpty, isTrue);
    });

    test('an empty catalogue is not a filtered-empty', () {
      const state = HomeLoaded(categories: categories, products: []);

      expect(state.isFilteredEmpty, isFalse);
    });

    blocTest<HomeBloc, HomeState>(
      'a filter arriving before the catalogue is ignored',
      setUp: givenCatalogue,
      build: () => HomeBloc(repository),
      act: (bloc) => bloc.add(const HomeCategorySelected('abayas')),
      expect: () => const <HomeState>[],
    );
  });

  group('refresh', () {
    blocTest<HomeBloc, HomeState>(
      'reloads from the repository',
      setUp: givenCatalogue,
      build: () => HomeBloc(repository),
      act: (bloc) => bloc.add(const HomeRefreshed()),
      expect: () => const [
        HomeLoading(),
        HomeLoaded(categories: categories, products: [abaya, set]),
      ],
    );
  });

  group('state equality', () {
    test('Loaded compares by catalogue and selection', () {
      const a = HomeLoaded(categories: categories, products: [abaya]);
      const b = HomeLoaded(categories: categories, products: [abaya]);
      const c = HomeLoaded(
        categories: categories,
        products: [abaya],
        selectedCategoryId: 'abayas',
      );

      expect(a, b);
      // Without selectedCategoryId in props, tapping a chip would emit a state
      // equal to the previous one and the grid would never update.
      expect(a, isNot(c));
    });
  });
}
