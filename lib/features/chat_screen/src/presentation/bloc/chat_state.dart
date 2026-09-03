import 'package:flutter/material.dart';
import 'package:schat/features/chat_screen/src/domain/models/message_model.dart';
import 'package:schat/features/chat_screen/src/domain/models/message_shares_model.dart';
import 'package:schat/features/chat_screen/src/domain/models/theme_color_model.dart';

abstract class ChatState {
  const ChatState();
}

class ChatInitial extends ChatState {
  const ChatInitial();
}

class ChatLoading extends ChatState {
  const ChatLoading();
}

class ChatLoaded extends ChatState {
  final List<MessageModel> messages;
  final List<MessageModel> pinnedMessages;
  final bool isMuted;
  final bool isLocked;
  final bool isFavorite;
  final String myId;
  final bool isRecipientOnline;
  final bool isRecipientTyping;
  final String? lastSeen;
  final Color? customBgColor;
  final String? notificationMessage;
  // Theme from server API
  final ThemeColorModel? themeColor;
  final List<ThemeColorModel> availableThemes;

  // Share tracking (populated after FetchMessageSharesEvent)
  final MessageSharesModel? sharesData;
  final String? sharesMessageId;

  // Group info — updated in real time via group_updated WebSocket event
  final String? groupName;
  final String? groupPictureUrl;
  final int? disappearingTimer;

  const ChatLoaded({
    required this.messages,
    this.pinnedMessages = const [],
    this.isMuted = false,
    this.isLocked = false,
    this.isFavorite = false,
    this.myId = '',
    this.isRecipientOnline = false,
    this.isRecipientTyping = false,
    this.lastSeen,
    this.customBgColor,
    this.notificationMessage,
    this.themeColor,
    this.availableThemes = const [],
    this.sharesData,
    this.sharesMessageId,
    this.groupName,
    this.groupPictureUrl,
    this.disappearingTimer,
  });

  ChatLoaded copyWith({
    List<MessageModel>? messages,
    List<MessageModel>? pinnedMessages,
    bool? isMuted,
    bool? isLocked,
    bool? isFavorite,
    String? myId,
    bool? isRecipientOnline,
    bool? isRecipientTyping,
    String? lastSeen,
    Color? customBgColor,
    String? notificationMessage,
    ThemeColorModel? themeColor,
    bool clearThemeColor = false,
    List<ThemeColorModel>? availableThemes,
    MessageSharesModel? sharesData,
    bool clearSharesData = false,
    String? sharesMessageId,
    String? groupName,
    String? groupPictureUrl,
    int? disappearingTimer,
  }) {
    return ChatLoaded(
      messages: messages ?? this.messages,
      pinnedMessages: pinnedMessages ?? this.pinnedMessages,
      isMuted: isMuted ?? this.isMuted,
      isLocked: isLocked ?? this.isLocked,
      isFavorite: isFavorite ?? this.isFavorite,
      myId: myId ?? this.myId,
      isRecipientOnline: isRecipientOnline ?? this.isRecipientOnline,
      isRecipientTyping: isRecipientTyping ?? this.isRecipientTyping,
      lastSeen: lastSeen ?? this.lastSeen,
      customBgColor: customBgColor ?? this.customBgColor,
      notificationMessage: notificationMessage,
      themeColor: clearThemeColor ? null : (themeColor ?? this.themeColor),
      availableThemes: availableThemes ?? this.availableThemes,
      sharesData: clearSharesData ? null : (sharesData ?? this.sharesData),
      sharesMessageId: sharesMessageId ?? this.sharesMessageId,
      groupName: groupName ?? this.groupName,
      groupPictureUrl: groupPictureUrl ?? this.groupPictureUrl,
      disappearingTimer: disappearingTimer ?? this.disappearingTimer,
    );
  }
}

class ChatError extends ChatState {
  final String errorMessage;
  const ChatError({required this.errorMessage});
}

class ChatDeleted extends ChatState {
  const ChatDeleted();
}
