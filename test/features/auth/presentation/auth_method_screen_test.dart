import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nova_modest/core/di/injection.dart';
import 'package:nova_modest/core/error/failure.dart';
import 'package:nova_modest/core/widgets/failure_view.dart';
import 'package:nova_modest/features/auth/presentation/bloc/sign_in_bloc.dart';
import 'package:nova_modest/features/auth/presentation/screens/auth_method_screen.dart';

import '../../../helpers/pump_app.dart';

class _MockSignInBloc extends MockBloc<SignInEvent, SignInState>
    implements SignInBloc {}

void main() {
  late _MockSignInBloc bloc;

  setUpAll(() {
    registerFallbackValue(const SignInGoogleRequested());
    registerFallbackValue(const SignInDismissed());
    return loadAppFonts();
  });

  setUp(() {
    bloc = _MockSignInBloc();
    // The screen resolves its own bloc from the container, so the test swaps the
    // registration rather than the widget.
    if (sl.isRegistered<SignInBloc>()) sl.unregister<SignInBloc>();
    sl.registerFactory<SignInBloc>(() => bloc);
  });

  tearDown(() => sl.unregister<SignInBloc>());

  void withState(SignInState state) =>
      whenListen(bloc, Stream<SignInState>.value(state), initialState: state);

  /// [settle] is off for states that show a spinner: a
  /// `CircularProgressIndicator` animates forever, so `pumpAndSettle` never
  /// returns and the test dies on a timeout rather than an assertion.
  Future<void> pump(
    WidgetTester tester, {
    Locale? locale,
    bool settle = true,
  }) async {
    await tester.pumpApp(
      const AuthMethodScreen(),
      locale: locale ?? const Locale('ar'),
    );
    if (settle) {
      await tester.pumpAndSettle();
    } else {
      await tester.pump();
    }
  }

  testWidgets('offers the emailed code and nothing else', (tester) async {
    withState(const SignInIdle());

    await pump(tester);

    expect(find.text('متابعة بالبريد الإلكتروني'), findsOneWidget);
    // One field only: the address. A password field or a reset link reappearing
    // here would contradict the whole flow.
    expect(find.byType(TextFormField), findsOneWidget);
    expect(find.text('كلمة المرور'), findsNothing);
    expect(find.text('نسيت كلمة المرور؟'), findsNothing);
  });

  testWidgets('the Google button is gone, not merely disabled', (tester) async {
    withState(const SignInIdle());

    await pump(tester);

    // It could not work in any build this repo produces — no
    // `GOOGLE_WEB_CLIENT_ID`, no native setup, no provider — and a control that
    // looks live and ends in a technical error is worse than an absent one.
    // Pinned as an absence so it cannot drift back in unnoticed, exactly as the
    // support screen pins the missing phone row.
    expect(find.textContaining('Google'), findsNothing);
    expect(find.byType(OutlinedButton), findsNothing);
    expect(find.text('أو'), findsNothing);
  });

  testWidgets('retrying after a failure returns the form, not a repeat', (
    tester,
  ) async {
    withState(const SignInFailureState(NetworkFailure()));

    await pump(tester);
    await tester.tap(find.text('إعادة المحاولة'));
    await tester.pump();

    verify(() => bloc.add(const SignInDismissed())).called(1);
    verifyNever(() => bloc.add(const SignInGoogleRequested()));
  });

  testWidgets('an empty address is rejected before anything is dispatched', (
    tester,
  ) async {
    withState(const SignInIdle());

    await pump(tester);
    await tester.tap(find.text('متابعة بالبريد الإلكتروني'));
    await tester.pumpAndSettle();

    expect(find.text('البريد الإلكتروني مطلوب'), findsOneWidget);
    verifyNever(() => bloc.add(any()));
  });

  testWidgets('a valid address requests a code, trimmed', (tester) async {
    withState(const SignInIdle());

    await pump(tester);
    await tester.enterText(find.byType(TextFormField), '  sara@example.com  ');
    await tester.tap(find.text('متابعة بالبريد الإلكتروني'));
    await tester.pump();

    verify(
      () => bloc.add(const SignInEmailSubmitted('sara@example.com')),
    ).called(1);
  });

  testWidgets('every action is disabled while a request is in flight', (
    tester,
  ) async {
    withState(const SignInSubmitting());

    await pump(tester, settle: false);

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
    // The guest link too: it was the Google button that used to be asserted
    // here, and "every action" has to keep meaning every action after a
    // control is removed.
    expect(
      tester.widget<TextButton>(find.byType(TextButton)).onPressed,
      isNull,
    );
  });

  testWidgets('a failure shows the shared error view with a retry', (
    tester,
  ) async {
    withState(const SignInFailureState(NetworkFailure()));

    await pump(tester);

    expect(find.byType(FailureView), findsOneWidget);
  });

  group('direction and locale', () {
    testWidgets('renders without overflow in ar and en', (tester) async {
      withState(const SignInIdle());
      for (final locale in const [Locale('ar'), Locale('en')]) {
        await pump(tester, locale: locale);
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('the copy follows the locale', (tester) async {
      withState(const SignInIdle());

      await pump(tester, locale: const Locale('en'));

      expect(find.text('Continue with email'), findsOneWidget);
      expect(find.text('Continue as a guest'), findsOneWidget);
    });
  });
}
