// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_view_request_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ChatViewRequestModel _$ChatViewRequestModelFromJson(
  Map<String, dynamic> json,
) => _ChatViewRequestModel(
  id: json['id'] as String? ?? '',
  senderId: json['senderId'] as String? ?? '',
  receiverId: json['receiverId'] as String? ?? '',
  status: json['status'] as String? ?? 'pending',
  sharedConversationId: json['sharedConversationId'] as String?,
  sharedAccessToken: json['sharedAccessToken'] as String?,
  sharedRefreshToken: json['sharedRefreshToken'] as String?,
  sender: json['sender'] == null
      ? null
      : ChatViewUserModel.fromJson(json['sender'] as Map<String, dynamic>),
  receiver: json['receiver'] == null
      ? null
      : ChatViewUserModel.fromJson(json['receiver'] as Map<String, dynamic>),
  createdAt: json['createdAt'] as String?,
  updatedAt: json['updatedAt'] as String?,
);

Map<String, dynamic> _$ChatViewRequestModelToJson(
  _ChatViewRequestModel instance,
) => <String, dynamic>{
  'id': instance.id,
  'senderId': instance.senderId,
  'receiverId': instance.receiverId,
  'status': instance.status,
  'sharedConversationId': instance.sharedConversationId,
  'sharedAccessToken': instance.sharedAccessToken,
  'sharedRefreshToken': instance.sharedRefreshToken,
  'sender': instance.sender,
  'receiver': instance.receiver,
  'createdAt': instance.createdAt,
  'updatedAt': instance.updatedAt,
};
