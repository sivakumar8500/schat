import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:schat/core/network/api_service.dart';
import 'package:schat/core/storage/storage_service.dart';
import 'package:schat/features/tones/data/models/tone_model.dart';
import 'package:schat/utils/common_endpoints.dart';

@lazySingleton
class ToneApiService {
  final ApiService _apiService;
  final StorageService _storageService;

  ToneApiService(this._apiService, this._storageService);

  /// 1. List available tones (optionally filtered by type)
  /// GET /api/v1/tones?tone_type=CALL or MESSAGE
  Future<List<Tone>> getAvailableTones({ToneType? type}) async {
    final queryParams = <String, dynamic>{};
    if (type != null) {
      queryParams['tone_type'] = type == ToneType.CALL ? 'CALL' : 'MESSAGE';
    }

    final result = await _apiService.get<dynamic>(
      CommonEndpoints.getTones,
      queryParameters: queryParams,
    );

    return result.when(
      success: (data) {
        if (data is List) {
          return data
              .map((item) => Tone.fromJson(Map<String, dynamic>.from(item as Map)))
              .toList();
        }
        return <Tone>[];
      },
      failure: (message, statusCode) {
        debugPrint('ToneApiService: Failed to fetch available tones: $message');
        return <Tone>[];
      },
    );
  }

  /// 2. Get current user's active call ringtone & message tone
  /// GET /api/v1/tones/me
  Future<UserTonesPreference?> getMyTones() async {
    final result = await _apiService.get<dynamic>(
      CommonEndpoints.myTones,
    );

    return result.when(
      success: (data) {
        if (data is Map) {
          final pref = UserTonesPreference.fromJson(Map<String, dynamic>.from(data));
          _cacheUserTones(pref);
          return pref;
        }
        return null;
      },
      failure: (message, statusCode) {
        debugPrint('ToneApiService: Failed to fetch user tones: $message');
        return null;
      },
    );
  }

  /// 3. Update current user's active call ringtone and/or message tone
  /// PUT /api/v1/tones/me
  Future<UserTonesPreference?> updateMyTones({
    String? callRingtoneId,
    String? messageToneId,
  }) async {
    final payload = <String, dynamic>{};
    if (callRingtoneId != null) {
      payload['call_ringtone_id'] = callRingtoneId;
    }
    if (messageToneId != null) {
      payload['message_tone_id'] = messageToneId;
    }

    final result = await _apiService.put<dynamic>(
      CommonEndpoints.myTones,
      data: payload,
    );

    return result.when(
      success: (data) {
        if (data is Map) {
          final pref = UserTonesPreference.fromJson(Map<String, dynamic>.from(data));
          _cacheUserTones(pref);
          return pref;
        }
        return null;
      },
      failure: (message, statusCode) {
        debugPrint('ToneApiService: Failed to update user tones: $message');
        return null;
      },
    );
  }

  /// 4. Reset user's tones back to system defaults
  /// DELETE /api/v1/tones/me
  Future<UserTonesPreference?> resetMyTones() async {
    final result = await _apiService.delete<dynamic>(
      CommonEndpoints.myTones,
    );

    return result.when(
      success: (data) {
        if (data is Map) {
          final pref = UserTonesPreference.fromJson(Map<String, dynamic>.from(data));
          _cacheUserTones(pref);
          return pref;
        }
        return null;
      },
      failure: (message, statusCode) {
        debugPrint('ToneApiService: Failed to reset user tones: $message');
        return null;
      },
    );
  }

  void _cacheUserTones(UserTonesPreference pref) {
    if (pref.callRingtone != null) {
      _storageService.saveCallRingtone(
        name: pref.callRingtone!.name,
        url: pref.callRingtone!.fileUrl,
      );
    }
    if (pref.messageTone != null) {
      _storageService.saveMessageTone(
        name: pref.messageTone!.name,
        url: pref.messageTone!.fileUrl,
      );
    }
  }
}
