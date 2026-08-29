import 'package:flutter_test/flutter_test.dart';
import 'package:nova_modest/core/error/result.dart';
import 'package:nova_modest/features/catalog/data/repositories/fake_catalog_repository.dart';
import 'package:nova_modest/features/catalog/domain/entities/product.dart';

/// One catalogue serves both screens. These pin the part that is easy to break
/// later: adding rows for a new screen must not silently change an existing one.
void main() {
  const repository = FakeCatalogRepository();

  Future<List<Product>> featured() async =>
      (await repository.featuredProducts() as Ok<List<Product>>).value;

  Future<List<Product>> inCategory(String id) async =>
      (await repository.productsInCategory(id) as Ok<List<Product>>).value;

  test('featured stays a curated slice, not the whole catalogue', () async {
    final home = await featured();
    final abayas = await inCategory('abayas');

    expect(home, hasLength(4));
    // The listing's products were appended to the same list. If featured ever
    // returned everything, Home's grid would grow every time another screen
    // needed data.
    expect(abayas.length, greaterThan(home.length));
  });

  test('a category returns every product in it', () async {
    final abayas = await inCategory('abayas');

    expect(abayas, isNotEmpty);
    expect(abayas.every((p) => p.categoryId == 'abayas'), isTrue);
    // The four from the listing design plus the two Home already had.
    expect(abayas.map((p) => p.id), containsAll(['p5', 'p6', 'p7', 'p8']));
  });

  test('an unknown category is empty, not an error', () async {
    final result = await repository.productsInCategory('does-not-exist');

    expect(result, isA<Ok<List<Product>>>());
    expect((result as Ok<List<Product>>).value, isEmpty);
  });

  test('the sold-out product carries the flag, not the widget', () async {
    final abayas = await inCategory('abayas');
    final soldOut = abayas.where((p) => p.isSoldOut).toList();

    expect(soldOut, hasLength(1));
    expect(soldOut.single.name, 'عباية كتان يومية');
  });

  test(
    'every listing product is tagged, so the chips are never dead',
    () async {
      final abayas = await inCategory('abayas');

      expect(abayas.every((p) => p.tags.isNotEmpty), isTrue);
    },
  );

  test('each tag matches at least one product', () async {
    final abayas = await inCategory('abayas');
    final tagIds = {for (final p in abayas) ...p.tags.map((t) => t.id)};

    // A chip that can never return anything is worse than no chip.
    for (final id in tagIds) {
      expect(
        abayas.where((p) => p.tags.any((t) => t.id == id)),
        isNotEmpty,
        reason: 'tag $id matches nothing',
      );
    }
    expect(tagIds, containsAll(['daily', 'occasions', 'colourful']));
  });

  test('categories are returned in display order', () async {
    final result = await repository.categories();
    final ids = (result as Ok).value.map((c) => c.id).toList();

    expect(ids, ['abayas', 'hijab-shawls', 'sets', 'accessories']);
  });

  group('search', () {
    Future<List<Product>> search(String query) async =>
        (await repository.searchProducts(query) as Ok<List<Product>>).value;

    test('matches a product by its name', () async {
      final hits = await search('كحلية');

      expect(hits.map((product) => product.id), ['p7']);
    });

    test('matches by the category a product sits in', () async {
      final hits = await search('حجاب وشالات');

      expect(hits, isNotEmpty);
      expect(
        hits.every((product) => product.categoryId == 'hijab-shawls'),
        isTrue,
      );
    });

    test('matches by tag, so a trending term always lands', () async {
      final hits = await search('مناسبات');

      expect(hits, isNotEmpty);
      expect(
        hits.every((product) => product.tags.any((t) => t.id == 'occasions')),
        isTrue,
      );
    });

    test('an empty query is no results, not the whole catalogue', () async {
      // "Show me everything" is what the listing is for.
      expect(await search(''), isEmpty);
      expect(await search('   '), isEmpty);
    });

    test('a query matching nothing returns nothing', () async {
      expect(await search('حذاء رياضي'), isEmpty);
    });

    group('Arabic is folded the way it is actually typed', () {
      test('taa marbuta and haa are the same letter to a shopper', () async {
        // Without folding, "عبايه" finds nothing while "عباية" finds eight
        // rows — and the screen looks broken to whoever typed it the ordinary
        // way.
        expect(await search('عبايه'), await search('عباية'));
        expect(await search('عبايه'), isNotEmpty);
      });

      test('the alef forms collapse', () async {
        expect(await search('اطقم'), await search('أطقم'));
        expect(await search('اطقم'), isNotEmpty);
      });

      test('harakat and tatweel are ignored', () async {
        expect(await search('عَبايةـ'), await search('عباية'));
      });
    });
  });

  group('trending', () {
    test('every trending term returns products', () async {
      final terms =
          (await repository.trendingSearches() as Ok<List<String>>).value;

      expect(terms, isNotEmpty);
      for (final term in terms) {
        final hits =
            (await repository.searchProducts(term) as Ok<List<Product>>).value;
        expect(
          hits,
          isNotEmpty,
          reason: 'trending term "$term" matches nothing',
        );
      }
    });
  });
}
