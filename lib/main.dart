import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:injectable/injectable.dart';
import 'package:nova_modest/app.dart';
import 'package:nova_modest/core/di/injection.dart';
import 'package:nova_modest/core/supabase/supabase_bootstrap.dart';

void main() {
  // runZonedGuarded catches async errors that escape the framework's own
  // handler. Both hooks currently forward to the console; wire them to a crash
  // reporter before release — `/production-readiness-review` treats an
  // unreported crash path as a blocker.
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      FlutterError.onError = (details) {
        FlutterError.presentError(details);
      };

      await initializeSupabase();
      await configureDependencies(environment: Environment.dev);

      // ScreenUtilInit must sit above everything that reads AppSpacing /
      // AppRadius / AppFontSize: those scales resolve `.h` / `.r` / `.sp` at
      // call time and throw if scaling has not been initialised. App builds the
      // theme inside this builder, so the theme is safe too.
      runApp(
        ScreenUtilInit(
          // The Figma baseline this project's measurements are taken from.
          designSize: const Size(375, 812),
          // Keeps text legible when the window is far from the baseline ratio.
          minTextAdapt: true,
          splitScreenMode: true,
          builder: (_, _) => const App(),
        ),
      );
    },
    (error, stack) {
      debugPrint('Uncaught zone error: $error\n$stack');
    },
  );
}
