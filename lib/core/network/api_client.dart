/// The transport seam (`06-flutter-error-guard.md` §3).
///
/// Everything above `lib/core/network/` depends on this interface, never on
/// `dio`. Implementations throw a [Failure] — never a transport-level
/// exception — so no layer above this one imports a networking package.
abstract class ApiClient {
  Future<T> get<T>(String path, {Map<String, dynamic>? query});

  Future<T> post<T>(String path, {Object? body});

  Future<T> put<T>(String path, {Object? body});

  Future<void> delete(String path);
}
