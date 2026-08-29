// The project's dimension scales, all resolved through `flutter_screenutil`
// against the 375x812 design baseline set in `main.dart`.
//
// These scales are CLOSED. If a Figma value is not on a scale, use the nearest
// value that is - do not add a new entry here.
//
// The one exception: a measurement specific to a single element on a single
// screen (a hero image height, say) belongs as a private constant inside that
// widget's own file, never in this one.
//
// Every member is a `get`, not a `const`, because scaling is only known once
// `ScreenUtilInit` has run. That means these cannot appear in a `const`
// expression - `EdgeInsetsDirectional.all(AppSpacing.m)` without `const` is
// correct and expected.

import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Spacing scale — gaps, padding, margins.
///
/// Scaled with `.h` per the project's design-system decision, so the rhythm
/// stays proportional to screen height. Note this applies to horizontal gaps
/// too: on an unusually wide-and-short window, horizontal padding tracks height
/// rather than width. That is the intended trade-off for a single consistent
/// scale; switch a specific case to `.w` only with a comment saying why.
abstract final class AppSpacing {
  static double get xxs => 4.h;
  static double get xs => 8.h;
  static double get s => 12.h;
  static double get m => 16.h;
  static double get l => 24.h;
  static double get xl => 32.h;
  static double get xxl => 48.h;
}

/// Corner-radius scale.
abstract final class AppRadius {
  static double get s => 8.r;
  static double get m => 12.r;
  static double get l => 16.r;

  /// Fully rounded — for chips and pill buttons.
  static double get pill => 999.r;
}

/// Font-size scale. `.sp` so sizes respect the platform text-scale setting.
abstract final class AppFontSize {
  static double get xs => 10.sp;
  static double get s => 12.sp;
  static double get m => 14.sp;
  static double get l => 16.sp;
  static double get xl => 18.sp;
  static double get xxl => 20.sp;
  static double get xxxl => 24.sp;
  static double get display => 28.sp;
}
