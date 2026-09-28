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
  normalizedJson['is_blocked'] = json['is_blocked'] ?? json['isBlocked'] ?? false;
  normalizedJson['is_blocked_by_me'] = json['is_blocked_by_me'] ?? json['isBlockedByMe'] ?? false;
  normalizedJson['is_blocked_by_other'] = json['is_blocked_by_other'] ?? json['isBlockedByOther'] ?? false;
  return normalizedJson;
}
