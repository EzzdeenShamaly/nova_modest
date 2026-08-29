// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'product_colour.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ProductColour {

 String get id; String get name;/// `#RRGGBB`, as the backend supplies it.
 String get hex;
/// Create a copy of ProductColour
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProductColourCopyWith<ProductColour> get copyWith => _$ProductColourCopyWithImpl<ProductColour>(this as ProductColour, _$identity);

  /// Serializes this ProductColour to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProductColour&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.hex, hex) || other.hex == hex));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,hex);

@override
String toString() {
  return 'ProductColour(id: $id, name: $name, hex: $hex)';
}


}

/// @nodoc
abstract mixin class $ProductColourCopyWith<$Res>  {
  factory $ProductColourCopyWith(ProductColour value, $Res Function(ProductColour) _then) = _$ProductColourCopyWithImpl;
@useResult
$Res call({
 String id, String name, String hex
});




}
/// @nodoc
class _$ProductColourCopyWithImpl<$Res>
    implements $ProductColourCopyWith<$Res> {
  _$ProductColourCopyWithImpl(this._self, this._then);

  final ProductColour _self;
  final $Res Function(ProductColour) _then;

/// Create a copy of ProductColour
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? hex = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,hex: null == hex ? _self.hex : hex // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [ProductColour].
extension ProductColourPatterns on ProductColour {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProductColour value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProductColour() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProductColour value)  $default,){
final _that = this;
switch (_that) {
case _ProductColour():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProductColour value)?  $default,){
final _that = this;
switch (_that) {
case _ProductColour() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String hex)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProductColour() when $default != null:
return $default(_that.id,_that.name,_that.hex);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String hex)  $default,) {final _that = this;
switch (_that) {
case _ProductColour():
return $default(_that.id,_that.name,_that.hex);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String hex)?  $default,) {final _that = this;
switch (_that) {
case _ProductColour() when $default != null:
return $default(_that.id,_that.name,_that.hex);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ProductColour implements ProductColour {
  const _ProductColour({required this.id, required this.name, required this.hex});
  factory _ProductColour.fromJson(Map<String, dynamic> json) => _$ProductColourFromJson(json);

@override final  String id;
@override final  String name;
/// `#RRGGBB`, as the backend supplies it.
@override final  String hex;

/// Create a copy of ProductColour
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProductColourCopyWith<_ProductColour> get copyWith => __$ProductColourCopyWithImpl<_ProductColour>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProductColourToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProductColour&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.hex, hex) || other.hex == hex));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,hex);

@override
String toString() {
  return 'ProductColour(id: $id, name: $name, hex: $hex)';
}


}

/// @nodoc
abstract mixin class _$ProductColourCopyWith<$Res> implements $ProductColourCopyWith<$Res> {
  factory _$ProductColourCopyWith(_ProductColour value, $Res Function(_ProductColour) _then) = __$ProductColourCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String hex
});




}
/// @nodoc
class __$ProductColourCopyWithImpl<$Res>
    implements _$ProductColourCopyWith<$Res> {
  __$ProductColourCopyWithImpl(this._self, this._then);

  final _ProductColour _self;
  final $Res Function(_ProductColour) _then;

/// Create a copy of ProductColour
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? hex = null,}) {
  return _then(_ProductColour(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,hex: null == hex ? _self.hex : hex // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
