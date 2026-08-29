import 'package:nova_modest/core/error/result.dart';

/// Remembers which language the shopper chose.
///
/// Deals in a **language code**, not a `Locale`: `Locale` is a `dart:ui` type,
/// and the domain layer stays framework-free — the same reason `ProductColour`
/// holds a hex string rather than a `Color`. The bloc turns the code into a
/// `Locale`.
///
/// A device preference rather than a session one, so it sits beside the
/// onboarding flag in shape and in storage — not with anything the account owns.
abstract class LocaleRepository {
  /// The stored language code, or `null` when nothing has been chosen yet.
  /// Absence is a legitimate answer, not a failure.
  Future<Result<String?>> savedLanguageCode();

  Future<Result<void>> save(String languageCode);
}
