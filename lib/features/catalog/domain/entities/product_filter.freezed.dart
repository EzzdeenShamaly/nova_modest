// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'product_filter.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ProductFilter {

/// Empty means every category. Products match if they are in **any** of
/// them — facets are OR within, AND between.
 Set<String> get categoryIds;/// Single-select, unlike the others: the listing's chip row has one "All"
/// chip and one active tag, which is a different affordance from a
/// checkbox list.
 String? get tagId; num? get minPrice; num? get maxPrice; Set<String> get sizes; Set<String> get colourIds;
/// Create a copy of ProductFilter
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProductFilterCopyWith<ProductFilter> get copyWith => _$ProductFilterCopyWithImpl<ProductFilter>(this as ProductFilter, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProductFilter&&const DeepCollectionEquality().equals(other.categoryIds, categoryIds)&&(identical(other.tagId, tagId) || other.tagId == tagId)&&(identical(other.minPrice, minPrice) || other.minPrice == minPrice)&&(identical(other.maxPrice, maxPrice) || other.maxPrice == maxPrice)&&const DeepCollectionEquality().equals(other.sizes, sizes)&&const DeepCollectionEquality().equals(other.colourIds, colourIds));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(categoryIds),tagId,minPrice,maxPrice,const DeepCollectionEquality().hash(sizes),const DeepCollectionEquality().hash(colourIds));

@override
String toString() {
  return 'ProductFilter(categoryIds: $categoryIds, tagId: $tagId, minPrice: $minPrice, maxPrice: $maxPrice, sizes: $sizes, colourIds: $colourIds)';
}


}

/// @nodoc
abstract mixin class $ProductFilterCopyWith<$Res>  {
  factory $ProductFilterCopyWith(ProductFilter value, $Res Function(ProductFilter) _then) = _$ProductFilterCopyWithImpl;
@useResult
$Res call({
 Set<String> categoryIds, String? tagId, num? minPrice, num? maxPrice, Set<String> sizes, Set<String> colourIds
});




}
/// @nodoc
class _$ProductFilterCopyWithImpl<$Res>
    implements $ProductFilterCopyWith<$Res> {
  _$ProductFilterCopyWithImpl(this._self, this._then);

  final ProductFilter _self;
  final $Res Function(ProductFilter) _then;

/// Create a copy of ProductFilter
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? categoryIds = null,Object? tagId = freezed,Object? minPrice = freezed,Object? maxPrice = freezed,Object? sizes = null,Object? colourIds = null,}) {
  return _then(_self.copyWith(
categoryIds: null == categoryIds ? _self.categoryIds : categoryIds // ignore: cast_nullable_to_non_nullable
as Set<String>,tagId: freezed == tagId ? _self.tagId : tagId // ignore: cast_nullable_to_non_nullable
as String?,minPrice: freezed == minPrice ? _self.minPrice : minPrice // ignore: cast_nullable_to_non_nullable
as num?,maxPrice: freezed == maxPrice ? _self.maxPrice : maxPrice // ignore: cast_nullable_to_non_nullable
as num?,sizes: null == sizes ? _self.sizes : sizes // ignore: cast_nullable_to_non_nullable
as Set<String>,colourIds: null == colourIds ? _self.colourIds : colourIds // ignore: cast_nullable_to_non_nullable
as Set<String>,
  ));
}

}


/// Adds pattern-matching-related methods to [ProductFilter].
extension ProductFilterPatterns on ProductFilter {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProductFilter value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProductFilter() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProductFilter value)  $default,){
final _that = this;
switch (_that) {
case _ProductFilter():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProductFilter value)?  $default,){
final _that = this;
switch (_that) {
case _ProductFilter() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Set<String> categoryIds,  String? tagId,  num? minPrice,  num? maxPrice,  Set<String> sizes,  Set<String> colourIds)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProductFilter() when $default != null:
return $default(_that.categoryIds,_that.tagId,_that.minPrice,_that.maxPrice,_that.sizes,_that.colourIds);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Set<String> categoryIds,  String? tagId,  num? minPrice,  num? maxPrice,  Set<String> sizes,  Set<String> colourIds)  $default,) {final _that = this;
switch (_that) {
case _ProductFilter():
return $default(_that.categoryIds,_that.tagId,_that.minPrice,_that.maxPrice,_that.sizes,_that.colourIds);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Set<String> categoryIds,  String? tagId,  num? minPrice,  num? maxPrice,  Set<String> sizes,  Set<String> colourIds)?  $default,) {final _that = this;
switch (_that) {
case _ProductFilter() when $default != null:
return $default(_that.categoryIds,_that.tagId,_that.minPrice,_that.maxPrice,_that.sizes,_that.colourIds);case _:
  return null;

}
}

}

