// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'checkout_draft.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$CheckoutDraft {

 ContactDetails? get contact;/// The whole address, not its id. The review screen draws it in full, and
/// holding the id would make every later step look it up again in a list
/// it does not otherwise need. Editing an address inside the flow goes
/// through the same step that set this, so the copy cannot go stale
/// (user, 2026-08-29).
 Address? get address;/// Preselected, as the frame draws them.
 ShippingMethod get shipping; PaymentMethod get payment;/// What the cart held when checkout opened.
///
/// A snapshot, handed in by the route the way the signed-in user is. The
/// cart cannot be edited from inside this flow, so it cannot go stale
/// while the flow is open — and the bloc stays testable without a cart.
 CartTotals? get cart;/// The lines the review screen lists. Handed in beside [cart] rather than
/// replacing it: step 3's totals plumbing works and is covered, and
/// deriving one from the other would mean rebuilding it
/// (`09-minimal-changes.md`).
 List<CartItem> get items;/// Set once the order is placed. Null for the whole flow before that.
 Order? get order;
/// Create a copy of CheckoutDraft
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CheckoutDraftCopyWith<CheckoutDraft> get copyWith => _$CheckoutDraftCopyWithImpl<CheckoutDraft>(this as CheckoutDraft, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CheckoutDraft&&(identical(other.contact, contact) || other.contact == contact)&&(identical(other.address, address) || other.address == address)&&(identical(other.shipping, shipping) || other.shipping == shipping)&&(identical(other.payment, payment) || other.payment == payment)&&(identical(other.cart, cart) || other.cart == cart)&&const DeepCollectionEquality().equals(other.items, items)&&(identical(other.order, order) || other.order == order));
}


@override
int get hashCode => Object.hash(runtimeType,contact,address,shipping,payment,cart,const DeepCollectionEquality().hash(items),order);

@override
String toString() {
  return 'CheckoutDraft(contact: $contact, address: $address, shipping: $shipping, payment: $payment, cart: $cart, items: $items, order: $order)';
}


}

/// @nodoc
abstract mixin class $CheckoutDraftCopyWith<$Res>  {
  factory $CheckoutDraftCopyWith(CheckoutDraft value, $Res Function(CheckoutDraft) _then) = _$CheckoutDraftCopyWithImpl;
@useResult
$Res call({
 ContactDetails? contact, Address? address, ShippingMethod shipping, PaymentMethod payment, CartTotals? cart, List<CartItem> items, Order? order
});


$ContactDetailsCopyWith<$Res>? get contact;$AddressCopyWith<$Res>? get address;$CartTotalsCopyWith<$Res>? get cart;$OrderCopyWith<$Res>? get order;

}
/// @nodoc
class _$CheckoutDraftCopyWithImpl<$Res>
    implements $CheckoutDraftCopyWith<$Res> {
  _$CheckoutDraftCopyWithImpl(this._self, this._then);

  final CheckoutDraft _self;
  final $Res Function(CheckoutDraft) _then;

/// Create a copy of CheckoutDraft
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? contact = freezed,Object? address = freezed,Object? shipping = null,Object? payment = null,Object? cart = freezed,Object? items = null,Object? order = freezed,}) {
  return _then(_self.copyWith(
contact: freezed == contact ? _self.contact : contact // ignore: cast_nullable_to_non_nullable
as ContactDetails?,address: freezed == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as Address?,shipping: null == shipping ? _self.shipping : shipping // ignore: cast_nullable_to_non_nullable
as ShippingMethod,payment: null == payment ? _self.payment : payment // ignore: cast_nullable_to_non_nullable
as PaymentMethod,cart: freezed == cart ? _self.cart : cart // ignore: cast_nullable_to_non_nullable
as CartTotals?,items: null == items ? _self.items : items // ignore: cast_nullable_to_non_nullable
as List<CartItem>,order: freezed == order ? _self.order : order // ignore: cast_nullable_to_non_nullable
as Order?,
  ));
}
/// Create a copy of CheckoutDraft
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ContactDetailsCopyWith<$Res>? get contact {
    if (_self.contact == null) {
    return null;
  }

  return $ContactDetailsCopyWith<$Res>(_self.contact!, (value) {
    return _then(_self.copyWith(contact: value));
  });
}/// Create a copy of CheckoutDraft
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
}/// Create a copy of CheckoutDraft
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CartTotalsCopyWith<$Res>? get cart {
    if (_self.cart == null) {
    return null;
  }

  return $CartTotalsCopyWith<$Res>(_self.cart!, (value) {
    return _then(_self.copyWith(cart: value));
  });
}/// Create a copy of CheckoutDraft
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$OrderCopyWith<$Res>? get order {
    if (_self.order == null) {
    return null;
  }

  return $OrderCopyWith<$Res>(_self.order!, (value) {
    return _then(_self.copyWith(order: value));
  });
}
}


