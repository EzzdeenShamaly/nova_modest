// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'product.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Product {

 String get id; String get name; num get price;@JsonKey(name: 'category_id') String get categoryId;@JsonKey(name: 'image_url') String? get imageUrl;@JsonKey(name: 'is_favourite') bool get isFavourite;@JsonKey(name: 'is_sold_out') bool get isSoldOut; List<ProductTag> get tags; String? get description;/// Carousel artwork. Empty until real photography exists.
 List<String> get images; List<ProductColour> get colours; List<String> get sizes; List<ProductFeature> get features;
/// Create a copy of Product
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProductCopyWith<Product> get copyWith => _$ProductCopyWithImpl<Product>(this as Product, _$identity);

  /// Serializes this Product to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Product&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.price, price) || other.price == price)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.imageUrl, imageUrl) || other.imageUrl == imageUrl)&&(identical(other.isFavourite, isFavourite) || other.isFavourite == isFavourite)&&(identical(other.isSoldOut, isSoldOut) || other.isSoldOut == isSoldOut)&&const DeepCollectionEquality().equals(other.tags, tags)&&(identical(other.description, description) || other.description == description)&&const DeepCollectionEquality().equals(other.images, images)&&const DeepCollectionEquality().equals(other.colours, colours)&&const DeepCollectionEquality().equals(other.sizes, sizes)&&const DeepCollectionEquality().equals(other.features, features));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,price,categoryId,imageUrl,isFavourite,isSoldOut,const DeepCollectionEquality().hash(tags),description,const DeepCollectionEquality().hash(images),const DeepCollectionEquality().hash(colours),const DeepCollectionEquality().hash(sizes),const DeepCollectionEquality().hash(features));

@override
String toString() {
  return 'Product(id: $id, name: $name, price: $price, categoryId: $categoryId, imageUrl: $imageUrl, isFavourite: $isFavourite, isSoldOut: $isSoldOut, tags: $tags, description: $description, images: $images, colours: $colours, sizes: $sizes, features: $features)';
}


}

/// @nodoc
abstract mixin class $ProductCopyWith<$Res>  {
  factory $ProductCopyWith(Product value, $Res Function(Product) _then) = _$ProductCopyWithImpl;
@useResult
$Res call({
 String id, String name, num price,@JsonKey(name: 'category_id') String categoryId,@JsonKey(name: 'image_url') String? imageUrl,@JsonKey(name: 'is_favourite') bool isFavourite,@JsonKey(name: 'is_sold_out') bool isSoldOut, List<ProductTag> tags, String? description, List<String> images, List<ProductColour> colours, List<String> sizes, List<ProductFeature> features
});




}
/// @nodoc
class _$ProductCopyWithImpl<$Res>
    implements $ProductCopyWith<$Res> {
  _$ProductCopyWithImpl(this._self, this._then);

  final Product _self;
  final $Res Function(Product) _then;

/// Create a copy of Product
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? price = null,Object? categoryId = null,Object? imageUrl = freezed,Object? isFavourite = null,Object? isSoldOut = null,Object? tags = null,Object? description = freezed,Object? images = null,Object? colours = null,Object? sizes = null,Object? features = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,price: null == price ? _self.price : price // ignore: cast_nullable_to_non_nullable
as num,categoryId: null == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as String,imageUrl: freezed == imageUrl ? _self.imageUrl : imageUrl // ignore: cast_nullable_to_non_nullable
as String?,isFavourite: null == isFavourite ? _self.isFavourite : isFavourite // ignore: cast_nullable_to_non_nullable
as bool,isSoldOut: null == isSoldOut ? _self.isSoldOut : isSoldOut // ignore: cast_nullable_to_non_nullable
as bool,tags: null == tags ? _self.tags : tags // ignore: cast_nullable_to_non_nullable
as List<ProductTag>,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,images: null == images ? _self.images : images // ignore: cast_nullable_to_non_nullable
as List<String>,colours: null == colours ? _self.colours : colours // ignore: cast_nullable_to_non_nullable
as List<ProductColour>,sizes: null == sizes ? _self.sizes : sizes // ignore: cast_nullable_to_non_nullable
as List<String>,features: null == features ? _self.features : features // ignore: cast_nullable_to_non_nullable
as List<ProductFeature>,
  ));
}

}


