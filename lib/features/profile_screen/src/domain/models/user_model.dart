import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:schat/core/storage/storage_service.dart';
import 'package:schat/injection.dart';

part 'user_model.freezed.dart';
part 'user_model.g.dart';

@freezed
abstract class UserModel with _$UserModel {
  const UserModel._();
  const factory UserModel({
    @JsonKey(name: 'phone_number') @Default('') String phoneNumber,
    String? username,
    @JsonKey(name: 'first_name') String? firstName,
    @JsonKey(name: 'last_name') String? lastName,
    @JsonKey(name: 'profile_picture_url') String? profilePictureUrl,
    String? about,
    @JsonKey(name: '_id', includeIfNull: false) @Default('') String id,
    @JsonKey(name: 'is_active') @Default(false) bool isActive,
    @JsonKey(name: 'is_online') @Default(false) bool isOnline,
    @JsonKey(name: 'last_seen') String? lastSeen,
    @JsonKey(name: 'is_subscribed') @Default(false) bool isSubscribed,
    @JsonKey(name: 'subscription_type') String? subscriptionType,
    @JsonKey(name: 'created_at') @Default('') String createdAt,
    @JsonKey(name: 'updated_at') @Default('') String updatedAt,
    @JsonKey(name: 'default_disappearing_timer') int? defaultDisappearingTimer,
    @JsonKey(name: 'contactName') String? contactName,
    @JsonKey(name: 'is_blocked') @Default(false) bool isBlocked,
    @JsonKey(name: 'is_blocked_by_me') @Default(false) bool isBlockedByMe,
    @JsonKey(name: 'is_blocked_by_other') @Default(false) bool isBlockedByOther,
    @JsonKey(name: 'read_receipts_enabled') @Default(true) bool readReceiptsEnabled,
    @JsonKey(name: 'typing_indicators_enabled') @Default(true) bool typingIndicatorsEnabled,
    @JsonKey(name: 'last_seen_enabled') @Default(true) bool lastSeenEnabled,
    @JsonKey(name: 'notifications_enabled') @Default(true) bool notificationsEnabled,
  }) = _UserModel;

  String get displayName {
    if (contactName != null && contactName!.isNotEmpty) {
      return contactName!;
    }
    if (username != null && username!.isNotEmpty) {
      return username!;
    }
    return phoneNumber;
  }

  factory UserModel.fromJson(Map<String, dynamic> json) => _$UserModelFromJson(_normalizeUserJson(json));

  @override
  Map<String, dynamic> toJson();
}

Map<String, dynamic> _normalizeUserJson(Map<String, dynamic> json) {
  final normalizedJson = Map<String, dynamic>.from(json);
  normalizedJson['_id'] = (json['id'] ?? json['_id'] ?? json['user_id'])?.toString() ?? '';
  final pic = json['profile_picture_url'] ??
      json['profilePictureUrl'] ??
      json['profile_picture'] ??
      json['profilePicture'] ??
      json['avatar_url'] ??
      json['avatarUrl'] ??
      json['avatar'] ??
      json['profile_pic'] ??
      json['caller_profile_picture_url'];
  if (pic != null && pic.toString().isNotEmpty) {
    normalizedJson['profile_picture_url'] = pic.toString();
  }
  if (json.containsKey('defaultDisappearingTimer') && !json.containsKey('default_disappearing_timer')) {
    normalizedJson['default_disappearing_timer'] = json['defaultDisappearingTimer'];
  }
  final categoryVal = json['about'] ??
      json['category'] ??
      json['user_category'] ??
      json['userCategory'] ??
      json['role'] ??
      json['occupation'];
  if (categoryVal != null && categoryVal.toString().isNotEmpty) {
    normalizedJson['about'] = categoryVal.toString();
  }

  normalizedJson['is_blocked'] = json['is_blocked'] ?? json['isBlocked'] ?? false;
  normalizedJson['is_blocked_by_me'] = json['is_blocked_by_me'] ?? json['isBlockedByMe'] ?? false;
  normalizedJson['is_blocked_by_other'] = json['is_blocked_by_other'] ?? json['isBlockedByOther'] ?? false;
  
  if (json.containsKey('read_receipts_enabled') && json['read_receipts_enabled'] != null) {
    normalizedJson['read_receipts_enabled'] = json['read_receipts_enabled'] == true;
  } else if (json.containsKey('readReceiptsEnabled') && json['readReceiptsEnabled'] != null) {
    normalizedJson['read_receipts_enabled'] = json['readReceiptsEnabled'] == true;
  } else {
    try {
      normalizedJson['read_receipts_enabled'] = getIt<StorageService>().getReadReceiptsEnabled();
    } catch (_) {
      normalizedJson['read_receipts_enabled'] = true;
    }
  }

  if (json.containsKey('typing_indicators_enabled') && json['typing_indicators_enabled'] != null) {
    normalizedJson['typing_indicators_enabled'] = json['typing_indicators_enabled'] == true;
  } else if (json.containsKey('typingIndicatorsEnabled') && json['typingIndicatorsEnabled'] != null) {
    normalizedJson['typing_indicators_enabled'] = json['typingIndicatorsEnabled'] == true;
  } else {
    try {
      normalizedJson['typing_indicators_enabled'] = getIt<StorageService>().getTypingIndicatorsEnabled();
    } catch (_) {
      normalizedJson['typing_indicators_enabled'] = true;
    }
  }

  if (json.containsKey('last_seen_enabled') && json['last_seen_enabled'] != null) {
    normalizedJson['last_seen_enabled'] = json['last_seen_enabled'] == true;
  } else if (json.containsKey('lastSeenEnabled') && json['lastSeenEnabled'] != null) {
    normalizedJson['last_seen_enabled'] = json['lastSeenEnabled'] == true;
  } else {
    try {
      normalizedJson['last_seen_enabled'] = getIt<StorageService>().getLastSeenEnabled();
    } catch (_) {
      normalizedJson['last_seen_enabled'] = true;
    }
  }
  return normalizedJson;
}
