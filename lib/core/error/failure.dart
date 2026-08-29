import 'package:equatable/equatable.dart';

/// The single, app-wide failure hierarchy (`06-flutter-error-guard.md` §1).
///
/// Sealed, so a `switch` over it is exhaustive and adding a case forces every
/// handler to be updated at compile time. There is deliberately no
/// per-feature or per-repository subclass: `OrderNotFoundFailure` and
/// `ProductNotFoundFailure` both render "not found", so they are one
/// [NotFoundFailure].
///
/// Extends [Equatable] so states carrying a `Failure` compare by value. Without
/// it, a `bloc_test` `expect` list comparing `AuthFailure(ServerFailure(...))`
/// would only pass for `const`-canonicalised instances, and the runtime-built
/// failures the network mapper produces would fail every assertion.
///
/// [message] is a **developer-facing fallback**, not the string shown to the
/// user. The UI switches on the failure's type and reads a localized string
/// (`11-flutter-l10n-guard`); see `core/widgets/failure_view.dart`. Never
/// surface a raw server message — it leaks implementation detail and is
/// unlocalized.
sealed class Failure extends Equatable {
  const Failure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

/// No connectivity, or a timeout.
final class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'No internet connection.']);
}

/// A 5xx response.
final class ServerFailure extends Failure {
  const ServerFailure(super.message, {this.statusCode});

  final int? statusCode;

  @override
  List<Object?> get props => [message, statusCode];
}

/// A 404 response.
final class NotFoundFailure extends Failure {
  const NotFoundFailure([super.message = 'Not found.']);
}

/// A 401 or 403 response.
///
/// Usually **not** rendered inline: it belongs to the refresh-then-logout flow
/// in the auth interceptor, so the user lands on the login screen rather than
/// an error card (`06-flutter-error-guard.md` §5).
final class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure([super.message = 'Session expired.']);
}

/// A 422 response, optionally carrying per-field messages.
final class ValidationFailure extends Failure {
  const ValidationFailure(super.message, {this.fieldErrors = const {}});

  final Map<String, String> fieldErrors;

  @override
  List<Object?> get props => [message, fieldErrors];
}

/// Local data could not be read or written.
final class CacheFailure extends Failure {
  const CacheFailure([super.message = 'Local data unavailable.']);
}

/// Anything unclassified. Logged, never swallowed.
final class UnknownFailure extends Failure {
  const UnknownFailure([super.message = 'Something went wrong.']);
}
