part of 'orders_bloc.dart';

sealed class OrdersEvent extends Equatable {
  const OrdersEvent();

  @override
  List<Object?> get props => const [];
}

/// The order history was asked for — on opening the screen, and on a retry.
final class OrdersRequested extends OrdersEvent {
  const OrdersRequested();
}
