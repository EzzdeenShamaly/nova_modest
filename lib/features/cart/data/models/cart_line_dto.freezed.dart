// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'cart_line_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$CartLineDto {

@JsonKey(name: 'product_id') String get productId;@JsonKey(name: 'colour_id') String? get colourId; String? get size; int get quantity;
/// Create a copy of CartLineDto
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CartLineDtoCopyWith<CartLineDto> get copyWith => _$CartLineDtoCopyWithImpl<CartLineDto>(this as CartLineDto, _$identity);

  /// Serializes this CartLineDto to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CartLineDto&&(identical(other.productId, productId) || other.productId == productId)&&(identical(other.colourId, colourId) || other.colourId == colourId)&&(identical(other.size, size) || other.size == size)&&(identical(other.quantity, quantity) || other.quantity == quantity));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,productId,colourId,size,quantity);

@override
String toString() {
  return 'CartLineDto(productId: $productId, colourId: $colourId, size: $size, quantity: $quantity)';
}


}

/// @nodoc
abstract mixin class $CartLineDtoCopyWith<$Res>  {
  factory $CartLineDtoCopyWith(CartLineDto value, $Res Function(CartLineDto) _then) = _$CartLineDtoCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'product_id') String productId,@JsonKey(name: 'colour_id') String? colourId, String? size, int quantity
});




}
/// @nodoc
class _$CartLineDtoCopyWithImpl<$Res>
    implements $CartLineDtoCopyWith<$Res> {
  _$CartLineDtoCopyWithImpl(this._self, this._then);

  final CartLineDto _self;
  final $Res Function(CartLineDto) _then;

/// Create a copy of CartLineDto
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? productId = null,Object? colourId = freezed,Object? size = freezed,Object? quantity = null,}) {
  return _then(_self.copyWith(
productId: null == productId ? _self.productId : productId // ignore: cast_nullable_to_non_nullable
as String,colourId: freezed == colourId ? _self.colourId : colourId // ignore: cast_nullable_to_non_nullable
as String?,size: freezed == size ? _self.size : size // ignore: cast_nullable_to_non_nullable
as String?,quantity: null == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [CartLineDto].
extension CartLineDtoPatterns on CartLineDto {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CartLineDto value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CartLineDto() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CartLineDto value)  $default,){
final _that = this;
switch (_that) {
case _CartLineDto():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CartLineDto value)?  $default,){
final _that = this;
switch (_that) {
case _CartLineDto() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'product_id')  String productId, @JsonKey(name: 'colour_id')  String? colourId,  String? size,  int quantity)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CartLineDto() when $default != null:
return $default(_that.productId,_that.colourId,_that.size,_that.quantity);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'product_id')  String productId, @JsonKey(name: 'colour_id')  String? colourId,  String? size,  int quantity)  $default,) {final _that = this;
switch (_that) {
case _CartLineDto():
return $default(_that.productId,_that.colourId,_that.size,_that.quantity);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'product_id')  String productId, @JsonKey(name: 'colour_id')  String? colourId,  String? size,  int quantity)?  $default,) {final _that = this;
switch (_that) {
case _CartLineDto() when $default != null:
return $default(_that.productId,_that.colourId,_that.size,_that.quantity);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CartLineDto implements CartLineDto {
  const _CartLineDto({@JsonKey(name: 'product_id') required this.productId, @JsonKey(name: 'colour_id') this.colourId, this.size, this.quantity = 1});
  factory _CartLineDto.fromJson(Map<String, dynamic> json) => _$CartLineDtoFromJson(json);

@override@JsonKey(name: 'product_id') final  String productId;
@override@JsonKey(name: 'colour_id') final  String? colourId;
@override final  String? size;
@override@JsonKey() final  int quantity;

/// Create a copy of CartLineDto
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CartLineDtoCopyWith<_CartLineDto> get copyWith => __$CartLineDtoCopyWithImpl<_CartLineDto>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CartLineDtoToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CartLineDto&&(identical(other.productId, productId) || other.productId == productId)&&(identical(other.colourId, colourId) || other.colourId == colourId)&&(identical(other.size, size) || other.size == size)&&(identical(other.quantity, quantity) || other.quantity == quantity));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,productId,colourId,size,quantity);

@override
String toString() {
  return 'CartLineDto(productId: $productId, colourId: $colourId, size: $size, quantity: $quantity)';
}


}

/// @nodoc
abstract mixin class _$CartLineDtoCopyWith<$Res> implements $CartLineDtoCopyWith<$Res> {
  factory _$CartLineDtoCopyWith(_CartLineDto value, $Res Function(_CartLineDto) _then) = __$CartLineDtoCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'product_id') String productId,@JsonKey(name: 'colour_id') String? colourId, String? size, int quantity
});




}
/// @nodoc
class __$CartLineDtoCopyWithImpl<$Res>
    implements _$CartLineDtoCopyWith<$Res> {
  __$CartLineDtoCopyWithImpl(this._self, this._then);

  final _CartLineDto _self;
  final $Res Function(_CartLineDto) _then;

/// Create a copy of CartLineDto
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? productId = null,Object? colourId = freezed,Object? size = freezed,Object? quantity = null,}) {
  return _then(_CartLineDto(
productId: null == productId ? _self.productId : productId // ignore: cast_nullable_to_non_nullable
as String,colourId: freezed == colourId ? _self.colourId : colourId // ignore: cast_nullable_to_non_nullable
as String?,size: freezed == size ? _self.size : size // ignore: cast_nullable_to_non_nullable
as String?,quantity: null == quantity ? _self.quantity : quantity // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
