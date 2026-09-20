import 'dart:typed_data';

import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:nova_modest/core/error/failure.dart';
import 'package:nova_modest/core/error/result.dart';
import 'package:nova_modest/core/media/avatar_picker.dart';
import 'package:nova_modest/features/auth/domain/entities/user.dart';
import 'package:nova_modest/features/auth/domain/repositories/auth_repository.dart';

part 'profile_edit_event.dart';
part 'profile_edit_state.dart';

/// Saves an edited profile.
///
/// Lives beside [SignInBloc] rather than in `features/profile/`, though the
/// screen it serves is a profile screen: both are **factories over
/// `AuthRepository` that report their outcome to `AuthBloc`**, and keeping the
/// two things that can change an account in one place beats splitting them
/// across features so the folder matches the screen. The screen already reads
/// `AuthBloc` from here for the same reason.
///
/// A factory, not a singleton: "saving" is one visit's business, and a
/// singleton would still be holding the last result the next time the form
/// opened.
@injectable
class ProfileEditBloc extends Bloc<ProfileEditEvent, ProfileEditState> {
  ProfileEditBloc(this._repository, this._picker)
    : super(const ProfileEditIdle()) {
    // droppable: a second tap while the save is in flight is discarded, not
    // queued. Without it a double-tap sends two writes whose responses can
    // resolve out of order.
    on<ProfileEditSubmitted>(_onSubmitted, transformer: droppable());
    // Same reasoning, and more literally: the gallery is already open, so a
    // second tap must not open a second one.
    on<ProfileAvatarRequested>(_onAvatarRequested, transformer: droppable());
    on<ProfileAvatarRecoveryRequested>(
      _onAvatarRecoveryRequested,
      transformer: droppable(),
    );
  }

  final AuthRepository _repository;
  final AvatarPicker _picker;

  Future<void> _onSubmitted(
    ProfileEditSubmitted event,
    Emitter<ProfileEditState> emit,
  ) async {
    emit(const ProfileEditSubmitting());

    // No try/catch: the repository returns a Result and this folds it. A catch
    // here would mean the data layer is leaking (`06-flutter-error-guard.md`
    // §4).
    final result = await _repository.updateProfile(
      displayName: event.displayName,
      phone: event.phone,
    );

    emit(result.fold(ProfileEditFailureState.new, ProfileEditSucceeded.new));
  }

  Future<void> _onAvatarRequested(
    ProfileAvatarRequested event,
    Emitter<ProfileEditState> emit,
  ) async {
    final bytes = await _picker.pick();
    // Backing out of the gallery is not a failure and must not report one: the
    // form goes back to how it was.
    if (bytes == null) {
      emit(const ProfileEditIdle());
      return;
    }
    await _upload(bytes, emit);
  }

  /// Picks up a photograph Android dropped when it killed the app mid-pick.
  ///
  /// Dispatched when the screen opens. On every other platform the picker
  /// answers null and nothing happens.
  Future<void> _onAvatarRecoveryRequested(
    ProfileAvatarRecoveryRequested event,
    Emitter<ProfileEditState> emit,
  ) async {
    final bytes = await _picker.recoverLostPick();
    if (bytes == null) return;
    await _upload(bytes, emit);
  }

  Future<void> _upload(Uint8List bytes, Emitter<ProfileEditState> emit) async {
    emit(const ProfileAvatarUploading());
    final result = await _repository.uploadAvatar(bytes);
    emit(result.fold(ProfileEditFailureState.new, ProfileAvatarUpdated.new));
  }
}