/// @nodoc


class _ProductFilter extends ProductFilter {
  const _ProductFilter({final  Set<String> categoryIds = const <String>{}, this.tagId, this.minPrice, this.maxPrice, final  Set<String> sizes = const <String>{}, final  Set<String> colourIds = const <String>{}}): _categoryIds = categoryIds,_sizes = sizes,_colourIds = colourIds,super._();
  

/// Empty means every category. Products match if they are in **any** of
/// them — facets are OR within, AND between.
 final  Set<String> _categoryIds;
/// Empty means every category. Products match if they are in **any** of
/// them — facets are OR within, AND between.
@override@JsonKey() Set<String> get categoryIds {
  if (_categoryIds is EqualUnmodifiableSetView) return _categoryIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_categoryIds);
}

/// Single-select, unlike the others: the listing's chip row has one "All"
/// chip and one active tag, which is a different affordance from a
/// checkbox list.
@override final  String? tagId;
@override final  num? minPrice;
@override final  num? maxPrice;
 final  Set<String> _sizes;
@override@JsonKey() Set<String> get sizes {
  if (_sizes is EqualUnmodifiableSetView) return _sizes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_sizes);
}

 final  Set<String> _colourIds;
@override@JsonKey() Set<String> get colourIds {
  if (_colourIds is EqualUnmodifiableSetView) return _colourIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_colourIds);
}


/// Create a copy of ProductFilter
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProductFilterCopyWith<_ProductFilter> get copyWith => __$ProductFilterCopyWithImpl<_ProductFilter>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProductFilter&&const DeepCollectionEquality().equals(other._categoryIds, _categoryIds)&&(identical(other.tagId, tagId) || other.tagId == tagId)&&(identical(other.minPrice, minPrice) || other.minPrice == minPrice)&&(identical(other.maxPrice, maxPrice) || other.maxPrice == maxPrice)&&const DeepCollectionEquality().equals(other._sizes, _sizes)&&const DeepCollectionEquality().equals(other._colourIds, _colourIds));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_categoryIds),tagId,minPrice,maxPrice,const DeepCollectionEquality().hash(_sizes),const DeepCollectionEquality().hash(_colourIds));

@override
String toString() {
  return 'ProductFilter(categoryIds: $categoryIds, tagId: $tagId, minPrice: $minPrice, maxPrice: $maxPrice, sizes: $sizes, colourIds: $colourIds)';
}


}

/// @nodoc
abstract mixin class _$ProductFilterCopyWith<$Res> implements $ProductFilterCopyWith<$Res> {
  factory _$ProductFilterCopyWith(_ProductFilter value, $Res Function(_ProductFilter) _then) = __$ProductFilterCopyWithImpl;
@override @useResult
$Res call({
 Set<String> categoryIds, String? tagId, num? minPrice, num? maxPrice, Set<String> sizes, Set<String> colourIds
});




}
/// @nodoc
class __$ProductFilterCopyWithImpl<$Res>
    implements _$ProductFilterCopyWith<$Res> {
  __$ProductFilterCopyWithImpl(this._self, this._then);

  final _ProductFilter _self;
  final $Res Function(_ProductFilter) _then;

/// Create a copy of ProductFilter
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? categoryIds = null,Object? tagId = freezed,Object? minPrice = freezed,Object? maxPrice = freezed,Object? sizes = null,Object? colourIds = null,}) {
  return _then(_ProductFilter(
categoryIds: null == categoryIds ? _self._categoryIds : categoryIds // ignore: cast_nullable_to_non_nullable
as Set<String>,tagId: freezed == tagId ? _self.tagId : tagId // ignore: cast_nullable_to_non_nullable
as String?,minPrice: freezed == minPrice ? _self.minPrice : minPrice // ignore: cast_nullable_to_non_nullable
as num?,maxPrice: freezed == maxPrice ? _self.maxPrice : maxPrice // ignore: cast_nullable_to_non_nullable
as num?,sizes: null == sizes ? _self._sizes : sizes // ignore: cast_nullable_to_non_nullable
as Set<String>,colourIds: null == colourIds ? _self._colourIds : colourIds // ignore: cast_nullable_to_non_nullable
as Set<String>,
  ));
}


}

// dart format on
