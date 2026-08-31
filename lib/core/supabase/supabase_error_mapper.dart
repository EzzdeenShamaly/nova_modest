import 'dart:async';
import 'dart:io';

import 'package:nova_modest/core/error/failure.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Maps SDK / I/O errors onto the app-wide [Failure] hierarchy.
///
/// [Failure.message] is developer-facing only; widgets switch on the type.
Failure mapSupabaseError(Object error) {
  if (error is SocketException || error is TimeoutException) {
    return const NetworkFailure();
  }
  if (error is AuthException) {
    // `error.code` first, `statusCode` only as a fallback.
    //
    // The status alone cannot tell these apart: GoTrue answers **403** both for
    // "your session expired" and for "that sign-in code is wrong", and reading
    // the status first collapsed the second into the first. A shopper halfway
    // through signing in was told their session had expired and to sign in
    // again — about a code they had just been emailed. That is what made the
    // real defect underneath it so hard to see.
    //
    // Only codes this project has evidence for are listed
    // (`10-evidence-and-dependency-guard.md`): `otp_expired` was observed live
    // on `/verify`, and the rate-limit pair is bounded by `[auth.rate_limit]`
    // in `supabase/config.toml`, so both are reachable here. Anything else
    // falls through to the status, which is the behaviour that was already
    // there.
    switch (error.code) {
      // A code that does not match, or one superseded by a newer request.
      // Wrong input, not a lost session.
      case 'otp_expired':
      case 'validation_failed':
      case 'over_email_send_rate_limit':
      case 'over_request_rate_limit':
        return ValidationFailure(error.message);
      case 'session_expired':
      case 'session_not_found':
        return UnauthorizedFailure(error.message);
    }

    final status = error.statusCode;
    if (status == '401' || status == '403') {
      return UnauthorizedFailure(error.message);
    }
    if (status == '422') {
      return ValidationFailure(error.message);
    }
    // The original text heuristic, kept as a last resort rather than removed.
    // It is fragile — it matches English substrings — but it was catching
    // something before this function learned to read codes, and dropping it
    // would quietly turn those into ServerFailure. Behind the switch above it
    // can no longer swallow an authorisation error.
    if (error.message.toLowerCase().contains('otp') ||
        error.message.toLowerCase().contains('token')) {
      return ValidationFailure(error.message);
    }
    return ServerFailure(error.message);
  }
  if (error is PostgrestException) {
    if (error.code == 'PGRST116') {
      return const NotFoundFailure();
    }
    if (error.code == '42501' || error.code == 'PGRST301') {
      return UnauthorizedFailure(error.message);
    }
    if (error.code == 'P0001' || error.code == '23514') {
      return ValidationFailure(error.message);
    }
    return ServerFailure(error.message);
  }
  return UnknownFailure(error.toString());
}
