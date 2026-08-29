// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'product_filter_options.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ProductFilterOptions {

 List<ProductCategory> get categories; List<ProductTag> get tags; List<String> get sizes; List<ProductColour> get colours; num? get minPrice; num? get maxPrice;
/// Create a copy of ProductFilterOptions
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProductFilterOptionsCopyWith<ProductFilterOptions> get copyWith => _$ProductFilterOptionsCopyWithImpl<ProductFilterOptions>(this as ProductFilterOptions, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProductFilterOptions&&const DeepCollectionEquality().equals(other.categories, categories)&&const DeepCollectionEquality().equals(other.tags, tags)&&const DeepCollectionEquality().equals(other.sizes, sizes)&&const DeepCollectionEquality().equals(other.colours, colours)&&(identical(other.minPrice, minPrice) || other.minPrice == minPrice)&&(identical(other.maxPrice, maxPrice) || other.maxPrice == maxPrice));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(categories),const DeepCollectionEquality().hash(tags),const DeepCollectionEquality().hash(sizes),const DeepCollectionEquality().hash(colours),minPrice,maxPrice);

@override
String toString() {
  return 'ProductFilterOptions(categories: $categories, tags: $tags, sizes: $sizes, colours: $colours, minPrice: $minPrice, maxPrice: $maxPrice)';
}


}

/// @nodoc
abstract mixin class $ProductFilterOptionsCopyWith<$Res>  {
  factory $ProductFilterOptionsCopyWith(ProductFilterOptions value, $Res Function(ProductFilterOptions) _then) = _$ProductFilterOptionsCopyWithImpl;
@useResult
$Res call({
 List<ProductCategory> categories, List<ProductTag> tags, List<String> sizes, List<ProductColour> colours, num? minPrice, num? maxPrice
});




}
/// @nodoc
class _$ProductFilterOptionsCopyWithImpl<$Res>
    implements $ProductFilterOptionsCopyWith<$Res> {
  _$ProductFilterOptionsCopyWithImpl(this._self, this._then);

  final ProductFilterOptions _self;
  final $Res Function(ProductFilterOptions) _then;

/// Create a copy of ProductFilterOptions
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? categories = null,Object? tags = null,Object? sizes = null,Object? colours = null,Object? minPrice = freezed,Object? maxPrice = freezed,}) {
  return _then(_self.copyWith(
categories: null == categories ? _self.categories : categories // ignore: cast_nullable_to_non_nullable
as List<ProductCategory>,tags: null == tags ? _self.tags : tags // ignore: cast_nullable_to_non_nullable
as List<ProductTag>,sizes: null == sizes ? _self.sizes : sizes // ignore: cast_nullable_to_non_nullable
as List<String>,colours: null == colours ? _self.colours : colours // ignore: cast_nullable_to_non_nullable
as List<ProductColour>,minPrice: freezed == minPrice ? _self.minPrice : minPrice // ignore: cast_nullable_to_non_nullable
as num?,maxPrice: freezed == maxPrice ? _self.maxPrice : maxPrice // ignore: cast_nullable_to_non_nullable
as num?,
  ));
}

}


/// Adds pattern-matching-related methods to [ProductFilterOptions].
extension ProductFilterOptionsPatterns on ProductFilterOptions {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProductFilterOptions value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProductFilterOptions() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProductFilterOptions value)  $default,){
final _that = this;
switch (_that) {
case _ProductFilterOptions():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProductFilterOptions value)?  $default,){
final _that = this;
switch (_that) {
case _ProductFilterOptions() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<ProductCategory> categories,  List<ProductTag> tags,  List<String> sizes,  List<ProductColour> colours,  num? minPrice,  num? maxPrice)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProductFilterOptions() when $default != null:
return $default(_that.categories,_that.tags,_that.sizes,_that.colours,_that.minPrice,_that.maxPrice);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<ProductCategory> categories,  List<ProductTag> tags,  List<String> sizes,  List<ProductColour> colours,  num? minPrice,  num? maxPrice)  $default,) {final _that = this;
switch (_that) {
case _ProductFilterOptions():
return $default(_that.categories,_that.tags,_that.sizes,_that.colours,_that.minPrice,_that.maxPrice);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<ProductCategory> categories,  List<ProductTag> tags,  List<String> sizes,  List<ProductColour> colours,  num? minPrice,  num? maxPrice)?  $default,) {final _that = this;
switch (_that) {
case _ProductFilterOptions() when $default != null:
return $default(_that.categories,_that.tags,_that.sizes,_that.colours,_that.minPrice,_that.maxPrice);case _:
  return null;

}
}

}

