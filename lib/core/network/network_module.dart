import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:schat/utils/common_endpoints.dart';
import 'api_interceptor.dart';

@module
abstract class NetworkModule {
  @lazySingleton
  Connectivity get connectivity => Connectivity();

  @lazySingleton
  Dio getDio(ApiInterceptor apiInterceptor) {
    final dio = Dio(
      BaseOptions(
        baseUrl: CommonEndpoints.baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    dio.interceptors.add(apiInterceptor);

    dio.interceptors.add(LogInterceptor(
      request: true,
      requestHeader: true,
      requestBody: true,
      responseHeader: true,
      responseBody: true,
      error: true,
    ));

    return dio;
  }
}
