// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'order.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$Order {

/// `ORD-YYMMDD-NNNN`, as `1:2137` and `1:1356` quote it.
 String get number; DateTime get placedAt; OrderTotals get totals; OrderStatus get status;/// What was bought, at the price it was bought for.
 List<CartItem> get items;/// Where it goes, and who receives it.
 Address? get address;/// The name and number the shopper gave at checkout, which may differ from
/// the account's — they may be buying for someone else.
 String? get recipientName; String? get recipientPhone;
/// Create a copy of Order
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OrderCopyWith<Order> get copyWith => _$OrderCopyWithImpl<Order>(this as Order, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Order&&(identical(other.number, number) || other.number == number)&&(identical(other.placedAt, placedAt) || other.placedAt == placedAt)&&(identical(other.totals, totals) || other.totals == totals)&&(identical(other.status, status) || other.status == status)&&const DeepCollectionEquality().equals(other.items, items)&&(identical(other.address, address) || other.address == address)&&(identical(other.recipientName, recipientName) || other.recipientName == recipientName)&&(identical(other.recipientPhone, recipientPhone) || other.recipientPhone == recipientPhone));
}


@override
int get hashCode => Object.hash(runtimeType,number,placedAt,totals,status,const DeepCollectionEquality().hash(items),address,recipientName,recipientPhone);

@override
String toString() {
  return 'Order(number: $number, placedAt: $placedAt, totals: $totals, status: $status, items: $items, address: $address, recipientName: $recipientName, recipientPhone: $recipientPhone)';
}


}

/// @nodoc
abstract mixin class $OrderCopyWith<$Res>  {
  factory $OrderCopyWith(Order value, $Res Function(Order) _then) = _$OrderCopyWithImpl;
@useResult
$Res call({
 String number, DateTime placedAt, OrderTotals totals, OrderStatus status, List<CartItem> items, Address? address, String? recipientName, String? recipientPhone
});


$OrderTotalsCopyWith<$Res> get totals;$AddressCopyWith<$Res>? get address;

}
/// @nodoc
class _$OrderCopyWithImpl<$Res>
    implements $OrderCopyWith<$Res> {
  _$OrderCopyWithImpl(this._self, this._then);

  final Order _self;
  final $Res Function(Order) _then;

/// Create a copy of Order
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? number = null,Object? placedAt = null,Object? totals = null,Object? status = null,Object? items = null,Object? address = freezed,Object? recipientName = freezed,Object? recipientPhone = freezed,}) {
  return _then(_self.copyWith(
number: null == number ? _self.number : number // ignore: cast_nullable_to_non_nullable
as String,placedAt: null == placedAt ? _self.placedAt : placedAt // ignore: cast_nullable_to_non_nullable
as DateTime,totals: null == totals ? _self.totals : totals // ignore: cast_nullable_to_non_nullable
as OrderTotals,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as OrderStatus,items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<CartItem>,address: freezed == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as Address?,recipientName: freezed == recipientName ? _self.recipientName : recipientName // ignore: cast_nullable_to_non_nullable
as String?,recipientPhone: freezed == recipientPhone ? _self.recipientPhone : recipientPhone // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}
/// Create a copy of Order
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$OrderTotalsCopyWith<$Res> get totals {
  
  return $OrderTotalsCopyWith<$Res>(_self.totals, (value) {
    return _then(_self.copyWith(totals: value));
  });
}/// Create a copy of Order
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AddressCopyWith<$Res>? get address {
    if (_self.address == null) {
    return null;
  }

  return $AddressCopyWith<$Res>(_self.address!, (value) {
    return _then(_self.copyWith(address: value));
  });
}
}


/// Adds pattern-matching-related methods to [Order].
extension OrderPatterns on Order {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Order value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Order() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Order value)  $default,){
final _that = this;
switch (_that) {
case _Order():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Order value)?  $default,){
final _that = this;
switch (_that) {
case _Order() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String number,  DateTime placedAt,  OrderTotals totals,  OrderStatus status,  List<CartItem> items,  Address? address,  String? recipientName,  String? recipientPhone)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Order() when $default != null:
return $default(_that.number,_that.placedAt,_that.totals,_that.status,_that.items,_that.address,_that.recipientName,_that.recipientPhone);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String number,  DateTime placedAt,  OrderTotals totals,  OrderStatus status,  List<CartItem> items,  Address? address,  String? recipientName,  String? recipientPhone)  $default,) {final _that = this;
switch (_that) {
case _Order():
return $default(_that.number,_that.placedAt,_that.totals,_that.status,_that.items,_that.address,_that.recipientName,_that.recipientPhone);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String number,  DateTime placedAt,  OrderTotals totals,  OrderStatus status,  List<CartItem> items,  Address? address,  String? recipientName,  String? recipientPhone)?  $default,) {final _that = this;
switch (_that) {
case _Order() when $default != null:
return $default(_that.number,_that.placedAt,_that.totals,_that.status,_that.items,_that.address,_that.recipientName,_that.recipientPhone);case _:
  return null;

}
}

}

