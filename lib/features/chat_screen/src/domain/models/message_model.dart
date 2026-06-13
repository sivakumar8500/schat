import 'package:freezed_annotation/freezed_annotation.dart';

part 'message_model.freezed.dart';
part 'message_model.g.dart';

@freezed
abstract class MessageModel with _$MessageModel {
  const factory MessageModel({
    required String id,
    required String chatId,
    required String type, // text, image, video, audio, doc, pdf, gif, call, video_call
    required String senderId,
    required String receiverId,
    required MessageContent content,
    required MessageSecurity security,
    required MessageViewControl viewControl,
    required MessageExpiry expiry,
    MessageCallMeta? callMeta,
    @Default([]) List<String> deletedFor,
    @Default(false) bool isDeletedForEveryone,
    required int createdAt,
    required int updatedAt,
  }) = _MessageModel;

  factory MessageModel.fromJson(Map<String, dynamic> json) => _$MessageModelFromJson(json);
}

@freezed
abstract class MessageContent with _$MessageContent {
  const factory MessageContent({
    String? text,
    String? fileUrl,
    String? thumbnail,
    String? fileName,
    int? fileSize,
    String? mimeType,
    int? duration,
  }) = _MessageContent;

  factory MessageContent.fromJson(Map<String, dynamic> json) => _$MessageContentFromJson(json);
}

@freezed
abstract class MessageSecurity with _$MessageSecurity {
  const factory MessageSecurity({
    required bool isLocked,
    required List<String> accessUsers,
    required bool allowDownload,
    required bool allowShare,
  }) = _MessageSecurity;

  factory MessageSecurity.fromJson(Map<String, dynamic> json) => _$MessageSecurityFromJson(json);
}

@freezed
abstract class MessageViewControl with _$MessageViewControl {
  const factory MessageViewControl({
    required String type, // once, etc.
    required int maxViews,
    required List<String> viewedBy,
    required bool isOpened,
    int? openedAt,
  }) = _MessageViewControl;

  factory MessageViewControl.fromJson(Map<String, dynamic> json) => _$MessageViewControlFromJson(json);
}

@freezed
abstract class MessageExpiry with _$MessageExpiry {
  const factory MessageExpiry({
    required bool isEnabled,
    required int expireAt,
  }) = _MessageExpiry;

  factory MessageExpiry.fromJson(Map<String, dynamic> json) => _$MessageExpiryFromJson(json);
}

@freezed
abstract class MessageCallMeta with _$MessageCallMeta {
  const factory MessageCallMeta({
    String? callType,
    int? duration,
    String? status,
  }) = _MessageCallMeta;

  factory MessageCallMeta.fromJson(Map<String, dynamic> json) => _$MessageCallMetaFromJson(json);
}
