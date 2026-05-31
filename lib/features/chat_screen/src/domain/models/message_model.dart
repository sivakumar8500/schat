import 'package:freezed_annotation/freezed_annotation.dart';
import 'dart:typed_data';

part 'message_model.freezed.dart';
part 'message_model.g.dart';

@freezed
abstract class MessageModel with _$MessageModel {
  const factory MessageModel({
    required String id,
    required String text,
    required String time,
    required bool isMe,
    @Default(false) bool isRead,
    @Default('text') String type,
    String? attachmentPath,
    String? attachmentName,
    @JsonKey(includeFromJson: false, includeToJson: false) Uint8List? attachmentBytes,
  }) = _MessageModel;

  factory MessageModel.fromJson(Map<String, dynamic> json) => _$MessageModelFromJson(json);
}
