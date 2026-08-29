import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nova_modest/core/di/injection.dart';
import 'package:nova_modest/core/error/failure.dart';
import 'package:nova_modest/core/theme/app_colors.dart';
import 'package:nova_modest/features/settings/domain/entities/notification_preferences.dart';
import 'package:nova_modest/features/settings/presentation/bloc/notification_preferences_bloc.dart';
import 'package:nova_modest/features/settings/presentation/screens/notifications_screen.dart';

import '../../helpers/pump_app.dart';

class _MockBloc
    extends MockBloc<NotificationPreferencesEvent, NotificationPreferencesState>
    implements NotificationPreferencesBloc {}

void main() {
  late _MockBloc bloc;

  setUpAll(() {
    registerFallbackValue(
      const NotificationPreferencesChanged(NotificationPreferences.defaults),
    );
    return loadAppFonts();
  });

  setUp(() {
    bloc = _MockBloc();
    // Provided with `create:`, so the provider closes it on dispose.
    when(bloc.close).thenAnswer((_) async {});
    if (sl.isRegistered<NotificationPreferencesBloc>()) {
      sl.unregister<NotificationPreferencesBloc>();
    }
    sl.registerFactory<NotificationPreferencesBloc>(() => bloc);
  });

  tearDown(() => sl.unregister<NotificationPreferencesBloc>());

  Future<void> pump(
    WidgetTester tester,
    NotificationPreferencesState state, {
    Locale? locale,
  }) async {
    whenListen(
      bloc,
      Stream<NotificationPreferencesState>.value(state),
      initialState: state,
    );
    await tester.pumpApp(
      NotificationsScreen(key: UniqueKey()),
      locale: locale ?? const Locale('ar'),
    );
    await tester.pumpAndSettle();
  }

  SwitchListTile tileFor(WidgetTester tester, String title) => tester.widget(
    find.ancestor(of: find.text(title), matching: find.byType(SwitchListTile)),
  );

  group('what is drawn', () {
    testWidgets('a switch per preference, with what each one covers', (
      tester,
    ) async {
      await pump(tester, const NotificationPreferencesUnresolved());

      expect(find.byType(SwitchListTile), findsNWidgets(2));
      expect(find.text('إشعارات الطلبات'), findsOneWidget);
      expect(find.text('العروض والتخفيضات'), findsOneWidget);
      expect(find.text('تأكيد الطلب وتحديثات الشحن والتوصيل.'), findsOneWidget);
    });

    testWidgets('renders from the first frame, before storage answers', (
      tester,
    ) async {
      // No loading state: two booleans always have a value.
      await pump(tester, const NotificationPreferencesUnresolved());

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(tileFor(tester, 'إشعارات الطلبات').value, isTrue);
      expect(tileFor(tester, 'العروض والتخفيضات').value, isFalse);
    });

    testWidgets('reflects what was stored', (tester) async {
      await pump(
        tester,
        const NotificationPreferencesResolved(
          NotificationPreferences(orders: false, promotions: true),
        ),
      );

      expect(tileFor(tester, 'إشعارات الطلبات').value, isFalse);
      expect(tileFor(tester, 'العروض والتخفيضات').value, isTrue);
    });

    testWidgets('says the phone has the final say', (tester) async {
      // The app cannot read the OS permission — no permission package is a
      // dependency — so it must not let two switches imply a guarantee it
      // cannot make.
      await pump(tester, const NotificationPreferencesUnresolved());

      expect(find.textContaining('إعدادات هاتفك'), findsOneWidget);
    });
  });

  group('changing one', () {
    testWidgets('sends the whole value, with only that field moved', (
      tester,
    ) async {
      await pump(tester, const NotificationPreferencesUnresolved());

      await tester.tap(find.text('العروض والتخفيضات'));
      await tester.pump();

      verify(
        () => bloc.add(
          const NotificationPreferencesChanged(
            NotificationPreferences(promotions: true),
          ),
        ),
      ).called(1);
    });

    testWidgets('turning one off leaves the other alone', (tester) async {
      await pump(
        tester,
        const NotificationPreferencesResolved(
          NotificationPreferences(orders: true, promotions: true),
        ),
      );

      await tester.tap(find.text('إشعارات الطلبات'));
      await tester.pump();

      verify(
        () => bloc.add(
          const NotificationPreferencesChanged(
            NotificationPreferences(orders: false, promotions: true),
          ),
        ),
      ).called(1);
    });
  });

  group('a failed save', () {
    testWidgets('is reported without the switch snapping back', (tester) async {
      await pump(
        tester,
        const NotificationPreferencesResolved(
          NotificationPreferences(promotions: true),
          saveFailure: CacheFailure(),
        ),
      );

      expect(find.text('البيانات المحلية غير متوفرة.'), findsOneWidget);
      // Still in its new position: the choice was applied, only not remembered.
      expect(tileFor(tester, 'العروض والتخفيضات').value, isTrue);
    });
  });

  group('the switch itself', () {
    testWidgets('its off state is legible, via the theme', (tester) async {
      // Material 3 takes the off thumb from `outline`, which this palette maps
      // to secondary — the same colour as the track. switchTheme is what stops
      // the control being one solid block.
      await pump(tester, const NotificationPreferencesUnresolved());

      final theme = Theme.of(tester.element(find.byType(SwitchListTile).first));
      expect(
        theme.switchTheme.thumbColor?.resolve(<WidgetState>{}),
        AppColors.mutedStrong,
      );
    });
  });

  group('direction and locale', () {
    testWidgets('renders without overflow in ar and en', (tester) async {
      for (final locale in const [Locale('ar'), Locale('en')]) {
        await pump(
          tester,
          const NotificationPreferencesUnresolved(),
          locale: locale,
        );
        expect(find.byType(SwitchListTile), findsNWidgets(2));
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('the copy follows the locale', (tester) async {
      await pump(
        tester,
        const NotificationPreferencesUnresolved(),
        locale: const Locale('en'),
      );

      expect(find.text('Order updates'), findsOneWidget);
      expect(find.text('Offers and sales'), findsOneWidget);
    });

    testWidgets('lays out RTL under Arabic', (tester) async {
      await pump(tester, const NotificationPreferencesUnresolved());

      expect(
        Directionality.of(tester.element(find.byType(SwitchListTile).first)),
        TextDirection.rtl,
      );
    });
  });
}
