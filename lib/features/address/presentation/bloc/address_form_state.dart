part of 'address_form_bloc.dart';

/// Submit-shaped, like `ProfileEditState`: nothing loads and there is no list
/// to be empty of, so the four-state contract does not apply
/// (`06-flutter-error-guard.md` §5).
sealed class AddressFormState extends Equatable {
  const AddressFormState();

  /// Whether a save is in flight, so the form can lock itself without every
  /// widget switching on the state.
  bool get isSubmitting => false;

  @override
  List<Object?> get props => const [];
}

final class AddressFormIdle extends AddressFormState {
  const AddressFormIdle();
}

final class AddressFormSubmitting extends AddressFormState {
  const AddressFormSubmitting();

  @override
  bool get isSubmitting => true;
}

final class AddressFormFailureState extends AddressFormState {
  const AddressFormFailureState(this.failure);

  final Failure failure;

  @override
  List<Object?> get props => [failure];
}

/// Saved. Carries the whole resulting list, because the repository returns it
/// and a screen popping back to the list would otherwise re-fetch what it has
/// already been handed.
final class AddressFormSucceeded extends AddressFormState {
  const AddressFormSucceeded(this.addresses);

  final List<Address> addresses;

  @override
  List<Object?> get props => [addresses];
}
