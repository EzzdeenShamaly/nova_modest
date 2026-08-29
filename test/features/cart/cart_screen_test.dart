import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nova_modest/core/error/failure.dart';
import 'package:nova_modest/core/widgets/failure_view.dart';
import 'package:nova_modest/core/widgets/quantity_stepper.dart';
import 'package:nova_modest/features/cart/domain/entities/cart_item.dart';
import 'package:nova_modest/features/cart/domain/entities/cart_totals.dart';
import 'package:nova_modest/features/cart/presentation/bloc/cart_bloc.dart';
import 'package:nova_modest/features/cart/presentation/screens/cart_screen.dart';
import 'package:nova_modest/features/cart/presentation/widgets/cart_item_tile.dart';
import 'package:nova_modest/features/cart/presentation/widgets/cart_summary.dart';
import 'package:nova_modest/features/catalog/domain/entities/product.dart';
import 'package:nova_modest/features/catalog/domain/entities/product_colour.dart';

import '../../helpers/pump_app.dart';
import '../../helpers/screen_blocs.dart';

void main() {
  late MockCartBloc bloc;

  const sand = ProductColour(id: 'sand', name: 'رملي', hex: '#D9C7A8');

  const dress = Product(
    id: 'p1',
    name: 'فستان كتان رملي',
    price: 450,
    categoryId: 'sets',
    colours: [sand],
    sizes: ['S', 'M', 'L'],
  );
  const scarf = Product(
    id: 'p3',
    name: 'وشاح حرير زيتوني',
    price: 120,
    categoryId: 'hijab-shawls',
  );

  const dressLine = CartItem(product: dress, colourId: 'sand', size: 'M');
  const scarfLine = CartItem(product: scarf, quantity: 2);

  final loaded = CartLoaded(
    items: const [dressLine, scarfLine],
    totals: CartTotals.of(const [dressLine, scarfLine]),
  );

  setUpAll(loadAppFonts);

  setUp(() => bloc = MockCartBloc());

  /// [settle] is off for the loading state: a spinner animates forever. The
  /// state is re-stubbed per pump because `Stream.value` is single-subscription.
  Future<void> pump(
    WidgetTester tester,
    CartState state, {
    Locale? locale,
    bool settle = true,
  }) async {
    whenListen(bloc, Stream<CartState>.value(state), initialState: state);
    await tester.pumpApp(
      const CartScreen(),
      cartBloc: bloc,
      locale: locale ?? const Locale('ar'),
    );
    if (settle) {
      await tester.pumpAndSettle();
    } else {
      await tester.pump();
    }
  }

  group('states', () {
    testWidgets('loading shows a spinner and no checkout bar', (tester) async {
      await pump(tester, const CartLoading(), settle: false);

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('متابعة الدفع'), findsNothing);
    });

    testWidgets('a failed read shows the shared error view with a retry', (
      tester,
    ) async {
      await pump(tester, const CartError(CacheFailure()));

      expect(find.byType(FailureView), findsOneWidget);
      await tester.tap(find.byType(FilledButton));
      await tester.pump();
      verify(() => bloc.add(const CartRequested())).called(1);
    });

    testWidgets('empty invites browsing instead of showing an empty list', (
      tester,
    ) async {
      await pump(tester, const CartEmpty());

      expect(find.text('سلتك فارغة'), findsOneWidget);
      expect(find.text('تسوّقي الآن'), findsOneWidget);
      expect(find.byType(CartItemTile), findsNothing);
      // No summary and no checkout: there is nothing to total or to pay for.
      expect(find.byType(CartSummary), findsNothing);
      expect(find.text('متابعة الدفع'), findsNothing);
    });

    testWidgets('loaded shows a line per item, the summary and the bar', (
      tester,
    ) async {
      await pump(tester, loaded);

      expect(find.byType(CartItemTile), findsNWidgets(2));
      expect(find.text('فستان كتان رملي'), findsOneWidget);
      expect(find.byType(CartSummary), findsOneWidget);
      expect(find.text('متابعة الدفع'), findsOneWidget);
    });
  });

  group('a cart line', () {
    testWidgets('names the colour and size that were chosen', (tester) async {
      await pump(tester, loaded);

      expect(find.text('اللون: رملي | المقاس: M'), findsOneWidget);
    });

    testWidgets('shows no choices line for a product that offers none', (
      tester,
    ) async {
      await pump(tester, loaded);

      // The scarf has neither colours nor sizes; a bare "Colour: | Size:" would
      // be worse than nothing.
      expect(find.textContaining('اللون:', findRichText: true), findsOneWidget);
    });

    testWidgets('prices the line, not the unit', (tester) async {
      await pump(tester, loaded);

      // Two scarves at 120.
      expect(find.textContaining('240'), findsOneWidget);
    });

    testWidgets('the stepper reports the new quantity', (tester) async {
      await pump(tester, loaded);

      final plus = find
          .descendant(
            of: find.byType(CartItemTile).first,
            matching: find.byIcon(Icons.add),
          )
          .first;
      await tester.ensureVisible(plus);
      await tester.pumpAndSettle();
      await tester.tap(plus);
      await tester.pump();

      verify(
        () => bloc.add(const CartQuantityChanged('p1|sand|M', 2)),
      ).called(1);
    });

    testWidgets('the close button removes that line', (tester) async {
      await pump(tester, loaded);

      final close = find
          .descendant(
            of: find.byType(CartItemTile).first,
            matching: find.byIcon(Icons.close),
          )
          .first;
      await tester.ensureVisible(close);
      await tester.pumpAndSettle();
      await tester.tap(close);
      await tester.pump();

      verify(() => bloc.add(const CartItemRemoved('p1|sand|M'))).called(1);
    });
  });

  group('the summary', () {
    testWidgets('shows subtotal, shipping and total', (tester) async {
      await pump(tester, loaded);

      expect(find.text('المجموع الفرعي'), findsOneWidget);
      expect(find.text('الشحن'), findsOneWidget);
      expect(find.text('الإجمالي'), findsOneWidget);
      // 450 + 240 = 690, plus 35 shipping — the same 35 checkout charges.
      expect(find.textContaining('690'), findsOneWidget);
      expect(find.textContaining('725'), findsOneWidget);
    });
  });

  group('checkout', () {
    testWidgets('leads somewhere now that the flow exists', (tester) async {
      // Disabled from the day the cart was built until checkout had a route.
      await pump(tester, loaded);

      final button = tester.widget<FilledButton>(
        find.ancestor(
          of: find.text('متابعة الدفع'),
          matching: find.byType(FilledButton),
        ),
      );
      expect(button.onPressed, isNotNull);
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
        Directionality.of(tester.element(find.byType(CartSummary))),
        TextDirection.rtl,
      );
    });

    testWidgets('the chrome follows the locale', (tester) async {
      await pump(tester, loaded, locale: const Locale('en'));

      expect(find.text('Cart'), findsOneWidget);
      expect(find.text('Subtotal'), findsOneWidget);
      expect(find.text('Proceed to checkout'), findsOneWidget);
      expect(find.text('Colour: رملي | Size: M'), findsOneWidget);
    });
  });

  group('the stepper is the shared control', () {
    testWidgets('drawn in its outlined variant here', (tester) async {
      await pump(tester, loaded);

      final steppers = tester.widgetList<QuantityStepper>(
        find.byType(QuantityStepper),
      );
      expect(steppers, hasLength(2));
      expect(
        steppers.every((s) => s.variant == QuantityStepperVariant.outlined),
        isTrue,
      );
    });
  });
}
