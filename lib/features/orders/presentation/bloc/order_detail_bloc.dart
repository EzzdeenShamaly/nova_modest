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

part 'order_detail_event.dart';
part 'order_detail_state.dart';

/// Owns one order, fetched by the number in the route.
///
/// **Fetches rather than reading the list.** The address form reads
/// `AddressListBloc` because it is always pushed as a child of the list; an
/// order number can arrive from a link or a notification with no list loaded
/// above it, so this asks the repository for itself.
///
/// A **factory**: one order per visit, and a singleton would still be holding
/// the last one the next time a card was tapped.
@injectable
class OrderDetailBloc extends Bloc<OrderDetailEvent, OrderDetailState> {
  OrderDetailBloc(this._repository) : super(const OrderDetailInitial()) {
    // droppable: one fetch in flight is enough, and a second tap on a retry
    // should be ignored rather than queued behind the first.
    on<OrderRequested>(_onRequested, transformer: droppable());
  }

  final OrderRepository _repository;

  Future<void> _onRequested(
    OrderRequested event,
    Emitter<OrderDetailState> emit,
  ) async {
    emit(const OrderDetailLoading());

    // No try/catch: the repository returns a `Result` and this folds it
    // (`06-flutter-error-guard.md` §4).
    emit(
      (await _repository.orderByNumber(
        event.number,
      )).fold(OrderDetailError.new, OrderDetailLoaded.new),
    );
  }
}
