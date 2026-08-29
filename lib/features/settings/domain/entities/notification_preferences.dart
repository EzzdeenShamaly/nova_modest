import 'package:freezed_annotation/freezed_annotation.dart';

part 'notification_preferences.freezed.dart';

/// Which notifications the shopper wants.
///
/// Split by **topic**, not by channel: "offers" and "marketing" are the same
/// thing said twice, and a topic/channel grid would be four toggles for a
/// feature nothing consumes yet. Adding an email channel later is one more
/// field here.
///
/// **Nothing acts on these today.** There is no push package in
/// `pubspec.yaml` and no backend to read them — the app records the preference
/// and honours it when notifications exist. Recorded in `progress.md`, because
/// unlike a disabled button these switches look like they work.
@freezed
abstract class NotificationPreferences with _$NotificationPreferences {
  const factory NotificationPreferences({
    /// Transactional: an order was confirmed, shipped, delivered. On by
    /// default — it is what a shopper expects to be told about.
    @Default(true) bool orders,

    /// Promotional. Off by default: marketing is opt-in, which is both the
    /// convention and the direction regulation keeps moving in.
    @Default(false) bool promotions,
  }) = _NotificationPreferences;

  /// What a shopper gets before they have chosen anything.
  static const NotificationPreferences defaults = NotificationPreferences();
}
