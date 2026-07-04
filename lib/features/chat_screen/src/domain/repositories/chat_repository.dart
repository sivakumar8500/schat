import 'dart:typed_data';
import 'package:schat/features/chat_screen/src/domain/models/message_model.dart';
import 'package:schat/features/chat_screen/src/domain/models/chat_media_model.dart';
import 'package:schat/features/chat_screen/src/domain/models/theme_color_model.dart';

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
  Future<void> updateGroupInfo({required String groupId, String? name, String? description, String? iconUrl});
  Future<void> addGroupParticipants({required String groupId, required List<String> userIds});
  Future<void> removeGroupParticipant({required String groupId, required String userId});
  Future<void> pinMessage(String messageId);
  Future<void> unpinMessage(String messageId);
  Future<List<MessageModel>> getPinnedMessages(String conversationId);

  /// Clears all messages in [conversationId] for the calling user only.
  /// Returns the server-side `clearedAt` ISO-8601 timestamp.
  Future<String?> clearChat(String conversationId);

  /// Fetches the list of available conversation theme colors.
  Future<List<ThemeColorModel>> getThemes();

  /// Updates the conversation theme. Pass [themeColorId] = null to remove the custom theme.
  Future<void> updateTheme({required String conversationId, String? themeColorId});
}
