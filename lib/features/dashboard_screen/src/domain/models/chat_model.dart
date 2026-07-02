import 'package:freezed_annotation/freezed_annotation.dart';
import 'recipient_model.dart';
import 'last_message_model.dart';

part 'chat_model.freezed.dart';
part 'chat_model.g.dart';

@freezed
abstract class ChatModel with _$ChatModel {
  const factory ChatModel({
    @JsonKey(name: '_id', includeIfNull: false) @Default('') String id,
    @JsonKey(name: 'is_group') @Default(false) bool isGroup,
    @JsonKey(name: 'group_name') String? groupName,
    @JsonKey(name: 'group_description') String? groupDescription,
    @JsonKey(name: 'created_at') @Default('') String createdAt,
    @JsonKey(name: 'updated_at') @Default('') String updatedAt,
    required RecipientModel recipient,
    @JsonKey(name: 'last_message') LastMessageModel? lastMessage,
    @JsonKey(name: 'unread_count') @Default(0) int unreadCount,
  }) = _ChatModel;

  factory ChatModel.fromJson(Map<String, dynamic> json) => _$ChatModelFromJson(_normalizeChatJson(json));

  Map<String, dynamic> toJson();
}

Map<String, dynamic> _normalizeChatJson(Map<String, dynamic> json) {
  final normalizedJson = Map<String, dynamic>.from(json);
  normalizedJson['_id'] = (json['id'] ?? json['_id'])?.toString() ?? '';
  
  // Ensure nested objects are handled
  if (json['recipient'] is Map) {
    normalizedJson['recipient'] = Map<String, dynamic>.from(json['recipient'] as Map);
  } else {
    normalizedJson['recipient'] = const RecipientModel().toJson();
  }
  
  if (json['last_message'] is Map) {
    normalizedJson['last_message'] = Map<String, dynamic>.from(json['last_message'] as Map);
  }

  return normalizedJson;
}
