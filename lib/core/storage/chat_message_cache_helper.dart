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

  /// Checks whether a temporary optimistic message duplicates a confirmed server message.
  static bool isDuplicateTempMessage(MessageModel tempMsg, MessageModel confirmedMsg) {
    if (!tempMsg.id.startsWith('temp_') || confirmedMsg.id.startsWith('temp_')) {
      return false;
    }

    // Both must be from the same sender (or both userView == 'send')
    final sameSender = (tempMsg.senderId.isNotEmpty &&
            confirmedMsg.senderId.isNotEmpty &&
            tempMsg.senderId == confirmedMsg.senderId) ||
        (tempMsg.userView == 'send' && confirmedMsg.userView == 'send');
    if (!sameSender) return false;

    // 1. Same attachmentName
    if (tempMsg.attachmentName != null &&
        tempMsg.attachmentName!.isNotEmpty &&
        confirmedMsg.attachmentName != null &&
        confirmedMsg.attachmentName!.isNotEmpty &&
        tempMsg.attachmentName == confirmedMsg.attachmentName) {
      return true;
    }

    // 2. Same media file or matching media URL / fileKey
    if (tempMsg.mediaUrl != null &&
        tempMsg.mediaUrl!.isNotEmpty &&
        confirmedMsg.mediaUrl != null &&
        confirmedMsg.mediaUrl!.isNotEmpty) {
      final u1 = tempMsg.mediaUrl!;
      final u2 = confirmedMsg.mediaUrl!;
      if (u1 == u2) return true;

      final name1 = u1.split('/').last.split('?').first;
      final name2 = u2.split('/').last.split('?').first;
      if (name1.isNotEmpty &&
          name2.isNotEmpty &&
          (name1 == name2 || u2.contains(name1) || u1.contains(name2))) {
        return true;
      }
    }

    // 3. Same content if non-empty text
    if (tempMsg.content.trim().isNotEmpty &&
        confirmedMsg.content.trim().isNotEmpty &&
        tempMsg.content.trim() == confirmedMsg.content.trim() &&
        tempMsg.mediaType == confirmedMsg.mediaType) {
      return true;
    }

    // 4. Same mediaType and created within 3 minutes of each other
    if (tempMsg.mediaType != null &&
        tempMsg.mediaType != 'text' &&
        tempMsg.mediaType == confirmedMsg.mediaType) {
      final dt1 = parseTimestamp(tempMsg.createdAt);
      final dt2 = parseTimestamp(confirmedMsg.createdAt);
      if (dt1.millisecondsSinceEpoch > 0 &&
          dt2.millisecondsSinceEpoch > 0 &&
          dt2.difference(dt1).abs().inMinutes <= 3) {
        return true;
      }
    }

    return false;
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

        // Deduplicate temp messages: remove any temp message superseded by a confirmed message or older than 10 mins
        final confirmedMsgs = map.values.where((m) => !m.id.startsWith('temp_')).toList();
        final now = DateTime.now();
        map.removeWhere((id, msg) {
          if (!id.startsWith('temp_')) return false;
          if (confirmedMsgs.any((c) => isDuplicateTempMessage(msg, c))) {
            return true;
          }
          final dt = parseTimestamp(msg.createdAt);
          if (dt.millisecondsSinceEpoch > 0 && now.difference(dt).inMinutes > 10) {
            return true;
          }
          return false;
        });

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

  /// Saves a complete list of messages for a conversation, merging with any existing cached messages so that newer socket messages or pending messages are never lost.
  static Future<void> saveMessages(String conversationId, List<MessageModel> messages) async {
    if (conversationId.isEmpty) return;
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

      final Map<String, Map<String, dynamic>> map = {};
      if (rawList is List) {
        for (final item in rawList) {
          if (item is Map) {
            final id = (item['id'] ?? item['_id'])?.toString();
            if (id != null && id.isNotEmpty) {
              map[id] = Map<String, dynamic>.from(item);
            }
          }
        }
      }
      for (final m in messages) {
        if (m.id.isNotEmpty) {
          map[m.id] = m.toJson();
        }
      }

      // Purge any temporary message in map that duplicates an incoming confirmed message or is stale (>10 min)
      final confirmed = messages.where((m) => !m.id.startsWith('temp_')).toList();
      final now = DateTime.now();
      map.removeWhere((id, item) {
        if (!id.startsWith('temp_')) return false;
        try {
          final tempMsg = MessageModel.fromJson(item);
          if (confirmed.any((c) => isDuplicateTempMessage(tempMsg, c))) {
            return true;
          }
          final dt = parseTimestamp((item['createdAt'] ?? item['created_at'])?.toString());
          if (dt.millisecondsSinceEpoch > 0 && now.difference(dt).inMinutes > 10) {
            return true;
          }
        } catch (_) {}
        return false;
      });

      final list = map.values.toList()
        ..sort((a, b) {
          final dtA = parseTimestamp((a['createdAt'] ?? a['created_at'])?.toString());
          final dtB = parseTimestamp((b['createdAt'] ?? b['created_at'])?.toString());
          final cmp = dtA.compareTo(dtB);
          if (cmp != 0) return cmp;
          final idA = (a['id'] ?? a['_id'] ?? '').toString();
          final idB = (b['id'] ?? b['_id'] ?? '').toString();
          return idA.compareTo(idB);
        });

      await box.put(conversationId, list);
      final cleanKey = normalizeConversationId(conversationId);
      if (cleanKey != conversationId) {
        await box.put(cleanKey, list);
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
        // If newMessage is confirmed, check if it replaces an existing temp message in list
        int tempIdx = -1;
        if (!newMessage.id.startsWith('temp_')) {
          for (int i = list.length - 1; i >= 0; i--) {
            final item = list[i];
            if (item is Map) {
              final id = (item['id'] ?? item['_id'])?.toString() ?? '';
              if (id.startsWith('temp_')) {
                try {
                  final tempMsg = MessageModel.fromJson(Map<String, dynamic>.from(item));
                  if (isDuplicateTempMessage(tempMsg, newMessage)) {
                    tempIdx = i;
                    break;
                  }
                } catch (_) {}
              }
            }
          }
        }

        if (tempIdx != -1) {
          list[tempIdx] = jsonMsg;
        } else {
          list.add(jsonMsg);
        }
      }

      // Purge any remaining duplicate temp messages in list
      if (!newMessage.id.startsWith('temp_')) {
        list.removeWhere((item) {
          if (item is Map) {
            final id = (item['id'] ?? item['_id'])?.toString() ?? '';
            if (id.startsWith('temp_')) {
              try {
                final tempMsg = MessageModel.fromJson(Map<String, dynamic>.from(item));
                return isDuplicateTempMessage(tempMsg, newMessage);
              } catch (_) {}
            }
          }
          return false;
        });
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

  /// Clears all cached messages for a conversation (exact key, clean key, and matching keys).
  static Future<void> clearConversation(String conversationId) async {
    if (conversationId.isEmpty) return;
    try {
      final box = await Hive.openBox(boxName);
      await box.delete(conversationId);
      final cleanKey = normalizeConversationId(conversationId);
      if (cleanKey != conversationId) {
        await box.delete(cleanKey);
      }
      for (final k in box.keys.toList()) {
        if (isSameConversation(k, conversationId)) {
          await box.delete(k);
        }
      }
    } catch (e) {
      debugPrint('ChatMessageCacheHelper: Error clearing conversation $conversationId: $e');
    }
  }

  /// Explicitly deletes a message from cache (useful for purging temporary messages).
  static Future<void> deleteMessage(String conversationId, String messageId) async {
    if (conversationId.isEmpty || messageId.isEmpty) return;
    try {
      final box = await Hive.openBox(boxName);
      dynamic rawList = box.get(conversationId);
      if (rawList == null) {
        final cleanKey = normalizeConversationId(conversationId);
        rawList = box.get(cleanKey);
      }
      if (rawList is List && rawList.isNotEmpty) {
        final list = List<dynamic>.from(rawList)
          ..removeWhere((item) => item is Map && ((item['id'] ?? item['_id'])?.toString() == messageId));
        await box.put(conversationId, list);
        final cleanKey = normalizeConversationId(conversationId);
        if (cleanKey != conversationId) {
          await box.put(cleanKey, list);
        }
      }
    } catch (e) {
      debugPrint('ChatMessageCacheHelper: Error deleting message $messageId: $e');
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
