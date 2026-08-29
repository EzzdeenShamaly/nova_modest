import 'package:flutter_test/flutter_test.dart';
import 'package:nova_modest/core/error/failure.dart';
import 'package:nova_modest/core/error/result.dart';
import 'package:nova_modest/features/address/data/repositories/fake_address_repository.dart';
import 'package:nova_modest/features/address/domain/entities/address.dart';

void main() {
  late FakeAddressRepository repository;

  const draft = Address(
    id: '',
    kind: AddressKind.other,
    label: 'بيت أمي',
    recipientName: 'سارة أحمد',
    phone: '+966 55 000 1111',
    country: 'المملكة العربية السعودية',
    region: 'حي الشاطئ',
    city: 'جدة',
    street: 'طريق الكورنيش، مبنى ٣',
  );

  setUp(() => repository = FakeAddressRepository());

  List<Address> listOf(Result<List<Address>> result) =>
      (result as Ok<List<Address>>).value;

  Future<List<Address>> all() async => listOf(await repository.addresses());

  group('reading', () {
    test('starts with the design\'s two addresses, default first', () async {
      final addresses = await all();

      expect(addresses.map((address) => address.id), ['a1', 'a2']);
      expect(addresses.first.isDefault, isTrue);
    });
  });

  group('saving', () {
    test('an empty id is a new address and is given one', () async {
      final saved = listOf(await repository.save(draft));

      expect(saved, hasLength(3));
      expect(saved.last.id, isNotEmpty);
      expect(saved.last.label, 'بيت أمي');
    });

    test('an existing id replaces rather than appending', () async {
      final existing = (await all()).first;

      final saved = listOf(
        await repository.save(existing.copyWith(label: 'البيت')),
      );

      expect(saved, hasLength(2));
      expect(saved.firstWhere((a) => a.id == existing.id).label, 'البيت');
    });

    test(
      'editing something already deleted is reported, not re-added',
      () async {
        await repository.remove('a2');

        final result = await repository.save(
          draft.copyWith(id: 'a2', label: 'عاد من الموت'),
        );

        // Silently re-adding would resurrect an address deleted on another
        // device.
        expect((result as Err<List<Address>>).failure, isA<NotFoundFailure>());
        expect(await all(), hasLength(1));
      },
    );

    test('saving one as default clears the flag from every other', () async {
      final saved = listOf(
        await repository.save(draft.copyWith(isDefault: true)),
      );

      expect(saved.where((address) => address.isDefault), hasLength(1));
      expect(saved.first.label, 'بيت أمي');
    });
  });

  group('the default', () {
    test('the very first address is default whatever it claims', () async {
      await repository.remove('a1');
      await repository.remove('a2');
      expect(await all(), isEmpty);

      final saved = listOf(await repository.save(draft));

      // A shopper with one address has no other candidate.
      expect(saved.single.isDefault, isTrue);
    });

    test('setting one clears the rest, in a single operation', () async {
      final saved = listOf(await repository.setDefault('a2'));

      expect(saved.where((address) => address.isDefault), hasLength(1));
      expect(saved.firstWhere((a) => a.id == 'a2').isDefault, isTrue);
      expect(saved.firstWhere((a) => a.id == 'a1').isDefault, isFalse);
    });

    test('the default sorts to the front', () async {
      final saved = listOf(await repository.setDefault('a2'));

      expect(saved.map((address) => address.id), ['a2', 'a1']);
    });

    test('removing the default promotes the next one', () async {
      final saved = listOf(await repository.remove('a1'));

      // Never a list with no default at all.
      expect(saved.single.id, 'a2');
      expect(saved.single.isDefault, isTrue);
    });

    test('removing a non-default leaves the default alone', () async {
      final saved = listOf(await repository.remove('a2'));

      expect(saved.single.id, 'a1');
      expect(saved.single.isDefault, isTrue);
    });

    test('an unknown id is reported for both mutations', () async {
      expect(
        (await repository.remove('nope') as Err<List<Address>>).failure,
        isA<NotFoundFailure>(),
      );
      expect(
        (await repository.setDefault('nope') as Err<List<Address>>).failure,
        isA<NotFoundFailure>(),
      );
    });
  });

  group('formatting', () {
    test('the postal block is the design\'s five lines', () async {
      final home = (await all()).first;

      expect(home.postalLines, [
        'السيد أحمد عبدالله',
        'شارع الملك فهد، مبنى ٤٥',
        'حي العليا، الرياض ١٢٢١١',
        'المملكة العربية السعودية',
        '+966 50 123 4567',
      ]);
    });

    test('a missing postal code leaves no dangling space', () async {
      final saved = listOf(await repository.save(draft));

      expect(saved.last.postalLines[2], 'حي الشاطئ، جدة');
    });

    test('the short summary reads widest first, as checkout draws it', () async {
      final home = (await all()).first;

      expect(
        home.shortSummary,
        'المملكة العربية السعودية، الرياض، حي العليا، شارع الملك فهد، مبنى ٤٥',
      );
    });
  });
}
