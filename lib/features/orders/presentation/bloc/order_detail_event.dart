part of 'order_detail_bloc.dart';

sealed class OrderDetailEvent extends Equatable {
  const OrderDetailEvent();

  @override
  List<Object?> get props => const [];
}

/// One order was asked for — on opening the screen, and on a retry.
final class OrderRequested extends OrderDetailEvent {
  const OrderRequested(this.number);

  final String number;

  @override
  List<Object?> get props => [number];
}
