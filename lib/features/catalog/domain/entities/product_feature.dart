import 'package:freezed_annotation/freezed_annotation.dart';

part 'product_feature.freezed.dart';
part 'product_feature.g.dart';

/// One selling point in a product's details list — fabric, fit, care.
///
/// [icon] is an identifier the backend chooses, not a glyph: the data owns the
/// meaning and the widget owns the drawing, so a new feature kind added by the
/// backend renders with a fallback marker instead of crashing or shipping a
/// blank row.
@freezed
abstract class ProductFeature with _$ProductFeature {
  const factory ProductFeature({
    required String text,

    /// `fabric`, `fit`, `care`, … Unknown values fall back to a plain marker.
    String? icon,
  }) = _ProductFeature;

  factory ProductFeature.fromJson(Map<String, dynamic> json) =>
      _$ProductFeatureFromJson(json);
}
