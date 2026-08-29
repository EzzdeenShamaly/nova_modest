part of 'home_bloc.dart';

sealed class HomeEvent extends Equatable {
  const HomeEvent();

  @override
  List<Object?> get props => const [];
}

/// The screen appeared and needs its catalogue.
final class HomeRequested extends HomeEvent {
  const HomeRequested();
}

/// Pull-to-refresh, or a retry from the error state.
final class HomeRefreshed extends HomeEvent {
  const HomeRefreshed();
}

/// A category chip was tapped. `null` is the "All" chip.
final class HomeCategorySelected extends HomeEvent {
  const HomeCategorySelected(this.categoryId);

  final String? categoryId;

  @override
  List<Object?> get props => [categoryId];
}
