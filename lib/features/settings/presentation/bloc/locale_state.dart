part of 'locale_bloc.dart';

/// Always carries a usable [locale] — there is no loading state and no empty
/// one, because the interface has to be rendered in *something* from the first
/// frame. The four-state contract does not apply for the same reason it does
/// not apply to `ProfileEditState`: nothing here is a list, and nothing here
/// can be absent.
sealed class LocaleState extends Equatable {
  const LocaleState(this.locale);

  final Locale locale;

  @override
  List<Object?> get props => [locale];
}

/// Before storage has answered. Holds [LocaleBloc.fallback], so the app renders
/// correctly from the first frame rather than waiting on a disk read.
///
/// Kept as a state of its own rather than folded into [LocaleResolved] because
/// it is what a splash gate would hold on, if the brief window between launch
/// and the stored value arriving ever proves visible.
final class LocaleUnresolved extends LocaleState {
  const LocaleUnresolved() : super(LocaleBloc.fallback);
}

/// Read from storage, or just chosen by the shopper.
final class LocaleResolved extends LocaleState {
  const LocaleResolved(super.locale, {this.saveFailure});

  /// Set when the choice was applied but could not be remembered.
  ///
  /// The locale is live either way — the design promises an immediate switch,
  /// and a disk error is a poor reason to refuse one. This rides along so the
  /// screen can say the choice will not survive a restart, instead of the app
  /// silently forgetting it later.
  final Failure? saveFailure;

  @override
  List<Object?> get props => [locale, saveFailure];
}
