import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
// show Environment: injectable also exports a `test` constant, which shadows
// flutter_test's `test()` function in every file that needs both.
import 'package:injectable/injectable.dart' show Environment;
import 'package:nova_modest/core/di/injection.dart';
import 'package:nova_modest/core/network/api_client.dart';
import 'package:nova_modest/core/network/interceptors/auth_interceptor.dart';
import 'package:nova_modest/core/storage/token_storage.dart';
import 'package:nova_modest/features/address/domain/repositories/address_repository.dart';
import 'package:nova_modest/features/address/presentation/bloc/address_form_bloc.dart';
import 'package:nova_modest/features/address/presentation/bloc/address_list_bloc.dart';
import 'package:nova_modest/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:nova_modest/features/auth/domain/repositories/auth_repository.dart';
import 'package:nova_modest/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:nova_modest/features/auth/presentation/bloc/profile_edit_bloc.dart';
import 'package:nova_modest/features/auth/presentation/bloc/sign_in_bloc.dart';
import 'package:nova_modest/features/cart/domain/repositories/cart_repository.dart';
import 'package:nova_modest/features/cart/presentation/bloc/cart_bloc.dart';
import 'package:nova_modest/features/catalog/domain/repositories/catalog_repository.dart';
import 'package:nova_modest/features/catalog/domain/repositories/search_history_repository.dart';
import 'package:nova_modest/features/catalog/presentation/bloc/home_bloc.dart';
import 'package:nova_modest/features/catalog/presentation/bloc/product_detail_bloc.dart';
import 'package:nova_modest/features/catalog/presentation/bloc/product_list_bloc.dart';
import 'package:nova_modest/features/catalog/presentation/bloc/search_bloc.dart';
import 'package:nova_modest/features/orders/domain/repositories/order_repository.dart';
import 'package:nova_modest/features/checkout/presentation/bloc/checkout_bloc.dart';
import 'package:nova_modest/features/onboarding/domain/repositories/onboarding_repository.dart';
import 'package:nova_modest/features/onboarding/presentation/bloc/onboarding_bloc.dart';
import 'package:nova_modest/features/settings/domain/repositories/locale_repository.dart';
import 'package:nova_modest/features/settings/domain/repositories/notification_preferences_repository.dart';
import 'package:nova_modest/features/settings/presentation/bloc/locale_bloc.dart';
import 'package:nova_modest/features/orders/presentation/bloc/order_detail_bloc.dart';
import 'package:nova_modest/features/orders/presentation/bloc/orders_bloc.dart';
import 'package:nova_modest/features/settings/presentation/bloc/notification_preferences_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Exercises the **real** container, which nothing else in the suite does.
///
/// Every other test registers its own stand-in with `sl.registerFactory`, so a
/// missing `@injectable` annotation, a bloc whose file failed to regenerate, or
/// a dependency the generator could not resolve is invisible to all of them —
/// `flutter analyze` stays clean and 450-odd tests keep passing while the app
/// throws `GetIt: Object/factory with type X is not registered` on the device.
/// That happened twice in one session before this file existed.
///
/// Resolving a type is the assertion: `get_it` constructs it and every
/// dependency underneath, so a broken edge anywhere in the graph fails here.
void main() {
  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();

    // `SharedPreferences` is registered `@preResolve`, so `configureDependencies`
    // reads from disk before it returns and needs a backing store in a test.
    SharedPreferences.setMockInitialValues({});
    // `FlutterSecureStorage` is constructed eagerly by the storage module. It
    // only reaches the platform channel when a method is called, but the
    // handler is stubbed so a future eager read cannot turn this into a flake.
    FlutterSecureStorage.setMockInitialValues({});

    await configureDependencies(environment: Environment.test);
  });

  // The container is a process-wide singleton, so a leaked registration would
  // change what the next test sees.
  tearDown(() => sl.reset());

  /// Resolves [T] and reports which type failed rather than a bare exception.
  void resolves<T extends Object>() {
    expect(
      () => sl<T>(),
      returnsNormally,
      reason: '$T does not resolve from the real container',
    );
  }

  group('repositories and data sources', () {
    test('every one resolves', () {
      resolves<AddressRepository>();
      resolves<AuthRepository>();
      resolves<AuthRemoteDataSource>();
      resolves<CartRepository>();
      resolves<CatalogRepository>();
      resolves<OnboardingRepository>();
      resolves<SearchHistoryRepository>();
      resolves<LocaleRepository>();
      resolves<OrderRepository>();
      resolves<NotificationPreferencesRepository>();
    });
  });

  group('infrastructure', () {
    test('storage and networking resolve', () {
      resolves<SharedPreferences>();
      resolves<FlutterSecureStorage>();
      resolves<TokenStorage>();
      resolves<Dio>();
      resolves<ApiClient>();
      resolves<AuthInterceptor>();
    });
  });

  group('blocs the screens ask the container for', () {
    test('app-wide singletons resolve', () {
      resolves<AuthBloc>();
      resolves<OnboardingBloc>();
      resolves<CartBloc>();
      // MaterialApp reads this one on every build, which is why it is a
      // singleton while its neighbour NotificationPreferencesBloc is not.
      resolves<LocaleBloc>();
    });

    test('screen-scoped factories resolve', () {
      // The two that shipped broken on the device were AddressListBloc and,
      // before it, the account routes' localisation tear-offs.
      resolves<AddressListBloc>();
      resolves<AddressFormBloc>();
      resolves<HomeBloc>();
      resolves<ProductListBloc>();
      resolves<ProductDetailBloc>();
      resolves<SearchBloc>();
      resolves<SignInBloc>();
      resolves<ProfileEditBloc>();
      resolves<NotificationPreferencesBloc>();
      resolves<OrdersBloc>();
      resolves<OrderDetailBloc>();
      resolves<CheckoutBloc>();
    });
  });

  group('scope', () {
    test('a factory hands out a new instance each time', () {
      // Two products opened in sequence must not share a size or a quantity,
      // which is why these are factories and not singletons
      // (`01-flutter-architecture-guard.md`).
      expect(sl<ProductDetailBloc>(), isNot(same(sl<ProductDetailBloc>())));
      expect(sl<AddressFormBloc>(), isNot(same(sl<AddressFormBloc>())));
    });

    test('an app-wide bloc is the same instance everywhere', () {
      // The router's guard reads AuthBloc and the navigation badge reads
      // CartBloc; a second instance of either would silently disagree with the
      // first.
      expect(sl<AuthBloc>(), same(sl<AuthBloc>()));
      expect(sl<CartBloc>(), same(sl<CartBloc>()));
    });
  });

  test('every registered type is covered by this file', () {
    // Reads the generated file rather than trusting a hand-kept number: the
    // list above drifted once already when the settings feature added four
    // registrations nothing here resolved, which is the exact gap this file
    // exists to close. A hardcoded count would have agreed with itself.
    final generated = File(
      'lib/core/di/injection.config.dart',
    ).readAsStringSync();
    final registered = RegExp(
      r'gh\.(?:factory|lazySingleton|singleton|factoryAsync|lazySingletonAsync)'
      r'<_i\d+\.(\w+)>',
    ).allMatches(generated).map((m) => m.group(1)!).toSet();

    final covered = RegExp(r'resolves<(\w+)>\(\)')
        .allMatches(File('test/core/di/injection_test.dart').readAsStringSync())
        .map((m) => m.group(1)!)
        .toSet();

    expect(
      registered.difference(covered),
      isEmpty,
      reason: 'these are registered but never resolved here',
    );
  });

  group('the fakes are what is wired', () {
    test(
      'the registered implementations are the stand-ins, not the HTTP ones',
      () {
        // Swapping a real backend in is meant to be one registration line. If
        // that ever happens by accident, this is where it shows.
        expect(
          sl<AuthRepository>().runtimeType.toString(),
          'FakeAuthRepository',
        );
        expect(
          sl<CatalogRepository>().runtimeType.toString(),
          'FakeCatalogRepository',
        );
        expect(
          sl<AddressRepository>().runtimeType.toString(),
          'FakeAddressRepository',
        );
        expect(
          sl<OrderRepository>().runtimeType.toString(),
          'FakeOrderRepository',
        );
      },
    );
  });
}
