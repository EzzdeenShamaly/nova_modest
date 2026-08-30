part of 'order_detail_bloc.dart';

/// Three states, not four.
///
/// There is no empty: one order either exists or it does not, and "it does not"
/// is a `NotFoundFailure` the repository already returns — an outcome with a
/// reason, which an `Empty` state would throw away
/// (`06-flutter-error-guard.md` §5).
sealed class OrderDetailState extends Equatable {
  const OrderDetailState();

  @override
  List<Object?> get props => const [];
}

final class OrderDetailInitial extends OrderDetailState {
  const OrderDetailInitial();
}

final class OrderDetailLoading extends OrderDetailState {
  const OrderDetailLoading();
}

final class OrderDetailError extends OrderDetailState {
  const OrderDetailError(this.failure);

  final Failure failure;

  @override
  List<Object?> get props => [failure];
}

final class OrderDetailLoaded extends OrderDetailState {
  const OrderDetailLoaded(this.order);

  final Order order;

  @override
  List<Object?> get props => [order];
}
