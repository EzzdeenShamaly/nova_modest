import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nova_modest/core/error/failure.dart';
import 'package:nova_modest/core/error/result.dart';
import 'package:nova_modest/features/cart/data/repositories/cart_repository_impl.dart';
import 'package:nova_modest/features/cart/domain/entities/cart_item.dart';
import 'package:nova_modest/features/catalog/domain/entities/product.dart';
import 'package:nova_modest/features/catalog/domain/repositories/catalog_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockPreferences extends Mock implements SharedPreferences {}

class _MockCatalog extends Mock implements CatalogRepository {}

void main() {
  late _MockPreferences preferences;
  late _MockCatalog catalog;
  late CartRepositoryImpl repository;

  const key = 'cart.lines';

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

  /// What the catalogue currently returns. Mutated by the tests that need the
  /// shop to change under a cart saved earlier.
  late Map<String, Product> catalogue;

  /// The one stored string, standing in for the preferences file.
  String? stored;

  List<Map<String, dynamic>> storedLines() =>
      (jsonDecode(stored!) as List<dynamic>).cast<Map<String, dynamic>>();

  List<CartItem> itemsOf(Result<List<CartItem>> result) =>
      (result as Ok<List<CartItem>>).value;

  setUp(() {
    preferences = _MockPreferences();
    catalog = _MockCatalog();
    catalogue = {'p1': dress, 'p3': scarf};
    stored = null;

    when(() => preferences.getString(key)).thenAnswer((_) => stored);
    when(() => preferences.setString(key, any())).thenAnswer((
      invocation,
    ) async {
      stored = invocation.positionalArguments[1] as String;
      return true;
    });
    when(() => catalog.productById(any())).thenAnswer((invocation) async {
      final id = invocation.positionalArguments.first as String;
      final product = catalogue[id];
      return product == null
          ? const Err<Product>(NotFoundFailure())
          : Ok<Product>(product);
    });

    repository = CartRepositoryImpl(preferences, catalog);
  });

  group('load', () {
    test('an untouched cart is empty, not an error', () async {
      final result = await repository.load();

      expect(itemsOf(result), isEmpty);
    });

    test('corrupt storage is reported rather than silently emptied', () async {
      stored = 'not json at all';

      final result = await repository.load();

      // Quietly resetting someone's cart hides the fault and loses their work.
      expect((result as Err<List<CartItem>>).failure, isA<CacheFailure>());
    });

    test('storage of the wrong shape is reported too', () async {
      stored = '{"productId":"p1"}';

      final result = await repository.load();

      expect((result as Err<List<CartItem>>).failure, isA<CacheFailure>());
    });

    test('a read failure maps to CacheFailure', () async {
      when(
        () => preferences.getString(key),
      ).thenThrow(PlatformException(code: 'unavailable'));

      final result = await repository.load();

      expect((result as Err<List<CartItem>>).failure, isA<CacheFailure>());
    });
  });

  group('add', () {
    test('stores ids only, never a copy of the product', () async {
      await repository.add(product: dress, colourId: 'sand', size: 'M');

      expect(storedLines(), [
        {'product_id': 'p1', 'colour_id': 'sand', 'size': 'M', 'quantity': 1},
      ]);
      // The whole point: no name and no price on disk to go stale.
      expect(stored, isNot(contains('450')));
      expect(stored, isNot(contains('فستان')));
    });

    test('returns the cart with the product attached', () async {
      final result = await repository.add(
        product: dress,
        colourId: 'sand',
        size: 'M',
      );

      final items = itemsOf(result);
      expect(items, hasLength(1));
      expect(items.single.product, dress);
      expect(items.single.size, 'M');
      expect(items.single.lineTotal, 450);
    });

    test('the same product, colour and size raises one line', () async {
      await repository.add(product: dress, colourId: 'sand', size: 'M');
      final result = await repository.add(
        product: dress,
        colourId: 'sand',
        size: 'M',
        quantity: 2,
      );

      expect(itemsOf(result), hasLength(1));
      expect(itemsOf(result).single.quantity, 3);
    });

    test('a different size is a second line', () async {
      await repository.add(product: dress, colourId: 'sand', size: 'M');
      final result = await repository.add(
        product: dress,
        colourId: 'sand',
        size: 'L',
      );

      // Buying the same garment in two sizes is ordinary, not a duplicate.
      expect(itemsOf(result), hasLength(2));
      expect(itemsOf(result).map((item) => item.size), ['M', 'L']);
    });

    test('merging cannot climb past the ceiling', () async {
      await repository.add(product: dress, quantity: 8);
      final result = await repository.add(product: dress, quantity: 8);

      expect(itemsOf(result).single.quantity, CartItem.maxQuantity);
    });

    test('a failed write is reported, not swallowed', () async {
      when(
        () => preferences.setString(key, any()),
      ).thenAnswer((_) async => false);

      final result = await repository.add(product: dress);

      expect((result as Err<List<CartItem>>).failure, isA<CacheFailure>());
    });
  });

  group('updateQuantity and remove', () {
    test('one line moves and the others do not', () async {
      await repository.add(product: dress, size: 'M');
      await repository.add(product: scarf);

      final result = await repository.updateQuantity('p1||M', 4);

      final items = itemsOf(result);
      expect(items.firstWhere((item) => item.product.id == 'p1').quantity, 4);
      expect(items.firstWhere((item) => item.product.id == 'p3').quantity, 1);
    });

    test('the quantity is clamped at both ends', () async {
      await repository.add(product: dress);

      final low = await repository.updateQuantity('p1||', 0);
      expect(itemsOf(low).single.quantity, 1);

      final high = await repository.updateQuantity('p1||', 99);
      expect(itemsOf(high).single.quantity, CartItem.maxQuantity);
    });

    test('an unknown line changes nothing', () async {
      await repository.add(product: dress);

      final result = await repository.updateQuantity('nope||', 5);

      expect(itemsOf(result).single.quantity, 1);
    });

    test('remove drops the line and persists the removal', () async {
      await repository.add(product: dress);
      await repository.add(product: scarf);

      final result = await repository.remove('p1||');

      expect(itemsOf(result).map((item) => item.product.id), ['p3']);
      expect(storedLines().map((line) => line['product_id']), ['p3']);
    });

    test('clear empties the cart and the storage behind it', () async {
      await repository.add(product: dress, size: 'M');
      await repository.add(product: scarf);

      final result = await repository.clear();

      expect(itemsOf(result), isEmpty);
      // Persisted, not only emitted: a cart that comes back on the next launch
      // is a cart of things already bought.
      expect(storedLines(), isEmpty);
    });

    test('clearing an already-empty cart is not an error', () async {
      final result = await repository.clear();

      expect(itemsOf(result), isEmpty);
    });
  });

  group('rehydration', () {
    test('a price change reaches a cart saved before it', () async {
      await repository.add(product: dress, size: 'M');

      // The shop re-prices while the cart sits on disk.
      catalogue['p1'] = dress.copyWith(price: 400);
      final result = await repository.load();

      expect(itemsOf(result).single.product.price, 400);
      expect(itemsOf(result).single.lineTotal, 400);
    });

    test('a product that left the catalogue drops out and is pruned', () async {
      await repository.add(product: dress);
      await repository.add(product: scarf);

      catalogue.remove('p1');
      final result = await repository.load();

      expect(itemsOf(result).map((item) => item.product.id), ['p3']);
      // Pruned, so it does not cost a lookup on every future load.
      expect(storedLines().map((line) => line['product_id']), ['p3']);
    });

    test('any other catalogue failure propagates', () async {
      await repository.add(product: dress);
      when(
        () => catalog.productById(any()),
      ).thenAnswer((_) async => const Err<Product>(NetworkFailure()));

      final result = await repository.load();

      // Not a NotFound, so this is not a vanished product — showing an empty
      // cart here would tell the shopper their cart had been cleared.
      expect((result as Err<List<CartItem>>).failure, isA<NetworkFailure>());
    });
  });
}
