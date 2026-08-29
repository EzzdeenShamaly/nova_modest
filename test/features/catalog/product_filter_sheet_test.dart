import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nova_modest/features/catalog/domain/entities/product.dart';
import 'package:nova_modest/features/catalog/domain/entities/product_category.dart';
import 'package:nova_modest/features/catalog/domain/entities/product_colour.dart';
import 'package:nova_modest/features/catalog/domain/entities/product_filter.dart';
import 'package:nova_modest/features/catalog/domain/entities/product_filter_options.dart';
import 'package:nova_modest/features/catalog/domain/entities/product_tag.dart';
import 'package:nova_modest/features/catalog/presentation/widgets/colour_swatch_row.dart';
import 'package:nova_modest/features/catalog/presentation/widgets/product_filter_sheet.dart';

import '../../helpers/pump_app.dart';

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
    sizes: ['L'],
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
  const categories = [
    ProductCategory(id: 'abayas', name: 'عبايات'),
    ProductCategory(id: 'hijab-shawls', name: 'حجاب وشالات'),
  ];

  setUpAll(loadAppFonts);

  /// Opens the sheet over a bare host and hands back a one-slot box the applied
  /// filter lands in, so a test can tell "applied nothing" from "dismissed".
  Future<List<ProductFilter?>> open(
    WidgetTester tester, {
    List<Product> products = all,
    List<ProductCategory> withCategories = categories,
    ProductFilter filter = ProductFilter.none,
    Locale locale = const Locale('ar'),
  }) async {
    final captured = <ProductFilter?>[];

    await tester.pumpApp(
      Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () async => captured.add(
              await showProductFilterSheet(
                context: context,
                products: products,
                options: ProductFilterOptions.from(
                  products,
                  categories: withCategories,
                ),
                filter: filter,
              ),
            ),
            child: const Text('open'),
          ),
        ),
      ),
      locale: locale,
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    return captured;
  }

  group('which facets are drawn', () {
    testWidgets('every facet the products support', (tester) async {
      await open(tester);

      expect(find.text('التصنيف'), findsOneWidget);
      expect(find.text('النمط'), findsOneWidget);
      expect(find.text('نطاق السعر'), findsOneWidget);
      expect(find.text('المقاس'), findsOneWidget);
      expect(find.text('اللون'), findsOneWidget);
    });

    testWidgets('a single-category listing hides the category facet', (
      tester,
    ) async {
      // This is what lets one sheet serve both screens: the listing needs no
      // special case, the facet simply has nothing to offer.
      await open(tester, products: const [abaya, gown]);

      expect(find.text('التصنيف'), findsNothing);
      expect(find.text('النمط'), findsOneWidget);
    });

    testWidgets('one product leaves no price range to drag', (tester) async {
      await open(tester, products: const [abaya]);

      expect(find.text('نطاق السعر'), findsNothing);
      expect(find.byType(RangeSlider), findsNothing);
    });
  });

  group('the pending filter', () {
    testWidgets('the count shows the effect before it is applied', (
      tester,
    ) async {
      await open(tester);

      expect(find.text('عرض النتائج (3)'), findsOneWidget);

      await tester.tap(find.text('L'));
      await tester.pumpAndSettle();

      // Only the gown is offered in L.
      expect(find.text('عرض النتائج (1)'), findsOneWidget);
    });

    testWidgets('nothing leaves the sheet until it is applied', (tester) async {
      final captured = await open(tester);

      await tester.tap(find.text('L'));
      await tester.pumpAndSettle();

      expect(captured, isEmpty);
    });

    testWidgets('applying hands back the whole value', (tester) async {
      final captured = await open(tester);

      await tester.tap(find.text('L'));
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('عرض النتائج'));
      await tester.pumpAndSettle();

      expect(captured.single, const ProductFilter(sizes: {'L'}));
    });

    testWidgets('dismissing is not the same as applying nothing', (
      tester,
    ) async {
      final captured = await open(
        tester,
        filter: const ProductFilter(sizes: {'M'}),
      );

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      // Null, so the caller leaves the existing filter alone rather than
      // clearing it because someone backed out.
      expect(captured.single, isNull);
    });

    testWidgets('reset clears the facets without closing', (tester) async {
      final captured = await open(
        tester,
        filter: const ProductFilter(sizes: {'M'}),
      );

      expect(find.text('عرض النتائج (1)'), findsOneWidget);
      await tester.tap(find.text('إعادة تعيين'));
      await tester.pumpAndSettle();

      expect(find.text('عرض النتائج (3)'), findsOneWidget);
      expect(captured, isEmpty);
    });

    testWidgets('clear all is inert while nothing is set', (tester) async {
      await open(tester);

      final clear = tester.widget<TextButton>(
        find.ancestor(
          of: find.text('مسح الكل'),
          matching: find.byType(TextButton),
        ),
      );
      expect(clear.onPressed, isNull);
    });
  });

  group('facet behaviour', () {
    testWidgets('sizes and colours accumulate', (tester) async {
      final captured = await open(tester);

      await tester.tap(find.text('S'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('L'));
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('عرض النتائج'));
      await tester.pumpAndSettle();

      expect(captured.single?.sizes, {'S', 'L'});
    });

    testWidgets('a style replaces the last one rather than adding', (
      tester,
    ) async {
      final captured = await open(tester);

      await tester.tap(find.text('يومي'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('مناسبات'));
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('عرض النتائج'));
      await tester.pumpAndSettle();

      // Single-select: the chip row on the listing has one active tag, and the
      // sheet must not be able to reach a state the chip row cannot show.
      expect(captured.single?.tagId, 'occasions');
    });

    testWidgets('a category checkbox narrows the count', (tester) async {
      await open(tester);

      await tester.tap(find.text('حجاب وشالات'));
      await tester.pumpAndSettle();

      expect(find.text('عرض النتائج (1)'), findsOneWidget);
    });

    testWidgets('the colour swatches are the shared control', (tester) async {
      await open(tester);

      expect(find.byType(ColourSwatch), findsNWidgets(2));
    });
  });

  group('direction and locale', () {
    testWidgets('renders without overflow in ar and en', (tester) async {
      for (final locale in const [Locale('ar'), Locale('en')]) {
        await open(tester, locale: locale);
        // Proves the sheet is actually up. Without this the second pass
        // silently asserted nothing: the first sheet's barrier was still
        // swallowing the tap that opens the second, and "no exception" is
        // trivially true for a sheet that never rendered.
        expect(find.byType(RangeSlider), findsOneWidget);
        expect(tester.takeException(), isNull);

        await tester.tap(find.byIcon(Icons.close));
        await tester.pumpAndSettle();
      }
    });

    testWidgets('the chrome follows the locale', (tester) async {
      await open(tester, locale: const Locale('en'));

      expect(find.text('Filters'), findsOneWidget);
      expect(find.text('Category'), findsOneWidget);
      expect(find.text('Reset'), findsOneWidget);
      expect(find.text('Show results (3)'), findsOneWidget);
    });
  });
}
