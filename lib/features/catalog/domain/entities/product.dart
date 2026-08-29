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
/// The detail fields — [description], [images], [colours], [sizes], [features] —
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
    @JsonKey(name: 'is_favourite') @Default(false) bool isFavourite,
    @JsonKey(name: 'is_sold_out') @Default(false) bool isSoldOut,
    @Default(<ProductTag>[]) List<ProductTag> tags,
    String? description,

    /// Carousel artwork. Empty until real photography exists.
    @Default(<String>[]) List<String> images,
    @Default(<ProductColour>[]) List<ProductColour> colours,
    @Default(<String>[]) List<String> sizes,
    @Default(<ProductFeature>[]) List<ProductFeature> features,
  }) = _Product;

  factory Product.fromJson(Map<String, dynamic> json) =>
      _$ProductFromJson(json);
}
