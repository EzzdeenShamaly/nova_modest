import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nova_modest/core/error/failure.dart';
import 'package:nova_modest/core/error/result.dart';
import 'package:nova_modest/features/auth/domain/entities/user.dart';
import 'package:nova_modest/features/auth/domain/repositories/auth_repository.dart';
import 'package:nova_modest/features/auth/presentation/bloc/profile_edit_bloc.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late _MockAuthRepository repository;

  const saved = User(
    id: 'u1',
    email: 'sara@example.com',
    displayName: 'سارة أحمد',
    phone: '+966 55 000 1111',
  );

  setUp(() => repository = _MockAuthRepository());

  void given(Result<User> result) => when(
    () => repository.updateProfile(
      displayName: any(named: 'displayName'),
      phone: any(named: 'phone'),
    ),
  ).thenAnswer((_) async => result);

  group('submitting', () {
    blocTest<ProfileEditBloc, ProfileEditState>(
      'emits [Submitting, Succeeded] carrying the saved user',
      setUp: () => given(const Ok(saved)),
      build: () => ProfileEditBloc(repository),
      act: (bloc) => bloc.add(
        const ProfileEditSubmitted(
          displayName: 'سارة أحمد',
          phone: '+966 55 000 1111',
        ),
      ),
      expect: () => const [
        ProfileEditSubmitting(),
        ProfileEditSucceeded(saved),
      ],
      verify: (_) => verify(
        () => repository.updateProfile(
          displayName: 'سارة أحمد',
          phone: '+966 55 000 1111',
        ),
      ).called(1),
    );

    blocTest<ProfileEditBloc, ProfileEditState>(
      'a null phone is passed through as a clear, not omitted',
      setUp: () => given(const Ok(saved)),
      build: () => ProfileEditBloc(repository),
      act: (bloc) => bloc.add(const ProfileEditSubmitted(displayName: 'سارة')),
      verify: (_) => verify(
        () => repository.updateProfile(displayName: 'سارة', phone: null),
      ).called(1),
    );

    blocTest<ProfileEditBloc, ProfileEditState>(
      'emits [Submitting, Failure] when the save fails',
      setUp: () => given(const Err(NetworkFailure())),
      build: () => ProfileEditBloc(repository),
      act: (bloc) => bloc.add(const ProfileEditSubmitted(displayName: 'سارة')),
      expect: () => const [
        ProfileEditSubmitting(),
        ProfileEditFailureState(NetworkFailure()),
      ],
    );

    blocTest<ProfileEditBloc, ProfileEditState>(
      'a double tap writes once',
      // Latency on purpose: droppable only drops an event while the previous
      // handler is still running, so a stub that returns instantly would let
      // both through and the test would pass for the wrong reason.
      setUp: () =>
          when(
            () => repository.updateProfile(
              displayName: any(named: 'displayName'),
              phone: any(named: 'phone'),
            ),
          ).thenAnswer((_) async {
            await Future<void>.delayed(const Duration(milliseconds: 50));
            return const Ok(saved);
          }),
      build: () => ProfileEditBloc(repository),
      act: (bloc) => bloc
        ..add(const ProfileEditSubmitted(displayName: 'سارة'))
        ..add(const ProfileEditSubmitted(displayName: 'سارة')),
      wait: const Duration(milliseconds: 200),
      // droppable: without it two writes go out and their responses can resolve
      // out of order.
      verify: (_) => verify(
        () => repository.updateProfile(
          displayName: any(named: 'displayName'),
          phone: any(named: 'phone'),
        ),
      ).called(1),
    );
  });

  group('state', () {
    test('only Submitting reports itself as in flight', () {
      expect(const ProfileEditIdle().isSubmitting, isFalse);
      expect(const ProfileEditSubmitting().isSubmitting, isTrue);
      expect(const ProfileEditSucceeded(saved).isSubmitting, isFalse);
      expect(
        const ProfileEditFailureState(NetworkFailure()).isSubmitting,
        isFalse,
      );
    });

    test('Succeeded compares by user', () {
      const other = User(id: 'u1', email: 'sara@example.com', displayName: 'س');

      expect(
        const ProfileEditSucceeded(saved),
        const ProfileEditSucceeded(saved),
      );
      // Without the user in props, saving twice would emit a state equal to the
      // previous one and the listener would never fire the second time.
      expect(
        const ProfileEditSucceeded(saved),
        isNot(const ProfileEditSucceeded(other)),
      );
    });
  });
}
