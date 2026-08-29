import 'dart:ui' show Locale;

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nova_modest/core/error/failure.dart';
import 'package:nova_modest/core/error/result.dart';
import 'package:nova_modest/features/settings/data/repositories/locale_repository_impl.dart';
import 'package:nova_modest/features/settings/domain/repositories/locale_repository.dart';
import 'package:nova_modest/features/settings/presentation/bloc/locale_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockLocaleRepository extends Mock implements LocaleRepository {}

class _MockPreferences extends Mock implements SharedPreferences {}

void main() {
  group('LocaleRepositoryImpl', () {
    late _MockPreferences preferences;
    late LocaleRepositoryImpl repository;

    const key = 'settings.language_code';
    String? stored;

    setUp(() {
      preferences = _MockPreferences();
      stored = null;

      when(() => preferences.getString(key)).thenAnswer((_) => stored);
      when(() => preferences.setString(key, any())).thenAnswer((
        invocation,
      ) async {
        stored = invocation.positionalArguments[1] as String;
        return true;
      });

      repository = LocaleRepositoryImpl(preferences);
    });

    test('nothing chosen yet is null, not a failure', () async {
      final result = await repository.savedLanguageCode();

      expect((result as Ok<String?>).value, isNull);
    });

    test('a saved code comes back', () async {
      await repository.save('en');

      expect((await repository.savedLanguageCode() as Ok<String?>).value, 'en');
    });

    test('a failed write is reported, not swallowed', () async {
      when(
        () => preferences.setString(key, any()),
      ).thenAnswer((_) async => false);

      final result = await repository.save('en');

      expect((result as Err<void>).failure, isA<CacheFailure>());
    });

    test('a read failure maps to CacheFailure', () async {
      when(
        () => preferences.getString(key),
      ).thenThrow(PlatformException(code: 'unavailable'));

      final result = await repository.savedLanguageCode();

      expect((result as Err<String?>).failure, isA<CacheFailure>());
    });
  });

  group('LocaleBloc', () {
    late _MockLocaleRepository repository;

    setUp(() => repository = _MockLocaleRepository());

    void givenSaved(Result<String?> result) => when(
      () => repository.savedLanguageCode(),
    ).thenAnswer((_) async => result);

    blocTest<LocaleBloc, LocaleState>(
      'an untouched install resolves to Arabic, not to the device',
      setUp: () => givenSaved(const Ok(null)),
      build: () => LocaleBloc(repository),
      act: (bloc) => bloc.add(const LocaleRequested()),
      // Following the device is what made an English handset render the whole
      // Arabic-first product in English, which is why the locale was pinned in
      // the first place.
      expect: () => const [LocaleResolved(Locale('ar'))],
    );

    blocTest<LocaleBloc, LocaleState>(
      'a stored choice is restored',
      setUp: () => givenSaved(const Ok('en')),
      build: () => LocaleBloc(repository),
      act: (bloc) => bloc.add(const LocaleRequested()),
      expect: () => const [LocaleResolved(Locale('en'))],
    );

    blocTest<LocaleBloc, LocaleState>(
      'an unreadable preference falls back rather than blocking the app',
      setUp: () => givenSaved(const Err(CacheFailure())),
      build: () => LocaleBloc(repository),
      act: (bloc) => bloc.add(const LocaleRequested()),
      expect: () => const [LocaleResolved(Locale('ar'))],
    );

    test('the state carries a usable locale before storage answers', () {
      // MaterialApp reads this on the very first frame; there is no loading
      // state to render instead.
      expect(const LocaleUnresolved().locale, LocaleBloc.fallback);
    });

    blocTest<LocaleBloc, LocaleState>(
      'choosing applies the language and persists it',
      setUp: () => when(
        () => repository.save(any()),
      ).thenAnswer((_) async => const Ok(null)),
      build: () => LocaleBloc(repository),
      act: (bloc) => bloc.add(const LocaleSelected('en')),
      expect: () => const [LocaleResolved(Locale('en'))],
      verify: (_) => verify(() => repository.save('en')).called(1),
    );

    blocTest<LocaleBloc, LocaleState>(
      'a failed save still switches the language, and says so',
      setUp: () => when(
        () => repository.save(any()),
      ).thenAnswer((_) async => const Err(CacheFailure())),
      build: () => LocaleBloc(repository),
      act: (bloc) => bloc.add(const LocaleSelected('en')),
      // Applied first, then the failure rides along: the design promises an
      // immediate switch, and a disk error is a poor reason to refuse one.
      expect: () => const [
        LocaleResolved(Locale('en')),
        LocaleResolved(Locale('en'), saveFailure: CacheFailure()),
      ],
    );

    test('a state with a save failure is not equal to one without', () {
      // Without saveFailure in props the second emit above would be a no-op and
      // the screen would never report it.
      expect(
        const LocaleResolved(Locale('en')),
        isNot(const LocaleResolved(Locale('en'), saveFailure: CacheFailure())),
      );
    });
  });
}
