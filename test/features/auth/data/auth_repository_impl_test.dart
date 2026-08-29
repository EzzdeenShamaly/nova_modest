import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nova_modest/core/error/failure.dart';
import 'package:nova_modest/core/error/result.dart';
import 'package:nova_modest/core/storage/token_storage.dart';
import 'package:nova_modest/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:nova_modest/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:nova_modest/features/auth/domain/entities/auth_session.dart';
import 'package:nova_modest/features/auth/domain/entities/user.dart';

class _MockRemote extends Mock implements AuthRemoteDataSource {}

class _MockTokenStorage extends Mock implements TokenStorage {}

void main() {
  late _MockRemote remote;
  late _MockTokenStorage tokenStorage;
  late AuthRepositoryImpl repository;

  const user = User(id: 'u1', email: 'a@b.com', displayName: 'Sara');
  const session = AuthSession(
    user: user,
    accessToken: 'access-123',
    refreshToken: 'refresh-456',
  );

  setUp(() {
    remote = _MockRemote();
    tokenStorage = _MockTokenStorage();
    repository = AuthRepositoryImpl(remote, tokenStorage);
  });

  group('email code', () {
    test(
      'requesting a code reports success without leaking existence',
      () async {
        when(() => remote.requestEmailCode(any())).thenAnswer((_) async {});

        final result = await repository.requestEmailCode('a@b.com');

        expect(result, isA<Ok<void>>());
        verify(() => remote.requestEmailCode('a@b.com')).called(1);
      },
    );

    test('verifying persists the tokens and returns only the user', () async {
      when(
        () => remote.verifyEmailCode(
          email: any(named: 'email'),
          code: any(named: 'code'),
        ),
      ).thenAnswer((_) async => session);
      when(
        () => tokenStorage.saveTokens(
          accessToken: any(named: 'accessToken'),
          refreshToken: any(named: 'refreshToken'),
        ),
      ).thenAnswer((_) async {});

      final result = await repository.verifyEmailCode(
        email: 'a@b.com',
        code: '123456',
      );

      expect((result as Ok<User>).value, user);
      // The token pair is handed to secure storage, never returned upward.
      verify(
        () => tokenStorage.saveTokens(
          accessToken: 'access-123',
          refreshToken: 'refresh-456',
        ),
      ).called(1);
    });

    test('maps a thrown Failure to Err without storing anything', () async {
      when(
        () => remote.verifyEmailCode(
          email: any(named: 'email'),
          code: any(named: 'code'),
        ),
      ).thenThrow(const UnauthorizedFailure());

      final result = await repository.verifyEmailCode(
        email: 'a@b.com',
        code: '000000',
      );

      expect((result as Err<User>).failure, const UnauthorizedFailure());
      verifyNever(
        () => tokenStorage.saveTokens(
          accessToken: any(named: 'accessToken'),
          refreshToken: any(named: 'refreshToken'),
        ),
      );
    });
  });

  group('currentUser', () {
    test('reports signed-out as Ok(null), not as a failure', () async {
      when(() => tokenStorage.readAccessToken()).thenAnswer((_) async => null);

      final result = await repository.currentUser();

      expect(result, isA<Ok<User?>>());
      expect((result as Ok<User?>).value, isNull);
      verifyNever(() => remote.me());
    });

    test(
      'clears a stored token the server rejects and reports signed-out',
      () async {
        when(
          () => tokenStorage.readAccessToken(),
        ).thenAnswer((_) async => 'stale');
        when(() => remote.me()).thenThrow(const UnauthorizedFailure());
        when(() => tokenStorage.clear()).thenAnswer((_) async {});

        final result = await repository.currentUser();

        expect((result as Ok<User?>).value, isNull);
        verify(() => tokenStorage.clear()).called(1);
      },
    );

    test(
      'surfaces a non-auth failure instead of silently signing out',
      () async {
        when(
          () => tokenStorage.readAccessToken(),
        ).thenAnswer((_) async => 'good');
        when(() => remote.me()).thenThrow(const NetworkFailure());

        final result = await repository.currentUser();

        expect((result as Err<User?>).failure, const NetworkFailure());
        verifyNever(() => tokenStorage.clear());
      },
    );
  });

  group('logout', () {
    test(
      'clears the session locally even when the server call fails',
      () async {
        when(() => remote.logout()).thenThrow(const NetworkFailure());
        when(() => tokenStorage.clear()).thenAnswer((_) async {});

        final result = await repository.logout();

        // A user who taps sign-out must end up signed out.
        expect(result, isA<Ok<void>>());
        verify(() => tokenStorage.clear()).called(1);
      },
    );

    test('reports a failure when the token itself cannot be cleared', () async {
      when(() => remote.logout()).thenAnswer((_) async {});
      when(() => tokenStorage.clear()).thenThrow(const CacheFailure());

      final result = await repository.logout();

      // This one IS reportable: the session survives.
      expect((result as Err<void>).failure, const CacheFailure());
    });
  });
}
