import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:nova_modest/core/error/failure.dart';
import 'package:nova_modest/core/error/result.dart';
import 'package:nova_modest/features/auth/domain/repositories/auth_repository.dart';

part 'account_deletion_event.dart';
part 'account_deletion_state.dart';

/// Deletes the signed-in shopper's account.
///
/// Beside `ProfileEditBloc` and for the same reason: it is a factory over
/// `AuthRepository` that reports its outcome to `AuthBloc`, so the transient
/// "deleting" state never enters the app-wide singleton. On success the screen
/// sends `AuthAccountDeleted`; on an expired session it sends
/// `AuthLogoutRequested`, which is how every other lost session ends.
@injectable
class AccountDeletionBloc
    extends Bloc<AccountDeletionEvent, AccountDeletionState> {
  AccountDeletionBloc(this._repository) : super(const AccountDeletionIdle()) {
    // droppable: a second confirmation while the first is in flight must not
    // send a second, irreversible request.
    on<AccountDeletionConfirmed>(_onConfirmed, transformer: droppable());
  }

  final AuthRepository _repository;

  Future<void> _onConfirmed(
    AccountDeletionConfirmed event,
    Emitter<AccountDeletionState> emit,
  ) async {
    emit(const AccountDeletionInProgress());
    final result = await _repository.deleteAccount();
    emit(
      result.fold(
        AccountDeletionFailed.new,
        (_) => const AccountDeletionSucceeded(),
      ),
    );
  }
}
