import "package:freezed_annotation/freezed_annotation.dart";

part "last_message_model.freezed.dart";
part "last_message_model.g.dart";

@freezed
abstract class LastMessageModel with _$LastMessageModel {
  const factory LastMessageModel({
    required String id,
    @JsonKey(name: "conversation_id") required String conversationId,
    @JsonKey(name: "sender_id") required String senderId,
    required String content,
    @JsonKey(name: "media_url") String? mediaUrl,
    @JsonKey(name: "media_type") String? mediaType,
    @JsonKey(name: "is_deleted") required bool isDeleted,
    @JsonKey(name: "created_at") required String createdAt,
    @JsonKey(name: "updated_at") required String updatedAt,
  }) = _LastMessageModel;

  factory LastMessageModel.fromJson(Map<String, dynamic> json) => _$LastMessageModelFromJson(json);
}
