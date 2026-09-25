import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter/material.dart';

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
    @JsonKey(includeFromJson: false, includeToJson: false) @Default(false) bool viewed,
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
  map['id'] = (json['id'] ?? json['_id'] ?? json['status_id'])?.toString() ?? '';
  map['textContent'] = json['textContent'] ?? json['text_content'] ?? json['text'];

  final rawMedia = json['mediaUrl'] ?? json['media_url'];
  if (rawMedia != null && rawMedia.toString().startsWith('http')) {
    map['mediaUrl'] = rawMedia.toString();
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
    @JsonKey(name: 'viewedAt') int? viewedAt,
  }) = _StatusViewerModel;

  factory StatusViewerModel.fromJson(Map<String, dynamic> json) {
    final map = Map<String, dynamic>.from(json);
    final vId = (map['viewerId'] ?? map['id'] ?? map['userId'] ?? map['user_id'])?.toString() ?? '';
    return StatusViewerModel(
      viewerId: vId,
      username: map['username']?.toString(),
      displayName: map['displayName']?.toString(),
      viewedAt: map['viewedAt'] is num ? (map['viewedAt'] as num).toInt() : null,
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

  factory StatusPrivacyModel.fromJson(Map<String, dynamic> json) => _$StatusPrivacyModelFromJson(json);
}

