import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:schat/features/dashboard_screen/src/domain/usecases/get_chats_usecase.dart';
import 'package:schat/features/dashboard_screen/src/domain/repositories/dashboard_repository.dart';
import 'package:schat/features/dashboard_screen/src/domain/repositories/contacts_repository.dart';
import 'package:schat/features/chat_socket_screen/src/domain/chat_socket_repository.dart';
import 'package:schat/features/dashboard_screen/src/domain/models/chat_model.dart';
import 'package:schat/features/dashboard_screen/src/domain/models/last_message_model.dart';
import 'package:schat/core/storage/storage_service.dart';
import 'chats_event.dart';
import 'chats_state.dart';

@lazySingleton
class ChatsBloc extends Bloc<ChatsEvent, ChatsState> {
  final GetChatsUseCase _getChatsUseCase;
  final DashboardRepository _chatRepository;
  // ignore: unused_field
  final ContactsRepository _contactsRepository;
  final ChatSocketRepository _socketRepository;
  final StorageService _storageService;
  StreamSubscription? _socketSubscription;

  ChatsBloc(
    this._getChatsUseCase,
    this._chatRepository,
    this._contactsRepository,
    this._socketRepository,
    this._storageService,
  ) : super(const ChatsInitial()) {
    on<FetchChats>(_onFetchChats);
    on<CreateChat>(_onCreateChat);
    on<UpdateUserStatus>(_onUpdateUserStatus);
    on<NewMessageReceived>(_onNewMessageReceived);
    on<MessageEdited>(_onMessageEdited);
    on<RemoveChat>(_onRemoveChat);
    on<CallLogUpdated>(_onCallLogUpdated);
    on<UpdateChatTypingStatus>(_onUpdateChatTypingStatus);
    on<MessageDeleted>(_onMessageDeleted);
    on<UpdateDisappearingTimer>(_onUpdateDisappearingTimer);
    on<UpdateMessageStatus>(_onUpdateMessageStatus);

    _listenToSocket();
  }

  Map<String, dynamic> _cleanMap(Map<dynamic, dynamic> map) {
    final Map<String, dynamic> result = {};
    map.forEach((key, val) {
      final k = key.toString();
      if (val is Map) {
        result[k] = _cleanMap(val);
      } else if (val is List) {
        result[k] = val.map((item) => item is Map ? _cleanMap(item) : item).toList();
      } else {
        result[k] = val;
      }
    });
    return result;
  }

