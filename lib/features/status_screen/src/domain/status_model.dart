import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter/material.dart';
import 'package:schat/core/storage/storage_service.dart';
import 'package:schat/injection.dart';
import 'package:schat/utils/common_endpoints.dart';

part 'status_model.freezed.dart';
part 'status_model.g.dart';

@freezed
abstract class StatusItemModel with _$StatusItemModel {
  const StatusItemModel._();
  const factory StatusItemModel({
    required String id,
    @JsonKey(name: 'userId') String? userId,
    @JsonKey(name: 'statusType') String? statusType,
    @JsonKey(name: 'textContent') String? text,
    @JsonKey(name: 'mediaUrl') String? imagePath,
    @JsonKey(name: 'textColor') String? textColor,
    @JsonKey(name: 'createdAt') required DateTime timestamp,
    @JsonKey(name: 'expiresAt') DateTime? expiresAt,
    @JsonKey(name: 'viewCount', defaultValue: 0) int? viewCount,
    @JsonKey(name: 'viewers', includeToJson: false) @Default([]) List<StatusViewerModel> viewers,
    @JsonKey(name: 'privacyType') String? privacyType,
    @JsonKey(name: 'privacyUserIds') List<String>? privacyUserIds,
    @JsonKey(includeFromJson: false, includeToJson: false) @Default(Colors.black) Color backgroundColor,
    @JsonKey(name: 'viewed', defaultValue: false) @Default(false) bool viewed,
  }) = _StatusItemModel;

  factory StatusItemModel.fromJson(Map<String, dynamic> json) => _$StatusItemModelFromJson(_normalizeStatusItemJson(json));

  Color get parsedBackgroundColor {
    if (textColor != null && textColor!.isNotEmpty) {
      try {
        String hex = textColor!.replaceAll('#', '');
        if (hex.length == 6) hex = 'FF$hex';
        return Color(int.parse(hex, radix: 16));
      } catch (_) {}
    }
    return backgroundColor != Colors.black ? backgroundColor : const Color(0xFF4A148C);
  }
}

Map<String, dynamic> _normalizeStatusItemJson(Map<String, dynamic> json) {
  final map = Map<String, dynamic>.from(json);
  final id = (json['id'] ?? json['_id'] ?? json['status_id'])?.toString() ?? '';
  map['id'] = id;
  map['textContent'] = json['textContent'] ?? json['text_content'] ?? json['text'];

  dynamic rawMedia = json['mediaUrl'] ?? json['media_url'] ?? json['media'] ?? json['fileUrl'] ?? json['file_url'] ?? json['url'];
  if (rawMedia is Map) {
    rawMedia = rawMedia['url'] ?? rawMedia['mediaUrl'] ?? rawMedia['media_url'];
  }
  if (rawMedia != null && rawMedia.toString().isNotEmpty) {
    String mediaStr = rawMedia.toString();
    if (mediaStr.startsWith('/')) {
      mediaStr = '${CommonEndpoints.baseUrl}$mediaStr';
    }
    map['mediaUrl'] = mediaStr;
  } else {
    map['mediaUrl'] = null;
  }

  map['textColor'] = json['textColor'] ?? json['text_color'];

  final rawCreatedAt = json['createdAt'] ?? json['created_at'];
  map['createdAt'] = _safeToIso8601String(rawCreatedAt);

  if (json['expiresAt'] != null || json['expires_at'] != null) {
    final rawExpiresAt = json['expiresAt'] ?? json['expires_at'];
    map['expiresAt'] = _safeToIso8601String(rawExpiresAt);
  }

  // Parse viewed state from backend or local cache
  bool isViewed = json['viewed'] == true ||
      json['isViewed'] == true ||
      json['is_viewed'] == true ||
      json['seen'] == true ||
      json['isSeen'] == true ||
      json['is_seen'] == true;

  try {
    final myUserId = getIt<StorageService>().getUserId();
    if (!isViewed && myUserId != null && myUserId.isNotEmpty) {
      final rawViewers = json['viewers'] ?? json['viewer_ids'] ?? json['views'];
      if (rawViewers is List) {
        isViewed = rawViewers.any((v) {
          if (v is Map) {
            final vId = (v['viewerId'] ?? v['id'] ?? v['userId'] ?? v['user_id'])?.toString();
            return vId == myUserId;
          }
          return v.toString() == myUserId;
        });
      }
    }

    if (!isViewed && id.isNotEmpty) {
      isViewed = getIt<StorageService>().isStatusViewed(id);
    }
  } catch (_) {}

  map['viewed'] = isViewed;

  return map;
}

