import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nova_modest/core/widgets/avatar_circle.dart';

import '../../helpers/pump_app.dart';
import '../../helpers/slow_network_image.dart';

/// **There are two ways a picture can be absent, and only one of them was
/// tested.**
///
/// `avatar_circle_test.dart` covers the first: a link that fails. In
/// `flutter_test` every network image fails at once, so that test lands in
/// `errorBuilder` and duly finds the letter.
///
/// This file covers the second: a link that has not arrived **yet**. Reaching
/// it needs a provider that is *slow* rather than *broken* — and with the
/// original `loadingBuilder` the circle was empty for that whole window, on a
/// real device for as long as the download took (measured on the emulator,
/// 2026-09-21).
///
/// Every network image added to this app from here on gets both.
void main() {
  testWidgets('the letter stands in while the picture is still downloading', (
    tester,
  ) async {
    await withSlowNetworkImages(() async {
      await tester.pumpApp(
        const AvatarCircle(
          imageUrl: 'https://example.invalid/avatars/u1/avatar',
          displayName: 'سارة',
        ),
      );
      // One frame, with the request open and not a byte delivered.
      await tester.pump();

      // The regression this file exists for: `loadingBuilder` is handed a null
      // progress until the first chunk arrives, and reading that null as
      // "loaded" hands back a RawImage holding no image — a blank disc where
      // her initial should be.
      expect(find.text('س'), findsOneWidget);
    });
  });

  testWidgets('and steps aside the moment there is a frame to paint', (
    tester,
  ) async {
    await withSlowNetworkImages(() async {
      await tester.pumpApp(
        const AvatarCircle(
          imageUrl: 'https://example.invalid/avatars/u1/avatar',
          displayName: 'سارة',
        ),
      );
      await tester.pump();

      // **The other half of the branch, pinned at the builder.** Driving a
      // real decode to completion was tried and does not work here: the codec
      // is an engine call, and a load started under the fake clock posts its
      // continuation to a zone that never runs, so the image hangs instead of
      // arriving. The end-to-end evidence is the emulator run of 2026-09-21,
      // where the uploaded photograph replaced the letter — in the form, in
      // the account header, and again after a cold start.
      final image = tester.widget<Image>(find.byType(Image));
      final context = tester.element(find.byType(Image));
      const decoded = SizedBox(key: Key('a-decoded-frame'));

      expect(
        image.frameBuilder!(context, decoded, 0, false),
        same(decoded),
        reason: 'a frame exists, so the picture is what gets painted',
      );
      expect(
        image.frameBuilder!(context, decoded, null, false),
        isNot(same(decoded)),
        reason: 'no frame yet, so the letter holds the place',
      );
    });
  });
}
