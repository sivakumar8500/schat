import 'dart:convert';
import 'dart:developer';
import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:schat/core/services/session_manager_service.dart';
import 'package:schat/core/storage/storage_service.dart';
import 'package:schat/injection.dart';

@injectable
class ApiInterceptor extends Interceptor {
  final StorageService _storageService;

  ApiInterceptor(this._storageService);

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = _storageService.getAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    log('--------------------------');
    log('API Request: ${options.method}');
    log('---------------------------');
    log('api --->: ${options.baseUrl}${options.path}');
    log('body ---->: ${jsonEncode(options.data ?? {})}');

    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    log('responce ----->: ${jsonEncode(response.data ?? {})}');
    log('----------------------------------');
    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    log('ERROR[${err.response?.statusCode}]');
    log('responce ----->: ${jsonEncode(err.response?.data ?? {})}');
    log('----------------------------------');

    final statusCode = err.response?.statusCode;
    final path = err.requestOptions.path.toLowerCase();

    // Auxiliary endpoints or sub-features (e.g. screen permissions, locked chats check,
    // push token registration, media grants, chat transfer target views) must NEVER cause
    // a global user logout if they return 401 or 403.
    final isExcludedEndpoint = path.contains('/auth/') ||
        path.contains('/screen-permission') ||
        path.contains('/lock') ||
        path.contains('/view-requests') ||
        path.contains('/target/') ||
        path.contains('/notifications/') ||
        path.contains('/tones') ||
        path.contains('/media/');

    // Only genuine 401 (Unauthorized) on core authenticated user/chat endpoints triggers logout.
    // 403 (Forbidden) is an access permission denial on a specific resource and must NEVER log the user out.
    if (statusCode == 401 &&
        _storageService.hasToken() &&
        !isExcludedEndpoint) {
      log('ApiInterceptor: 401 session unauthorized - logging out & navigating to login');
      getIt<SessionManagerService>().logoutAndRedirectToLogin(
        reason: 'Your session has expired or your account was logged in on another device.',
      );
    }

    super.onError(err, handler);
  }
}
