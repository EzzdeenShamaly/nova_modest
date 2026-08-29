import 'package:nova_modest/core/error/result.dart';

/// The shopper's own recent searches.
///
/// Deliberately separate from [CatalogRepository]: what this device has looked
/// for is local and personal, while the catalogue is shared and remote. Keeping
/// them apart is why a server-backed catalogue can arrive without touching this
/// file — the same split `OnboardingRepository` makes against `AuthRepository`.
///
/// Every method returns the **whole** resulting list rather than void, so the
/// bloc has one emit path instead of a read after every write.
abstract class SearchHistoryRepository {
  /// Newest first.
  Future<Result<List<String>>> recent();

  /// Records [term] as the most recent search.
  ///
  /// Repeating an earlier search moves it to the front rather than adding a
  /// second copy, and the list is capped so it stays a shortlist.
  Future<Result<List<String>>> record(String term);

  /// Forgets one term — the × on a chip.
  Future<Result<List<String>>> remove(String term);

  /// Forgets everything.
  Future<Result<List<String>>> clear();
}
