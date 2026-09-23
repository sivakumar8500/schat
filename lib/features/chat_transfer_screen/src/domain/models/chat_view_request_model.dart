import 'package:freezed_annotation/freezed_annotation.dart';
import 'chat_view_user_model.dart';

part 'chat_view_request_model.freezed.dart';
part 'chat_view_request_model.g.dart';

@freezed
abstract class ChatViewRequestModel with _$ChatViewRequestModel {
  const factory ChatViewRequestModel({
    @Default('') String id,
    @Default('') String senderId,
    @Default('') String receiverId,
    @Default('pending') String status,
    String? sharedConversationId,
    String? sharedAccessToken,
    String? sharedRefreshToken,
    ChatViewUserModel? sender,
    ChatViewUserModel? receiver,
    String? createdAt,
    String? updatedAt,
  }) = _ChatViewRequestModel;

  factory ChatViewRequestModel.fromJson(Map<String, dynamic> json) => _$ChatViewRequestModelFromJson(_normalizeRequestJson(json));
}

Map<String, dynamic> _normalizeRequestJson(Map<String, dynamic> json) {
  final map = Map<String, dynamic>.from(json);
  map['id'] = (json['id'] ?? json['_id'] ?? '').toString();
  map['senderId'] = (json['senderId'] ?? json['sender_id'] ?? '').toString();
  map['receiverId'] = (json['receiverId'] ?? json['receiver_id'] ?? '').toString();
  map['status'] = (json['status'] ?? 'pending').toString().toLowerCase();
  map['sharedConversationId'] = json['sharedConversationId']?.toString() ?? json['shared_conversation_id']?.toString();
  map['sharedAccessToken'] = json['sharedAccessToken']?.toString() ?? json['shared_access_token']?.toString();
  map['sharedRefreshToken'] = json['sharedRefreshToken']?.toString() ?? json['shared_refresh_token']?.toString();
  
  if (json['sender'] is Map) {
    map['sender'] = Map<String, dynamic>.from(json['sender'] as Map);
  }
  if (json['receiver'] is Map) {
    map['receiver'] = Map<String, dynamic>.from(json['receiver'] as Map);
  }
  map['createdAt'] = (json['createdAt'] ?? json['created_at'])?.toString();
  map['updatedAt'] = (json['updatedAt'] ?? json['updated_at'])?.toString();

  return map;
}
