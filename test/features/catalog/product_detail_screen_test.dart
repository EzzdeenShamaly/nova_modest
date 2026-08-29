import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nova_modest/core/di/injection.dart';
import 'package:nova_modest/core/error/failure.dart';
import 'package:nova_modest/core/theme/app_colors.dart';
import 'package:nova_modest/core/widgets/failure_view.dart';
import 'package:nova_modest/core/widgets/quantity_stepper.dart';
import 'package:nova_modest/features/cart/presentation/bloc/cart_bloc.dart';
import 'package:nova_modest/features/catalog/domain/entities/product.dart';
import 'package:nova_modest/features/catalog/domain/entities/product_colour.dart';
import 'package:nova_modest/features/catalog/domain/entities/product_feature.dart';
import 'package:nova_modest/features/catalog/presentation/bloc/product_detail_bloc.dart';
import 'package:nova_modest/features/catalog/presentation/screens/product_detail_screen.dart';
import 'package:nova_modest/features/catalog/presentation/widgets/colour_swatch_row.dart';
import 'package:nova_modest/features/catalog/presentation/widgets/product_image_carousel.dart';

import '../../helpers/pump_app.dart';
import '../../helpers/screen_blocs.dart';

class _MockProductDetailBloc
    extends MockBloc<ProductDetailEvent, ProductDetailState>
    implements ProductDetailBloc {}

