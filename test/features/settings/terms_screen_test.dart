import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nova_modest/features/settings/presentation/screens/terms_screen.dart';

import '../../helpers/pump_app.dart';

/// The terms, in place since 2026-09-21.
///
/// What is asserted here is **not the wording** — that would break on every
/// edit the owner makes to his own document. It is the handful of clauses that
/// must agree with what the code does, because those are the ones that turn
/// into a false promise the moment either side moves: the fees, what
/// "confirmed" means, that there is no cancel button, and that ordering needs
/// an account.
void main() {
  setUpAll(loadAppFonts);

  Future<void> pump(WidgetTester tester, {Locale? locale}) async {
    await tester.pumpApp(
      TermsScreen(key: UniqueKey()),
      locale: locale ?? const Locale('ar'),
    );
    await tester.pumpAndSettle();
  }

  /// The whole document as one string, as the screen renders it.
  String body(WidgetTester tester) => tester
      .widgetList<Text>(find.byType(Text))
      .map((t) => t.data ?? '')
      .join('\n');

  testWidgets('shows the terms themselves, not a note about their absence', (
    tester,
  ) async {
    await pump(tester);

    expect(find.text('الشروط والأحكام'), findsOneWidget);
    expect(find.textContaining('قيد الإعداد'), findsNothing);
    expect(find.textContaining('سيتم إضافة'), findsNothing);
  });

  testWidgets('the numbers in it are the numbers the app charges', (
    tester,
  ) async {
    await pump(tester);
    final text = body(tester);

    // `ShippingMethod.standard.cost` and `PaymentMethod.cashOnDelivery.fee`.
    // If either moves and this file does not, the shop is quoting a price it
    // does not charge.
    expect(text, contains('٣٥ ر.س'));
    expect(text, contains('١٥ ر.س'));
    // CartItem.maxLines and CartItem.maxQuantity, spelled out.
    expect(text, contains('عشرين صنفاً'));
    expect(text, contains('عشر قطعٍ'));
  });

  testWidgets('it promises nothing the app cannot do', (tester) async {
    await pump(tester);
    final text = body(tester);

    // No cancel action exists in the storefront — `OrderStatus.cancelled` is a
    // status the backend writes, and the screen has no control for it.
    expect(text, contains('لا يوجد زرّ إلغاءٍ داخل التطبيق'));
    // "Confirmed" is acceptance, not payment: the correction the owner made on
    // 2026-09-20, now stated to the shopper.
    expect(text, contains('ولا تعني أن المبلغ قد وصل'));
    // Guest checkout was closed in 02ddde7.
    expect(text, contains('لا يوجد شراءٌ كزائرة'));
    // Notifications are stored and sent by nothing.
    expect(text, contains('لا يرسل إشعاراتٍ بعد'));
  });

  testWidgets('it does not offer Google sign-in, which does not work', (
    tester,
  ) async {
    await pump(tester);

    expect(find.textContaining('Google'), findsNothing);
  });

  group('direction and locale', () {
    testWidgets('renders without overflow in ar and en', (tester) async {
      for (final locale in const [Locale('ar'), Locale('en')]) {
        await pump(tester, locale: locale);
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('the document follows the locale', (tester) async {
      await pump(tester, locale: const Locale('en'));
      final text = body(tester);

      expect(find.text('Terms & conditions'), findsOneWidget);
      expect(text, contains('Cash on delivery only'));
      expect(text, contains('SAR 35'));
      expect(text, contains('Kingdom of Saudi Arabia'));
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
