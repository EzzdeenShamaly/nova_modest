part of 'profile_edit_bloc.dart';

/// Submit-shaped, like `SignInState`: there is no list to be empty of and
/// nothing to load, so the four-state contract does not apply
/// (`06-flutter-error-guard.md` §5). What exists is idle, in flight, failed,
/// and done.
sealed class ProfileEditState extends Equatable {
  const ProfileEditState();

  /// Whether a save is in flight, so the form can disable itself without every
  /// widget switching on the state.
  bool get isSubmitting => false;

  @override
  List<Object?> get props => const [];
}

final class ProfileEditIdle extends ProfileEditState {
  const ProfileEditIdle();
}

final class ProfileEditSubmitting extends ProfileEditState {
  const ProfileEditSubmitting();

  @override
  bool get isSubmitting => true;
}

final class ProfileEditFailureState extends ProfileEditState {
  const ProfileEditFailureState(this.failure);

  final Failure failure;

  @override
  List<Object?> get props => [failure];
}

/// Saved. Carries the user as it now stands, which the screen hands to
/// `AuthBloc` through `AuthProfileUpdated`.
final class ProfileEditSucceeded extends ProfileEditState {
  const ProfileEditSucceeded(this.user);

  final User user;

  @override
  List<Object?> get props => [user];
}

/// A picture is on its way up.
///
/// Deliberately **not** `isSubmitting`: the form is not what is busy. Locking
/// the name and phone fields because a photograph is uploading would stop a
/// shopper doing something unrelated and unaffected — the two writes touch
/// different columns.
final class ProfileAvatarUploading extends ProfileEditState {
  const ProfileAvatarUploading();
}

/// The picture is up. Distinct from [ProfileEditSucceeded] because the screen
/// responds differently: a saved form closes, a changed picture stays put so
/// she can see it.
final class ProfileAvatarUpdated extends ProfileEditState {
  const ProfileAvatarUpdated(this.user);

  final User user;

  @override
  List<Object?> get props => [user];
}
