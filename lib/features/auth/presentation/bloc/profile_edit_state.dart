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
