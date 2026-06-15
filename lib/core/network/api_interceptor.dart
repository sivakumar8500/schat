import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:schat/core/storage/storage_service.dart';

@injectable
class ApiInterceptor extends Interceptor {
  final StorageService _storageService;

  ApiInterceptor(this._storageService);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await _storageService.getAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    
    print('--------------------------');
    print('API Request: ${options.method}');
    print('---------------------------');
    print('api --->: ${options.baseUrl}${options.path}');
    print('body ---->: ${jsonEncode(options.data ?? {})}');
    
    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    print('responce ----->: ${jsonEncode(response.data ?? {})}');
    print('----------------------------------');
    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    print('ERROR[${err.response?.statusCode}]');
    print('responce ----->: ${jsonEncode(err.response?.data ?? {})}');
    print('----------------------------------');
    super.onError(err, handler);
  }
}
