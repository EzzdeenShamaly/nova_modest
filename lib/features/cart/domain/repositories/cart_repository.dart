import 'package:nova_modest/core/error/result.dart';
import 'package:nova_modest/features/cart/domain/entities/cart_item.dart';
import 'package:nova_modest/features/catalog/domain/entities/product.dart';

/// Owns the shopper's cart.
///
/// Every method returns the **whole** resulting cart rather than void, so the
/// bloc has one emit path for a load and for a mutation instead of a read
/// after every write.
abstract class CartRepository {
  /// The code carried by the [ValidationFailure] [add] returns when the cart
  /// already holds [CartItem.maxLines] lines.
  ///
  /// Part of this interface, not of one implementation, because the bloc reads
  /// it to tell a cart that is **declining** from a cart that has **failed** —
  /// and those are different screens. Nothing is written when it is returned.
  static const String fullCode = 'cart_full';

  /// The cart as it stands, with each product refreshed from the catalogue.
  Future<Result<List<CartItem>>> load();

  /// Adds [product] with the given choices.
  ///
  /// A line matching the same product, colour and size has its quantity raised
  /// instead of a second line appearing; the result is capped at
  /// [CartItem.maxQuantity].
  ///
  /// Returns `Err(ValidationFailure(code: `[fullCode]`))` when the addition
  /// would be the twenty-first **line**. Raising the quantity of a line that is
  /// already there is never refused — the limit counts lines, as
  /// `place_order` does.
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

  /// Empties the cart.
  ///
  /// Called when an order is placed, not from any control the shopper taps:
  /// leaving the lines behind means they come back to a cart of things they
  /// have already bought and can buy again by accident. Returns the empty list
  /// like every other method here, so the bloc has one emit path.
  Future<Result<List<CartItem>>> clear();
}
