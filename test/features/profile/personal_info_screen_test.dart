import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nova_modest/core/di/injection.dart';
import 'package:nova_modest/core/error/failure.dart';
import 'package:nova_modest/features/auth/domain/entities/user.dart';
import 'package:nova_modest/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:nova_modest/features/auth/presentation/bloc/profile_edit_bloc.dart';
import 'package:nova_modest/features/profile/presentation/screens/personal_info_screen.dart';

import '../../helpers/pump_app.dart';

class _MockAuthBloc extends MockBloc<AuthEvent, AuthState>
    implements AuthBloc {}

class _MockProfileEditBloc extends MockBloc<ProfileEditEvent, ProfileEditState>
    implements ProfileEditBloc {}

void main() {
  late _MockAuthBloc authBloc;
  late _MockProfileEditBloc editBloc;

  const user = User(
    id: 'u1',
    email: 'sara@example.com',
    displayName: 'سارة',
    phone: '+966 50 123 4567',
  );

  setUpAll(() {
    registerFallbackValue(const AuthLogoutRequested());
    registerFallbackValue(const ProfileEditSubmitted(displayName: ''));
    return loadAppFonts();
  });

  setUp(() {
    authBloc = _MockAuthBloc();
    editBloc = _MockProfileEditBloc();

    whenListen(
      authBloc,
      Stream<AuthState>.value(const AuthAuthenticated(user)),
      initialState: const AuthAuthenticated(user),
    );

    if (sl.isRegistered<ProfileEditBloc>()) sl.unregister<ProfileEditBloc>();
    sl.registerFactory<ProfileEditBloc>(() => editBloc);
  });

  tearDown(() => sl.unregister<ProfileEditBloc>());

  /// [settle] is off for the submitting state: the save button's spinner
  /// animates forever, so `pumpAndSettle` would time out instead of asserting.
  Future<void> pump(
    WidgetTester tester, {
    ProfileEditState state = const ProfileEditIdle(),
    Locale? locale,
    bool settle = true,
  }) async {
    whenListen(
      editBloc,
      Stream<ProfileEditState>.value(state),
      initialState: state,
    );
    await tester.pumpApp(
      PersonalInfoScreen(key: UniqueKey()),
      authBloc: authBloc,
      locale: locale ?? const Locale('ar'),
    );
    if (settle) {
      await tester.pumpAndSettle();
    } else {
      await tester.pump();
    }
  }

  Finder fieldFor(String value) => find.widgetWithText(TextFormField, value);

  group('the form', () {
    testWidgets('opens on the current user, from AuthBloc', (tester) async {
      await pump(tester);

      expect(fieldFor('سارة'), findsOneWidget);
      expect(fieldFor('sara@example.com'), findsOneWidget);
      expect(fieldFor('+966 50 123 4567'), findsOneWidget);
    });

    testWidgets('the email cannot be edited and says so', (tester) async {
      await pump(tester);

      final email = tester.widget<TextFormField>(fieldFor('sara@example.com'));
      expect(email.enabled, isFalse);
      expect(find.text('لا يمكن تغيير البريد الإلكتروني.'), findsOneWidget);
      expect(find.byIcon(Icons.lock_outline), findsOneWidget);
    });

    testWidgets('a shopper with no phone opens on an empty field', (
      tester,
    ) async {
      whenListen(
        authBloc,
        Stream<AuthState>.value(
          const AuthAuthenticated(
            User(id: 'u2', email: 'a@b.com', displayName: 'ليلى'),
          ),
        ),
        initialState: const AuthAuthenticated(
          User(id: 'u2', email: 'a@b.com', displayName: 'ليلى'),
        ),
      );
      await pump(tester);

      expect(find.text('رقم الجوال'), findsOneWidget);
      expect(find.textContaining('+966'), findsNothing);
    });
  });

  group('saving', () {
    testWidgets('is disabled until something actually changes', (tester) async {
      await pump(tester);

      FilledButton saveButton() => tester.widget<FilledButton>(
        find.ancestor(
          of: find.text('حفظ التغييرات'),
          matching: find.byType(FilledButton),
        ),
      );
      expect(saveButton().onPressed, isNull);

      await tester.enterText(fieldFor('سارة'), 'سارة أحمد');
      await tester.pumpAndSettle();

      expect(saveButton().onPressed, isNotNull);
    });

    testWidgets('sends the edited values, with the email left out', (
      tester,
    ) async {
      await pump(tester);

      await tester.enterText(fieldFor('سارة'), 'سارة أحمد');
      await tester.pumpAndSettle();
      await tester.tap(find.text('حفظ التغييرات'));
      await tester.pump();

      verify(
        () => editBloc.add(
          const ProfileEditSubmitted(
            displayName: 'سارة أحمد',
            phone: '+966 50 123 4567',
          ),
        ),
      ).called(1);
    });

    testWidgets('an emptied phone is sent as a clear, not as unchanged', (
      tester,
    ) async {
      await pump(tester);

      await tester.enterText(fieldFor('+966 50 123 4567'), '');
      await tester.pumpAndSettle();
      await tester.tap(find.text('حفظ التغييرات'));
      await tester.pump();

      verify(
        () => editBloc.add(const ProfileEditSubmitted(displayName: 'سارة')),
      ).called(1);
    });

    testWidgets('an empty name is refused before anything is sent', (
      tester,
    ) async {
      await pump(tester);

      await tester.enterText(fieldFor('سارة'), '   ');
      await tester.pumpAndSettle();
      await tester.tap(find.text('حفظ التغييرات'));
      await tester.pumpAndSettle();

      expect(find.text('الاسم مطلوب'), findsOneWidget);
      verifyNever(() => editBloc.add(any(that: isA<ProfileEditSubmitted>())));
    });

    testWidgets('a phone that is not a number is refused', (tester) async {
      await pump(tester);

      await tester.enterText(fieldFor('+966 50 123 4567'), 'not a number');
      await tester.pumpAndSettle();
      await tester.tap(find.text('حفظ التغييرات'));
      await tester.pumpAndSettle();

      expect(find.text('أدخلي رقم جوال صحيح'), findsOneWidget);
      verifyNever(() => editBloc.add(any(that: isA<ProfileEditSubmitted>())));
    });

    testWidgets('a save in flight locks the fields and shows a spinner', (
      tester,
    ) async {
      await pump(tester, state: const ProfileEditSubmitting(), settle: false);

      final name = tester.widget<TextFormField>(fieldFor('سارة'));
      expect(name.enabled, isFalse);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });

  group('the outcome', () {
    testWidgets('a success reports the new user to AuthBloc', (tester) async {
      const saved = User(
        id: 'u1',
        email: 'sara@example.com',
        displayName: 'سارة أحمد',
      );
      await pump(tester, state: const ProfileEditSucceeded(saved));

      // The session's user is AuthBloc's to own; this screen only reports.
      verify(() => authBloc.add(const AuthProfileUpdated(saved))).called(1);
    });

    testWidgets('a failure is reported without throwing the form away', (
      tester,
    ) async {
      await pump(
        tester,
        state: const ProfileEditFailureState(NetworkFailure()),
      );

      expect(find.text('لا يوجد اتصال بالإنترنت.'), findsOneWidget);
      // What was typed is still correct, so the fields stay.
      expect(fieldFor('سارة'), findsOneWidget);
    });
  });

  group('leaving', () {
    testWidgets('an untouched form leaves without asking', (tester) async {
      await pump(tester);

      expect(
        tester.widget<PopScope<Object?>>(find.byType(PopScope<Object?>)).canPop,
        isTrue,
      );
    });

    testWidgets('an edited form is guarded', (tester) async {
      await pump(tester);

      await tester.enterText(fieldFor('سارة'), 'سارة أحمد');
      await tester.pumpAndSettle();

      expect(
        tester.widget<PopScope<Object?>>(find.byType(PopScope<Object?>)).canPop,
        isFalse,
      );
    });
  });

  group('direction and locale', () {
    testWidgets('renders without overflow in ar and en', (tester) async {
      for (final locale in const [Locale('ar'), Locale('en')]) {
        await pump(tester, locale: locale);
        expect(find.byType(TextFormField), findsNWidgets(3));
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('the chrome follows the locale', (tester) async {
      await pump(tester, locale: const Locale('en'));

      expect(find.text('Full name'), findsOneWidget);
      expect(find.text('Phone number'), findsOneWidget);
      expect(find.text('Save changes'), findsOneWidget);
      expect(
        find.text('Your email address cannot be changed.'),
        findsOneWidget,
      );
    });
  });
}
