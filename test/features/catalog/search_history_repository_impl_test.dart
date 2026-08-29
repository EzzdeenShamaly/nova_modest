import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nova_modest/core/error/failure.dart';
import 'package:nova_modest/core/error/result.dart';
import 'package:nova_modest/features/catalog/data/repositories/search_history_repository_impl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockPreferences extends Mock implements SharedPreferences {}

void main() {
  late _MockPreferences preferences;
  late SearchHistoryRepositoryImpl repository;

  const key = 'search.history';

  /// The one stored list, standing in for the preferences file.
  List<String>? stored;

  List<String> termsOf(Result<List<String>> result) =>
      (result as Ok<List<String>>).value;

  setUp(() {
    preferences = _MockPreferences();
    stored = null;

    when(() => preferences.getStringList(key)).thenAnswer((_) => stored);
    when(() => preferences.setStringList(key, any())).thenAnswer((
      invocation,
    ) async {
      stored = (invocation.positionalArguments[1] as List<dynamic>)
          .cast<String>();
      return true;
    });

    repository = SearchHistoryRepositoryImpl(preferences);
  });

  group('recent', () {
    test('an untouched history is empty, not an error', () async {
      expect(termsOf(await repository.recent()), isEmpty);
    });

    test('a read failure maps to CacheFailure', () async {
      when(
        () => preferences.getStringList(key),
      ).thenThrow(PlatformException(code: 'unavailable'));

      final result = await repository.recent();

      expect((result as Err<List<String>>).failure, isA<CacheFailure>());
    });
  });

  group('record', () {
    test('the newest search comes first', () async {
      await repository.record('عباية');
      final result = await repository.record('وشاح');

      expect(termsOf(result), ['وشاح', 'عباية']);
      expect(stored, ['وشاح', 'عباية']);
    });

    test('repeating a search moves it up rather than duplicating it', () async {
      await repository.record('عباية');
      await repository.record('وشاح');
      final result = await repository.record('عباية');

      // A shortlist, not a log.
      expect(termsOf(result), ['عباية', 'وشاح']);
    });

    test('the term is trimmed before it is stored', () async {
      final result = await repository.record('  عباية  ');

      expect(termsOf(result), ['عباية']);
    });

    test('an empty term is not recorded and is not a failure', () async {
      await repository.record('عباية');
      final result = await repository.record('   ');

      expect(termsOf(result), ['عباية']);
      verifyNever(() => preferences.setStringList(key, ['عباية', '   ']));
    });

    test('the list is capped, dropping the oldest', () async {
      for (
        var index = 0;
        index < SearchHistoryRepositoryImpl.maxEntries + 3;
        index++
      ) {
        await repository.record('term$index');
      }

      final result = await repository.recent();
      expect(
        termsOf(result),
        hasLength(SearchHistoryRepositoryImpl.maxEntries),
      );
      expect(termsOf(result).first, 'term10');
      expect(termsOf(result), isNot(contains('term0')));
    });

    test('a failed write is reported, not swallowed', () async {
      when(
        () => preferences.setStringList(key, any()),
      ).thenAnswer((_) async => false);

      final result = await repository.record('عباية');

      expect((result as Err<List<String>>).failure, isA<CacheFailure>());
    });
  });

  group('remove and clear', () {
    test('one term goes and the rest stay', () async {
      await repository.record('عباية');
      await repository.record('وشاح');

      final result = await repository.remove('عباية');

      expect(termsOf(result), ['وشاح']);
      expect(stored, ['وشاح']);
    });

    test('removing something absent changes nothing', () async {
      await repository.record('عباية');

      expect(termsOf(await repository.remove('حذاء')), ['عباية']);
    });

    test('clear empties the list and persists that', () async {
      await repository.record('عباية');

      expect(termsOf(await repository.clear()), isEmpty);
      expect(stored, isEmpty);
    });
  });
}
