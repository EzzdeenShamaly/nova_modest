import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nova_modest/core/error/failure.dart';
import 'package:nova_modest/core/theme/app_colors.dart';
import 'package:nova_modest/core/widgets/failure_view.dart';
import 'package:nova_modest/features/address/domain/entities/address.dart';
import 'package:nova_modest/features/cart/domain/entities/cart_item.dart';
import 'package:nova_modest/features/catalog/domain/entities/product.dart';
import 'package:nova_modest/features/catalog/domain/entities/product_colour.dart';
import 'package:nova_modest/features/orders/domain/entities/order.dart';
import 'package:nova_modest/features/orders/domain/entities/order_status.dart';
import 'package:nova_modest/features/orders/domain/entities/order_totals.dart';
import 'package:nova_modest/features/orders/presentation/bloc/order_detail_bloc.dart';
import 'package:nova_modest/features/orders/presentation/screens/order_detail_screen.dart';
import 'package:nova_modest/features/orders/presentation/widgets/order_item_line.dart';
import 'package:nova_modest/features/orders/presentation/widgets/order_status_tracker.dart';

import '../../helpers/pump_app.dart';

class _MockOrderDetailBloc extends MockBloc<OrderDetailEvent, OrderDetailState>
    implements OrderDetailBloc {}

