import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'api_result.dart';

@lazySingleton
class ApiService {
  final Dio _dio;

  ApiService(this._dio);

  Future<ApiResult<T>> call<T>({
    required String path,
    required String method,
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    T Function(dynamic)? mapper,
  }) async {
    try {
      final response = await _dio.request(
        path,
        data: data,
        queryParameters: queryParameters,
        options: (options ?? Options()).copyWith(method: method),
      );

      if (response.data != null) {
        if (mapper != null) {
          return ApiResult.success(mapper(response.data));
        }
        return ApiResult.success(response.data as T);
      } else {
        return ApiResult.failure('Empty response');
      }
    } on DioException catch (e) {
      String errorMessage = 'Something went wrong';
      final statusCode = e.response?.statusCode;
      
      if (e.response?.data != null) {
        final data = e.response?.data;
        if (data is Map) {
          final detail = data['detail'];
          if (detail is String) {
            errorMessage = detail;
          } else if (detail is List && detail.isNotEmpty) {
            // Handle FastAPI validation errors which are often in detail list
            final firstError = detail.first;
            if (firstError is Map) {
              errorMessage = firstError['msg'] ?? firstError['message'] ?? e.message ?? 'Validation error';
            } else {
              errorMessage = firstError.toString();
            }
          } else {
            errorMessage = data['message'] ?? data['error'] ?? data['msg'] ?? e.message ?? 'Something went wrong';
          }
        } else if (data is String) {
          errorMessage = data;
        } else {
          errorMessage = e.message ?? 'Something went wrong';
        }
      } else if (e.type == DioExceptionType.connectionTimeout) {
        errorMessage = 'Connection timeout. Please check your internet.';
      } else if (e.type == DioExceptionType.receiveTimeout) {
        errorMessage = 'Server is taking too long to respond.';
      } else {
        errorMessage = e.message ?? 'Something went wrong';
      }
      
      return ApiResult.failure(errorMessage, statusCode: statusCode);
    } catch (e) {
      return ApiResult.failure(e.toString());
    }
  }
}

extension ApiServiceExtensions on ApiService {
  Future<ApiResult<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    T Function(dynamic)? mapper,
  }) =>
      call(
        path: path,
        method: 'GET',
        queryParameters: queryParameters,
        mapper: mapper,
      );

  Future<ApiResult<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    T Function(dynamic)? mapper,
  }) =>
      call(
        path: path,
        method: 'POST',
        data: data,
        queryParameters: queryParameters,
        mapper: mapper,
      );

  Future<ApiResult<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    T Function(dynamic)? mapper,
  }) =>
      call(
        path: path,
        method: 'PUT',
        data: data,
        queryParameters: queryParameters,
        mapper: mapper,
      );

  Future<ApiResult<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    T Function(dynamic)? mapper,
  }) =>
      call(
        path: path,
        method: 'PATCH',
        data: data,
        queryParameters: queryParameters,
        mapper: mapper,
      );

  Future<ApiResult<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    T Function(dynamic)? mapper,
  }) =>
      call(
        path: path,
        method: 'DELETE',
        data: data,
        queryParameters: queryParameters,
        mapper: mapper,
      );
}
