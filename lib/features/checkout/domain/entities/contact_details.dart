import 'package:freezed_annotation/freezed_annotation.dart';

part 'contact_details.freezed.dart';

/// Who the order is for and how to reach them, from Figma `1:2163`.
///
/// The frame collects a **name and a phone number only**. [email] is not one of
/// its fields: it comes from the account when there is one, rides along so
/// "مراجعة الطلب" can show it as the design draws, and is null for a guest.
///
/// **That leaves a guest order with no email to confirm to** — a real gap,
/// raised with the user and recorded in `progress.md` rather than closed by
/// inventing a field the design does not have.
@freezed
abstract class ContactDetails with _$ContactDetails {
  const ContactDetails._();

  const factory ContactDetails({
    @Default('') String fullName,
    @Default('') String phone,
    String? email,
  }) = _ContactDetails;

  /// Whether both collected fields have something in them.
  ///
  /// Not a substitute for the form's validation — that reports *which* field is
  /// wrong and why. This answers the different question the bloc asks: is the
  /// draft complete enough to move on.
  bool get isComplete => fullName.trim().isNotEmpty && phone.trim().isNotEmpty;
}
