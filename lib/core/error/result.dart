import 'package:nova_modest/core/error/failure.dart';

/// The value-or-failure type repositories return (`06-flutter-error-guard.md`
/// §2), resolved with [ResultX.fold] in a Bloc handler.
///
/// Twenty lines of Dart 3 sealed classes give the same exhaustiveness as
/// `dartz` or `fpdart` with no dependency to keep current — adding either
/// package needs an explicit request (`10-evidence-and-dependency-guard.md`).
sealed class Result<T> {
  const Result();
}

final class Ok<T> extends Result<T> {
  const Ok(this.value);

  final T value;
}

final class Err<T> extends Result<T> {
  const Err(this.failure);

  final Failure failure;
}

extension ResultX<T> on Result<T> {
  /// Collapses both branches into one value. `onErr` comes first so the
  /// failure path is impossible to forget at a call site.
  R fold<R>(R Function(Failure failure) onErr, R Function(T value) onOk) =>
      switch (this) {
        Ok(:final value) => onOk(value),
        Err(:final failure) => onErr(failure),
      };
}