void main() {
  late _MockProductDetailBloc bloc;
  late MockCartBloc cartBloc;

  const black = ProductColour(id: 'black', name: 'أسود', hex: '#000000');
  const grey = ProductColour(id: 'grey', name: 'رمادي', hex: '#6B7280');

  const product = Product(
    id: 'p2',
    name: 'عباءة سوداء بتفاصيل عصرية',
    price: 520,
    categoryId: 'abayas',
    description: 'عباية كلاسيكية مصممة بعناية',
    colours: [black, grey],
    sizes: ['S', 'M', 'L'],
    features: [
      ProductFeature(text: 'قماش كريب فاخر', icon: 'fabric'),
      ProductFeature(text: 'يفضل الغسيل الجاف', icon: 'care'),
    ],
  );
  const loaded = ProductDetailLoaded(
    product: product,
    selectedColourId: 'black',
    selectedSize: 'S',
  );

  setUpAll(() {
    registerFallbackValue(const ProductDetailRequested('p2'));
    return loadAppFonts();
  });

  setUp(() {
    bloc = _MockProductDetailBloc();
    cartBloc = stubCartBloc();
    if (sl.isRegistered<ProductDetailBloc>()) {
      sl.unregister<ProductDetailBloc>();
    }
    sl.registerFactory<ProductDetailBloc>(() => bloc);
  });

  tearDown(() => sl.unregister<ProductDetailBloc>());

  /// [settle] is off for the loading state: a spinner animates forever. The
  /// state is re-stubbed per pump because `Stream.value` is single-subscription.
  Future<void> pump(
    WidgetTester tester,
    ProductDetailState state, {
    Locale? locale,
    bool settle = true,
  }) async {
    whenListen(
      bloc,
      Stream<ProductDetailState>.value(state),
      initialState: state,
    );
    await tester.pumpApp(
      const ProductDetailScreen(productId: 'p2'),
      cartBloc: cartBloc,
      locale: locale ?? const Locale('ar'),
    );
    if (settle) {
      await tester.pumpAndSettle();
    } else {
      await tester.pump();
    }
  }

  group('states', () {
    testWidgets('loading shows a spinner and no action bar', (tester) async {
      await pump(tester, const ProductDetailLoading(), settle: false);

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byType(QuantityStepper), findsNothing);
    });

    testWidgets('a missing product shows the shared error view with a retry', (
      tester,
    ) async {
      await pump(tester, const ProductDetailError(NotFoundFailure()));

      expect(find.byType(FailureView), findsOneWidget);
      await tester.tap(find.byType(FilledButton));
      await tester.pump();
      verify(() => bloc.add(const ProductDetailRefreshed('p2'))).called(1);
    });

    testWidgets('loaded shows every section', (tester) async {
      await pump(tester, loaded);

      expect(find.byType(ProductImageCarousel), findsOneWidget);
      expect(find.text('عباءة سوداء بتفاصيل عصرية'), findsOneWidget);
      expect(find.byType(ColourSwatchRow), findsOneWidget);
      expect(find.text('اللون'), findsOneWidget);
      expect(find.text('المقاس'), findsOneWidget);
      expect(find.text('التفاصيل'), findsOneWidget);
      expect(find.byType(QuantityStepper), findsOneWidget);
    });
  });

  group('carousel', () {
    testWidgets('with no artwork it shows one page and no indicators', (
      tester,
    ) async {
      // Real photography does not exist yet; one page has nothing to indicate.
      await pump(tester, loaded);

      expect(find.byType(PageView), findsNothing);
    });
  });

  group('colour', () {
    testWidgets('paints the garment colour, not a palette colour', (
      tester,
    ) async {
      await pump(tester, loaded);

      final swatches = tester
          .widgetList<Container>(find.byType(Container))
          .map((c) => c.decoration)
          .whereType<BoxDecoration>()
          .where((d) => d.shape == BoxShape.circle)
          .toList();
      // #6B7280 is the garment's grey — content, so it must render as itself.
      expect(swatches.map((d) => d.color), contains(const Color(0xFF6B7280)));
    });

    testWidgets('tapping a swatch records the choice', (tester) async {
      await pump(tester, loaded);

      // The page is taller than the viewport, so the selector starts below the
      // fold; tapping its off-screen offset would hit nothing and the failure
      // would read as "the widget ignored the tap".
      final swatch = find
          .descendant(
            of: find.byType(ColourSwatchRow),
            matching: find.byType(InkWell),
          )
          .at(1);
      await tester.ensureVisible(swatch);
      await tester.pumpAndSettle();
      await tester.tap(swatch);
      await tester.pump();

      verify(
        () => bloc.add(const ProductDetailColourSelected('grey')),
      ).called(1);
    });
  });

  group('size', () {
    testWidgets('every size is offered and the selected one is inverted', (
      tester,
    ) async {
      await pump(tester, loaded);

      for (final size in ['S', 'M', 'L']) {
        expect(find.text(size), findsOneWidget);
      }
      final selected = tester.widget<Text>(find.text('S'));
      expect(selected.style?.color, AppColors.background);
    });

    testWidgets('tapping a size records the choice', (tester) async {
      await pump(tester, loaded);

      await tester.ensureVisible(find.text('M'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('M'));
      await tester.pump();

      verify(() => bloc.add(const ProductDetailSizeSelected('M'))).called(1);
    });
  });

  group('quantity', () {
    testWidgets('minus is disabled at one', (tester) async {
      await pump(tester, loaded);

      final buttons = tester
          .widgetList<IconButton>(find.byType(IconButton))
          .where((b) => b.icon is Icon)
          .toList();
      final minus = buttons.firstWhere(
        (b) => (b.icon as Icon).icon == Icons.remove,
      );
      expect(minus.onPressed, isNull);
    });

    testWidgets('plus reports the next value', (tester) async {
      await pump(tester, loaded);

      await tester.tap(find.byIcon(Icons.add));
      await tester.pump();

      verify(() => bloc.add(const ProductDetailQuantityChanged(2))).called(1);
    });

    testWidgets('plus is disabled at the ceiling', (tester) async {
      await pump(
        tester,
        const ProductDetailLoaded(
          product: product,
          quantity: ProductDetailBloc.maxQuantity,
        ),
      );

      final plus = tester
          .widgetList<IconButton>(find.byType(IconButton))
          .firstWhere((b) => (b.icon as Icon).icon == Icons.add);
      expect(plus.onPressed, isNull);
    });
  });

  group('add to cart', () {
    testWidgets('sends the whole selection to the cart', (tester) async {
      await pump(tester, loaded);

      await tester.tap(find.text('أضف إلى السلة'));
      await tester.pump();

      // Colour, size and quantity all travel as values. The cart never reads
      // this bloc, which dies with the screen.
      verify(
        () => cartBloc.add(
          const CartItemAdded(product: product, colourId: 'black', size: 'S'),
        ),
      ).called(1);
    });

    testWidgets('confirms, with a way straight to the cart', (tester) async {
      await pump(tester, loaded);

      await tester.tap(find.text('أضف إلى السلة'));
      await tester.pump();

      expect(find.text('تمت الإضافة إلى السلة'), findsOneWidget);
      expect(find.text('عرض السلة'), findsOneWidget);
    });

    testWidgets('is disabled for a sold-out product', (tester) async {
      await pump(
        tester,
        const ProductDetailLoaded(
          product: Product(
            id: 'p6',
            name: 'عباية كتان يومية',
            price: 620,
            categoryId: 'abayas',
            isSoldOut: true,
          ),
        ),
      );

      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNull);
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
        Directionality.of(tester.element(find.byType(ColourSwatchRow))),
        TextDirection.rtl,
      );
    });

    testWidgets('the chrome follows the locale', (tester) async {
      await pump(tester, loaded, locale: const Locale('en'));

      expect(find.text('Add to cart'), findsOneWidget);
      expect(find.text('Colour'), findsOneWidget);
      expect(find.text('Size guide'), findsOneWidget);
    });
  });
}
