import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FontLoader;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nova_modest/core/theme/app_theme.dart';
import 'package:nova_modest/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:nova_modest/features/cart/presentation/bloc/cart_bloc.dart';
import 'package:nova_modest/features/onboarding/presentation/bloc/onboarding_bloc.dart';
import 'package:nova_modest/l10n/app_localizations.dart';

/// The Figma baseline, identical to the value `main.dart` passes.
const Size _designSize = Size(375, 812);

/// Loads the app's bundled font faces into the test engine.
///
/// Without this, `flutter_test` renders with its placeholder font, where every
/// glyph is a square of the font size. That makes text metrics fictional — an
/// Arabic and an English string of similar length measure identically — so any
/// assertion about wrapping, overflow, or measured size is meaningless. Call
/// this from `setUpAll` in tests that measure layout.
Future<void> loadAppFonts() async {
  final loader = FontLoader(AppTheme.fontFamily);
  for (final path in const [
    'assets/fonts/IBMPlexSansArabic-Light.ttf',
    'assets/fonts/IBMPlexSansArabic-Regular.ttf',
    'assets/fonts/IBMPlexSansArabic-Medium.ttf',
    'assets/fonts/IBMPlexSansArabic-SemiBold.ttf',
    'assets/fonts/IBMPlexSansArabic-Bold.ttf',
  ]) {
    loader.addFont(
      File(path).readAsBytes().then(
        (bytes) => ByteData.view(Uint8List.fromList(bytes).buffer),
      ),
    );
  }
  await loader.load();
}

extension PumpApp on WidgetTester {
  /// Pumps [widget] inside the localization and bloc scaffolding every screen
  /// test needs, so no test hand-rolls a `MaterialApp`.
  ///
  /// [locale] defaults to `ar` — the template locale and the app's primary one.
  /// Pass `Locale('en')` to assert English copy.
  Future<void> pumpApp(
    Widget widget, {
    AuthBloc? authBloc,
    OnboardingBloc? onboardingBloc,
    CartBloc? cartBloc,
    Locale locale = const Locale('ar'),
  }) async {
    // The test surface defaults to 800x600, which is nothing like the 375x812
    // design baseline: screenutil would scale `.sp` by 800/375 and `.h` by
    // 600/812, so text came out 2.13x too large and any layout assertion
    // measured a phantom. Pinning the surface to the baseline makes the scale
    // factor 1, so a test measures what the design specifies.
    view.physicalSize = _designSize;
    view.devicePixelRatio = 1;
    addTearDown(view.resetPhysicalSize);
    addTearDown(view.resetDevicePixelRatio);

    // ScreenUtilInit is not optional in tests: AppSpacing / AppRadius /
    // AppFontSize resolve `.h` / `.r` / `.sp` at call time and throw if scaling
    // was never initialised, and AppTheme reads all three. designSize matches
    // main.dart so a test measures what the app renders.
    Widget app(Widget child) => ScreenUtilInit(
      designSize: _designSize,
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (_, _) => MaterialApp(
        locale: locale,
        theme: AppTheme.light,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: child,
      ),
    );

    // Only the blocs a test actually supplies are provided, so a screen that
    // reads one it was not given fails loudly instead of silently picking up a
    // stand-in. Wrapped one at a time rather than through MultiBlocProvider,
    // which needs a non-empty list and a type from a transitive package.
    Widget tree = app(widget);
    if (onboardingBloc != null) {
      tree = BlocProvider<OnboardingBloc>.value(
        value: onboardingBloc,
        child: tree,
      );
    }
    if (authBloc != null) {
      tree = BlocProvider<AuthBloc>.value(value: authBloc, child: tree);
    }
    if (cartBloc != null) {
      tree = BlocProvider<CartBloc>.value(value: cartBloc, child: tree);
    }

    await pumpWidget(tree);
  }
}
