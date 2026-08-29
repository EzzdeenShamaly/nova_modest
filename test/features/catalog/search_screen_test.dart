import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nova_modest/core/di/injection.dart';
import 'package:nova_modest/core/error/failure.dart';
import 'package:nova_modest/core/widgets/failure_view.dart';
import 'package:nova_modest/features/catalog/domain/entities/product.dart';
import 'package:nova_modest/features/catalog/domain/entities/product_category.dart';
import 'package:nova_modest/features/catalog/domain/entities/product_filter.dart';
import 'package:nova_modest/features/catalog/domain/entities/product_sort.dart';
import 'package:nova_modest/features/catalog/presentation/bloc/search_bloc.dart';
import 'package:nova_modest/features/catalog/presentation/screens/search_screen.dart';
import 'package:nova_modest/features/catalog/presentation/widgets/category_discovery_grid.dart';
import 'package:nova_modest/features/catalog/presentation/widgets/product_card.dart';
import 'package:nova_modest/features/catalog/presentation/widgets/search_field.dart';
import 'package:nova_modest/features/catalog/presentation/widgets/search_term_chips.dart';

import '../../helpers/pump_app.dart';

class _MockSearchBloc extends MockBloc<SearchEvent, SearchState>
    implements SearchBloc {}

void main() {
  late _MockSearchBloc bloc;

  const abaya = Product(
    id: 'p1',
    name: 'عباية كتان يومية',
    price: 450,
    categoryId: 'abayas',
    sizes: ['S', 'M'],
  );
  const gown = Product(
    id: 'p2',
    name: 'عباية رسمية كحلية',
    price: 950,
    categoryId: 'abayas',
    sizes: ['L'],
  );

  const categories = [
    ProductCategory(id: 'abayas', name: 'عبايات'),
    ProductCategory(id: 'sets', name: 'أطقم'),
  ];

  const idle = SearchIdle(
    history: ['وشاح', 'عباية'],
    trending: ['عبايات', 'مناسبات'],
    categories: categories,
  );

  const results = SearchResults(
    query: 'عباية',
    products: [abaya, gown],
    categories: categories,
  );

  setUpAll(() {
    registerFallbackValue(const SearchOpened());
    return loadAppFonts();
  });

  setUp(() {
    bloc = _MockSearchBloc();
    if (sl.isRegistered<SearchBloc>()) sl.unregister<SearchBloc>();
    sl.registerFactory<SearchBloc>(() => bloc);
  });

  tearDown(() => sl.unregister<SearchBloc>());

  /// [settle] is off for the loading state: a spinner animates forever. The
  /// state is re-stubbed per pump because `Stream.value` is single-subscription.
  Future<void> pump(
    WidgetTester tester,
    SearchState state, {
    Locale? locale,
    bool settle = true,
  }) async {
    whenListen(bloc, Stream<SearchState>.value(state), initialState: state);
    // A fresh key on every pump. Without it Flutter reuses the element, the
    // BlocProvider never re-runs `create`, and a second pump in one test
    // silently keeps showing the first state — which is how "renders in ar and
    // en" would have asserted Arabic twice.
    await tester.pumpApp(
      SearchScreen(key: UniqueKey()),
      locale: locale ?? const Locale('ar'),
    );
    if (settle) {
      await tester.pumpAndSettle();
    } else {
      await tester.pump();
    }
  }

  group('states', () {
    testWidgets('loading shows a spinner', (tester) async {
      await pump(tester, const SearchLoading(), settle: false);

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('a failure shows the shared error view with a retry', (
      tester,
    ) async {
      await pump(tester, const SearchError(NetworkFailure()));

      expect(find.byType(FailureView), findsOneWidget);
      // The screen dispatches SearchOpened on create; clear that so the count
      // below is the retry itself.
      clearInteractions(bloc);
      await tester.tap(find.byType(FilledButton));
      await tester.pump();
      verify(() => bloc.add(const SearchOpened())).called(1);
    });

    testWidgets('idle shows discovery content, not a no-results message', (
      tester,
    ) async {
      await pump(tester, idle);

      expect(find.text('عمليات بحث سابقة'), findsOneWidget);
      expect(find.text('الأكثر بحثاً'), findsOneWidget);
      expect(find.text('استكشفي الفئات'), findsOneWidget);
      expect(find.text('لا توجد نتائج'), findsNothing);
    });

    testWidgets('a query that matched nothing names what was searched for', (
      tester,
    ) async {
      await pump(tester, const SearchEmpty('حذاء رياضي'));

      expect(find.text('لا توجد نتائج'), findsOneWidget);
      expect(find.textContaining('حذاء رياضي'), findsOneWidget);
      expect(find.byType(ProductCard), findsNothing);
    });

    testWidgets('results show the count, the sort control and the grid', (
      tester,
    ) async {
      await pump(tester, results);

      expect(find.textContaining('عباية'), findsWidgets);
      expect(find.text('ترتيب'), findsOneWidget);
      expect(find.byType(ProductCard), findsNWidgets(2));
    });
  });

  group('the discovery screen', () {
    testWidgets('an empty history draws no heading over nothing', (
      tester,
    ) async {
      // First launch: the history is necessarily empty, and a heading over an
      // empty wrap is three lines of nothing.
      await pump(
        tester,
        const SearchIdle(trending: ['عبايات'], categories: categories),
      );

      expect(find.text('عمليات بحث سابقة'), findsNothing);
      expect(find.text('الأكثر بحثاً'), findsOneWidget);
    });

    testWidgets('tapping a recent term searches for it', (tester) async {
      await pump(tester, idle);

      await tester.tap(find.text('وشاح'));
      await tester.pump();

      verify(() => bloc.add(const SearchSubmitted('وشاح'))).called(1);
    });

    testWidgets('the term also lands in the field', (tester) async {
      await pump(tester, idle);

      await tester.tap(find.text('وشاح'));
      await tester.pump();

      expect(find.widgetWithText(TextField, 'وشاح'), findsOneWidget);
    });

    testWidgets('a recent term can be forgotten', (tester) async {
      await pump(tester, idle);

      final remove = find
          .descendant(
            of: find.byType(SearchTermChips).first,
            matching: find.byIcon(Icons.close),
          )
          .first;
      await tester.tap(remove);
      await tester.pump();

      verify(() => bloc.add(const SearchHistoryEntryRemoved('وشاح'))).called(1);
    });

    testWidgets('trending terms are offered but cannot be removed', (
      tester,
    ) async {
      await pump(tester, idle);

      final chipRows = tester.widgetList<SearchTermChips>(
        find.byType(SearchTermChips),
      );
      expect(chipRows, hasLength(2));
      expect(chipRows.first.onRemoved, isNotNull);
      expect(chipRows.last.onRemoved, isNull);
    });

    testWidgets('clear all empties the history', (tester) async {
      await pump(tester, idle);

      await tester.tap(find.text('مسح الكل'));
      await tester.pump();

      verify(() => bloc.add(const SearchHistoryCleared())).called(1);
    });

    testWidgets('every category is offered to browse', (tester) async {
      await pump(tester, idle);

      expect(find.byType(CategoryDiscoveryGrid), findsOneWidget);
      expect(find.text('عبايات'), findsWidgets);
    });
  });

  group('the field', () {
    testWidgets('typing reports every keystroke; the bloc debounces', (
      tester,
    ) async {
      await pump(tester, idle);

      await tester.enterText(find.byType(TextField), 'عب');
      await tester.pump();

      verify(() => bloc.add(const SearchQueryChanged('عب'))).called(1);
    });

    testWidgets('clearing empties the field and returns to discovery', (
      tester,
    ) async {
      await pump(tester, results);

      await tester.enterText(find.byType(TextField), 'عباية');
      await tester.pump();
      await tester.tap(find.byIcon(Icons.close));
      await tester.pump();

      verify(() => bloc.add(const SearchCleared())).called(1);
      expect(find.widgetWithText(TextField, 'عباية'), findsNothing);
    });

    testWidgets('the clear control only appears once there is text', (
      tester,
    ) async {
      await pump(tester, idle);

      // Scoped to the field: the recent-search chips carry their own close
      // marks, so a bare byIcon would count those too.
      Finder clearControl() => find.descendant(
        of: find.byType(SearchField),
        matching: find.byIcon(Icons.close),
      );

      expect(clearControl(), findsNothing);

      await tester.enterText(find.byType(TextField), 'ع');
      await tester.pump();

      expect(clearControl(), findsOneWidget);
    });
  });

  group('narrowing', () {
    testWidgets('the filter button is absent while browsing', (tester) async {
      // The browsing frame has no filter button because there is nothing yet
      // to narrow.
      await pump(tester, idle);

      expect(find.byIcon(Icons.tune), findsNothing);
    });

    testWidgets('the filter button appears with results', (tester) async {
      await pump(tester, results);

      expect(find.byIcon(Icons.tune), findsOneWidget);
    });

    testWidgets('the filter sheet applies back into the bloc', (tester) async {
      await pump(tester, results);

      await tester.tap(find.byIcon(Icons.tune));
      await tester.pumpAndSettle();
      await tester.tap(find.text('L'));
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('عرض النتائج'));
      await tester.pumpAndSettle();

      verify(
        () => bloc.add(const SearchFilterChanged(ProductFilter(sizes: {'L'}))),
      ).called(1);
    });

    testWidgets('dismissing the filter sheet changes nothing', (tester) async {
      await pump(tester, results);

      await tester.tap(find.byIcon(Icons.tune));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      // Dismissed is not "applied nothing": the results must be left alone.
      verifyNever(() => bloc.add(any(that: isA<SearchFilterChanged>())));
    });

    testWidgets('the sort sheet reports the chosen order', (tester) async {
      await pump(tester, results);

      await tester.tap(find.text('ترتيب'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('السعر: من الأقل'));
      await tester.pumpAndSettle();

      verify(
        () => bloc.add(const SearchSortChanged(ProductSort.priceAscending)),
      ).called(1);
    });

    testWidgets('a filter covering nothing keeps the controls reachable', (
      tester,
    ) async {
      await pump(
        tester,
        const SearchResults(
          query: 'عباية',
          products: [abaya, gown],
          categories: categories,
          filter: ProductFilter(sizes: {'XXL'}),
        ),
      );

      expect(find.text('لا توجد نتائج بهذه الفلاتر'), findsOneWidget);
      // Not the no-results screen: the filter button has to stay or the
      // shopper cannot widen it again.
      expect(find.byIcon(Icons.tune), findsOneWidget);
      expect(find.text('ترتيب'), findsOneWidget);
    });
  });

  group('direction and locale', () {
    testWidgets('renders without overflow in ar and en', (tester) async {
      for (final state in const <SearchState>[idle, results]) {
        for (final locale in const [Locale('ar'), Locale('en')]) {
          await pump(tester, state, locale: locale);
          expect(tester.takeException(), isNull);
        }
      }
    });

    testWidgets('the chrome follows the locale', (tester) async {
      await pump(tester, idle, locale: const Locale('en'));

      expect(find.text('Recent searches'), findsOneWidget);
      expect(find.text('Trending'), findsOneWidget);
      expect(find.text('Explore categories'), findsOneWidget);
    });

    testWidgets('the result count is an ICU plural, not a ternary', (
      tester,
    ) async {
      await pump(tester, results, locale: const Locale('en'));
      expect(find.textContaining('2 results'), findsOneWidget);

      await pump(
        tester,
        const SearchResults(
          query: 'عباية',
          products: [abaya],
          categories: categories,
        ),
        locale: const Locale('en'),
      );
      expect(find.textContaining('1 result for'), findsOneWidget);
    });
  });
}
