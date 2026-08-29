import 'package:flutter_test/flutter_test.dart';
import 'package:nova_modest/features/catalog/domain/entities/product.dart';
import 'package:nova_modest/features/catalog/domain/entities/product_category.dart';
import 'package:nova_modest/features/catalog/domain/entities/product_colour.dart';
import 'package:nova_modest/features/catalog/domain/entities/product_filter.dart';
import 'package:nova_modest/features/catalog/domain/entities/product_filter_options.dart';
import 'package:nova_modest/features/catalog/domain/entities/product_tag.dart';

void main() {
  const daily = ProductTag(id: 'daily', name: 'يومي');
  const occasions = ProductTag(id: 'occasions', name: 'مناسبات');

  const black = ProductColour(id: 'black', name: 'أسود', hex: '#000000');
  const sand = ProductColour(id: 'sand', name: 'رملي', hex: '#E8DFD3');

  const abaya = Product(
    id: 'p1',
    name: 'عباية كتان يومية',
    price: 450,
    categoryId: 'abayas',
    tags: [daily],
    sizes: ['S', 'M'],
    colours: [black],
  );
  const gown = Product(
    id: 'p2',
    name: 'عباية رسمية كحلية',
    price: 950,
    categoryId: 'abayas',
    tags: [occasions],
    sizes: ['M', 'L'],
    colours: [sand],
  );
  const scarf = Product(
    id: 'p3',
    name: 'شيلة حريرية',
    price: 120,
    categoryId: 'hijab-shawls',
    tags: [daily],
  );

  const all = [abaya, gown, scarf];

  List<String> idsOf(List<Product> products) => [
    for (final product in products) product.id,
  ];

  group('apply', () {
    test('an empty filter narrows nothing', () {
      expect(idsOf(ProductFilter.none.apply(all)), ['p1', 'p2', 'p3']);
      expect(ProductFilter.none.isEmpty, isTrue);
      expect(ProductFilter.none.activeCount, 0);
    });

    test('categories are OR within the facet', () {
      const filter = ProductFilter(categoryIds: {'abayas', 'hijab-shawls'});

      expect(idsOf(filter.apply(all)), ['p1', 'p2', 'p3']);
      expect(idsOf(const ProductFilter(categoryIds: {'abayas'}).apply(all)), [
        'p1',
        'p2',
      ]);
    });

    test('facets are AND between', () {
      // Everyday abayas: the tag alone would also match the scarf.
      const filter = ProductFilter(categoryIds: {'abayas'}, tagId: 'daily');

      expect(idsOf(filter.apply(all)), ['p1']);
      expect(filter.activeCount, 2);
    });

    test('price bounds are inclusive at both ends', () {
      expect(idsOf(const ProductFilter(minPrice: 450).apply(all)), [
        'p1',
        'p2',
      ]);
      expect(idsOf(const ProductFilter(maxPrice: 450).apply(all)), [
        'p1',
        'p3',
      ]);
      expect(
        idsOf(const ProductFilter(minPrice: 450, maxPrice: 950).apply(all)),
        ['p1', 'p2'],
      );
    });

    test('a price range counts as one active facet, not two', () {
      expect(const ProductFilter(minPrice: 100, maxPrice: 900).activeCount, 1);
      expect(const ProductFilter(minPrice: 100).activeCount, 1);
    });

    test('a size matches when the product offers it among others', () {
      expect(idsOf(const ProductFilter(sizes: {'L'}).apply(all)), ['p2']);
      expect(idsOf(const ProductFilter(sizes: {'M'}).apply(all)), ['p1', 'p2']);
    });

    test('a product offering no sizes cannot satisfy a size filter', () {
      // The scarf has no sizes at all. Letting it through unchecked would put
      // an unsized item in a result the shopper asked to be sized.
      expect(
        idsOf(const ProductFilter(sizes: {'M'}).apply(all)),
        isNot(contains('p3')),
      );
    });

    test('colours match by id, not by hex', () {
      expect(idsOf(const ProductFilter(colourIds: {'sand'}).apply(all)), [
        'p2',
      ]);
    });

    test('a filter matching nothing returns an empty list, not everything', () {
      const filter = ProductFilter(categoryIds: {'sets'});

      expect(filter.apply(all), isEmpty);
    });
  });

  group('options', () {
    const categories = [
      ProductCategory(id: 'abayas', name: 'عبايات'),
      ProductCategory(id: 'hijab-shawls', name: 'حجاب وشالات'),
      ProductCategory(id: 'sets', name: 'أطقم'),
    ];

    test('are derived from the products in hand, de-duplicated', () {
      final options = ProductFilterOptions.from(all);

      expect(options.tags.map((tag) => tag.id), ['daily', 'occasions']);
      expect(options.sizes, ['S', 'M', 'L']);
      expect(options.colours.map((colour) => colour.id), ['black', 'sand']);
      expect(options.minPrice, 120);
      expect(options.maxPrice, 950);
    });

    test('categories are kept only where a product on screen belongs', () {
      final options = ProductFilterOptions.from(all, categories: categories);

      // "sets" has no product here, so offering it would be a dead control.
      expect(options.categories.map((category) => category.id), [
        'abayas',
        'hijab-shawls',
      ]);
    });

    test('a facet with one option is not worth drawing', () {
      // A single-category listing: every product shares the category, so the
      // category section hides and only the styles remain.
      final options = ProductFilterOptions.from(const [
        abaya,
        gown,
      ], categories: categories);

      expect(options.hasCategories, isFalse);
      expect(options.hasTags, isTrue);
      expect(options.hasSizes, isTrue);
      expect(options.hasColours, isTrue);
    });

    test('a range needs two different ends', () {
      final single = ProductFilterOptions.from(const [abaya]);

      // One product means one price, and a slider whose ends coincide cannot
      // be dragged — so the price section hides while the sized and coloured
      // facets it still has stay.
      expect(single.minPrice, single.maxPrice);
      expect(single.hasPriceRange, isFalse);
      expect(single.hasSizes, isTrue);
    });

    test('no products means no options at all', () {
      final none = ProductFilterOptions.from(const []);

      expect(none.isEmpty, isTrue);
      expect(none.minPrice, isNull);
    });
  });

  group('equality', () {
    test('two filters with the same facets are the same value', () {
      const a = ProductFilter(categoryIds: {'abayas'}, sizes: {'M'});
      const b = ProductFilter(categoryIds: {'abayas'}, sizes: {'M'});
      const c = ProductFilter(categoryIds: {'abayas'}, sizes: {'L'});

      expect(a, b);
      // Without deep collection equality, changing a size would emit a state
      // equal to the previous one and the grid would never update.
      expect(a, isNot(c));
    });

    test('copyWith can clear the tag without clearing the rest', () {
      const filter = ProductFilter(tagId: 'daily', sizes: {'M'});

      final cleared = filter.copyWith(tagId: null);

      expect(cleared.tagId, isNull);
      expect(cleared.sizes, {'M'});
    });
  });
}
