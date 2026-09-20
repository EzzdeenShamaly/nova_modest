import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nova_modest/core/widgets/avatar_circle.dart';

import '../../helpers/pump_app.dart';

/// The picture, and — more often — what stands in for it.
///
/// The fallback is the part that has to be right: a signed link lives an hour,
/// the shopper may never set a picture at all, and neither case may show a
/// broken-image glyph where her face would be.
void main() {
  testWidgets('shows the first letter of the name when there is no picture', (
    tester,
  ) async {
    await tester.pumpApp(
      const AvatarCircle(imageUrl: null, displayName: 'سارة أحمد'),
    );

    expect(find.text('س'), findsOneWidget);
    expect(find.byType(Image), findsNothing);
  });

  testWidgets('takes the first letter by code point, not by index', (
    tester,
  ) async {
    // An emoji is two UTF-16 code units. Slicing at index 1 would render half a
    // surrogate pair — the replacement glyph, in place of a name.
    await tester.pumpApp(
      const AvatarCircle(imageUrl: null, displayName: '😀 سارة'),
    );

    expect(find.text('😀'), findsOneWidget);
  });

  testWidgets('an empty name renders nothing rather than throwing', (
    tester,
  ) async {
    await tester.pumpApp(const AvatarCircle(imageUrl: null, displayName: '  '));

    expect(tester.takeException(), isNull);
  });

  testWidgets('falls back to the letter when the link cannot be loaded', (
    tester,
  ) async {
    // In a test every network image fails, which is precisely the expired-link
    // case: the letter must still be there.
    await tester.pumpApp(
      const AvatarCircle(
        imageUrl: 'https://example.invalid/avatar',
        displayName: 'سارة',
      ),
    );
    await tester.pump();

    expect(find.text('س'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  group('as a control', () {
    testWidgets('is not a button when no handler is given', (tester) async {
      await tester.pumpApp(
        const AvatarCircle(imageUrl: null, displayName: 'سارة'),
      );

      expect(find.byType(InkWell), findsNothing);
      // The account header draws it beside the name; announcing "س" as well
      // would read the shopper her own initial for no reason.
      final handle = tester.ensureSemantics();
      expect(find.bySemanticsLabel('تغيير صورتك'), findsNothing);
      expect(find.text('س'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('taps through to the handler', (tester) async {
      var taps = 0;
      await tester.pumpApp(
        AvatarCircle(imageUrl: null, displayName: 'سارة', onTap: () => taps++),
      );

      await tester.tap(find.byType(InkWell));
      expect(taps, 1);
    });

    testWidgets('shows progress and refuses a second tap while uploading', (
      tester,
    ) async {
      var taps = 0;
      await tester.pumpApp(
        AvatarCircle(
          imageUrl: null,
          displayName: 'سارة',
          busy: true,
          onTap: () => taps++,
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.tap(find.byType(InkWell));
      // The bloc drops a second event anyway; the control not accepting the tap
      // is what stops it looking unresponsive rather than ignored.
      expect(taps, 0);
    });

    testWidgets('carries a name a screen reader can announce', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpApp(
        AvatarCircle(imageUrl: null, displayName: 'سارة', onTap: () {}),
      );

      // "تغيير صورتك" — without it the control is an unlabelled circle.
      expect(find.bySemanticsLabel('تغيير صورتك'), findsOneWidget);
      handle.dispose();
    });
  });
}
