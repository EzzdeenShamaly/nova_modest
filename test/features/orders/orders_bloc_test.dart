import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nova_modest/core/error/failure.dart';
import 'package:nova_modest/core/error/result.dart';
import 'package:nova_modest/features/orders/domain/entities/order.dart';
import 'package:nova_modest/features/orders/domain/entities/order_status.dart';
import 'package:nova_modest/features/orders/domain/entities/order_totals.dart';
import 'package:nova_modest/features/orders/domain/repositories/order_repository.dart';
import 'package:nova_modest/features/orders/presentation/bloc/orders_bloc.dart';

class _MockOrderRepository extends Mock implements OrderRepository {}

void main() {
  late _MockOrderRepository repository;

  final processing = Order(
    number: 'ORD-260818-0001',
    placedAt: DateTime(2024, 8, 26),
    totals: const OrderTotals(subtotal: 1200, shipping: 35, paymentFee: 15),
    status: OrderStatus.processing,
  );

  final delivered = Order(
    number: 'ORD-020624-0018',
    placedAt: DateTime(2024, 6, 2),
    totals: const OrderTotals(subtotal: 800, shipping: 35, paymentFee: 15),
    status: OrderStatus.delivered,
  );

  setUp(() => repository = _MockOrderRepository());

  void givenOrders(Result<List<Order>> result) =>
      when(() => repository.orders()).thenAnswer((_) async => result);

  group('loading', () {
    blocTest<OrdersBloc, OrdersState>(
      'no history is its own state, not an empty list',
      setUp: () => givenOrders(const Ok(<Order>[])),
      build: () => OrdersBloc(repository),
      act: (bloc) => bloc.add(const OrdersRequested()),
      // "You have not ordered anything yet" invites browsing; a list with no
      // cards invites nothing.
      expect: () => const [OrdersLoading(), OrdersEmpty()],
    );

    blocTest<OrdersBloc, OrdersState>(
      'a stocked history arrives in the order the repository sorted it',
      setUp: () => givenOrders(Ok([processing, delivered])),
      build: () => OrdersBloc(repository),
      act: (bloc) => bloc.add(const OrdersRequested()),
      // The whole sequence: asserting only the last state would hide a missing
      // Loading emission, which is what makes a screen look frozen.
      expect: () => [
        const OrdersLoading(),
        OrdersLoaded([processing, delivered]),
      ],
    );

    blocTest<OrdersBloc, OrdersState>(
      'a failed read is an error state with a retry behind it',
      setUp: () => givenOrders(const Err(NetworkFailure())),
      build: () => OrdersBloc(repository),
      act: (bloc) => bloc.add(const OrdersRequested()),
      expect: () => const [OrdersLoading(), OrdersError(NetworkFailure())],
    );

    blocTest<OrdersBloc, OrdersState>(
      'a second request while one is in flight is dropped, not queued',
      setUp: () => when(() => repository.orders()).thenAnswer((_) async {
        // Latency, or nothing overlaps and droppable is never exercised.
        await Future<void>.delayed(const Duration(milliseconds: 50));
        return Ok([processing]);
      }),
      build: () => OrdersBloc(repository),
      act: (bloc) => bloc
        ..add(const OrdersRequested())
        ..add(const OrdersRequested()),
      wait: const Duration(milliseconds: 120),
      verify: (_) => verify(() => repository.orders()).called(1),
    );
  });

  group('the entity the list reads', () {
    test('counts quantities, not lines, for "المنتجات (٢)"', () {
      // An order of one garment in twos is two items on one line.
      expect(processing.itemCount, 0);
      expect(processing.items, isEmpty);
      expect(processing.leadItem, isNull);
      expect(processing.hiddenItemCount, 0);
    });

    test('status carries its own order, so the tracker needs no positions', () {
      expect(OrderStatus.pending.isBefore(OrderStatus.delivered), isTrue);
      expect(OrderStatus.delivered.isBefore(OrderStatus.pending), isFalse);
      // A stage is not before itself; the tracker draws it as current.
      expect(OrderStatus.shipped.isBefore(OrderStatus.shipped), isFalse);
    });

    test('the five stages are declared in the order they happen', () {
      // `1:1480` draws them top to bottom in exactly this order.
      expect(OrderStatus.values, [
        OrderStatus.pending,
        OrderStatus.confirmed,
        OrderStatus.processing,
        OrderStatus.shipped,
        OrderStatus.delivered,
      ]);
    });
  });
}
