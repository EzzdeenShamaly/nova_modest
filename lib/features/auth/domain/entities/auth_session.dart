import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:nova_modest/features/auth/domain/entities/user.dart';

part 'auth_session.freezed.dart';
part 'auth_session.g.dart';

/// The login endpoint's response: the user plus the token pair.
///
/// Deliberately **not** exposed above the data layer. The repository strips the
/// tokens into [TokenStorage] and returns only the [User], so no token value
/// reaches a Bloc, a widget, or anything that could end up in a log or a crash
/// report (`03-flutter-security-guard.md`).
///
/// `toString` is overridden for the same reason: the generated one would print
/// both tokens.
@freezed
abstract class AuthSession with _$AuthSession {
  const factory AuthSession({
    required User user,
    @JsonKey(name: 'access_token') required String accessToken,
    @JsonKey(name: 'refresh_token') required String refreshToken,
  }) = _AuthSession;

  factory AuthSession.fromJson(Map<String, dynamic> json) =>
      _$AuthSessionFromJson(json);
}

extension AuthSessionRedaction on AuthSession {
  /// Use this in any diagnostic string instead of the object itself.
  String get redacted => 'AuthSession(user: ${user.id}, tokens: <redacted>)';
}
