// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'order_totals.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$OrderTotals {

 num get subtotal; num get shipping; num get paymentFee;
/// Create a copy of OrderTotals
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OrderTotalsCopyWith<OrderTotals> get copyWith => _$OrderTotalsCopyWithImpl<OrderTotals>(this as OrderTotals, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OrderTotals&&(identical(other.subtotal, subtotal) || other.subtotal == subtotal)&&(identical(other.shipping, shipping) || other.shipping == shipping)&&(identical(other.paymentFee, paymentFee) || other.paymentFee == paymentFee));
}


@override
int get hashCode => Object.hash(runtimeType,subtotal,shipping,paymentFee);

@override
String toString() {
  return 'OrderTotals(subtotal: $subtotal, shipping: $shipping, paymentFee: $paymentFee)';
}


}

/// @nodoc
abstract mixin class $OrderTotalsCopyWith<$Res>  {
  factory $OrderTotalsCopyWith(OrderTotals value, $Res Function(OrderTotals) _then) = _$OrderTotalsCopyWithImpl;
@useResult
$Res call({
 num subtotal, num shipping, num paymentFee
});




}
/// @nodoc
class _$OrderTotalsCopyWithImpl<$Res>
    implements $OrderTotalsCopyWith<$Res> {
  _$OrderTotalsCopyWithImpl(this._self, this._then);

  final OrderTotals _self;
  final $Res Function(OrderTotals) _then;

/// Create a copy of OrderTotals
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? subtotal = null,Object? shipping = null,Object? paymentFee = null,}) {
  return _then(_self.copyWith(
subtotal: null == subtotal ? _self.subtotal : subtotal // ignore: cast_nullable_to_non_nullable
as num,shipping: null == shipping ? _self.shipping : shipping // ignore: cast_nullable_to_non_nullable
as num,paymentFee: null == paymentFee ? _self.paymentFee : paymentFee // ignore: cast_nullable_to_non_nullable
as num,
  ));
}

}


/// Adds pattern-matching-related methods to [OrderTotals].
extension OrderTotalsPatterns on OrderTotals {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _OrderTotals value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OrderTotals() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _OrderTotals value)  $default,){
final _that = this;
switch (_that) {
case _OrderTotals():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _OrderTotals value)?  $default,){
final _that = this;
switch (_that) {
case _OrderTotals() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( num subtotal,  num shipping,  num paymentFee)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OrderTotals() when $default != null:
return $default(_that.subtotal,_that.shipping,_that.paymentFee);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( num subtotal,  num shipping,  num paymentFee)  $default,) {final _that = this;
switch (_that) {
case _OrderTotals():
return $default(_that.subtotal,_that.shipping,_that.paymentFee);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( num subtotal,  num shipping,  num paymentFee)?  $default,) {final _that = this;
switch (_that) {
case _OrderTotals() when $default != null:
return $default(_that.subtotal,_that.shipping,_that.paymentFee);case _:
  return null;

}
}

}

/// @nodoc


class _OrderTotals extends OrderTotals {
  const _OrderTotals({required this.subtotal, required this.shipping, required this.paymentFee}): super._();
  

@override final  num subtotal;
@override final  num shipping;
@override final  num paymentFee;

/// Create a copy of OrderTotals
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OrderTotalsCopyWith<_OrderTotals> get copyWith => __$OrderTotalsCopyWithImpl<_OrderTotals>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _OrderTotals&&(identical(other.subtotal, subtotal) || other.subtotal == subtotal)&&(identical(other.shipping, shipping) || other.shipping == shipping)&&(identical(other.paymentFee, paymentFee) || other.paymentFee == paymentFee));
}


@override
int get hashCode => Object.hash(runtimeType,subtotal,shipping,paymentFee);

@override
String toString() {
  return 'OrderTotals(subtotal: $subtotal, shipping: $shipping, paymentFee: $paymentFee)';
}


}

/// @nodoc
abstract mixin class _$OrderTotalsCopyWith<$Res> implements $OrderTotalsCopyWith<$Res> {
  factory _$OrderTotalsCopyWith(_OrderTotals value, $Res Function(_OrderTotals) _then) = __$OrderTotalsCopyWithImpl;
@override @useResult
$Res call({
 num subtotal, num shipping, num paymentFee
});




}
/// @nodoc
class __$OrderTotalsCopyWithImpl<$Res>
    implements _$OrderTotalsCopyWith<$Res> {
  __$OrderTotalsCopyWithImpl(this._self, this._then);

  final _OrderTotals _self;
  final $Res Function(_OrderTotals) _then;

/// Create a copy of OrderTotals
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? subtotal = null,Object? shipping = null,Object? paymentFee = null,}) {
  return _then(_OrderTotals(
subtotal: null == subtotal ? _self.subtotal : subtotal // ignore: cast_nullable_to_non_nullable
as num,shipping: null == shipping ? _self.shipping : shipping // ignore: cast_nullable_to_non_nullable
as num,paymentFee: null == paymentFee ? _self.paymentFee : paymentFee // ignore: cast_nullable_to_non_nullable
as num,
  ));
}


}

// dart format on
