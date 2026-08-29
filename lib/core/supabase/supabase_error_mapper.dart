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
    final code = error.statusCode;
    if (code == '401' || code == '403') {
      return UnauthorizedFailure(error.message);
    }
    if (code == '422' ||
        error.message.toLowerCase().contains('otp') ||
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
