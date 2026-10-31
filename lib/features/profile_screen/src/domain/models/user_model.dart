import 'package:freezed_annotation/freezed_annotation.dart';

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
  final Map<String, dynamic> baseJson = (json['user'] is Map)
      ? Map<String, dynamic>.from(json['user'] as Map)
      : (json['data'] is Map ? Map<String, dynamic>.from(json['data'] as Map) : json);
  final normalizedJson = Map<String, dynamic>.from(baseJson);
  normalizedJson['_id'] = (baseJson['id'] ?? baseJson['_id'] ?? baseJson['user_id'])?.toString() ?? '';
  normalizedJson['phone_number'] = (baseJson['phone_number'] ?? baseJson['phoneNumber'])?.toString() ?? '';

  final pic = baseJson['profile_picture_url'] ??
      baseJson['profilePictureUrl'] ??
      baseJson['profile_picture'] ??
      baseJson['profilePicture'] ??
      baseJson['avatar_url'] ??
      baseJson['avatarUrl'] ??
      baseJson['avatar'] ??
      baseJson['profile_pic'] ??
      baseJson['caller_profile_picture_url'] ??
      json['profile_picture_url'] ??
      json['profilePictureUrl'];
  if (pic != null && pic.toString().isNotEmpty) {
    normalizedJson['profile_picture_url'] = pic.toString();
  }
  if (baseJson.containsKey('defaultDisappearingTimer') && !baseJson.containsKey('default_disappearing_timer')) {
    normalizedJson['default_disappearing_timer'] = baseJson['defaultDisappearingTimer'];
  }
  final categoryVal = baseJson['about'] ??
      baseJson['category'] ??
      baseJson['user_category'] ??
      baseJson['userCategory'] ??
      baseJson['role'] ??
      baseJson['occupation'];
  if (categoryVal != null && categoryVal.toString().isNotEmpty) {
    normalizedJson['about'] = categoryVal.toString();
  }

  normalizedJson['is_blocked'] = baseJson['is_blocked'] ?? baseJson['isBlocked'] ?? false;
  normalizedJson['is_blocked_by_me'] = baseJson['is_blocked_by_me'] ?? baseJson['isBlockedByMe'] ?? false;
  normalizedJson['is_blocked_by_other'] = baseJson['is_blocked_by_other'] ?? baseJson['isBlockedByOther'] ?? false;
  
  if (baseJson.containsKey('read_receipts_enabled') && baseJson['read_receipts_enabled'] != null) {
    normalizedJson['read_receipts_enabled'] = baseJson['read_receipts_enabled'] == true;
  } else if (baseJson.containsKey('readReceiptsEnabled') && baseJson['readReceiptsEnabled'] != null) {
    normalizedJson['read_receipts_enabled'] = baseJson['readReceiptsEnabled'] == true;
  } else {
    normalizedJson['read_receipts_enabled'] = true;
  }

  if (baseJson.containsKey('typing_indicators_enabled') && baseJson['typing_indicators_enabled'] != null) {
    normalizedJson['typing_indicators_enabled'] = baseJson['typing_indicators_enabled'] == true;
  } else if (baseJson.containsKey('typingIndicatorsEnabled') && baseJson['typingIndicatorsEnabled'] != null) {
    normalizedJson['typing_indicators_enabled'] = baseJson['typingIndicatorsEnabled'] == true;
  } else {
    normalizedJson['typing_indicators_enabled'] = true;
  }

  if (baseJson.containsKey('last_seen_enabled') && baseJson['last_seen_enabled'] != null) {
    normalizedJson['last_seen_enabled'] = baseJson['last_seen_enabled'] == true;
  } else if (baseJson.containsKey('lastSeenEnabled') && baseJson['lastSeenEnabled'] != null) {
    normalizedJson['last_seen_enabled'] = baseJson['lastSeenEnabled'] == true;
  } else {
    normalizedJson['last_seen_enabled'] = true;
  }
  return normalizedJson;
}
