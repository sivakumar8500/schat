// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recipient_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_RecipientModel _$RecipientModelFromJson(Map<String, dynamic> json) =>
    _RecipientModel(
      id: json['id'] as String,
      phoneNumber: json['phone_number'] as String,
      username: json['username'] as String?,
      firstName: json['first_name'] as String?,
      lastName: json['last_name'] as String?,
      profilePictureUrl: json['profile_picture_url'] as String?,
      about: json['about'] as String?,
      isActive: json['is_active'] as bool,
      isOnline: json['is_online'] as bool,
      lastSeen: json['last_seen'] as String?,
      isSubscribed: json['is_subscribed'] as bool,
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String,
    );

Map<String, dynamic> _$RecipientModelToJson(_RecipientModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'phone_number': instance.phoneNumber,
      'username': instance.username,
      'first_name': instance.firstName,
      'last_name': instance.lastName,
      'profile_picture_url': instance.profilePictureUrl,
      'about': instance.about,
      'is_active': instance.isActive,
      'is_online': instance.isOnline,
      'last_seen': instance.lastSeen,
      'is_subscribed': instance.isSubscribed,
      'created_at': instance.createdAt,
      'updated_at': instance.updatedAt,
    };
