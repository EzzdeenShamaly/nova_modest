import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:nova_modest/app.dart';
import 'package:nova_modest/core/di/injection.dart';
import 'package:nova_modest/features/auth/domain/entities/user.dart';
import 'package:nova_modest/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:nova_modest/features/cart/presentation/bloc/cart_bloc.dart';
import 'package:nova_modest/features/onboarding/presentation/bloc/onboarding_bloc.dart';

export 'pump_app.dart' show loadAppFonts;

class _MockAuthBloc extends MockBloc<AuthEvent, AuthState>
    implements AuthBloc {}

class _MockOnboardingBloc extends MockBloc<OnboardingEvent, OnboardingState>
    implements OnboardingBloc {}

class _MockCartBloc extends MockBloc<CartEvent, CartState>
    implements CartBloc {}

/// Boots the **real** [App] — its own `MaterialApp.router`, its own router built
/// in `initState`, its own bloc providers.
///
/// Almost every test in this suite pumps one screen inside scaffolding it
/// controls, which cannot see anything about how the app is assembled. This is
/// for the properties that only exist once it is: that changing the locale
/// re-renders everything without resetting navigation, for instance.
///
/// The session blocs are stubbed through the container so the guard lands on
/// Home; whatever the caller wants to exercise for real it registers itself
/// before calling this.
Future<GoRouter> bootRealApp(
  WidgetTester tester, {
  bool signedIn = true,
}) async {
  const designSize = Size(375, 812);
  tester.view.physicalSize = designSize;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  const user = User(id: 'u1', email: 'a@b.com', displayName: 'سارة');

  void put<T extends Object>(T Function() create) {
    if (sl.isRegistered<T>()) sl.unregister<T>();
    sl.registerLazySingleton<T>(create);
  }

  put<AuthBloc>(() {
    final bloc = _MockAuthBloc();
    final state = signedIn
        ? const AuthAuthenticated(user)
        : const AuthUnauthenticated();
    whenListen(bloc, Stream<AuthState>.value(state), initialState: state);
    return bloc;
  });

  put<OnboardingBloc>(() {
    final bloc = _MockOnboardingBloc();
    whenListen(
      bloc,
      Stream<OnboardingState>.value(const OnboardingNotRequired()),
      initialState: const OnboardingNotRequired(),
    );
    return bloc;
  });

  put<CartBloc>(() {
    final bloc = _MockCartBloc();
    whenListen(
      bloc,
      Stream<CartState>.value(const CartEmpty()),
      initialState: const CartEmpty(),
    );
    return bloc;
  });

  addTearDown(() {
    sl
      ..unregister<AuthBloc>()
      ..unregister<OnboardingBloc>()
      ..unregister<CartBloc>();
  });

  // main.dart puts ScreenUtilInit above App, because AppSpacing and friends
  // resolve at call time and App builds the theme.
  await tester.pumpWidget(
    ScreenUtilInit(
      designSize: designSize,
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (_, _) => const App(),
    ),
  );
  await tester.pumpAndSettle();

  final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
  return app.routerConfig! as GoRouter;
}
