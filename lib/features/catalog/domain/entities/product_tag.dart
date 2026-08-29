import 'package:freezed_annotation/freezed_annotation.dart';

part 'product_tag.freezed.dart';
part 'product_tag.g.dart';

/// An attribute a product carries — "daily", "occasions", "colourful".
///
/// Distinct from a category: a product belongs to exactly one category but may
/// carry several tags, and tags are what the listing screen's secondary chips
/// filter on.
///
/// Carries its own display name because the backend owns the wording, the same
/// way category names do. Tag labels are **data**, not UI strings, so they are
/// deliberately absent from the ARB files.
@freezed
abstract class ProductTag with _$ProductTag {
  const factory ProductTag({required String id, required String name}) =
      _ProductTag;

  factory ProductTag.fromJson(Map<String, dynamic> json) =>
      _$ProductTagFromJson(json);
}