/// Adds pattern-matching-related methods to [CheckoutDraft].
extension CheckoutDraftPatterns on CheckoutDraft {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CheckoutDraft value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CheckoutDraft() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CheckoutDraft value)  $default,){
final _that = this;
switch (_that) {
case _CheckoutDraft():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CheckoutDraft value)?  $default,){
final _that = this;
switch (_that) {
case _CheckoutDraft() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( ContactDetails? contact,  Address? address,  ShippingMethod shipping,  PaymentMethod payment,  CartTotals? cart,  List<CartItem> items,  Order? order)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CheckoutDraft() when $default != null:
return $default(_that.contact,_that.address,_that.shipping,_that.payment,_that.cart,_that.items,_that.order);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( ContactDetails? contact,  Address? address,  ShippingMethod shipping,  PaymentMethod payment,  CartTotals? cart,  List<CartItem> items,  Order? order)  $default,) {final _that = this;
switch (_that) {
case _CheckoutDraft():
return $default(_that.contact,_that.address,_that.shipping,_that.payment,_that.cart,_that.items,_that.order);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( ContactDetails? contact,  Address? address,  ShippingMethod shipping,  PaymentMethod payment,  CartTotals? cart,  List<CartItem> items,  Order? order)?  $default,) {final _that = this;
switch (_that) {
case _CheckoutDraft() when $default != null:
return $default(_that.contact,_that.address,_that.shipping,_that.payment,_that.cart,_that.items,_that.order);case _:
  return null;

}
}

}

/// @nodoc


class _CheckoutDraft extends CheckoutDraft {
  const _CheckoutDraft({this.contact, this.address, this.shipping = ShippingMethod.standard, this.payment = PaymentMethod.cashOnDelivery, this.cart, final  List<CartItem> items = const <CartItem>[], this.order}): _items = items,super._();
  

@override final  ContactDetails? contact;
/// The whole address, not its id. The review screen draws it in full, and
/// holding the id would make every later step look it up again in a list
/// it does not otherwise need. Editing an address inside the flow goes
/// through the same step that set this, so the copy cannot go stale
/// (user, 2026-08-29).
@override final  Address? address;
/// Preselected, as the frame draws them.
@override@JsonKey() final  ShippingMethod shipping;
@override@JsonKey() final  PaymentMethod payment;
/// What the cart held when checkout opened.
///
/// A snapshot, handed in by the route the way the signed-in user is. The
/// cart cannot be edited from inside this flow, so it cannot go stale
/// while the flow is open — and the bloc stays testable without a cart.
@override final  CartTotals? cart;
/// The lines the review screen lists. Handed in beside [cart] rather than
/// replacing it: step 3's totals plumbing works and is covered, and
/// deriving one from the other would mean rebuilding it
/// (`09-minimal-changes.md`).
 final  List<CartItem> _items;
/// The lines the review screen lists. Handed in beside [cart] rather than
/// replacing it: step 3's totals plumbing works and is covered, and
/// deriving one from the other would mean rebuilding it
/// (`09-minimal-changes.md`).
@override@JsonKey() List<CartItem> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}

/// Set once the order is placed. Null for the whole flow before that.
@override final  Order? order;

/// Create a copy of CheckoutDraft
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CheckoutDraftCopyWith<_CheckoutDraft> get copyWith => __$CheckoutDraftCopyWithImpl<_CheckoutDraft>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CheckoutDraft&&(identical(other.contact, contact) || other.contact == contact)&&(identical(other.address, address) || other.address == address)&&(identical(other.shipping, shipping) || other.shipping == shipping)&&(identical(other.payment, payment) || other.payment == payment)&&(identical(other.cart, cart) || other.cart == cart)&&const DeepCollectionEquality().equals(other._items, _items)&&(identical(other.order, order) || other.order == order));
}


