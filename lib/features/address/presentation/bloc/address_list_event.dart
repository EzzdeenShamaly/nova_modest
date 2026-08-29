part of 'address_list_bloc.dart';

sealed class AddressListEvent extends Equatable {
  const AddressListEvent();

  @override
  List<Object?> get props => const [];
}

/// The screen opened, or came back from the form and needs the list again.
final class AddressesRequested extends AddressListEvent {
  const AddressesRequested();
}

/// The delete control on one card, already confirmed.
final class AddressDeleted extends AddressListEvent {
  const AddressDeleted(this.id);

  final String id;

  @override
  List<Object?> get props => [id];
}

/// A card was made the default.
final class AddressDefaultSelected extends AddressListEvent {
  const AddressDefaultSelected(this.id);

  final String id;

  @override
  List<Object?> get props => [id];
}
