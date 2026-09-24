import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:schat/features/chat_screen/src/domain/models/theme_color_model.dart';

abstract class ChatEvent {
  const ChatEvent();
}

class LoadMessagesEvent extends ChatEvent {
  final String conversationId;
  final String? recipientId;
  final bool? initialIsOnline;
  final ThemeColorModel? initialThemeColor;
  final String? initialCustomWallpaperUrl;
  final int? initialDisappearingTimer;
  const LoadMessagesEvent({
    required this.conversationId,
    this.recipientId,
    this.initialIsOnline,
    this.initialThemeColor,
    this.initialCustomWallpaperUrl,
    this.initialDisappearingTimer,
  });
}

class SendMessageEvent extends ChatEvent {
  final String conversationId;
  final String text;
  final String type;
  final String? attachmentPath;
  final String? attachmentName;
  final Uint8List? attachmentBytes;
  final String? replyMessageId;
  final String? replyMessageBody;
  final bool allowShare;
  final bool allowDownload;
  final bool allowView;
  final int? fileSize;
  final String? messageId;
  final double? latitude;
  final double? longitude;
  final String? address;
  final String? title;

  const SendMessageEvent({
    required this.conversationId,
    required this.text,
    this.type = 'text',
    this.attachmentPath,
    this.attachmentName,
    this.attachmentBytes,
    this.replyMessageId,
    this.replyMessageBody,
    this.allowShare = true,
    this.allowDownload = true,
    this.allowView = true,
    this.fileSize,
    this.messageId,
    this.latitude,
    this.longitude,
    this.address,
    this.title,
  });
}

class MarkMessageFailedEvent extends ChatEvent {
  final String messageId;
  final String conversationId;
  const MarkMessageFailedEvent({required this.messageId, required this.conversationId});
}

class ReceiveMessageEvent extends ChatEvent {
  final Map<String, dynamic> messageData;
  const ReceiveMessageEvent({required this.messageData});
}

class ToggleMuteEvent extends ChatEvent {
  final bool isMuted;
  const ToggleMuteEvent({required this.isMuted});
}

class ToggleLockEvent extends ChatEvent {
  final bool isLocked;
  const ToggleLockEvent({required this.isLocked});
}

class UpdateUserStatusEvent extends ChatEvent {
  final String userId;
  final bool isOnline;
  final String? lastSeen;
  const UpdateUserStatusEvent({required this.userId, required this.isOnline, this.lastSeen});
}

class UpdateTypingIndicatorEvent extends ChatEvent {
  final String conversationId;
  final bool isTyping;
  const UpdateTypingIndicatorEvent({required this.conversationId, required this.isTyping});
}

class MarkMessageReadEvent extends ChatEvent {
  final String messageId;
  final String conversationId;
  const MarkMessageReadEvent({required this.messageId, required this.conversationId});
}

class MarkMessageDeliveredEvent extends ChatEvent {
  final String messageId;
  final String conversationId;
  const MarkMessageDeliveredEvent({required this.messageId, required this.conversationId});
}

class DeleteMessagesEvent extends ChatEvent {
  final List<String> messageIds;
  final String conversationId;
  final String deleteType; // 'me' or 'everyone'
  const DeleteMessagesEvent({required this.messageIds, required this.conversationId, required this.deleteType});
}

class EditMessageEvent extends ChatEvent {
  final String messageId;
  final String conversationId;
  final String newContent;
  const EditMessageEvent({required this.messageId, required this.conversationId, required this.newContent});
}

class PinMessageEvent extends ChatEvent {
  final String messageId;
  final String conversationId;
  final bool isPinned;
  const PinMessageEvent({required this.messageId, required this.conversationId, required this.isPinned});
}

class ReceivePinMessageEvent extends ChatEvent {
  final Map<String, dynamic> messageData;
  const ReceivePinMessageEvent({required this.messageData});
}

class ReceiveUnpinMessageEvent extends ChatEvent {
  final Map<String, dynamic> messageData;
  const ReceiveUnpinMessageEvent({required this.messageData});
}

class ReceiveDeleteMessageEvent extends ChatEvent {
  final String messageId;
  final String conversationId;
  const ReceiveDeleteMessageEvent({required this.messageId, required this.conversationId});
}

class ReceiveEditMessageEvent extends ChatEvent {
  final String messageId;
  final String conversationId;
  final String? newContent;
  final String? updatedAt;
  final int? editedAt;
  final bool? allowShare;
  final bool? allowDownload;
  final bool? allowView;
  final bool? isLocked;

  const ReceiveEditMessageEvent({
    required this.messageId,
    required this.conversationId,
    this.newContent,
    this.updatedAt,
    this.editedAt,
    this.allowShare,
    this.allowDownload,
    this.allowView,
    this.isLocked,
  });
}

class ChangeBackgroundColorEvent extends ChatEvent {
  final Color color;
  final String conversationId;
  const ChangeBackgroundColorEvent({required this.color, required this.conversationId});
}

class UpdateAttachmentPermissionsEvent extends ChatEvent {
  final String messageId;
  final String conversationId;
  final bool allowShare;
  final bool allowDownload;
  final bool allowView;

  const UpdateAttachmentPermissionsEvent({
    required this.messageId,
    required this.conversationId,
    required this.allowShare,
    required this.allowDownload,
    required this.allowView,
  });
}