/// Adds pattern-matching-related methods to [Product].
extension ProductPatterns on Product {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Product value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Product() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Product value)  $default,){
final _that = this;
switch (_that) {
case _Product():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Product value)?  $default,){
final _that = this;
switch (_that) {
case _Product() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  num price, @JsonKey(name: 'category_id')  String categoryId, @JsonKey(name: 'image_url')  String? imageUrl, @JsonKey(name: 'is_favourite')  bool isFavourite, @JsonKey(name: 'is_sold_out')  bool isSoldOut,  List<ProductTag> tags,  String? description,  List<String> images,  List<ProductColour> colours,  List<String> sizes,  List<ProductFeature> features)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Product() when $default != null:
return $default(_that.id,_that.name,_that.price,_that.categoryId,_that.imageUrl,_that.isFavourite,_that.isSoldOut,_that.tags,_that.description,_that.images,_that.colours,_that.sizes,_that.features);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  num price, @JsonKey(name: 'category_id')  String categoryId, @JsonKey(name: 'image_url')  String? imageUrl, @JsonKey(name: 'is_favourite')  bool isFavourite, @JsonKey(name: 'is_sold_out')  bool isSoldOut,  List<ProductTag> tags,  String? description,  List<String> images,  List<ProductColour> colours,  List<String> sizes,  List<ProductFeature> features)  $default,) {final _that = this;
switch (_that) {
case _Product():
return $default(_that.id,_that.name,_that.price,_that.categoryId,_that.imageUrl,_that.isFavourite,_that.isSoldOut,_that.tags,_that.description,_that.images,_that.colours,_that.sizes,_that.features);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  num price, @JsonKey(name: 'category_id')  String categoryId, @JsonKey(name: 'image_url')  String? imageUrl, @JsonKey(name: 'is_favourite')  bool isFavourite, @JsonKey(name: 'is_sold_out')  bool isSoldOut,  List<ProductTag> tags,  String? description,  List<String> images,  List<ProductColour> colours,  List<String> sizes,  List<ProductFeature> features)?  $default,) {final _that = this;
switch (_that) {
case _Product() when $default != null:
return $default(_that.id,_that.name,_that.price,_that.categoryId,_that.imageUrl,_that.isFavourite,_that.isSoldOut,_that.tags,_that.description,_that.images,_that.colours,_that.sizes,_that.features);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Product implements Product {
  const _Product({required this.id, required this.name, required this.price, @JsonKey(name: 'category_id') required this.categoryId, @JsonKey(name: 'image_url') this.imageUrl, @JsonKey(name: 'is_favourite') this.isFavourite = false, @JsonKey(name: 'is_sold_out') this.isSoldOut = false, final  List<ProductTag> tags = const <ProductTag>[], this.description, final  List<String> images = const <String>[], final  List<ProductColour> colours = const <ProductColour>[], final  List<String> sizes = const <String>[], final  List<ProductFeature> features = const <ProductFeature>[]}): _tags = tags,_images = images,_colours = colours,_sizes = sizes,_features = features;
  factory _Product.fromJson(Map<String, dynamic> json) => _$ProductFromJson(json);

@override final  String id;
@override final  String name;
@override final  num price;
@override@JsonKey(name: 'category_id') final  String categoryId;
@override@JsonKey(name: 'image_url') final  String? imageUrl;
@override@JsonKey(name: 'is_favourite') final  bool isFavourite;
@override@JsonKey(name: 'is_sold_out') final  bool isSoldOut;
 final  List<ProductTag> _tags;
@override@JsonKey() List<ProductTag> get tags {
  if (_tags is EqualUnmodifiableListView) return _tags;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_tags);
}

@override final  String? description;
/// Carousel artwork. Empty until real photography exists.
 final  List<String> _images;
/// Carousel artwork. Empty until real photography exists.
@override@JsonKey() List<String> get images {
  if (_images is EqualUnmodifiableListView) return _images;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_images);
}

 final  List<ProductColour> _colours;
@override@JsonKey() List<ProductColour> get colours {
  if (_colours is EqualUnmodifiableListView) return _colours;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_colours);
}

 final  List<String> _sizes;
