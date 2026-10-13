import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nova_modest/core/widgets/product_thumbnail.dart';
import 'package:nova_modest/features/catalog/domain/entities/product.dart';
import 'package:nova_modest/features/catalog/presentation/widgets/product_card.dart';
import 'package:nova_modest/features/catalog/presentation/widgets/product_image_carousel.dart';

import '../../helpers/pump_app.dart';
import '../../helpers/slow_network_image.dart';

/// The catalogue is images, and all three of its call sites carried an
/// `errorBuilder` and nothing else — so a picture that had not arrived **yet**
/// drew nothing at all. `AvatarCircle` was given a `frameBuilder` for exactly
/// this on 2026-09-21; these three were missed.
///
/// It matters here for a second reason that has nothing to do with hanging: a
/// storefront whose cards are white rectangles is something a Play reviewer
/// rejects long before considering the network (owner, 2026-10-12).
void main() {
  setUpAll(loadAppFonts);

  /// The one frame after the request opens and before a byte arrives — the
  /// window the old code painted nothing in.
  Future<void> pumpFirstFrame(WidgetTester tester, Widget child) async {
    await tester.pumpApp(child);
    await tester.pump();
  }

  testWidgets('a card holds its artwork place until the picture arrives', (
    tester,
  ) async {
    await withSlowNetworkImages(() async {
      await pumpFirstFrame(
        tester,
        // Scaffold, because the card's own InkWell needs a Material ancestor
        // and this is the only test that renders a card on its own.
        const Scaffold(
          body: SizedBox(
            width: 200,
            height: 320,
            child: ProductCard(product: _withArtwork),
          ),
        ),
      );

      // The same stand-in a failed load gets: the shopper sees the card's
      // artwork block, not a hole in the grid.
      expect(find.byIcon(Icons.checkroom_outlined), findsOneWidget);
    });
  });

  testWidgets('a thumbnail holds its place too', (tester) async {
    await withSlowNetworkImages(() async {
      await pumpFirstFrame(
        tester,
        const ProductThumbnail(
          imageUrl: 'https://example.invalid/p1.jpg',
          width: 64,
          height: 64,
          iconSize: 24,
        ),
      );

      expect(find.byIcon(Icons.checkroom_outlined), findsOneWidget);
    });
  });

  testWidgets('and so does a carousel page', (tester) async {
    await withSlowNetworkImages(() async {
      await pumpFirstFrame(
        tester,
        const SizedBox(
          width: 360,
          height: 400,
          child: ProductImageCarousel(
            images: ['https://example.invalid/p1.jpg'],
          ),
        ),
      );

      expect(find.byIcon(Icons.checkroom_outlined), findsOneWidget);
    });
  });

  testWidgets('and each steps aside the moment there is a frame to paint', (
    tester,
  ) async {
    await withSlowNetworkImages(() async {
      await pumpFirstFrame(
        tester,
        // Scaffold, because the card's own InkWell needs a Material ancestor
        // and this is the only test that renders a card on its own.
        const Scaffold(
          body: SizedBox(
            width: 200,
            height: 320,
            child: ProductCard(product: _withArtwork),
          ),
        ),
      );

      // Pinned at the builder for the same reason `avatar_circle_loading_test`
      // is: a real decode started under the fake clock posts its continuation
      // to a zone that never runs, so the image would hang rather than arrive.
      final image = tester.widget<Image>(find.byType(Image));
      final context = tester.element(find.byType(Image));
      const decoded = SizedBox(key: Key('a-decoded-frame'));

      expect(image.frameBuilder!(context, decoded, 0, false), same(decoded));
      expect(
        image.frameBuilder!(context, decoded, null, false),
        isNot(same(decoded)),
      );
    });
  });
}

/// One product that has artwork — the only field these tests care about.
const _withArtwork = Product(
  id: 'p1',
  name: 'عباءة كلاسيكية',
  price: 450,
  categoryId: 'abayas',
  imageUrl: 'https://example.invalid/p1.jpg',
);
