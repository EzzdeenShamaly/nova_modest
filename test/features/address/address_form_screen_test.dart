import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nova_modest/core/di/injection.dart';
import 'package:nova_modest/core/error/failure.dart';
import 'package:nova_modest/features/address/domain/entities/address.dart';
import 'package:nova_modest/features/address/presentation/bloc/address_form_bloc.dart';
import 'package:nova_modest/features/address/presentation/bloc/address_list_bloc.dart';
import 'package:nova_modest/features/address/presentation/screens/address_form_screen.dart';
import 'package:nova_modest/features/address/presentation/widgets/address_form.dart';

import '../../helpers/pump_app.dart';

class _MockAddressFormBloc extends MockBloc<AddressFormEvent, AddressFormState>
    implements AddressFormBloc {}

class _MockAddressListBloc extends MockBloc<AddressListEvent, AddressListState>
    implements AddressListBloc {}

void main() {
  late _MockAddressFormBloc formBloc;
  late _MockAddressListBloc listBloc;

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

  setUpAll(() {
    registerFallbackValue(const AddressFormSubmitted(home));
    registerFallbackValue(const AddressesRequested());
    return loadAppFonts();
  });

  setUp(() {
    formBloc = _MockAddressFormBloc();
    listBloc = _MockAddressListBloc();

    // The screen provides the form bloc with `create:`, so the provider closes
    // it on dispose and a null return breaks the widget tree's finalisation.
    when(formBloc.close).thenAnswer((_) async {});

    if (sl.isRegistered<AddressFormBloc>()) sl.unregister<AddressFormBloc>();
    sl.registerFactory<AddressFormBloc>(() => formBloc);
  });

  tearDown(() => sl.unregister<AddressFormBloc>());

  Future<void> pump(
    WidgetTester tester, {
    String? addressId,
    AddressFormState state = const AddressFormIdle(),
    AddressListState list = const AddressListLoaded([home]),
    Locale? locale,
    bool settle = true,
  }) async {
    whenListen(
      formBloc,
      Stream<AddressFormState>.value(state),
      initialState: state,
    );
    whenListen(
      listBloc,
      Stream<AddressListState>.value(list),
      initialState: list,
    );

    await tester.pumpApp(
      // The list bloc sits above this route in the app, because the form is
      // pushed as a child of the addresses list.
      BlocProvider<AddressListBloc>.value(
        value: listBloc,
        child: AddressFormScreen(key: UniqueKey(), addressId: addressId),
      ),
      locale: locale ?? const Locale('ar'),
    );
    if (settle) {
      await tester.pumpAndSettle();
    } else {
      await tester.pump();
    }
  }

  Finder fieldFor(String value) => find.widgetWithText(TextFormField, value);

  group('adding', () {
    testWidgets('opens empty and titled for a new address', (tester) async {
      await pump(tester);

      expect(find.text('إضافة عنوان جديد'), findsWidgets);
      expect(fieldFor('المنزل'), findsNothing);
    });

    testWidgets('refuses to submit while required fields are empty', (
      tester,
    ) async {
      await pump(tester);

      await tester.tap(find.text('حفظ العنوان'));
      await tester.pumpAndSettle();

      expect(find.text('هذا الحقل مطلوب'), findsWidgets);
      verifyNever(() => formBloc.add(any(that: isA<AddressFormSubmitted>())));
    });

    testWidgets('a complete form submits an address with an empty id', (
      tester,
    ) async {
      await pump(tester);

      await tester.enterText(find.byType(TextFormField).at(0), 'بيت أمي');
      await tester.enterText(find.byType(TextFormField).at(1), 'سارة أحمد');
      await tester.enterText(find.byType(TextFormField).at(2), '+966550001111');
      await tester.enterText(find.byType(TextFormField).at(3), 'حي الشاطئ');
      await tester.enterText(find.byType(TextFormField).at(4), 'جدة');
      await tester.enterText(find.byType(TextFormField).at(6), 'طريق الكورنيش');
      await tester.pumpAndSettle();

      await tester.tap(find.text('حفظ العنوان'));
      await tester.pumpAndSettle();

      final captured =
          verify(
                () =>
                    formBloc.add(captureAny(that: isA<AddressFormSubmitted>())),
              ).captured.single
              as AddressFormSubmitted;

      // Empty id, so the repository treats it as new without the screen having
      // to branch.
      expect(captured.address.id, isEmpty);
      expect(captured.address.label, 'بيت أمي');
      expect(captured.address.city, 'جدة');
    });

    testWidgets('a required field below the fold is brought into view', (
      tester,
    ) async {
      // The whole reported defect: the form is ~934pt tall in a 375x812
      // surface, so "العنوان بالتفصيل" sits under the fold. Filling everything
      // visible and tapping save used to fail validation against a field — and
      // an error message — the shopper could not see, which reads as a button
      // that does nothing.
      await pump(tester);

      await tester.enterText(find.byType(TextFormField).at(0), 'بيت أمي');
      await tester.enterText(find.byType(TextFormField).at(1), 'سارة أحمد');
      await tester.enterText(find.byType(TextFormField).at(2), '+966550001111');
      await tester.enterText(find.byType(TextFormField).at(3), 'حي الشاطئ');
      await tester.enterText(find.byType(TextFormField).at(4), 'جدة');
      // index 6 — the street — is deliberately left empty.
      await tester.pumpAndSettle();

      await tester.tap(find.text('حفظ العنوان'));
      await tester.pumpAndSettle();

      verifyNever(() => formBloc.add(any(that: isA<AddressFormSubmitted>())));

      // Present in the tree is not the assertion: `find.text` searches the
      // element tree, and a SingleChildScrollView builds every child whether or
      // not it is on screen. What matters is that it is inside the viewport.
      final error = find.text('هذا الحقل مطلوب');
      expect(error, findsOneWidget);
      final rect = tester.getRect(error);
      expect(rect.top, greaterThanOrEqualTo(0));
      expect(
        rect.bottom,
        lessThanOrEqualTo(812),
        reason: 'the only validation error is still off-screen',
      );
    });

    testWidgets('a phone that is not a number is refused', (tester) async {
      await pump(tester);

      await tester.enterText(find.byType(TextFormField).at(2), 'not a number');
      await tester.pumpAndSettle();
      await tester.tap(find.text('حفظ العنوان'));
      await tester.pumpAndSettle();

      expect(find.text('أدخلي رقم جوال صحيح'), findsOneWidget);
    });
  });

  group('editing', () {
    testWidgets('opens on the address the list already holds', (tester) async {
      await pump(tester, addressId: 'a1');

      expect(find.text('تعديل العنوان'), findsWidgets);
      expect(fieldFor('المنزل'), findsOneWidget);
      expect(fieldFor('حي العليا'), findsOneWidget);
      expect(fieldFor('الرياض'), findsOneWidget);
    });

    testWidgets('submits carrying the original id, so it replaces', (
      tester,
    ) async {
      await pump(tester, addressId: 'a1');

      await tester.enterText(fieldFor('المنزل'), 'البيت');
      await tester.pumpAndSettle();
      await tester.tap(find.text('حفظ العنوان'));
      await tester.pumpAndSettle();

      final captured =
          verify(
                () =>
                    formBloc.add(captureAny(that: isA<AddressFormSubmitted>())),
              ).captured.single
              as AddressFormSubmitted;

      expect(captured.address.id, 'a1');
      expect(captured.address.label, 'البيت');
    });
  });

  group('the outcome', () {
    testWidgets('a success asks the list to reload', (tester) async {
      await pump(tester, state: const AddressFormSucceeded([home]));

      verify(() => listBloc.add(const AddressesRequested())).called(1);
    });

    testWidgets('a failure is reported without throwing the typing away', (
      tester,
    ) async {
      await pump(
        tester,
        addressId: 'a1',
        state: const AddressFormFailureState(NetworkFailure()),
      );

      expect(find.text('لا يوجد اتصال بالإنترنت.'), findsOneWidget);
      // Eight fields of typing are still on screen and still correct.
      expect(fieldFor('المنزل'), findsOneWidget);
    });

    testWidgets('a save in flight locks the form and shows a spinner', (
      tester,
    ) async {
      await pump(
        tester,
        addressId: 'a1',
        state: const AddressFormSubmitting(),
        settle: false,
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      final label = tester.widget<TextFormField>(fieldFor('المنزل'));
      expect(label.enabled, isFalse);
    });
  });

  group('leaving', () {
    testWidgets('an untouched form leaves without asking', (tester) async {
      await pump(tester, addressId: 'a1');

      expect(
        tester.widget<PopScope<Object?>>(find.byType(PopScope<Object?>)).canPop,
        isTrue,
      );
    });

    testWidgets('an edited form is guarded', (tester) async {
      await pump(tester, addressId: 'a1');

      await tester.enterText(fieldFor('المنزل'), 'البيت');
      await tester.pumpAndSettle();

      expect(
        tester.widget<PopScope<Object?>>(find.byType(PopScope<Object?>)).canPop,
        isFalse,
      );
    });
  });

  group('the form widget', () {
    testWidgets('is the reusable one checkout will host', (tester) async {
      await pump(tester);

      // Not a form built into this screen: the same widget goes inside the
      // checkout page later, which is why the screen owns only the bar.
      expect(find.byType(AddressForm), findsOneWidget);
    });

    testWidgets('offers all three kinds, defaulting to home', (tester) async {
      await pump(tester);

      for (final kind in const ['المنزل', 'العمل', 'أخرى']) {
        expect(find.widgetWithText(ChoiceChip, kind), findsOneWidget);
      }
      final selected = tester
          .widgetList<ChoiceChip>(find.byType(ChoiceChip))
          .where((chip) => chip.selected);
      expect(selected, hasLength(1));
    });
  });

  group('direction and locale', () {
    testWidgets('renders without overflow in ar and en', (tester) async {
      for (final locale in const [Locale('ar'), Locale('en')]) {
        await pump(tester, addressId: 'a1', locale: locale);
        expect(find.byType(AddressForm), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('the chrome follows the locale', (tester) async {
      await pump(tester, locale: const Locale('en'));

      expect(find.text('Address name'), findsOneWidget);
      expect(find.text('District'), findsOneWidget);
      expect(find.text('Save address'), findsOneWidget);
    });
  });
}
