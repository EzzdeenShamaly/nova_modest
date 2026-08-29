import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nova_modest/core/error/failure.dart';
import 'package:nova_modest/core/error/result.dart';
import 'package:nova_modest/features/settings/data/repositories/notification_preferences_repository_impl.dart';
import 'package:nova_modest/features/settings/domain/entities/notification_preferences.dart';
import 'package:nova_modest/features/settings/domain/repositories/notification_preferences_repository.dart';
import 'package:nova_modest/features/settings/presentation/bloc/notification_preferences_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockPreferences extends Mock implements SharedPreferences {}

class _MockRepository extends Mock
    implements NotificationPreferencesRepository {}

void main() {
  const ordersKey = 'settings.notifications.orders';
  const promotionsKey = 'settings.notifications.promotions';

  group('the entity', () {
    test('defaults are transactional on, marketing off', () {
      // Marketing is opt-in; order updates are what a shopper expects to be
      // told about.
      expect(NotificationPreferences.defaults.orders, isTrue);
      expect(NotificationPreferences.defaults.promotions, isFalse);
    });

    test('compares by every field', () {
      const a = NotificationPreferences();
      expect(a, a.copyWith());
      expect(a, isNot(a.copyWith(orders: false)));
      expect(a, isNot(a.copyWith(promotions: true)));
    });
  });

  group('the repository', () {
    late _MockPreferences preferences;
    late NotificationPreferencesRepositoryImpl repository;
    final store = <String, bool>{};

    setUp(() {
      preferences = _MockPreferences();
      store.clear();

      when(() => preferences.getBool(any())).thenAnswer(
        (invocation) => store[invocation.positionalArguments.first as String],
      );
      when(() => preferences.setBool(any(), any())).thenAnswer((
        invocation,
      ) async {
        store[invocation.positionalArguments[0] as String] =
            invocation.positionalArguments[1] as bool;
        return true;
      });

      repository = NotificationPreferencesRepositoryImpl(preferences);
    });

    NotificationPreferences valueOf(Result<NotificationPreferences> result) =>
        (result as Ok<NotificationPreferences>).value;

    test('an untouched device gets the defaults, not an error', () async {
      final saved = valueOf(await repository.saved());

      expect(saved, NotificationPreferences.defaults);
    });

    test('a key set on its own does not disturb the other', () async {
      store[promotionsKey] = true;

      final saved = valueOf(await repository.saved());

      // Absence means "never chosen", which the defaults answer.
      expect(saved.orders, isTrue);
      expect(saved.promotions, isTrue);
    });

    test('saving writes one key per preference', () async {
      await repository.save(
        const NotificationPreferences(orders: false, promotions: true),
      );

      expect(store[ordersKey], isFalse);
      expect(store[promotionsKey], isTrue);
    });

    test('a later read sees what was saved', () async {
      await repository.save(const NotificationPreferences(orders: false));

      expect(valueOf(await repository.saved()).orders, isFalse);
    });

    test('a failed write is reported, not swallowed', () async {
      when(
        () => preferences.setBool(any(), any()),
      ).thenAnswer((_) async => false);

      final result = await repository.save(NotificationPreferences.defaults);

      expect((result as Err<void>).failure, isA<CacheFailure>());
    });

    test('a read failure maps to CacheFailure', () async {
      when(
        () => preferences.getBool(any()),
      ).thenThrow(PlatformException(code: 'unavailable'));

      final result = await repository.saved();

      expect(
        (result as Err<NotificationPreferences>).failure,
        isA<CacheFailure>(),
      );
    });
  });

  group('the bloc', () {
    late _MockRepository repository;

    const changed = NotificationPreferences(orders: false, promotions: true);

    setUp(() {
      repository = _MockRepository();
      registerFallbackValue(NotificationPreferences.defaults);
    });

    blocTest<NotificationPreferencesBloc, NotificationPreferencesState>(
      'resolves what storage holds',
      setUp: () => when(
        () => repository.saved(),
      ).thenAnswer((_) async => const Ok(changed)),
      build: () => NotificationPreferencesBloc(repository),
      act: (bloc) => bloc.add(const NotificationPreferencesRequested()),
      expect: () => const [NotificationPreferencesResolved(changed)],
    );

    blocTest<NotificationPreferencesBloc, NotificationPreferencesState>(
      'a failed read falls back to the defaults rather than blocking',
      setUp: () => when(
        () => repository.saved(),
      ).thenAnswer((_) async => const Err(CacheFailure())),
      build: () => NotificationPreferencesBloc(repository),
      act: (bloc) => bloc.add(const NotificationPreferencesRequested()),
      // Nothing is lost that a tap cannot restore, so a settings screen should
      // not refuse to draw over it.
      expect: () => const [
        NotificationPreferencesResolved(NotificationPreferences.defaults),
      ],
    );

    blocTest<NotificationPreferencesBloc, NotificationPreferencesState>(
      'applies the change before the write, and stays applied',
      setUp: () => when(
        () => repository.save(any()),
      ).thenAnswer((_) async => const Ok(null)),
      build: () => NotificationPreferencesBloc(repository),
      act: (bloc) => bloc.add(const NotificationPreferencesChanged(changed)),
      // One state: a switch that waits for the disk before it moves reads as
      // broken.
      expect: () => const [NotificationPreferencesResolved(changed)],
      verify: (_) => verify(() => repository.save(changed)).called(1),
    );

    blocTest<NotificationPreferencesBloc, NotificationPreferencesState>(
      'a failed write keeps the change and reports it',
      setUp: () => when(
        () => repository.save(any()),
      ).thenAnswer((_) async => const Err(CacheFailure())),
      build: () => NotificationPreferencesBloc(repository),
      act: (bloc) => bloc.add(const NotificationPreferencesChanged(changed)),
      // Applied, then told it will not survive a restart — the switch does not
      // snap back.
      expect: () => const [
        NotificationPreferencesResolved(changed),
        NotificationPreferencesResolved(changed, saveFailure: CacheFailure()),
      ],
    );

    test('every state carries usable preferences', () {
      // No loading state and no empty one: two booleans always have a value,
      // and the switches are drawn from the first frame.
      expect(
        const NotificationPreferencesUnresolved().preferences,
        NotificationPreferences.defaults,
      );
      expect(
        const NotificationPreferencesResolved(changed).preferences,
        changed,
      );
    });
  });
}