  void _listenToSocket() {
    _socketSubscription = _socketRepository.onMessage.listen((data) {
      if (data == null) return;
      
      try {
        final Map mapData = data is Map ? data : {};
        if (mapData.isEmpty) return;
        
        final cleanData = _cleanMap(Map<dynamic, dynamic>.from(mapData));
        final type = cleanData['type']?.toString();
        
        if (type == 'user_status' || type == 'user_online' || type == 'user_offline') {
          final userId = (cleanData['user_id'] ?? cleanData['id'] ?? cleanData['sender_id'])
              ?.toString();
          final status = cleanData['status']?.toString();
          final isOnline = type == 'user_online' || (type == 'user_status' && status == 'online');
          final lastSeen = cleanData['last_seen']?.toString();
          if (userId != null) {
            add(UpdateUserStatus(
              userId: userId,
              isOnline: isOnline,
              lastSeen: lastSeen,
            ));
          }
        } else if (type == 'new_message' || type == 'message') {
          final message = cleanData['message'] ?? (cleanData.containsKey('id') ? cleanData : null);
          if (message is Map) {
            final convId = (message['conversationId'] ?? message['conversation_id'])?.toString();
            final updatedAt = (message['updatedAt'] ?? message['created_at'])?.toString();
            final unreadCount = int.tryParse(cleanData['unread_count']?.toString() ?? '') ?? 
                                int.tryParse(cleanData['unreadCount']?.toString() ?? '') ??
                                int.tryParse(cleanData['unread']?.toString() ?? '');
            final senderId = (message['senderId'] ?? message['sender_id'] ?? message['sender'])?.toString();
            final msgId = (message['id'] ?? message['messageId'] ?? message['_id'])?.toString();
            final myId = _storageService.getUserId() ?? '';
            
            if (convId != null && msgId != null && senderId != myId && senderId != null) {
              _socketRepository.sendDeliveryReceipt(convId, msgId);
            }
            
            if (convId != null) {
              add(NewMessageReceived(
                conversationId: convId,
                lastMessage: LastMessageModel.fromJson(Map<String, dynamic>.from(message)),
                updatedAt: updatedAt ?? DateTime.now().toIso8601String(),
                unreadCount: unreadCount,
              ));
            }
          }
        } else if (type == 'message_edited' || type == 'edit_message') {
          final message = cleanData['message'];
          if (message is Map) {
            final convId = (message['conversationId'] ?? message['conversation_id'])?.toString();
            if (convId != null) {
              add(MessageEdited(
                conversationId: convId,
                message: LastMessageModel.fromJson(Map<String, dynamic>.from(message)),
              ));
            }
          }
        } else if (type == 'message_deleted_for_everyone' || type == 'delete_message') {
          final convId = (cleanData['conversationId'] ?? cleanData['conversation_id'])?.toString();
          final msgId = (cleanData['messageId'] ?? cleanData['message_id'] ?? cleanData['id'])?.toString();
          if (convId != null && msgId != null) {
            add(MessageDeleted(conversationId: convId, messageId: msgId));
          }
        } else if (type == 'conversation_deleted') {
          final convId = (cleanData['conversationId'] ?? cleanData['conversation_id'])?.toString();
          if (convId != null) {
            add(RemoveChat(conversationId: convId));
          }
        } else if (type == 'participant_left') {
           // If myId left, remove chat. If someone else left and it's a group, maybe update participant count.
           // For now, if we receive participant_left for a 1-on-1, it's basically conversation_deleted.
           final convId = (cleanData['conversation_id'] ?? cleanData['conversationId'])?.toString();
           if (convId != null) {
              // Check if it's 1-on-1 and other user left
              add(RemoveChat(conversationId: convId));
           }
        } else if (type == 'call_log_updated') {
          final convId = (cleanData['conversation_id'] ?? cleanData['conversationId'])?.toString();
          final callMeta = cleanData['call_meta'] ?? cleanData['callMeta'];
          var msgId = (cleanData['message_id'] ?? cleanData['messageId'])?.toString();
          if (msgId == null && callMeta is Map) {
            msgId = (callMeta['message_id'] ?? callMeta['messageId'])?.toString();
          }
          msgId ??= 'call_${DateTime.now().millisecondsSinceEpoch}';
          if (convId != null && callMeta is Map) {
             add(CallLogUpdated(
               conversationId: convId, 
               messageId: msgId, 
               callMeta: Map<String, dynamic>.from(callMeta),
             ));
          }
        } else if (type == 'call_initiated' || type == 'call_incoming') {
          final convId = (cleanData['conversation_id'] ?? cleanData['conversationId'])?.toString();
          final msgId = (cleanData['message_id'] ?? cleanData['messageId'])?.toString() ?? 'call_${DateTime.now().millisecondsSinceEpoch}';
          final callType = (cleanData['call_type'] ?? cleanData['callType'])?.toString() ?? 'audio';
          if (convId != null) {
            add(CallLogUpdated(
              conversationId: convId,
              messageId: msgId,
              callMeta: {
                'callType': callType,
                'status': 'calling',
                'senderId': cleanData['sender_id'] ?? cleanData['senderId'],
              },
            ));
          }
        } else if (type == 'call_answered' || type == 'call_hangup') {
          final convId = (cleanData['conversation_id'] ?? cleanData['conversationId'])?.toString();
          final response = (cleanData['response'] ?? cleanData['status'] ?? (type == 'call_hangup' ? 'completed' : '')).toString();
          final callType = (cleanData['call_type'] ?? cleanData['callType'])?.toString() ?? 'audio';
          if (convId != null) {
            add(CallLogUpdated(
              conversationId: convId,
              messageId: (cleanData['message_id'] ?? cleanData['messageId'])?.toString() ?? 'call_${DateTime.now().millisecondsSinceEpoch}',
              callMeta: {
                'callType': callType,
                'status': response.isNotEmpty ? response : 'answered',
                'senderId': cleanData['sender_id'] ?? cleanData['senderId'],
              },
            ));
          }
        } else if (type == 'user_typing' || type == 'typing') {
          final convId = (cleanData['conversationId'] ?? cleanData['conversation_id'])?.toString();
          final isTypingField = cleanData['is_typing'] ?? cleanData['isTyping'];
          final isTyping = isTypingField is bool ? isTypingField : true;
          final senderId = (cleanData['sender_id'] ?? cleanData['senderId'] ?? cleanData['sender'])?.toString();
          final myId = _storageService.getUserId() ?? '';

          if (convId != null && senderId != myId) {
            add(UpdateChatTypingStatus(
              conversationId: convId,
              isTyping: isTyping,
            ));
          }
        } else if (type == 'conversation_settings_updated' || type == 'disappearing_timer_updated') {
          final convId = (cleanData['conversationId'] ?? cleanData['conversation_id'])?.toString();
          if (convId != null) {
            final dynamic rawTimer = cleanData['disappearing_timer'] ?? cleanData['disappearingTimer'] ?? cleanData['timer'] ?? cleanData['timer_seconds'];
            final int? timerSec = rawTimer != null ? int.tryParse(rawTimer.toString()) : null;
            add(UpdateDisappearingTimer(conversationId: convId, seconds: timerSec));
          }
        } else if (type == 'screen_permission_request') {
          final req = cleanData['request'] ?? cleanData['data'] ?? cleanData;
          if (req is Map) {
            final convId = (req['conversationId'] ?? req['conversation_id'])?.toString();
            final senderId = (req['senderId'] ?? req['sender_id'])?.toString() ?? '';
            final senderName = (req['senderName'] ?? req['sender_name'])?.toString() ?? 'Contact';
            final permType = (req['permissionType'] ?? req['permission_type'])?.toString() ?? 'screenshot';
            final myId = _storageService.getUserId() ?? '';
            final isMe = myId.isNotEmpty && senderId == myId;
            final permLabel = permType == 'screen_record' ? 'screen record' : 'screenshot';
            final count = req['allowedCount'] ?? req['allowed_count'];
            final duration = req['durationSeconds'] ?? req['duration_seconds'];
            final detail = permType == 'screenshot'
                ? '${count ?? 1} screenshot${(count ?? 1) > 1 ? 's' : ''}'
                : '${duration ?? 30}s recording';
            final contentText = isMe
                ? '📷 You requested $permLabel permission ($detail)'
                : '📷 $senderName requested $permLabel permission ($detail)';

            if (convId != null) {
              final lastMsg = LastMessageModel(
                id: (req['id'] ?? req['_id'] ?? 'perm_${DateTime.now().millisecondsSinceEpoch}').toString(),
                conversationId: convId,
                senderId: senderId,
                content: contentText,
                mediaType: 'system',
                createdAt: DateTime.now().toIso8601String(),
                updatedAt: DateTime.now().toIso8601String(),
              );
              add(NewMessageReceived(
                conversationId: convId,
                lastMessage: lastMsg,
                updatedAt: DateTime.now().toIso8601String(),
              ));
            }
          }
        } else if (type == 'screen_permission_response') {
          final req = cleanData['request'] ?? cleanData['data'] ?? cleanData;
          final action = cleanData['action']?.toString() ?? cleanData['status']?.toString() ?? 'rejected';
          if (req is Map) {
            final convId = (req['conversationId'] ?? req['conversation_id'])?.toString();
            final permType = (req['permissionType'] ?? req['permission_type'])?.toString() ?? 'screenshot';
            final permLabel = permType == 'screen_record' ? 'screen record' : 'screenshot';
            final isAccepted = action == 'accept' || action == 'accepted';
            final contentText = isAccepted
                ? '✅ $permLabel permission granted'
                : '❌ $permLabel permission rejected';

            if (convId != null) {
              final lastMsg = LastMessageModel(
                id: (req['id'] ?? req['_id'] ?? 'perm_resp_${DateTime.now().millisecondsSinceEpoch}').toString(),
                conversationId: convId,
                senderId: (req['receiverId'] ?? req['receiver_id'])?.toString() ?? '',
                content: contentText,
                mediaType: 'system',
                createdAt: DateTime.now().toIso8601String(),
                updatedAt: DateTime.now().toIso8601String(),
              );
              add(NewMessageReceived(
                conversationId: convId,
                lastMessage: lastMsg,
                updatedAt: DateTime.now().toIso8601String(),
              ));
            }
          }
        } else if (type == 'message_read' || type == 'read_receipt' || type == 'message_opened') {
          final convId = (cleanData['conversationId'] ?? cleanData['conversation_id'])?.toString();
          final msgId = (cleanData['messageId'] ?? cleanData['message_id'] ?? cleanData['id'])?.toString();
          final msgIdsListRaw = cleanData['messageIds'] ?? cleanData['message_ids'];
          List<String>? msgIdsList;
          if (msgIdsListRaw is List) {
            msgIdsList = msgIdsListRaw.map((e) => e.toString()).toList();
          }
          if (convId != null) {
            add(UpdateMessageStatus(
              conversationId: convId,
              messageId: msgId,
              messageIds: msgIdsList,
              status: 'read',
            ));
          }
        } else if (type == 'delivery_receipt' || type == 'message_delivered') {
          final convId = (cleanData['conversationId'] ?? cleanData['conversation_id'])?.toString();
          final msgId = (cleanData['messageId'] ?? cleanData['message_id'] ?? cleanData['id'])?.toString();
          final msgIdsListRaw = cleanData['messageIds'] ?? cleanData['message_ids'];
          List<String>? msgIdsList;
          if (msgIdsListRaw is List) {
            msgIdsList = msgIdsListRaw.map((e) => e.toString()).toList();
          }
          if (convId != null) {
            add(UpdateMessageStatus(
              conversationId: convId,
              messageId: msgId,
              messageIds: msgIdsList,
              status: 'delivered',
            ));
          }
        }
      } catch (e) {
        // Log error
      }
    });
  }

