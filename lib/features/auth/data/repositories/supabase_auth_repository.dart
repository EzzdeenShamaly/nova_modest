import 'package:google_sign_in/google_sign_in.dart';
import 'package:injectable/injectable.dart';
import 'package:nova_modest/core/error/failure.dart';
import 'package:nova_modest/core/error/result.dart';
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

  SupabaseClient get _client => Supabase.instance.client;

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
      return _readCurrentUser();
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
      return _readCurrentUser();
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
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        return const Err(UnauthorizedFailure());
      }

      await _client
          .from('profiles')
          .update({'display_name': displayName, 'phone': phone})
          .eq('id', userId);

      return _readCurrentUser();
    } catch (error) {
      return Err(mapSupabaseError(error));
    }
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
      if (_client.auth.currentSession == null) {
        return const Ok(null);
      }
      return _readCurrentUser();
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

  Future<Result<User>> _readCurrentUser() async {
    final authUser = _client.auth.currentUser;
    if (authUser == null) {
      return const Err(UnauthorizedFailure());
    }

    final row = await _client
        .from('profiles')
        .select()
        .eq('id', authUser.id)
        .maybeSingle();

    if (row == null) {
      return Ok(
        User(
          id: authUser.id,
          email: authUser.email ?? '',
          displayName: authUser.email?.split('@').first ?? 'Shopper',
        ),
      );
    }

    return Ok(User.fromJson(row));
  }
}