@override@JsonKey() List<String> get sizes {
  if (_sizes is EqualUnmodifiableListView) return _sizes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_sizes);
}

 final  List<ProductFeature> _features;
@override@JsonKey() List<ProductFeature> get features {
  if (_features is EqualUnmodifiableListView) return _features;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_features);
}


/// Create a copy of Product
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProductCopyWith<_Product> get copyWith => __$ProductCopyWithImpl<_Product>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProductToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Product&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.price, price) || other.price == price)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.imageUrl, imageUrl) || other.imageUrl == imageUrl)&&(identical(other.isFavourite, isFavourite) || other.isFavourite == isFavourite)&&(identical(other.isSoldOut, isSoldOut) || other.isSoldOut == isSoldOut)&&const DeepCollectionEquality().equals(other._tags, _tags)&&(identical(other.description, description) || other.description == description)&&const DeepCollectionEquality().equals(other._images, _images)&&const DeepCollectionEquality().equals(other._colours, _colours)&&const DeepCollectionEquality().equals(other._sizes, _sizes)&&const DeepCollectionEquality().equals(other._features, _features));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,price,categoryId,imageUrl,isFavourite,isSoldOut,const DeepCollectionEquality().hash(_tags),description,const DeepCollectionEquality().hash(_images),const DeepCollectionEquality().hash(_colours),const DeepCollectionEquality().hash(_sizes),const DeepCollectionEquality().hash(_features));

@override
String toString() {
  return 'Product(id: $id, name: $name, price: $price, categoryId: $categoryId, imageUrl: $imageUrl, isFavourite: $isFavourite, isSoldOut: $isSoldOut, tags: $tags, description: $description, images: $images, colours: $colours, sizes: $sizes, features: $features)';
}


}

/// @nodoc
abstract mixin class _$ProductCopyWith<$Res> implements $ProductCopyWith<$Res> {
  factory _$ProductCopyWith(_Product value, $Res Function(_Product) _then) = __$ProductCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, num price,@JsonKey(name: 'category_id') String categoryId,@JsonKey(name: 'image_url') String? imageUrl,@JsonKey(name: 'is_favourite') bool isFavourite,@JsonKey(name: 'is_sold_out') bool isSoldOut, List<ProductTag> tags, String? description, List<String> images, List<ProductColour> colours, List<String> sizes, List<ProductFeature> features
});




}
/// @nodoc
class __$ProductCopyWithImpl<$Res>
    implements _$ProductCopyWith<$Res> {
  __$ProductCopyWithImpl(this._self, this._then);

  final _Product _self;
  final $Res Function(_Product) _then;

/// Create a copy of Product
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? price = null,Object? categoryId = null,Object? imageUrl = freezed,Object? isFavourite = null,Object? isSoldOut = null,Object? tags = null,Object? description = freezed,Object? images = null,Object? colours = null,Object? sizes = null,Object? features = null,}) {
  return _then(_Product(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,price: null == price ? _self.price : price // ignore: cast_nullable_to_non_nullable
as num,categoryId: null == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as String,imageUrl: freezed == imageUrl ? _self.imageUrl : imageUrl // ignore: cast_nullable_to_non_nullable
as String?,isFavourite: null == isFavourite ? _self.isFavourite : isFavourite // ignore: cast_nullable_to_non_nullable
as bool,isSoldOut: null == isSoldOut ? _self.isSoldOut : isSoldOut // ignore: cast_nullable_to_non_nullable
as bool,tags: null == tags ? _self._tags : tags // ignore: cast_nullable_to_non_nullable
as List<ProductTag>,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,images: null == images ? _self._images : images // ignore: cast_nullable_to_non_nullable
as List<String>,colours: null == colours ? _self._colours : colours // ignore: cast_nullable_to_non_nullable
as List<ProductColour>,sizes: null == sizes ? _self._sizes : sizes // ignore: cast_nullable_to_non_nullable
as List<String>,features: null == features ? _self._features : features // ignore: cast_nullable_to_non_nullable
as List<ProductFeature>,
  ));
}


}

// dart format on
