import 'dart:developer' as developer;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Debug-build request/response logging.
///
/// Never logs headers or request bodies: the `Authorization` header carries the
/// bearer token and a login body carries a password, and neither may reach a
/// log sink (`03-flutter-security-guard.md`). Method, path and status code are
/// enough to diagnose a failing call.
///
/// Guarded by [kDebugMode] so it is inert in release builds.
class LoggingInterceptor extends Interceptor {
  const LoggingInterceptor();

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (kDebugMode) {
      developer.log('→ ${options.method} ${options.path}', name: 'network');
    }
    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    if (kDebugMode) {
      developer.log(
        '← ${response.statusCode} ${response.requestOptions.path}',
        name: 'network',
      );
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (kDebugMode) {
      developer.log(
        '✗ ${err.type.name} ${err.requestOptions.path} '
        '(${err.response?.statusCode ?? 'no response'})',
        name: 'network',
      );
    }
    handler.next(err);
  }
}
