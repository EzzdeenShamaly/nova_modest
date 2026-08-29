import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nova_modest/core/di/injection.dart';
import 'package:nova_modest/core/error/failure.dart';
import 'package:nova_modest/core/widgets/failure_view.dart';
import 'package:nova_modest/features/catalog/domain/entities/product.dart';
import 'package:nova_modest/features/catalog/domain/entities/product_filter.dart';
import 'package:nova_modest/features/catalog/domain/entities/product_tag.dart';
import 'package:nova_modest/features/catalog/presentation/bloc/product_list_bloc.dart';
import 'package:nova_modest/features/catalog/presentation/screens/product_list_screen.dart';
import 'package:nova_modest/features/catalog/presentation/widgets/filter_chip_row.dart';
import 'package:nova_modest/features/catalog/presentation/widgets/product_card.dart';

import '../../helpers/pump_app.dart';

class _MockProductListBloc extends MockBloc<ProductListEvent, ProductListState>
    implements ProductListBloc {}

void main() {
  late _MockProductListBloc bloc;

  const daily = ProductTag(id: 'daily', name: 'يومي');
  const occasions = ProductTag(id: 'occasions', name: 'مناسبات');

  const soldOut = Product(
    id: 'p1',
    name: 'عباية كتان يومية',
    price: 620,
    categoryId: 'abayas',
    isSoldOut: true,
    tags: [daily],
  );
  const available = Product(
    id: 'p2',
    name: 'عباية رسمية كحلية',
    price: 950,
    categoryId: 'abayas',
    tags: [occasions],
  );
  const loaded = ProductListLoaded(
    categoryId: 'abayas',
    categoryName: 'عبايات',
    products: [soldOut, available],
  );

  setUpAll(() {
    registerFallbackValue(const ProductListRequested('abayas'));
    return loadAppFonts();
  });

  setUp(() {
    bloc = _MockProductListBloc();
    if (sl.isRegistered<ProductListBloc>()) sl.unregister<ProductListBloc>();
    sl.registerFactory<ProductListBloc>(() => bloc);
  });

  tearDown(() => sl.unregister<ProductListBloc>());

  /// [settle] is off for the loading state: a spinner animates forever, so
  /// `pumpAndSettle` would time out instead of asserting. The state is re-stubbed
  /// before every pump because `Stream.value` is single-subscription.
  Future<void> pump(
    WidgetTester tester,
    ProductListState state, {
    Locale? locale,
    bool settle = true,
  }) async {
    whenListen(
      bloc,
      Stream<ProductListState>.value(state),
      initialState: state,
    );
    await tester.pumpApp(
      const ProductListScreen(categoryId: 'abayas'),
      locale: locale ?? const Locale('ar'),
    );
    if (settle) {
      await tester.pumpAndSettle();
    } else {
      await tester.pump();
    }
  }

  group('the four states each render', () {
    testWidgets('loading shows a spinner and no grid', (tester) async {
      await pump(tester, const ProductListLoading(), settle: false);

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byType(ProductCard), findsNothing);
    });

    testWidgets('error shows the shared view with a working retry', (
      tester,
    ) async {
      await pump(tester, const ProductListError(NetworkFailure()));

      expect(find.byType(FailureView), findsOneWidget);
      await tester.tap(find.byType(FilledButton));
      await tester.pump();
      verify(() => bloc.add(const ProductListRefreshed('abayas'))).called(1);
    });

    testWidgets('empty shows its own message, not an empty grid', (
      tester,
    ) async {
      await pump(tester, const ProductListEmpty(categoryName: 'عبايات'));

      expect(find.text('لا توجد منتجات في هذه الفئة'), findsOneWidget);
      expect(find.byType(ProductCard), findsNothing);
      expect(find.byType(FilterChipRow), findsNothing);
    });

    testWidgets('loaded shows the chips and the grid', (tester) async {
      await pump(tester, loaded);

      expect(find.byType(FilterChipRow), findsOneWidget);
      expect(find.byType(ProductCard), findsNWidgets(2));
      expect(find.text('عباية رسمية كحلية'), findsOneWidget);
    });
  });

  group('title', () {
    testWidgets('uses the category name from the catalogue', (tester) async {
      await pump(tester, loaded);

      expect(find.text('عبايات'), findsOneWidget);
    });

    testWidgets('falls back to the id before the catalogue answers', (
      tester,
    ) async {
      // Better a raw id for a moment than an invented label.
      await pump(tester, const ProductListLoading(), settle: false);

      expect(find.text('abayas'), findsOneWidget);
    });
  });

  group('sold out', () {
    testWidgets('is badged and loses its favourite control', (tester) async {
      final semantics = tester.ensureSemantics();

      await pump(tester, loaded);

      expect(find.text('نفد من المخزن'), findsOneWidget);
      // Two products, but only the available one offers a favourite button.
      expect(find.bySemanticsLabel('إضافة للمفضلة'), findsOneWidget);
      semantics.dispose();
    });

    testWidgets('does not respond to a tap', (tester) async {
      await pump(tester, loaded);

      // Asserted on the InkWell, not on ProductCard.onTap: the screen now hands
      // every card a handler and the card itself refuses it when the product is
      // sold out. Checking the parameter passed *in* would pass for the wrong
      // reason — and did, until the detail screen gave it something to pass.
      final soldOutCard = find.ancestor(
        of: find.text('عباية كتان يومية'),
        matching: find.byType(ProductCard),
      );
      final inkWell = tester.widget<InkWell>(
        find.descendant(of: soldOutCard, matching: find.byType(InkWell)).first,
      );
      // Opening a page you cannot buy from is worse than no tap at all.
      expect(inkWell.onTap, isNull);
    });
  });

  group('tag filter', () {
    testWidgets('offers the tags present in this category', (tester) async {
      await pump(tester, loaded);

      expect(find.text('يومي'), findsOneWidget);
      expect(find.text('مناسبات'), findsOneWidget);
      expect(find.text('الكل'), findsOneWidget);
    });

    testWidgets('tapping a tag dispatches the selection', (tester) async {
      await pump(tester, loaded);
      await tester.tap(find.text('يومي'));
      await tester.pump();

      verify(() => bloc.add(const ProductListTagSelected('daily'))).called(1);
    });

    testWidgets('a selected tag narrows the grid', (tester) async {
      await pump(
        tester,
        const ProductListLoaded(
          categoryId: 'abayas',
          categoryName: 'عبايات',
          products: [soldOut, available],
          filter: ProductFilter(tagId: 'daily'),
        ),
      );

      expect(find.byType(ProductCard), findsOneWidget);
      expect(find.text('عباية كتان يومية'), findsOneWidget);
    });

    testWidgets('an empty filter keeps the chips reachable', (tester) async {
      await pump(
        tester,
        const ProductListLoaded(
          categoryId: 'abayas',
          categoryName: 'عبايات',
          products: [available],
          filter: ProductFilter(tagId: 'daily'),
        ),
      );

      expect(find.text('لا توجد منتجات بهذا الفلتر'), findsOneWidget);
      expect(find.byType(FilterChipRow), findsOneWidget);
      expect(find.byType(ProductCard), findsNothing);
    });
  });

  group('direction and locale', () {
    testWidgets('renders without overflow in ar and en', (tester) async {
      for (final locale in const [Locale('ar'), Locale('en')]) {
        await pump(tester, loaded, locale: locale);
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('lays out RTL under Arabic', (tester) async {
      await pump(tester, loaded);

      expect(
        Directionality.of(tester.element(find.byType(FilterChipRow))),
        TextDirection.rtl,
      );
    });

    testWidgets('the chrome follows the locale', (tester) async {
      await pump(tester, loaded, locale: const Locale('en'));

      expect(find.text('Sold out'), findsOneWidget);
      expect(find.text('All'), findsOneWidget);
    });
  });
}