  static bool _isSameConversation(dynamic id1, dynamic id2) {
    if (id1 == null || id2 == null) return false;
    final s1 = id1.toString().replaceAll('-', '').toLowerCase().trim();
    final s2 = id2.toString().replaceAll('-', '').toLowerCase().trim();
    return s1.isNotEmpty && s1 == s2;
  }

  static DateTime _parseDateTime(dynamic raw) {
    if (raw == null) return DateTime.fromMillisecondsSinceEpoch(0);
    if (raw is DateTime) return raw.toUtc();
    if (raw is num) {
      if (raw > 100000000000) {
        return DateTime.fromMillisecondsSinceEpoch(raw.toInt(), isUtc: true);
      } else if (raw > 0) {
        return DateTime.fromMillisecondsSinceEpoch((raw * 1000).toInt(), isUtc: true);
      }
      return DateTime.fromMillisecondsSinceEpoch(0);
    }
    final s = raw.toString().trim();
    if (s.isEmpty) return DateTime.fromMillisecondsSinceEpoch(0);

    final numVal = num.tryParse(s);
    if (numVal != null && numVal > 100000000) {
      if (numVal > 100000000000) {
        return DateTime.fromMillisecondsSinceEpoch(numVal.toInt(), isUtc: true);
      } else {
        return DateTime.fromMillisecondsSinceEpoch((numVal * 1000).toInt(), isUtc: true);
      }
    }

    final parsed = DateTime.tryParse(s);
    if (parsed != null) return parsed.toUtc();
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  static DateTime getChatActivityTime(ChatModel chat) {
    DateTime latest = DateTime.fromMillisecondsSinceEpoch(0);

    final lastMsg = chat.lastMessage;
    if (lastMsg != null) {
      final cAt = _parseDateTime(lastMsg.createdAt);
      if (cAt.isAfter(latest)) latest = cAt;
      final uAt = _parseDateTime(lastMsg.updatedAt);
      if (uAt.isAfter(latest)) latest = uAt;
    }

    final chatUAt = _parseDateTime(chat.updatedAt);
    if (chatUAt.isAfter(latest)) latest = chatUAt;

    final chatCAt = _parseDateTime(chat.createdAt);
    if (chatCAt.isAfter(latest)) latest = chatCAt;

    return latest;
  }

  bool _hasInitialLoaded = false;

  Future<void> _onFetchChats(FetchChats event, Emitter<ChatsState> emit) async {
    debugPrint('DEBUG: ChatsBloc _onFetchChats triggered');
    if (state is! ChatsLoaded) {
      emit(const ChatsLoading());
    }
    try {
      final result = await _getChatsUseCase.execute();
      debugPrint('DEBUG: ChatsBloc _getChatsUseCase result received');
      result.when(
        success: (chats) {
          debugPrint('DEBUG: ChatsBloc _onFetchChats SUCCESS, chats count: ${chats.length}');
          
          List<ChatModel> finalChats;
          if (_hasInitialLoaded && state is ChatsLoaded) {
            final existingChats = (state as ChatsLoaded).chats;
            final existingMap = {for (var c in existingChats) c.id: c};
            final existingUserMap = {for (var c in existingChats) c.recipient.id: c};

            finalChats = chats.map((newChat) {
              final existing = existingMap[newChat.id] ?? existingUserMap[newChat.recipient.id];
              if (existing != null) {
                final existingPic = existing.recipient.profilePictureUrl;
                if (existingPic != null && existingPic.isNotEmpty) {
                  return newChat.copyWith(
                    recipient: newChat.recipient.copyWith(
                      profilePictureUrl: existingPic,
                    ),
                  );
                }
              }
              return newChat;
            }).toList();
          } else {
            _hasInitialLoaded = true;
            finalChats = List<ChatModel>.from(chats);
          }

          // Sort by most recent message/activity time descending (newest at top)
          final sortedChats = finalChats
            ..sort((a, b) => getChatActivityTime(b).compareTo(getChatActivityTime(a)));
          emit(ChatsLoaded(sortedChats));
        },
        failure: (error, statusCode) {
          debugPrint('DEBUG: ChatsBloc _onFetchChats FAILURE: $error, status: $statusCode');
          if (state is! ChatsLoaded) {
            emit(ChatsError(error));
          }
        },
      );
    } catch (e) {
      debugPrint('DEBUG: ChatsBloc _onFetchChats EXCEPTION: $e');
      if (state is! ChatsLoaded) {
        emit(ChatsError(e.toString()));
      }
    }
  }

  void _onNewMessageReceived(NewMessageReceived event, Emitter<ChatsState> emit) {
    final currentState = state;
    if (currentState is ChatsLoaded) {
      final List<ChatModel> updatedChats = List<ChatModel>.from(currentState.chats);
      final index = updatedChats.indexWhere((c) => _isSameConversation(c.id, event.conversationId));
      final currentUserId = _storageService.getUserId();
      
      if (index != -1) {
        final chat = updatedChats.removeAt(index);
        final isFromMe = event.lastMessage.senderId == currentUserId;
        
        int newUnreadCount = event.unreadCount ?? chat.unreadCount;
        if (event.unreadCount == null && !isFromMe) {
          newUnreadCount = chat.unreadCount + 1;
        } else if (isFromMe) {
          newUnreadCount = 0;
        }

        final updatedChat = chat.copyWith(
          lastMessage: event.lastMessage,
          updatedAt: event.updatedAt,
          unreadCount: newUnreadCount,
        );
        updatedChats.insert(0, updatedChat);
        updatedChats.sort((a, b) => getChatActivityTime(b).compareTo(getChatActivityTime(a)));
        emit(ChatsLoaded(updatedChats));
      } else {
        add(const FetchChats());
      }
    }
  }

  void _onMessageEdited(MessageEdited event, Emitter<ChatsState> emit) {
    final currentState = state;
    if (currentState is ChatsLoaded) {
      final List<ChatModel> updatedChats = currentState.chats.map((chat) {
        if (_isSameConversation(chat.id, event.conversationId) && chat.lastMessage?.id == event.message.id) {
          return chat.copyWith(lastMessage: event.message);
        }
        return chat;
      }).toList();
      emit(ChatsLoaded(updatedChats));
    }
  }

  void _onMessageDeleted(MessageDeleted event, Emitter<ChatsState> emit) {
    final currentState = state;
    if (currentState is ChatsLoaded) {
      final List<ChatModel> updatedChats = currentState.chats.map((chat) {
        if (_isSameConversation(chat.id, event.conversationId) && chat.lastMessage?.id == event.messageId) {
          final updatedLastMessage = chat.lastMessage?.copyWith(isDeleted: true);
          return chat.copyWith(lastMessage: updatedLastMessage);
        }
        return chat;
      }).toList();
      emit(ChatsLoaded(updatedChats));
    }
  }

  void _onRemoveChat(RemoveChat event, Emitter<ChatsState> emit) {
    final currentState = state;
    if (currentState is ChatsLoaded) {
      final List<ChatModel> updatedChats = currentState.chats
          .where((c) => !_isSameConversation(c.id, event.conversationId))
          .toList();
      emit(ChatsLoaded(updatedChats));
    }
  }

  void _onCallLogUpdated(CallLogUpdated event, Emitter<ChatsState> emit) {
    final currentState = state;
    if (currentState is ChatsLoaded) {
      final List<ChatModel> updatedChats = List<ChatModel>.from(currentState.chats);
      final index = updatedChats.indexWhere((c) => _isSameConversation(c.id, event.conversationId));

      final callType = event.callMeta['callType'] ?? event.callMeta['call_type'] ?? 'audio';
      final status = (event.callMeta['status'] ?? 'completed').toString().toLowerCase();
      final String content;

      if (status == 'missed') {
        content = 'Missed $callType call';
      } else if (status == 'rejected' || status == 'busy' || status == 'reject' || status == 'decline' || status == 'declined') {
        content = 'Declined $callType call';
      } else if (status == 'calling') {
        content = '$callType call';
      } else {
        content = '$callType call';
      }

      final nowIso = DateTime.now().toIso8601String();

      if (index != -1) {
        final chat = updatedChats.removeAt(index);
        final currentUserId = _storageService.getUserId() ?? '';
        final senderId = (event.callMeta['senderId'] ?? event.callMeta['sender_id'] ?? '').toString();
        final isFromMe = senderId.isNotEmpty && senderId == currentUserId;
        final isMissed = status == 'missed' || status == 'reject' || status == 'rejected' || status == 'decline' || status == 'declined';

        final existingMsg = chat.lastMessage;
        final updatedLastMessage = existingMsg != null
            ? existingMsg.copyWith(
                id: event.messageId,
                mediaType: 'call',
                content: content,
                senderId: senderId.isNotEmpty ? senderId : existingMsg.senderId,
                updatedAt: nowIso,
              )
            : LastMessageModel(
                id: event.messageId,
                conversationId: event.conversationId,
                senderId: senderId.isNotEmpty ? senderId : currentUserId,
                content: content,
                mediaType: 'call',
                createdAt: nowIso,
                updatedAt: nowIso,
              );

        final updatedChat = chat.copyWith(
          lastMessage: updatedLastMessage,
          updatedAt: nowIso,
          unreadCount: (!isFromMe && isMissed) ? chat.unreadCount + 1 : chat.unreadCount,
        );

        updatedChats.insert(0, updatedChat);
        updatedChats.sort((a, b) => getChatActivityTime(b).compareTo(getChatActivityTime(a)));
        emit(ChatsLoaded(updatedChats));
      } else {
        add(const FetchChats());
      }
    }
  }

  void _onUpdateUserStatus(UpdateUserStatus event, Emitter<ChatsState> emit) {
    final currentState = state;
    if (currentState is ChatsLoaded) {
       final List<ChatModel> updatedChats = currentState.chats.map((chat) {
        if (!chat.isGroup && chat.recipient.id == event.userId) {
          final updatedRecipient = chat.recipient.copyWith(
            isOnline: event.isOnline,
            lastSeen: event.lastSeen ?? chat.recipient.lastSeen,
          );
          return chat.copyWith(recipient: updatedRecipient);
        }
        return chat;
      }).toList();
      emit(ChatsLoaded(updatedChats));
    }
  }

  void _onUpdateChatTypingStatus(UpdateChatTypingStatus event, Emitter<ChatsState> emit) {
    final currentState = state;
    if (currentState is ChatsLoaded) {
      final List<ChatModel> updatedChats = currentState.chats.map((chat) {
        if (_isSameConversation(chat.id, event.conversationId)) {
          return chat.copyWith(isTyping: event.isTyping);
        }
        return chat;
      }).toList();
      emit(ChatsLoaded(updatedChats));
    }
  }

  void _onUpdateDisappearingTimer(UpdateDisappearingTimer event, Emitter<ChatsState> emit) {
    final currentState = state;
    if (currentState is ChatsLoaded) {
      final List<ChatModel> updatedChats = currentState.chats.map((chat) {
        if (_isSameConversation(chat.id, event.conversationId)) {
          return chat.copyWith(disappearingTimer: event.seconds);
        }
        return chat;
      }).toList();
      emit(ChatsLoaded(updatedChats));
    }
  }

  void _onUpdateMessageStatus(UpdateMessageStatus event, Emitter<ChatsState> emit) {
    final currentState = state;
    if (currentState is ChatsLoaded) {
      final List<ChatModel> updatedChats = currentState.chats.map((chat) {
        if (_isSameConversation(chat.id, event.conversationId)) {
          final lastMsg = chat.lastMessage;
          if (lastMsg != null) {
            final isTarget = event.messageId == null ||
                lastMsg.id == event.messageId ||
                (event.messageIds != null && event.messageIds!.contains(lastMsg.id));
            if (isTarget) {
              final isRead = event.status == 'read' || lastMsg.isRead;
              final isDelivered = event.status == 'delivered' || isRead || lastMsg.isDelivered;
              final updatedLastMsg = lastMsg.copyWith(
                isRead: isRead,
                isDelivered: isDelivered,
                status: isRead ? 'read' : (isDelivered ? 'delivered' : lastMsg.status),
              );
              return chat.copyWith(
                lastMessage: updatedLastMsg,
                unreadCount: event.status == 'read' ? 0 : chat.unreadCount,
              );
            }
          }
        }
        return chat;
      }).toList();
      emit(ChatsLoaded(updatedChats));
    }
  }

  Future<void> _onCreateChat(CreateChat event, Emitter<ChatsState> emit) async {
    emit(const ChatsLoading());
    final result = await _chatRepository.startDirectChat(event.participantId);

    await result.when(
      success: (chat) async {
        emit(
          ChatCreated(
            chat,
            event.contactName,
            profilePictureUrl: event.profilePictureUrl,
          ),
        );
      },
      failure: (error, statusCode) {
        emit(ChatsError(error));
      },
    );
  }

  @override
  Future<void> close() {
    _socketSubscription?.cancel();
    return super.close();
  }
}
