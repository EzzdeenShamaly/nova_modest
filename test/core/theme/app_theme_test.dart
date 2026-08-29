import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nova_modest/core/theme/app_colors.dart';
import 'package:nova_modest/core/theme/app_dimensions.dart';
import 'package:nova_modest/core/theme/app_theme.dart';

/// Proves the design system is actually wired into the theme rather than merely
/// declared in files nothing reads. If someone reintroduces a seed colour or a
/// literal hex, these fail.
void main() {
  /// AppTheme reads `.h` / `.sp` / `.r`, so it can only be built inside a
  /// ScreenUtilInit subtree.
  Future<ThemeData> buildTheme(WidgetTester tester) async {
    late ThemeData theme;
    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(375, 812),
        minTextAdapt: true,
        splitScreenMode: true,
        builder: (_, _) {
          theme = AppTheme.light;
          return const SizedBox.shrink();
        },
      ),
    );
    return theme;
  }

  testWidgets('every ColorScheme role comes from AppColors', (tester) async {
    final scheme = (await buildTheme(tester)).colorScheme;

    expect(scheme.primary, AppColors.accent);
    expect(scheme.onPrimary, AppColors.primaryText);
    expect(scheme.secondary, AppColors.secondary);
    expect(scheme.onSecondary, AppColors.primaryText);
    expect(scheme.surface, AppColors.background);
    expect(scheme.onSurface, AppColors.primaryText);
    expect(scheme.outline, AppColors.secondary);
    expect(scheme.error, AppColors.error);
    expect(scheme.onError, AppColors.background);

    // Guards against ColorScheme.fromSeed creeping back in: a generated scheme
    // would never land exactly on the palette values above.
    expect(
      <Color>[
        scheme.primary,
        scheme.secondary,
        scheme.surface,
        scheme.onSurface,
        scheme.error,
      ],
      everyElement(
        // A List, not a Set: a const Set<Color> is rejected because Color has no
        // primitive equality.
        isIn(<Color>[
          AppColors.background,
          AppColors.primaryText,
          AppColors.secondary,
          AppColors.accent,
          AppColors.error,
        ]),
      ),
    );
  });

  testWidgets('the error colour is the agreed terracotta, not a system red', (
    tester,
  ) async {
    final scheme = (await buildTheme(tester)).colorScheme;

    // Pinned to the exact value carried over from the admin "cancelled" state,
    // so a later "let's just use Colors.red" cannot pass review silently.
    expect(scheme.error, const Color(0xFFB5524A));
    expect(scheme.error, isNot(Colors.red));
  });

  testWidgets('surfaces and dividers use the palette', (tester) async {
    final theme = await buildTheme(tester);

    expect(theme.scaffoldBackgroundColor, AppColors.background);
    expect(theme.appBarTheme.backgroundColor, AppColors.background);
    expect(theme.appBarTheme.foregroundColor, AppColors.primaryText);
    expect(theme.dividerTheme.color, AppColors.secondary);
    expect(theme.iconTheme.color, AppColors.primaryText);
    expect(theme.progressIndicatorTheme.color, AppColors.accent);
  });

  testWidgets('the bundled Arabic family is applied', (tester) async {
    final theme = await buildTheme(tester);

    expect(theme.textTheme.bodyMedium?.fontFamily, 'IBM Plex Sans Arabic');
    expect(theme.textTheme.titleLarge?.fontFamily, 'IBM Plex Sans Arabic');
  });

  testWidgets(
    'TextTheme sizes come from AppFontSize and colours from AppColors',
    (tester) async {
      late TextTheme textTheme;
      late double expectedBody;
      late double expectedDisplay;

      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(375, 812),
          minTextAdapt: true,
          splitScreenMode: true,
          builder: (_, _) {
            textTheme = AppTheme.light.textTheme;
            expectedBody = AppFontSize.m;
            expectedDisplay = AppFontSize.display;
            return const SizedBox.shrink();
          },
        ),
      );

      expect(textTheme.bodyMedium?.fontSize, expectedBody);
      expect(textTheme.displayLarge?.fontSize, expectedDisplay);
      expect(textTheme.bodyMedium?.color, AppColors.primaryText);
      expect(textTheme.displayLarge?.color, AppColors.primaryText);
    },
  );

  testWidgets('component shapes use the AppRadius scale', (tester) async {
    late ThemeData theme;
    late double expectedRadius;

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(375, 812),
        minTextAdapt: true,
        splitScreenMode: true,
        builder: (_, _) {
          theme = AppTheme.light;
          expectedRadius = AppRadius.l;
          return const SizedBox.shrink();
        },
      ),
    );

    final shape = theme.cardTheme.shape;
    expect(shape, isA<RoundedRectangleBorder>());
    expect(
      (shape! as RoundedRectangleBorder).borderRadius,
      BorderRadius.circular(expectedRadius),
    );
  });

  testWidgets('a switch is legible while it is off', (tester) async {
    // Material 3 takes the off state from the ColorScheme: the track from
    // surfaceContainerHighest, and BOTH the track outline and the thumb from
    // outline. This palette maps all three to AppColors.secondary, so an
    // unthemed switch was one solid #E8DFD3 blob at 1.00:1 — it did not read as
    // a switch at all.
    late final ThemeData theme;
    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(375, 812),
        builder: (_, _) {
          theme = AppTheme.light;
          return const SizedBox.shrink();
        },
      ),
    );

    const off = <WidgetState>{};
    final thumb = theme.switchTheme.thumbColor?.resolve(off);
    final track = theme.switchTheme.trackColor?.resolve(off);

    expect(thumb, isNotNull, reason: 'the off thumb is left to Material');
    expect(track, isNotNull);
    expect(
      _contrast(thumb!, track!),
      greaterThan(3),
      reason: 'the off thumb does not stand out from its track',
    );
  });
}

/// WCAG relative-contrast between two opaque colours.
double _contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final hi = la > lb ? la : lb;
  final lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}
