import 'package:dio/dio.dart';
import 'package:nova_modest/core/storage/token_storage.dart';

/// Attaches the stored access token to every outgoing request.
///
/// Lives inside `lib/core/network/`, which is the boundary `dio` is allowed to
/// cross — nothing under `lib/features/` imports it
/// (`06-flutter-error-guard.md` §3).
///
/// **Refresh-on-401 is deliberately not implemented here.** That flow needs a
/// second, interceptor-free `Dio` instance to avoid a refresh loop, plus
/// single-flight queueing so ten concurrent 401s produce one refresh rather
/// than ten. `/flutter-network-gen` owns it. Until then a 401 maps straight to
/// `UnauthorizedFailure` and the router's redirect guard sends the user to the
/// login screen, which is correct behaviour — just less forgiving than a
/// refresh would be.
class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._tokenStorage);

  final TokenStorage _tokenStorage;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _tokenStorage.readAccessToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }
}
