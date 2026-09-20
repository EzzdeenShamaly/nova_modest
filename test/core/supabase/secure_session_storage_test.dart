import 'package:flutter/services.dart' show PlatformException;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nova_modest/core/supabase/secure_session_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockSecureStorage extends Mock implements FlutterSecureStorage {}

/// Where the session lives, and what happens when the keystore will not play.
///
/// The failure paths matter more than the happy one here. A shopper whose
/// keystore cannot be read must sign in again — not meet an error screen, and
/// not carry on with the plaintext session this class exists to remove
/// (user, 2026-09-20).
void main() {
  late _MockSecureStorage secure;
  late SharedPreferences preferences;

  const session = '{"access_token":"a-token","refresh_token":"r-token"}';

  Future<SecureSessionStorage> storage() async => SecureSessionStorage(
    secureStorage: secure,
    preferences: () async => preferences,
  );

  Future<void> givenPlaintextSession(String? value) async {
    SharedPreferences.setMockInitialValues(
      value == null ? {} : {SecureSessionStorage.legacyKey: value},
    );
    preferences = await SharedPreferences.getInstance();
  }

  setUp(() async {
    secure = _MockSecureStorage();
    when(() => secure.read(key: any(named: 'key'))).thenAnswer((_) async => null);
    when(
      () => secure.write(key: any(named: 'key'), value: any(named: 'value')),
    ).thenAnswer((_) async {});
    when(() => secure.delete(key: any(named: 'key'))).thenAnswer((_) async {});
    await givenPlaintextSession(null);
  });

  group('the key the old storage used', () {
    test('is rebuilt from the project url, not guessed', () {
      // `sb-<project ref>-auth-token` is how the SDK's default named it. A
      // different name here would leave an upgrading shopper's session behind
      // — and behind means readable, in plain text.
      expect(SecureSessionStorage.legacyKey, startsWith('sb-'));
      expect(SecureSessionStorage.legacyKey, endsWith('-auth-token'));
    });
  });

  group('migrating a session written in plain text', () {
    test('moves it into the keystore and deletes the plaintext copy', () async {
      await givenPlaintextSession(session);

      await (await storage()).initialize();

      verify(
        () => secure.write(key: SecureSessionStorage.key, value: session),
      ).called(1);
      expect(
        preferences.getString(SecureSessionStorage.legacyKey),
        isNull,
        reason: 'the plaintext copy must not survive the migration',
      );
    });

    test('leaves a newer keystore session alone', () async {
      await givenPlaintextSession(session);
      when(
        () => secure.read(key: SecureSessionStorage.key),
      ).thenAnswer((_) async => '{"access_token":"newer"}');

      await (await storage()).initialize();

      verifyNever(
        () => secure.write(key: any(named: 'key'), value: any(named: 'value')),
      );
      // The stale plaintext copy still goes.
      expect(preferences.getString(SecureSessionStorage.legacyKey), isNull);
    });

    test('does nothing when there was never a plaintext session', () async {
      await (await storage()).initialize();

      verifyNever(
        () => secure.write(key: any(named: 'key'), value: any(named: 'value')),
      );
    });

    test('a failed migration wipes both and starts clean', () async {
      // The constraint: never an error screen, and never left on the plaintext
      // session. Signing in again is the accepted cost.
      await givenPlaintextSession(session);
      when(
        () => secure.write(key: any(named: 'key'), value: any(named: 'value')),
      ).thenThrow(PlatformException(code: 'keystore'));

      final subject = await storage();
      await expectLater(subject.initialize(), completes);

      verify(() => secure.delete(key: SecureSessionStorage.key)).called(1);
      expect(preferences.getString(SecureSessionStorage.legacyKey), isNull);
      expect(await subject.hasAccessToken(), isFalse);
    });
  });

  group('reading and writing', () {
    test('a stored session is returned', () async {
      when(
        () => secure.read(key: SecureSessionStorage.key),
      ).thenAnswer((_) async => session);
      final subject = await storage();

      expect(await subject.accessToken(), session);
      expect(await subject.hasAccessToken(), isTrue);
    });

    test('an unreadable keystore answers "no session" rather than throwing', () async {
      when(
        () => secure.read(key: any(named: 'key')),
      ).thenThrow(PlatformException(code: 'keystore'));
      final subject = await storage();

      expect(await subject.accessToken(), isNull);
      expect(await subject.hasAccessToken(), isFalse);
      verify(() => secure.delete(key: SecureSessionStorage.key)).called(2);
    });

    test('a failed write leaves nothing half-saved', () async {
      when(
        () => secure.write(key: any(named: 'key'), value: any(named: 'value')),
      ).thenThrow(PlatformException(code: 'keystore'));
      final subject = await storage();

      await expectLater(subject.persistSession(session), completes);

      verify(() => secure.delete(key: SecureSessionStorage.key)).called(1);
    });

    test('signing out clears the keystore and any plaintext leftover', () async {
      await givenPlaintextSession(session);
      final subject = await storage();

      await subject.removePersistedSession();

      verify(() => secure.delete(key: SecureSessionStorage.key)).called(1);
      expect(preferences.getString(SecureSessionStorage.legacyKey), isNull);
    });
  });
}
