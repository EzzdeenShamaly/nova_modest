import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nova_modest/core/di/injection.dart';
import 'package:nova_modest/features/auth/presentation/bloc/sign_in_bloc.dart';
import 'package:nova_modest/features/address/presentation/bloc/address_form_bloc.dart';
import 'package:nova_modest/features/address/presentation/bloc/address_list_bloc.dart';
import 'package:nova_modest/features/cart/presentation/bloc/cart_bloc.dart';
import 'package:nova_modest/features/catalog/presentation/bloc/home_bloc.dart';
import 'package:nova_modest/features/catalog/presentation/bloc/product_list_bloc.dart';
import 'package:nova_modest/features/orders/presentation/bloc/orders_bloc.dart';
import 'package:nova_modest/features/settings/presentation/bloc/notification_preferences_bloc.dart';
import 'package:nova_modest/features/catalog/presentation/bloc/search_bloc.dart';

class _MockSignInBloc extends MockBloc<SignInEvent, SignInState>
    implements SignInBloc {}

class _MockHomeBloc extends MockBloc<HomeEvent, HomeState>
    implements HomeBloc {}

class _MockProductListBloc extends MockBloc<ProductListEvent, ProductListState>
    implements ProductListBloc {}

/// Public, unlike its neighbours: checkout hosts the address feature's blocs
/// rather than resolving them, so its screen test drives these directly instead
/// of going through [registerScreenBlocs].
class MockAddressListBloc extends MockBloc<AddressListEvent, AddressListState>
    implements AddressListBloc {}

class MockAddressFormBloc extends MockBloc<AddressFormEvent, AddressFormState>
    implements AddressFormBloc {}

class _MockSearchBloc extends MockBloc<SearchEvent, SearchState>
    implements SearchBloc {}

class _MockOrdersBloc extends MockBloc<OrdersEvent, OrdersState>
    implements OrdersBloc {}

class _MockNotificationPreferencesBloc
    extends MockBloc<NotificationPreferencesEvent, NotificationPreferencesState>
    implements NotificationPreferencesBloc {}

/// The app-wide cart, faked.
///
/// Unlike the two above, `CartBloc` is not resolved from the container by the
/// screens that use it — `app.dart` provides it to the whole tree — so tests
/// pass one in rather than registering it. Exposed by name so a test can
/// `verify` what the product page dispatched.
class MockCartBloc extends MockBloc<CartEvent, CartState> implements CartBloc {}

/// A cart pinned to [state], for tests that only need one to exist in the tree.
MockCartBloc stubCartBloc([CartState state = const CartEmpty()]) {
  final bloc = MockCartBloc();
  whenListen(bloc, Stream<CartState>.value(state), initialState: state);
  return bloc;
}

/// An address list pinned to [state], for a test that only needs one in the
/// tree. Mirrors [stubCartBloc].
MockAddressListBloc stubAddressListBloc(AddressListState state) {
  final bloc = MockAddressListBloc();
  whenListen(bloc, Stream<AddressListState>.value(state), initialState: state);
  when(bloc.close).thenAnswer((_) async {});
  return bloc;
}

/// An address form bloc pinned to [state], idle unless a test is exercising a
/// save.
MockAddressFormBloc stubAddressFormBloc([
  AddressFormState state = const AddressFormIdle(),
]) {
  final bloc = MockAddressFormBloc();
  whenListen(bloc, Stream<AddressFormState>.value(state), initialState: state);
  when(bloc.close).thenAnswer((_) async {});
  return bloc;
}

