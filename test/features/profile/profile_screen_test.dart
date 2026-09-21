import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nova_modest/core/di/injection.dart';
import 'package:nova_modest/core/error/failure.dart';
import 'package:nova_modest/core/theme/app_colors.dart';
import 'package:nova_modest/features/auth/domain/entities/user.dart';
import 'package:nova_modest/features/auth/presentation/bloc/account_deletion_bloc.dart';
import 'package:nova_modest/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:nova_modest/features/profile/presentation/screens/profile_screen.dart';
import 'package:nova_modest/features/profile/presentation/widgets/profile_menu_tile.dart';

import '../../helpers/pump_app.dart';

class _MockAuthBloc extends MockBloc<AuthEvent, AuthState>
    implements AuthBloc {}

class _MockAccountDeletionBloc
    extends MockBloc<AccountDeletionEvent, AccountDeletionState>
    implements AccountDeletionBloc {}

void main() {
  late _MockAuthBloc authBloc;
  late _MockAccountDeletionBloc deletionBloc;

  const user = User(
    id: 'u1',
    email: 'sara@example.com',
    displayName: 'سارة',
    phone: '+966 50 123 4567',
  );

  setUpAll(() {
    registerFallbackValue(const AuthLogoutRequested());
    registerFallbackValue(const AccountDeletionConfirmed());
    return loadAppFonts();
  });

  setUp(() {
    authBloc = _MockAuthBloc();
    deletionBloc = _MockAccountDeletionBloc();
    whenListen(
      deletionBloc,
      const Stream<AccountDeletionState>.empty(),
      initialState: const AccountDeletionIdle(),
    );
    // The screen asks the container for its own deletion bloc, as
    // PersonalInfoScreen does for ProfileEditBloc.
    if (sl.isRegistered<AccountDeletionBloc>()) {
      sl.unregister<AccountDeletionBloc>();
    }
    sl.registerFactory<AccountDeletionBloc>(() => deletionBloc);
  });

  tearDown(() => sl.unregister<AccountDeletionBloc>());

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
        // Not in the frame: Play requires in-app deletion (blocker 5).
        'حذف الحساب',
      ]) {
        expect(find.text(label), findsOneWidget, reason: 'missing $label');
      }
      expect(find.byType(ProfileMenuTile), findsNWidgets(9));
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

    testWidgets(
      'the two rows that end things are destructive and lead nowhere',
      (tester) async {
        await pump(tester, const AuthAuthenticated(user));

        final tiles = tester
            .widgetList<ProfileMenuTile>(find.byType(ProfileMenuTile))
            .toList();
        final destructive = tiles.where((tile) => tile.destructive);

        expect(destructive.map((tile) => tile.label), [
          'تسجيل الخروج',
          'حذف الحساب',
        ]);
        // Seven rows lead somewhere; the last two act here.
        expect(find.byIcon(Icons.chevron_right), findsNWidgets(7));
      },
    );

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

  group('deleting the account', () {
    Future<void> openDialog(WidgetTester tester) async {
      await pump(tester, const AuthAuthenticated(user));
      await tester.scrollUntilVisible(find.text('حذف الحساب'), 200);
      await tester.tap(find.text('حذف الحساب'));
      await tester.pumpAndSettle();
    }

    /// Replays [states] from the deletion bloc, as its listener would see them.
    Future<void> pumpWithDeletion(
      WidgetTester tester,
      List<AccountDeletionState> states,
    ) async {
      whenListen(
        deletionBloc,
        Stream<AccountDeletionState>.fromIterable(states),
        initialState: const AccountDeletionIdle(),
      );
      await pump(tester, const AuthAuthenticated(user));
    }

    testWidgets('is the last row, in the error colour', (tester) async {
      await pump(tester, const AuthAuthenticated(user));

      // Play requires deletion to be discoverable in the app.
      final tiles = tester
          .widgetList<ProfileMenuTile>(find.byType(ProfileMenuTile))
          .toList();
      expect(tiles.last.label, 'حذف الحساب');
      expect(tiles.last.destructive, isTrue);
    });

    testWidgets('the dialog says what goes and what stays, before any press', (
      tester,
    ) async {
      await openDialog(tester);

      final body = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(Text),
      );
      final text = tester
          .widgetList<Text>(body)
          .map((t) => t.data ?? '')
          .join(' ');

      // What goes.
      expect(text, contains('ملفكِ الشخصي'));
      expect(text, contains('عناوينكِ المحفوظة'));
      expect(text, contains('صورتكِ الشخصية'));
      expect(text, contains('لا يمكن التراجع'));
      // What stays — orders.user_id is ON DELETE SET NULL, and she must know
      // that before pressing, not after (owner, 2026-09-21).
      expect(text, contains('طلباتكِ السابقة فتبقى لدى المتجر'));
      verifyNever(() => deletionBloc.add(any()));
    });

    testWidgets('cancelling deletes nothing', (tester) async {
      await openDialog(tester);

      await tester.tap(find.text('إلغاء'));
      await tester.pumpAndSettle();

      verifyNever(() => deletionBloc.add(any()));
    });

    testWidgets('confirming sends exactly one deletion', (tester) async {
      await openDialog(tester);

      // The title says it too; the button is the one to press.
      await tester.tap(find.widgetWithText(TextButton, 'حذف الحساب'));
      await tester.pumpAndSettle();

      verify(
        () => deletionBloc.add(const AccountDeletionConfirmed()),
      ).called(1);
    });

    testWidgets('success ends the session through AuthBloc', (tester) async {
      await pumpWithDeletion(tester, const [
        AccountDeletionInProgress(),
        AccountDeletionSucceeded(),
      ]);

      // Not AuthLogoutRequested: the account is gone, and there is no server
      // session left to end.
      verify(() => authBloc.add(const AuthAccountDeleted())).called(1);
      verifyNever(() => authBloc.add(const AuthLogoutRequested()));
    });

    testWidgets('an expired session signs her out, as everywhere else', (
      tester,
    ) async {
      await pumpWithDeletion(tester, const [
        AccountDeletionFailed(UnauthorizedFailure('not_signed_in')),
      ]);

      verify(() => authBloc.add(const AuthLogoutRequested())).called(1);
      verifyNever(() => authBloc.add(const AuthAccountDeleted()));
    });

    testWidgets('a refusal is reported and the account left as it was', (
      tester,
    ) async {
      await pumpWithDeletion(tester, const [
        AccountDeletionFailed(
          ValidationFailure(
            'account_delete_failed',
            code: 'account_delete_failed',
          ),
        ),
      ]);

      // The honest sentence: the photo is removed before the account, so by
      // this failure it is already gone.
      expect(
        find.text(
          'تعذّر حذف الحساب، وقد حُذفت صورتكِ الشخصية. أعيدي المحاولة لاحقاً.',
        ),
        findsOneWidget,
      );
      verifyNever(() => authBloc.add(any()));
    });

    testWidgets('nothing on the screen can be touched while it runs', (
      tester,
    ) async {
      whenListen(
        deletionBloc,
        const Stream<AccountDeletionState>.empty(),
        initialState: const AccountDeletionInProgress(),
      );
      await pump(tester, const AuthAuthenticated(user), settle: false);

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byType(ProfileMenuTile), findsNothing);
    });
  });

  group('direction and locale', () {
    testWidgets('renders without overflow in ar and en', (tester) async {
      for (final locale in const [Locale('ar'), Locale('en')]) {
        await pump(tester, const AuthAuthenticated(user), locale: locale);
        expect(find.byType(ProfileMenuTile), findsNWidgets(9));
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
