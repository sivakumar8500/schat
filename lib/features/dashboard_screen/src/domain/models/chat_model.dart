import 'package:freezed_annotation/freezed_annotation.dart';
import 'recipient_model.dart';
import 'last_message_model.dart';
import 'package:schat/features/chat_screen/src/domain/models/theme_color_model.dart';

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
    @JsonKey(name: 'isHidden') @Default(false) bool isHidden,
    @JsonKey(name: 'isHided') @Default(false) bool isHided,
    @JsonKey(name: 'is_muted') @Default(false) bool isMuted,
    @JsonKey(name: 'is_favorite') @Default(false) bool isFavorite,
    @JsonKey(name: 'themeColor') ThemeColorModel? themeColor,
    @JsonKey(includeFromJson: false, includeToJson: false) @Default(false) bool isTyping,
  }) = _ChatModel;

  factory ChatModel.fromJson(Map<String, dynamic> json) => _$ChatModelFromJson(_normalizeChatJson(json));

  Map<String, dynamic> toJson();
}

Map<String, dynamic> _normalizeChatJson(Map<String, dynamic> json) {
  final normalizedJson = Map<String, dynamic>.from(json);
  normalizedJson['_id'] = (json['id'] ?? json['_id'])?.toString() ?? '';
  
  // Normalize unread_count
  final unreadVal = json['unread_count'] ?? json['unreadCount'];
  normalizedJson['unread_count'] = unreadVal is num ? unreadVal.toInt() : (int.tryParse(unreadVal?.toString() ?? '') ?? 0);

  // Ensure nested objects are handled
  if (json['recipient'] is Map) {
    final recipientMap = Map<String, dynamic>.from(json['recipient'] as Map);
    final groupPic = json['groupPictureUrl'] ?? json['groupImageUrl'] ?? json['group_picture_url'] ?? json['icon_url'];
    if (groupPic != null && groupPic.toString().isNotEmpty) {
      recipientMap['profile_picture_url'] = groupPic.toString();
    }
    normalizedJson['recipient'] = recipientMap;
  } else {
    final groupPic = json['groupPictureUrl'] ?? json['groupImageUrl'] ?? json['group_picture_url'] ?? json['icon_url'];
    if (groupPic != null && groupPic.toString().isNotEmpty) {
      normalizedJson['recipient'] = {
        'profile_picture_url': groupPic.toString(),
      };
    } else {
      normalizedJson['recipient'] = const RecipientModel().toJson();
    }
  }
  
  if (json['last_message'] is Map) {
    normalizedJson['last_message'] = Map<String, dynamic>.from(json['last_message'] as Map);
  }

  return normalizedJson;
}
