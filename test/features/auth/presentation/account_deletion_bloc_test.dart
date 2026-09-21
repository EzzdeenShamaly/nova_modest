import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nova_modest/core/error/failure.dart';
import 'package:nova_modest/core/error/result.dart';
import 'package:nova_modest/features/auth/domain/repositories/auth_repository.dart';
import 'package:nova_modest/features/auth/presentation/bloc/account_deletion_bloc.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late _MockAuthRepository repository;

  setUp(() => repository = _MockAuthRepository());

  blocTest<AccountDeletionBloc, AccountDeletionState>(
    'emits [InProgress, Succeeded] when the account is deleted',
    setUp: () => when(
      () => repository.deleteAccount(),
    ).thenAnswer((_) async => const Ok(null)),
    build: () => AccountDeletionBloc(repository),
    act: (bloc) => bloc.add(const AccountDeletionConfirmed()),
    expect: () => const [
      AccountDeletionInProgress(),
      AccountDeletionSucceeded(),
    ],
  );

  blocTest<AccountDeletionBloc, AccountDeletionState>(
    'emits [InProgress, Failed] carrying the refusal',
    setUp: () => when(() => repository.deleteAccount()).thenAnswer(
      (_) async => const Err(
        ValidationFailure('avatar_delete_failed', code: 'avatar_delete_failed'),
      ),
    ),
    build: () => AccountDeletionBloc(repository),
    act: (bloc) => bloc.add(const AccountDeletionConfirmed()),
    expect: () => const [
      AccountDeletionInProgress(),
      AccountDeletionFailed(
        ValidationFailure('avatar_delete_failed', code: 'avatar_delete_failed'),
      ),
    ],
  );

  blocTest<AccountDeletionBloc, AccountDeletionState>(
    'a second confirmation while the first is in flight sends nothing',
    // Latency on purpose, as in the other droppable tests: an instant stub
    // would let both through and pass for the wrong reason. This request is
    // irreversible, so the second one must never leave.
    setUp: () => when(() => repository.deleteAccount()).thenAnswer((_) async {
      await Future<void>.delayed(const Duration(milliseconds: 50));
      return const Ok(null);
    }),
    build: () => AccountDeletionBloc(repository),
    act: (bloc) => bloc
      ..add(const AccountDeletionConfirmed())
      ..add(const AccountDeletionConfirmed()),
    wait: const Duration(milliseconds: 200),
    verify: (_) => verify(() => repository.deleteAccount()).called(1),
  );
}
