part of 'address_list_bloc.dart';

/// The four states from `06-flutter-error-guard.md` §5, all reachable.
///
/// [AddressListEmpty] is a distinct state rather than `Loaded([])`: "no saved
/// addresses" is a different screen from a list with no cards — it carries an
/// invitation to add one and nothing else.
sealed class AddressListState extends Equatable {
  const AddressListState();

  @override
  List<Object?> get props => const [];
}

final class AddressListInitial extends AddressListState {
  const AddressListInitial();
}

final class AddressListLoading extends AddressListState {
  const AddressListLoading();
}

final class AddressListEmpty extends AddressListState {
  const AddressListEmpty();
}

final class AddressListError extends AddressListState {
  const AddressListError(this.failure);

  final Failure failure;

  @override
  List<Object?> get props => [failure];
}

final class AddressListLoaded extends AddressListState {
  const AddressListLoaded(this.addresses);

  /// Default first, as the repository sorts them.
  final List<Address> addresses;

  @override
  List<Object?> get props => [addresses];
}