String _safeToIso8601String(dynamic raw) {
  if (raw == null) return DateTime.now().toIso8601String();
  if (raw is int) {
    // If Unix timestamp in seconds vs milliseconds
    if (raw < 100000000000) {
      return DateTime.fromMillisecondsSinceEpoch(raw * 1000).toIso8601String();
    } else {
      return DateTime.fromMillisecondsSinceEpoch(raw).toIso8601String();
    }
  }
  if (raw is double) {
    final intVal = raw.toInt();
    if (intVal < 100000000000) {
      return DateTime.fromMillisecondsSinceEpoch(intVal * 1000).toIso8601String();
    } else {
      return DateTime.fromMillisecondsSinceEpoch(intVal).toIso8601String();
    }
  }
  if (raw is String) {
    if (raw.isEmpty) return DateTime.now().toIso8601String();
    final parsedInt = int.tryParse(raw);
    if (parsedInt != null) {
      return _safeToIso8601String(parsedInt);
    }
    return raw;
  }
  return DateTime.now().toIso8601String();
}


@freezed
abstract class StatusViewerModel with _$StatusViewerModel {
  const factory StatusViewerModel({
    required String viewerId,
    String? username,
    String? displayName,
    String? profilePictureUrl,
    @JsonKey(name: 'viewedAt') String? viewedAt,
  }) = _StatusViewerModel;

  factory StatusViewerModel.fromJson(Map<String, dynamic> json) {
    final map = Map<String, dynamic>.from(json);
    final vId = (map['viewerId'] ?? map['id'] ?? map['userId'] ?? map['user_id'])?.toString() ?? '';
    final rawViewedAt = map['viewedAt'] ?? map['viewed_at'] ?? map['timestamp'] ?? map['created_at'];
    String? viewedAtStr;
    if (rawViewedAt is int) {
      if (rawViewedAt > 10000000000) {
        viewedAtStr = DateTime.fromMillisecondsSinceEpoch(rawViewedAt).toIso8601String();
      } else {
        viewedAtStr = DateTime.fromMillisecondsSinceEpoch(rawViewedAt * 1000).toIso8601String();
      }
    } else if (rawViewedAt is double) {
      viewedAtStr = DateTime.fromMillisecondsSinceEpoch((rawViewedAt * 1000).toInt()).toIso8601String();
    } else if (rawViewedAt != null) {
      final parsedInt = int.tryParse(rawViewedAt.toString());
      if (parsedInt != null && parsedInt > 1000000) {
        if (parsedInt > 10000000000) {
          viewedAtStr = DateTime.fromMillisecondsSinceEpoch(parsedInt).toIso8601String();
        } else {
          viewedAtStr = DateTime.fromMillisecondsSinceEpoch(parsedInt * 1000).toIso8601String();
        }
      } else {
        viewedAtStr = rawViewedAt.toString();
      }
    }

    return StatusViewerModel(
      viewerId: vId,
      username: map['username']?.toString(),
      displayName: map['displayName']?.toString(),
      profilePictureUrl: (map['profilePictureUrl'] ?? map['profile_picture_url'] ?? map['avatar'])?.toString(),
      viewedAt: viewedAtStr,
    );
  }
}

@freezed
abstract class StatusContactModel with _$StatusContactModel {
  const factory StatusContactModel({
    @JsonKey(name: 'userId') required String contactId,
    @JsonKey(name: 'displayName', defaultValue: 'User') required String name,
    @JsonKey(name: 'username') String? username,
    @JsonKey(name: 'profilePictureUrl') String? profilePictureUrl,
    @JsonKey(includeFromJson: false, includeToJson: false) @Default(Colors.blue) Color profileColor,
    @Default([]) List<StatusItemModel> statuses,
    @JsonKey(includeFromJson: false, includeToJson: false) @Default(false) bool isMuted,
  }) = _StatusContactModel;
  
