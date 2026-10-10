import 'package:flutter/material.dart';
import 'package:schat/features/chat_screen/src/domain/models/message_model.dart';
import 'package:schat/features/chat_screen/src/domain/models/message_shares_model.dart';
import 'package:schat/features/chat_screen/src/domain/models/theme_color_model.dart';

import 'package:schat/features/chat_screen/src/domain/models/screen_permission_model.dart';

import 'package:collection/collection.dart';

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
  // Theme & Wallpaper from server API
  final ThemeColorModel? themeColor;
  final String? customWallpaperUrl;
  final List<ThemeColorModel> availableThemes;

  // Share tracking (populated after FetchMessageSharesEvent)
  final MessageSharesModel? sharesData;
  final String? sharesMessageId;

  // Group info — updated in real time via group_updated WebSocket event
  final String? groupName;
  final String? groupPictureUrl;
  final int? disappearingTimer;
  final bool onlyAdminsSendMessages;

  // Screen permissions (active granted permissions for current user & incoming pending requests)
  final List<ScreenPermissionModel> activeScreenPermissions;
  final ScreenPermissionModel? incomingScreenPermissionRequest;

  ScreenPermissionModel? get activeScreenPermission {
    final valid = activeScreenPermissions.where((p) =>
        !p.isCompleted &&
        !p.isRejected &&
        ((p.isScreenshot && (p.remainingCount ?? p.allowedCount ?? 1) > 0) ||
            (p.isScreenRecord && p.durationSeconds != null)));
    return valid.isNotEmpty ? valid.first : null;
  }

  int get totalRemainingScreenshots => activeScreenPermissions
      .where((p) => p.isScreenshot && !p.isCompleted && !p.isRejected)
      .fold(0, (sum, p) => sum + (p.remainingCount ?? p.allowedCount ?? 0));

  int get totalAllowedScreenshots => activeScreenPermissions
      .where((p) => p.isScreenshot && !p.isCompleted && !p.isRejected)
      .fold(0, (sum, p) => sum + (p.allowedCount ?? 1));

  ScreenPermissionModel? get firstActiveScreenshotPermission =>
      activeScreenPermissions.firstWhereOrNull(
        (p) =>
            p.isScreenshot &&
            !p.isCompleted &&
            !p.isRejected &&
            (p.remainingCount ?? p.allowedCount ?? 1) > 0,
      );

  ScreenPermissionModel? get firstActiveScreenRecordPermission =>
      activeScreenPermissions.firstWhereOrNull(
        (p) =>
            p.isScreenRecord &&
            !p.isCompleted &&
            !p.isRejected &&
            p.durationSeconds != null,
      );

  // Privacy settings (null = inherit global, true = on, false = off)
  final bool? readReceiptsEnabled;
  final bool? typingIndicatorsEnabled;

  // Block state
  final bool isBlocked;
  final bool isBlockedByMe;
  final bool isBlockedByOther;

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
    this.customWallpaperUrl,
    this.availableThemes = const [],
    this.sharesData,
    this.sharesMessageId,
    this.groupName,
    this.groupPictureUrl,
    this.disappearingTimer,
    this.onlyAdminsSendMessages = false,
    this.activeScreenPermissions = const [],
    ScreenPermissionModel? activeScreenPermission,
    this.incomingScreenPermissionRequest,
    this.readReceiptsEnabled,
    this.typingIndicatorsEnabled,
    this.isBlocked = false,
    this.isBlockedByMe = false,
    this.isBlockedByOther = false,
  }) : super();

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
    String? customWallpaperUrl,
    bool clearCustomWallpaperUrl = false,
    List<ThemeColorModel>? availableThemes,
    MessageSharesModel? sharesData,
    bool clearSharesData = false,
    String? sharesMessageId,
    String? groupName,
    String? groupPictureUrl,
    int? disappearingTimer,
    bool clearDisappearingTimer = false,
    bool? onlyAdminsSendMessages,
    List<ScreenPermissionModel>? activeScreenPermissions,
    bool clearActiveScreenPermissions = false,
    ScreenPermissionModel? activeScreenPermission,
    bool clearActiveScreenPermission = false,
    ScreenPermissionModel? incomingScreenPermissionRequest,
    bool clearIncomingScreenPermissionRequest = false,
    bool? readReceiptsEnabled,
    bool clearReadReceiptsEnabled = false,
    bool? typingIndicatorsEnabled,
    bool clearTypingIndicatorsEnabled = false,
    bool? isBlocked,
    bool? isBlockedByMe,
    bool? isBlockedByOther,
  }) {
    List<ScreenPermissionModel> resolvedPermissions;
    if (clearActiveScreenPermissions || clearActiveScreenPermission) {
      resolvedPermissions = const [];
    } else if (activeScreenPermissions != null) {
      resolvedPermissions = activeScreenPermissions;
    } else if (activeScreenPermission != null) {
      final list = List<ScreenPermissionModel>.from(this.activeScreenPermissions);
      final idx = list.indexWhere((p) => p.id == activeScreenPermission.id);
      if (idx >= 0) {
        list[idx] = activeScreenPermission;
      } else {
        list.add(activeScreenPermission);
      }
      resolvedPermissions = list;
    } else {
      resolvedPermissions = this.activeScreenPermissions;
    }

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
      customWallpaperUrl: clearCustomWallpaperUrl
          ? null
          : (customWallpaperUrl ?? this.customWallpaperUrl),
      availableThemes: availableThemes ?? this.availableThemes,
      sharesData: clearSharesData ? null : (sharesData ?? this.sharesData),
      sharesMessageId: sharesMessageId ?? this.sharesMessageId,
      groupName: groupName ?? this.groupName,
      groupPictureUrl: groupPictureUrl ?? this.groupPictureUrl,
      disappearingTimer: clearDisappearingTimer
          ? null
          : (disappearingTimer ?? this.disappearingTimer),
      onlyAdminsSendMessages: onlyAdminsSendMessages ?? this.onlyAdminsSendMessages,
      activeScreenPermissions: resolvedPermissions,
      incomingScreenPermissionRequest: clearIncomingScreenPermissionRequest
          ? null
          : (incomingScreenPermissionRequest ?? this.incomingScreenPermissionRequest),
      readReceiptsEnabled: clearReadReceiptsEnabled
          ? null
          : (readReceiptsEnabled ?? this.readReceiptsEnabled),
      typingIndicatorsEnabled: clearTypingIndicatorsEnabled
          ? null
          : (typingIndicatorsEnabled ?? this.typingIndicatorsEnabled),
      isBlocked: isBlocked ?? this.isBlocked,
      isBlockedByMe: isBlockedByMe ?? this.isBlockedByMe,
      isBlockedByOther: isBlockedByOther ?? this.isBlockedByOther,
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
