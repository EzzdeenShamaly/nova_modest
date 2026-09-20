part of 'profile_edit_bloc.dart';

sealed class ProfileEditEvent extends Equatable {
  const ProfileEditEvent();

  @override
  List<Object?> get props => const [];
}

/// The form was submitted, having already validated.
///
/// The email is absent because the contract has no way to change it — see
/// `AuthRepository.updateProfile`.
final class ProfileEditSubmitted extends ProfileEditEvent {
  const ProfileEditSubmitted({required this.displayName, this.phone});

  final String displayName;

  /// Null clears the number, which is a legitimate edit rather than "leave it
  /// as it was".
  final String? phone;

  @override
  List<Object?> get props => [displayName, phone];
}

/// The shopper asked to change her picture.
///
/// The bytes are not on the event: choosing the photograph is the bloc's job
/// through [AvatarPicker], so no widget calls a plugin and a test can hand the
/// bloc a picture without a gallery.
final class ProfileAvatarRequested extends ProfileEditEvent {
  const ProfileAvatarRequested();
}

/// The screen opened; ask Android whether it dropped a pick.
///
/// A separate event rather than something the bloc does on construction: it
/// reaches the network when it finds something, and that must be tied to a
/// screen being shown rather than to a bloc being built.
final class ProfileAvatarRecoveryRequested extends ProfileEditEvent {
  const ProfileAvatarRecoveryRequested();
}
