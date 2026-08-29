import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nova_modest/core/theme/app_colors.dart';
import 'package:nova_modest/features/onboarding/presentation/bloc/onboarding_bloc.dart';
import 'package:nova_modest/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:nova_modest/features/onboarding/presentation/widgets/onboarding_slide.dart';

import '../../../helpers/pump_app.dart';

class _MockOnboardingBloc extends MockBloc<OnboardingEvent, OnboardingState>
    implements OnboardingBloc {}

void main() {
  late _MockOnboardingBloc bloc;

  setUpAll(() {
    registerFallbackValue(const OnboardingFinished());
    return loadAppFonts();
  });

  setUp(() {
    bloc = _MockOnboardingBloc();
    whenListen(
      bloc,
      Stream<OnboardingState>.value(const OnboardingRequired()),
      initialState: const OnboardingRequired(),
    );
  });

  Future<void> pump(WidgetTester tester, {Locale? locale}) async {
    await tester.pumpApp(
      const OnboardingScreen(),
      onboardingBloc: bloc,
      locale: locale ?? const Locale('ar'),
    );
    await tester.pumpAndSettle();
  }

  Future<void> swipeForward(WidgetTester tester) async {
    // RTL: the next page lives to the start side, so a forward swipe drags
    // toward the end. Using the PageView's own controller keeps the test
    // direction-agnostic.
    final view = tester.widget<PageView>(find.byType(PageView));
    view.controller!.jumpToPage(view.controller!.page!.round() + 1);
    await tester.pumpAndSettle();
  }

  testWidgets('opens on the first slide', (tester) async {
    await pump(tester);

    expect(find.byType(OnboardingSlide), findsOneWidget);
    expect(find.text('تسوقي أناقتك بكل سهولة'), findsOneWidget);
  });

  testWidgets('walks through all three slides in order', (tester) async {
    await pump(tester);

    expect(find.text('تسوقي أناقتك بكل سهولة'), findsOneWidget);
    await swipeForward(tester);
    expect(find.text('تصاميم محتشمة بلمسة عصرية'), findsOneWidget);
    await swipeForward(tester);
    expect(find.text('توصيل سريع وموثوق لباب بيتك'), findsOneWidget);
  });

  testWidgets('the action reads "next" until the last slide, then "start"', (
    tester,
  ) async {
    await pump(tester);

    expect(find.text('التالي'), findsOneWidget);
    expect(find.text('ابدأ'), findsNothing);

    await swipeForward(tester);
    expect(find.text('التالي'), findsOneWidget);

    await swipeForward(tester);
    expect(find.text('ابدأ'), findsOneWidget);
    expect(find.text('التالي'), findsNothing);
  });

  testWidgets('the action advances instead of finishing on a middle slide', (
    tester,
  ) async {
    await pump(tester);

    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();

    expect(find.text('تصاميم محتشمة بلمسة عصرية'), findsOneWidget);
    verifyNever(() => bloc.add(any()));
  });

  testWidgets('the action on the last slide finishes the onboarding', (
    tester,
  ) async {
    await pump(tester);
    await swipeForward(tester);
    await swipeForward(tester);

    await tester.tap(find.byType(FilledButton));
    await tester.pump();

    verify(() => bloc.add(const OnboardingFinished())).called(1);
  });

  testWidgets('skip finishes the onboarding exactly like the last action', (
    tester,
  ) async {
    await pump(tester);

    await tester.tap(find.text('تخطي'));
    await tester.pump();

    verify(() => bloc.add(const OnboardingFinished())).called(1);
  });

  testWidgets('skip is reachable from every slide', (tester) async {
    await pump(tester);
    for (var i = 0; i < 2; i++) {
      expect(find.text('تخطي'), findsOneWidget);
      await swipeForward(tester);
    }
    expect(find.text('تخطي'), findsOneWidget);
  });

  group('pagination dots', () {
    List<double> dotWidths(WidgetTester tester) => tester
        .widgetList<AnimatedContainer>(find.byType(AnimatedContainer))
        .map((c) => (c.constraints?.maxWidth ?? 0))
        .toList();

    testWidgets('one dot is stretched, and it tracks the page', (tester) async {
      await pump(tester);

      var widths = dotWidths(tester);
      expect(widths.length, 3);
      // The active pill is wider than the plain dots.
      expect(widths.indexOf(widths.reduce((a, b) => a > b ? a : b)), 0);

      await swipeForward(tester);
      widths = dotWidths(tester);
      expect(widths.indexOf(widths.reduce((a, b) => a > b ? a : b)), 1);

      await swipeForward(tester);
      widths = dotWidths(tester);
      expect(widths.indexOf(widths.reduce((a, b) => a > b ? a : b)), 2);
    });

    testWidgets('the active dot uses the accent colour', (tester) async {
      await pump(tester);

      final decorations = tester
          .widgetList<AnimatedContainer>(find.byType(AnimatedContainer))
          .map((c) => c.decoration! as BoxDecoration)
          .toList();

      expect(decorations.first.color, AppColors.accent);
      expect(decorations.last.color, AppColors.subtle);
    });
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

      expect(find.text('Shop your elegance with ease'), findsOneWidget);
      expect(find.text('Next'), findsOneWidget);
      expect(find.text('Skip'), findsOneWidget);
    });

    testWidgets('lays out RTL under the Arabic locale', (tester) async {
      await pump(tester);

      expect(
        Directionality.of(tester.element(find.byType(OnboardingSlide))),
        TextDirection.rtl,
      );
    });
  });
}
