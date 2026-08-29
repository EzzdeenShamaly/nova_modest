import 'package:nova_modest/core/error/result.dart';
import 'package:nova_modest/features/auth/domain/entities/user.dart';

/// What the presentation layer depends on.
///
/// **Passwordless.** The product signs people in with Google or a one-time code
/// emailed to them; there is no password anywhere in the system, and therefore no
/// password reset either.
///
/// This is the seam the fake and the real implementation share. Swapping the
/// backend in is one registration line in `core/di/` — no widget, bloc or test
/// above this interface changes.
abstract class AuthRepository {
  /// Runs the Google flow and establishes a session.
  Future<Result<User>> signInWithGoogle();

  /// Asks the backend to email a one-time code to [email].
  ///
  /// Succeeds whether or not an account exists: replying differently would tell
  /// an attacker which addresses are registered.
  Future<Result<void>> requestEmailCode(String email);

  /// Exchanges a code for a session.
  Future<Result<User>> verifyEmailCode({
    required String email,
    required String code,
  });

  /// Saves an edited profile and returns the user as it now stands.
  ///
  /// **The email is deliberately not a parameter.** "The address cannot be
  /// changed" is a rule about the account, not a disabled field in one screen —
  /// stating it in the contract means no caller can express the change at all.
  ///
  /// [phone] may be null: a shopper who signed in with Google can genuinely
  /// have no number, and clearing it is a legitimate edit.
  Future<Result<User>> updateProfile({
    required String displayName,
    String? phone,
  });

  /// Clears the stored session. Succeeds locally even if the server call fails,
  /// because a user who taps "sign out" must end up signed out.
  Future<Result<void>> logout();

  /// The current user if a stored session is still valid, or `null` if there is
  /// none. `null` is "signed out", a legitimate state — an [Ok] value, not an
  /// [Err].
  Future<Result<User?>> currentUser();
}
