// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Product _$ProductFromJson(Map<String, dynamic> json) => _Product(
  id: json['id'] as String,
  name: json['name'] as String,
  price: json['price'] as num,
  categoryId: json['category_id'] as String,
  imageUrl: json['image_url'] as String?,
  isFavourite: json['is_favourite'] as bool? ?? false,
  isSoldOut: json['is_sold_out'] as bool? ?? false,
  tags:
      (json['tags'] as List<dynamic>?)
          ?.map((e) => ProductTag.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <ProductTag>[],
  description: json['description'] as String?,
  images:
      (json['images'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const <String>[],
  colours:
      (json['colours'] as List<dynamic>?)
          ?.map((e) => ProductColour.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <ProductColour>[],
  sizes:
      (json['sizes'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const <String>[],
  features:
      (json['features'] as List<dynamic>?)
          ?.map((e) => ProductFeature.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <ProductFeature>[],
);

Map<String, dynamic> _$ProductToJson(_Product instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'price': instance.price,
  'category_id': instance.categoryId,
  'image_url': instance.imageUrl,
  'is_favourite': instance.isFavourite,
  'is_sold_out': instance.isSoldOut,
  'tags': instance.tags,
  'description': instance.description,
  'images': instance.images,
  'colours': instance.colours,
  'sizes': instance.sizes,
  'features': instance.features,
};
