// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_view_user_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ChatViewUserModel _$ChatViewUserModelFromJson(Map<String, dynamic> json) =>
    _ChatViewUserModel(
      id: json['id'] as String? ?? '',
      username: json['username'] as String? ?? '',
      phoneNumber: json['phoneNumber'] as String? ?? '',
      name: json['name'] as String? ?? '',
      profilePictureUrl: json['profilePictureUrl'] as String?,
      isSubscribed: json['isSubscribed'] as bool? ?? false,
      subscriptionType: json['subscriptionType'] as String?,
    );

Map<String, dynamic> _$ChatViewUserModelToJson(_ChatViewUserModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'username': instance.username,
      'phoneNumber': instance.phoneNumber,
      'name': instance.name,
      'profilePictureUrl': instance.profilePictureUrl,
      'isSubscribed': instance.isSubscribed,
      'subscriptionType': instance.subscriptionType,
    };
