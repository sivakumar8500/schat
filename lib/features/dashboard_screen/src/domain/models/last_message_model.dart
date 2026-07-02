import 'package:freezed_annotation/freezed_annotation.dart';

part 'last_message_model.freezed.dart';
part 'last_message_model.g.dart';

@freezed
abstract class LastMessageModel with _$LastMessageModel {
  const factory LastMessageModel({
    @JsonKey(name: '_id', includeIfNull: false) required String id,
    @JsonKey(name: 'conversation_id') required String conversationId,
    @JsonKey(name: 'sender_id') required String senderId,
    required String content,
    @JsonKey(name: 'media_url') String? mediaUrl,
    @JsonKey(name: 'media_type') String? mediaType,
    @JsonKey(name: 'is_deleted') @Default(false) bool isDeleted,
    @JsonKey(name: 'created_at') required String createdAt,
    @JsonKey(name: 'updated_at') required String updatedAt,
  }) = _LastMessageModel;

  factory LastMessageModel.fromJson(Map<String, dynamic> json) => _$LastMessageModelFromJson(_normalizeLastMessage(json));

  Map<String, dynamic> toJson();
}

Map<String, dynamic> _normalizeLastMessage(Map<String, dynamic> json) {
  // Handle the specific logic from the previous manual implementation
  String contentText = '';
  String? mediaUrl;
  String? mediaType = json['type']?.toString() ?? json['media_type']?.toString();

  final dynamic contentData = json['content'];
  if (contentData is Map) {
    contentText = contentData['text']?.toString() ?? '';
    mediaUrl = (contentData['fileKey'] ?? contentData['file_key'] ?? contentData['url'])?.toString();
  } else if (contentData is String) {
    contentText = contentData;
    mediaUrl = (json['media_url'] ?? json['url'])?.toString();
  } else {
    contentText = json['content']?.toString() ?? '';
  }

  // Create a normalized map for the generated factory
  final normalizedJson = Map<String, dynamic>.from(json);
  normalizedJson['content'] = contentText;
  normalizedJson['media_url'] = mediaUrl ?? json['media_url'];
  normalizedJson['media_type'] = mediaType;
  normalizedJson['_id'] = (json['id'] ?? json['_id'] ?? json['message_id'])?.toString() ?? '';
  normalizedJson['conversation_id'] = (json['conversationId'] ?? json['conversation_id'] ?? json['conversation'])?.toString() ?? '';
  normalizedJson['sender_id'] = (json['senderId'] ?? json['sender_id'] ?? json['sender'])?.toString() ?? '';
  normalizedJson['is_deleted'] = json['isDeleted'] ?? json['is_deleted'] ?? json['isDeletedForEveryone'] ?? false;
  normalizedJson['created_at'] = (json['createdAt'] ?? json['created_at'])?.toString() ?? '';
  normalizedJson['updated_at'] = (json['updatedAt'] ?? json['updated_at'])?.toString() ?? '';

  return normalizedJson;
}
