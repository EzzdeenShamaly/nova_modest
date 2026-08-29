import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nova_modest/core/error/failure.dart';
import 'package:nova_modest/core/error/result.dart';
import 'package:nova_modest/features/auth/domain/entities/user.dart';
import 'package:nova_modest/features/auth/domain/repositories/auth_repository.dart';
import 'package:nova_modest/features/auth/presentation/bloc/sign_in_bloc.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late _MockAuthRepository repository;

  const user = User(id: 'u1', email: 'a@b.com', displayName: 'Sara');

  setUp(() => repository = _MockAuthRepository());

  group('Google', () {
    blocTest<SignInBloc, SignInState>(
      'emits [Submitting, Succeeded] when Google returns a user',
      setUp: () => when(
        () => repository.signInWithGoogle(),
      ).thenAnswer((_) async => const Ok(user)),
      build: () => SignInBloc(repository),
      act: (bloc) => bloc.add(const SignInGoogleRequested()),
      expect: () => const [SignInSubmitting(), SignInSucceeded(user)],
    );

    blocTest<SignInBloc, SignInState>(
      'emits [Submitting, Failure] when Google fails',
      setUp: () => when(
        () => repository.signInWithGoogle(),
      ).thenAnswer((_) async => const Err(NetworkFailure())),
      build: () => SignInBloc(repository),
      act: (bloc) => bloc.add(const SignInGoogleRequested()),
      expect: () => const [
        SignInSubmitting(),
        SignInFailureState(NetworkFailure()),
      ],
    );

    blocTest<SignInBloc, SignInState>(
      'droppable: a double tap runs one sign-in',
      setUp: () =>
          when(() => repository.signInWithGoogle()).thenAnswer((_) async {
            await Future<void>.delayed(const Duration(milliseconds: 30));
            return const Ok(user);
          }),
      build: () => SignInBloc(repository),
      act: (bloc) => bloc
        ..add(const SignInGoogleRequested())
        ..add(const SignInGoogleRequested()),
      wait: const Duration(milliseconds: 100),
      expect: () => const [SignInSubmitting(), SignInSucceeded(user)],
      verify: (_) => verify(() => repository.signInWithGoogle()).called(1),
    );
  });

  group('email code', () {
    blocTest<SignInBloc, SignInState>(
      'emits [Submitting, CodeSent] carrying the address to the next step',
      setUp: () => when(
        () => repository.requestEmailCode(any()),
      ).thenAnswer((_) async => const Ok(null)),
      build: () => SignInBloc(repository),
      act: (bloc) => bloc.add(const SignInEmailSubmitted('a@b.com')),
      expect: () => const [SignInSubmitting(), SignInCodeSent('a@b.com')],
      verify: (_) =>
          verify(() => repository.requestEmailCode('a@b.com')).called(1),
    );

    blocTest<SignInBloc, SignInState>(
      'emits [Submitting, Succeeded] when the code is accepted',
      setUp: () => when(
        () => repository.verifyEmailCode(
          email: any(named: 'email'),
          code: any(named: 'code'),
        ),
      ).thenAnswer((_) async => const Ok(user)),
      build: () => SignInBloc(repository),
      act: (bloc) =>
          bloc.add(const SignInCodeSubmitted(email: 'a@b.com', code: '123456')),
      expect: () => const [SignInSubmitting(), SignInSucceeded(user)],
    );

    blocTest<SignInBloc, SignInState>(
      'emits [Submitting, Failure] when the code is rejected',
      setUp: () => when(
        () => repository.verifyEmailCode(
          email: any(named: 'email'),
          code: any(named: 'code'),
        ),
      ).thenAnswer((_) async => const Err(UnauthorizedFailure())),
      build: () => SignInBloc(repository),
      act: (bloc) =>
          bloc.add(const SignInCodeSubmitted(email: 'a@b.com', code: '000000')),
      expect: () => const [
        SignInSubmitting(),
        SignInFailureState(UnauthorizedFailure()),
      ],
    );

    blocTest<SignInBloc, SignInState>(
      'a resend returns to CodeSent so the user stays on the code screen',
      setUp: () => when(
        () => repository.requestEmailCode(any()),
      ).thenAnswer((_) async => const Ok(null)),
      build: () => SignInBloc(repository),
      act: (bloc) => bloc.add(const SignInCodeResendRequested('a@b.com')),
      expect: () => const [SignInSubmitting(), SignInCodeSent('a@b.com')],
    );
  });

  group('state equality', () {
    test('CodeSent compares by address', () {
      expect(const SignInCodeSent('a@b.com'), const SignInCodeSent('a@b.com'));
      expect(
        const SignInCodeSent('a@b.com'),
        isNot(const SignInCodeSent('c@d.com')),
      );
    });
  });
}