/// Registers inert stand-ins for the blocs screens resolve from the container
/// themselves.
///
/// Any test that renders whatever route the guard lands on needs these: a screen
/// that calls `sl<SomeBloc>()` in `build` throws before a single routing
/// assertion is reached, and the failure reads as a GetIt error rather than
/// anything about routing. Registering them centrally means adding a screen that
/// resolves its own bloc breaks one file, not every navigation suite.
void registerScreenBlocs() {
  void put<T extends Object>(T Function() create) {
    if (sl.isRegistered<T>()) sl.unregister<T>();
    sl.registerFactory<T>(create);
  }

  put<SignInBloc>(() {
    final bloc = _MockSignInBloc();
    whenListen(
      bloc,
      Stream<SignInState>.value(const SignInIdle()),
      initialState: const SignInIdle(),
    );
    return bloc;
  });

  put<SearchBloc>(() {
    final bloc = _MockSearchBloc();
    // Idle, not Loading, for the same reason Home is pinned to Empty: a
    // spinner animates forever and `pumpAndSettle` would time out.
    whenListen(
      bloc,
      Stream<SearchState>.value(const SearchIdle()),
      initialState: const SearchIdle(),
    );
    return bloc;
  });

  put<AddressListBloc>(() {
    final bloc = MockAddressListBloc();
    // Empty, not Loading: a spinner animates forever, so a navigation test
    // ending in pumpAndSettle would time out instead of asserting.
    whenListen(
      bloc,
      Stream<AddressListState>.value(const AddressListEmpty()),
      initialState: const AddressListEmpty(),
    );
    // Both address screens provide their bloc with `create:`, so the provider
    // closes it on dispose and an unstubbed close() breaks the widget tree's
    // finalisation.
    when(bloc.close).thenAnswer((_) async {});
    return bloc;
  });

  put<AddressFormBloc>(() {
    final bloc = MockAddressFormBloc();
    whenListen(
      bloc,
      Stream<AddressFormState>.value(const AddressFormIdle()),
      initialState: const AddressFormIdle(),
    );
    when(bloc.close).thenAnswer((_) async {});
    return bloc;
  });

  // The categories tab's root is the product listing now, not a placeholder, so
  // every navigation suite reaches this one.
  put<ProductListBloc>(() {
    final bloc = _MockProductListBloc();
    whenListen(
      bloc,
      Stream<ProductListState>.value(const ProductListEmpty()),
      initialState: const ProductListEmpty(),
    );
    return bloc;
  });

  // The orders row is a real screen now — the last PlaceholderTab in the app
  // is gone — so every navigation suite that opens it reaches this.
  put<OrdersBloc>(() {
    final bloc = _MockOrdersBloc();
    // Empty, not Loading: a spinner animates forever and a navigation test
    // ending in pumpAndSettle would time out instead of asserting.
    whenListen(
      bloc,
      Stream<OrdersState>.value(const OrdersEmpty()),
      initialState: const OrdersEmpty(),
    );
    // Provided with `create:`, so the provider closes it on dispose.
    when(bloc.close).thenAnswer((_) async {});
    return bloc;
  });

  // The account menu's notifications row is a real screen now, so every
  // navigation suite that opens it reaches this.
  put<NotificationPreferencesBloc>(() {
    final bloc = _MockNotificationPreferencesBloc();
    whenListen(
      bloc,
      Stream<NotificationPreferencesState>.value(
        const NotificationPreferencesUnresolved(),
      ),
      initialState: const NotificationPreferencesUnresolved(),
    );
    // Provided with `create:`, so the provider closes it on dispose.
    when(bloc.close).thenAnswer((_) async {});
    return bloc;
  });

  put<HomeBloc>(() {
    final bloc = _MockHomeBloc();
    // HomeEmpty, not HomeLoading: a spinner animates forever, so a navigation
    // test that ends in `pumpAndSettle` would time out instead of asserting.
    // These suites care where the router lands, not what Home is showing.
    whenListen(
      bloc,
      Stream<HomeState>.value(const HomeEmpty()),
      initialState: const HomeEmpty(),
    );
    return bloc;
  });
}

/// Undoes [registerScreenBlocs]. Call from `tearDown`.
void unregisterScreenBlocs() {
  if (sl.isRegistered<SignInBloc>()) sl.unregister<SignInBloc>();
  if (sl.isRegistered<HomeBloc>()) sl.unregister<HomeBloc>();
  if (sl.isRegistered<ProductListBloc>()) sl.unregister<ProductListBloc>();
  if (sl.isRegistered<NotificationPreferencesBloc>()) {
    sl.unregister<NotificationPreferencesBloc>();
  }
  if (sl.isRegistered<AddressListBloc>()) sl.unregister<AddressListBloc>();
  if (sl.isRegistered<AddressFormBloc>()) sl.unregister<AddressFormBloc>();
  if (sl.isRegistered<SearchBloc>()) sl.unregister<SearchBloc>();
  if (sl.isRegistered<OrdersBloc>()) sl.unregister<OrdersBloc>();
}
