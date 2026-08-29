// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:dio/dio.dart' as _i361;
import 'package:flutter_secure_storage/flutter_secure_storage.dart' as _i558;
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;
import 'package:nova_modest/core/network/api_client.dart' as _i401;
import 'package:nova_modest/core/network/dio_api_client.dart' as _i742;
import 'package:nova_modest/core/network/interceptors/auth_interceptor.dart'
    as _i453;
import 'package:nova_modest/core/network/network_module.dart' as _i91;
import 'package:nova_modest/core/storage/preferences_module.dart' as _i373;
import 'package:nova_modest/core/storage/storage_module.dart' as _i297;
import 'package:nova_modest/core/storage/token_storage.dart' as _i780;
import 'package:nova_modest/features/address/data/repositories/fake_address_repository.dart'
    as _i577;
import 'package:nova_modest/features/address/data/repositories/supabase_address_repository.dart'
    as _i1101;
import 'package:nova_modest/features/address/domain/repositories/address_repository.dart'
    as _i1039;
import 'package:nova_modest/features/address/presentation/bloc/address_form_bloc.dart'
    as _i35;
import 'package:nova_modest/features/address/presentation/bloc/address_list_bloc.dart'
    as _i512;
import 'package:nova_modest/features/auth/data/datasources/auth_remote_datasource.dart'
    as _i125;
import 'package:nova_modest/features/auth/data/repositories/fake_auth_repository.dart'
    as _i192;
import 'package:nova_modest/features/auth/data/repositories/supabase_auth_repository.dart'
    as _i1102;
import 'package:nova_modest/features/auth/domain/repositories/auth_repository.dart'
    as _i643;
import 'package:nova_modest/features/auth/presentation/bloc/auth_bloc.dart'
    as _i795;
import 'package:nova_modest/features/auth/presentation/bloc/profile_edit_bloc.dart'
    as _i703;
import 'package:nova_modest/features/auth/presentation/bloc/sign_in_bloc.dart'
    as _i129;
import 'package:nova_modest/features/cart/data/repositories/cart_repository_impl.dart'
    as _i290;
import 'package:nova_modest/features/cart/domain/repositories/cart_repository.dart'
    as _i866;
import 'package:nova_modest/features/cart/presentation/bloc/cart_bloc.dart'
    as _i776;
import 'package:nova_modest/features/catalog/data/repositories/fake_catalog_repository.dart'
    as _i623;
import 'package:nova_modest/features/catalog/data/repositories/supabase_catalog_repository.dart'
    as _i1103;
import 'package:nova_modest/features/catalog/data/repositories/search_history_repository_impl.dart'
    as _i448;
import 'package:nova_modest/features/catalog/domain/repositories/catalog_repository.dart'
    as _i479;
import 'package:nova_modest/features/catalog/domain/repositories/search_history_repository.dart'
    as _i666;
import 'package:nova_modest/features/catalog/presentation/bloc/home_bloc.dart'
    as _i661;
import 'package:nova_modest/features/catalog/presentation/bloc/product_detail_bloc.dart'
    as _i838;
import 'package:nova_modest/features/catalog/presentation/bloc/product_list_bloc.dart'
    as _i840;
import 'package:nova_modest/features/catalog/presentation/bloc/search_bloc.dart'
    as _i1072;
import 'package:nova_modest/features/checkout/data/repositories/fake_order_repository.dart'
    as _i753;
import 'package:nova_modest/features/checkout/data/repositories/supabase_order_repository.dart'
    as _i1104;
import 'package:nova_modest/features/checkout/domain/repositories/order_repository.dart'
    as _i146;
import 'package:nova_modest/features/checkout/presentation/bloc/checkout_bloc.dart'
    as _i1012;
import 'package:nova_modest/features/onboarding/data/repositories/onboarding_repository_impl.dart'
    as _i4;
import 'package:nova_modest/features/onboarding/domain/repositories/onboarding_repository.dart'
    as _i835;
import 'package:nova_modest/features/onboarding/presentation/bloc/onboarding_bloc.dart'
    as _i267;
import 'package:nova_modest/features/settings/data/repositories/locale_repository_impl.dart'
    as _i147;
import 'package:nova_modest/features/settings/data/repositories/notification_preferences_repository_impl.dart'
    as _i410;
import 'package:nova_modest/features/settings/domain/repositories/locale_repository.dart'
    as _i1022;
import 'package:nova_modest/features/settings/domain/repositories/notification_preferences_repository.dart'
    as _i247;
import 'package:nova_modest/features/settings/presentation/bloc/locale_bloc.dart'
    as _i1059;
import 'package:nova_modest/features/settings/presentation/bloc/notification_preferences_bloc.dart'
    as _i913;
import 'package:shared_preferences/shared_preferences.dart' as _i460;

