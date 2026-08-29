import 'package:injectable/injectable.dart';
import 'package:nova_modest/core/network/api_client.dart';
import 'package:nova_modest/features/auth/domain/entities/auth_session.dart';
import 'package:nova_modest/features/auth/domain/entities/user.dart';

/// Talks to the auth endpoints through the [ApiClient] seam.
///
/// Never imports `dio`. Throws a `Failure` (raised by the client) which the
/// repository converts to a [Result].
abstract class AuthRemoteDataSource {
  /// Asks the backend to email a one-time code. Returns nothing on purpose: the
  /// response must not reveal whether the address is registered.
  Future<void> requestEmailCode(String email);

  Future<AuthSession> verifyEmailCode({
    required String email,
    required String code,
  });

  Future<User> me();

  Future<void> logout();
}

@LazySingleton(as: AuthRemoteDataSource)
class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  const AuthRemoteDataSourceImpl(this._apiClient);

  final ApiClient _apiClient;

  @override
  Future<void> requestEmailCode(String email) =>
      _apiClient.post<void>('/auth/email-code', body: {'email': email});

  @override
  Future<AuthSession> verifyEmailCode({
    required String email,
    required String code,
  }) async {
    final json = await _apiClient.post<Map<String, dynamic>>(
      '/auth/email-code/verify',
      body: {'email': email, 'code': code},
    );
    return AuthSession.fromJson(json);
  }

  @override
  Future<User> me() async {
    final json = await _apiClient.get<Map<String, dynamic>>('/auth/me');
    return User.fromJson(json);
  }

  @override
  Future<void> logout() => _apiClient.post<void>('/auth/logout');
}
