part of 'locale_bloc.dart';

sealed class LocaleEvent extends Equatable {
  const LocaleEvent();

  @override
  List<Object?> get props => const [];
}

/// Dispatched once at startup to read whatever was chosen last.
final class LocaleRequested extends LocaleEvent {
  const LocaleRequested();
}

/// A language was picked on the language screen.
///
/// Carries a code rather than a `Locale` so the event matches what the
/// repository stores and what the screen's options are keyed by.
final class LocaleSelected extends LocaleEvent {
  const LocaleSelected(this.languageCode);

  final String languageCode;

  @override
  List<Object?> get props => [languageCode];
}