/// @nodoc


class _ProductFilterOptions extends ProductFilterOptions {
  const _ProductFilterOptions({final  List<ProductCategory> categories = const <ProductCategory>[], final  List<ProductTag> tags = const <ProductTag>[], final  List<String> sizes = const <String>[], final  List<ProductColour> colours = const <ProductColour>[], this.minPrice, this.maxPrice}): _categories = categories,_tags = tags,_sizes = sizes,_colours = colours,super._();
  

 final  List<ProductCategory> _categories;
@override@JsonKey() List<ProductCategory> get categories {
  if (_categories is EqualUnmodifiableListView) return _categories;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_categories);
}

 final  List<ProductTag> _tags;
@override@JsonKey() List<ProductTag> get tags {
  if (_tags is EqualUnmodifiableListView) return _tags;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_tags);
}

 final  List<String> _sizes;
@override@JsonKey() List<String> get sizes {
  if (_sizes is EqualUnmodifiableListView) return _sizes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_sizes);
}

 final  List<ProductColour> _colours;
@override@JsonKey() List<ProductColour> get colours {
  if (_colours is EqualUnmodifiableListView) return _colours;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_colours);
}

@override final  num? minPrice;
@override final  num? maxPrice;

/// Create a copy of ProductFilterOptions
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProductFilterOptionsCopyWith<_ProductFilterOptions> get copyWith => __$ProductFilterOptionsCopyWithImpl<_ProductFilterOptions>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProductFilterOptions&&const DeepCollectionEquality().equals(other._categories, _categories)&&const DeepCollectionEquality().equals(other._tags, _tags)&&const DeepCollectionEquality().equals(other._sizes, _sizes)&&const DeepCollectionEquality().equals(other._colours, _colours)&&(identical(other.minPrice, minPrice) || other.minPrice == minPrice)&&(identical(other.maxPrice, maxPrice) || other.maxPrice == maxPrice));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_categories),const DeepCollectionEquality().hash(_tags),const DeepCollectionEquality().hash(_sizes),const DeepCollectionEquality().hash(_colours),minPrice,maxPrice);

@override
String toString() {
  return 'ProductFilterOptions(categories: $categories, tags: $tags, sizes: $sizes, colours: $colours, minPrice: $minPrice, maxPrice: $maxPrice)';
}


}

/// @nodoc
abstract mixin class _$ProductFilterOptionsCopyWith<$Res> implements $ProductFilterOptionsCopyWith<$Res> {
  factory _$ProductFilterOptionsCopyWith(_ProductFilterOptions value, $Res Function(_ProductFilterOptions) _then) = __$ProductFilterOptionsCopyWithImpl;
@override @useResult
$Res call({
 List<ProductCategory> categories, List<ProductTag> tags, List<String> sizes, List<ProductColour> colours, num? minPrice, num? maxPrice
});




}
/// @nodoc
class __$ProductFilterOptionsCopyWithImpl<$Res>
    implements _$ProductFilterOptionsCopyWith<$Res> {
  __$ProductFilterOptionsCopyWithImpl(this._self, this._then);

  final _ProductFilterOptions _self;
  final $Res Function(_ProductFilterOptions) _then;

/// Create a copy of ProductFilterOptions
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? categories = null,Object? tags = null,Object? sizes = null,Object? colours = null,Object? minPrice = freezed,Object? maxPrice = freezed,}) {
  return _then(_ProductFilterOptions(
categories: null == categories ? _self._categories : categories // ignore: cast_nullable_to_non_nullable
as List<ProductCategory>,tags: null == tags ? _self._tags : tags // ignore: cast_nullable_to_non_nullable
as List<ProductTag>,sizes: null == sizes ? _self._sizes : sizes // ignore: cast_nullable_to_non_nullable
as List<String>,colours: null == colours ? _self._colours : colours // ignore: cast_nullable_to_non_nullable
as List<ProductColour>,minPrice: freezed == minPrice ? _self.minPrice : minPrice // ignore: cast_nullable_to_non_nullable
as num?,maxPrice: freezed == maxPrice ? _self.maxPrice : maxPrice // ignore: cast_nullable_to_non_nullable
as num?,
  ));
}


}

// dart format on
