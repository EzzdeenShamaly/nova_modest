import 'package:injectable/injectable.dart';
import 'package:nova_modest/core/error/failure.dart';
import 'package:nova_modest/core/error/result.dart';
import 'package:nova_modest/features/address/domain/entities/address.dart';
import 'package:nova_modest/features/address/domain/repositories/address_repository.dart';

/// Stands in for the addresses backend.
///
/// Registered in the `test` environment. The running app uses
/// `SupabaseAddressRepository`.
///
/// Held **in memory**, not in `SharedPreferences`: an address carries a
/// recipient's name, their phone number and where they live, which is the PII
/// `03-flutter-security-guard` reserves the keystore for. Persisting it would
/// mean either plaintext preferences, which that rule forbids, or widening the
/// `TokenStorage` seam for the sake of a stand-in — the same call made for the
/// edited profile, and accepted on the same terms (user, 2026-08-22). Edits
/// survive navigation, not a restart.
///
/// The two seeded rows are the design's own (Figma `1:1767`), so the screens are
/// built against the content they were designed for.
@LazySingleton(as: AddressRepository, env: [Environment.test])
class FakeAddressRepository implements AddressRepository {
  FakeAddressRepository();

  /// Long enough for the loading state to be real, short enough not to irritate.
  static const Duration _latency = Duration(milliseconds: 600);

  static const List<Address> _seed = [
    Address(
      id: 'a1',
      kind: AddressKind.home,
      label: 'المنزل',
      recipientName: 'السيد أحمد عبدالله',
      phone: '+966 50 123 4567',
      country: 'المملكة العربية السعودية',
      region: 'حي العليا',
      city: 'الرياض',
      street: 'شارع الملك فهد، مبنى ٤٥',
      postalCode: '١٢٢١١',
      isDefault: true,
    ),
    Address(
      id: 'a2',
      kind: AddressKind.work,
      label: 'العمل',
      recipientName: 'السيد أحمد عبدالله',
      phone: '+966 11 987 6543',
      country: 'المملكة العربية السعودية',
      region: 'طريق العروبة',
      city: 'الرياض',
      street: 'برج المملكة، الطابق ٢٢',
      postalCode: '١١٣٢١',
    ),
  ];

  List<Address> _addresses = List<Address>.of(_seed);

  int _nextId = _seed.length + 1;

  @override
  Future<Result<List<Address>>> addresses() async {
    await Future<void>.delayed(_latency);
    return Ok(_sorted(_addresses));
  }

  @override
  Future<Result<List<Address>>> save(Address address) async {
    await Future<void>.delayed(_latency);

    final isNew = address.id.isEmpty;
    final entry = isNew ? address.copyWith(id: 'a${_nextId++}') : address;

    if (!isNew && _addresses.every((existing) => existing.id != entry.id)) {
      // Editing something that is no longer there. Reported rather than
      // silently re-added, which would resurrect an address the shopper
      // deleted on another device.
      return const Err(NotFoundFailure());
    }

    final next = isNew
        ? [..._addresses, entry]
        : [
            for (final existing in _addresses)
              if (existing.id == entry.id) entry else existing,
          ];

    // The first address has no other candidate, so it is the default whatever
    // it claims.
    _addresses = _applyDefault(
      next,
      defaultId: (entry.isDefault || next.length == 1) ? entry.id : null,
    );
    return Ok(_sorted(_addresses));
  }

  @override
  Future<Result<List<Address>>> remove(String id) async {
    await Future<void>.delayed(_latency);

    final removed = _addresses.where((address) => address.id == id).firstOrNull;
    if (removed == null) return const Err(NotFoundFailure());

    final next = [
      for (final address in _addresses)
        if (address.id != id) address,
    ];

    // Removing the default promotes the next one, so the list never ends up
    // with no default at all.
    _addresses = _applyDefault(
      next,
      defaultId: removed.isDefault && next.isNotEmpty ? next.first.id : null,
    );
    return Ok(_sorted(_addresses));
  }

  @override
  Future<Result<List<Address>>> setDefault(String id) async {
    await Future<void>.delayed(_latency);

    if (_addresses.every((address) => address.id != id)) {
      return const Err(NotFoundFailure());
    }

    _addresses = _applyDefault(_addresses, defaultId: id);
    return Ok(_sorted(_addresses));
  }

  /// Makes [defaultId] the only default. A null [defaultId] leaves whichever
  /// one already holds the flag alone.
  static List<Address> _applyDefault(
    List<Address> addresses, {
    required String? defaultId,
  }) {
    if (defaultId == null) return addresses;
    return [
      for (final address in addresses)
        address.copyWith(isDefault: address.id == defaultId),
    ];
  }

  /// Default first, the rest in the order they were added — the order the
  /// design's list draws.
  static List<Address> _sorted(List<Address> addresses) => [
    ...addresses.where((address) => address.isDefault),
    ...addresses.where((address) => !address.isDefault),
  ];
}
