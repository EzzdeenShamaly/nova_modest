import 'package:freezed_annotation/freezed_annotation.dart';

part 'address.freezed.dart';
part 'address.g.dart';

/// What an address is for, which is what picks its glyph.
///
/// Separate from the address's [Address.label] so a shopper can call it
/// whatever they like — "بيت أمي" is a home — without the icon having to be
/// guessed from a string that changes with the language.
enum AddressKind {
  @JsonValue('home')
  home,
  @JsonValue('work')
  work,
  @JsonValue('other')
  other,
}

/// A delivery address.
///
/// Deliberately **not** a profile-screen type. It is owned by
/// `features/address/` because two features need it: the account section
/// manages the list today, and checkout will pick one from it. Building it
/// inside `features/profile/` would have left checkout depending on the account
/// screen to ask for a delivery address.
@freezed
abstract class Address with _$Address {
  const Address._();

  const factory Address({
    required String id,
    required AddressKind kind,

    /// What the shopper calls it — "المنزل", "العمل", anything.
    required String label,
    @JsonKey(name: 'recipient_name') required String recipientName,
    required String phone,
    required String country,

    /// The neighbourhood or district, as the design's form labels it
    /// ("المنطقة"): "العليا", not "الرياض".
    required String region,
    required String city,

    /// Street and building, one line: "شارع الملك فهد، مبنى ٤٥".
    required String street,
    @JsonKey(name: 'postal_code') String? postalCode,

    /// A landmark or a preferred delivery time. Optional, and shown nowhere on
    /// the card — it is for whoever delivers.
    String? notes,
    @JsonKey(name: 'is_default') @Default(false) bool isDefault,
  }) = _Address;

  factory Address.fromJson(Map<String, dynamic> json) =>
      _$AddressFromJson(json);

  /// The postal block the list card draws: recipient, street, locality,
  /// country, phone.
  ///
  /// Which fields appear and in what order is a rule about the data, so it
  /// lives here rather than in a widget (`01-flutter-architecture-guard.md`) —
  /// and both this screen and checkout read the same one instead of composing
  /// it twice.
  ///
  /// **Assumes one country's postal convention.** Ordering genuinely differs
  /// between countries; the day a second one is supported this becomes a
  /// per-country formatter, not a longer getter.
  List<String> get postalLines => [
    recipientName,
    street,
    [
      region,
      if (postalCode case final code?) '$city $code' else city,
    ].join(_separator),
    country,
    phone,
  ];

  /// The two-line form the checkout card uses, widest first.
  String get shortSummary => [country, city, region, street].join(_separator);

  /// The three lines the review screen draws (`1:1840`): where, then which
  /// city, then the postal code called out on its own.
  ///
  /// A third arrangement of the same fields, and it lives here beside the other
  /// two for the same reason they do — which fields appear and in what order is
  /// a rule about the data. A widget composing it would be the fourth place
  /// this decision lived.
  ///
  /// The postal line is dropped entirely when there is no code, rather than
  /// drawn with a blank after the label.
  List<String> reviewLines(String postalCodeLabel) => [
    [street, region].join(_separator),
    [city, country].join(_separator),
    if (postalCode case final code?) '$postalCodeLabel $code',
  ];

  /// The Arabic comma, as both frames draw it.
  ///
  /// Punctuation that varies by locale, and deferred alongside the field order
  /// above rather than pretended not to exist.
  static const String _separator = '، ';
}
