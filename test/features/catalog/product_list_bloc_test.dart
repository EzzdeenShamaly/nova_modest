import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nova_modest/core/error/failure.dart';
import 'package:nova_modest/core/error/result.dart';
import 'package:nova_modest/features/catalog/domain/entities/product.dart';
import 'package:nova_modest/features/catalog/domain/entities/product_filter.dart';
import 'package:nova_modest/features/catalog/domain/entities/product_category.dart';
import 'package:nova_modest/features/catalog/domain/entities/product_tag.dart';
import 'package:nova_modest/features/catalog/domain/repositories/catalog_repository.dart';
import 'package:nova_modest/features/catalog/presentation/bloc/product_list_bloc.dart';

class _MockCatalogRepository extends Mock implements CatalogRepository {}

void main() {
  late _MockCatalogRepository repository;

  const daily = ProductTag(id: 'daily', name: 'يومي');
  const occasions = ProductTag(id: 'occasions', name: 'مناسبات');
  const categories = [ProductCategory(id: 'abayas', name: 'عبايات')];

  const everyday = Product(
    id: 'p1',
    name: 'عباية كتان يومية',
    price: 620,
    categoryId: 'abayas',
    isSoldOut: true,
    tags: [daily],
  );
  const formal = Product(
    id: 'p2',
    name: 'عباية رسمية كحلية',
    price: 950,
    categoryId: 'abayas',
    tags: [occasions],
  );

  setUp(() => repository = _MockCatalogRepository());

  void givenCategory({List<Product> products = const [everyday, formal]}) {
    when(
      () => repository.productsInCategory(any()),
    ).thenAnswer((_) async => Ok(products));
    when(
      () => repository.categories(),
    ).thenAnswer((_) async => const Ok(categories));
  }

  group('the four states', () {
    blocTest<ProductListBloc, ProductListState>(
      'loading then data, titled from the catalogue',
      setUp: givenCategory,
      build: () => ProductListBloc(repository),
      act: (bloc) => bloc.add(const ProductListRequested('abayas')),
      expect: () => const [
        ProductListLoading(),
        ProductListLoaded(
          categoryId: 'abayas',
          categoryName: 'عبايات',
          products: [everyday, formal],
        ),
      ],
    );

    blocTest<ProductListBloc, ProductListState>(
      'loading then empty when the category holds nothing',
      setUp: () => givenCategory(products: const []),
      build: () => ProductListBloc(repository),
      act: (bloc) => bloc.add(const ProductListRequested('abayas')),
      expect: () => const [
        ProductListLoading(),
        ProductListEmpty(categoryName: 'عبايات'),
      ],
    );

    blocTest<ProductListBloc, ProductListState>(
      'loading then error when the products call fails',
      setUp: () {
        when(
          () => repository.productsInCategory(any()),
        ).thenAnswer((_) async => const Err(NetworkFailure()));
        when(
          () => repository.categories(),
        ).thenAnswer((_) async => const Ok(categories));
      },
      build: () => ProductListBloc(repository),
      act: (bloc) => bloc.add(const ProductListRequested('abayas')),
      expect: () => const [
        ProductListLoading(),
        ProductListError(NetworkFailure()),
      ],
    );

    blocTest<ProductListBloc, ProductListState>(
      'a failure naming the category does not fail the screen',
      setUp: () {
        when(
          () => repository.productsInCategory(any()),
        ).thenAnswer((_) async => const Ok([formal]));
        when(
          () => repository.categories(),
        ).thenAnswer((_) async => const Err(NetworkFailure()));
      },
      build: () => ProductListBloc(repository),
      act: (bloc) => bloc.add(const ProductListRequested('abayas')),
      // The products are what the user came for; the title falls back to the id
      // rather than throwing the whole screen away over a heading.
      expect: () => const [
        ProductListLoading(),
        ProductListLoaded(categoryId: 'abayas', products: [formal]),
      ],
    );
  });

  group('tag filter', () {
    blocTest<ProductListBloc, ProductListState>(
      'narrows the grid without another round trip',
      setUp: givenCategory,
      build: () => ProductListBloc(repository),
      act: (bloc) async {
        bloc.add(const ProductListRequested('abayas'));
        await Future<void>.delayed(Duration.zero);
        bloc.add(const ProductListTagSelected('daily'));
      },
      skip: 2,
      verify: (bloc) {
        final state = bloc.state as ProductListLoaded;
        expect(state.visibleProducts, const [everyday]);
        expect(state.products, const [everyday, formal]);
        verify(() => repository.productsInCategory('abayas')).called(1);
      },
    );

    blocTest<ProductListBloc, ProductListState>(
      'the All chip clears the filter',
      setUp: givenCategory,
      build: () => ProductListBloc(repository),
      act: (bloc) async {
        bloc.add(const ProductListRequested('abayas'));
        await Future<void>.delayed(Duration.zero);
        bloc
          ..add(const ProductListTagSelected('daily'))
          ..add(const ProductListTagSelected(null));
      },
      skip: 3,
      verify: (bloc) {
        final state = bloc.state as ProductListLoaded;
        expect(state.selectedTagId, isNull);
        expect(state.visibleProducts, const [everyday, formal]);
      },
    );

    test('available tags are de-duplicated and keep first-seen order', () {
      const state = ProductListLoaded(
        categoryId: 'abayas',
        products: [everyday, formal, everyday],
      );

      expect(state.availableTags.map((t) => t.id), ['daily', 'occasions']);
    });

    test('a tag matching nothing stays inside Loaded', () {
      // Not ProductListEmpty: the chips must stay reachable or the user has no
      // way back to a different filter.
      const state = ProductListLoaded(
        categoryId: 'abayas',
        products: [formal],
        filter: ProductFilter(tagId: 'daily'),
      );

      expect(state.visibleProducts, isEmpty);
      expect(state.isFilteredEmpty, isTrue);
    });

    blocTest<ProductListBloc, ProductListState>(
      'a tag arriving before the products is ignored',
      setUp: givenCategory,
      build: () => ProductListBloc(repository),
      act: (bloc) => bloc.add(const ProductListTagSelected('daily')),
      expect: () => const <ProductListState>[],
    );
  });

  group('state equality', () {
    test('Loaded compares by category, products and selection', () {
      const a = ProductListLoaded(categoryId: 'abayas', products: [formal]);
      const b = ProductListLoaded(categoryId: 'abayas', products: [formal]);
      const c = ProductListLoaded(
        categoryId: 'abayas',
        products: [formal],
        filter: ProductFilter(tagId: 'occasions'),
      );

      expect(a, b);
      // Without selectedTagId in props, tapping a chip would emit a state equal
      // to the previous one and the grid would never update.
      expect(a, isNot(c));
    });
  });
}
