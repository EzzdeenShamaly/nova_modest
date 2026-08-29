import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:nova_modest/core/error/failure.dart';
import 'package:nova_modest/core/error/result.dart';
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
  ProfileEditBloc(this._repository) : super(const ProfileEditIdle()) {
    // droppable: a second tap while the save is in flight is discarded, not
    // queued. Without it a double-tap sends two writes whose responses can
    // resolve out of order.
    on<ProfileEditSubmitted>(_onSubmitted, transformer: droppable());
  }

  final AuthRepository _repository;

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
}
