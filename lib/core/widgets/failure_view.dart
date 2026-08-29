import 'package:flutter/material.dart';
import 'package:nova_modest/core/error/failure.dart';
import 'package:nova_modest/l10n/app_localizations.dart';

/// One error UI for the whole app — not a bespoke error widget per screen
/// (`06-flutter-error-guard.md` §5).
///
/// The `switch` is exhaustive over the sealed [Failure] hierarchy, so adding a
/// new failure type is a compile error here rather than a screen that silently
/// renders nothing.
///
/// Reads a localized string per failure **type** and never uses
/// `failure.message`: that field is a developer-facing fallback in English, and
/// this app's primary locale is Arabic.
class FailureView extends StatelessWidget {
  const FailureView({required this.failure, this.onRetry, super.key});

  final Failure failure;

  /// When null, no retry affordance is shown — appropriate for a failure the
  /// user cannot resolve by trying again.
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsetsDirectional.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _icon,
              size: 48,
              color: theme.colorScheme.error,
              // Decorative: the message below carries the meaning, so an
              // explicit empty label stops a screen reader announcing it twice.
              semanticLabel: '',
            ),
            const SizedBox(height: 16),
            Text(
              _message(l10n),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              FilledButton.tonal(onPressed: onRetry, child: Text(l10n.retry)),
            ],
          ],
        ),
      ),
    );
  }

  IconData get _icon => switch (failure) {
    NetworkFailure() => Icons.wifi_off_outlined,
    ServerFailure() => Icons.cloud_off_outlined,
    NotFoundFailure() => Icons.search_off_outlined,
    UnauthorizedFailure() => Icons.lock_outline,
    ValidationFailure() => Icons.error_outline,
    CacheFailure() => Icons.storage_outlined,
    UnknownFailure() => Icons.error_outline,
  };

  String _message(AppLocalizations l10n) => failureMessage(failure, l10n);
}

/// The localized message for a [Failure], by **type**.
///
/// Public because not every failure gets a full-screen view: a form that fails
/// to save reports it in a snack bar, and writing this `switch` twice is how two
/// surfaces end up disagreeing about what a `CacheFailure` says.
///
/// Never uses `failure.message` — that field is a developer-facing English
/// fallback (`06-flutter-error-guard.md` §1).
String failureMessage(Failure failure, AppLocalizations l10n) =>
    switch (failure) {
      NetworkFailure() => l10n.failureNetwork,
      ServerFailure() => l10n.failureServer,
      NotFoundFailure() => l10n.failureNotFound,
      UnauthorizedFailure() => l10n.failureUnauthorized,
      ValidationFailure() => l10n.failureValidation,
      CacheFailure() => l10n.failureCache,
      UnknownFailure() => l10n.failureUnknown,
    };
