// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_UserModel _$UserModelFromJson(Map<String, dynamic> json) => _UserModel(
  phoneNumber: json['phone_number'] as String? ?? '',
  username: json['username'] as String?,
  firstName: json['first_name'] as String?,
  lastName: json['last_name'] as String?,
  profilePictureUrl: json['profile_picture_url'] as String?,
  about: json['about'] as String?,
  id: json['_id'] as String? ?? '',
  isActive: json['is_active'] as bool? ?? false,
  isOnline: json['is_online'] as bool? ?? false,
  lastSeen: json['last_seen'] as String?,
  isSubscribed: json['is_subscribed'] as bool? ?? false,
  subscriptionType: json['subscription_type'] as String?,
  createdAt: json['created_at'] as String? ?? '',
  updatedAt: json['updated_at'] as String? ?? '',
  defaultDisappearingTimer: (json['default_disappearing_timer'] as num?)
      ?.toInt(),
  contactName: json['contactName'] as String?,
  isBlocked: json['is_blocked'] as bool? ?? false,
  isBlockedByMe: json['is_blocked_by_me'] as bool? ?? false,
  isBlockedByOther: json['is_blocked_by_other'] as bool? ?? false,
  readReceiptsEnabled: json['read_receipts_enabled'] as bool? ?? true,
  typingIndicatorsEnabled: json['typing_indicators_enabled'] as bool? ?? true,
  lastSeenEnabled: json['last_seen_enabled'] as bool? ?? true,
  notificationsEnabled: json['notifications_enabled'] as bool? ?? true,
);

Map<String, dynamic> _$UserModelToJson(_UserModel instance) =>
    <String, dynamic>{
      'phone_number': instance.phoneNumber,
      'username': instance.username,
      'first_name': instance.firstName,
      'last_name': instance.lastName,
      'profile_picture_url': instance.profilePictureUrl,
      'about': instance.about,
      '_id': instance.id,
      'is_active': instance.isActive,
      'is_online': instance.isOnline,
      'last_seen': instance.lastSeen,
      'is_subscribed': instance.isSubscribed,
      'subscription_type': instance.subscriptionType,
      'created_at': instance.createdAt,
      'updated_at': instance.updatedAt,
      'default_disappearing_timer': instance.defaultDisappearingTimer,
      'contactName': instance.contactName,
      'is_blocked': instance.isBlocked,
      'is_blocked_by_me': instance.isBlockedByMe,
      'is_blocked_by_other': instance.isBlockedByOther,
      'read_receipts_enabled': instance.readReceiptsEnabled,
      'typing_indicators_enabled': instance.typingIndicatorsEnabled,
      'last_seen_enabled': instance.lastSeenEnabled,
      'notifications_enabled': instance.notificationsEnabled,
    };
