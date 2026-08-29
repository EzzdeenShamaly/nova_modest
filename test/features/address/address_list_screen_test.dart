import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nova_modest/core/error/failure.dart';
import 'package:nova_modest/core/widgets/failure_view.dart';
import 'package:nova_modest/features/address/domain/entities/address.dart';
import 'package:nova_modest/features/address/presentation/bloc/address_list_bloc.dart';
import 'package:nova_modest/features/address/presentation/screens/address_list_screen.dart';
import 'package:nova_modest/features/address/presentation/widgets/address_card.dart';

import '../../helpers/pump_app.dart';

class _MockAddressListBloc extends MockBloc<AddressListEvent, AddressListState>
    implements AddressListBloc {}

void main() {
  late _MockAddressListBloc bloc;

  const home = Address(
    id: 'a1',
    kind: AddressKind.home,
    label: 'المنزل',
    recipientName: 'السيد أحمد عبدالله',
    phone: '+966 50 123 4567',
    country: 'المملكة العربية السعودية',
    region: 'حي العليا',
    city: 'الرياض',
    street: 'شارع الملك فهد، مبنى ٤٥',
    postalCode: '١٢٢١١',
    isDefault: true,
  );
  const work = Address(
    id: 'a2',
    kind: AddressKind.work,
    label: 'العمل',
    recipientName: 'السيد أحمد عبدالله',
    phone: '+966 11 987 6543',
    country: 'المملكة العربية السعودية',
    region: 'طريق العروبة',
    city: 'الرياض',
    street: 'برج المملكة، الطابق ٢٢',
  );

  setUpAll(() {
    registerFallbackValue(const AddressesRequested());
    return loadAppFonts();
  });

  setUp(() => bloc = _MockAddressListBloc());

  /// [settle] is off for the loading state: a spinner animates forever.
  Future<void> pump(
    WidgetTester tester,
    AddressListState state, {
    Locale? locale,
    bool settle = true,
  }) async {
    whenListen(
      bloc,
      Stream<AddressListState>.value(state),
      initialState: state,
    );
    await tester.pumpApp(
      // Handed in, not resolved: the ShellRoute around the address routes owns
      // this bloc so the list and the form share one. A screen test that
      // registered it in `sl` instead would be testing a tree the app does not
      // build — see test/router/address_routes_test.dart.
      BlocProvider<AddressListBloc>.value(
        value: bloc,
        child: AddressListScreen(key: UniqueKey()),
      ),
      locale: locale ?? const Locale('ar'),
    );
    if (settle) {
      await tester.pumpAndSettle();
    } else {
      await tester.pump();
    }
  }

  group('states', () {
    testWidgets('loading shows a spinner and no cards', (tester) async {
      await pump(tester, const AddressListLoading(), settle: false);

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byType(AddressCard), findsNothing);
    });

    testWidgets('a failed read shows the shared error view with a retry', (
      tester,
    ) async {
      await pump(tester, const AddressListError(NetworkFailure()));

      expect(find.byType(FailureView), findsOneWidget);
      // The screen already dispatched one on open; this asserts the retry adds
      // its own rather than counting both.
      clearInteractions(bloc);
      await tester.tap(find.byType(FilledButton).first);
      await tester.pump();
      verify(() => bloc.add(const AddressesRequested())).called(1);
    });

    testWidgets('empty invites adding rather than showing nothing', (
      tester,
    ) async {
      await pump(tester, const AddressListEmpty());

      expect(find.text('لا توجد عناوين محفوظة'), findsOneWidget);
      expect(find.byType(AddressCard), findsNothing);
      // The add bar stays: an empty list with no way to fill it is a dead end.
      expect(find.text('إضافة عنوان جديد'), findsOneWidget);
    });

    testWidgets('loaded draws a card per address', (tester) async {
      await pump(tester, const AddressListLoaded([home, work]));

      expect(find.byType(AddressCard), findsNWidgets(2));
      expect(find.text('المنزل'), findsOneWidget);
      expect(find.text('العمل'), findsOneWidget);
    });
  });

  group('a card', () {
    testWidgets('draws the postal block the entity formats', (tester) async {
      await pump(tester, const AddressListLoaded([home]));

      for (final line in home.postalLines) {
        expect(find.text(line), findsOneWidget, reason: 'missing $line');
      }
    });

    testWidgets('only the default carries the badge', (tester) async {
      await pump(tester, const AddressListLoaded([home, work]));

      expect(find.text('الافتراضي'), findsOneWidget);
    });

    testWidgets('the default is not offered a set-default action', (
      tester,
    ) async {
      await pump(tester, const AddressListLoaded([home, work]));

      // One control, on the work address only — on the default it would be a
      // no-op dressed as an action.
      expect(find.text('تعيين كافتراضي'), findsOneWidget);
    });

    testWidgets('choosing a default reports which one', (tester) async {
      await pump(tester, const AddressListLoaded([home, work]));

      await tester.tap(find.text('تعيين كافتراضي'));
      await tester.pump();

      verify(() => bloc.add(const AddressDefaultSelected('a2'))).called(1);
    });

    testWidgets('the icon follows the kind, not the label', (tester) async {
      await pump(tester, const AddressListLoaded([home, work]));

      expect(find.byIcon(Icons.home_outlined), findsOneWidget);
      expect(find.byIcon(Icons.work_outline), findsOneWidget);
    });
  });

  group('deleting', () {
    testWidgets('asks before removing', (tester) async {
      await pump(tester, const AddressListLoaded([home, work]));

      await tester.tap(find.byIcon(Icons.delete_outline).first);
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      // An address takes eight fields to type back in.
      verifyNever(() => bloc.add(any(that: isA<AddressDeleted>())));
    });

    testWidgets('cancelling leaves the address alone', (tester) async {
      await pump(tester, const AddressListLoaded([home, work]));

      await tester.tap(find.byIcon(Icons.delete_outline).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('إلغاء'));
      await tester.pumpAndSettle();

      verifyNever(() => bloc.add(any(that: isA<AddressDeleted>())));
    });

    testWidgets('confirming reports the id', (tester) async {
      await pump(tester, const AddressListLoaded([home, work]));

      await tester.tap(find.byIcon(Icons.delete_outline).first);
      await tester.pumpAndSettle();
      // The dialog repeats the label on its confirming action.
      await tester.tap(find.text('حذف العنوان').last);
      await tester.pumpAndSettle();

      verify(() => bloc.add(const AddressDeleted('a1'))).called(1);
    });
  });

  group('direction and locale', () {
    testWidgets('renders without overflow in ar and en', (tester) async {
      for (final locale in const [Locale('ar'), Locale('en')]) {
        await pump(
          tester,
          const AddressListLoaded([home, work]),
          locale: locale,
        );
        expect(find.byType(AddressCard), findsNWidgets(2));
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('the chrome follows the locale, the data does not', (
      tester,
    ) async {
      await pump(
        tester,
        const AddressListLoaded([home]),
        locale: const Locale('en'),
      );

      expect(find.text('My addresses'), findsOneWidget);
      expect(find.text('Default'), findsOneWidget);
      expect(find.text('Add a new address'), findsOneWidget);
      // The address itself is data the backend owns, so it stays Arabic.
      expect(find.text('المنزل'), findsOneWidget);
    });

    testWidgets('lays out RTL under Arabic', (tester) async {
      await pump(tester, const AddressListLoaded([home]));

      expect(
        Directionality.of(tester.element(find.byType(AddressCard))),
        TextDirection.rtl,
      );
    });
  });
}
