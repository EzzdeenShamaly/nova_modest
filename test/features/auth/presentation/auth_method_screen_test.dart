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

  testWidgets('offers exactly Google and email — no password anywhere', (
    tester,
  ) async {
    withState(const SignInIdle());

    await pump(tester);

    expect(find.text('المتابعة عبر Google'), findsOneWidget);
    expect(find.text('متابعة بالبريد الإلكتروني'), findsOneWidget);
    // One field only: the address. A password field or a reset link reappearing
    // here would contradict the whole flow.
    expect(find.byType(TextFormField), findsOneWidget);
    expect(find.text('كلمة المرور'), findsNothing);
    expect(find.text('نسيت كلمة المرور؟'), findsNothing);
  });

  testWidgets('the Google button dispatches the Google flow', (tester) async {
    withState(const SignInIdle());

    await pump(tester);
    await tester.tap(find.text('المتابعة عبر Google'));
    await tester.pump();

    verify(() => bloc.add(const SignInGoogleRequested())).called(1);
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
    expect(
      tester.widget<OutlinedButton>(find.byType(OutlinedButton)).onPressed,
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

      expect(find.text('Continue with Google'), findsOneWidget);
      expect(find.text('Continue as a guest'), findsOneWidget);
    });
  });
}
