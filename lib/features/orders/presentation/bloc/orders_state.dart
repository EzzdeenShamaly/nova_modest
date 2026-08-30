part of 'orders_bloc.dart';

/// The four states from `06-flutter-error-guard.md` §5, all reachable.
///
/// [OrdersEmpty] is a distinct state rather than `Loaded([])`: "you have not
/// ordered anything yet" is a different screen from a list with no cards — it
/// invites the shopper to browse and shows nothing else.
sealed class OrdersState extends Equatable {
  const OrdersState();

  @override
  List<Object?> get props => const [];
}

final class OrdersInitial extends OrdersState {
  const OrdersInitial();
}

final class OrdersLoading extends OrdersState {
  const OrdersLoading();
}

final class OrdersEmpty extends OrdersState {
  const OrdersEmpty();
}

final class OrdersError extends OrdersState {
  const OrdersError(this.failure);

  final Failure failure;

  @override
  List<Object?> get props => [failure];
}

final class OrdersLoaded extends OrdersState {
  const OrdersLoaded(this.orders);

  /// Newest first, as the repository sorts them.
  final List<Order> orders;

  @override
  List<Object?> get props => [orders];
}
