import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nova_modest/core/error/failure.dart';
import 'package:nova_modest/core/widgets/failure_view.dart';
import 'package:nova_modest/features/cart/domain/entities/cart_item.dart';
import 'package:nova_modest/features/catalog/domain/entities/product.dart';
import 'package:nova_modest/features/orders/domain/entities/order.dart';
import 'package:nova_modest/features/orders/domain/entities/order_status.dart';
import 'package:nova_modest/features/orders/domain/entities/order_totals.dart';
import 'package:nova_modest/features/orders/presentation/bloc/orders_bloc.dart';
import 'package:nova_modest/features/orders/presentation/screens/orders_screen.dart';

import '../../helpers/pump_app.dart';

class _MockOrdersBloc extends MockBloc<OrdersEvent, OrdersState>
    implements OrdersBloc {}

void main() {
  late _MockOrdersBloc bloc;

  const coat = Product(
    id: 'p1',
    name: 'معطف كلاسيكي خفيف',
    price: 1200,
    categoryId: 'sets',
  );
  const bag = Product(
    id: 'p2',
    name: 'حقيبة يد جلدية',
    price: 520,
    categoryId: 'accessories',
  );

  final oneLine = Order(
    number: 'ORD-260818-0001',
    placedAt: DateTime(2024, 8, 26),
    totals: const OrderTotals(subtotal: 1200, shipping: 35, paymentFee: 15),
    status: OrderStatus.processing,
    items: const [CartItem(product: coat, size: 'M')],
  );

  final threeLines = Order(
    number: 'ORD-150724-0042',
    placedAt: DateTime(2024, 7, 15),
    totals: const OrderTotals(subtotal: 3370, shipping: 35, paymentFee: 15),
    status: OrderStatus.shipped,
    items: const [
      CartItem(product: coat),
      CartItem(product: bag),
      CartItem(product: bag, size: 'S'),
    ],
  );

  final done = Order(
    number: 'ORD-020624-0018',
    placedAt: DateTime(2024, 6, 2),
    totals: const OrderTotals(subtotal: 800, shipping: 35, paymentFee: 15),
    status: OrderStatus.delivered,
    items: const [CartItem(product: bag)],
  );

  setUpAll(loadAppFonts);

  setUp(() => bloc = _MockOrdersBloc());

  /// [settle] is off for the loading state: a spinner animates forever.
  Future<void> pump(
    WidgetTester tester,
    OrdersState state, {
    Locale? locale,
    bool settle = true,
  }) async {
    whenListen(bloc, Stream<OrdersState>.value(state), initialState: state);
    await tester.pumpApp(
      BlocProvider<OrdersBloc>.value(value: bloc, child: const OrdersScreen()),
      locale: locale ?? const Locale('ar'),
    );
    if (settle) {
      await tester.pumpAndSettle();
    } else {
      await tester.pump();
    }
  }

  group('states', () {
    testWidgets('loading shows a spinner and no list', (tester) async {
      await pump(tester, const OrdersLoading(), settle: false);

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('طلباتي'), findsNothing);
    });

    testWidgets('a failed read offers a retry that asks again', (tester) async {
      await pump(tester, const OrdersError(NetworkFailure()));

      expect(find.byType(FailureView), findsOneWidget);

      // The screen dispatches on open through the route, not here, so nothing
      // to clear — but the tap must be the only thing that dispatches.
      await tester.tap(find.byType(FilledButton));
      await tester.pump();

      verify(() => bloc.add(const OrdersRequested())).called(1);
    });

    testWidgets(
      'no history invites browsing instead of showing an empty list',
      (tester) async {
        await pump(tester, const OrdersEmpty());

        expect(find.text('لا توجد طلبات بعد'), findsOneWidget);
        expect(find.text('ابدئي التسوق'), findsOneWidget);
        expect(find.text('طلباتي'), findsNothing);
      },
    );

    testWidgets('a stocked history shows a card per order', (tester) async {
      await pump(tester, OrdersLoaded([oneLine, threeLines, done]));

      expect(find.text('طلباتي'), findsOneWidget);
      expect(find.textContaining('ORD-260818-0001'), findsOneWidget);
      expect(find.textContaining('ORD-150724-0042'), findsOneWidget);
      expect(find.textContaining('ORD-020624-0018'), findsOneWidget);
    });
  });

  group('a card', () {
    testWidgets('shows the date and what the order came to', (tester) async {
      await pump(tester, OrdersLoaded([oneLine]));

      // 1200 + 35 shipping + 15 cash fee.
      expect(find.textContaining('1,250'), findsOneWidget);
      // Formatted by intl for the locale, not assembled from parts.
      expect(find.textContaining('2024'), findsOneWidget);
    });

    testWidgets('counts the lines its one thumbnail does not show', (
      tester,
    ) async {
      await pump(tester, OrdersLoaded([threeLines, oneLine]));

      // Three lines, one picture, so "+2" — and nothing on the single-line one.
      expect(find.text('+2'), findsOneWidget);
    });

    testWidgets('opens its own details', (tester) async {
      await pump(tester, OrdersLoaded([oneLine]));

      final inkWell = tester.widget<InkWell>(find.byType(InkWell).first);
      // Where it goes is a router property, asserted in
      // `test/router/orders_routes_test.dart`; that it goes anywhere at all is
      // this screen's.
      expect(inkWell.onTap, isNotNull);
    });
  });

  group('the status badge', () {
    testWidgets('names each stage rather than relying on its colour', (
      tester,
    ) async {
      await pump(tester, OrdersLoaded([oneLine, threeLines, done]));

      expect(find.text('قيد التحضير'), findsOneWidget);
      expect(find.text('تم الشحن'), findsOneWidget);
      // The list frame writes the short form; the details tracker writes
      // "تم التوصيل" for the same stage.
      expect(find.text('مكتمل'), findsOneWidget);
    });
  });

  group('the count beside the heading', () {
    testWidgets('uses the Arabic dual, which a ternary cannot express', (
      tester,
    ) async {
      await pump(tester, OrdersLoaded([oneLine, threeLines]));

      expect(find.text('طلبان'), findsOneWidget);
    });

    testWidgets('and the singular', (tester) async {
      await pump(tester, OrdersLoaded([oneLine]));

      expect(find.text('طلب واحد'), findsOneWidget);
    });

    testWidgets('and the plural band above two', (tester) async {
      await pump(tester, OrdersLoaded([oneLine, threeLines, done]));

      expect(find.text('3 طلبات'), findsOneWidget);
    });
  });

  group('direction and locale', () {
    testWidgets('renders without overflow in ar and en', (tester) async {
      for (final locale in const [Locale('ar'), Locale('en')]) {
        await pump(
          tester,
          OrdersLoaded([oneLine, threeLines, done]),
          locale: locale,
        );
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('the chrome follows the locale', (tester) async {
      await pump(tester, OrdersLoaded([oneLine]), locale: const Locale('en'));

      expect(find.text('My orders'), findsOneWidget);
      expect(find.text('1 order'), findsOneWidget);
      expect(find.text('Processing'), findsOneWidget);
    });

    testWidgets('lays out RTL under Arabic', (tester) async {
      await pump(tester, OrdersLoaded([oneLine]));

      expect(
        Directionality.of(tester.element(find.byType(OrdersScreen))),
        TextDirection.rtl,
      );
    });
  });
}
