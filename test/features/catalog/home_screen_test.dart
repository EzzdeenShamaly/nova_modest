import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nova_modest/core/di/injection.dart';
import 'package:nova_modest/core/error/failure.dart';
import 'package:nova_modest/core/theme/app_colors.dart';
import 'package:nova_modest/core/widgets/failure_view.dart';
import 'package:nova_modest/features/catalog/domain/entities/product.dart';
import 'package:nova_modest/features/catalog/domain/entities/product_category.dart';
import 'package:nova_modest/features/catalog/presentation/bloc/home_bloc.dart';
import 'package:nova_modest/features/catalog/presentation/screens/home_screen.dart';
import 'package:nova_modest/features/catalog/presentation/widgets/filter_chip_row.dart';
import 'package:nova_modest/features/catalog/presentation/widgets/home_hero_banner.dart';
import 'package:nova_modest/features/catalog/presentation/widgets/product_card.dart';

import '../../helpers/pump_app.dart';

class _MockHomeBloc extends MockBloc<HomeEvent, HomeState>
    implements HomeBloc {}

void main() {
  late _MockHomeBloc bloc;

  const categories = [
    ProductCategory(id: 'abayas', name: 'عبايات'),
    ProductCategory(id: 'sets', name: 'أطقم'),
  ];
  const abaya = Product(
    id: 'p1',
    name: 'عباءة كلاسيكية',
    price: 450,
    categoryId: 'abayas',
  );
  const set = Product(
    id: 'p2',
    name: 'طقم مريح',
    price: 380,
    categoryId: 'sets',
  );
  const loaded = HomeLoaded(categories: categories, products: [abaya, set]);

  setUpAll(() {
    registerFallbackValue(const HomeRequested());
    return loadAppFonts();
  });

  setUp(() {
    bloc = _MockHomeBloc();
    if (sl.isRegistered<HomeBloc>()) sl.unregister<HomeBloc>();
    sl.registerFactory<HomeBloc>(() => bloc);
  });

  tearDown(() => sl.unregister<HomeBloc>());

  /// Re-stubs before every pump on purpose. `Stream.value` is
  /// single-subscription, so a second `pumpApp` builds a second BlocProvider
  /// that tries to listen again and the bloc's state comes back null — a
  /// confusing `type 'Null' is not a subtype of type 'HomeState'` far from its
  /// cause.
  void withState(HomeState state) =>
      whenListen(bloc, Stream<HomeState>.value(state), initialState: state);

  /// [settle] is off for the loading state: a spinner animates forever, so
  /// `pumpAndSettle` would time out instead of asserting.
  Future<void> pump(
    WidgetTester tester,
    HomeState state, {
    Locale? locale,
    bool settle = true,
  }) async {
    withState(state);
    await tester.pumpApp(
      const HomeScreen(),
      locale: locale ?? const Locale('ar'),
    );
    if (settle) {
      await tester.pumpAndSettle();
    } else {
      await tester.pump();
    }
  }

  group('the four states each render', () {
    testWidgets('loading shows a spinner and nothing else', (tester) async {
      await pump(tester, const HomeLoading(), settle: false);

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byType(ProductCard), findsNothing);
    });

    testWidgets('error shows the shared view with a working retry', (
      tester,
    ) async {
      await pump(tester, const HomeError(NetworkFailure()));

      expect(find.byType(FailureView), findsOneWidget);
      await tester.tap(find.byType(FilledButton));
      await tester.pump();
      verify(() => bloc.add(const HomeRefreshed())).called(1);
    });

    testWidgets('empty shows its own message, not an empty grid', (
      tester,
    ) async {
      await pump(tester, const HomeEmpty());

      expect(find.text('لا توجد منتجات بعد'), findsOneWidget);
      expect(find.byType(ProductCard), findsNothing);
      expect(find.byType(FilterChipRow), findsNothing);
    });

    testWidgets('loaded shows the banner, the chips and the grid', (
      tester,
    ) async {
      await pump(tester, loaded);

      expect(find.byType(HomeHeroBanner), findsOneWidget);
      expect(find.byType(FilterChipRow), findsOneWidget);
      expect(find.byType(ProductCard), findsNWidgets(2));
      expect(find.text('عباءة كلاسيكية'), findsOneWidget);
    });
  });

  group('category filter', () {
    testWidgets('the All chip leads, before the backend categories', (
      tester,
    ) async {
      await pump(tester, loaded);

      expect(find.text('الكل'), findsOneWidget);
      expect(find.text('عبايات'), findsOneWidget);
      expect(find.text('أطقم'), findsOneWidget);
    });

    testWidgets('tapping a chip dispatches the selection', (tester) async {
      await pump(tester, loaded);
      await tester.tap(find.text('عبايات'));
      await tester.pump();

      verify(() => bloc.add(const HomeCategorySelected('abayas'))).called(1);
    });

    testWidgets('the All chip clears the selection', (tester) async {
      await pump(
        tester,
        const HomeLoaded(
          categories: categories,
          products: [abaya, set],
          selectedCategoryId: 'abayas',
        ),
      );
      await tester.tap(find.text('الكل'));
      await tester.pump();

      verify(() => bloc.add(const HomeCategorySelected(null))).called(1);
    });

    testWidgets('a selected filter narrows the grid', (tester) async {
      await pump(
        tester,
        const HomeLoaded(
          categories: categories,
          products: [abaya, set],
          selectedCategoryId: 'abayas',
        ),
      );

      expect(find.byType(ProductCard), findsOneWidget);
      expect(find.text('عباءة كلاسيكية'), findsOneWidget);
      expect(find.text('طقم مريح'), findsNothing);
    });

    testWidgets('an empty filter keeps the chips reachable', (tester) async {
      // The distinction that matters: this is not HomeEmpty, so the user can
      // still pick another category instead of being stranded.
      await pump(
        tester,
        const HomeLoaded(
          categories: categories,
          products: [abaya],
          selectedCategoryId: 'sets',
        ),
      );

      expect(find.text('لا توجد منتجات في هذه الفئة'), findsOneWidget);
      expect(find.byType(FilterChipRow), findsOneWidget);
      expect(find.byType(ProductCard), findsNothing);
    });
  });

  group('product card', () {
    testWidgets('prices carry the accent colour and the currency', (
      tester,
    ) async {
      await pump(tester, loaded);

      final price = tester.widget<Text>(find.textContaining('ر.س').first);
      expect(price.style?.color, AppColors.accent);
    });

    testWidgets('prices place the currency symbol per locale', (tester) async {
      // intl does NOT substitute Arabic-Indic digits for `ar` — CLDR's default
      // numbering there is Latin, and commerce in the Gulf follows it. What it
      // does do is flip the symbol to the trailing side and emit a direction
      // mark, which is the part worth pinning.
      await pump(tester, loaded);
      final arabic = tester
          .widget<Text>(find.textContaining('ر.س').first)
          .data!;
      expect(arabic.trimRight(), endsWith('ر.س'));
      expect(arabic, contains('450'));

      await pump(tester, loaded, locale: const Locale('en'));
      final english = tester
          .widget<Text>(find.textContaining('SAR').first)
          .data!;
      expect(english.trimLeft(), startsWith('SAR'));
    });

    testWidgets('the favourite control is exposed to a screen reader', (
      tester,
    ) async {
      // The semantics tree is not built unless a test asks for it, so without
      // this handle the assertion below would pass vacuously on an empty tree.
      final semantics = tester.ensureSemantics();
      await pump(tester, loaded);

      expect(find.bySemanticsLabel('إضافة للمفضلة'), findsNWidgets(2));
      semantics.dispose();
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

    testWidgets('the copy follows the locale', (tester) async {
      withState(loaded);

      await pump(tester, loaded, locale: const Locale('en'));

      expect(find.text('Featured'), findsOneWidget);
      expect(find.text('See all'), findsOneWidget);
      expect(find.text('All'), findsOneWidget);
    });
  });
}
