import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nova_modest/core/theme/app_colors.dart';
import 'package:nova_modest/features/splash/presentation/screens/splash_screen.dart';

import '../../helpers/pump_app.dart';

void main() {
  // Real font metrics: the placeholder test font would make every string of a
  // given length measure the same, so the wrapping assertion below would be
  // testing nothing.
  setUpAll(loadAppFonts);

  Text textWidget(WidgetTester tester, String data) =>
      tester.widget<Text>(find.text(data));

  testWidgets('renders the wordmark and the Arabic tagline in ar', (
    tester,
  ) async {
    await tester.pumpApp(const SplashScreen());
    await tester.pumpAndSettle();

    expect(find.text('NOVA MODEST'), findsOneWidget);
    expect(find.text('احتشام عصري، يناسب كل يوم'), findsOneWidget);
  });

  testWidgets('the brandmark is never translated or transliterated', (
    tester,
  ) async {
    for (final locale in const [Locale('ar'), Locale('en')]) {
      await tester.pumpApp(const SplashScreen(), locale: locale);
      await tester.pumpAndSettle();

      // Same Latin mark in every locale, and never written in Arabic letters.
      expect(find.text('NOVA MODEST'), findsOneWidget);
      expect(find.text('نوفا مودست'), findsNothing);
    }
  });

  testWidgets('the tagline follows the active locale', (tester) async {
    await tester.pumpApp(const SplashScreen(), locale: const Locale('en'));
    await tester.pumpAndSettle();

    expect(find.text('Modern modesty, for every day'), findsOneWidget);
    expect(find.text('احتشام عصري، يناسب كل يوم'), findsNothing);
  });

  testWidgets('the wordmark is laid out LTR even under an RTL locale', (
    tester,
  ) async {
    await tester.pumpApp(const SplashScreen());
    await tester.pumpAndSettle();

    // The screen itself mirrors...
    expect(
      Directionality.of(tester.element(find.byType(SplashScreen))),
      TextDirection.rtl,
    );
    // ...but the brandmark's own glyph order does not.
    expect(textWidget(tester, 'NOVA MODEST').textDirection, TextDirection.ltr);
  });

  testWidgets('typography comes from the design system', (tester) async {
    await tester.pumpApp(const SplashScreen());
    await tester.pumpAndSettle();

    final wordmark = textWidget(tester, 'NOVA MODEST').style!;
    expect(wordmark.fontFamily, 'IBM Plex Sans Arabic');
    expect(wordmark.color, AppColors.primaryText);
    expect(wordmark.fontWeight, FontWeight.w600);
    // The design's 4.8 tracking at 24px.
    expect(wordmark.letterSpacing, 4.8);

    final tagline = textWidget(tester, 'احتشام عصري، يناسب كل يوم').style!;
    expect(tagline.fontFamily, 'IBM Plex Sans Arabic');
    // Weight 300 as designed, from the bundled Light face - not a second family.
    expect(tagline.fontWeight, FontWeight.w300);
  });

  testWidgets('the muted tagline colour is derived from the palette, not new', (
    tester,
  ) async {
    await tester.pumpApp(const SplashScreen());
    await tester.pumpAndSettle();

    final colour = textWidget(
      tester,
      'احتشام عصري، يناسب كل يوم',
    ).style!.color!;

    // Derived from primaryText rather than added as a sixth constant
    // (12-flutter-design-system-guard.md §3).
    expect(colour, AppColors.muted);
    expect(
      <Color>[colour],
      isNot(
        contains(
          isIn(<Color>[
            AppColors.secondary,
            AppColors.accent,
            AppColors.error,
            AppColors.background,
          ]),
        ),
      ),
    );
  });

  testWidgets('the wordmark matches the width in the design', (tester) async {
    await tester.pumpApp(const SplashScreen());
    await tester.pumpAndSettle();

    final box = tester.renderObject<RenderBox>(find.text('NOVA MODEST'));
    // The Figma frame is 218x32. Width lands on 218 with the design's 24px size
    // and 4.8 tracking, which is what makes this a fidelity check rather than a
    // restatement of the style values asserted above.
    expect(box.size.width, closeTo(218, 4));
  });

  testWidgets('the accent dot sits symmetrically between mark and tagline', (
    tester,
  ) async {
    await tester.pumpApp(const SplashScreen());
    await tester.pumpAndSettle();

    Rect rectOf(Finder f) => tester.getRect(f);
    final mark = rectOf(find.text('NOVA MODEST'));
    final dot = rectOf(find.byType(DecoratedBox).last);
    final tag = rectOf(find.text('احتشام عصري، يناسب كل يوم'));

    final above = dot.top - mark.bottom;
    final below = tag.top - dot.bottom;

    // The design's 8 belonged to the Arabic brand transliteration this screen
    // does not render; the separator is centred, so both gaps are AppSpacing.l.
    expect(above, closeTo(below, 1));
  });

  testWidgets('renders without overflow in both directions', (tester) async {
    for (final locale in const [Locale('ar'), Locale('en')]) {
      await tester.pumpApp(const SplashScreen(), locale: locale);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('the tagline stays on one line at the design width', (
    tester,
  ) async {
    // The design fits the tagline on a single line at 375pt; a longer
    // translation wrapping is a real regression, not a cosmetic one.
    for (final locale in const [Locale('ar'), Locale('en')]) {
      await tester.pumpApp(const SplashScreen(), locale: locale);
      await tester.pumpAndSettle();

      final tagline = find.byWidgetPredicate(
        (w) => w is Text && w.data != null && w.data != 'NOVA MODEST',
      );
      final box = tester.renderObject<RenderBox>(tagline);
      // One line measures 20 at 14sp; a second line takes it to 40. 30 sits
      // between the two with room for a metrics change that is not a wrap.
      expect(
        box.size.height,
        lessThan(30),
        reason: 'tagline wrapped to a second line in ${locale.languageCode}',
      );
    }
  });
}
