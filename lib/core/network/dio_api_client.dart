import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:nova_modest/core/error/failure.dart';
import 'package:nova_modest/core/network/api_client.dart';

/// The Dio-backed [ApiClient] — and the **only** place in the app where a
/// [DioException] is caught and turned into a [Failure]
/// (`06-flutter-error-guard.md` §3).
///
/// Consequences checked in review:
/// - no `import 'package:dio/dio.dart'` anywhere under `lib/features/`
/// - no `on DioException catch` outside `lib/core/network/`
/// - no second `Dio` instance, which would escape the interceptor chain
///   (auth, logging) and any future certificate pinning
@LazySingleton(as: ApiClient)
class DioApiClient implements ApiClient {
  const DioApiClient(this._dio);

  final Dio _dio;

  @override
  Future<T> get<T>(String path, {Map<String, dynamic>? query}) async {
    try {
      final response = await _dio.get<T>(path, queryParameters: query);
      return _requireData(response);
    } on DioException catch (e) {
      _mapAndThrow(e);
    }
  }

  @override
  Future<T> post<T>(String path, {Object? body}) async {
    try {
      final response = await _dio.post<T>(path, data: body);
      return _requireData(response);
    } on DioException catch (e) {
      _mapAndThrow(e);
    }
  }

  @override
  Future<T> put<T>(String path, {Object? body}) async {
    try {
      final response = await _dio.put<T>(path, data: body);
      return _requireData(response);
    } on DioException catch (e) {
      _mapAndThrow(e);
    }
  }

  @override
  Future<void> delete(String path) async {
    try {
      await _dio.delete<void>(path);
    } on DioException catch (e) {
      _mapAndThrow(e);
    }
  }

  /// A 2xx with an unexpectedly empty body is a server contract violation, not
  /// a transport error — surfaced rather than returned as a silent null.
  ///
  /// Unless the caller asked for a type that permits null: `post<void>` for a
  /// 204 logout, or an explicitly nullable `T`, both legitimately have no body.
  /// `null is T` is true for `void` and for any nullable `T`, and false for a
  /// non-nullable one, which is exactly the distinction needed here.
  T _requireData<T>(Response<T> response) {
    final data = response.data;
    if (data == null) {
      if (null is T) return null as T;
      throw const ServerFailure('The server returned an empty response.');
    }
    return data;
  }

  /// Returns [Never]: every branch throws, so callers need no fallback.
  Never _mapAndThrow(DioException e) {
    throw switch (e.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.receiveTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.transformTimeout ||
      DioExceptionType.connectionError => const NetworkFailure(),
      DioExceptionType.badCertificate => const NetworkFailure(
        'Could not establish a secure connection.',
      ),
      DioExceptionType.cancel => const UnknownFailure('Request cancelled.'),
      DioExceptionType.badResponse => _mapStatus(e.response),
      DioExceptionType.unknown => const UnknownFailure(),
    };
  }

  Failure _mapStatus(Response<dynamic>? response) =>
      switch (response?.statusCode) {
        401 || 403 => const UnauthorizedFailure(),
        404 => const NotFoundFailure(),
        422 => _validationFailure(response),
        final int code when code >= 500 => ServerFailure(
          'Server error.',
          statusCode: code,
        ),
        _ => const UnknownFailure(),
      };

  /// Parses a 422 body into per-field messages.
  ///
  /// `06-flutter-error-guard.md` §3 writes this as
  /// `ValidationFailure.fromResponse(e.response)`, but that factory would put a
  /// `dio` type in the signature of a `core/error/` class and break the very
  /// containment the same section requires. The parsing lives here instead —
  /// same behaviour, seam intact.
  ///
  /// Expects `{"errors": {"email": ["already taken"]}}`; any other shape falls
  /// back to a field-less [ValidationFailure] rather than throwing while
  /// already on an error path.
  Failure _validationFailure(Response<dynamic>? response) {
    final body = response?.data;
    if (body is! Map) return const ValidationFailure('Validation failed.');

    final errors = body['errors'];
    if (errors is! Map) return const ValidationFailure('Validation failed.');

    final fieldErrors = <String, String>{};
    for (final entry in errors.entries) {
      final key = entry.key;
      final value = entry.value;
      if (key is! String) continue;
      fieldErrors[key] = switch (value) {
        final List<dynamic> list when list.isNotEmpty => '${list.first}',
        final String s => s,
        _ => 'Invalid value.',
      };
    }
    return ValidationFailure('Validation failed.', fieldErrors: fieldErrors);
  }
}
