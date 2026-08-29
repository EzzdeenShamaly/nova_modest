import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nova_modest/features/settings/presentation/screens/terms_screen.dart';

import '../../helpers/pump_app.dart';

void main() {
  setUpAll(loadAppFonts);

  Future<void> pump(WidgetTester tester, {Locale? locale}) async {
    await tester.pumpApp(
      TermsScreen(key: UniqueKey()),
      locale: locale ?? const Locale('ar'),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('says the terms are not here yet, rather than inventing them', (
    tester,
  ) async {
    await pump(tester);

    expect(find.text('الشروط والأحكام'), findsOneWidget);
    expect(
      find.text('سيتم إضافة الشروط والأحكام الكاملة هنا.'),
      findsOneWidget,
    );
    expect(find.textContaining('قيد الإعداد'), findsOneWidget);
  });

  testWidgets('carries no drafted clauses', (tester) async {
    // The point of the screen: an absent policy is stated, not approximated.
    // Anything that reads like a clause here would be a business promise
    // nobody made.
    await pump(tester);

    for (final clause in const ['يحق لنا', 'يوافق المستخدم', 'المادة']) {
      expect(
        find.textContaining(clause),
        findsNothing,
        reason: 'invented legal wording: $clause',
      );
    }
  });

  group('direction and locale', () {
    testWidgets('renders without overflow in ar and en', (tester) async {
      for (final locale in const [Locale('ar'), Locale('en')]) {
        await pump(tester, locale: locale);
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('the copy follows the locale', (tester) async {
      await pump(tester, locale: const Locale('en'));

      expect(find.text('Terms & conditions'), findsOneWidget);
      expect(
        find.text('The full terms and conditions will be added here.'),
        findsOneWidget,
      );
    });

    testWidgets('lays out RTL under Arabic', (tester) async {
      await pump(tester);

      expect(
        Directionality.of(tester.element(find.byType(TermsScreen))),
        TextDirection.rtl,
      );
    });
  });
}
