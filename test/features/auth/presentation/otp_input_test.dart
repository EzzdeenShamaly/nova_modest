import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nova_modest/features/auth/presentation/widgets/otp_input.dart';

import '../../../helpers/pump_app.dart';

/// Geometry, not intent.
///
/// The screen test that already covered this control asserted the assembled
/// code after `find.byType(TextField).at(i)` — and that finder returns widgets
/// in **tree** order, which is index order whatever the layout does. It passed
/// while the row rendered mirrored, so a shopper reading a code left to right
/// typed it into the wrong boxes and sign-in failed with a valid code.
///
/// These tests measure `dx`. That is the only thing that could have caught it.
void main() {
  setUpAll(loadAppFonts);

  Future<String> pumpOtp(WidgetTester tester, {required Locale locale}) async {
    var code = '';
    await tester.pumpApp(
      Scaffold(
        body: OtpInput(onChanged: (value) => code = value, onCompleted: (_) {}),
      ),
      locale: locale,
    );
    await tester.pumpAndSettle();
    return code;
  }

  /// The horizontal position of each box, by its index in the widget tree.
  List<double> boxLefts(WidgetTester tester) => [
    for (var i = 0; i < 6; i++)
      tester.getTopLeft(find.byType(TextField).at(i)).dx,
  ];

  /// Types [code] the way the control moves focus: one digit per box, in index
  /// order, which is what a shopper's finger follows.
  Future<void> typeInFocusOrder(WidgetTester tester, String code) async {
    for (var i = 0; i < code.length; i++) {
      await tester.enterText(find.byType(TextField).at(i), code[i]);
      await tester.pump();
    }
  }

  group('the boxes read left to right', () {
    testWidgets('under Arabic, where the rest of the UI mirrors', (
      tester,
    ) async {
      await pumpOtp(tester, locale: const Locale('ar'));

      final lefts = boxLefts(tester);
      // Index 0 leftmost, index 5 rightmost — the opposite of what an
      // unpinned Row does under RTL, and the whole defect.
      expect(
        lefts,
        orderedEquals(List<double>.from(lefts)..sort()),
        reason: 'boxes must ascend left to right, not mirror',
      );
      expect(lefts.first, lessThan(lefts.last));
    });

    testWidgets('under English, unchanged', (tester) async {
      await pumpOtp(tester, locale: const Locale('en'));

      final lefts = boxLefts(tester);
      expect(lefts, orderedEquals(List<double>.from(lefts)..sort()));
    });

    testWidgets('the ambient direction is still the app locale', (
      tester,
    ) async {
      // The control pins its own row; it does not reach up and change the page.
      await pumpOtp(tester, locale: const Locale('ar'));

      expect(
        Directionality.of(tester.element(find.byType(OtpInput))),
        TextDirection.rtl,
      );
    });
  });

  group('what is typed is what is read back', () {
    testWidgets('the first digit lands in the leftmost box, in Arabic', (
      tester,
    ) async {
      await pumpOtp(tester, locale: const Locale('ar'));
      await typeInFocusOrder(tester, '338329');

      final lefts = boxLefts(tester);
      final leftmost = lefts.indexOf(lefts.reduce((a, b) => a < b ? a : b));
      final rightmost = lefts.indexOf(lefts.reduce((a, b) => a > b ? a : b));

      // A shopper reading "338329" off an email and typing it in order must
      // see "338329" on screen, not "923833".
      expect(
        tester
            .widget<TextField>(find.byType(TextField).at(leftmost))
            .controller
            ?.text,
        '3',
      );
      expect(
        tester
            .widget<TextField>(find.byType(TextField).at(rightmost))
            .controller
            ?.text,
        '9',
      );
    });

    testWidgets('and the assembled code is the one typed', (tester) async {
      var reported = '';
      await tester.pumpApp(
        Scaffold(
          body: OtpInput(
            onChanged: (value) => reported = value,
            onCompleted: (_) {},
          ),
        ),
        locale: const Locale('ar'),
      );
      await tester.pumpAndSettle();
      await typeInFocusOrder(tester, '338329');

      expect(reported, '338329');
    });
  });

  group('pasting', () {
    testWidgets('fills every box in reading order', (tester) async {
      await pumpOtp(tester, locale: const Locale('ar'));

      await tester.enterText(find.byType(TextField).first, '987654');
      await tester.pumpAndSettle();

      final lefts = boxLefts(tester);
      final leftmost = lefts.indexOf(lefts.reduce((a, b) => a < b ? a : b));

      expect(
        tester
            .widget<TextField>(find.byType(TextField).at(leftmost))
            .controller
            ?.text,
        '9',
      );
    });
  });
}
