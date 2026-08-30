import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nova_modest/core/error/failure.dart';
import 'package:nova_modest/core/error/result.dart';
import 'package:nova_modest/features/orders/domain/entities/order.dart';
import 'package:nova_modest/features/orders/domain/entities/order_status.dart';
import 'package:nova_modest/features/orders/domain/entities/order_totals.dart';
import 'package:nova_modest/features/orders/domain/repositories/order_repository.dart';
import 'package:nova_modest/features/orders/presentation/bloc/order_detail_bloc.dart';

class _MockOrderRepository extends Mock implements OrderRepository {}

void main() {
  late _MockOrderRepository repository;

  const number = 'ORD-260818-0001';

  final order = Order(
    number: number,
    placedAt: DateTime(2024, 8, 26),
    totals: const OrderTotals(subtotal: 1200, shipping: 35, paymentFee: 15),
    status: OrderStatus.processing,
  );

  setUp(() => repository = _MockOrderRepository());

  void givenOrder(Result<Order> result) => when(
    () => repository.orderByNumber(any()),
  ).thenAnswer((_) async => result);

  blocTest<OrderDetailBloc, OrderDetailState>(
    'fetches the order the route named',
    setUp: () => givenOrder(Ok(order)),
    build: () => OrderDetailBloc(repository),
    act: (bloc) => bloc.add(const OrderRequested(number)),
    // The whole sequence: asserting only the last state would hide a missing
    // Loading emission, which is what makes a screen look frozen.
    expect: () => [const OrderDetailLoading(), OrderDetailLoaded(order)],
    verify: (_) => verify(() => repository.orderByNumber(number)).called(1),
  );

  blocTest<OrderDetailBloc, OrderDetailState>(
    'an unknown number is a failure with a reason, not an empty screen',
    setUp: () => givenOrder(const Err(NotFoundFailure())),
    build: () => OrderDetailBloc(repository),
    act: (bloc) => bloc.add(const OrderRequested('ORD-000000-9999')),
    // No Empty state in this hierarchy: one order exists or it does not, and
    // "it does not" carries a reason an Empty would throw away.
    expect: () => const [
      OrderDetailLoading(),
      OrderDetailError(NotFoundFailure()),
    ],
  );

  blocTest<OrderDetailBloc, OrderDetailState>(
    'a failed read is an error state with a retry behind it',
    setUp: () => givenOrder(const Err(NetworkFailure())),
    build: () => OrderDetailBloc(repository),
    act: (bloc) => bloc.add(const OrderRequested(number)),
    expect: () => const [
      OrderDetailLoading(),
      OrderDetailError(NetworkFailure()),
    ],
  );

  blocTest<OrderDetailBloc, OrderDetailState>(
    'a second request while one is in flight is dropped, not queued',
    setUp: () =>
        when(() => repository.orderByNumber(any())).thenAnswer((_) async {
          // Latency, or nothing overlaps and droppable is never exercised.
          await Future<void>.delayed(const Duration(milliseconds: 50));
          return Ok(order);
        }),
    build: () => OrderDetailBloc(repository),
    act: (bloc) => bloc
      ..add(const OrderRequested(number))
      ..add(const OrderRequested(number)),
    wait: const Duration(milliseconds: 120),
    verify: (_) => verify(() => repository.orderByNumber(number)).called(1),
  );
}
