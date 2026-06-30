import 'dart:typed_data';
import 'package:schat/features/chat_screen/src/domain/models/message_model.dart';
import 'package:schat/features/chat_screen/src/domain/models/chat_media_model.dart';

abstract class ChatRepository {
  Future<List<MessageModel>> getMessages(String conversationId);
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
  Future<List<ChatMediaModel>> getConversationMedia(String conversationId);
  Future<Map<String, dynamic>> getGroupDetails(String groupId);
  
  // New Backend APIs
  Future<void> toggleFavorite({required String conversationId, required bool isFavorite});
  Future<void> toggleMute({required String conversationId, required bool isMuted});
  Future<void> forwardMessage({required String messageId, required String targetConversationId});
  Future<void> setDisappearingTimer({required String conversationId, int? seconds});
  Future<void> deleteGroup(String groupId);
}
