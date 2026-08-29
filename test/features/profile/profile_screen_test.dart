import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nova_modest/core/error/failure.dart';
import 'package:nova_modest/core/theme/app_colors.dart';
import 'package:nova_modest/features/auth/domain/entities/user.dart';
import 'package:nova_modest/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:nova_modest/features/profile/presentation/screens/profile_screen.dart';
import 'package:nova_modest/features/profile/presentation/widgets/profile_menu_tile.dart';

import '../../helpers/pump_app.dart';

class _MockAuthBloc extends MockBloc<AuthEvent, AuthState>
    implements AuthBloc {}

void main() {
  late _MockAuthBloc authBloc;

  const user = User(
    id: 'u1',
    email: 'sara@example.com',
    displayName: 'سارة',
    phone: '+966 50 123 4567',
  );

  setUpAll(loadAppFonts);

  setUp(() => authBloc = _MockAuthBloc());

  /// [settle] is off for the loading state: a spinner animates forever. The
  /// state is re-stubbed per pump because `Stream.value` is single-subscription.
  Future<void> pump(
    WidgetTester tester,
    AuthState state, {
    Locale? locale,
    bool settle = true,
  }) async {
    whenListen(authBloc, Stream<AuthState>.value(state), initialState: state);
    await tester.pumpApp(
      ProfileScreen(key: UniqueKey()),
      authBloc: authBloc,
      locale: locale ?? const Locale('ar'),
    );
    if (settle) {
      await tester.pumpAndSettle();
    } else {
      await tester.pump();
    }
  }

  group('the header card', () {
    testWidgets('shows the signed-in user, from AuthBloc', (tester) async {
      await pump(tester, const AuthAuthenticated(user));

      expect(find.text('سارة'), findsOneWidget);
      expect(find.text('sara@example.com'), findsOneWidget);
      expect(find.text('+966 50 123 4567'), findsOneWidget);
    });

    testWidgets('a shopper with no phone gets no empty line', (tester) async {
      // Signing in with Google can leave the number genuinely unknown.
      await pump(
        tester,
        const AuthAuthenticated(
          User(id: 'u2', email: 'a@b.com', displayName: 'ليلى'),
        ),
      );

      expect(find.text('a@b.com'), findsOneWidget);
      expect(find.textContaining('+'), findsNothing);
    });

    testWidgets('stands in for the missing avatar with the initial', (
      tester,
    ) async {
      await pump(tester, const AuthAuthenticated(user));

      expect(find.text('س'), findsOneWidget);
    });
  });

  group('the menu', () {
    testWidgets('lists every destination the design has', (tester) async {
      await pump(tester, const AuthAuthenticated(user));

      for (final label in const [
        'طلباتي',
        'البيانات الشخصية',
        'العناوين',
        'اللغة',
        'الإشعارات',
        'المساعدة والدعم',
        'الشروط والأحكام',
        'تسجيل الخروج',
      ]) {
        expect(find.text(label), findsOneWidget, reason: 'missing $label');
      }
      expect(find.byType(ProfileMenuTile), findsNWidgets(8));
    });

    testWidgets('the language row reports the language in force', (
      tester,
    ) async {
      await pump(tester, const AuthAuthenticated(user));

      expect(find.text('العربية'), findsOneWidget);
    });

    testWidgets('only the language row carries a value', (tester) async {
      await pump(tester, const AuthAuthenticated(user));

      final withValues = tester
          .widgetList<ProfileMenuTile>(find.byType(ProfileMenuTile))
          .where((tile) => tile.value != null);

      expect(withValues, hasLength(1));
    });

    testWidgets('sign-out is the destructive row and has no chevron', (
      tester,
    ) async {
      await pump(tester, const AuthAuthenticated(user));

      final tiles = tester
          .widgetList<ProfileMenuTile>(find.byType(ProfileMenuTile))
          .toList();
      final destructive = tiles.where((tile) => tile.destructive);

      expect(destructive, hasLength(1));
      expect(destructive.single.label, 'تسجيل الخروج');
      // Seven rows lead somewhere; the eighth acts here.
      expect(find.byIcon(Icons.chevron_right), findsNWidgets(7));
    });

    testWidgets('the destructive row uses the palette error colour', (
      tester,
    ) async {
      await pump(tester, const AuthAuthenticated(user));

      final label = tester.widget<Text>(find.text('تسجيل الخروج'));
      // Not the design's #BA1A1A: the palette already carries a destructive
      // role, added by an explicit decision.
      expect(label.style?.color, AppColors.error);
    });
  });

  group('signing out', () {
    testWidgets('asks before ending the session', (tester) async {
      await pump(tester, const AuthAuthenticated(user));

      await tester.tap(find.text('تسجيل الخروج'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('هل تريدين تسجيل الخروج من حسابك؟'), findsOneWidget);
      // The row alone must not end the session — it is one tap inside a
      // scrolling list.
      verifyNever(() => authBloc.add(const AuthLogoutRequested()));
    });

    testWidgets('cancelling leaves the session alone', (tester) async {
      await pump(tester, const AuthAuthenticated(user));

      await tester.tap(find.text('تسجيل الخروج'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('إلغاء'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);
      verifyNever(() => authBloc.add(const AuthLogoutRequested()));
    });

    testWidgets('confirming reports it to AuthBloc', (tester) async {
      await pump(tester, const AuthAuthenticated(user));

      await tester.tap(find.text('تسجيل الخروج'));
      await tester.pumpAndSettle();
      // The dialog repeats the label on its confirming action.
      await tester.tap(find.text('تسجيل الخروج').last);
      await tester.pumpAndSettle();

      // The screen never navigates: the router's guard moves the user once the
      // session state changes.
      verify(() => authBloc.add(const AuthLogoutRequested())).called(1);
    });
  });

  group('other session states', () {
    testWidgets('a sign-out in flight shows a spinner, not a stale card', (
      tester,
    ) async {
      await pump(tester, const AuthLoading(), settle: false);

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byType(ProfileMenuTile), findsNothing);
    });

    testWidgets('a resolved guest draws nothing while the guard moves them', (
      tester,
    ) async {
      // Unreachable behind Routes.protectedPrefixes, but the screen must not
      // throw if it is ever built in that instant.
      for (final state in const [
        AuthUnauthenticated(),
        AuthFailureState(NetworkFailure()),
      ]) {
        await pump(tester, state);
        expect(find.byType(ProfileMenuTile), findsNothing);
        expect(tester.takeException(), isNull);
      }
    });
  });

  group('direction and locale', () {
    testWidgets('renders without overflow in ar and en', (tester) async {
      for (final locale in const [Locale('ar'), Locale('en')]) {
        await pump(tester, const AuthAuthenticated(user), locale: locale);
        expect(find.byType(ProfileMenuTile), findsNWidgets(8));
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('the chrome follows the locale, and so does the language row', (
      tester,
    ) async {
      await pump(
        tester,
        const AuthAuthenticated(user),
        locale: const Locale('en'),
      );

      expect(find.text('My orders'), findsOneWidget);
      expect(find.text('Terms & conditions'), findsOneWidget);
      // Each locale names itself, so the row reports the language in force
      // rather than a fixed label.
      expect(find.text('English'), findsOneWidget);
    });

    testWidgets('lays out RTL under Arabic', (tester) async {
      await pump(tester, const AuthAuthenticated(user));

      expect(
        Directionality.of(tester.element(find.byType(ProfileMenuTile).first)),
        TextDirection.rtl,
      );
    });
  });
}
