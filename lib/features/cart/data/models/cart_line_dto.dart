import 'package:freezed_annotation/freezed_annotation.dart';

part 'cart_line_dto.freezed.dart';
part 'cart_line_dto.g.dart';

/// What actually gets stored: ids and a quantity, never a product snapshot.
///
/// The product is re-read from the catalogue on every load, so a price change
/// or a sold-out flag reaches the cart immediately. Storing the product itself
/// would freeze whatever it cost the day it was added.
@freezed
abstract class CartLineDto with _$CartLineDto {
  const factory CartLineDto({
    @JsonKey(name: 'product_id') required String productId,
    @JsonKey(name: 'colour_id') String? colourId,
    String? size,
    @Default(1) int quantity,
  }) = _CartLineDto;

  factory CartLineDto.fromJson(Map<String, dynamic> json) =>
      _$CartLineDtoFromJson(json);
}
