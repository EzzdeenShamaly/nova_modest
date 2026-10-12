import 'dart:typed_data';

import 'package:flutter/foundation.dart' show debugPrint, visibleForTesting;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:injectable/injectable.dart';
import 'package:nova_modest/core/error/failure.dart';
import 'package:nova_modest/core/error/result.dart';
import 'package:nova_modest/core/media/image_bytes.dart';
import 'package:nova_modest/core/supabase/secure_session_storage.dart';
import 'package:nova_modest/core/supabase/supabase_error_mapper.dart';
import 'package:nova_modest/features/auth/domain/entities/user.dart';
import 'package:nova_modest/features/auth/domain/repositories/auth_repository.dart';
// hide User: gotrue exports its own `User` through supabase_flutter, which
// shadows this app's entity — the same collision injectable's `Order` causes in
// the orders feature.
import 'package:supabase_flutter/supabase_flutter.dart' hide User;

/// Live [AuthRepository] against Supabase Auth + `profiles`.
@LazySingleton(as: AuthRepository, env: [Environment.dev])
class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository();

  static const String _googleWebClientId = String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
  );

  /// Private bucket, `png/jpeg/webp`, 2 MiB — read from the live project on
  /// 2026-09-20 rather than assumed. The size is repeated here so a picture the
  /// bucket will refuse is refused in Arabic, before the upload, instead of
  /// coming back as a bare 413.
  static const String _avatarBucket = 'avatars';
  static const int _maxAvatarBytes = 2 * 1024 * 1024;

  /// One object per shopper, at `<uid>/avatar`.
  ///
  /// The first path segment must be the uid: all three storage policies are
  /// `(storage.foldername(name))[1] = auth.uid()`. A fixed name under it means
  /// the second upload **overwrites** the first — which is the only way to
  /// replace a picture here, because the bucket grants INSERT, SELECT and
  /// UPDATE and **no DELETE** (measured 2026-09-20). Dated names would leave
  /// every old picture behind with nothing able to remove them.
  String _avatarPath(String userId) => '$userId/avatar';

  /// How long a display link stays good for.
  ///
  /// One hour, matching the access token's own lifetime: a link that outlived
  /// the session would keep a private object reachable after sign-out, and one
  /// much shorter would expire while the shopper is still looking at the
  /// screen it was minted for.
  static const int _signedUrlSeconds = 60 * 60;

  SupabaseClient get _client => client;

  /// The seam a test substitutes a loopback Supabase through, exactly as
  /// `SupabaseOrderRepository` does. The app always gets the real one.
  @visibleForTesting
  SupabaseClient get client => Supabase.instance.client;

  /// The signed-in shopper, as the second seam: a loopback client has no
  /// session, and every write below needs to know whose row it is writing.
  @visibleForTesting
  String? get currentUserId => client.auth.currentUser?.id;

  /// The address on the token, as the third seam. It is the one profile field
  /// the session itself carries, so it is what a degraded read can still show.
  @visibleForTesting
  String? get currentEmail => client.auth.currentUser?.email;

  @override
  Future<Result<User>> signInWithGoogle() async {
    if (_googleWebClientId.isEmpty) {
      return const Err(
        ServerFailure(
          'Google sign-in is not configured. Set GOOGLE_WEB_CLIENT_ID and '
          'enable the Google provider in Supabase.',
        ),
      );
    }

    try {
      final googleSignIn = GoogleSignIn(
        scopes: const ['email', 'profile'],
        serverClientId: _googleWebClientId,
      );
      final account = await googleSignIn.signIn();
      if (account == null) {
        return const Err(UnauthorizedFailure('Google sign-in was cancelled.'));
      }

      final googleAuth = await account.authentication;
      final idToken = googleAuth.idToken;
      if (idToken == null) {
        return const Err(ServerFailure('Google did not return an ID token.'));
      }

      await _client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: googleAuth.accessToken,
      );
      return await _readCurrentUser();
    } on Failure catch (failure) {
      return Err(failure);
    } catch (error) {
      return Err(mapSupabaseError(error));
    }
  }

  @override
  Future<Result<void>> requestEmailCode(String email) async {
    try {
      // Always succeeds from the caller's point of view: a distinct response
      // for an unknown address would be an account-enumeration oracle.
      await _client.auth.signInWithOtp(email: email, shouldCreateUser: true);
      return const Ok(null);
    } catch (_) {
      return const Ok(null);
    }
  }

  @override
  Future<Result<User>> verifyEmailCode({
    required String email,
    required String code,
  }) async {
    try {
      await _client.auth.verifyOTP(
        email: email,
        token: code,
        type: OtpType.email,
      );
      return await _readCurrentUser();
    } catch (error) {
      return Err(mapSupabaseError(error));
    }
  }

  @override
  Future<Result<User>> updateProfile({
    required String displayName,
    String? phone,
  }) async {
    try {
      final userId = currentUserId;
      if (userId == null) {
        return const Err(UnauthorizedFailure());
      }

      await _client
          .from('profiles')
          .update({'display_name': displayName, 'phone': phone})
          .eq('id', userId);

      return await _readCurrentUser();
    } catch (error) {
      return Err(mapSupabaseError(error));
    }
  }

  @override
  Future<Result<User>> uploadAvatar(Uint8List imageBytes) async {
    try {
      final userId = currentUserId;
      if (userId == null) {
        return const Err(UnauthorizedFailure());
      }

      // From the bytes, never from a file name: the picker reports whatever the
      // device called the file, and the bucket checks the content type against
      // its own list.
      final format = ImageFormat.of(imageBytes);
      if (format == null) {
        return const Err(
          ValidationFailure(
            'Unsupported image format.',
            code: 'avatar_unsupported_format',
          ),
        );
      }
      if (imageBytes.length > _maxAvatarBytes) {
        return const Err(
          ValidationFailure('Image too large.', code: 'avatar_too_large'),
        );
      }

      await _client.storage
          .from(_avatarBucket)
          .uploadBinary(
            _avatarPath(userId),
            imageBytes,
            fileOptions: FileOptions(
              contentType: format.mimeType,
              // Replace in place. See _avatarPath: there is no DELETE policy,
              // so overwriting is how a picture changes.
              upsert: true,
            ),
          );

      // The **path** is stored, not a link: a signed link expires, and a row
      // holding a dead URL is worse than one holding the object's name. Nothing
      // else reads this column — the dashboard does not render shopper
      // avatars — so the storefront owns its shape.
      await _client
          .from('profiles')
          .update({'avatar_url': _avatarPath(userId)})
          .eq('id', userId);

      return await _readCurrentUser();
    } catch (error) {
      return Err(mapSupabaseError(error));
    }
  }

  @override
  Future<Result<void>> deleteAccount() async {
    try {
      // The dashboard's `delete-account` Edge Function. Identity is the
      // session's own token, which the client attaches; the body is empty on
      // purpose, because the function never reads identity from it.
      await _client.functions.invoke('delete-account', body: const {});
    } catch (error) {
      // 401 → UnauthorizedFailure, anything else keeps its code
      // (`_functionFailure` in the mapper).
      return Err(mapSupabaseError(error));
    }

    // Deleted. What is left is this device's copy of a session for an account
    // that no longer exists.
    await clearLocalSession();
    return const Ok(null);
  }

  /// Ends the session **on this device only**, without depending on the
  /// server.
  ///
  /// `signOut` drops the in-memory session and announces `signedOut` *before*
  /// it calls the server (`gotrue_client.dart`, `_signOut`), and it swallows a
  /// 401, 403 or 404 from that call — but it rethrows anything else, and with
  /// the account gone that call has nothing left to do anyway. So it runs
  /// inside a catch, for its local half. The keystore is then cleared
  /// explicitly rather than trusting the `signedOut` listener to do it: the
  /// account no longer exists, and a refresh token for it must not survive on
  /// the device by any path.
  @visibleForTesting
  Future<void> clearLocalSession() async {
    try {
      await _client.auth.signOut(scope: SignOutScope.local);
    } catch (_) {
      // Expected: the server no longer knows this account. The local half has
      // already run.
    }
    await SecureSessionStorage().removePersistedSession();
  }

  @override
  Future<Result<void>> logout() async {
    try {
      await _client.auth.signOut();
    } catch (_) {
      // A user who taps sign out must end up signed out even if the server
      // is unreachable. Local session clear still happens inside signOut.
    }
    return const Ok(null);
  }

  @override
  Future<Result<User?>> currentUser() async {
    try {
      if (currentUserId == null) {
        return const Ok(null);
      }
      return await _readCurrentUser();
    } on UnauthorizedFailure {
      await _client.auth.signOut();
      return const Ok(null);
    } catch (error) {
      final failure = mapSupabaseError(error);
      if (failure is UnauthorizedFailure) {
        await _client.auth.signOut();
        return const Ok(null);
      }
      return Err(failure);
    }
  }

  /// How long the session check may wait on the profile read.
  ///
  /// Eight seconds. Measured 2026-10-11: the read takes under a second against
  /// a healthy project, while an unreachable one sat for **59 seconds** behind
  /// the SDK's own retry chain — the token refresh retries every 13–16 s and
  /// postgrest retries on top of that. The app opens on what the session knows
  /// rather than waiting that out. The request itself is not cancelled; its
  /// answer is simply no longer waited for.
  static const Duration _profileReadTimeout = Duration(seconds: 8);

  Future<Result<User>> _readCurrentUser() async {
    final userId = currentUserId;
    if (userId == null) {
      return const Err(UnauthorizedFailure());
    }
    final email = currentEmail;

    final Map<String, dynamic>? row;
    try {
      row = await _client
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle()
          .timeout(_profileReadTimeout);
    } catch (error) {
      // **A network failure only.** The session is valid and the token says who
      // she is; what is missing is the row. Going "signed out" here would lie
      // to a signed-in shopper silently, and the account tab would send her to
      // the sign-in screen (owner, 2026-10-12).
      //
      // Anything else keeps its meaning and travels on: a policy refusal signs
      // her out at the caller, a server error is reported. Falling back on
      // those would keep her "signed in" on a token the server has rejected.
      if (mapSupabaseError(error) is NetworkFailure) {
        return Ok(_userFromSession(userId, email));
      }
      rethrow;
    }

    if (row == null) {
      return Ok(_userFromSession(userId, email));
    }

    return Ok(await withSignedAvatar(User.fromJson(row)));
  }

  /// What the token alone can say: the id and the address, with a name derived
  /// from the address. `display_name`, `phone` and `avatar_url` live in
  /// `profiles` and are simply not known yet — the avatar falls back to her
  /// initial, and the account screen omits a phone line rather than showing an
  /// empty one.
  /// `fromSession` is what stops a form pre-filled from this object writing its
  /// own blanks back over a real row (`User.fromSession`).
  User _userFromSession(String userId, String? email) => User(
    id: userId,
    email: email ?? '',
    displayName: email?.split('@').first ?? 'Shopper',
    fromSession: true,
  );

  /// Turns the stored avatar **path** into a link the app can draw.
  ///
  /// Signed once here, per profile read, rather than once per widget: every
  /// screen then reads the one `User.avatarUrl` it already has, and a list of
  /// ten rows does not mint ten links for the same object. A profile is read on
  /// launch, after a sign-in and after an edit, so the link is never much older
  /// than the screen showing it.
  ///
  /// **Failure leaves it null.** An expired session or a dead network returns
  /// the user with no picture, and the avatar falls back to the shopper's
  /// initial — not an error screen, and not a broken-image icon, for something
  /// decorative (user, 2026-09-20).
  @visibleForTesting
  Future<User> withSignedAvatar(User user) async {
    final path = user.avatarUrl;
    if (path == null || path.isEmpty) return user;

    // A value written before this version, or by anything else, may already be
    // a full URL. Signing that would fail; passing it through costs nothing.
    if (path.startsWith('http')) return user;

    try {
      final signed = await _client.storage
          .from(_avatarBucket)
          .createSignedUrl(path, _signedUrlSeconds)
          // On the session-check path as well, so a stalled network cannot
          // hold the app open here after the read itself was bounded.
          .timeout(_profileReadTimeout);
      return user.copyWith(avatarUrl: signed);
    } catch (error) {
      debugPrint('avatar: could not sign $path ($error)');
      return user.copyWith(avatarUrl: null);
    }
  }
}
