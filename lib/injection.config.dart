// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:connectivity_plus/connectivity_plus.dart' as _i895;
import 'package:dio/dio.dart' as _i361;
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;

import 'core/network/api_interceptor.dart' as _i729;
import 'core/network/api_service.dart' as _i374;
import 'core/network/connectivity_repository.dart' as _i232;
import 'core/network/network_module.dart' as _i550;
import 'core/storage/storage_service.dart' as _i263;
import 'features/auth_screen/src/data/repositories/auth_repository_impl.dart'
    as _i299;
import 'features/auth_screen/src/domain/repositories/auth_repository.dart'
    as _i939;
import 'features/chat_screen/src/data/repositories/chat_repository_impl.dart'
    as _i715;
import 'features/chat_screen/src/domain/repositories/chat_repository.dart'
    as _i649;
import 'features/connectivity/src/presentation/bloc/connectivity_bloc.dart'
    as _i201;
import 'features/dashboard_screen/src/data/repositories/chat_repository_impl.dart'
    as _i599;
import 'features/dashboard_screen/src/domain/repositories/chat_repository.dart'
    as _i908;
import 'features/dashboard_screen/src/domain/repositories/contacts_repository.dart'
    as _i1069;
import 'features/dashboard_screen/src/domain/usecases/get_chats_usecase.dart'
    as _i127;
import 'features/dashboard_screen/src/presentation/bloc/chats_bloc.dart'
    as _i236;
import 'features/payment_screen/src/data/repositories/payment_repository_impl.dart'
    as _i39;
import 'features/payment_screen/src/domain/repositories/payment_repository.dart'
    as _i466;
import 'features/profile_screen/src/data/repositories/profile_repository_impl.dart'
    as _i67;
import 'features/profile_screen/src/domain/repositories/profile_repository.dart'
    as _i651;
import 'features/status_screen/src/data/repositories/status_repository_impl.dart'
    as _i769;
import 'features/status_screen/src/domain/repositories/status_repository.dart'
    as _i906;
import 'features/subscription_screen/src/data/repositories/subscription_repository_impl.dart'
    as _i819;
import 'features/subscription_screen/src/domain/repositories/subscription_repository.dart'
    as _i702;

extension GetItInjectableX on _i174.GetIt {
  // initializes the registration of main-scope dependencies inside of GetIt
  _i174.GetIt init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) {
    final gh = _i526.GetItHelper(this, environment, environmentFilter);
    final networkModule = _$NetworkModule();
    gh.lazySingleton<_i895.Connectivity>((() => networkModule.connectivity));
    gh.lazySingleton<_i263.StorageService>((() => _i263.StorageService()));
    gh.lazySingleton<_i466.PaymentRepository>(
        (() => _i39.PaymentRepositoryImpl()));
    gh.lazySingleton<_i906.StatusRepository>(
        (() => _i769.StatusRepositoryImpl()));
    gh.lazySingleton<_i649.ChatRepository>((() => _i715.ChatRepositoryImpl()));
    gh.lazySingleton<_i232.ConnectivityRepository>(
        (() => _i232.ConnectivityRepositoryImpl(gh<_i895.Connectivity>())));
    gh.factory<_i729.ApiInterceptor>(
        (() => _i729.ApiInterceptor(gh<_i263.StorageService>())));
    gh.lazySingleton<_i361.Dio>(
        (() => networkModule.getDio(gh<_i729.ApiInterceptor>())));
    gh.factory<_i201.ConnectivityBloc>(
        (() => _i201.ConnectivityBloc(gh<_i232.ConnectivityRepository>())));
    gh.lazySingleton<_i374.ApiService>((() => _i374.ApiService(gh<_i361.Dio>())));
    gh.lazySingleton<_i939.AuthRepository>((() => _i299.AuthRepositoryImpl(
        gh<_i374.ApiService>(), gh<_i263.StorageService>())));
    gh.lazySingleton<_i651.ProfileRepository>(
        (() => _i67.ProfileRepositoryImpl(gh<_i374.ApiService>())));
    gh.lazySingleton<_i702.SubscriptionRepository>(
        (() => _i819.SubscriptionRepositoryImpl(gh<_i374.ApiService>())));
    gh.lazySingleton<_i1069.ContactsRepository>(
        (() => _i1069.ContactsRepositoryImpl(gh<_i374.ApiService>())));
    gh.lazySingleton<_i908.ChatRepository>(
        (() => _i599.ChatRepositoryImpl(gh<_i374.ApiService>())));
    gh.lazySingleton<_i127.GetChatsUseCase>(
        (() => _i127.GetChatsUseCase(gh<_i908.ChatRepository>())));
    gh.factory<_i236.ChatsBloc>((() => _i236.ChatsBloc(
        gh<_i127.GetChatsUseCase>(), gh<_i908.ChatRepository>())));
    return this;
  }
}

class _$NetworkModule extends _i550.NetworkModule {}
