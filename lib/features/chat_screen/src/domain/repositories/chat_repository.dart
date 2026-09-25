import 'dart:typed_data';
import 'package:schat/features/chat_screen/src/domain/models/message_model.dart';
import 'package:schat/features/chat_screen/src/domain/models/chat_media_model.dart';
import 'package:schat/features/chat_screen/src/domain/models/message_shares_model.dart';
import 'package:schat/features/chat_screen/src/domain/models/theme_color_model.dart';

import 'package:schat/features/chat_screen/src/domain/models/screen_permission_model.dart';
import 'package:schat/features/chat_screen/src/domain/models/scheduled_message_model.dart';
import 'package:schat/features/chat_screen/src/domain/models/media_permissions_model.dart';
import 'package:schat/features/chat_screen/src/domain/models/media_access_tree_model.dart';

abstract class ChatRepository {
  Future<List<MessageModel>> getMessages(String conversationId, {int? limit, int? skip});
  Future<bool> sendMessage(MessageModel message);
  Future<String?> uploadMedia({
    required String conversationId,
    required String filePath,
    required String fileName,
    required String mediaType, // CHAT_IMAGE, CHAT_VIDEO, VOICE_NOTE, DOCUMENT
    required String mimeType,
    required int fileSizeBytes,
    Uint8List? fileBytes,
  });
  Future<List<ChatMediaModel>> getConversationMedia(String conversationId, {int? limit});
  Future<Map<String, dynamic>> getGroupDetails(String groupId);
  
  // New Backend APIs
  Future<void> toggleFavorite({required String conversationId, required bool isFavorite});
  Future<void> toggleMute({required String conversationId, required bool isMuted});
  Future<void> forwardMessage({required String messageId, required String targetConversationId});
  Future<void> setDisappearingTimer({required String conversationId, int? seconds});
  Future<void> deleteGroup(String groupId);
  Future<void> updateGroupInfo({
    required String groupId,
    String? name,
    String? description,
    String? iconUrl,
    List<String>? participantIds,
  });
  Future<void> addGroupParticipants({required String groupId, required List<String> userIds});
  Future<void> removeGroupParticipant({required String groupId, required String userId});
  Future<void> promoteGroupAdmin({required String groupId, required String userId});
  Future<void> demoteGroupAdmin({required String groupId, required String userId});
  Future<void> pinMessage(String messageId);
  Future<void> unpinMessage(String messageId);
  Future<List<MessageModel>> getPinnedMessages(String conversationId);

  /// Clears all messages in [conversationId] for the calling user only.
  /// Returns the server-side `clearedAt` ISO-8601 timestamp.
  Future<String?> clearChat(String conversationId);

  /// Fetches the list of available conversation theme colors.
  Future<List<ThemeColorModel>> getThemes();

  /// Updates the conversation theme and/or custom wallpaper.
  Future<void> updateTheme({
    required String conversationId,
    String? themeColorId,
    String? customWallpaperUrl,
    bool applyToAll = false,
  });

  /// Resets the conversation theme or default user theme.
  Future<void> resetTheme({
    required String conversationId,
    bool resetAll = false,
  });

  /// PATCH the security object of a message. Only the original owner can set allowShare = false.
  Future<void> updateMessageSecurity(
    String messageId, {
    required bool allowShare,
    required bool allowDownload,
    bool allowView = true,
    bool isLocked = false,
    List<String> accessUsers = const [],
  });

  /// GET the list of users who have received a forwarded copy of the message.
  /// Only the original sender/owner can call this.
  Future<MessageSharesModel> getMessageShares(String messageId);

  /// POST /messages/scheduled to schedule a message for a future date/time.
  Future<bool> scheduleMessage(Map<String, dynamic> requestData);

  /// GET /messages/scheduled to retrieve pending scheduled messages.
  Future<List<ScheduledMessageModel>> getScheduledMessages({String? conversationId});

  /// DELETE /messages/scheduled/{id} to cancel/delete a scheduled message.
  Future<bool> cancelScheduledMessage(String scheduledMessageId);

  /// PUT /messages/scheduled/{id} to edit/update a scheduled message.
  Future<ScheduledMessageModel> updateScheduledMessage(String scheduledMessageId, Map<String, dynamic> requestData);

  /// GET /media/{mediaId}/permissions to fetch media DRM and access control permissions.
  Future<MediaPermissionsModel> getMediaPermissions(String mediaId);

  /// GET /media/{mediaId}/access-tree to fetch the hierarchical access and downstream share tree.
  Future<MediaAccessTreeModel> getMediaAccessTree(String mediaId);

  /// Screen capture permission methods
  Future<ScreenPermissionModel> requestScreenPermission({
    required String conversationId,
    required String permissionType,
    int? allowedCount,
    int? durationSeconds,
  });

  Future<ScreenPermissionModel> respondToScreenPermission({
    required String requestId,
    required String action,
  });

  Future<List<ScreenPermissionModel>> getPendingScreenPermissions();

  Future<ScreenPermissionModel?> getActiveScreenPermission(String conversationId);

  Future<ScreenPermissionModel> consumeScreenPermission(String requestId);
}

