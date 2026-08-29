import 'package:flutter_test/flutter_test.dart';
import 'package:nova_modest/core/error/failure.dart';
import 'package:nova_modest/features/auth/domain/entities/user.dart';
import 'package:nova_modest/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:nova_modest/features/onboarding/presentation/bloc/onboarding_bloc.dart';
import 'package:nova_modest/router/app_router.dart';
import 'package:nova_modest/router/routes.dart';

/// Enumerates the routing decision directly.
///
/// The splash screen was skipped on a real device because the guard treated the
/// startup check as a decided state. Thirteen widget-level router tests missed
/// it: pinning a bloc to one fixed state cannot express `AuthInitial ->
/// AuthCheckInProgress -> resolved`. Against a pure function the whole matrix is
/// reachable, so a wrong "undecided" set fails here immediately.
void main() {
  const user = User(id: 'u1', email: 'a@b.com', displayName: 'Sara');

  String? redirect({
    required AuthState auth,
    required OnboardingState onboarding,
    String location = Routes.splashPath,
    String? query,
  }) => resolveRedirect(
    auth: auth,
    onboarding: onboarding,
    location: location,
    uri: Uri.parse(query == null ? location : '$location?$query'),
  );

  /// Every auth state, labelled by whether startup has decided who the user is.
  const undecided = <String, AuthState>{
    'AuthInitial': AuthInitial(),
    'AuthCheckInProgress': AuthCheckInProgress(),
  };
  const decided = <String, AuthState>{
    'AuthLoading': AuthLoading(),
    'AuthUnauthenticated': AuthUnauthenticated(),
    'AuthAuthenticated': AuthAuthenticated(user),
    'AuthFailureState': AuthFailureState(NetworkFailure()),
  };

  group('startup is undecided', () {
    for (final entry in undecided.entries) {
      test('${entry.key} holds the splash, whatever onboarding says', () {
        for (final onboarding in const <OnboardingState>[
          OnboardingInitial(),
          OnboardingRequired(),
          OnboardingNotRequired(),
          OnboardingFailureState(CacheFailure()),
        ]) {
          expect(
            redirect(auth: entry.value, onboarding: onboarding),
            isNull,
            reason: '${entry.key} + $onboarding left the splash',
          );
          expect(
            redirect(
              auth: entry.value,
              onboarding: onboarding,
              location: Routes.homePath,
            ),
            Routes.splashPath,
            reason: '${entry.key} + $onboarding did not return to the splash',
          );
        }
      });
    }

    test('an undecided onboarding holds the splash for every auth state', () {
      for (final auth in {...undecided, ...decided}.entries) {
        expect(
          redirect(auth: auth.value, onboarding: const OnboardingInitial()),
          isNull,
          reason: '${auth.key} left the splash before onboarding resolved',
        );
      }
    });
  });

  group('startup has decided', () {
    test(
      'AuthLoading is NOT undecided — a submit must not reach the splash',
      () {
        // The other half of the original bug. Treating every wait as undecided
        // throws the user off the login form mid-submit.
        expect(
          redirect(
            auth: const AuthLoading(),
            onboarding: const OnboardingNotRequired(),
            location: Routes.loginPath,
          ),
          isNull,
        );
      },
    );

    for (final entry in decided.entries) {
      test('${entry.key} leaves the splash once onboarding has resolved', () {
        expect(
          redirect(
            auth: entry.value,
            onboarding: const OnboardingNotRequired(),
          ),
          isNotNull,
          reason: '${entry.key} was stuck on the splash',
        );
      });
    }
  });

  group('onboarding gate', () {
    test('a first launch takes over, for signed-in users too', () {
      for (final auth in decided.values) {
        expect(
          redirect(auth: auth, onboarding: const OnboardingRequired()),
          Routes.onboardingPath,
        );
      }
    });

    test('it holds once there', () {
      expect(
        redirect(
          auth: const AuthUnauthenticated(),
          onboarding: const OnboardingRequired(),
          location: Routes.onboardingPath,
        ),
        isNull,
      );
    });

    test('a resolved onboarding makes its own route a dead end', () {
      expect(
        redirect(
          auth: const AuthUnauthenticated(),
          onboarding: const OnboardingNotRequired(),
          location: Routes.onboardingPath,
        ),
        Routes.homePath,
      );
    });

    test('a failed flag read lets the user in rather than replaying it', () {
      expect(
        redirect(
          auth: const AuthUnauthenticated(),
          onboarding: const OnboardingFailureState(CacheFailure()),
        ),
        Routes.homePath,
      );
    });
  });

  group('public browsing and the sign-in gate', () {
    test('a guest reaches Home', () {
      expect(
        redirect(
          auth: const AuthUnauthenticated(),
          onboarding: const OnboardingNotRequired(),
        ),
        Routes.homePath,
      );
    });

    test('a guest is stopped at a protected area, carrying the path', () {
      expect(
        redirect(
          auth: const AuthUnauthenticated(),
          onboarding: const OnboardingNotRequired(),
          location: '/orders/42',
        ),
        '${Routes.loginPath}?${Routes.fromQueryParam}=%2Forders%2F42',
      );
    });

    test('a signed-in user passes the gate untouched', () {
      expect(
        redirect(
          auth: const AuthAuthenticated(user),
          onboarding: const OnboardingNotRequired(),
          location: '/orders/42',
        ),
        isNull,
      );
    });

    test('sign-in returns to where the gate interrupted', () {
      expect(
        redirect(
          auth: const AuthAuthenticated(user),
          onboarding: const OnboardingNotRequired(),
          location: Routes.loginPath,
          query: '${Routes.fromQueryParam}=%2Forders',
        ),
        '/orders',
      );
    });

    test('sign-in with no pending destination goes Home', () {
      expect(
        redirect(
          auth: const AuthAuthenticated(user),
          onboarding: const OnboardingNotRequired(),
          location: Routes.loginPath,
        ),
        Routes.homePath,
      );
    });

    test('a guest may sit on the login screen', () {
      expect(
        redirect(
          auth: const AuthUnauthenticated(),
          onboarding: const OnboardingNotRequired(),
          location: Routes.loginPath,
        ),
        isNull,
      );
    });
  });
}
