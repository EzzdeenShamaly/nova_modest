import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:nova_modest/features/catalog/domain/entities/product.dart';
import 'package:nova_modest/features/catalog/domain/entities/product_colour.dart';

part 'cart_item.freezed.dart';

/// One line in the cart: a product, plus the choices the shopper made about it.
///
/// Carries the whole [Product] rather than an id, so the screen can render a
/// line without a second lookup. It is **not** what gets persisted — storage
/// keeps ids only and the product is fetched fresh from the catalogue on every
/// load, so a price can never go stale in someone's cart. See `CartLineDto`.
///
/// No `fromJson`/`toJson` on purpose: serialising this would be the stale-price
/// design that was deliberately rejected.
@freezed
abstract class CartItem with _$CartItem {
  const CartItem._();

  const factory CartItem({
    required Product product,
    String? colourId,
    String? size,
    @Default(1) int quantity,
  }) = _CartItem;

  /// The most one line may hold.
  ///
  /// Matches `ProductDetailBloc.maxQuantity` by value but is a separate rule:
  /// that one caps what a single "add to cart" may request, this caps what one
  /// line may accumulate across several adds. Both stand in for real stock,
  /// which the backend will supply.
  static const int maxQuantity = 10;

  /// Identity of the line.
  ///
  /// The same garment in two sizes is two lines, so the key is the product and
  /// every choice made about it — not the product alone.
  String get lineId => '${product.id}|${colourId ?? ''}|${size ?? ''}';

  num get lineTotal => product.price * quantity;

  /// The chosen colour, resolved against the product's current options.
  ///
  /// Null when the product offers no colours, or when the stored choice is no
  /// longer offered — the line still shows, just without a colour.
  ProductColour? get colour {
    for (final option in product.colours) {
      if (option.id == colourId) return option;
    }
    return null;
  }
}
