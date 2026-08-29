import 'package:freezed_annotation/freezed_annotation.dart';

part 'product_colour.freezed.dart';
part 'product_colour.g.dart';

/// A colour the garment actually comes in.
///
/// **Not a design-system colour.** [hex] is the product's own colour, the same
/// kind of content as its name and price — a swatch that rendered anything else
/// would misinform the shopper. It arrives from the backend as a string and is
/// parsed where it is drawn, so no literal colour appears in widget code and the
/// palette does not grow (`12-flutter-design-system-guard.md`).
///
/// The domain layer stays framework-free: this holds a string, never a
/// `dart:ui` `Color`.
@freezed
abstract class ProductColour with _$ProductColour {
  const factory ProductColour({
    required String id,
    required String name,

    /// `#RRGGBB`, as the backend supplies it.
    required String hex,
  }) = _ProductColour;

  factory ProductColour.fromJson(Map<String, dynamic> json) =>
      _$ProductColourFromJson(json);
}
