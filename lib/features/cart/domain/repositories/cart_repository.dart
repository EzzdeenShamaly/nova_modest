import 'package:nova_modest/core/error/result.dart';
import 'package:nova_modest/features/cart/domain/entities/cart_item.dart';
import 'package:nova_modest/features/catalog/domain/entities/product.dart';

/// Owns the shopper's cart.
///
/// Every method returns the **whole** resulting cart rather than void, so the
/// bloc has one emit path for a load and for a mutation instead of a read
/// after every write.
abstract class CartRepository {
  /// The cart as it stands, with each product refreshed from the catalogue.
  Future<Result<List<CartItem>>> load();

  /// Adds [product] with the given choices.
  ///
  /// A line matching the same product, colour and size has its quantity raised
  /// instead of a second line appearing; the result is capped at
  /// [CartItem.maxQuantity].
  Future<Result<List<CartItem>>> add({
    required Product product,
    String? colourId,
    String? size,
    int quantity = 1,
  });

  /// Sets the quantity of one line, identified by [CartItem.lineId].
  Future<Result<List<CartItem>>> updateQuantity(String lineId, int quantity);

  /// Drops one line entirely.
  Future<Result<List<CartItem>>> remove(String lineId);
}
