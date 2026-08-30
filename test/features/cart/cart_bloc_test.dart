import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nova_modest/core/error/failure.dart';
import 'package:nova_modest/core/error/result.dart';
import 'package:nova_modest/features/cart/domain/entities/cart_item.dart';
import 'package:nova_modest/features/cart/domain/entities/cart_totals.dart';
import 'package:nova_modest/features/checkout/domain/entities/shipping_method.dart';
import 'package:nova_modest/features/cart/domain/repositories/cart_repository.dart';
import 'package:nova_modest/features/cart/presentation/bloc/cart_bloc.dart';
import 'package:nova_modest/features/catalog/domain/entities/product.dart';

class _MockCartRepository extends Mock implements CartRepository {}

void main() {
  late _MockCartRepository repository;

  const dress = Product(
    id: 'p1',
    name: 'فستان كتان رملي',
    price: 450,
    categoryId: 'sets',
  );
  const scarf = Product(
    id: 'p3',
    name: 'وشاح حرير زيتوني',
    price: 120,
    categoryId: 'hijab-shawls',
  );

  const dressLine = CartItem(product: dress, colourId: 'sand', size: 'M');
  const scarfLine = CartItem(product: scarf, quantity: 2);

  setUpAll(() => registerFallbackValue(dress));

  setUp(() => repository = _MockCartRepository());

  void givenLoad(Result<List<CartItem>> result) =>
      when(() => repository.load()).thenAnswer((_) async => result);

  group('loading', () {
    blocTest<CartBloc, CartState>(
      'an empty cart is its own state, not an empty list',
      setUp: () => givenLoad(const Ok(<CartItem>[])),
      build: () => CartBloc(repository),
      act: (bloc) => bloc.add(const CartRequested()),
      // "Your cart is empty" is a different screen from a list with no rows.
      expect: () => const [CartLoading(), CartEmpty()],
    );

    blocTest<CartBloc, CartState>(
      'a stocked cart arrives with its totals already computed',
      setUp: () => givenLoad(const Ok([dressLine, scarfLine])),
      build: () => CartBloc(repository),
      act: (bloc) => bloc.add(const CartRequested()),
      expect: () => [
        const CartLoading(),
        CartLoaded(
          items: const [dressLine, scarfLine],
          totals: CartTotals.of(const [dressLine, scarfLine]),
        ),
      ],
    );

    blocTest<CartBloc, CartState>(
      'a failed read is an error state, reachable because the cart is stored',
      setUp: () => givenLoad(const Err(CacheFailure())),
      build: () => CartBloc(repository),
      act: (bloc) => bloc.add(const CartRequested()),
      expect: () => const [CartLoading(), CartError(CacheFailure())],
    );
  });

  group('clearing after an order is placed', () {
    blocTest<CartBloc, CartState>(
      'empties the cart',
      setUp: () => when(
        () => repository.clear(),
      ).thenAnswer((_) async => const Ok(<CartItem>[])),
      build: () => CartBloc(repository),
      act: (bloc) => bloc.add(const CartCleared()),
      // No loading state: there is nothing to fetch, and a spinner between two
      // versions of a cart is a flicker rather than information.
      expect: () => const [CartEmpty()],
      verify: (_) => verify(() => repository.clear()).called(1),
    );

    blocTest<CartBloc, CartState>(
      'a failed clear is reported rather than swallowed',
      setUp: () => when(
        () => repository.clear(),
      ).thenAnswer((_) async => const Err(CacheFailure())),
      build: () => CartBloc(repository),
      act: (bloc) => bloc.add(const CartCleared()),
      // The order was still placed; the cart simply did not empty. Saying so
      // beats a badge that silently disagrees with the storage.
      expect: () => const [CartError(CacheFailure())],
    );
  });

  group('adding', () {
    blocTest<CartBloc, CartState>(
      'passes the whole selection through to the repository',
      setUp: () => when(
        () => repository.add(
          product: any(named: 'product'),
          colourId: any(named: 'colourId'),
          size: any(named: 'size'),
          quantity: any(named: 'quantity'),
        ),
      ).thenAnswer((_) async => const Ok([dressLine])),
      build: () => CartBloc(repository),
      act: (bloc) => bloc.add(
        const CartItemAdded(
          product: dress,
          colourId: 'sand',
          size: 'M',
          quantity: 3,
        ),
      ),
      verify: (_) => verify(
        () => repository.add(
          product: dress,
          colourId: 'sand',
          size: 'M',
          quantity: 3,
        ),
      ).called(1),
    );

    blocTest<CartBloc, CartState>(
      'does not pass through loading',
      setUp: () => when(
        () => repository.add(
          product: any(named: 'product'),
          colourId: any(named: 'colourId'),
          size: any(named: 'size'),
          quantity: any(named: 'quantity'),
        ),
      ).thenAnswer((_) async => const Ok([dressLine])),
      build: () => CartBloc(repository),
      act: (bloc) => bloc.add(const CartItemAdded(product: dress)),
      // Exactly one state. A CartLoading in between would blank the cart tab
      // behind a shopper who is still on the product page, and flicker the
      // list for one who is not.
      expect: () => [
        CartLoaded(
          items: const [dressLine],
          totals: CartTotals.of(const [dressLine]),
        ),
      ],
    );
  });

  group('mutating', () {
    blocTest<CartBloc, CartState>(
      'the quantity is clamped by the bloc, not only by the buttons',
      setUp: () => when(
        () => repository.updateQuantity(any(), any()),
      ).thenAnswer((_) async => const Ok([dressLine])),
      build: () => CartBloc(repository),
      act: (bloc) => bloc
        ..add(const CartQuantityChanged('p1|sand|M', 0))
        ..add(const CartQuantityChanged('p1|sand|M', 99)),
      verify: (_) {
        verify(() => repository.updateQuantity('p1|sand|M', 1)).called(1);
        verify(
          () => repository.updateQuantity('p1|sand|M', CartItem.maxQuantity),
        ).called(1);
      },
    );

    blocTest<CartBloc, CartState>(
      'removing the last line lands on the empty state',
      setUp: () => when(
        () => repository.remove(any()),
      ).thenAnswer((_) async => const Ok(<CartItem>[])),
      build: () => CartBloc(repository),
      act: (bloc) => bloc.add(const CartItemRemoved('p1|sand|M')),
      expect: () => const [CartEmpty()],
    );

    blocTest<CartBloc, CartState>(
      'a failed write surfaces, with a retry that re-reads storage',
      setUp: () => when(
        () => repository.remove(any()),
      ).thenAnswer((_) async => const Err(CacheFailure())),
      build: () => CartBloc(repository),
      act: (bloc) => bloc.add(const CartItemRemoved('p1|sand|M')),
      expect: () => const [CartError(CacheFailure())],
    );
  });

  group('totals', () {
    test('subtotal is the sum of the lines and shipping is flat', () {
      final totals = CartTotals.of(const [dressLine, scarfLine]);

      expect(totals.subtotal, 450 + 120 * 2);
      expect(totals.shipping, CartTotals.shippingFee);
      expect(totals.total, 690 + 35);
    });

    test('the quote is the shipping method checkout will charge', () {
      // These were 30 here and 35 at checkout, so the total moved between the
      // cart and step 3 with nothing on screen explaining it.
      expect(CartTotals.shippingFee, ShippingMethod.standard.cost);
    });

    test('an empty cart is charged nothing to ship', () {
      final totals = CartTotals.of(const []);

      expect(totals.subtotal, 0);
      expect(totals.shipping, 0);
    });
  });

  group('badge count', () {
    test('counts quantities, not lines', () {
      final state = CartLoaded(
        items: const [dressLine, scarfLine],
        totals: CartTotals.of(const [dressLine, scarfLine]),
      );

      expect(state.itemCount, 3);
    });

    test('every other state counts nothing', () {
      for (final state in const [
        CartInitial(),
        CartLoading(),
        CartEmpty(),
        CartError(CacheFailure()),
      ]) {
        expect(state.itemCount, 0);
      }
    });
  });

  group('state equality', () {
    test('Loaded compares by items and totals', () {
      final a = CartLoaded(
        items: const [dressLine],
        totals: CartTotals.of(const [dressLine]),
      );
      final same = CartLoaded(
        items: const [dressLine],
        totals: CartTotals.of(const [dressLine]),
      );
      const heavier = CartItem(
        product: dress,
        colourId: 'sand',
        size: 'M',
        quantity: 2,
      );
      final different = CartLoaded(
        items: const [heavier],
        totals: CartTotals.of(const [heavier]),
      );

      expect(a, same);
      // Without these in props, raising a quantity would emit a state equal to
      // the previous one and the list would never update.
      expect(a, isNot(different));
    });

    test('a line is identified by the product and every choice on it', () {
      const inM = CartItem(product: dress, colourId: 'sand', size: 'M');
      const inL = CartItem(product: dress, colourId: 'sand', size: 'L');

      expect(inM.lineId, 'p1|sand|M');
      expect(inM.lineId, isNot(inL.lineId));
    });
  });
}
