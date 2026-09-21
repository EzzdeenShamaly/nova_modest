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
    if (error.code == 'P0001') {
      // The order contract's format: a stable code in `message`, the prose
      // explanation in `details`. The code is carried through so the UI can say
      // which refusal this was instead of one generic sentence for all thirteen
      // (`supabase/contract/customer.md`, *Place an order*).
      return ValidationFailure(error.message, code: error.message);
    }
    if (error.code == '23514') {
      // A CHECK violation, deliberately carrying **no** code: `message` here is
      // Postgres's constraint text, not a contract code, and passing it as one
      // would invent a fourteenth.
      //
      // No path in this app reaches one today. Every CHECK lives on `orders`,
      // `order_items` or `products`; the app holds no INSERT or UPDATE
      // privilege on any of them (revoked in `20260829120000_init.sql`), and
      // `place_order` refuses with `P0001` long before its own insert. The one
      // table the app does write, `user_addresses`, has no CHECK at all — only
      // the partial unique index `user_addresses_one_default`, which raises
      // **23505**, not this. Kept because a future constraint should degrade to
      // a sensible message rather than to `UnknownFailure`.
      return ValidationFailure(error.message);
    }
    return ServerFailure(error.message);
  }
  if (error is FunctionException) {
    return _functionFailure(error);
  }
  return UnknownFailure(error.toString());
}

/// An Edge Function's refusal. The dashboard's functions answer in one format —
/// `{"code": "...", "detail": "..."}` with a meaningful status — and the SDK
/// hands back that body, parsed, as `details`.
///
/// **A 401 is a lost session, not a refusal**, whatever code rides with it:
/// it becomes [UnauthorizedFailure] so the caller treats it as every other
/// expired session is treated, by signing out and returning to sign-in
/// (owner, 2026-09-21). Everything else keeps its code, so the UI can say which
/// refusal it was; a response with no readable code keeps none, and falls to
/// the generic message rather than inventing one.
Failure _functionFailure(FunctionException error) {
  final details = error.details;
  final code = details is Map ? details['code'] : null;
  if (error.status == 401) {
    return UnauthorizedFailure(code is String ? code : 'Session expired.');
  }
  if (code is String && code.isNotEmpty) {
    return ValidationFailure(code, code: code);
  }
  return ServerFailure('Function failed with ${error.status}.');
}
