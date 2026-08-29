part of 'address_form_bloc.dart';

sealed class AddressFormEvent extends Equatable {
  const AddressFormEvent();

  @override
  List<Object?> get props => const [];
}

/// The form was submitted, having already validated.
///
/// Carries a whole [Address]: an empty [Address.id] is a new one, a populated
/// id is an edit, and the repository decides which — so neither the form nor
/// the screen has to branch on it.
final class AddressFormSubmitted extends AddressFormEvent {
  const AddressFormSubmitted(this.address);

  final Address address;

  @override
  List<Object?> get props => [address];
}
