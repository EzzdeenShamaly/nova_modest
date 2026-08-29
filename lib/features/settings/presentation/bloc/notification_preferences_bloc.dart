import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:nova_modest/core/error/failure.dart';
import 'package:nova_modest/core/error/result.dart';
import 'package:nova_modest/features/settings/domain/entities/notification_preferences.dart';
import 'package:nova_modest/features/settings/domain/repositories/notification_preferences_repository.dart';

part 'notification_preferences_event.dart';
part 'notification_preferences_state.dart';

/// Owns the notification preferences.
///
/// A **factory**, unlike its neighbour `LocaleBloc`: nothing outside this
/// screen reads these, whereas `MaterialApp` reads the locale on every build.
/// The difference is the whole reason one is a singleton and this is not
/// (`01-flutter-architecture-guard.md`).
@injectable
class NotificationPreferencesBloc
    extends Bloc<NotificationPreferencesEvent, NotificationPreferencesState> {
  NotificationPreferencesBloc(this._repository)
    : super(const NotificationPreferencesUnresolved()) {
    // droppable: the startup read is idempotent, so a duplicate is waste.
    on<NotificationPreferencesRequested>(
      _onRequested,
      transformer: droppable(),
    );
    // sequential: two switches flipped quickly are two read-modify-writes
    // against the same stored pair, and interleaving them would lose one.
    on<NotificationPreferencesChanged>(_onChanged, transformer: sequential());
  }

  final NotificationPreferencesRepository _repository;

  Future<void> _onRequested(
    NotificationPreferencesRequested event,
    Emitter<NotificationPreferencesState> emit,
  ) async {
    final result = await _repository.saved();

    // A failed read is not worth blocking a settings screen over: it falls back
    // to the defaults and the shopper can choose again. Nothing is lost that a
    // tap cannot restore.
    emit(
      NotificationPreferencesResolved(
        result.fold((_) => NotificationPreferences.defaults, (saved) => saved),
      ),
    );
  }

  /// Applies the change **first**, then reports a failed write.
  ///
  /// The same call `LocaleBloc` makes: a switch that refuses to move until the
  /// disk agrees reads as broken, and a disk error is a poor reason to refuse a
  /// preference. The failure rides along on the state so the screen can say the
  /// choice will not survive a restart, rather than the app silently forgetting
  /// it later.
  Future<void> _onChanged(
    NotificationPreferencesChanged event,
    Emitter<NotificationPreferencesState> emit,
  ) async {
    emit(NotificationPreferencesResolved(event.preferences));

    final result = await _repository.save(event.preferences);
    if (result case Err(:final failure)) {
      emit(
        NotificationPreferencesResolved(
          event.preferences,
          saveFailure: failure,
        ),
      );
    }
  }
}
