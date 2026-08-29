import 'package:nova_modest/core/error/result.dart';
import 'package:nova_modest/features/address/domain/entities/address.dart';

/// The shopper's saved delivery addresses.
///
/// Every method returns the **whole** resulting list rather than void, so a
/// bloc has one emit path for a read and for a mutation — the shape the cart
/// and the search history already use.
///
/// **Exactly one address is default, always.** That rule lives here and not in
/// a screen: checkout will need it too, and a rule restated by each consumer is
/// a rule one of them will get wrong.
abstract class AddressRepository {
  /// Newest last, with the default one first.
  Future<Result<List<Address>>> addresses();

  /// Adds [address] when its id is empty, or replaces the one it names.
  ///
  /// The first address saved becomes the default whatever it claims — a
  /// shopper with one address has no other candidate.
  Future<Result<List<Address>>> save(Address address);

  /// Drops one address. Removing the default promotes the next remaining one,
  /// so the list never ends up with none.
  Future<Result<List<Address>>> remove(String id);

  /// Makes one address the default and clears the flag from every other, in a
  /// single operation.
  Future<Result<List<Address>>> setDefault(String id);
}
