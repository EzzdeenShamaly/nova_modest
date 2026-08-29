// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'address.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Address _$AddressFromJson(Map<String, dynamic> json) => _Address(
  id: json['id'] as String,
  kind: $enumDecode(_$AddressKindEnumMap, json['kind']),
  label: json['label'] as String,
  recipientName: json['recipient_name'] as String,
  phone: json['phone'] as String,
  country: json['country'] as String,
  region: json['region'] as String,
  city: json['city'] as String,
  street: json['street'] as String,
  postalCode: json['postal_code'] as String?,
  notes: json['notes'] as String?,
  isDefault: json['is_default'] as bool? ?? false,
);

Map<String, dynamic> _$AddressToJson(_Address instance) => <String, dynamic>{
  'id': instance.id,
  'kind': _$AddressKindEnumMap[instance.kind]!,
  'label': instance.label,
  'recipient_name': instance.recipientName,
  'phone': instance.phone,
  'country': instance.country,
  'region': instance.region,
  'city': instance.city,
  'street': instance.street,
  'postal_code': instance.postalCode,
  'notes': instance.notes,
  'is_default': instance.isDefault,
};

const _$AddressKindEnumMap = {
  AddressKind.home: 'home',
  AddressKind.work: 'work',
  AddressKind.other: 'other',
};
