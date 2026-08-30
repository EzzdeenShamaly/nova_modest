import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
// hide Order: injectable exports an `Order` annotation that shadows this
// feature's entity.
import 'package:injectable/injectable.dart' hide Order;
import 'package:nova_modest/core/error/failure.dart';
import 'package:nova_modest/core/error/result.dart';
import 'package:nova_modest/features/orders/domain/entities/order.dart';
import 'package:nova_modest/features/orders/domain/repositories/order_repository.dart';

part 'orders_event.dart';
part 'orders_state.dart';

/// Owns the shopper's order history.
///
/// A **factory**, scoped to the screen: nothing outside it reads the list, and
/// the confirmation screen has its own order in hand rather than asking here.
@injectable
class OrdersBloc extends Bloc<OrdersEvent, OrdersState> {
  OrdersBloc(this._repository) : super(const OrdersInitial()) {
    // droppable: one load in flight is enough; a duplicate is waste, and a
    // pull-to-refresh that arrives mid-load should be ignored rather than
    // queued behind it.
    on<OrdersRequested>(_onRequested, transformer: droppable());
  }

  final OrderRepository _repository;

  Future<void> _onRequested(
    OrdersRequested event,
    Emitter<OrdersState> emit,
  ) async {
    emit(const OrdersLoading());

    // No try/catch: the repository returns a `Result` and this folds it
    // (`06-flutter-error-guard.md` §4).
    emit(
      (await _repository.orders()).fold(
        OrdersError.new,
        (orders) => orders.isEmpty ? const OrdersEmpty() : OrdersLoaded(orders),
      ),
    );
  }
}
