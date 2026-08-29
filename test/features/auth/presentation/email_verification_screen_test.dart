import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nova_modest/core/di/injection.dart';
import 'package:nova_modest/features/auth/presentation/bloc/sign_in_bloc.dart';
import 'package:nova_modest/features/auth/presentation/screens/email_verification_screen.dart';
import 'package:nova_modest/features/auth/presentation/widgets/otp_input.dart';

import '../../../helpers/pump_app.dart';

class _MockSignInBloc extends MockBloc<SignInEvent, SignInState>
    implements SignInBloc {}

void main() {
  late _MockSignInBloc bloc;

  const email = 'sara@example.com';

  setUpAll(() {
    registerFallbackValue(const SignInCodeResendRequested(email));
    return loadAppFonts();
  });

  setUp(() {
    bloc = _MockSignInBloc();
    whenListen(
      bloc,
      Stream<SignInState>.value(const SignInIdle()),
      initialState: const SignInIdle(),
    );
    if (sl.isRegistered<SignInBloc>()) sl.unregister<SignInBloc>();
    sl.registerFactory<SignInBloc>(() => bloc);
  });

  tearDown(() => sl.unregister<SignInBloc>());

  /// Never `pumpAndSettle` here: the resend countdown is a periodic timer that
  /// schedules a frame every second, so settling never happens.
  Future<void> pump(WidgetTester tester, {Locale? locale}) async {
    await tester.pumpApp(
      const EmailVerificationScreen(email: email),
      locale: locale ?? const Locale('ar'),
    );
    await tester.pump();
  }

  Future<void> enterCode(WidgetTester tester, String code) async {
    final boxes = find.byType(TextField);
    for (var i = 0; i < code.length; i++) {
      await tester.enterText(boxes.at(i), code[i]);
      await tester.pump();
    }
  }

  testWidgets('shows six boxes and names the address the code went to', (
    tester,
  ) async {
    await pump(tester);

    expect(find.byType(OtpInput), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(6));
    expect(find.textContaining(email), findsOneWidget);
  });

  testWidgets('a complete code submits without needing the button', (
    tester,
  ) async {
    await pump(tester);
    await enterCode(tester, '123456');

    verify(
      () => bloc.add(const SignInCodeSubmitted(email: email, code: '123456')),
    ).called(1);
  });

  testWidgets('an incomplete code is refused and nothing is dispatched', (
    tester,
  ) async {
    await pump(tester);
    await enterCode(tester, '123');

    await tester.tap(find.byType(FilledButton));
    await tester.pump();

    expect(find.text('أدخلي الرمز المكون من 6 أرقام'), findsOneWidget);
    verifyNever(() => bloc.add(any()));
  });

  testWidgets('typing advances through the boxes', (tester) async {
    await pump(tester);
    await enterCode(tester, '12');

    final fields = tester.widgetList<TextField>(find.byType(TextField));
    expect(fields.elementAt(0).controller?.text, '1');
    expect(fields.elementAt(1).controller?.text, '2');
    expect(fields.elementAt(2).controller?.text, isEmpty);
  });

  testWidgets('pasting a whole code fills every box', (tester) async {
    await pump(tester);
    // A paste lands entirely in the focused box; all six digits must survive.
    await tester.enterText(find.byType(TextField).first, '987654');
    await tester.pump();

    final fields = tester
        .widgetList<TextField>(find.byType(TextField))
        .map((f) => f.controller?.text)
        .toList();
    expect(fields, ['9', '8', '7', '6', '5', '4']);
  });

  group('resend', () {
    testWidgets('is locked behind the countdown', (tester) async {
      await pump(tester);

      expect(find.text('0:45'), findsOneWidget);
      final resend = tester.widget<TextButton>(find.byType(TextButton));
      expect(resend.onPressed, isNull);
    });

    testWidgets('unlocks once the window elapses', (tester) async {
      await pump(tester);
      await tester.pump(const Duration(seconds: 46));

      expect(find.text('0:45'), findsNothing);
      final resend = tester.widget<TextButton>(find.byType(TextButton));
      expect(resend.onPressed, isNotNull);

      await tester.tap(find.byType(TextButton));
      await tester.pump();
      verify(() => bloc.add(const SignInCodeResendRequested(email))).called(1);
    });
  });

  group('direction and locale', () {
    testWidgets('renders without overflow in ar and en', (tester) async {
      for (final locale in const [Locale('ar'), Locale('en')]) {
        await pump(tester, locale: locale);
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('lays out RTL under Arabic', (tester) async {
      await pump(tester);

      expect(
        Directionality.of(tester.element(find.byType(OtpInput))),
        TextDirection.rtl,
      );
    });
  });
}
