import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nova_modest/features/settings/presentation/screens/help_screen.dart';

import '../../helpers/pump_app.dart';

void main() {
  /// What the platform clipboard was last handed.
  String? copied;

  setUpAll(loadAppFonts);

  setUp(() {
    copied = null;
    // Clipboard.setData crosses a platform channel, which does not exist in a
    // test. Intercepting it is also how the assertion is made.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'Clipboard.setData') {
            copied =
                (call.arguments as Map<Object?, Object?>)['text'] as String?;
          }
          return null;
        });
  });

  tearDown(
    () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null),
  );

  Future<void> pump(WidgetTester tester, {Locale? locale}) async {
    await tester.pumpApp(
      HelpScreen(key: UniqueKey()),
      locale: locale ?? const Locale('ar'),
    );
    await tester.pumpAndSettle();
  }

  group('the questions', () {
    testWidgets('both sections are drawn', (tester) async {
      await pump(tester);

      expect(find.text('الأسئلة الشائعة'), findsOneWidget);
      expect(find.text('تواصلي معنا'), findsOneWidget);
    });

    testWidgets('every question is listed, and only the questions', (
      tester,
    ) async {
      await pump(tester);

      expect(find.byType(ExpansionTile), findsNWidgets(4));
      // Answers stay collapsed until asked for.
      expect(
        find.textContaining('لا توجد كلمة مرور في التطبيق.'),
        findsNothing,
      );
    });

    testWidgets('a question opens and closes', (tester) async {
      await pump(tester);

      await tester.tap(find.text('كيف أسجّل الدخول؟'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('لا توجد كلمة مرور في التطبيق.'),
        findsOneWidget,
      );

      await tester.tap(find.text('كيف أسجّل الدخول؟'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('لا توجد كلمة مرور في التطبيق.'),
        findsNothing,
      );
    });

    testWidgets('the answers describe what the app actually does', (
      tester,
    ) async {
      // Every entry here is checkable against the code: the email really is
      // unchangeable, because `AuthRepository.updateProfile` has no field for
      // it. Nothing invents a shipping window or a returns policy.
      await pump(tester);

      await tester.tap(find.text('هل أستطيع تغيير بريدي الإلكتروني؟'));
      await tester.pumpAndSettle();

      expect(find.textContaining('لا يمكن تغييره من التطبيق'), findsOneWidget);
    });
  });

  group('contact', () {
    testWidgets('shows the support details', (tester) async {
      await pump(tester);

      expect(find.text('support@novamodest.com'), findsOneWidget);
      expect(find.text('+966 50 000 0000'), findsOneWidget);
    });

    testWidgets('tapping a row copies it and confirms', (tester) async {
      await pump(tester);

      await tester.tap(find.text('support@novamodest.com'));
      await tester.pumpAndSettle();

      expect(copied, 'support@novamodest.com');
      expect(find.text('تم النسخ'), findsOneWidget);
    });

    testWidgets('the phone row copies the number, not the email', (
      tester,
    ) async {
      await pump(tester);

      await tester.tap(find.text('+966 50 000 0000'));
      await tester.pumpAndSettle();

      expect(copied, '+966 50 000 0000');
    });
  });

  group('direction and locale', () {
    testWidgets('renders without overflow in ar and en', (tester) async {
      for (final locale in const [Locale('ar'), Locale('en')]) {
        await pump(tester, locale: locale);
        expect(find.byType(ExpansionTile), findsNWidgets(4));
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('the chrome follows the locale, the contact details do not', (
      tester,
    ) async {
      await pump(tester, locale: const Locale('en'));

      expect(find.text('Frequently asked questions'), findsOneWidget);
      expect(find.text('How do I sign in?'), findsOneWidget);
      // An address and a number are content, identical in every language.
      expect(find.text('support@novamodest.com'), findsOneWidget);
    });

    testWidgets('lays out RTL under Arabic', (tester) async {
      await pump(tester);

      expect(
        Directionality.of(tester.element(find.byType(ExpansionTile).first)),
        TextDirection.rtl,
      );
    });
  });
}
