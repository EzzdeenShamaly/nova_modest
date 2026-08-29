import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nova_modest/core/error/failure.dart';
import 'package:nova_modest/core/error/result.dart';
import 'package:nova_modest/features/onboarding/domain/repositories/onboarding_repository.dart';
import 'package:nova_modest/features/onboarding/presentation/bloc/onboarding_bloc.dart';

class _MockOnboardingRepository extends Mock implements OnboardingRepository {}

void main() {
  late _MockOnboardingRepository repository;

  setUp(() => repository = _MockOnboardingRepository());

  group('OnboardingStatusRequested', () {
    blocTest<OnboardingBloc, OnboardingState>(
      'emits [Required] on a first launch',
      setUp: () => when(
        () => repository.isOnboardingRequired(),
      ).thenAnswer((_) async => const Ok(true)),
      build: () => OnboardingBloc(repository),
      act: (bloc) => bloc.add(const OnboardingStatusRequested()),
      expect: () => const [OnboardingRequired()],
    );

    blocTest<OnboardingBloc, OnboardingState>(
      'emits [NotRequired] once the flag is recorded',
      setUp: () => when(
        () => repository.isOnboardingRequired(),
      ).thenAnswer((_) async => const Ok(false)),
      build: () => OnboardingBloc(repository),
      act: (bloc) => bloc.add(const OnboardingStatusRequested()),
      expect: () => const [OnboardingNotRequired()],
    );

    blocTest<OnboardingBloc, OnboardingState>(
      'emits [FailureState] when the flag cannot be read',
      setUp: () => when(
        () => repository.isOnboardingRequired(),
      ).thenAnswer((_) async => const Err(CacheFailure())),
      build: () => OnboardingBloc(repository),
      act: (bloc) => bloc.add(const OnboardingStatusRequested()),
      expect: () => const [OnboardingFailureState(CacheFailure())],
    );

    blocTest<OnboardingBloc, OnboardingState>(
      'droppable: a duplicate status request is discarded',
      setUp: () =>
          when(() => repository.isOnboardingRequired()).thenAnswer((_) async {
            await Future<void>.delayed(const Duration(milliseconds: 30));
            return const Ok(true);
          }),
      build: () => OnboardingBloc(repository),
      act: (bloc) => bloc
        ..add(const OnboardingStatusRequested())
        ..add(const OnboardingStatusRequested()),
      wait: const Duration(milliseconds: 100),
      expect: () => const [OnboardingRequired()],
      verify: (_) => verify(() => repository.isOnboardingRequired()).called(1),
    );
  });

  group('OnboardingFinished', () {
    blocTest<OnboardingBloc, OnboardingState>(
      'records the flag and emits [NotRequired]',
      setUp: () => when(
        () => repository.markSeen(),
      ).thenAnswer((_) async => const Ok(null)),
      build: () => OnboardingBloc(repository),
      act: (bloc) => bloc.add(const OnboardingFinished()),
      expect: () => const [OnboardingNotRequired()],
      verify: (_) => verify(() => repository.markSeen()).called(1),
    );

    blocTest<OnboardingBloc, OnboardingState>(
      'still lets the user through when the write fails',
      setUp: () => when(
        () => repository.markSeen(),
      ).thenAnswer((_) async => const Err(CacheFailure())),
      build: () => OnboardingBloc(repository),
      act: (bloc) => bloc.add(const OnboardingFinished()),
      // Deliberate degradation: the user finished it, so trapping them behind a
      // disk error would be worse than replaying the intro next launch.
      expect: () => const [OnboardingNotRequired()],
    );
  });

  group('state equality', () {
    test('FailureState compares by failure', () {
      expect(
        const OnboardingFailureState(CacheFailure()),
        const OnboardingFailureState(CacheFailure()),
      );
      expect(
        const OnboardingFailureState(CacheFailure()),
        isNot(const OnboardingFailureState(UnknownFailure())),
      );
    });
  });
}