  const StatusContactModel._();

  factory StatusContactModel.fromJson(Map<String, dynamic> json) => _$StatusContactModelFromJson(json);
  
  bool get allViewed => statuses.every((s) => s.viewed);
  int get statusCount => statuses.length;
}

@freezed
abstract class StatusPrivacyContact with _$StatusPrivacyContact {
  const factory StatusPrivacyContact({
    required String id,
    String? username,
    String? phoneNumber,
    String? displayName,
    String? profilePictureUrl,
  }) = _StatusPrivacyContact;

  factory StatusPrivacyContact.fromJson(Map<String, dynamic> json) => _$StatusPrivacyContactFromJson(json);
}

Map<String, dynamic> _normalizePrivacyJson(Map<String, dynamic> rawJson) {
  final json = rawJson.containsKey('data') && rawJson['data'] is Map
      ? Map<String, dynamic>.from(rawJson['data'] as Map)
      : Map<String, dynamic>.from(rawJson);

  final type = (json['privacyType'] ?? json['privacy_type'] ?? json['type'] ?? 'contacts').toString();

  List<String> parseIds(dynamic raw) {
    if (raw is List) {
      return raw.map((e) {
        if (e is Map) {
          return (e['id'] ?? e['_id'] ?? e['userId'] ?? e['user_id'] ?? '').toString();
        }
        return e.toString();
      }).where((id) => id.isNotEmpty).toList();
    }
    return [];
  }

  List<String> included = parseIds(json['includedUserIds'] ?? json['included_user_ids']);
  if (included.isEmpty && (json['includedContacts'] != null || json['included_contacts'] != null)) {
    included = parseIds(json['includedContacts'] ?? json['included_contacts']);
  }
  List<String> excluded = parseIds(json['excludedUserIds'] ?? json['excluded_user_ids']);
  if (excluded.isEmpty && (json['excludedContacts'] != null || json['excluded_contacts'] != null)) {
    excluded = parseIds(json['excludedContacts'] ?? json['excluded_contacts']);
  }

  final privacyUserIds = parseIds(json['privacyUserIds'] ?? json['privacy_user_ids'] ?? json['contactIds'] ?? json['contact_ids']);
  if (privacyUserIds.isNotEmpty) {
    final lowerType = type.toLowerCase();
    if (lowerType == 'only' || lowerType == 'include' || lowerType == 'only_share_with' || lowerType == 'only_share') {
      if (included.isEmpty) included = privacyUserIds;
    } else if (lowerType == 'except' || lowerType == 'exclude' || lowerType == 'my_contacts_except') {
      if (excluded.isEmpty) excluded = privacyUserIds;
    }
  }

  return {
    'privacyType': type,
    'includedUserIds': included,
    'excludedUserIds': excluded,
    'includedContacts': json['includedContacts'] ?? json['included_contacts'] ?? [],
    'excludedContacts': json['excludedContacts'] ?? json['excluded_contacts'] ?? [],
    'updatedAt': json['updatedAt'] ?? json['updated_at'],
  };
}

@freezed
abstract class StatusPrivacyModel with _$StatusPrivacyModel {
  const factory StatusPrivacyModel({
    @JsonKey(name: 'privacyType', defaultValue: 'ALL') String? privacyType,
    @JsonKey(name: 'includedUserIds') @Default([]) List<String> includedUserIds,
    @JsonKey(name: 'excludedUserIds') @Default([]) List<String> excludedUserIds,
    @JsonKey(name: 'includedContacts') @Default([]) List<StatusPrivacyContact> includedContacts,
    @JsonKey(name: 'excludedContacts') @Default([]) List<StatusPrivacyContact> excludedContacts,
    @JsonKey(name: 'updatedAt') int? updatedAt,
  }) = _StatusPrivacyModel;

  factory StatusPrivacyModel.fromJson(Map<String, dynamic> json) => _$StatusPrivacyModelFromJson(_normalizePrivacyJson(json));
}

