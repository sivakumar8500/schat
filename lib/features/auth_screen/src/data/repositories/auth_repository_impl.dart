import 'package:flutter/foundation.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:injectable/injectable.dart';
import 'package:schat/core/network/api_result.dart';
import 'package:schat/core/network/api_service.dart';
import 'package:schat/core/notifications/call_notification_service.dart';
import 'package:schat/core/security/secure_attachment_service.dart';
import 'package:schat/core/storage/storage_service.dart';
import 'package:schat/features/auth_screen/src/data/models/send_otp_request.dart';
import 'package:schat/features/auth_screen/src/data/models/verify_otp_request.dart';
import 'package:schat/features/auth_screen/src/data/models/verify_otp_response.dart';
import 'package:schat/features/auth_screen/src/domain/repositories/auth_repository.dart';
import 'package:schat/features/chat_socket_screen/src/domain/chat_socket_repository.dart';
import 'package:schat/injection.dart';
import 'package:schat/utils/common_endpoints.dart';

@LazySingleton(as: AuthRepository)
class AuthRepositoryImpl implements AuthRepository {
  final ApiService _apiService;
  final StorageService _storageService;

  AuthRepositoryImpl(this._apiService, this._storageService);

  @override
  Future<ApiResult<bool>> sendOtp(String mobile, {String? appSignature}) async {
    final request = SendOtpRequest(phoneNumber: mobile, appSignature: appSignature);
    return _apiService.post<bool>(
      CommonEndpoints.sendOtp,
      data: request.toJson(),
      mapper: (json) {
        if (json is Map<String, dynamic>) {
          return json['success'] == true;
        }
        return false;
      },
    );
  }

  @override
  Future<ApiResult<bool>> verifyOtp(String mobile, String otp, String deviceId) async {
    final request = VerifyOtpRequest(
      phoneNumber: mobile,
      otp: otp,
      deviceId: deviceId,
    );

    final result = await _apiService.post<VerifyOtpResponse>(
      CommonEndpoints.verifyOtp,
      data: request.toJson(),
      mapper: (json) => VerifyOtpResponse.fromJson(json),
    );

    return result.when(
      success: (response) async {
        await _storageService.saveTokens(
          accessToken: response.accessToken,
          refreshToken: response.refreshToken,
        );
        // Register the device for push notifications now that we have tokens
        getIt<CallNotificationService>().registerDevice();
        return ApiResult.success(true);
      },
      failure: (message, statusCode) => ApiResult.failure(message, statusCode: statusCode),
    );
  }

  @override
  Future<void> logout() async {
    try {
      // 1. Call Backend Logout API: POST /api/v1/auth/logout with Bearer token
      // This unregisters device tokens on the server to immediately stop calls and notifications.
      await _apiService.post<dynamic>(
        CommonEndpoints.logout,
        data: {},
        mapper: (_) => null,
      );
    } catch (e) {
      debugPrint('AuthRepositoryImpl: Logout API error: $e');
    }

    try {
      // 2. Disconnect socket connection
      if (getIt.isRegistered<ChatSocketRepository>()) {
        getIt<ChatSocketRepository>().disconnect();
      }
    } catch (e) {
      debugPrint('AuthRepositoryImpl: Socket disconnect error: $e');
    }

    try {
      // 3. Terminate active CallKit & WebRTC calls
      await FlutterCallkitIncoming.endAllCalls();
    } catch (e) {
      debugPrint('AuthRepositoryImpl: End calls error: $e');
    }

    try {
      // 4. Wipe encrypted attachments
      await getIt<SecureAttachmentService>().clearAllEncryptedData();
    } catch (e) {
      debugPrint('AuthRepositoryImpl: Error clearing encrypted data: $e');
    }

    // 5. Clear stored tokens and user details
    await _storageService.clearTokens();
    await _storageService.clearUser();
    await Future.delayed(const Duration(milliseconds: 300));
  }
}

