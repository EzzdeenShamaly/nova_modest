import 'dart:ui' show Locale;

import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:nova_modest/core/error/failure.dart';
import 'package:nova_modest/core/error/result.dart';
import 'package:nova_modest/features/settings/domain/repositories/locale_repository.dart';

part 'locale_event.dart';
part 'locale_state.dart';

/// Owns the language the whole interface is rendered in.
///
/// App-wide (`@lazySingleton`) because `MaterialApp` reads it and the account's
/// language screen writes it — and because `11-flutter-l10n-guard` §8 requires
/// the selected locale to be state, never a top-level mutable variable. This
/// bloc is what replaced the `locale: const Locale('ar')` pinned in `app.dart`
/// since the onboarding was built.
///
/// Switching is **immediate and needs no restart**: the router is built once in
/// `App.initState`, so rebuilding `MaterialApp.router` with a new locale keeps
/// the navigation stack exactly where it was. That is the promise the design's
/// explanatory line makes.
@lazySingleton
class LocaleBloc extends Bloc<LocaleEvent, LocaleState> {
  LocaleBloc(this._repository) : super(const LocaleUnresolved()) {
    // droppable: the startup read is idempotent, so a duplicate is waste.
    on<LocaleRequested>(_onRequested, transformer: droppable());
    // restartable: only the newest choice matters.
    on<LocaleSelected>(_onSelected, transformer: restartable());
  }

  /// The language an Arabic-first shop opens in when nothing has been chosen.
  ///
  /// Deliberately **not** the device's. Following the device is what made an
  /// English handset render the whole product in English and LTR, which is why
  /// the locale was pinned in the first place; removing the pin must not
  /// reintroduce it.
  static const Locale fallback = Locale('ar');

  final LocaleRepository _repository;

  Future<void> _onRequested(
    LocaleRequested event,
    Emitter<LocaleState> emit,
  ) async {
    final result = await _repository.savedLanguageCode();

    // A failed read is not worth blocking the app over: it falls back to the
    // default, and the shopper can choose again. Nothing is lost that a tap
    // cannot restore.
    emit(
      LocaleResolved(
        result.fold(
          (_) => fallback,
          (code) => code == null ? fallback : Locale(code),
        ),
      ),
    );
  }

  Future<void> _onSelected(
    LocaleSelected event,
    Emitter<LocaleState> emit,
  ) async {
    final chosen = Locale(event.languageCode);

    // Applied first, then persisted. The design promises the interface updates
    // immediately, and a disk error is a poor reason to refuse a language
    // change — so the failure rides along on the state instead of cancelling
    // it, and the screen says the choice could not be remembered.
    emit(LocaleResolved(chosen));

    final saved = await _repository.save(event.languageCode);
    if (saved case Err(:final failure)) {
      emit(LocaleResolved(chosen, saveFailure: failure));
    }
  }
}
