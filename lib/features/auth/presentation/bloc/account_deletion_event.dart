part of 'account_deletion_bloc.dart';

sealed class AccountDeletionEvent extends Equatable {
  const AccountDeletionEvent();

  @override
  List<Object?> get props => const [];
}

/// The shopper read the dialog — what goes, what stays — and confirmed.
///
/// There is no "requested" event before it: the dialog is the request, and the
/// only thing that reaches this bloc is the answer.
final class AccountDeletionConfirmed extends AccountDeletionEvent {
  const AccountDeletionConfirmed();
}
