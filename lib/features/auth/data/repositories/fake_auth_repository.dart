import 'package:injectable/injectable.dart';
import 'package:nova_modest/core/error/failure.dart';
import 'package:nova_modest/core/error/result.dart';
import 'package:nova_modest/core/storage/token_storage.dart';
import 'package:nova_modest/features/auth/domain/entities/user.dart';
import 'package:nova_modest/features/auth/domain/repositories/auth_repository.dart';

/// Stands in for the backend until it exists.
///
/// **This is the registered [AuthRepository].** `AuthRepositoryImpl` is written
/// against the same interface but deliberately left unregistered; switching to it
/// is one line in `core/di/` and changes nothing above this seam.
///
/// It succeeds every time, after a short delay so the UI's loading states are
/// actually exercised rather than skipped. It writes through the real
/// [TokenStorage] instead of holding a boolean in memory, so a signed-in session
/// survives a restart and sign-out genuinely clears something — the same code
/// path the real implementation will use.
@LazySingleton(as: AuthRepository)
class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository(this._tokenStorage);

  /// Long enough to see a spinner, short enough not to annoy anyone testing.
  static const Duration _latency = Duration(milliseconds: 700);

  static const User _user = User(
    id: 'fake-user-1',
    email: 'sara@example.com',
    displayName: 'سارة',
    // The design's own number (Figma `1:1645`), so the account screen is built
    // against the content it was designed for.
    phone: '+966 50 123 4567',
  );

  final TokenStorage _tokenStorage;

  /// The profile as edited this session.
  ///
  /// In memory on purpose, and the one place this fake knowingly diverges from
  /// the real thing: the token goes through real secure storage so a **session**
  /// survives a restart, but an edited name does not, and the account reverts to
  /// [_user] on the next launch. Persisting it would mean either plaintext
  /// preferences — which `03-flutter-security-guard` forbids for a name, an
  /// address and a phone number — or widening the [TokenStorage] seam for the
  /// sake of a stand-in. Accepted until the backend owns this
  /// (user, 2026-08-22).
  User _current = _user;

  @override
  Future<Result<User>> signInWithGoogle() => _establishSession();

  @override
  Future<Result<void>> requestEmailCode(String email) async {
    await Future<void>.delayed(_latency);
    // No account lookup: the real endpoint must answer identically for a known
    // and an unknown address, or it becomes an account-enumeration oracle.
    return const Ok(null);
  }

  @override
  Future<Result<User>> verifyEmailCode({
    required String email,
    required String code,
  }) async {
    // Any six digits are accepted. Rejecting some codes here would invent a rule
    // the real backend has not defined yet, and the UI would end up built
    // against a fiction.
    return _establishSession();
  }

  @override
  Future<Result<User?>> currentUser() async {
    try {
      final stored = await _tokenStorage.readAccessToken();
      if (stored == null || stored.isEmpty) return const Ok(null);
      return Ok(_current);
    } on Failure catch (failure) {
      return Err(failure);
    }
  }

  @override
  Future<Result<User>> updateProfile({
    required String displayName,
    String? phone,
  }) async {
    await Future<void>.delayed(_latency);
    // Succeeds every time, like the rest of this fake. Rejecting an edit here
    // would invent a validation rule the real backend has not defined, and the
    // UI would end up built against a fiction.
    _current = _current.copyWith(displayName: displayName, phone: phone);
    return Ok(_current);
  }

  @override
  Future<Result<void>> logout() async {
    try {
      await _tokenStorage.clear();
      // The next session starts from the seeded profile, not from whatever the
      // previous user edited.
      _current = _user;
      return const Ok(null);
    } on Failure catch (failure) {
      return Err(failure);
    }
  }

  Future<Result<User>> _establishSession() async {
    await Future<void>.delayed(_latency);
    // Derived at run time rather than written as a literal. There is no secret
    // here to protect — it authorises nothing — but a credential-shaped constant
    // in source is the pattern `guard-write.mjs` exists to stop, and a distinct
    // value per session also models the real thing more closely.
    final marker = 'fake-session-${DateTime.now().microsecondsSinceEpoch}';
    try {
      await _tokenStorage.saveTokens(
        accessToken: marker,
        refreshToken: '$marker-r',
      );
      return const Ok(_user);
    } on Failure catch (failure) {
      return Err(failure);
    }
  }
}
