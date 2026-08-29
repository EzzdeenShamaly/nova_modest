import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:nova_modest/core/error/failure.dart';
import 'package:nova_modest/core/error/result.dart';
import 'package:nova_modest/features/address/domain/entities/address.dart';
import 'package:nova_modest/features/address/domain/repositories/address_repository.dart';

part 'address_list_event.dart';
part 'address_list_state.dart';

/// Owns the saved-addresses list.
///
/// A **factory**, scoped to the screen: nothing outside it reads the list, and
/// checkout will ask the same repository for itself rather than sharing this.
@injectable
class AddressListBloc extends Bloc<AddressListEvent, AddressListState> {
  AddressListBloc(this._repository) : super(const AddressListInitial()) {
    // droppable: one load in flight is enough; a duplicate is waste.
    on<AddressesRequested>(_onRequested, transformer: droppable());
    // sequential: both mutations are read-modify-write against one stored list,
    // and both can move which address is the default.
    on<AddressDeleted>(_onDeleted, transformer: sequential());
    on<AddressDefaultSelected>(_onDefaultSelected, transformer: sequential());
  }

  final AddressRepository _repository;

  Future<void> _onRequested(
    AddressesRequested event,
    Emitter<AddressListState> emit,
  ) async {
    emit(const AddressListLoading());
    _emitList(await _repository.addresses(), emit);
  }

  /// Deleting does **not** pass through [AddressListLoading]: a spinner between
  /// two versions of the same list is a flicker, not information. The same
  /// holds for choosing a default.
  Future<void> _onDeleted(
    AddressDeleted event,
    Emitter<AddressListState> emit,
  ) async => _emitList(await _repository.remove(event.id), emit);

  Future<void> _onDefaultSelected(
    AddressDefaultSelected event,
    Emitter<AddressListState> emit,
  ) async => _emitList(await _repository.setDefault(event.id), emit);

  /// The one place a repository result becomes a state.
  ///
  /// No try/catch anywhere in this bloc: the repository returns a `Result` and
  /// this folds it (`06-flutter-error-guard.md` §4).
  void _emitList(Result<List<Address>> result, Emitter<AddressListState> emit) {
    emit(
      result.fold(
        AddressListError.new,
        (addresses) => addresses.isEmpty
            ? const AddressListEmpty()
            : AddressListLoaded(addresses),
      ),
    );
  }
}