void main() {
  late _MockOrderDetailBloc bloc;

  const number = 'ORD-260818-0001';

  const coat = Product(
    id: 'p1',
    name: 'معطف كلاسيكي خفيف',
    price: 1200,
    categoryId: 'sets',
    colours: [ProductColour(id: 'beige', name: 'بيج رمادي', hex: '#C9C0B2')],
  );

  const savedAddress = Address(
    id: 'a1',
    kind: AddressKind.home,
    label: 'المنزل',
    // What the address book holds, which the order deliberately overrides.
    recipientName: 'أحمد عبدالله',
    phone: '+966 11 000 0000',
    country: 'المملكة العربية السعودية',
    region: 'حي العليا',
    city: 'الرياض',
    street: 'شارع التحلية، مبنى 45',
    postalCode: '12241',
  );

  Order orderWith({
    OrderStatus status = OrderStatus.processing,
    List<CartItem> items = const [
      CartItem(product: coat, colourId: 'beige', size: 'M'),
    ],
    Address? address = savedAddress,
  }) => Order(
    number: number,
    placedAt: DateTime(2024, 8, 26),
    totals: const OrderTotals(subtotal: 1200, shipping: 35, paymentFee: 15),
    status: status,
    items: items,
    address: address,
    recipientName: 'سارة أحمد',
    recipientPhone: '+966550001111',
  );

  setUpAll(loadAppFonts);

  setUp(() => bloc = _MockOrderDetailBloc());

  /// [settle] is off for the loading state: a spinner animates forever.
  Future<void> pump(
    WidgetTester tester,
    OrderDetailState state, {
    Locale? locale,
    bool settle = true,
  }) async {
    whenListen(
      bloc,
      Stream<OrderDetailState>.value(state),
      initialState: state,
    );
    await tester.pumpApp(
      BlocProvider<OrderDetailBloc>.value(
        value: bloc,
        child: const OrderDetailScreen(number: number),
      ),
      locale: locale ?? const Locale('ar'),
    );
    if (settle) {
      await tester.pumpAndSettle();
    } else {
      await tester.pump();
    }
  }

  /// The tracker's dots, in the order the stages happen.
  List<Color?> stageDots(WidgetTester tester) => tester
      .widgetList<Container>(
        find.descendant(
          of: find.byType(OrderStatusTracker),
          matching: find.byType(Container),
        ),
      )
      .map((container) => (container.decoration! as BoxDecoration).color)
      .toList();

  group('states', () {
    testWidgets('loading shows a spinner and nothing else', (tester) async {
      await pump(tester, const OrderDetailLoading(), settle: false);

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byType(OrderStatusTracker), findsNothing);
    });

    testWidgets('an unknown number says so and offers a retry', (tester) async {
      await pump(tester, const OrderDetailError(NotFoundFailure()));

      expect(find.byType(FailureView), findsOneWidget);

      await tester.tap(find.byType(FilledButton));
      await tester.pump();

      verify(() => bloc.add(const OrderRequested(number))).called(1);
    });

    testWidgets('a loaded order shows every section', (tester) async {
      await pump(tester, OrderDetailLoaded(orderWith()));

      expect(find.text('الطلب #ORD-260818-0001'), findsOneWidget);
      expect(find.textContaining('2024'), findsWidgets);
      expect(find.byType(OrderStatusTracker), findsOneWidget);
      expect(find.byType(OrderItemLine), findsOneWidget);
      expect(find.text('عنوان التوصيل'), findsOneWidget);
    });
  });

  group('the status tracker', () {
    testWidgets('draws all five stages the details frame names', (
      tester,
    ) async {
      await pump(tester, OrderDetailLoaded(orderWith()));

      expect(find.text('قيد الانتظار'), findsOneWidget);
      expect(find.text('مؤكد'), findsOneWidget);
      expect(find.text('قيد التحضير'), findsOneWidget);
      expect(find.text('تم الشحن'), findsOneWidget);
      // The long wording here; the list badge writes «مكتمل» for the same
      // stage.
      expect(find.text('تم التوصيل'), findsOneWidget);
      expect(find.text('مكتمل'), findsNothing);
    });

    testWidgets('marks what is behind, what is current and what is ahead', (
      tester,
    ) async {
      await pump(
        tester,
        OrderDetailLoaded(orderWith(status: OrderStatus.processing)),
      );

      // Pending and confirmed are behind, processing is current, the last two
      // are ahead — measured from `1:1480`, which draws done stages black, the
      // current one accent, and pending ones faint.
      expect(stageDots(tester), [
        AppColors.primaryText,
        AppColors.primaryText,
        AppColors.accent,
        AppColors.subtle,
        AppColors.subtle,
      ]);
    });

    testWidgets('a delivered order has nothing ahead of it', (tester) async {
      await pump(
        tester,
        OrderDetailLoaded(orderWith(status: OrderStatus.delivered)),
      );

      expect(stageDots(tester), [
        AppColors.primaryText,
        AppColors.primaryText,
        AppColors.primaryText,
        AppColors.primaryText,
        AppColors.accent,
      ]);
    });

    testWidgets('the current stage is the largest, not only the brightest', (
      tester,
    ) async {
      await pump(
        tester,
        OrderDetailLoaded(orderWith(status: OrderStatus.processing)),
      );

      final sizes = tester
          .widgetList<Container>(
            find.descendant(
              of: find.byType(OrderStatusTracker),
              matching: find.byType(Container),
            ),
          )
          .map((container) => tester.getSize(find.byWidget(container)).width)
          .toList();

      // Size is a second signal, so the current stage is not carried by hue
      // alone.
      expect(sizes[2], greaterThan(sizes.first));
    });
  });

  group('the delivery address', () {
    testWidgets('names who the order was actually for', (tester) async {
      await pump(tester, OrderDetailLoaded(orderWith()));

      // What was typed at checkout, not what the address book holds: the
      // contact step is editable because a shopper may buy for someone else.
      expect(find.text('سارة أحمد'), findsOneWidget);
      expect(find.text('أحمد عبدالله'), findsNothing);
      expect(find.text('+966550001111'), findsOneWidget);
    });

    testWidgets('draws the address the order recorded', (tester) async {
      await pump(tester, OrderDetailLoaded(orderWith()));

      expect(find.text('شارع التحلية، مبنى 45، حي العليا'), findsOneWidget);
      expect(find.textContaining('12241'), findsOneWidget);
    });
  });

  group('the money', () {
    testWidgets('totals what was actually charged, fee included', (
      tester,
    ) async {
      await pump(tester, OrderDetailLoaded(orderWith()));

      await tester.scrollUntilVisible(find.text('رسوم الدفع'), 200);
      await tester.pumpAndSettle();

      // The frame draws neither this row nor a payment method, and its own
      // arithmetic predates cash on delivery carrying a fee.
      expect(find.text('رسوم الدفع'), findsOneWidget);
      // 1200 + 35 shipping + 15 fee.
      expect(find.textContaining('1,250'), findsOneWidget);
    });
  });

  group('direction and locale', () {
    testWidgets('renders without overflow in ar and en', (tester) async {
      for (final locale in const [Locale('ar'), Locale('en')]) {
        await pump(tester, OrderDetailLoaded(orderWith()), locale: locale);
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('the chrome follows the locale', (tester) async {
      await pump(
        tester,
        OrderDetailLoaded(orderWith()),
        locale: const Locale('en'),
      );

      expect(find.text('Order details'), findsWidgets);
      expect(find.text('Order status'), findsOneWidget);
      expect(find.text('Delivered'), findsOneWidget);
    });

    testWidgets('lays out RTL under Arabic', (tester) async {
      await pump(tester, OrderDetailLoaded(orderWith()));

      expect(
        Directionality.of(tester.element(find.byType(OrderStatusTracker))),
        TextDirection.rtl,
      );
    });
  });
}