class ToggleFavoriteEvent extends ChatEvent {
  final bool isFavorite;
  const ToggleFavoriteEvent({required this.isFavorite});
}

class SetDisappearingTimerEvent extends ChatEvent {
  final int? seconds;
  const SetDisappearingTimerEvent({this.seconds});
}

class UpdateGroupInfoEvent extends ChatEvent {
  final String groupId;
  final String? name;
  final String? description;
  final String? iconUrl;
  const UpdateGroupInfoEvent({required this.groupId, this.name, this.description, this.iconUrl});
}

class AddGroupParticipantsEvent extends ChatEvent {
  final String groupId;
  final List<String> userIds;
  const AddGroupParticipantsEvent({required this.groupId, required this.userIds});
}

class RemoveGroupParticipantEvent extends ChatEvent {
  final String groupId;
  final String userId;
  const RemoveGroupParticipantEvent({required this.groupId, required this.userId});
}

class ReceiveCallLogUpdateEvent extends ChatEvent {
  final Map<String, dynamic> callLogData;
  const ReceiveCallLogUpdateEvent({required this.callLogData});
}

class CloseChatEvent extends ChatEvent {
  const CloseChatEvent();
}

class ShowNotificationEvent extends ChatEvent {
  final String message;
  final bool isError;
  const ShowNotificationEvent({required this.message, this.isError = false});
}

class ClearChatEvent extends ChatEvent {
  final String conversationId;
  const ClearChatEvent({required this.conversationId});
}

class LoadThemesEvent extends ChatEvent {
  const LoadThemesEvent();
}

class UpdateThemeEvent extends ChatEvent {
  final String? themeColorId; // null to remove theme
  final ThemeColorModel? themeColor;
  final String? customWallpaperUrl;
  final bool clearWallpaper;
  final bool applyToAll;

  const UpdateThemeEvent({
    this.themeColorId,
    this.themeColor,
    this.customWallpaperUrl,
    this.clearWallpaper = false,
    this.applyToAll = false,
  });
}

class ResetThemeEvent extends ChatEvent {
  final bool resetAll;
  const ResetThemeEvent({this.resetAll = false});
}

class LoadMoreMessagesEvent extends ChatEvent {
  final String conversationId;
  const LoadMoreMessagesEvent({required this.conversationId});
}

/// Dispatched by the owner to PATCH the security.allowShare field on a message.
class UpdateMessageSecurityEvent extends ChatEvent {
  final String messageId;
  final bool allowShare;
  final bool allowDownload;
  final bool isLocked;

  const UpdateMessageSecurityEvent({
    required this.messageId,
    required this.allowShare,
    required this.allowDownload,
    this.isLocked = false,
  });
}

/// Dispatched by the owner to fetch the list of users who have received a
/// forwarded copy of the message (GET /messages/{id}/shares).
class FetchMessageSharesEvent extends ChatEvent {
  final String messageId;
  const FetchMessageSharesEvent({required this.messageId});
}

/// Received when the server broadcasts a group_updated WebSocket event.
class ReceiveGroupUpdatedEvent extends ChatEvent {
  final Map<String, dynamic> data;
  const ReceiveGroupUpdatedEvent({required this.data});
}

/// Received when the server broadcasts a group_admin_updated WebSocket event.
class ReceiveGroupAdminUpdatedEvent extends ChatEvent {
  final Map<String, dynamic> data;
  const ReceiveGroupAdminUpdatedEvent({required this.data});
}

/// Promote a participant to group admin via POST /groups/{group_id}/admins/{user_id}.
class PromoteGroupAdminEvent extends ChatEvent {
  final String groupId;
  final String userId;
  const PromoteGroupAdminEvent({required this.groupId, required this.userId});
}

/// Demote a group admin via DELETE /groups/{group_id}/admins/{user_id}.
class DemoteGroupAdminEvent extends ChatEvent {
  final String groupId;
  final String userId;
  const DemoteGroupAdminEvent({required this.groupId, required this.userId});
}

class ReceiveFileActionEvent extends ChatEvent {
  final String messageId;
  final String actionType; // 'file_viewed', 'file_downloaded', 'file_shared'
  const ReceiveFileActionEvent({required this.messageId, required this.actionType});
}

class ScheduleMessageEvent extends ChatEvent {
  final Map<String, dynamic> requestData;
  const ScheduleMessageEvent(this.requestData);
}

class CheckExpiredMessagesEvent extends ChatEvent {
  const CheckExpiredMessagesEvent();
}

class ReceiveDisappearingTimerUpdatedEvent extends ChatEvent {
  final int? seconds;
  const ReceiveDisappearingTimerUpdatedEvent({this.seconds});
}

class ReceiveScreenPermissionRequestEvent extends ChatEvent {
  final Map<String, dynamic> requestData;
  const ReceiveScreenPermissionRequestEvent({required this.requestData});
}

class ReceiveScreenPermissionResponseEvent extends ChatEvent {
  final Map<String, dynamic> requestData;
  final String action;
  const ReceiveScreenPermissionResponseEvent({required this.requestData, required this.action});
}

class UpdateActiveScreenPermissionEvent extends ChatEvent {
  final Map<String, dynamic>? permissionData;
  const UpdateActiveScreenPermissionEvent({this.permissionData});
}

class ConsumeScreenPermissionEvent extends ChatEvent {
  final String requestId;
  const ConsumeScreenPermissionEvent({required this.requestId});
}


