import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:nova_modest/core/error/failure.dart';
import 'package:nova_modest/core/error/result.dart';
import 'package:nova_modest/features/address/domain/entities/address.dart';
import 'package:nova_modest/features/address/domain/repositories/address_repository.dart';

part 'address_form_event.dart';
part 'address_form_state.dart';

/// Saves one address, new or edited.
///
/// A **factory**: saving is one visit's business, and a singleton would still
/// be holding the last result the next time the form opened.
///
/// Separate from `AddressListBloc` rather than one bloc with more events,
/// because the form is a widget checkout will host inside its own page — it has
/// to be able to save without a list bloc anywhere above it.
@injectable
class AddressFormBloc extends Bloc<AddressFormEvent, AddressFormState> {
  AddressFormBloc(this._repository) : super(const AddressFormIdle()) {
    // droppable: a second tap while the save is in flight is discarded, not
    // queued. Without it a double-tap saves twice and, for a new address,
    // creates two of them.
    on<AddressFormSubmitted>(_onSubmitted, transformer: droppable());
  }

  final AddressRepository _repository;

  Future<void> _onSubmitted(
    AddressFormSubmitted event,
    Emitter<AddressFormState> emit,
  ) async {
    emit(const AddressFormSubmitting());

    // No try/catch: the repository returns a Result and this folds it
    // (`06-flutter-error-guard.md` §4).
    final result = await _repository.save(event.address);

    emit(result.fold(AddressFormFailureState.new, AddressFormSucceeded.new));
  }
}
