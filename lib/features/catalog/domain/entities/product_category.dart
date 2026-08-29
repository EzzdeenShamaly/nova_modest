import 'package:freezed_annotation/freezed_annotation.dart';

part 'product_category.freezed.dart';
part 'product_category.g.dart';

/// A catalogue category, as the backend defines it.
///
/// Named `ProductCategory` rather than `Category` because `Category` collides
/// with a Flutter framework type and the resulting import shadowing is a
/// genuinely confusing error to read.
///
/// The "All" chip on Home is **not** one of these — it is a UI affordance with
/// its own localized label, not a row the backend returns.
@freezed
abstract class ProductCategory with _$ProductCategory {
  const factory ProductCategory({required String id, required String name}) =
      _ProductCategory;

  factory ProductCategory.fromJson(Map<String, dynamic> json) =>
      _$ProductCategoryFromJson(json);
}
