// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cart_line_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_CartLineDto _$CartLineDtoFromJson(Map<String, dynamic> json) => _CartLineDto(
  productId: json['product_id'] as String,
  colourId: json['colour_id'] as String?,
  size: json['size'] as String?,
  quantity: (json['quantity'] as num?)?.toInt() ?? 1,
);

Map<String, dynamic> _$CartLineDtoToJson(_CartLineDto instance) =>
    <String, dynamic>{
      'product_id': instance.productId,
      'colour_id': instance.colourId,
      'size': instance.size,
      'quantity': instance.quantity,
    };
