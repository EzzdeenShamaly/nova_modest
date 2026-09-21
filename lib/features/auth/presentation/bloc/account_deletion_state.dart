part of 'account_deletion_bloc.dart';

/// Submit-shaped, like `ProfileEditState`: nothing loads, so the four-state
/// contract does not apply. What exists is idle, in flight, failed, and done.
sealed class AccountDeletionState extends Equatable {
  const AccountDeletionState();

  @override
  List<Object?> get props => const [];
}

final class AccountDeletionIdle extends AccountDeletionState {
  const AccountDeletionIdle();
}

final class AccountDeletionInProgress extends AccountDeletionState {
  const AccountDeletionInProgress();
}

final class AccountDeletionFailed extends AccountDeletionState {
  const AccountDeletionFailed(this.failure);

  final Failure failure;

  @override
  List<Object?> get props => [failure];
}

/// The account is gone and the device's session with it.
final class AccountDeletionSucceeded extends AccountDeletionState {
  const AccountDeletionSucceeded();
}
