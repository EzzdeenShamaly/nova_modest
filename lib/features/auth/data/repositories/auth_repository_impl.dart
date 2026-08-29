import 'package:nova_modest/core/error/failure.dart';
import 'package:nova_modest/core/error/result.dart';
import 'package:nova_modest/core/storage/token_storage.dart';
import 'package:nova_modest/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:nova_modest/features/auth/domain/entities/user.dart';
import 'package:nova_modest/features/auth/domain/repositories/auth_repository.dart';

/// The real, HTTP-backed [AuthRepository].
///
/// **Deliberately not registered.** `FakeAuthRepository` carries the app until
/// the backend exists; this class is the skeleton that replaces it. Switching
/// over is one line in `core/di/` plus re-running the generator — no widget,
/// bloc or test above the interface changes.
///
/// Endpoint paths and payload shapes below are assumptions and must be confirmed
/// against the real API before this is turned on. See `progress.md` → Blocked.
class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl(this._remote, this._tokenStorage);

  final AuthRemoteDataSource _remote;
  final TokenStorage _tokenStorage;

  @override
  Future<Result<User>> signInWithGoogle() async {
    // Intentionally unimplemented, and unreachable: this class is not
    // registered. Completing it needs a native sign-in package to obtain a
    // Google ID token, which is not in pubspec.yaml and would need to be asked
    // for explicitly (10-evidence-and-dependency-guard.md). The token then goes
    // to the backend through `_remote`, and the branch below mirrors
    // `verifyEmailCode`.
    throw UnimplementedError(
      'Google sign-in needs a native sign-in package; see the class doc.',
    );
  }

  @override
  Future<Result<void>> requestEmailCode(String email) async {
    try {
      await _remote.requestEmailCode(email);
      return const Ok(null);
    } on Failure catch (failure) {
      return Err(failure);
    }
  }

  @override
  Future<Result<User>> verifyEmailCode({
    required String email,
    required String code,
  }) async {
    try {
      final session = await _remote.verifyEmailCode(email: email, code: code);
      await _tokenStorage.saveTokens(
        accessToken: session.accessToken,
        refreshToken: session.refreshToken,
      );
      // Only the user crosses this boundary; the tokens stop here.
      return Ok(session.user);
    } on Failure catch (failure) {
      return Err(failure);
    }
  }

  @override
  Future<Result<User>> updateProfile({
    required String displayName,
    String? phone,
  }) async {
    // Intentionally unimplemented, and unreachable: this class is not
    // registered. The endpoint and its payload shape are not confirmed, and
    // guessing them here would put a fiction behind a compiling method
    // (`10-evidence-and-dependency-guard.md`). Recorded in progress.md
    // alongside the other unconfirmed endpoints.
    throw UnimplementedError(
      'updateProfile needs a confirmed backend endpoint.',
    );
  }

  @override
  Future<Result<void>> logout() async {
    try {
      await _remote.logout();
    } on Failure catch (_) {
      // Intentionally swallowed: a user who taps "sign out" must end up signed
      // out even if the server is unreachable. The local clear below is what
      // actually signs them out.
    }

    try {
      await _tokenStorage.clear();
      return const Ok(null);
    } on Failure catch (failure) {
      // Failing to clear the token IS reportable — the session survives.
      return Err(failure);
    }
  }

  @override
  Future<Result<User?>> currentUser() async {
    try {
      final stored = await _tokenStorage.readAccessToken();
      if (stored == null || stored.isEmpty) {
        // No stored session is "signed out", not a failure.
        return const Ok(null);
      }
      return Ok(await _remote.me());
    } on UnauthorizedFailure catch (_) {
      // A stored token the server rejects is a stale session, not an error to
      // show the user: clear it and report signed-out.
      await _tokenStorage.clear();
      return const Ok(null);
    } on Failure catch (failure) {
      return Err(failure);
    }
  }
}
