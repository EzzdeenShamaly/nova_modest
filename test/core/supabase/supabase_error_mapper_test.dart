import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nova_modest/core/error/failure.dart';
import 'package:nova_modest/core/supabase/supabase_error_mapper.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// The first tests for anything in `core/supabase/`.
///
/// This function is the whole reason a shopper ever sees a sensible message
/// instead of a raw SDK exception, and it is pure — no client, no server, no
/// network. There was no excuse for it being untested.
void main() {
  group('an auth error is read by its code, not by its status', () {
    test('a wrong or stale sign-in code is a validation failure', () {
      // Observed live: GoTrue answers `/verify` with 403 and
      // `error_code: otp_expired` for a code that does not match. Reading the
      // status first made that an UnauthorizedFailure, whose message is
      // "your session expired, sign in again" — told to someone in the middle
      // of signing in, about a code they had just been emailed.
      final failure = mapSupabaseError(
        const AuthException(
          'Token has expired or is invalid',
          statusCode: '403',
          code: 'otp_expired',
        ),
      );

      expect(failure, isA<ValidationFailure>());
    });

    test('a rate-limited request is a validation failure, not a server one', () {
      // `[auth.rate_limit]` in config.toml caps email sends and verifications,
      // so this is reachable by anyone tapping resend a few times.
      for (final code in const [
        'over_email_send_rate_limit',
        'over_request_rate_limit',
      ]) {
        expect(
          mapSupabaseError(
            AuthException('Too many requests', statusCode: '429', code: code),
          ),
          isA<ValidationFailure>(),
          reason: code,
        );
      }
    });

    test('a malformed request is a validation failure', () {
      expect(
        mapSupabaseError(
          const AuthException(
            'Invalid email',
            statusCode: '422',
            code: 'validation_failed',
          ),
        ),
        isA<ValidationFailure>(),
      );
    });

    test('a genuinely expired session is still unauthorized', () {
      // The case the old ordering was reaching for, and the only one that
      // should produce "sign in again".
      expect(
        mapSupabaseError(
          const AuthException(
            'JWT expired',
            statusCode: '401',
            code: 'session_expired',
          ),
        ),
        isA<UnauthorizedFailure>(),
      );
    });
  });

  group('without a code, the status still decides', () {
    test('401 and 403 remain unauthorized', () {
      // `AuthException.code` is null for errors raised before a response
      // arrives, so the status has to keep working.
      for (final status in const ['401', '403']) {
        expect(
          mapSupabaseError(AuthException('Denied', statusCode: status)),
          isA<UnauthorizedFailure>(),
          reason: status,
        );
      }
    });

    test('422 remains a validation failure', () {
      expect(
        mapSupabaseError(const AuthException('Bad input', statusCode: '422')),
        isA<ValidationFailure>(),
      );
    });

    test('anything else is a server failure', () {
      expect(
        mapSupabaseError(const AuthException('Boom', statusCode: '500')),
        isA<ServerFailure>(),
      );
    });

    test('the old text heuristic still catches what it used to', () {
      // Kept as a last resort when reading codes replaced it, so a coded-less
      // error that used to be a ValidationFailure did not silently become a
      // ServerFailure. It sits behind the switch, where it can no longer
      // swallow an authorisation error.
      expect(
        mapSupabaseError(
          const AuthException('Invalid token supplied', statusCode: '400'),
        ),
        isA<ValidationFailure>(),
      );
    });
  });

  group('the Postgrest mapping is unchanged', () {
    // Verified live against the running stack: an anonymous read of
    // `order_number_sequences` — RLS on, no policy — answers 42501.
    test('42501 and PGRST301 are authorisation, not connectivity', () {
      for (final code in const ['42501', 'PGRST301']) {
        expect(
          mapSupabaseError(PostgrestException(message: 'denied', code: code)),
          isA<UnauthorizedFailure>(),
          reason: code,
        );
      }
    });

    test('PGRST116 is not found', () {
      expect(
        mapSupabaseError(
          const PostgrestException(message: 'no rows', code: 'PGRST116'),
        ),
        isA<NotFoundFailure>(),
      );
    });

    test('P0001 and 23514 are validation — place_order raises P0001', () {
      for (final code in const ['P0001', '23514']) {
        expect(
          mapSupabaseError(PostgrestException(message: 'refused', code: code)),
          isA<ValidationFailure>(),
          reason: code,
        );
      }
    });

    test('anything else from Postgrest is a server failure', () {
      expect(
        mapSupabaseError(
          const PostgrestException(message: 'boom', code: '42P01'),
        ),
        isA<ServerFailure>(),
      );
    });
  });

  group('transport and the catch-all', () {
    test('a socket or timeout error is a network failure', () {
      expect(
        mapSupabaseError(const SocketException('no route')),
        isA<NetworkFailure>(),
      );
      expect(mapSupabaseError(TimeoutException('slow')), isA<NetworkFailure>());
    });

    test('an unrecognised object is unknown, never swallowed', () {
      expect(mapSupabaseError(StateError('odd')), isA<UnknownFailure>());
    });
  });
}