/// @nodoc


class _Order extends Order {
  const _Order({required this.number, required this.placedAt, required this.totals, required this.status, final  List<CartItem> items = const <CartItem>[], this.address, this.recipientName, this.recipientPhone}): _items = items,super._();
  

/// `ORD-YYMMDD-NNNN`, as `1:2137` and `1:1356` quote it.
@override final  String number;
@override final  DateTime placedAt;
@override final  OrderTotals totals;
@override final  OrderStatus status;
/// What was bought, at the price it was bought for.
 final  List<CartItem> _items;
/// What was bought, at the price it was bought for.
@override@JsonKey() List<CartItem> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}

/// Where it goes, and who receives it.
@override final  Address? address;
/// The name and number the shopper gave at checkout, which may differ from
/// the account's — they may be buying for someone else.
@override final  String? recipientName;
@override final  String? recipientPhone;

/// Create a copy of Order
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OrderCopyWith<_Order> get copyWith => __$OrderCopyWithImpl<_Order>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Order&&(identical(other.number, number) || other.number == number)&&(identical(other.placedAt, placedAt) || other.placedAt == placedAt)&&(identical(other.totals, totals) || other.totals == totals)&&(identical(other.status, status) || other.status == status)&&const DeepCollectionEquality().equals(other._items, _items)&&(identical(other.address, address) || other.address == address)&&(identical(other.recipientName, recipientName) || other.recipientName == recipientName)&&(identical(other.recipientPhone, recipientPhone) || other.recipientPhone == recipientPhone));
}


@override
int get hashCode => Object.hash(runtimeType,number,placedAt,totals,status,const DeepCollectionEquality().hash(_items),address,recipientName,recipientPhone);

@override
String toString() {
  return 'Order(number: $number, placedAt: $placedAt, totals: $totals, status: $status, items: $items, address: $address, recipientName: $recipientName, recipientPhone: $recipientPhone)';
}


}

/// @nodoc
abstract mixin class _$OrderCopyWith<$Res> implements $OrderCopyWith<$Res> {
  factory _$OrderCopyWith(_Order value, $Res Function(_Order) _then) = __$OrderCopyWithImpl;
@override @useResult
$Res call({
 String number, DateTime placedAt, OrderTotals totals, OrderStatus status, List<CartItem> items, Address? address, String? recipientName, String? recipientPhone
});


@override $OrderTotalsCopyWith<$Res> get totals;@override $AddressCopyWith<$Res>? get address;

}
/// @nodoc
class __$OrderCopyWithImpl<$Res>
    implements _$OrderCopyWith<$Res> {
  __$OrderCopyWithImpl(this._self, this._then);

  final _Order _self;
  final $Res Function(_Order) _then;

/// Create a copy of Order
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? number = null,Object? placedAt = null,Object? totals = null,Object? status = null,Object? items = null,Object? address = freezed,Object? recipientName = freezed,Object? recipientPhone = freezed,}) {
  return _then(_Order(
number: null == number ? _self.number : number // ignore: cast_nullable_to_non_nullable
as String,placedAt: null == placedAt ? _self.placedAt : placedAt // ignore: cast_nullable_to_non_nullable
as DateTime,totals: null == totals ? _self.totals : totals // ignore: cast_nullable_to_non_nullable
as OrderTotals,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as OrderStatus,items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<CartItem>,address: freezed == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as Address?,recipientName: freezed == recipientName ? _self.recipientName : recipientName // ignore: cast_nullable_to_non_nullable
as String?,recipientPhone: freezed == recipientPhone ? _self.recipientPhone : recipientPhone // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of Order
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$OrderTotalsCopyWith<$Res> get totals {
  
  return $OrderTotalsCopyWith<$Res>(_self.totals, (value) {
    return _then(_self.copyWith(totals: value));
  });
}/// Create a copy of Order
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AddressCopyWith<$Res>? get address {
    if (_self.address == null) {
    return null;
  }

  return $AddressCopyWith<$Res>(_self.address!, (value) {
    return _then(_self.copyWith(address: value));
  });
}
}

// dart format on
