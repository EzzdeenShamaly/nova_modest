import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:nova_modest/features/catalog/domain/entities/product_colour.dart';
import 'package:nova_modest/features/catalog/domain/entities/product_feature.dart';
import 'package:nova_modest/features/catalog/domain/entities/product_tag.dart';

part 'product.freezed.dart';
part 'product.g.dart';

/// A catalogue product.
///
/// [price] is a `num` in the catalogue's own currency; formatting it for a
/// reader is a presentation concern and happens in the widget, not here
/// (`01-flutter-architecture-guard.md`).
///
/// [imageUrl] is nullable on purpose: no artwork exists yet, and a card that
/// cannot render without one would be a card that cannot render at all.
///
/// [isSoldOut] is a property of the product, not of any one screen. The listing
/// dims the card and hides its favourite control; anything else showing the
/// product makes its own decision from the same flag.
///
/// There is **one** artwork field, [imageUrl], and it is the one the database
/// has: `products.image_url`. A second `images` list lived here until
/// 2026-09-19 and had no column behind it, so it was empty on every product the
/// server returned while the product page, the cart and the review all read it
/// — a beautiful card opening onto a placeholder. A gallery is the widget's
/// shape, not the entity's, until the schema grows one.
///
/// The detail fields — [description], [colours], [sizes], [features] —
/// default to empty rather than living on a separate entity. The detail view is
/// a *superset* of the listing view, not a different shape, and one class per
/// entity is this project's rule. A listing endpoint that omits them yields a
/// product whose detail fields are empty, which every screen already handles.
@freezed
abstract class Product with _$Product {
  const factory Product({
    required String id,
    required String name,
    required num price,
    @JsonKey(name: 'category_id') required String categoryId,
    @JsonKey(name: 'image_url') String? imageUrl,
    @JsonKey(name: 'is_sold_out') @Default(false) bool isSoldOut,
    @Default(<ProductTag>[]) List<ProductTag> tags,
    String? description,
    @Default(<ProductColour>[]) List<ProductColour> colours,
    @Default(<String>[]) List<String> sizes,
    @Default(<ProductFeature>[]) List<ProductFeature> features,
  }) = _Product;

  factory Product.fromJson(Map<String, dynamic> json) =>
      _$ProductFromJson(json);
}
