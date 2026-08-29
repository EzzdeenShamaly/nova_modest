import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nova_modest/core/error/result.dart';
import 'package:nova_modest/core/storage/token_storage.dart';
import 'package:nova_modest/features/auth/data/repositories/fake_auth_repository.dart';
import 'package:nova_modest/features/auth/domain/entities/user.dart';

class _MockTokenStorage extends Mock implements TokenStorage {}

/// The registered `AuthRepository`. These pin the part of it that is easy to
/// get wrong now that it holds an edited profile: what a later read returns,
/// and what a sign-out does to it.
void main() {
  late _MockTokenStorage tokenStorage;
  late FakeAuthRepository repository;

  /// Stands in for the keystore, so a session can be present or absent.
  String? token;

  User userOf(Result<User> result) => (result as Ok<User>).value;

  setUp(() {
    tokenStorage = _MockTokenStorage();
    token = 'a-session';

    when(() => tokenStorage.readAccessToken()).thenAnswer((_) async => token);
    when(
      () => tokenStorage.saveTokens(
        accessToken: any(named: 'accessToken'),
        refreshToken: any(named: 'refreshToken'),
      ),
    ).thenAnswer((_) async {
      token = 'a-session';
    });
    when(() => tokenStorage.clear()).thenAnswer((_) async {
      token = null;
    });

    repository = FakeAuthRepository(tokenStorage);
  });

  Future<User?> currentUser() async =>
      (await repository.currentUser() as Ok<User?>).value;

  group('updateProfile', () {
    test('returns the user as it now stands', () async {
      final updated = userOf(
        await repository.updateProfile(
          displayName: 'سارة أحمد',
          phone: '+966 55 000 1111',
        ),
      );

      expect(updated.displayName, 'سارة أحمد');
      expect(updated.phone, '+966 55 000 1111');
    });

    test(
      'leaves the email alone — the contract cannot express changing it',
      () async {
        final before = await currentUser();

        final updated = userOf(
          await repository.updateProfile(displayName: 'سارة أحمد'),
        );

        expect(updated.email, before!.email);
        expect(updated.id, before.id);
      },
    );

    test('a later read sees the edit', () async {
      await repository.updateProfile(displayName: 'سارة أحمد');

      expect((await currentUser())!.displayName, 'سارة أحمد');
    });

    test('clearing the phone is a legitimate edit', () async {
      await repository.updateProfile(displayName: 'سارة');

      // Not "omitted, so keep the old one": a shopper removing their number
      // must end up without one.
      expect((await currentUser())!.phone, isNull);
    });
  });

  group('the edit and the session', () {
    test(
      'signing out returns the next session to the seeded profile',
      () async {
        await repository.updateProfile(displayName: 'سارة أحمد');
        await repository.logout();

        expect(await currentUser(), isNull);

        await repository.signInWithGoogle();
        expect((await currentUser())!.displayName, 'سارة');
      },
    );

    test('no session means no user, whatever was edited', () async {
      await repository.updateProfile(displayName: 'سارة أحمد');
      token = null;

      expect(await currentUser(), isNull);
    });
  });
}
