import 'package:flutter/services.dart' show PlatformException;
import 'package:injectable/injectable.dart';
import 'package:nova_modest/core/error/failure.dart';
import 'package:nova_modest/core/error/result.dart';
import 'package:nova_modest/features/settings/domain/entities/notification_preferences.dart';
import 'package:nova_modest/features/settings/domain/repositories/notification_preferences_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// `SharedPreferences`-backed notification preferences.
///
/// Plain preferences, and here that is the right answer rather than a
/// compromise: `03-flutter-security-guard` names an interface preference as
/// exactly the non-sensitive case. Addresses and the profile went to memory
/// instead because they carry PII; two booleans carry none.
///
/// One key per preference rather than a JSON blob: partial writes stay cheap
/// and there is no parse failure to handle for two booleans.
@LazySingleton(as: NotificationPreferencesRepository)
class NotificationPreferencesRepositoryImpl
    implements NotificationPreferencesRepository {
  const NotificationPreferencesRepositoryImpl(this._preferences);

  static const String _ordersKey = 'settings.notifications.orders';
  static const String _promotionsKey = 'settings.notifications.promotions';

  final SharedPreferences _preferences;

  @override
  Future<Result<NotificationPreferences>> saved() async {
    try {
      const defaults = NotificationPreferences.defaults;
      // A missing key means "never chosen", which the defaults answer. Absence
      // is not an error.
      return Ok(
        NotificationPreferences(
          orders: _preferences.getBool(_ordersKey) ?? defaults.orders,
          promotions:
              _preferences.getBool(_promotionsKey) ?? defaults.promotions,
        ),
      );
    } on PlatformException catch (_) {
      return const Err(
        CacheFailure('Could not read the notification preferences.'),
      );
    }
  }

  @override
  Future<Result<void>> save(NotificationPreferences preferences) async {
    try {
      // setBool reports whether the write landed; ignoring it would let a
      // failed save look like a success until the next launch.
      final written = await Future.wait([
        _preferences.setBool(_ordersKey, preferences.orders),
        _preferences.setBool(_promotionsKey, preferences.promotions),
      ]);
      if (written.contains(false)) {
        return const Err(
          CacheFailure('Could not save the notification preferences.'),
        );
      }
      return const Ok(null);
    } on PlatformException catch (_) {
      return const Err(
        CacheFailure('Could not save the notification preferences.'),
      );
    }
  }
}
