import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:nova_modest/core/network/api_config.dart';
import 'package:nova_modest/core/network/interceptors/auth_interceptor.dart';
import 'package:nova_modest/core/network/interceptors/logging_interceptor.dart';
import 'package:nova_modest/core/storage/token_storage.dart';

/// Builds the one configured [Dio] instance for the app.
///
/// Lives inside `lib/core/network/` so the `dio` import never leaks into
/// `core/di/`. Registered as a lazy singleton: a second instance would bypass
/// the interceptor chain and any future certificate pinning
/// (`06-flutter-error-guard.md` §3).
@module
abstract class NetworkModule {
  @lazySingleton
  AuthInterceptor authInterceptor(TokenStorage tokenStorage) =>
      AuthInterceptor(tokenStorage);

  @lazySingleton
  Dio dio(AuthInterceptor authInterceptor) => Dio(
    BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: ApiConfig.connectTimeout,
      receiveTimeout: ApiConfig.receiveTimeout,
      sendTimeout: ApiConfig.sendTimeout,
      contentType: Headers.jsonContentType,
      responseType: ResponseType.json,
    ),
  )..interceptors.addAll([authInterceptor, const LoggingInterceptor()]);
}