@override
int get hashCode => Object.hash(runtimeType,contact,address,shipping,payment,cart,const DeepCollectionEquality().hash(_items),order);

@override
String toString() {
  return 'CheckoutDraft(contact: $contact, address: $address, shipping: $shipping, payment: $payment, cart: $cart, items: $items, order: $order)';
}


}

/// @nodoc
abstract mixin class _$CheckoutDraftCopyWith<$Res> implements $CheckoutDraftCopyWith<$Res> {
  factory _$CheckoutDraftCopyWith(_CheckoutDraft value, $Res Function(_CheckoutDraft) _then) = __$CheckoutDraftCopyWithImpl;
@override @useResult
$Res call({
 ContactDetails? contact, Address? address, ShippingMethod shipping, PaymentMethod payment, CartTotals? cart, List<CartItem> items, Order? order
});


@override $ContactDetailsCopyWith<$Res>? get contact;@override $AddressCopyWith<$Res>? get address;@override $CartTotalsCopyWith<$Res>? get cart;@override $OrderCopyWith<$Res>? get order;

}
/// @nodoc
class __$CheckoutDraftCopyWithImpl<$Res>
    implements _$CheckoutDraftCopyWith<$Res> {
  __$CheckoutDraftCopyWithImpl(this._self, this._then);

  final _CheckoutDraft _self;
  final $Res Function(_CheckoutDraft) _then;

/// Create a copy of CheckoutDraft
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? contact = freezed,Object? address = freezed,Object? shipping = null,Object? payment = null,Object? cart = freezed,Object? items = null,Object? order = freezed,}) {
  return _then(_CheckoutDraft(
contact: freezed == contact ? _self.contact : contact // ignore: cast_nullable_to_non_nullable
as ContactDetails?,address: freezed == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as Address?,shipping: null == shipping ? _self.shipping : shipping // ignore: cast_nullable_to_non_nullable
as ShippingMethod,payment: null == payment ? _self.payment : payment // ignore: cast_nullable_to_non_nullable
as PaymentMethod,cart: freezed == cart ? _self.cart : cart // ignore: cast_nullable_to_non_nullable
as CartTotals?,items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<CartItem>,order: freezed == order ? _self.order : order // ignore: cast_nullable_to_non_nullable
as Order?,
  ));
}

/// Create a copy of CheckoutDraft
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ContactDetailsCopyWith<$Res>? get contact {
    if (_self.contact == null) {
    return null;
  }

  return $ContactDetailsCopyWith<$Res>(_self.contact!, (value) {
    return _then(_self.copyWith(contact: value));
  });
}/// Create a copy of CheckoutDraft
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
}/// Create a copy of CheckoutDraft
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CartTotalsCopyWith<$Res>? get cart {
    if (_self.cart == null) {
    return null;
  }

  return $CartTotalsCopyWith<$Res>(_self.cart!, (value) {
    return _then(_self.copyWith(cart: value));
  });
}/// Create a copy of CheckoutDraft
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$OrderCopyWith<$Res>? get order {
    if (_self.order == null) {
    return null;
  }

  return $OrderCopyWith<$Res>(_self.order!, (value) {
    return _then(_self.copyWith(order: value));
  });
}
}

// dart format on
