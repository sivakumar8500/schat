import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:schat/features/chat_screen/src/domain/models/message_model.dart';

class ChatMessageCacheHelper {
  ChatMessageCacheHelper._();

  static const String boxName = 'cached_messages';

  static String normalizeConversationId(String id) {
    return id.replaceAll('-', '').toLowerCase().trim();
  }

  static bool isSameConversation(dynamic id1, dynamic id2) {
    if (id1 == null || id2 == null) return false;
    final s1 = id1.toString().replaceAll('-', '').toLowerCase().trim();
    final s2 = id2.toString().replaceAll('-', '').toLowerCase().trim();
    return s1 == s2;
  }

  static DateTime parseTimestamp(String? createdAt) {
    if (createdAt == null || createdAt.isEmpty) {
      return DateTime.fromMillisecondsSinceEpoch(0);
    }
    final parsedInt = int.tryParse(createdAt);
    if (parsedInt != null) {
      if (createdAt.length <= 10) {
        return DateTime.fromMillisecondsSinceEpoch(parsedInt * 1000);
      } else {
        return DateTime.fromMillisecondsSinceEpoch(parsedInt);
      }
    }
    return DateTime.tryParse(createdAt) ?? DateTime.fromMillisecondsSinceEpoch(0);
  }

  /// Loads cached messages for a conversation, trying exact key, normalized key, and key search.
  static Future<List<MessageModel>> loadMessages(String conversationId) async {
    if (conversationId.isEmpty) return [];
    try {
      final box = await Hive.openBox(boxName);
      dynamic rawList = box.get(conversationId);
      if (rawList == null) {
        final cleanKey = normalizeConversationId(conversationId);
        rawList = box.get(cleanKey);
      }
      if (rawList == null) {
        for (final k in box.keys) {
          if (isSameConversation(k, conversationId)) {
            rawList = box.get(k);
            break;
          }
        }
      }

      if (rawList is List && rawList.isNotEmpty) {
        final Map<String, MessageModel> map = {};
        for (final item in rawList) {
          if (item is Map) {
            try {
              final msg = MessageModel.fromJson(Map<String, dynamic>.from(item));
              if (msg.id.isNotEmpty) {
                map[msg.id] = msg;
              }
            } catch (_) {}
          }
        }
        final list = map.values.toList()
          ..sort((a, b) {
            final dtA = parseTimestamp(a.createdAt);
            final dtB = parseTimestamp(b.createdAt);
            final cmp = dtA.compareTo(dtB);
            if (cmp != 0) return cmp;
            return a.id.compareTo(b.id);
          });
        return list;
      }
    } catch (e) {
      debugPrint('ChatMessageCacheHelper: Error loading messages for $conversationId: $e');
    }
    return [];
  }

  /// Saves a complete list of messages for a conversation, under both the given key and normalized key.
  static Future<void> saveMessages(String conversationId, List<MessageModel> messages) async {
    if (conversationId.isEmpty) return;
    try {
      final box = await Hive.openBox(boxName);
      final serializable = messages.map((m) => m.toJson()).toList();
      await box.put(conversationId, serializable);
      final cleanKey = normalizeConversationId(conversationId);
      if (cleanKey != conversationId) {
        await box.put(cleanKey, serializable);
      }
    } catch (e) {
      debugPrint('ChatMessageCacheHelper: Error saving messages for $conversationId: $e');
    }
  }

  /// Appends or updates a single message in cache.
  static Future<void> appendMessage(String conversationId, MessageModel newMessage) async {
    if (conversationId.isEmpty || newMessage.id.isEmpty) return;
    try {
      final box = await Hive.openBox(boxName);
      dynamic rawList = box.get(conversationId);
      if (rawList == null) {
        final cleanKey = normalizeConversationId(conversationId);
        rawList = box.get(cleanKey);
      }
      if (rawList == null) {
        for (final k in box.keys) {
          if (isSameConversation(k, conversationId)) {
            rawList = box.get(k);
            break;
          }
        }
      }

      final List<dynamic> list = rawList is List ? List<dynamic>.from(rawList) : <dynamic>[];
      int existingIdx = -1;
      for (int i = 0; i < list.length; i++) {
        final item = list[i];
        if (item is Map) {
          final id = (item['id'] ?? item['_id'])?.toString();
          if (id == newMessage.id) {
            existingIdx = i;
            break;
          }
        }
      }

      final jsonMsg = newMessage.toJson();
      if (existingIdx != -1) {
        list[existingIdx] = jsonMsg;
      } else {
        list.add(jsonMsg);
      }

      await box.put(conversationId, list);
      final cleanKey = normalizeConversationId(conversationId);
      if (cleanKey != conversationId) {
        await box.put(cleanKey, list);
      }
    } catch (e) {
      debugPrint('ChatMessageCacheHelper: Error appending message for $conversationId: $e');
    }
  }

  /// Appends a raw json message map (e.g. from socket payload) into cache.
  static Future<void> appendRawMessage(String conversationId, Map<String, dynamic> rawMessage) async {
    try {
      final actualMessage = (rawMessage['message'] is Map)
          ? Map<String, dynamic>.from(rawMessage['message'] as Map)
          : rawMessage;
      final msg = MessageModel.fromJson(actualMessage);
      if (msg.id.isNotEmpty) {
        await appendMessage(conversationId, msg);
      }
    } catch (e) {
      debugPrint('ChatMessageCacheHelper: Error appending raw message: $e');
    }
  }

  /// Marks a message as deleted or removes it in cache.
  static Future<void> markMessageDeleted(String conversationId, String messageId) async {
    if (conversationId.isEmpty || messageId.isEmpty) return;
    try {
      final box = await Hive.openBox(boxName);
      dynamic rawList = box.get(conversationId);
      if (rawList == null) {
        final cleanKey = normalizeConversationId(conversationId);
        rawList = box.get(cleanKey);
      }
      if (rawList is List && rawList.isNotEmpty) {
        final List<dynamic> list = List<dynamic>.from(rawList);
        for (int i = 0; i < list.length; i++) {
          final item = list[i];
          if (item is Map) {
            final id = (item['id'] ?? item['_id'])?.toString();
            if (id == messageId) {
              final map = Map<String, dynamic>.from(item);
              map['isDeleted'] = true;
              list[i] = map;
              break;
            }
          }
        }
        await box.put(conversationId, list);
        final cleanKey = normalizeConversationId(conversationId);
        if (cleanKey != conversationId) {
          await box.put(cleanKey, list);
        }
      }
    } catch (e) {
      debugPrint('ChatMessageCacheHelper: Error marking message deleted: $e');
    }
  }

  /// Updates an edited message in cache.
  static Future<void> updateEditedMessage(String conversationId, MessageModel editedMessage) async {
    await appendMessage(conversationId, editedMessage);
  }
}
