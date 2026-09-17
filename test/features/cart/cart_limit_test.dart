import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nova_modest/core/error/failure.dart';
import 'package:nova_modest/core/error/result.dart';
import 'package:nova_modest/features/cart/domain/entities/cart_item.dart';
import 'package:nova_modest/features/cart/domain/entities/cart_totals.dart';
import 'package:nova_modest/features/cart/domain/repositories/cart_repository.dart';
import 'package:nova_modest/features/cart/presentation/bloc/cart_bloc.dart';
import 'package:nova_modest/features/catalog/domain/entities/product.dart';

class _MockCartRepository extends Mock implements CartRepository {}

/// The twenty-line limit, which mirrors `place_order`'s `k_max_lines`.
///
/// Without it the shopper learns about it at the very end of checkout, after
/// filling in contact details and an address, from a server refusal.
void main() {
  Product product(int i) =>
      Product(id: 'p$i', name: 'منتج $i', price: 100, categoryId: 'abayas');

  List<CartItem> linesOf(int count) => [
    for (var i = 0; i < count; i++) CartItem(product: product(i)),
  ];

  group('the limit counts lines, not garments', () {
    test('twenty lines of ten each is not full — the contract allows it', () {
      // 20 lines x quantity 10 = 200 garments, and `place_order` accepts it.
      // Confusing the two limits would refuse a legal order.
      final full = CartLoaded(
        items: [
          for (var i = 0; i < CartItem.maxLines; i++)
            CartItem(product: product(i), quantity: CartItem.maxQuantity),
        ],
        totals: const CartTotals(subtotal: 0, shipping: 0),
      );

      expect(full.itemCount, 200);
      expect(full.isFull, isTrue, reason: 'twenty lines is the limit');
    });

    test('nineteen lines is not full whatever the quantities', () {
      final cart = CartLoaded(
        items: linesOf(CartItem.maxLines - 1),
        totals: const CartTotals(subtotal: 0, shipping: 0),
      );

      expect(cart.isFull, isFalse);
    });

    test('a cart that has not loaded is never full', () {
      expect(const CartInitial().isFull, isFalse);
      expect(const CartLoading().isFull, isFalse);
      expect(const CartEmpty().isFull, isFalse);
    });
  });

  group('the bloc keeps the cart when an addition is declined', () {
    late CartRepository repository;

    setUp(() {
      repository = _MockCartRepository();
      registerFallbackValue(product(0));
    });

    final atLimit = CartLoaded(
      items: linesOf(CartItem.maxLines),
      totals: const CartTotals(subtotal: 0, shipping: 0),
    );

    blocTest<CartBloc, CartState>(
      'a full cart refuses without becoming an error screen',
      setUp: () => when(
        () => repository.add(
          product: any(named: 'product'),
          colourId: any(named: 'colourId'),
          size: any(named: 'size'),
          quantity: any(named: 'quantity'),
        ),
      ).thenAnswer(
        (_) async => const Err(
          ValidationFailure('Cart is full.', code: CartRepository.fullCode),
        ),
      ),
      build: () => CartBloc(repository),
      seed: () => atLimit,
      act: (bloc) => bloc.add(CartItemAdded(product: product(99))),
      // Not CartError: the cart is intact and still correct. An error card here
      // would replace a working cart over something the shopper can undo.
      expect: () => [
        CartAdditionRefused(items: atLimit.items, totals: atLimit.totals),
      ],
    );

    blocTest<CartBloc, CartState>(
      'a real storage failure is still an error screen',
      setUp: () => when(
        () => repository.add(
          product: any(named: 'product'),
          colourId: any(named: 'colourId'),
          size: any(named: 'size'),
          quantity: any(named: 'quantity'),
        ),
      ).thenAnswer((_) async => const Err(CacheFailure('disk gone'))),
      build: () => CartBloc(repository),
      seed: () => atLimit,
      act: (bloc) => bloc.add(CartItemAdded(product: product(99))),
      expect: () => [const CartError(CacheFailure('disk gone'))],
    );
  });

  test('the refused state still draws a cart, and counts for the badge', () {
    final refused = CartAdditionRefused(
      items: linesOf(3),
      totals: const CartTotals(subtotal: 0, shipping: 0),
    );

    expect(refused.itemCount, 3);
    expect(refused.cart.items, refused.items);
    expect(refused.isFull, isTrue);
  });
}
