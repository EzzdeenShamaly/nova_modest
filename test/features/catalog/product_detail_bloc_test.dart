import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nova_modest/core/error/failure.dart';
import 'package:nova_modest/core/error/result.dart';
import 'package:nova_modest/features/catalog/domain/entities/product.dart';
import 'package:nova_modest/features/catalog/domain/entities/product_colour.dart';
import 'package:nova_modest/features/catalog/domain/repositories/catalog_repository.dart';
import 'package:nova_modest/features/catalog/presentation/bloc/product_detail_bloc.dart';

class _MockCatalogRepository extends Mock implements CatalogRepository {}

void main() {
  late _MockCatalogRepository repository;

  const black = ProductColour(id: 'black', name: 'أسود', hex: '#000000');
  const grey = ProductColour(id: 'grey', name: 'رمادي', hex: '#6B7280');

  const product = Product(
    id: 'p2',
    name: 'عباءة سوداء بتفاصيل عصرية',
    price: 520,
    categoryId: 'abayas',
    colours: [black, grey],
    sizes: ['S', 'M', 'L'],
  );
  const bare = Product(
    id: 'p9',
    name: 'قطعة بلا خيارات',
    price: 100,
    categoryId: 'abayas',
  );

  setUp(() => repository = _MockCatalogRepository());

  void given(Product p) =>
      when(() => repository.productById(any())).thenAnswer((_) async => Ok(p));

  group('states', () {
    blocTest<ProductDetailBloc, ProductDetailState>(
      'loading then data, with the first colour and size preselected',
      setUp: () => given(product),
      build: () => ProductDetailBloc(repository),
      act: (bloc) => bloc.add(const ProductDetailRequested('p2')),
      // The design shows a selection already made; a shopper should not have to
      // pick before the screen looks finished.
      expect: () => const [
        ProductDetailLoading(),
        ProductDetailLoaded(
          product: product,
          selectedColourId: 'black',
          selectedSize: 'S',
        ),
      ],
    );

    blocTest<ProductDetailBloc, ProductDetailState>(
      'an unknown product is an error, not an empty screen',
      setUp: () => when(
        () => repository.productById(any()),
      ).thenAnswer((_) async => const Err(NotFoundFailure())),
      build: () => ProductDetailBloc(repository),
      act: (bloc) => bloc.add(const ProductDetailRequested('nope')),
      // There is no Empty state here on purpose: a product either exists or it
      // does not, and "does not" is a NotFoundFailure.
      expect: () => const [
        ProductDetailLoading(),
        ProductDetailError(NotFoundFailure()),
      ],
    );

    blocTest<ProductDetailBloc, ProductDetailState>(
      'a product with no options selects nothing and is still complete',
      setUp: () => given(bare),
      build: () => ProductDetailBloc(repository),
      act: (bloc) => bloc.add(const ProductDetailRequested('p9')),
      verify: (bloc) {
        final state = bloc.state as ProductDetailLoaded;
        expect(state.selectedColourId, isNull);
        expect(state.selectedSize, isNull);
        // Nothing outstanding, so the button must not be blocked.
        expect(state.isSelectionComplete, isTrue);
      },
    );
  });

  group('selection', () {
    blocTest<ProductDetailBloc, ProductDetailState>(
      'colour and size are recorded without another fetch',
      setUp: () => given(product),
      build: () => ProductDetailBloc(repository),
      act: (bloc) async {
        bloc.add(const ProductDetailRequested('p2'));
        await Future<void>.delayed(Duration.zero);
        bloc
          ..add(const ProductDetailColourSelected('grey'))
          ..add(const ProductDetailSizeSelected('L'));
      },
      skip: 3,
      verify: (bloc) {
        final state = bloc.state as ProductDetailLoaded;
        expect(state.selectedColourId, 'grey');
        expect(state.selectedSize, 'L');
        verify(() => repository.productById('p2')).called(1);
      },
    );

    blocTest<ProductDetailBloc, ProductDetailState>(
      'a selection before the product arrives is ignored',
      setUp: () => given(product),
      build: () => ProductDetailBloc(repository),
      act: (bloc) => bloc.add(const ProductDetailSizeSelected('L')),
      expect: () => const <ProductDetailState>[],
    );
  });

  group('quantity', () {
    blocTest<ProductDetailBloc, ProductDetailState>(
      'starts at one',
      setUp: () => given(product),
      build: () => ProductDetailBloc(repository),
      act: (bloc) => bloc.add(const ProductDetailRequested('p2')),
      verify: (bloc) => expect((bloc.state as ProductDetailLoaded).quantity, 1),
    );

    blocTest<ProductDetailBloc, ProductDetailState>(
      'is clamped at both ends by the bloc, not just by the buttons',
      setUp: () => given(product),
      build: () => ProductDetailBloc(repository),
      act: (bloc) async {
        bloc.add(const ProductDetailRequested('p2'));
        await Future<void>.delayed(Duration.zero);
        bloc.add(const ProductDetailQuantityChanged(0));
      },
      skip: 2,
      verify: (bloc) => expect((bloc.state as ProductDetailLoaded).quantity, 1),
    );

    blocTest<ProductDetailBloc, ProductDetailState>(
      'cannot exceed the ceiling',
      setUp: () => given(product),
      build: () => ProductDetailBloc(repository),
      act: (bloc) async {
        bloc.add(const ProductDetailRequested('p2'));
        await Future<void>.delayed(Duration.zero);
        bloc.add(const ProductDetailQuantityChanged(99));
      },
      skip: 2,
      verify: (bloc) => expect(
        (bloc.state as ProductDetailLoaded).quantity,
        ProductDetailBloc.maxQuantity,
      ),
    );
  });

  group('state equality', () {
    test('Loaded compares by product and every choice', () {
      const a = ProductDetailLoaded(product: product, selectedSize: 'S');
      const b = ProductDetailLoaded(product: product, selectedSize: 'S');
      const differentSize = ProductDetailLoaded(
        product: product,
        selectedSize: 'M',
      );
      const differentQty = ProductDetailLoaded(
        product: product,
        selectedSize: 'S',
        quantity: 2,
      );

      expect(a, b);
      // Without these in props, changing a size or a quantity would emit a
      // state equal to the previous one and the screen would never update.
      expect(a, isNot(differentSize));
      expect(a, isNot(differentQty));
    });
  });
}