extension GetItInjectableX on _i174.GetIt {
  // initializes the registration of main-scope dependencies inside of GetIt
  Future<_i174.GetIt> init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) async {
    final gh = _i526.GetItHelper(this, environment, environmentFilter);
    final preferencesModule = _$PreferencesModule();
    final storageModule = _$StorageModule();
    final networkModule = _$NetworkModule();
    await gh.factoryAsync<_i460.SharedPreferences>(
      () => preferencesModule.preferences,
      preResolve: true,
    );
    gh.lazySingleton<_i558.FlutterSecureStorage>(
      () => storageModule.secureStorage,
    );
    gh.lazySingleton<_i1039.AddressRepository>(
      () => _i577.FakeAddressRepository(),
      registerFor: {'test'},
    );
    gh.lazySingleton<_i1039.AddressRepository>(
      () => const _i1101.SupabaseAddressRepository(),
      registerFor: {'dev'},
    );
    gh.lazySingleton<_i780.TokenStorage>(
      () => _i780.SecureTokenStorage(gh<_i558.FlutterSecureStorage>()),
    );
    gh.lazySingleton<_i643.AuthRepository>(
      () => _i192.FakeAuthRepository(gh<_i780.TokenStorage>()),
      registerFor: {'test'},
    );
    gh.lazySingleton<_i643.AuthRepository>(
      () => _i1102.SupabaseAuthRepository(),
      registerFor: {'dev'},
    );
    gh.factory<_i35.AddressFormBloc>(
      () => _i35.AddressFormBloc(gh<_i1039.AddressRepository>()),
    );
    gh.factory<_i512.AddressListBloc>(
      () => _i512.AddressListBloc(gh<_i1039.AddressRepository>()),
    );
    gh.lazySingleton<_i146.OrderRepository>(
      () => _i753.FakeOrderRepository(),
      registerFor: {'test'},
    );
    gh.lazySingleton<_i146.OrderRepository>(
      () => const _i1104.SupabaseOrderRepository(),
      registerFor: {'dev'},
    );
    gh.lazySingleton<_i666.SearchHistoryRepository>(
      () => _i448.SearchHistoryRepositoryImpl(gh<_i460.SharedPreferences>()),
    );
    gh.lazySingleton<_i835.OnboardingRepository>(
      () => _i4.OnboardingRepositoryImpl(gh<_i460.SharedPreferences>()),
    );
    gh.lazySingleton<_i247.NotificationPreferencesRepository>(
      () => _i410.NotificationPreferencesRepositoryImpl(
        gh<_i460.SharedPreferences>(),
      ),
    );
    gh.lazySingleton<_i1022.LocaleRepository>(
      () => _i147.LocaleRepositoryImpl(gh<_i460.SharedPreferences>()),
    );
    gh.lazySingleton<_i479.CatalogRepository>(
      () => const _i623.FakeCatalogRepository(),
      registerFor: {'test'},
    );
    gh.lazySingleton<_i479.CatalogRepository>(
      () => const _i1103.SupabaseCatalogRepository(),
      registerFor: {'dev'},
    );
    gh.lazySingleton<_i866.CartRepository>(
      () => _i290.CartRepositoryImpl(
        gh<_i460.SharedPreferences>(),
        gh<_i479.CatalogRepository>(),
      ),
    );
    gh.factory<_i913.NotificationPreferencesBloc>(
      () => _i913.NotificationPreferencesBloc(
        gh<_i247.NotificationPreferencesRepository>(),
      ),
    );
    gh.factory<_i1072.SearchBloc>(
      () => _i1072.SearchBloc(
        gh<_i479.CatalogRepository>(),
        gh<_i666.SearchHistoryRepository>(),
      ),
    );
    gh.factory<_i1012.CheckoutBloc>(
      () => _i1012.CheckoutBloc(gh<_i146.OrderRepository>()),
    );
    gh.lazySingleton<_i776.CartBloc>(
      () => _i776.CartBloc(gh<_i866.CartRepository>()),
    );
    gh.lazySingleton<_i453.AuthInterceptor>(
      () => networkModule.authInterceptor(gh<_i780.TokenStorage>()),
    );
    gh.lazySingleton<_i795.AuthBloc>(
      () => _i795.AuthBloc(gh<_i643.AuthRepository>()),
    );
    gh.factory<_i703.ProfileEditBloc>(
      () => _i703.ProfileEditBloc(gh<_i643.AuthRepository>()),
    );
    gh.factory<_i129.SignInBloc>(
      () => _i129.SignInBloc(gh<_i643.AuthRepository>()),
    );
    gh.lazySingleton<_i1059.LocaleBloc>(
      () => _i1059.LocaleBloc(gh<_i1022.LocaleRepository>()),
    );
    gh.factory<_i661.HomeBloc>(
      () => _i661.HomeBloc(gh<_i479.CatalogRepository>()),
    );
    gh.factory<_i838.ProductDetailBloc>(
      () => _i838.ProductDetailBloc(gh<_i479.CatalogRepository>()),
    );
    gh.factory<_i840.ProductListBloc>(
      () => _i840.ProductListBloc(gh<_i479.CatalogRepository>()),
    );
    gh.lazySingleton<_i267.OnboardingBloc>(
      () => _i267.OnboardingBloc(gh<_i835.OnboardingRepository>()),
    );
    gh.lazySingleton<_i361.Dio>(
      () => networkModule.dio(gh<_i453.AuthInterceptor>()),
    );
    gh.lazySingleton<_i401.ApiClient>(
      () => _i742.DioApiClient(gh<_i361.Dio>()),
    );
    gh.lazySingleton<_i125.AuthRemoteDataSource>(
      () => _i125.AuthRemoteDataSourceImpl(gh<_i401.ApiClient>()),
    );
    return this;
  }
}

class _$PreferencesModule extends _i373.PreferencesModule {}

class _$StorageModule extends _i297.StorageModule {}

class _$NetworkModule extends _i91.NetworkModule {}
