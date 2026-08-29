import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nova_modest/core/error/failure.dart';
import 'package:nova_modest/core/error/result.dart';
import 'package:nova_modest/features/onboarding/data/repositories/onboarding_repository_impl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockPreferences extends Mock implements SharedPreferences {}

void main() {
  late _MockPreferences preferences;
  late OnboardingRepositoryImpl repository;

  const key = 'onboarding.has_seen';

  setUp(() {
    preferences = _MockPreferences();
    repository = OnboardingRepositoryImpl(preferences);
  });

  group('isOnboardingRequired', () {
    test('a missing flag is a first launch, not an error', () async {
      when(() => preferences.getBool(key)).thenReturn(null);

      final result = await repository.isOnboardingRequired();

      expect((result as Ok<bool>).value, isTrue);
    });

    test('a recorded flag means the onboarding is done', () async {
      when(() => preferences.getBool(key)).thenReturn(true);

      final result = await repository.isOnboardingRequired();

      expect((result as Ok<bool>).value, isFalse);
    });

    test('maps a platform failure to CacheFailure', () async {
      when(
        () => preferences.getBool(key),
      ).thenThrow(PlatformException(code: 'unavailable'));

      final result = await repository.isOnboardingRequired();

      expect(result, isA<Err<bool>>());
      expect((result as Err<bool>).failure, isA<CacheFailure>());
    });
  });

  group('markSeen', () {
    test('records the flag', () async {
      when(() => preferences.setBool(key, true)).thenAnswer((_) async => true);

      final result = await repository.markSeen();

      expect(result, isA<Ok<void>>());
      verify(() => preferences.setBool(key, true)).called(1);
    });

    test('reports a failure when the write does not land', () async {
      // setBool returns false rather than throwing. Treating that as success
      // would replay the onboarding on the next launch.
      when(() => preferences.setBool(key, true)).thenAnswer((_) async => false);

      final result = await repository.markSeen();

      expect((result as Err<void>).failure, isA<CacheFailure>());
    });

    test('maps a platform failure to CacheFailure', () async {
      when(
        () => preferences.setBool(key, true),
      ).thenThrow(PlatformException(code: 'unavailable'));

      final result = await repository.markSeen();

      expect((result as Err<void>).failure, isA<CacheFailure>());
    });
  });
}
