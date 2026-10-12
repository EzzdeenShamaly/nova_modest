import 'package:freezed_annotation/freezed_annotation.dart';

part 'user.freezed.dart';
part 'user.g.dart';

/// The signed-in user.
///
/// One `freezed` class serves both the domain entity and the DTO role — a
/// separate `UserModel` that only copies fields across is boilerplate. Split
/// them only if the API shape genuinely diverges from what the app needs.
///
/// Note the `abstract class ... with _$User` form: freezed 3 requires
/// `abstract` (or `sealed`), unlike the plain `class` freezed 2 used.
@freezed
abstract class User with _$User {
  const factory User({
    required String id,
    required String email,
    @JsonKey(name: 'display_name') required String displayName,
    @JsonKey(name: 'avatar_url') String? avatarUrl,

    /// Nullable on purpose: the sign-in flow is Google or an email code, so a
    /// shopper can have an account and no phone number at all. The account
    /// screen omits the line rather than showing an empty one.
    String? phone,

    /// True when this user was built from the **session token alone**, because
    /// the `profiles` row could not be read — see `_userFromSession` in
    /// `SupabaseAuthRepository`. Then [id] and [email] are real, [displayName]
    /// is derived from the address, and [phone] and [avatarUrl] are *unknown*
    /// rather than absent.
    ///
    /// That distinction is the whole point of the flag. Without it a form
    /// pre-filled from this user cannot tell "she has no number" from "we never
    /// read it", and saving the form writes `phone: null` over a real number.
    ///
    /// Never serialised in either direction: it describes how this object was
    /// obtained, not a column. A row that was read is never from the session.
    @JsonKey(includeFromJson: false, includeToJson: false)
    @Default(false)
    bool fromSession,
  }) = _User;

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
}
