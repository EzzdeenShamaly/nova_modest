import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nova_modest/core/error/failure.dart';
import 'package:nova_modest/core/error/result.dart';
import 'package:nova_modest/features/auth/domain/entities/user.dart';
import 'package:nova_modest/features/auth/domain/repositories/auth_repository.dart';
import 'package:nova_modest/features/auth/presentation/bloc/auth_bloc.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late _MockAuthRepository repository;

  const user = User(id: 'u1', email: 'a@b.com', displayName: 'Sara');

  setUp(() => repository = _MockAuthRepository());

  // Any AuthCheckRequested case crosses AuthBloc.minimumSessionCheckDuration,
  // the floor that stops the splash flashing. blocTest must outwait it or it
  // asserts before the resolved state arrives.
  final pastFloor =
      AuthBloc.minimumSessionCheckDuration + const Duration(milliseconds: 200);

  group('AuthCheckRequested', () {
    blocTest<AuthBloc, AuthState>(
      'emits [CheckInProgress, Unauthenticated] when there is no stored session',
      setUp: () => when(
        () => repository.currentUser(),
      ).thenAnswer((_) async => const Ok(null)),
      build: () => AuthBloc(repository),
      act: (bloc) => bloc.add(const AuthCheckRequested()),
      wait: pastFloor,
      expect: () => const [AuthCheckInProgress(), AuthUnauthenticated()],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [CheckInProgress, Authenticated] when the stored session is still valid',
      setUp: () => when(
        () => repository.currentUser(),
      ).thenAnswer((_) async => const Ok(user)),
      build: () => AuthBloc(repository),
      act: (bloc) => bloc.add(const AuthCheckRequested()),
      wait: pastFloor,
      expect: () => const [AuthCheckInProgress(), AuthAuthenticated(user)],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [CheckInProgress, Failure] when the session check fails',
      setUp: () => when(
        () => repository.currentUser(),
      ).thenAnswer((_) async => const Err(NetworkFailure())),
      build: () => AuthBloc(repository),
      act: (bloc) => bloc.add(const AuthCheckRequested()),
      wait: pastFloor,
      expect: () => const [
        AuthCheckInProgress(),
        AuthFailureState(NetworkFailure()),
      ],
    );
  });

  group('startup versus user-initiated waiting', () {
    // The router holds the splash on AuthCheckInProgress and must ignore
    // AuthLoading. If these two ever collapse into one state, the splash is
    // either skipped or the login form bounces the user back to it.
    blocTest<AuthBloc, AuthState>(
      'the startup check reports AuthCheckInProgress, never AuthLoading',
      setUp: () => when(
        () => repository.currentUser(),
      ).thenAnswer((_) async => const Ok(null)),
      build: () => AuthBloc(repository),
      act: (bloc) => bloc.add(const AuthCheckRequested()),
      wait: pastFloor,
      expect: () => const [AuthCheckInProgress(), AuthUnauthenticated()],
      verify: (bloc) => expect(bloc.state, isNot(isA<AuthLoading>())),
    );

    blocTest<AuthBloc, AuthState>(
      'a sign-out reports AuthLoading, never AuthCheckInProgress',
      setUp: () => when(
        () => repository.logout(),
      ).thenAnswer((_) async => const Ok(null)),
      build: () => AuthBloc(repository),
      act: (bloc) => bloc.add(const AuthLogoutRequested()),
      expect: () => const [AuthLoading(), AuthUnauthenticated()],
    );
  });

  group('AuthSessionEstablished', () {
    blocTest<AuthBloc, AuthState>(
      'takes the user straight from a completed sign-in flow',
      build: () => AuthBloc(repository),
      act: (bloc) => bloc.add(const AuthSessionEstablished(user)),
      // No repository call and no loading hop: SignInBloc already did the work
      // and stored the token. Re-checking would add the startup floor's delay to
      // every sign-in.
      expect: () => const [AuthAuthenticated(user)],
      verify: (_) => verifyNever(() => repository.currentUser()),
    );
  });

  group('minimum session-check duration', () {
    test(
      'holds the resolved state so the splash screen is actually seen',
      () async {
        when(
          () => repository.currentUser(),
        ).thenAnswer((_) async => const Ok(null));

        final bloc = AuthBloc(repository);
        addTearDown(bloc.close);

        final stopwatch = Stopwatch()..start();
        bloc.add(const AuthCheckRequested());
        await bloc.stream.firstWhere((s) => s is AuthUnauthenticated);
        stopwatch.stop();

        // A repository that answers instantly must still not resolve before the
        // floor, or the splash flashes and vanishes.
        expect(
          stopwatch.elapsed,
          greaterThanOrEqualTo(AuthBloc.minimumSessionCheckDuration),
        );
      },
    );
  });

  group('AuthProfileUpdated', () {
    const edited = User(
      id: 'u1',
      email: 'a@b.com',
      displayName: 'Sara Ahmed',
      phone: '+966 55 000 1111',
    );

    blocTest<AuthBloc, AuthState>(
      'replaces the session user without touching the repository',
      setUp: () => when(
        () => repository.currentUser(),
      ).thenAnswer((_) async => const Ok(user)),
      build: () => AuthBloc(repository),
      act: (bloc) async {
        bloc.add(const AuthCheckRequested());
        await Future<void>.delayed(pastFloor);
        bloc.add(const AuthProfileUpdated(edited));
      },
      wait: pastFloor,
      skip: 2,
      expect: () => const [AuthAuthenticated(edited)],
      // The write already happened in ProfileEditBloc; re-reading here would be
      // a second source of truth for the same person.
      verify: (_) => verifyNever(
        () => repository.updateProfile(
          displayName: any(named: 'displayName'),
          phone: any(named: 'phone'),
        ),
      ),
    );

    blocTest<AuthBloc, AuthState>(
      'an edit arriving after sign-out does not sign the user back in',
      build: () => AuthBloc(repository),
      act: (bloc) => bloc.add(const AuthProfileUpdated(edited)),
      expect: () => const <AuthState>[],
    );
  });

  group('AuthLogoutRequested', () {
    blocTest<AuthBloc, AuthState>(
      'emits [Loading, Unauthenticated] on sign-out',
      setUp: () => when(
        () => repository.logout(),
      ).thenAnswer((_) async => const Ok(null)),
      build: () => AuthBloc(repository),
      act: (bloc) => bloc.add(const AuthLogoutRequested()),
      expect: () => const [AuthLoading(), AuthUnauthenticated()],
    );
  });

  group('state equality', () {
    // Guards the props contract directly: a field missing from props makes two
    // different states compare equal, emit becomes a no-op, and the UI silently
    // stops updating (02-flutter-state-guard.md).
    test('AuthAuthenticated compares by user', () {
      const other = User(id: 'u2', email: 'c@d.com', displayName: 'Omar');
      expect(const AuthAuthenticated(user), const AuthAuthenticated(user));
      expect(
        const AuthAuthenticated(user),
        isNot(const AuthAuthenticated(other)),
      );
    });

    test('AuthFailureState compares by failure', () {
      expect(
        const AuthFailureState(NetworkFailure()),
        const AuthFailureState(NetworkFailure()),
      );
      expect(
        const AuthFailureState(NetworkFailure()),
        isNot(const AuthFailureState(UnknownFailure())),
      );
      // Runtime-built failures must compare by value too — this is why Failure
      // extends Equatable rather than relying on const canonicalisation.
      // statusCode is read from a non-const source on purpose: with a literal
      // the compiler would canonicalise both instances and the assertion would
      // pass without Equatable doing any work at all.
      final statusCode = <int>[500].first;
      expect(
        AuthFailureState(
          ServerFailure('Server error.', statusCode: statusCode),
        ),
        AuthFailureState(
          ServerFailure('Server error.', statusCode: statusCode),
        ),
      );
    });
  });
}
