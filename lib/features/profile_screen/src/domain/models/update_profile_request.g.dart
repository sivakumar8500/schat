// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_profile_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_UpdateProfileRequest _$UpdateProfileRequestFromJson(
  Map<String, dynamic> json,
) => _UpdateProfileRequest(
  username: json['username'] as String?,
  firstName: json['first_name'] as String?,
  lastName: json['last_name'] as String?,
  profilePictureUrl: json['profile_picture_url'] as String?,
  about: json['about'] as String?,
);

Map<String, dynamic> _$UpdateProfileRequestToJson(
  _UpdateProfileRequest instance,
) => <String, dynamic>{
  'username': instance.username,
  'first_name': instance.firstName,
  'last_name': instance.lastName,
  'profile_picture_url': instance.profilePictureUrl,
  'about': instance.about,
};
