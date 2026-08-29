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
