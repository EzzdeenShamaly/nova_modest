import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nova_modest/core/error/failure.dart';
import 'package:nova_modest/core/error/result.dart';
import 'package:nova_modest/features/address/domain/entities/address.dart';
import 'package:nova_modest/features/address/domain/repositories/address_repository.dart';
import 'package:nova_modest/features/address/presentation/bloc/address_form_bloc.dart';
import 'package:nova_modest/features/address/presentation/bloc/address_list_bloc.dart';

class _MockAddressRepository extends Mock implements AddressRepository {}

void main() {
  late _MockAddressRepository repository;

  const home = Address(
    id: 'a1',
    kind: AddressKind.home,
    label: 'المنزل',
    recipientName: 'سارة',
    phone: '+966 50 123 4567',
    country: 'المملكة العربية السعودية',
    region: 'حي العليا',
    city: 'الرياض',
    street: 'شارع الملك فهد، مبنى ٤٥',
    isDefault: true,
  );
  const work = Address(
    id: 'a2',
    kind: AddressKind.work,
    label: 'العمل',
    recipientName: 'سارة',
    phone: '+966 11 987 6543',
    country: 'المملكة العربية السعودية',
    region: 'طريق العروبة',
    city: 'الرياض',
    street: 'برج المملكة، الطابق ٢٢',
  );

  setUpAll(() => registerFallbackValue(home));

  setUp(() => repository = _MockAddressRepository());

  group('AddressListBloc', () {
    void givenList(Result<List<Address>> result) =>
        when(() => repository.addresses()).thenAnswer((_) async => result);

    blocTest<AddressListBloc, AddressListState>(
      'an empty list is its own state, not a list with no cards',
      setUp: () => givenList(const Ok(<Address>[])),
      build: () => AddressListBloc(repository),
      act: (bloc) => bloc.add(const AddressesRequested()),
      expect: () => const [AddressListLoading(), AddressListEmpty()],
    );

    blocTest<AddressListBloc, AddressListState>(
      'a stocked list arrives in the order the repository sorted it',
      setUp: () => givenList(const Ok([home, work])),
      build: () => AddressListBloc(repository),
      act: (bloc) => bloc.add(const AddressesRequested()),
      expect: () => const [
        AddressListLoading(),
        AddressListLoaded([home, work]),
      ],
    );

    blocTest<AddressListBloc, AddressListState>(
      'a failed read is an error state with a retry behind it',
      setUp: () => givenList(const Err(NetworkFailure())),
      build: () => AddressListBloc(repository),
      act: (bloc) => bloc.add(const AddressesRequested()),
      expect: () => const [
        AddressListLoading(),
        AddressListError(NetworkFailure()),
      ],
    );

    blocTest<AddressListBloc, AddressListState>(
      'deleting does not pass through loading',
      setUp: () => when(
        () => repository.remove(any()),
      ).thenAnswer((_) async => const Ok([home])),
      build: () => AddressListBloc(repository),
      act: (bloc) => bloc.add(const AddressDeleted('a2')),
      // Exactly one state: a spinner between two versions of the same list is
      // a flicker, not information.
      expect: () => const [
        AddressListLoaded([home]),
      ],
      verify: (_) => verify(() => repository.remove('a2')).called(1),
    );

    blocTest<AddressListBloc, AddressListState>(
      'deleting the last address lands on the empty state',
      setUp: () => when(
        () => repository.remove(any()),
      ).thenAnswer((_) async => const Ok(<Address>[])),
      build: () => AddressListBloc(repository),
      act: (bloc) => bloc.add(const AddressDeleted('a1')),
      expect: () => const [AddressListEmpty()],
    );

    blocTest<AddressListBloc, AddressListState>(
      'choosing a default hands the whole re-sorted list back',
      setUp: () => when(
        () => repository.setDefault(any()),
      ).thenAnswer((_) async => const Ok([work, home])),
      build: () => AddressListBloc(repository),
      act: (bloc) => bloc.add(const AddressDefaultSelected('a2')),
      expect: () => const [
        AddressListLoaded([work, home]),
      ],
      // The "exactly one default" rule is the repository's, not this bloc's:
      // checkout will need it too.
      verify: (_) => verify(() => repository.setDefault('a2')).called(1),
    );

    blocTest<AddressListBloc, AddressListState>(
      'a failed mutation surfaces rather than being swallowed',
      setUp: () => when(
        () => repository.remove(any()),
      ).thenAnswer((_) async => const Err(NotFoundFailure())),
      build: () => AddressListBloc(repository),
      act: (bloc) => bloc.add(const AddressDeleted('gone')),
      expect: () => const [AddressListError(NotFoundFailure())],
    );
  });

  group('AddressFormBloc', () {
    blocTest<AddressFormBloc, AddressFormState>(
      'emits [Submitting, Succeeded] carrying the resulting list',
      setUp: () => when(
        () => repository.save(any()),
      ).thenAnswer((_) async => const Ok([home, work])),
      build: () => AddressFormBloc(repository),
      act: (bloc) => bloc.add(const AddressFormSubmitted(work)),
      expect: () => const [
        AddressFormSubmitting(),
        AddressFormSucceeded([home, work]),
      ],
      verify: (_) => verify(() => repository.save(work)).called(1),
    );

    blocTest<AddressFormBloc, AddressFormState>(
      'emits [Submitting, Failure] when the save fails',
      setUp: () => when(
        () => repository.save(any()),
      ).thenAnswer((_) async => const Err(NetworkFailure())),
      build: () => AddressFormBloc(repository),
      act: (bloc) => bloc.add(const AddressFormSubmitted(work)),
      expect: () => const [
        AddressFormSubmitting(),
        AddressFormFailureState(NetworkFailure()),
      ],
    );

    blocTest<AddressFormBloc, AddressFormState>(
      'a double tap saves once, so a new address is not created twice',
      // Latency on purpose: droppable only drops while the previous handler is
      // still running, so an instant stub would let both through and the test
      // would pass for the wrong reason.
      setUp: () => when(() => repository.save(any())).thenAnswer((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 50));
        return const Ok([home]);
      }),
      build: () => AddressFormBloc(repository),
      act: (bloc) => bloc
        ..add(const AddressFormSubmitted(work))
        ..add(const AddressFormSubmitted(work)),
      wait: const Duration(milliseconds: 200),
      verify: (_) => verify(() => repository.save(any())).called(1),
    );

    test('only Submitting reports itself as in flight', () {
      expect(const AddressFormIdle().isSubmitting, isFalse);
      expect(const AddressFormSubmitting().isSubmitting, isTrue);
      expect(const AddressFormSucceeded([home]).isSubmitting, isFalse);
      expect(
        const AddressFormFailureState(NetworkFailure()).isSubmitting,
        isFalse,
      );
    });
  });

  group('state equality', () {
    test('Loaded compares by the addresses it holds', () {
      const a = AddressListLoaded([home, work]);
      const same = AddressListLoaded([home, work]);
      const reordered = AddressListLoaded([work, home]);

      expect(a, same);
      // Without the list in props, choosing a new default would emit a state
      // equal to the previous one and the cards would never re-order.
      expect(a, isNot(reordered));
    });

    test('an address compares by every field, default included', () {
      expect(home, home.copyWith());
      expect(home, isNot(home.copyWith(isDefault: false)));
      expect(home, isNot(home.copyWith(label: 'البيت')));
    });
  });
}
