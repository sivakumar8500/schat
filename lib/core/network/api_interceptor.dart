import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:schat/core/storage/storage_service.dart';

@injectable
class ApiInterceptor extends Interceptor {
  final StorageService _storageService;

  ApiInterceptor(this._storageService);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = _storageService.getAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    
    debugPrint('--------------------------');
    debugPrint('API Request: ${options.method}');
    debugPrint('---------------------------');
    debugPrint('api --->: ${options.baseUrl}${options.path}');
    debugPrint('body ---->: ${jsonEncode(options.data ?? {})}');
    
    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    debugPrint('responce ----->: ${jsonEncode(response.data ?? {})}');
    debugPrint('----------------------------------');
    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    debugPrint('ERROR[${err.response?.statusCode}]');
    debugPrint('responce ----->: ${jsonEncode(err.response?.data ?? {})}');
    debugPrint('----------------------------------');
    super.onError(err, handler);
  }
}

