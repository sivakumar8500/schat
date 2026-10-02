import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:record/record.dart';
import 'package:hive/hive.dart';
import 'package:schat/core/storage/storage_service.dart';
import 'package:schat/core/security/screen_protection_service.dart';
import 'package:schat/core/security/secure_attachment_service.dart';
import 'package:schat/injection.dart';
import 'package:schat/features/dashboard_screen/src/domain/repositories/dashboard_repository.dart';
import 'package:schat/features/profile_screen/src/domain/models/user_model.dart';
import 'package:schat/features/profile_screen/src/domain/repositories/profile_repository.dart';
import 'package:schat/features/chat_socket_screen/src/domain/chat_socket_repository.dart';
import 'package:schat/core/notifications/in_app_notification_service.dart';
import 'package:schat/utils/common_fontstyles.dart';
import 'package:schat/utils/common_fonts.dart';
import 'package:schat/utils/common_strings.dart';
import 'package:schat/utils/common_spaces.dart';
import 'package:schat/utils/common_colors.dart';
import 'package:schat/utils/common_icons.dart';
import 'package:schat/utils/common_notifications.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:fast_contacts/fast_contacts.dart';
import 'package:schat/features/dashboard_screen/src/domain/repositories/contacts_repository.dart';
import 'package:schat/features/dashboard_screen/src/domain/models/chat_model.dart';
import 'package:schat/features/dashboard_screen/src/presentation/bloc/contacts_bloc.dart';
import 'package:schat/features/dashboard_screen/src/presentation/bloc/contacts_event.dart';
import 'package:schat/features/dashboard_screen/src/presentation/bloc/contacts_state.dart';
import 'package:schat/features/dashboard_screen/src/presentation/bloc/chats_bloc.dart';
import 'package:schat/features/dashboard_screen/src/presentation/bloc/chats_state.dart';
import 'package:schat/features/dashboard_screen/src/presentation/widgets/create_group_bottom_sheet.dart';
import 'widgets/message_bubble.dart';
import 'widgets/schedule_message_bottom_sheet.dart';
import 'widgets/location_share_bottom_sheet.dart';
import 'widgets/request_screen_permission_bottom_sheet.dart';
import 'widgets/chat_lock_bottom_sheet.dart';
import 'package:collection/collection.dart';
import 'contact_profile_page.dart';
import 'full_screen_image_page.dart';
import 'group_info_page.dart';
import 'shared_media_page.dart';
import 'attachment_preview_page.dart';
import 'package:schat/utils/permission_helper.dart';
import '../../../call_screen/call_screen.dart';
import 'widgets/chat_theme_bottom_sheet.dart';
import 'package:schat/utils/common_endpoints.dart';
import '../domain/models/message_model.dart';
import '../domain/models/chat_media_model.dart';
import '../domain/models/theme_color_model.dart';
import 'package:schat/features/chat_screen/src/presentation/bloc/chat_bloc.dart';
import 'package:schat/features/chat_screen/src/presentation/bloc/chat_event.dart';
import 'package:schat/features/chat_screen/src/presentation/bloc/chat_state.dart';
import 'package:schat/features/chat_socket_screen/src/presentation/bloc/chat_socket_bloc.dart';
import 'package:schat/features/chat_socket_screen/src/presentation/bloc/chat_socket_event.dart';
import 'package:schat/features/chat_screen/src/domain/repositories/chat_repository.dart';


class ChatPage extends StatefulWidget {
  final String conversationId;
  final String contactName;
  final Color contactColor;
  final bool isOnline;
  final String? profilePictureUrl;
  final String recipientId;
  final bool isGroup;
  final ThemeColorModel? initialThemeColor;
  final String? initialCustomWallpaperUrl;
  final String? initialSharedText;
  final String? initialSharedFilePath;
  final String? initialSharedFileName;
  final String? initialSharedFileType;
  final int? initialDisappearingTimer;
  final bool isReadOnly;
  final bool isBlocked;
  final bool isBlockedByMe;
  final bool isBlockedByOther;
  final bool? initialReadReceiptsEnabled;
  final bool? initialTypingIndicatorsEnabled;
  final bool initialIsLocked;

  const ChatPage({
    super.key,
    required this.conversationId,
    required this.contactName,
    required this.contactColor,
    required this.isOnline,
    required this.recipientId,
    this.isGroup = false,
    this.profilePictureUrl,
    this.initialThemeColor,
    this.initialCustomWallpaperUrl,
    this.initialSharedText,
    this.initialSharedFilePath,
    this.initialSharedFileName,
    this.initialSharedFileType,
    this.initialDisappearingTimer,
    this.isReadOnly = false,
    this.isBlocked = false,
    this.isBlockedByMe = false,
    this.isBlockedByOther = false,
    this.initialReadReceiptsEnabled,
    this.initialTypingIndicatorsEnabled,
    this.initialIsLocked = false,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isTyping = false;
  bool _showAttachmentGrid = false;
  bool _isSearching = false;
  String _searchQuery = '';
  final FocusNode _inputFocusNode = FocusNode();

  late ChatBloc _chatBloc;
  Timer? _typingIndicatorTimer;
  late CallWebRtcBloc _callWebRtcBloc;
  StreamSubscription? _callSocketSubscription;
  StreamSubscription? _screenshotSubscription;
  Timer? _screenRecordTimer;
  String? _activeScreenRecordPermissionId;
  Timer? _screenshotAutoExpireTimer;
  String? _activeScreenshotPermissionId;

  final Set<String> _selectedMessageIds = {};
  MessageModel? _replyingToMessage;
  MessageModel? _editingMessage;
  
  String? _selectedAttachmentPath;
  String? _selectedAttachmentName;
  String? _selectedAttachmentType; // 'image', 'video', 'audio', 'file', 'location', 'contact'
  Uint8List? _selectedAttachmentBytes;
  int _selectedAttachmentSize = 0;
  bool _attachmentAllowShare = false;
  bool _attachmentAllowDownload = false;
  bool _attachmentAllowView = true;
  bool _attachmentIsViewOnce = false;
  int _attachmentViewCount = 1;
  Offset? _tapPosition;

  // Voice recording state
  final AudioRecorder _audioRecorder = AudioRecorder();
  bool _isRecording = false;
  int _recordDurationSeconds = 0;
  Timer? _recordingTimer;

  // Recorded voice preview state
  Uint8List? _recordedBytes;
  String? _recordedPath;
  String? _recordedName;
  int _recordedDurationSecs = 0;

  // Preview playback state
  final AudioPlayer _previewPlayer = AudioPlayer();
  bool _isPlayingPreview = false;
  int _previewPositionSecs = 0;
  Timer? _previewPositionTimer;

  bool _isAdmin = false;
  bool _onlyAdminsSendMessages = false;
  Map<String, String> _groupParticipantNames = {};
  Map<String, String?> _groupParticipantProfilePics = {};
  List<UserModel> _groupParticipants = [];
  bool _showMentionSuggestions = false;
  String _mentionQuery = '';
  bool _showUnknownContactBanner = false;

  late String _effectiveContactName;
  late String? _effectiveProfilePic;
  late bool _effectiveIsGroup;

  @override
  void initState() {
    super.initState();
    _effectiveContactName = widget.contactName;
    _effectiveProfilePic = widget.profilePictureUrl;
    _effectiveIsGroup = widget.isGroup;
    _resolveConversationDetails();

    if (widget.isGroup) {
      _checkIfAdmin();
    }
    _inputFocusNode.addListener(() {
      if (_inputFocusNode.hasFocus) {
        setState(() {
          _showAttachmentGrid = false;
        });
      }
    });
    debugPrint('DEBUG: ChatPage Initializing for conv: ${widget.conversationId}, recipient: ${widget.recipientId}, initialOnline: ${widget.isOnline}');
    _checkUnknownContactStatus();
    getIt<InAppNotificationService>().setActiveChat(
      conversationId: widget.conversationId,
      recipientId: widget.recipientId,
    );
    _chatBloc = ChatBloc()..add(LoadMessagesEvent(
      conversationId: widget.conversationId,
      recipientId: widget.recipientId,
      initialIsOnline: widget.isOnline,
      initialThemeColor: widget.initialThemeColor,
      initialCustomWallpaperUrl: widget.initialCustomWallpaperUrl,
      initialDisappearingTimer: widget.initialDisappearingTimer,
      initialIsBlocked: widget.isBlocked,
      initialIsBlockedByMe: widget.isBlockedByMe,
      initialIsBlockedByOther: widget.isBlockedByOther,
      initialReadReceiptsEnabled: widget.initialReadReceiptsEnabled,
      initialTypingIndicatorsEnabled: widget.initialTypingIndicatorsEnabled,
      initialIsLocked: widget.initialIsLocked,
    ));

    // Pre-populate with shared text if provided
    if (widget.initialSharedText != null && widget.initialSharedText!.isNotEmpty) {
      _messageController.text = widget.initialSharedText!;
      _isTyping = true;
    }

    // Init CallWebRtcBloc and listen for incoming call socket events
    _callWebRtcBloc = getIt<CallWebRtcBloc>();
    // _listenForCallEvents(); // CallWebRtcBloc now listens to socket internally

    // Listen to preview player events
    _previewPlayer.onPlayerComplete.listen((_) {
      if (mounted) {
        setState(() {
          _isPlayingPreview = false;
          _previewPositionSecs = _recordedDurationSecs;
        });
      }
    });
    _previewPlayer.onPositionChanged.listen((p) {
      if (mounted && _isPlayingPreview) {
        setState(() {
          _previewPositionSecs = p.inSeconds;
        });
      }
    });

    // Listen for screenshots to decrement allowed count and auto turn off
    _screenshotSubscription = getIt<ScreenProtectionService>().onScreenshot.listen((_) {
      final state = _chatBloc.state;
      if (state is ChatLoaded && state.activeScreenPermission != null && state.activeScreenPermission!.isScreenshot) {
        final perm = state.activeScreenPermission!;
        final currentRemaining = perm.remainingCount ?? perm.allowedCount ?? 1;
        final newRemaining = currentRemaining - 1;
        debugPrint('ScreenProtection: Screenshot taken! newRemaining=$newRemaining / ${perm.allowedCount}');

        if (newRemaining <= 0) {
          // Immediately re-enable protection locally with 0 delay so no further screenshots are possible!
          getIt<ScreenProtectionService>().enableProtection();
          if (mounted) {
            context.showInfoNotification('All allowed screenshot(s) taken (${perm.allowedCount}/${perm.allowedCount}). Protection re-enabled.');
          }
        } else {
          if (mounted) {
            context.showInfoNotification('Screenshot taken. $newRemaining of ${perm.allowedCount} screenshot(s) remaining.');
          }
        }

        _chatBloc.add(ConsumeScreenPermissionEvent(requestId: perm.id));
      }
    });
  }

  Future<void> _resolveConversationDetails() async {
    try {
      // 1. Try to match from local ChatsBloc state
      try {
        final chatsBloc = getIt<ChatsBloc>();
        final state = chatsBloc.state;
        if (state is ChatsLoaded) {
          final matched = state.chats.firstWhereOrNull((c) => c.id == widget.conversationId);
          if (matched != null) {
            final resolvedName = matched.isGroup
                ? (matched.groupName ?? 'Group')
                : matched.recipient.displayName;
            if (mounted &&
                resolvedName.isNotEmpty &&
                (resolvedName != _effectiveContactName ||
                    _effectiveContactName == 'sChat' ||
                    _effectiveContactName == 'Chat' ||
                    _effectiveContactName == 'New Message')) {
              setState(() {
                _effectiveContactName = resolvedName;
                _effectiveIsGroup = matched.isGroup;
                _effectiveProfilePic = matched.recipient.profilePictureUrl ?? _effectiveProfilePic;
              });
              return;
            }
          }
        }
      } catch (_) {}

      // 2. Fetch from backend if name is missing/generic or to guarantee up-to-date group info
      if (_effectiveContactName.isEmpty ||
          _effectiveContactName == 'sChat' ||
          _effectiveContactName == 'Chat' ||
          _effectiveContactName == 'New Message') {
        final result = await getIt<DashboardRepository>().getChats();
        result.when(
          success: (chats) {
            final matched = chats.firstWhereOrNull((c) => c.id == widget.conversationId);
            if (matched != null && mounted) {
              final resolvedName = matched.isGroup
                  ? (matched.groupName ?? 'Group')
                  : matched.recipient.displayName;
              if (resolvedName.isNotEmpty) {
                setState(() {
                  _effectiveContactName = resolvedName;
                  _effectiveIsGroup = matched.isGroup;
                  _effectiveProfilePic = matched.recipient.profilePictureUrl ?? _effectiveProfilePic;
                });
              }
            }
          },
          failure: (error, code) {},
        );
      }
    } catch (e) {
      debugPrint('Error resolving conversation details in ChatPage: $e');
    }
  }

  Future<List<UserModel>> _getForwardContacts() async {
    try {
      final contactsRepo = getIt<ContactsRepository>();
      final Map<String, UserModel> userMap = {};

      // 1. Load cached contacts
      final cached = await contactsRepo.getCachedContacts();
      for (final u in cached) {
        if (u.id.isNotEmpty) userMap[u.id] = u;
      }

      // 2. If ContactsBloc is loaded, merge its synced contacts
      try {
        final contactsBloc = getIt<ContactsBloc>();
        if (contactsBloc.state is ContactsLoaded) {
          final blocUsers = (contactsBloc.state as ContactsLoaded).syncedContacts;
          for (final u in blocUsers) {
            if (u.id.isNotEmpty) userMap[u.id] = u;
          }
        }
      } catch (_) {}

      // 3. If list is still empty, fetch synced contacts from server
      if (userMap.isEmpty) {
        final res = await contactsRepo.fetchSyncedContacts();
        res.when(
          success: (list) {
            for (final u in list) {
              if (u.id.isNotEmpty) userMap[u.id] = u;
            }
          },
          failure: (_, _) {},
        );
      }

      // 4. Merge recent active chat recipients from ChatsBloc if available
      try {
        final chatsBloc = getIt<ChatsBloc>();
        if (chatsBloc.state is ChatsLoaded) {
          for (final chat in (chatsBloc.state as ChatsLoaded).chats) {
            if (!chat.isGroup && chat.recipient.id.isNotEmpty) {
              final r = chat.recipient;
              if (!userMap.containsKey(r.id)) {
                userMap[r.id] = UserModel(
                  id: r.id,
                  username: r.username,
                  phoneNumber: r.phoneNumber,
                  profilePictureUrl: r.profilePictureUrl,
                  contactName: r.displayName.isNotEmpty ? r.displayName : r.username,
                  about: r.about,
                  isOnline: r.isOnline,
                );
              } else {
                final existing = userMap[r.id]!;
                if ((existing.profilePictureUrl == null || existing.profilePictureUrl!.isEmpty) &&
                    (r.profilePictureUrl != null && r.profilePictureUrl!.isNotEmpty)) {
                  userMap[r.id] = existing.copyWith(
                    profilePictureUrl: r.profilePictureUrl,
                    about: existing.about ?? r.about,
                  );
                }
              }
            }
          }
        }
      } catch (_) {}

      final myId = getIt<StorageService>().getUserId();
      return userMap.values.where((user) {
        final isMe = user.id == myId;
        final isCurrentRecipient = user.id == widget.recipientId;
        return !isMe && !isCurrentRecipient;
      }).toList();
    } catch (e) {
      debugPrint('Error loading forward contacts: $e');
    }
    return [];
  }

  void _scrollToMessage(String messageId) {
    if (_chatBloc.state is! ChatLoaded) return;
    final state = _chatBloc.state as ChatLoaded;

    final displayedMessages = state.messages.where((m) {
      if (m.isDeletedForMe) return false;
      if (_isSearching && _searchQuery.isNotEmpty) {
        return m.content.toLowerCase().contains(_searchQuery.toLowerCase());
      }
      return true;
    }).toList();

    final indexInList = displayedMessages.indexWhere((m) => m.id == messageId);
    if (indexInList != -1) {
      // In a reverse ListView, index 0 is at the bottom (newest).
      // Our displayedMessages list is oldest-to-newest.
      // So the builder index for the message at indexInList is:
      final builderIndex = displayedMessages.length - 1 - indexInList;

      // Estimate offset. Standard approach without ScrollablePositionedList
      // We can jump roughly to the area.
      const double estimatedItemHeight = 120.0;
      final targetOffset = builderIndex * estimatedItemHeight;

      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          targetOffset,
          duration: const Duration(milliseconds: 600),
          curve: Curves.fastOutSlowIn,
        );
      }
    } else {
      context.showInfoNotification('Message not found in current view');
    }
  }

  Widget _buildPinnedMessageBanner(ChatState state) {
    if (state is! ChatLoaded || state.pinnedMessages.isEmpty) return const SizedBox.shrink();

    final latestPinned = state.pinnedMessages.first;
    final totalPinned = state.pinnedMessages.length;

    return GestureDetector(
      onTap: () => _scrollToMessage(latestPinned.id),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: context.colors.lightBackground,
          border: Border(
            bottom: BorderSide(
              color: context.colors.border,
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            Icon(CommonIcons.pin, color: context.colors.primary, size: 20),
            CommonSpaces.w12,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    totalPinned > 1 ? 'Pinned Messages ($totalPinned)' : 'Pinned Message',
                    style: context.bodySmall.copyWith(
                      fontWeight: FontWeight.bold,
                      color: context.colors.primary,
                    ),
                  ),
                  Text(
                    latestPinned.content.isEmpty ? (latestPinned.mediaType ?? 'Attachment') : latestPinned.content,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.bodyMedium.copyWith(
                      color: context.colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (totalPinned > 1)
              IconButton(
                icon: Icon(Icons.keyboard_arrow_down, color: context.colors.textSecondary),
                onPressed: () => _showPinnedMessagesList(context, state.pinnedMessages),
              ),
            IconButton(
              icon: Icon(CommonIcons.close, color: context.colors.textSecondary, size: 18),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: () {
                _chatBloc.add(PinMessageEvent(
                  messageId: latestPinned.id,
                  conversationId: widget.conversationId,
                  isPinned: false,
                ));
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showPinnedMessagesList(BuildContext context, List<MessageModel> pinnedMessages) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          decoration: BoxDecoration(
            color: context.colors.scaffoldBackground,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: context.colors.textHint.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Row(
                children: [
                  Icon(CommonIcons.pin, color: context.colors.primary, size: 24),
                  CommonSpaces.w12,
                  Text(
                    'Pinned Messages',
                    style: context.titleLarge.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              CommonSpaces.h16,
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: pinnedMessages.length,
                  separatorBuilder: (_, _) => const Divider(),
                  itemBuilder: (context, index) {
                    final msg = pinnedMessages[index];
                    return ListTile(
                      onTap: () {
                        Navigator.pop(context);
                        _scrollToMessage(msg.id);
                      },
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        msg.content.isEmpty ? (msg.mediaType ?? 'Attachment') : msg.content,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: context.bodyMedium,
                      ),
                      subtitle: Text(
                        _formatTime(msg.createdAt),
                        style: context.bodySmall.copyWith(color: context.colors.textSecondary),
                      ),
                      trailing: IconButton(
                        icon: Icon(CommonIcons.close, size: 20),
                        onPressed: () {
                          _chatBloc.add(PinMessageEvent(
                            messageId: msg.id,
                            conversationId: widget.conversationId,
                            isPinned: false,
                          ));
                          if (pinnedMessages.length == 1) {
                            Navigator.pop(context);
                          }
                        },
                      ),
                    );
                  },
                ),
              ),
              CommonSpaces.h20,
            ],
          ),
        );
      },
    );
  }

  Widget _buildRecordingBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: context.colors.error.withValues(alpha: 0.05),
        border: Border(
          top: BorderSide(color: context.colors.error.withValues(alpha: 0.3), width: 1),
        ),
      ),
      child: Row(
        children: [
          // Pulsing red dot
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.4, end: 1.0),
            duration: const Duration(milliseconds: 600),
            builder: (context, value, _) => Opacity(
              opacity: value,
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: context.colors.error,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
          CommonSpaces.w10,
          Icon(CommonIcons.mic, color: context.colors.error, size: 20),
          CommonSpaces.w8,
          Text(
            _formatRecordingDuration(_recordDurationSeconds),
            style: context.bodyMedium.copyWith(
              color: context.colors.error,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          Text(
            'Tap mic to stop',
            style: context.bodySmall.copyWith(
              color: context.colors.textSecondary,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVoicePreviewBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: context.colors.lightBackground,
        border: Border(
          top: BorderSide(color: context.colors.border, width: 1),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              // Cancel button
              GestureDetector(
                onTap: _cancelRecording,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: context.colors.error.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(CommonIcons.close, color: context.colors.error, size: 18),
                ),
              ),
              CommonSpaces.w12,
              // Play/Pause + waveform + duration
              Expanded(
                child: GestureDetector(
                  onTap: _togglePreviewPlayback,
                  child: Container(
                    height: 48,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: context.colors.lightBackground,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: context.colors.primary.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        // Play / Pause icon
                        Icon(
                          _isPlayingPreview
                              ? CommonIcons.pause
                              : CommonIcons.playArrowRounded,
                          color: context.colors.primary,
                          size: 22,
                        ),
                        CommonSpaces.w8,
                        // Waveform bars (progress-tinted)
                        Expanded(
                          child: LayoutBuilder(builder: (context, constraints) {
                            const barCount = 20;
                            final progress = _recordedDurationSecs > 0
                                ? (_previewPositionSecs / _recordedDurationSecs).clamp(0.0, 1.0)
                                : 0.0;
                            final filledBars = (barCount * progress).round();
                            final heights = [12.0, 20.0, 14.0, 24.0, 16.0, 28.0,
                                             18.0, 22.0, 10.0, 26.0, 14.0, 20.0,
                                             12.0, 18.0, 24.0, 16.0, 20.0, 12.0,
                                             22.0, 14.0];
                            return Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: List.generate(barCount, (i) {
                                final filled = i < filledBars;
                                return Container(
                                  width: 3,
                                  height: heights[i % heights.length],
                                  decoration: BoxDecoration(
                                    color: filled
                                        ? context.colors.primary
                                        : context.colors.primary.withValues(alpha: 0.3),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                );
                              }),
                            );
                          }),
                        ),
                        CommonSpaces.w8,
                        Text(
                          _isPlayingPreview
                              ? _formatRecordingDuration(_previewPositionSecs)
                              : _formatRecordingDuration(_recordedDurationSecs),
                          style: context.bodySmall.copyWith(
                            color: context.colors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              CommonSpaces.w12,
              // Send button
              GestureDetector(
                onTap: _sendRecordedVoice,
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: context.colors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(CommonIcons.send,
                      color: context.colors.pureWhite, size: 20),
                ),
              ),
            ],
          ),
          if (!widget.isGroup) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Divider(height: 1),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildPermissionToggle(
                  icon: _attachmentAllowView ? CommonIcons.visibility : CommonIcons.visibilityOff,
                  label: 'View',
                  isActive: _attachmentAllowView,
                  onTap: () => setState(() => _attachmentAllowView = !_attachmentAllowView),
                ),
                _buildPermissionToggle(
                  icon: _attachmentAllowDownload ? CommonIcons.download : CommonIcons.downloadOff,
                  label: 'Download',
                  isActive: _attachmentAllowDownload,
                  onTap: () => setState(() => _attachmentAllowDownload = !_attachmentAllowDownload),
                ),
                _buildPermissionToggle(
                  icon: _attachmentAllowShare ? CommonIcons.share : CommonIcons.shareOff,
                  label: 'Share',
                  isActive: _attachmentAllowShare,
                  onTap: () => setState(() => _attachmentAllowShare = !_attachmentAllowShare),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildReplyPreview() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: context.colors.lightBackground,
        border: Border(
          top: BorderSide(color: context.colors.border, width: 1),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 36,
            color: context.colors.primary,
          ),
          CommonSpaces.w12,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Replying to ${_resolveSenderName(_replyingToMessage?.senderId ?? '', _replyingToMessage?.senderName)}',
                  style: context.bodySmall.copyWith(
                    fontWeight: FontWeight.bold,
                    color: context.colors.primary,
                  ),
                ),
                Text(
                  _getReplyMessageBody(_replyingToMessage) ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.bodyMedium.copyWith(
                    color: context.colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(CommonIcons.close, color: context.colors.textSecondary, size: 20),
            onPressed: () {
              setState(() {
                _replyingToMessage = null;
              });
            },
          ),
        ],
      ),
    );
  }

  String? _getReplyMessageBody(MessageModel? msg) {
    if (msg == null) return null;
    final isMedia = msg.mediaType != null && msg.mediaType != 'text';
    if (isMedia) {
      final name = msg.attachmentName ?? '';
      if (name.isNotEmpty) return name;
      final content = msg.content;
      if (content.isNotEmpty) return content;
      if (msg.mediaType == 'image') return 'Photo';
      if (msg.mediaType == 'video') return 'Video';
      if (msg.mediaType == 'audio' || msg.mediaType == 'voice_note') return 'Voice note';
      return 'File';
    }
    return msg.content;
  }

  Widget _buildEditPreview() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: context.colors.lightBackground,
        border: Border(
          top: BorderSide(color: context.colors.border, width: 1),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 36,
            color: context.colors.warning,
          ),
          CommonSpaces.w12,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Editing Message',
                  style: context.bodySmall.copyWith(
                    fontWeight: FontWeight.bold,
                    color: context.colors.warning,
                  ),
                ),
                Text(
                  _editingMessage!.content,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.bodyMedium.copyWith(
                    color: context.colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(CommonIcons.close, color: context.colors.textSecondary, size: 20),
            onPressed: () {
              setState(() {
                _editingMessage = null;
                _messageController.clear();
                _isTyping = false;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBottomSection(BuildContext context) {
    // Voice preview state takes priority
    if (_recordedBytes != null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildVoicePreviewBar(),
          _buildInputBar(context),
        ],
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!_isRecording && _showUnknownContactBanner) _buildUnknownContactBanner(context),
        if (_isRecording) _buildRecordingBanner(),
        if (!_isRecording && _replyingToMessage != null) _buildReplyPreview(),
        if (!_isRecording && _editingMessage != null) _buildEditPreview(),
        if (!_isRecording && _selectedAttachmentType != null) _buildAttachmentPreview(),
        _buildInputBar(context),
        if (!_isRecording && _showAttachmentGrid) _buildAttachmentGrid(context),
      ],
    );
  }

  void _showMessageMenu(BuildContext context, MessageModel msg, bool isMe, Offset? tapPosition, bool isRecipientOnline) async {
    final RenderBox overlay = Navigator.of(context).overlay!.context.findRenderObject() as RenderBox;
    final position = RelativeRect.fromRect(
      Rect.fromLTWH(
        tapPosition?.dx ?? overlay.size.width / 2,
        tapPosition?.dy ?? overlay.size.height / 2,
        0,
        0,
      ),
      Offset.zero & overlay.size,
    );

    final isText = msg.mediaType == null || msg.mediaType == 'text';

    final result = await showMenu<String>(
      context: context,
      position: position,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      color: context.colors.cardBackground,
      elevation: 6,
      items: [
        _HorizontalActionMenuEntry(
          msg: msg,
          isMe: isMe,
          isText: isText,
        ),
      ],
    );

    if (result == null || !context.mounted) return;

    if (result == 'Reply') {
      setState(() {
        _replyingToMessage = msg;
        _editingMessage = null;
      });
    } else if (result == 'Copy') {
      Clipboard.setData(ClipboardData(text: msg.content));
      context.showSuccessNotification('Message copied to clipboard');
    } else if (result == 'Edit') {
      setState(() {
        _editingMessage = msg;
        _replyingToMessage = null;
        _messageController.text = msg.content;
        _isTyping = true;
      });
    } else if (result == 'Pin' || result == 'Unpin') {
      final shouldPin = !msg.isPinned;
      _chatBloc.add(PinMessageEvent(
        messageId: msg.id,
        conversationId: widget.conversationId,
        isPinned: shouldPin,
      ));
    } else if (result == 'Forward') {
      _showForwardBottomSheet(context, msg);
    } else if (result == 'Info') {
      _showMessageInfo(context, msg, isRecipientOnline);
    } else if (result == 'Select') {
      setState(() {
        _selectedMessageIds.add(msg.id);
      });
    } else if (result == 'Delete') {
      _showDeleteDialog(context, [msg]);
    }
  }

  Widget _buildMemberStatusTile(BuildContext context, UserModel user, String timeStr, Color checkmarkColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: context.colors.primary.withValues(alpha: 0.15),
            backgroundImage: (user.profilePictureUrl != null && user.profilePictureUrl!.isNotEmpty)
                ? CachedNetworkImageProvider(user.profilePictureUrl!)
                : null,
            child: (user.profilePictureUrl == null || user.profilePictureUrl!.isEmpty)
                ? Text(
                    user.displayName.isNotEmpty ? user.displayName[0].toUpperCase() : '?',
                    style: TextStyle(
                      color: context.colors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.displayName,
                  style: context.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if ((user.username ?? '').isNotEmpty)
                  Text(
                    '@${user.username}',
                    style: context.bodySmall.copyWith(
                      color: context.colors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
          ),
          Text(
            timeStr,
            style: context.bodySmall.copyWith(
              color: context.colors.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  void _showMessageInfo(BuildContext context, MessageModel msg, bool isRecipientOnline) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final isDelivered = msg.isRead || msg.isDelivered || widget.isGroup || isRecipientOnline;
        final myId = (_chatBloc.state is ChatLoaded) ? (_chatBloc.state as ChatLoaded).myId : '';
        final senderId = msg.senderId.isNotEmpty ? msg.senderId : myId;

        final otherParticipants = widget.isGroup
            ? _groupParticipants.where((u) => u.id != senderId).toList()
            : <UserModel>[];

        final readParticipants = msg.isRead ? otherParticipants : <UserModel>[];
        final deliveredParticipants = isDelivered ? otherParticipants : <UserModel>[];

        const emeraldGreen = Color(0xFF00D084);
        const skyBlue = Color(0xFF34B7F1);
        final cardBg = isDark ? const Color(0xFF1E262C) : const Color(0xFFF4F7F9);
        final bubbleBg = isDark ? const Color(0xFF132B25) : context.colors.sentBubble;
        final borderColor = isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06);

        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          decoration: BoxDecoration(
            color: context.colors.scaffoldBackground,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top Drag Handle
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    decoration: BoxDecoration(
                      color: context.colors.textHint.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                // Header Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: emeraldGreen.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.info_outline_rounded,
                          color: emeraldGreen,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Message Info',
                              style: context.titleMedium.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            Text(
                              widget.isGroup ? 'Group Message Details' : 'Delivery & Read Receipts',
                              style: context.bodySmall.copyWith(
                                color: context.colors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(sheetCtx).pop(),
                        icon: Icon(
                          Icons.close_rounded,
                          color: context.colors.textSecondary,
                          size: 22,
                        ),
                        splashRadius: 20,
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, thickness: 0.8),
                // Scrollable Content
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 1. Message Bubble Card Preview
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: bubbleBg,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: emeraldGreen.withValues(alpha: 0.2),
                              width: 0.8,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: context.colors.textPrimary.withValues(alpha: 0.04),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (msg.mediaUrl != null || msg.attachmentBytes != null || msg.attachmentName != null) ...[
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: emeraldGreen.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(
                                        msg.mediaType == 'image'
                                            ? Icons.image_rounded
                                            : msg.mediaType == 'video'
                                                ? Icons.videocam_rounded
                                                : (msg.mediaType == 'audio' || msg.mediaType == 'voice_note')
                                                    ? Icons.audiotrack_rounded
                                                    : Icons.insert_drive_file_rounded,
                                        color: emeraldGreen,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        msg.attachmentName ?? (msg.mediaType != null ? msg.mediaType!.toUpperCase() : 'Attachment'),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: context.bodyMedium.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                if (msg.content.isNotEmpty && msg.content != msg.attachmentName)
                                  const SizedBox(height: 8),
                              ],
                              if (msg.content.isNotEmpty && (msg.attachmentName == null || msg.content != msg.attachmentName))
                                Text(
                                  msg.content,
                                  style: context.bodyLarge.copyWith(
                                    fontSize: 15,
                                    color: context.colors.textPrimary,
                                    height: 1.35,
                                  ),
                                ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  if (msg.isEdited) ...[
                                    Icon(Icons.edit_outlined, size: 12, color: context.colors.textSecondary),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Edited  •  ',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: context.colors.textSecondary,
                                      ),
                                    ),
                                  ],
                                  Text(
                                    _formatTime(msg.isEdited && msg.updatedAt.isNotEmpty ? msg.updatedAt : msg.createdAt),
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      color: context.colors.textSecondary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(
                                    msg.isRead ? Icons.done_all_rounded : (isDelivered ? Icons.done_all_rounded : Icons.done_rounded),
                                    size: 14,
                                    color: msg.isRead ? skyBlue : (isDelivered ? emeraldGreen : context.colors.textSecondary),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Section Label
                        Padding(
                          padding: const EdgeInsets.only(left: 4, bottom: 8),
                          child: Text(
                            'MESSAGE STATUS',
                            style: context.bodySmall.copyWith(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                              color: context.colors.textSecondary,
                            ),
                          ),
                        ),

                        // 2. Status Timeline Card
                        Container(
                          decoration: BoxDecoration(
                            color: cardBg,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: borderColor, width: 0.8),
                          ),
                          child: Column(
                            children: [
                              // 1. Read Tile
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: msg.isRead
                                            ? skyBlue.withValues(alpha: 0.15)
                                            : context.colors.textHint.withValues(alpha: 0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.done_all_rounded,
                                        color: msg.isRead ? skyBlue : context.colors.textHint,
                                        size: 18,
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                widget.isGroup
                                                    ? 'Read by (${readParticipants.length} of ${otherParticipants.length})'
                                                    : 'Read',
                                                style: context.titleSmall.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                  color: msg.isRead ? skyBlue : context.colors.textPrimary,
                                                ),
                                              ),
                                              if (!widget.isGroup && msg.isRead)
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: skyBlue.withValues(alpha: 0.15),
                                                    borderRadius: BorderRadius.circular(6),
                                                  ),
                                                  child: const Text(
                                                    'Seen',
                                                    style: TextStyle(
                                                      fontSize: 10.5,
                                                      fontWeight: FontWeight.bold,
                                                      color: skyBlue,
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                          const SizedBox(height: 3),
                                          if (!widget.isGroup)
                                            Text(
                                              msg.isRead
                                                  ? _formatFullDateTime(msg.updatedAt.isNotEmpty ? msg.updatedAt : msg.createdAt)
                                                  : 'Not read yet',
                                              style: context.bodyMedium.copyWith(
                                                color: msg.isRead ? context.colors.textSecondary : context.colors.textHint,
                                                fontSize: 13,
                                                fontStyle: msg.isRead ? FontStyle.normal : FontStyle.italic,
                                              ),
                                            )
                                          else if (readParticipants.isEmpty)
                                            Text(
                                              'Not read yet',
                                              style: context.bodyMedium.copyWith(
                                                color: context.colors.textHint,
                                                fontSize: 13,
                                                fontStyle: FontStyle.italic,
                                              ),
                                            )
                                          else ...[
                                            const SizedBox(height: 8),
                                            ...readParticipants.map((u) => _buildMemberStatusTile(
                                                  context,
                                                  u,
                                                  _formatFullDateTime(msg.updatedAt.isNotEmpty ? msg.updatedAt : msg.createdAt),
                                                  skyBlue,
                                                )),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Divider(height: 1, thickness: 0.8, color: borderColor, indent: 56),

                              // 2. Delivered Tile
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: isDelivered
                                            ? emeraldGreen.withValues(alpha: 0.15)
                                            : context.colors.textHint.withValues(alpha: 0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.done_all_rounded,
                                        color: isDelivered ? emeraldGreen : context.colors.textHint,
                                        size: 18,
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                widget.isGroup
                                                    ? 'Delivered to (${deliveredParticipants.length})'
                                                    : 'Delivered',
                                                style: context.titleSmall.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              if (!widget.isGroup && isDelivered)
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: emeraldGreen.withValues(alpha: 0.15),
                                                    borderRadius: BorderRadius.circular(6),
                                                  ),
                                                  child: const Text(
                                                    'Delivered',
                                                    style: TextStyle(
                                                      fontSize: 10.5,
                                                      fontWeight: FontWeight.bold,
                                                      color: emeraldGreen,
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                          const SizedBox(height: 3),
                                          if (!widget.isGroup)
                                            Text(
                                              isDelivered ? _formatFullDateTime(msg.createdAt) : 'Pending delivery',
                                              style: context.bodyMedium.copyWith(
                                                color: isDelivered ? context.colors.textSecondary : context.colors.textHint,
                                                fontSize: 13,
                                                fontStyle: isDelivered ? FontStyle.normal : FontStyle.italic,
                                              ),
                                            )
                                          else if (deliveredParticipants.isEmpty)
                                            Text(
                                              isDelivered ? _formatFullDateTime(msg.createdAt) : 'Pending delivery',
                                              style: context.bodyMedium.copyWith(
                                                color: context.colors.textSecondary,
                                                fontSize: 13,
                                              ),
                                            )
                                          else ...[
                                            const SizedBox(height: 8),
                                            ...deliveredParticipants.map((u) => _buildMemberStatusTile(
                                                  context,
                                                  u,
                                                  _formatFullDateTime(msg.createdAt),
                                                  emeraldGreen,
                                                )),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Divider(height: 1, thickness: 0.8, color: borderColor, indent: 56),

                              // 3. Sent Tile
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: emeraldGreen.withValues(alpha: 0.15),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.check_rounded,
                                        color: emeraldGreen,
                                        size: 18,
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Sent',
                                            style: context.titleSmall.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            _formatFullDateTime(msg.createdAt),
                                            style: context.bodyMedium.copyWith(
                                              color: context.colors.textSecondary,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Extra Badges / Security details
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.lock_outline_rounded, size: 13, color: context.colors.textHint),
                            const SizedBox(width: 5),
                            Text(
                              'End-to-end encrypted',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: context.colors.textHint,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatFullDateTime(String timestamp) {
    try {
      DateTime date;
      final parsedInt = int.tryParse(timestamp);
      if (parsedInt != null) {
        if (timestamp.length <= 10) {
          date = DateTime.fromMillisecondsSinceEpoch(parsedInt * 1000).toLocal();
        } else {
          date = DateTime.fromMillisecondsSinceEpoch(parsedInt).toLocal();
        }
      } else {
        date = DateTime.parse(timestamp).toLocal();
      }
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      final monthName = months[date.month - 1];
      final hour = date.hour > 12 ? date.hour - 12 : (date.hour == 0 ? 12 : date.hour);
      final minute = date.minute.toString().padLeft(2, '0');
      final period = date.hour >= 12 ? 'PM' : 'AM';
      return '$monthName ${date.day}, ${date.year} at $hour:$minute $period';
    } catch (e) {
      return timestamp;
    }
  }

  void _sendForwardSocketMessage(ChatSocketRepository repo, String conversationId, MessageModel msg) {
    repo.sendMessage(
      conversationId: conversationId,
      type: msg.mediaType ?? 'text',
      text: msg.content,
      fileKey: msg.mediaUrl,
      fileName: msg.attachmentName,
      fileSize: msg.fileSize,
      mimeType: msg.attachmentName != null ? _getMimeType(msg.attachmentName!, msg.mediaType ?? 'file') : null,
      security: {
        'allowShare': msg.allowShare,
        'allowDownload': msg.allowDownload,
        'allowView': msg.allowView,
      },
      viewControl: {
        'allowShare': msg.allowShare,
        'allowDownload': msg.allowDownload,
        'allowView': msg.allowView,
      },
    );
  }

  void _showForwardBottomSheet(BuildContext context, MessageModel msg) async {
    final messageId = msg.id;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    final contacts = await _getForwardContacts();
    
    if (context.mounted) {
      Navigator.pop(context);
    }

    if (contacts.isEmpty) {
      if (context.mounted) {
        context.showInfoNotification('No contacts available for forwarding');
      }
      return;
    }

    if (context.mounted) {
      final Set<UserModel> selectedUsers = {};

      StreamSubscription? contactsSub;
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (bottomSheetCtx) {
          List<UserModel> localContacts = List.from(contacts);
          bool isSyncing = false;
          String forwardSearchQuery = '';

          return StatefulBuilder(
            builder: (context, setModalState) {
              return Material(
                color: context.colors.scaffoldBackground,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                child: Container(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                    CommonSpaces.h16,
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: context.colors.textSecondary.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    CommonSpaces.h16,
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Forward Message',
                                style: context.titleLarge.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: context.colors.textPrimary,
                                ),
                              ),
                              if (selectedUsers.isNotEmpty)
                                Text(
                                  '${selectedUsers.length}/5 selected',
                                  style: context.bodySmall.copyWith(
                                    color: selectedUsers.length >= 5 
                                        ? context.colors.error 
                                        : context.colors.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                            ],
                          ),
                          const Spacer(),
                          IconButton(
                            onPressed: isSyncing 
                                ? null 
                                : () {
                                    setModalState(() {
                                      isSyncing = true;
                                    });
                                    final bloc = getIt<ContactsBloc>();
                                    bloc.add(const SyncContactsEvent());
                                    contactsSub?.cancel();
                                    contactsSub = bloc.stream.listen((contactsState) async {
                                      if (contactsState is ContactsLoaded) {
                                        contactsSub?.cancel();
                                        final updated = await _getForwardContacts();
                                        setModalState(() {
                                          localContacts = updated;
                                          isSyncing = false;
                                        });
                                      } else if (contactsState is ContactsFailure) {
                                        contactsSub?.cancel();
                                        setModalState(() {
                                          isSyncing = false;
                                        });
                                        if (context.mounted) {
                                          context.showErrorNotification('Sync failed: ${contactsState.errorMessage}');
                                        }
                                      }
                                    });
                                  },
                            icon: isSyncing 
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : Icon(Icons.refresh, color: context.colors.primary),
                            tooltip: 'Sync Contacts',
                          ),
                          IconButton(
                            onPressed: () {
                              contactsSub?.cancel();
                              Navigator.pop(bottomSheetCtx);
                            },
                            icon: Icon(Icons.close, color: context.colors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    Divider(color: context.colors.textSecondary.withValues(alpha: 0.1)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                      child: Container(
                        decoration: BoxDecoration(
                          color: context.colors.border.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: 'Search contacts...',
                            hintStyle: context.bodySmall.copyWith(color: context.colors.textSecondary),
                            prefixIcon: Icon(Icons.search_rounded, size: 20, color: context.colors.textSecondary),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          ),
                          onChanged: (val) {
                            setModalState(() {
                              forwardSearchQuery = val.trim();
                            });
                          },
                        ),
                      ),
                    ),
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.45,
                      ),
                      child: Builder(
                        builder: (context) {
                          final filtered = localContacts.where((u) {
                            return u.displayName.toLowerCase().contains(forwardSearchQuery.toLowerCase()) ||
                                (u.phoneNumber.isNotEmpty && u.phoneNumber.contains(forwardSearchQuery)) ||
                                (u.about != null && u.about!.toLowerCase().contains(forwardSearchQuery.toLowerCase()));
                          }).toList();

                          if (filtered.isEmpty) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 24),
                              child: Center(
                                child: Text(
                                  forwardSearchQuery.isNotEmpty ? 'No contacts found' : 'No contacts available',
                                  style: context.bodySmall.copyWith(color: context.colors.textSecondary),
                                ),
                              ),
                            );
                          }

                          return ListView.builder(
                            shrinkWrap: true,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            itemCount: filtered.length,
                            itemBuilder: (context, index) {
                              final user = filtered[index];
                              final name = user.displayName;
                              final isSelected = selectedUsers.any((u) => u.id == user.id);
                              final hasAvatar = user.profilePictureUrl != null && user.profilePictureUrl!.trim().isNotEmpty;

                              return ListTile(
                                onTap: () {
                                  setModalState(() {
                                    if (isSelected) {
                                      selectedUsers.removeWhere((u) => u.id == user.id);
                                    } else {
                                      if (selectedUsers.length < 5) {
                                        selectedUsers.add(user);
                                      } else {
                                        context.showInfoNotification('Maximum 5 members allowed');
                                      }
                                    }
                                  });
                                },
                                leading: Stack(
                                  children: [
                                    CircleAvatar(
                                      radius: 22,
                                      backgroundColor: context.colors.primary.withValues(alpha: 0.12),
                                      backgroundImage: hasAvatar
                                          ? CachedNetworkImageProvider(user.profilePictureUrl!.trim())
                                          : null,
                                      onBackgroundImageError: hasAvatar
                                          ? (e, s) {}
                                          : null,
                                      child: !hasAvatar
                                          ? Text(
                                              name.isNotEmpty ? name[0].toUpperCase() : '?',
                                              style: TextStyle(
                                                color: context.colors.primary,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            )
                                          : null,
                                    ),
                                    if (isSelected)
                                      Positioned(
                                        right: 0,
                                        bottom: 0,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: context.colors.primary,
                                            shape: BoxShape.circle,
                                            border: Border.all(color: context.colors.scaffoldBackground, width: 2),
                                          ),
                                          child: const Icon(Icons.check, size: 12, color: Colors.white),
                                        ),
                                      ),
                                  ],
                                ),
                                title: Text(
                                  name,
                                  style: context.bodyLarge.copyWith(
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                    color: isSelected ? context.colors.primary : context.colors.textPrimary,
                                  ),
                                ),
                                subtitle: Text(
                                  user.about ?? 'Hey there! I am using Schat.',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: context.bodySmall.copyWith(color: context.colors.textSecondary),
                                ),
                                trailing: AnimatedContainer(
                                  duration: const Duration(milliseconds: 180),
                                  width: 22,
                                  height: 22,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isSelected ? context.colors.primary : Colors.transparent,
                                    border: Border.all(
                                      color: isSelected ? context.colors.primary : context.colors.textSecondary.withValues(alpha: 0.4),
                                      width: 2,
                                    ),
                                  ),
                                  child: isSelected
                                      ? const Center(child: Icon(Icons.check_rounded, color: Colors.white, size: 14))
                                      : null,
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: selectedUsers.isEmpty
                              ? null
                              : () async {
                                  Navigator.pop(bottomSheetCtx);
                                  
                                  context.showInfoNotification('Forwarding to ${selectedUsers.length} contacts...');

                                  for (final user in selectedUsers) {
                                    try {
                                      final dashboardRepo = getIt<DashboardRepository>();
                                      final chatRepo = getIt<ChatRepository>();
                                      final socketRepo = getIt<ChatSocketRepository>();
                                      final result = await dashboardRepo.startDirectChat(user.id);
                                      
                                      result.when(
                                        success: (chat) async {
                                          if (messageId.isNotEmpty && !messageId.startsWith('temp_')) {
                                            try {
                                              await chatRepo.forwardMessage(
                                                messageId: messageId,
                                                targetConversationId: chat.id,
                                              );
                                              // If API succeeds, we assume server broadcasts it to all participants.
                                              // We do NOT need to send via socket manually in this case.
                                              return;
                                            } catch (e) {
                                              debugPrint('Forward API failed fallback to socket: $e');
                                              final errStr = e.toString().toLowerCase();
                                              if (errStr.contains('sharing') || errStr.contains('disabled') || errStr.contains('turned off') || errStr.contains('403') || errStr.contains('forbidden')) {
                                                if (context.mounted) {
                                                  context.showErrorNotification('Sharing has been turned off for this file by the owner.');
                                                }
                                                return; // Do NOT fall back to socket, abort forwarding
                                              }
                                            }
                                          }
                                          // Send socket message only if API is skipped (temp message) or fails
                                          _sendForwardSocketMessage(socketRepo, chat.id, msg);
                                        },
                                        failure: (_, _) {},
                                      );
                                    } catch (e) {
                                      debugPrint('Error forwarding to ${user.username}: $e');
                                    }
                                  }
                                  context.showSuccessNotification('Message forwarded successfully');
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: context.colors.primary,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: context.colors.textHint.withValues(alpha: 0.3),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 0,
                          ),
                          child: Text(
                            selectedUsers.isEmpty 
                                ? 'Select Contacts' 
                                : 'Send to ${selectedUsers.length} Contact${selectedUsers.length > 1 ? 's' : ''}',
                            style: context.bodyLarge.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    ).then((_) {
      contactsSub?.cancel();
    });
  }
}

  void _showDeleteDialog(BuildContext context, List<MessageModel> messages) {
    final myId = (_chatBloc.state as ChatLoaded).myId;
    final allFromMe = messages.every((msg) => msg.senderId == myId);

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          backgroundColor: context.colors.scaffoldBackground,
          title: Text(
            'Delete Message${messages.length > 1 ? "s" : ""}',
            style: context.titleLarge.copyWith(fontWeight: FontWeight.bold),
          ),
          content: Text(
            'Are you sure you want to delete ${messages.length > 1 ? "these messages" : "this message"}?',
            style: context.bodyMedium,
          ),
          actions: [
            TextButton(
              child: Text('Cancel', style: TextStyle(color: context.colors.textSecondary)),
              onPressed: () => Navigator.pop(dialogCtx),
            ),
            TextButton(
              child: Text('Delete for me', style: TextStyle(color: context.colors.error)),
              onPressed: () {
                Navigator.pop(dialogCtx);
                final ids = messages.map((m) => m.id).toList();
                _chatBloc.add(DeleteMessagesEvent(
                  messageIds: ids,
                  conversationId: widget.conversationId,
                  deleteType: 'me',
                ));
                setState(() {
                  _selectedMessageIds.clear();
                });
              },
            ),
            if (allFromMe)
              TextButton(
                child: Text('Delete for everyone', style: TextStyle(color: context.colors.error, fontWeight: FontWeight.bold)),
                onPressed: () {
                  Navigator.pop(dialogCtx);
                  final ids = messages.map((m) => m.id).toList();
                  _chatBloc.add(DeleteMessagesEvent(
                    messageIds: ids,
                    conversationId: widget.conversationId,
                    deleteType: 'everyone',
                  ));
                  setState(() {
                    _selectedMessageIds.clear();
                  });
                },
              ),
          ],
        );
      },
    );
  }


  Future<void> _checkIfAdmin() async {
    if (!widget.isGroup) return;
    try {
      final repo = getIt<ChatRepository>();
      final data = await repo.getGroupDetails(widget.conversationId);
      final myId = getIt<StorageService>().getUserId() ?? '';
      final participantsData = data['participants'];
      bool isAdmin = false;
      final Map<String, String> namesMap = {};
      final Map<String, String?> picsMap = {};
      final List<UserModel> participantsList = [];
      if (participantsData is List) {
        for (var p in participantsData) {
          if (p is Map) {
            final userJson = p['user'] ?? p;
            if (userJson is Map) {
              final user = UserModel.fromJson(Map<String, dynamic>.from(userJson));
              if (user.id.isNotEmpty) {
                namesMap[user.id] = user.displayName;
                if (user.profilePictureUrl != null && user.profilePictureUrl!.isNotEmpty) {
                  picsMap[user.id] = user.profilePictureUrl;
                }
                if (user.id != myId) {
                  participantsList.add(user);
                }
              }
              if (user.id == myId && p['is_admin'] == true) {
                isAdmin = true;
              }
            }
          }
        }
      }
      final bool onlyAdmins = data['only_admins_send_messages'] == true || data['onlyAdminsSendMessages'] == true;
      if (mounted) {
        setState(() {
          _isAdmin = isAdmin;
          _onlyAdminsSendMessages = onlyAdmins;
          _groupParticipantNames = namesMap;
          _groupParticipantProfilePics = picsMap;
          _groupParticipants = participantsList;
        });
      }
    } catch (e) {
      debugPrint('Error loading group details: $e');
    }
  }

  String _resolveSenderName(String senderId, [String? fallbackSenderName]) {
    final myId = getIt<StorageService>().getUserId() ?? '';
    if (senderId.isNotEmpty && senderId == myId) {
      return 'You';
    }
    if (fallbackSenderName != null && fallbackSenderName.trim().isNotEmpty) {
      return fallbackSenderName.trim();
    }
    if (_groupParticipantNames.containsKey(senderId) && _groupParticipantNames[senderId]!.trim().isNotEmpty) {
      return _groupParticipantNames[senderId]!.trim();
    }
    try {
      if (getIt.isRegistered<ContactsBloc>()) {
        final contactsState = getIt<ContactsBloc>().state;
        if (contactsState is ContactsLoaded) {
          final matched = contactsState.syncedContacts.firstWhere(
            (c) => c.id == senderId,
            orElse: () => const UserModel(),
          );
          if (matched.id.isNotEmpty && matched.displayName.isNotEmpty) {
            return matched.displayName;
          }
        }
      }
    } catch (_) {}

    if (!widget.isGroup) {
      return widget.contactName;
    }
    return 'Member';
  }

  String? _resolveSenderProfilePic(String senderId, [String? fallbackUrl]) {
    if (fallbackUrl != null && fallbackUrl.isNotEmpty) {
      return fallbackUrl;
    }
    if (_groupParticipantProfilePics.containsKey(senderId) &&
        _groupParticipantProfilePics[senderId] != null &&
        _groupParticipantProfilePics[senderId]!.isNotEmpty) {
      return _groupParticipantProfilePics[senderId];
    }
    try {
      if (getIt.isRegistered<ContactsBloc>()) {
        final contactsState = getIt<ContactsBloc>().state;
        if (contactsState is ContactsLoaded) {
          final matched = contactsState.syncedContacts.firstWhere(
            (c) => c.id == senderId,
            orElse: () => const UserModel(),
          );
          if (matched.id.isNotEmpty &&
              matched.profilePictureUrl != null &&
              matched.profilePictureUrl!.isNotEmpty) {
            return matched.profilePictureUrl;
          }
        }
      }
    } catch (_) {}
    return null;
  }

  @override
  void dispose() {
    getIt<InAppNotificationService>().clearActiveChat();
    _callSocketSubscription?.cancel();
    _screenshotSubscription?.cancel();
    _screenRecordTimer?.cancel();
    _screenRecordTimer = null;
    _screenshotAutoExpireTimer?.cancel();
    _screenshotAutoExpireTimer = null;
    getIt<ScreenProtectionService>().enableProtection();
    _stopTypingTimer();
    _messageController.dispose();
    _inputFocusNode.dispose();
    _scrollController.dispose();
    _chatBloc.close();
    _recordingTimer?.cancel();
    _audioRecorder.dispose();
    _previewPlayer.dispose();
    _previewPositionTimer?.cancel();
    super.dispose();
  }

  // ── Voice recording helpers ──────────────────────────────────────────────

  Future<void> _startRecording() async {
    // Request permission
    final hasPermission = await _audioRecorder.hasPermission();
    if (!hasPermission) {
      if (mounted) context.showErrorNotification('Microphone permission denied');
      return;
    }

    try {
      final dir = kIsWeb ? null : await getTemporaryDirectory();
      final path = kIsWeb
          ? 'voice_${DateTime.now().millisecondsSinceEpoch}.m4a'
          : '${dir!.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';

      await _audioRecorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        ),
        path: path,
      );

      setState(() {
        _isRecording = true;
        _recordDurationSeconds = 0;
      });

      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) {
          setState(() => _recordDurationSeconds++);
        }
      });
    } catch (e) {
      debugPrint('Recording start error: $e');
      if (mounted) context.showErrorNotification('Failed to start recording: $e');
    }
  }

  Future<void> _stopAndPreviewRecording() async {
    _recordingTimer?.cancel();
    _recordingTimer = null;

    if (!_isRecording) return;

    final durationSecs = _recordDurationSeconds;
    setState(() {
      _isRecording = false;
      _recordDurationSeconds = 0;
    });

    try {
      final path = await _audioRecorder.stop();
      if (path == null) {
        if (mounted) context.showErrorNotification('Recording failed');
        return;
      }

      if (durationSecs < 1) {
        try { File(path).deleteSync(); } catch (_) {}
        if (mounted) context.showInfoNotification('Recording too short, try again');
        return;
      }

      // Read bytes
      Uint8List? bytes;
      int size = 0;

      if (kIsWeb) {
        try {
          final response = await http.get(Uri.parse(path));
          if (response.statusCode == 200) {
            bytes = response.bodyBytes;
            size = bytes.length;
          }
        } catch (e) {
          debugPrint('Web: failed to fetch blob bytes: $e');
        }
      } else {
        final file = File(path);
        if (await file.exists()) {
          bytes = await file.readAsBytes();
          size = bytes.length;
        }
      }

      if (bytes == null || size == 0) {
        if (mounted) context.showErrorNotification('Recording is empty, please try again');
        return;
      }

      final name = 'voice_${DateTime.now().millisecondsSinceEpoch}.m4a';

      // Show preview — don't send yet
      setState(() {
        _recordedBytes = bytes;
        _recordedPath = path;
        _recordedName = name;
        _recordedDurationSecs = durationSecs;
      });
    } catch (e) {
      debugPrint('Stop recording error: $e');
      if (mounted) context.showErrorNotification('Failed to process recording: $e');
    }
  }

  Future<void> _sendRecordedVoice() async {
    final bytes = _recordedBytes;
    final path = _recordedPath;
    final name = _recordedName ?? 'voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
    final durationSecs = _recordedDurationSecs;
    final size = bytes?.length ?? 0;
    final allowShare = _attachmentAllowShare;
    final allowDownload = _attachmentAllowDownload;
    final allowView = _attachmentAllowView;

    if (bytes == null || size == 0) return;

    // Stop playback if any
    await _previewPlayer.stop();

    // Clear preview immediately
    setState(() {
      _isPlayingPreview = false;
      _previewPositionSecs = 0;
      _recordedBytes = null;
      _recordedPath = null;
      _recordedName = null;
      _recordedDurationSecs = 0;
      _attachmentAllowShare = false;
      _attachmentAllowDownload = false;
      _attachmentAllowView = true;
    });

    final String tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';

    _chatBloc.add(SendMessageEvent(
      conversationId: widget.conversationId,
      text: '',
      type: 'audio',
      attachmentPath: path,
      attachmentName: name,
      attachmentBytes: bytes,
      allowShare: allowShare,
      allowDownload: allowDownload,
      allowView: allowView,
      fileSize: size,
      messageId: tempId,
    ));

    _performVoiceUploadAndSend(
      path: path ?? '',
      name: name,
      bytes: bytes,
      size: size,
      durationSecs: durationSecs,
      tempId: tempId,
      allowShare: allowShare,
      allowDownload: allowDownload,
      allowView: allowView,
    );
  }

  Future<void> _performVoiceUploadAndSend({
    required String path,
    required String name,
    required Uint8List bytes,
    required int size,
    required int durationSecs,
    required String tempId,
    bool allowShare = true,
    bool allowDownload = true,
    bool allowView = true,
  }) async {
    String? fileKey;
    try {
      final repo = getIt<ChatRepository>();
      fileKey = await repo.uploadMedia(
        conversationId: widget.conversationId,
        filePath: path,
        fileName: name,
        mediaType: 'VOICE_NOTE',
        mimeType: 'audio/mpeg',
        fileSizeBytes: size,
        fileBytes: bytes,
      );
    } catch (e) {
      debugPrint('Voice upload error: $e');
      if (mounted) {
        _chatBloc.add(MarkMessageFailedEvent(
          messageId: tempId,
          conversationId: widget.conversationId,
        ));
      }
      return;
    }

    if (fileKey != null && mounted) {
      final bool isSocketConnected = getIt<ChatSocketRepository>().isConnected;
      if (!isSocketConnected) {
        _chatBloc.add(MarkMessageFailedEvent(
          messageId: tempId,
          conversationId: widget.conversationId,
        ));
      } else {
        context.read<ChatSocketBloc>().add(SendMessage(
          conversationId: widget.conversationId,
          type: 'voice_note',
          fileKey: fileKey,
          fileName: name,
          fileSize: size,
          mimeType: 'audio/mpeg',
          duration: durationSecs.toDouble(),
          security: {
            'allowShare': allowShare,
            'allowDownload': allowDownload,
            'allowView': allowView,
          },
          viewControl: {
            'allowShare': allowShare,
            'allowDownload': allowDownload,
            'allowView': allowView,
          },
          expiry: _getExpiryData(),
        ));
      }
    } else if (mounted) {
      _chatBloc.add(MarkMessageFailedEvent(
        messageId: tempId,
        conversationId: widget.conversationId,
      ));
    }
  }

  Future<void> _cancelRecording() async {
    _recordingTimer?.cancel();
    _recordingTimer = null;

    // Stop playback if any
    await _previewPlayer.stop();

    // If actively recording, stop the recorder
    if (_isRecording) {
      setState(() {
        _isRecording = false;
        _recordDurationSeconds = 0;
      });
      try {
        final path = await _audioRecorder.stop();
        if (path != null && !kIsWeb) {
          try { File(path).deleteSync(); } catch (_) {}
        }
      } catch (_) {}
    }

    // Also clear any preview
    if (_recordedBytes != null) {
      if (_recordedPath != null && !kIsWeb) {
        try { File(_recordedPath!).deleteSync(); } catch (_) {}
      }
      setState(() {
        _isPlayingPreview = false;
        _previewPositionSecs = 0;
        _recordedBytes = null;
        _recordedPath = null;
        _recordedName = null;
        _recordedDurationSecs = 0;
        _attachmentAllowShare = false;
        _attachmentAllowDownload = false;
        _attachmentAllowView = true;
      });
    }
  }

  String _formatRecordingDuration(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Future<void> _togglePreviewPlayback() async {
    if (_isPlayingPreview) {
      await _previewPlayer.pause();
      if (mounted) setState(() => _isPlayingPreview = false);
    } else {
      if (_recordedPath != null) {
        // If at the end, restart
        if (_previewPositionSecs >= _recordedDurationSecs) {
          await _previewPlayer.seek(Duration.zero);
          _previewPositionSecs = 0;
        }

        await _previewPlayer.play(
          kIsWeb ? UrlSource(_recordedPath!) : DeviceFileSource(_recordedPath!),
        );
        if (mounted) setState(() => _isPlayingPreview = true);
      }
    }
  }

  bool _isTypingIndicatorEnabled() {
    final state = _chatBloc.state;
    final chatOverride = state is ChatLoaded ? state.typingIndicatorsEnabled : null;
    final globalSetting = getIt<StorageService>().getTypingIndicatorsEnabled();
    return chatOverride ?? globalSetting;
  }

  void _sendTypingStatus(bool isTyping) {
    if (isTyping && !_isTypingIndicatorEnabled()) return;
    context.read<ChatSocketBloc>().add(SendTypingIndicator(widget.conversationId, isTyping: isTyping));
  }

  void _onTextChanged(String value) {
    final hasText = value.trim().isNotEmpty;
    final hasAttachment = _selectedAttachmentType != null;
    final shouldShowSend = hasText || hasAttachment;
    if (shouldShowSend != _isTyping) {
      setState(() {
        _isTyping = shouldShowSend;
      });
      // Immediately notify about change if enabled
      _sendTypingStatus(hasText);
    }

    if (widget.isGroup) {
      final text = value;
      final selection = _messageController.selection;
      final cursorIndex = selection.baseOffset;
      if (cursorIndex > 0 && cursorIndex <= text.length) {
        final textBeforeCursor = text.substring(0, cursorIndex);
        final lastAtIndex = textBeforeCursor.lastIndexOf('@');
        if (lastAtIndex != -1) {
          final query = textBeforeCursor.substring(lastAtIndex + 1);
          if (!query.contains(' ') && !query.contains('\n')) {
            setState(() {
              _mentionQuery = query.toLowerCase();
              _showMentionSuggestions = true;
            });
          } else {
            if (_showMentionSuggestions) {
              setState(() => _showMentionSuggestions = false);
            }
          }
        } else {
          if (_showMentionSuggestions) {
            setState(() => _showMentionSuggestions = false);
          }
        }
      } else {
        if (_showMentionSuggestions) {
          setState(() => _showMentionSuggestions = false);
        }
      }
    } else {
      if (_showMentionSuggestions) {
        setState(() => _showMentionSuggestions = false);
      }
    }

    if (hasText) {
      _startTypingTimer();
    } else {
      _stopTypingTimer();
    }
  }

  void _insertMention(UserModel user) {
    final text = _messageController.text;
    final selection = _messageController.selection;
    final cursorIndex = selection.baseOffset;
    if (cursorIndex >= 0 && cursorIndex <= text.length) {
      final textBeforeCursor = text.substring(0, cursorIndex);
      final lastAtIndex = textBeforeCursor.lastIndexOf('@');
      if (lastAtIndex != -1) {
        final textAfterCursor = text.substring(cursorIndex);
        final mentionName = (user.displayName.isNotEmpty ? user.displayName : user.username) ?? 'user';
        final newText = '${textBeforeCursor.substring(0, lastAtIndex)}@$mentionName $textAfterCursor';
        final newCursorPosition = lastAtIndex + mentionName.length + 2;
        _messageController.value = TextEditingValue(
          text: newText,
          selection: TextSelection.collapsed(offset: newCursorPosition),
        );
      }
    }
    setState(() {
      _showMentionSuggestions = false;
    });
  }

  void _insertRawMention(String mentionName) {
    final text = _messageController.text;
    final selection = _messageController.selection;
    final cursorIndex = selection.baseOffset;
    if (cursorIndex >= 0 && cursorIndex <= text.length) {
      final textBeforeCursor = text.substring(0, cursorIndex);
      final lastAtIndex = textBeforeCursor.lastIndexOf('@');
      if (lastAtIndex != -1) {
        final textAfterCursor = text.substring(cursorIndex);
        final newText = '${textBeforeCursor.substring(0, lastAtIndex)}@$mentionName $textAfterCursor';
        final newCursorPosition = lastAtIndex + mentionName.length + 2;
        _messageController.value = TextEditingValue(
          text: newText,
          selection: TextSelection.collapsed(offset: newCursorPosition),
        );
      }
    }
    setState(() {
      _showMentionSuggestions = false;
    });
  }

  void _handleMentionTap(BuildContext context, String rawMention) {
    final cleanName = rawMention.startsWith('@') ? rawMention.substring(1).trim() : rawMention.trim();
    if (cleanName.isEmpty) return;

    // Handle @all or @everyone in group chats
    if (cleanName.toLowerCase() == 'all' || cleanName.toLowerCase() == 'everyone') {
      if (widget.isGroup) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MultiBlocProvider(
              providers: [
                BlocProvider.value(value: _chatBloc),
                BlocProvider.value(value: _callWebRtcBloc),
              ],
              child: GroupInfoPage(
                conversationId: widget.conversationId,
                groupName: widget.contactName,
                groupColor: widget.contactColor,
              ),
            ),
          ),
        );
        return;
      }
    }

    UserModel? targetUser;
    for (final user in _groupParticipants) {
      final dName = user.displayName.toLowerCase();
      final uName = (user.username ?? '').toLowerCase();
      final query = cleanName.toLowerCase();
      if (dName == query || uName == query || dName.contains(query) || (uName.isNotEmpty && uName.contains(query))) {
        targetUser = user;
        break;
      }
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MultiBlocProvider(
          providers: [
            BlocProvider.value(value: _chatBloc),
            BlocProvider.value(value: _callWebRtcBloc),
          ],
          child: ContactProfilePage(
            conversationId: widget.conversationId,
            contactName: targetUser?.displayName ?? cleanName,
            contactColor: Colors.blueAccent,
            isOnline: false,
            recipientId: targetUser?.id,
            isFromGroup: true,
            profilePictureUrl: targetUser?.profilePictureUrl,
          ),
        ),
      ),
    );
  }

  void _startTypingTimer() {
    if (_typingIndicatorTimer?.isActive ?? false) return;
    
    _typingIndicatorTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_messageController.text.trim().isNotEmpty) {
        _sendTypingStatus(true);
      } else {
        _stopTypingTimer();
      }
    });
  }

  void _stopTypingTimer() {
    _typingIndicatorTimer?.cancel();
    _typingIndicatorTimer = null;
  }

  Map<String, dynamic>? _getExpiryData() {
    final state = _chatBloc.state;
    if (state is ChatLoaded) {
      final timer = state.disappearingTimer;
      if (timer != null && timer != 0) {
        if (timer > 0) {
          return {
            'timer_seconds': timer,
            'expires_at': (DateTime.now().millisecondsSinceEpoch ~/ 1000) + timer,
          };
        } else if (timer < 0) {
          final secondsFromMidnight = (-timer) - 1;
          final targetHour = secondsFromMidnight ~/ 3600;
          final targetMinute = (secondsFromMidnight % 3600) ~/ 60;
          final now = DateTime.now();
          DateTime nextCutoff = DateTime(now.year, now.month, now.day, targetHour, targetMinute);
          if (!nextCutoff.isAfter(now)) {
            nextCutoff = nextCutoff.add(const Duration(days: 1));
          }
          final expiresAt = nextCutoff.millisecondsSinceEpoch ~/ 1000;
          return {
            'timer_seconds': timer,
            'expires_at': expiresAt,
          };
        }
      }
    }
    return null;
  }

  Future<void> _sendMessage(BuildContext context) async {
    final chatState = _chatBloc.state;
    if (chatState is ChatLoaded && chatState.isBlocked) {
      context.showErrorNotification(chatState.isBlockedByMe
          ? 'You blocked this contact. Unblock to send messages.'
          : 'Cannot send messages to this contact.');
      return;
    }

    final text = _messageController.text.trim();

    if (_selectedAttachmentType != null) {
      await _uploadAndSendAttachment(context);
      return;
    }

    if (text.isEmpty) return;

    if (_editingMessage != null) {
      _chatBloc.add(EditMessageEvent(
        messageId: _editingMessage!.id,
        conversationId: widget.conversationId,
        newContent: text,
      ));
      setState(() {
        _editingMessage = null;
      });
    } else {
      final String tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';

      // Optimistically update UI
      _chatBloc.add(SendMessageEvent(
        conversationId: widget.conversationId,
        text: text,
        replyMessageId: _replyingToMessage?.id,
        replyMessageBody: _getReplyMessageBody(_replyingToMessage),
        messageId: tempId,
      ));

      final bool isSocketConnected = getIt<ChatSocketRepository>().isConnected;
      if (!isSocketConnected) {
        _chatBloc.add(MarkMessageFailedEvent(
          messageId: tempId,
          conversationId: widget.conversationId,
        ));
      } else {
        // Send via socket
        context.read<ChatSocketBloc>().add(SendMessage(
          conversationId: widget.conversationId,
          type: 'text',
          text: text,
          replyMessageId: _replyingToMessage?.id,
          expiry: _getExpiryData(),
        ));
      }

      setState(() {
        _replyingToMessage = null;
      });
    }

    _messageController.clear();
    _stopTypingTimer();
    context.read<ChatSocketBloc>().add(SendTypingIndicator(widget.conversationId, isTyping: false));
    setState(() {
      _isTyping = false;
    });
  }

  Future<void> _uploadAndSendAttachment(BuildContext context) async {
    final String type = _selectedAttachmentType!;
    final String name = _selectedAttachmentName ?? 'File';
    final Uint8List? bytes = _selectedAttachmentBytes;
    final String? path = _selectedAttachmentPath;
    final int size = _selectedAttachmentSize;
    final String caption = _messageController.text.trim();
    final bool allowShare = _attachmentAllowShare;
    final bool allowDownload = _attachmentAllowDownload;
    final bool allowView = _attachmentAllowView;
    final bool isViewOnce = _attachmentIsViewOnce;
    final int viewCount = _attachmentViewCount;

    // Clear preview states immediately so UI is responsive
    setState(() {
      _selectedAttachmentPath = null;
      _selectedAttachmentBytes = null;
      _selectedAttachmentName = null;
      _selectedAttachmentType = null;
      _selectedAttachmentSize = 0;
      _attachmentAllowShare = false;
      _attachmentAllowDownload = false;
      _attachmentAllowView = true;
      _attachmentIsViewOnce = false;
      _attachmentViewCount = 1;
      _messageController.clear();
      _isTyping = false;
    });

    if (type == 'location' || type == 'contact') {
      final String tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
      
      double? lat;
      double? lng;
      if (type == 'location' && path != null && path.contains(',')) {
        final parts = path.split(',');
        lat = double.tryParse(parts[0]);
        lng = double.tryParse(parts[1]);
      }

      _chatBloc.add(SendMessageEvent(
        conversationId: widget.conversationId,
        text: caption.isNotEmpty ? caption : name,
        type: type,
        attachmentPath: type == 'location' ? null : path, // Remove from fileKey
        attachmentName: name,
        latitude: lat,
        longitude: lng,
        title: type == 'location' ? name : null,
        allowShare: allowShare,
        allowDownload: allowDownload,
        allowView: allowView,
        isViewOnce: isViewOnce,
        maxViews: viewCount,
        fileSize: size,
        messageId: tempId,
      ));

      final bool isSocketConnected = getIt<ChatSocketRepository>().isConnected;
      if (!isSocketConnected) {
        _chatBloc.add(MarkMessageFailedEvent(
          messageId: tempId,
          conversationId: widget.conversationId,
        ));
      } else {
        context.read<ChatSocketBloc>().add(SendMessage(
          conversationId: widget.conversationId,
          type: type,
          text: caption.isNotEmpty ? caption : name,
          fileKey: type == 'location' ? null : path, // Remove from fileKey
          latitude: lat,
          longitude: lng,
          title: type == 'location' ? name : null,
          security: {
            'allowShare': isViewOnce ? false : allowShare,
            'allowDownload': isViewOnce ? false : allowDownload,
            'allowView': allowView,
          },
          viewControl: {
            'type': isViewOnce ? 'once' : 'normal',
            'maxViews': viewCount,
            'isViewOnce': isViewOnce,
            'allowShare': isViewOnce ? false : allowShare,
            'allowDownload': isViewOnce ? false : allowDownload,
            'allowView': allowView,
          },
          expiry: _getExpiryData(),
        ));
      }
      return;
    }

    final String tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';

    // 1. Send optimistic message event immediately to ChatBloc (shows loader)
    _chatBloc.add(SendMessageEvent(
      conversationId: widget.conversationId,
      text: caption.isNotEmpty ? caption : (type == 'image' ? '' : name),
      type: type,
      attachmentPath: path,
      attachmentName: name,
      attachmentBytes: bytes,
      allowShare: isViewOnce ? false : allowShare,
      allowDownload: isViewOnce ? false : allowDownload,
      allowView: allowView,
      isViewOnce: isViewOnce,
      maxViews: viewCount,
      fileSize: size,
      messageId: tempId,
    ));

    // 2. Perform the upload and socket broadcast in the background
    _performBackgroundUploadAndSend(
      context: context,
      type: type,
      name: name,
      bytes: bytes,
      path: path,
      size: size,
      caption: caption,
      allowShare: isViewOnce ? false : allowShare,
      allowDownload: isViewOnce ? false : allowDownload,
      allowView: allowView,
      isViewOnce: isViewOnce,
      viewCount: viewCount,
      tempId: tempId,
    );
  }

  Future<void> _performBackgroundUploadAndSend({
    required BuildContext context,
    required String type,
    required String name,
    required Uint8List? bytes,
    required String? path,
    required int size,
    required String caption,
    required bool allowShare,
    required bool allowDownload,
    required bool allowView,
    bool isViewOnce = false,
    int viewCount = 1,
    required String tempId,
  }) async {
    String? fileKey;
    try {
      final repo = getIt<ChatRepository>();
      fileKey = await repo.uploadMedia(
        conversationId: widget.conversationId,
        filePath: path ?? '',
        fileName: name,
        mediaType: _getMediaType(type),
        mimeType: _getMimeType(name, type),
        fileSizeBytes: size,
        fileBytes: bytes,
      );
    } catch (e) {
      debugPrint('Background upload error: $e');
      if (context.mounted) {
        _chatBloc.add(MarkMessageFailedEvent(
          messageId: tempId,
          conversationId: widget.conversationId,
        ));
      }
      return;
    }

    if (fileKey != null && context.mounted) {
      final bool isSocketConnected = getIt<ChatSocketRepository>().isConnected;
      if (!isSocketConnected) {
        _chatBloc.add(MarkMessageFailedEvent(
          messageId: tempId,
          conversationId: widget.conversationId,
        ));
      } else {
        context.read<ChatSocketBloc>().add(SendMessage(
          conversationId: widget.conversationId,
          type: type,
          text: caption.isNotEmpty ? caption : (type == 'image' ? '' : name),
          fileKey: fileKey,
          fileName: name,
          fileSize: size,
          mimeType: _getMimeType(name, type),
          security: {
            'allowShare': isViewOnce ? false : allowShare,
            'allowDownload': isViewOnce ? false : allowDownload,
            'allowView': allowView,
          },
          viewControl: {
            'type': isViewOnce ? 'once' : 'normal',
            'maxViews': viewCount,
            'isViewOnce': isViewOnce,
            'allowShare': isViewOnce ? false : allowShare,
            'allowDownload': isViewOnce ? false : allowDownload,
            'allowView': allowView,
          },
          expiry: _getExpiryData(),
        ));
      }
    } else if (context.mounted) {
      _chatBloc.add(MarkMessageFailedEvent(
        messageId: tempId,
        conversationId: widget.conversationId,
      ));
    }
  }

  void _resendMessage(MessageModel msg) {
    _chatBloc.add(DeleteMessagesEvent(
      messageIds: [msg.id],
      conversationId: widget.conversationId,
      deleteType: 'me',
    ));

    final String tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';

    if (msg.mediaType == null || msg.mediaType == 'text') {
      _chatBloc.add(SendMessageEvent(
        conversationId: widget.conversationId,
        text: msg.content,
        replyMessageId: msg.replyMessageId,
        replyMessageBody: msg.replyMessageBody,
        messageId: tempId,
      ));

      final bool isSocketConnected = getIt<ChatSocketRepository>().isConnected;
      if (!isSocketConnected) {
        _chatBloc.add(MarkMessageFailedEvent(
          messageId: tempId,
          conversationId: widget.conversationId,
        ));
      } else {
        context.read<ChatSocketBloc>().add(SendMessage(
          conversationId: widget.conversationId,
          type: 'text',
          text: msg.content,
          replyMessageId: msg.replyMessageId,
          expiry: _getExpiryData(),
        ));
      }
    } else {
      _chatBloc.add(SendMessageEvent(
        conversationId: widget.conversationId,
        text: msg.content,
        type: msg.mediaType!,
        attachmentPath: msg.mediaUrl,
        attachmentName: msg.attachmentName,
        attachmentBytes: msg.attachmentBytes,
        allowShare: msg.allowShare,
        allowDownload: msg.allowDownload,
        allowView: msg.allowView,
        isViewOnce: msg.isViewOnce,
        maxViews: msg.maxViews,
        fileSize: msg.fileSize,
        messageId: tempId,
      ));

      if (msg.mediaType == 'location' || msg.mediaType == 'contact') {
        final bool isSocketConnected = getIt<ChatSocketRepository>().isConnected;
        if (!isSocketConnected) {
          _chatBloc.add(MarkMessageFailedEvent(
            messageId: tempId,
            conversationId: widget.conversationId,
          ));
        } else {
          context.read<ChatSocketBloc>().add(SendMessage(
            conversationId: widget.conversationId,
            type: msg.mediaType!,
            text: msg.content,
            fileKey: msg.mediaUrl,
            security: {
              'allowShare': msg.allowShare,
              'allowDownload': msg.allowDownload,
              'allowView': msg.allowView,
            },
            viewControl: {
              'allowShare': msg.allowShare,
              'allowDownload': msg.allowDownload,
              'allowView': msg.allowView,
            },
            expiry: _getExpiryData(),
          ));
        }
      } else {
        _performBackgroundUploadAndSend(
          context: context,
          type: msg.mediaType!,
          name: msg.attachmentName ?? 'File',
          bytes: msg.attachmentBytes,
          path: msg.mediaUrl,
          size: msg.fileSize ?? 0,
          caption: msg.content,
          allowShare: msg.allowShare,
          allowDownload: msg.allowDownload,
          allowView: msg.allowView,
          isViewOnce: msg.isViewOnce,
          viewCount: msg.maxViews,
          tempId: tempId,
        );
      }
    }
  }

  Widget _buildAttachmentPreview() {
    final isImage = _selectedAttachmentType == 'image';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: context.colors.lightBackground,
        border: Border(
          top: BorderSide(color: context.colors.border, width: 1),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              // Preview thumbnail/icon
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 56,
                  height: 56,
                  color: context.colors.border.withValues(alpha: 0.3),
                  child: isImage
                      ? (_selectedAttachmentBytes != null
                          ? Image.memory(
                              _selectedAttachmentBytes!,
                              fit: BoxFit.cover,
                            )
                          : const Icon(CommonIcons.gallery, size: 28))
                      : (_selectedAttachmentType == 'video' && _selectedAttachmentPath != null
                          ? _VideoPreviewThumbnail(path: _selectedAttachmentPath!)
                          : Center(
                              child: Icon(
                                _selectedAttachmentType == 'video'
                                    ? CommonIcons.playCircle
                                    : _selectedAttachmentType == 'audio'
                                        ? CommonIcons.audio
                                        : _selectedAttachmentType == 'location'
                                            ? CommonIcons.location
                                            : _selectedAttachmentType == 'contact'
                                                ? CommonIcons.person
                                                : CommonIcons.document,
                                color: context.colors.primary,
                                size: 28,
                              ),
                            )),
                ),
              ),
              CommonSpaces.w12,
              // Attachment Name / Size details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _selectedAttachmentName ?? 'Attachment',
                      style: context.bodyMedium.copyWith(
                        fontWeight: FontWeight.bold,
                        color: context.colors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    CommonSpaces.h4,
                    Text(
                      _selectedAttachmentType == 'location'
                          ? 'Location share'
                          : _selectedAttachmentType == 'contact'
                              ? 'Contact card'
                              : _formatBytes(_selectedAttachmentSize),
                      style: context.bodySmall.copyWith(
                        color: context.colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              // Clear Button
              IconButton(
                icon: Icon(CommonIcons.close, color: context.colors.textSecondary),
                onPressed: () {
                  setState(() {
                    _selectedAttachmentPath = null;
                    _selectedAttachmentBytes = null;
                    _selectedAttachmentName = null;
                    _selectedAttachmentType = null;
                    _selectedAttachmentSize = 0;
                    _attachmentAllowShare = false;
                    _attachmentAllowDownload = false;
                    _attachmentAllowView = true;
                    _isTyping = _messageController.text.trim().isNotEmpty;
                  });
                },
              ),
            ],
          ),
          if (!widget.isGroup && (_selectedAttachmentType == 'image' || _selectedAttachmentType == 'video' || _selectedAttachmentType == 'audio' || _selectedAttachmentType == 'file')) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Divider(height: 1),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildPermissionToggle(
                  icon: _attachmentAllowView ? CommonIcons.visibility : CommonIcons.visibilityOff,
                  label: 'View',
                  isActive: _attachmentAllowView,
                  onTap: () => setState(() => _attachmentAllowView = !_attachmentAllowView),
                ),
                _buildPermissionToggle(
                  icon: _attachmentAllowDownload ? CommonIcons.download : CommonIcons.downloadOff,
                  label: 'Download',
                  isActive: _attachmentAllowDownload,
                  onTap: () => setState(() => _attachmentAllowDownload = !_attachmentAllowDownload),
                ),
                _buildPermissionToggle(
                  icon: _attachmentAllowShare ? CommonIcons.share : CommonIcons.shareOff,
                  label: 'Share',
                  isActive: _attachmentAllowShare,
                  onTap: () => setState(() => _attachmentAllowShare = !_attachmentAllowShare),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPermissionToggle({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive 
              ? context.colors.primary.withValues(alpha: 0.1) 
              : context.colors.textHint.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive 
                ? context.colors.primary.withValues(alpha: 0.3) 
                : context.colors.textHint.withValues(alpha: 0.1),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isActive ? context.colors.primary : context.colors.textHint,
            ),
            CommonSpaces.w6,
            Text(
              label,
              style: context.bodySmall.copyWith(
                color: isActive ? context.colors.primary : context.colors.textHint,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }


  String _formatBytes(int bytes) {
    if (bytes <= 0) return "0 B";
    const suffixes = ["B", "KB", "MB", "GB"];
    var i = 0;
    double w = bytes.toDouble();
    while (w >= 1024 && i < suffixes.length - 1) {
      w /= 1024;
      i++;
    }
    return "${w.toStringAsFixed(1)} ${suffixes[i]}";
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ChatBloc>.value(
      value: _chatBloc,
      child: BlocConsumer<ChatBloc, ChatState>(
        listener: (context, state) {
          if (state is ChatError) {
            context.showErrorNotification(state.errorMessage);
          } else if (state is ChatDeleted) {
            if (ModalRoute.of(context)?.isCurrent == true) {
              Navigator.of(context).pop();
            }
          } else if (state is ChatLoaded && state.notificationMessage != null) {
            context.showInfoNotification(state.notificationMessage!);
          }

          if (state is ChatLoaded) {
            final activePerm = state.activeScreenPermission;
            final isScreenshotAllowed = activePerm != null &&
                activePerm.isScreenshot &&
                !activePerm.isCompleted &&
                !activePerm.isRejected &&
                (activePerm.remainingCount ?? 1) > 0;
            final isScreenRecordAllowed = activePerm != null &&
                activePerm.isScreenRecord &&
                !activePerm.isCompleted &&
                !activePerm.isRejected &&
                activePerm.durationSeconds != null;

            if (isScreenshotAllowed || isScreenRecordAllowed) {
              getIt<ScreenProtectionService>().disableProtection();

              // Handle screenshot permission safety auto-lock timer (60s)
              if (isScreenshotAllowed) {
                if (_screenshotAutoExpireTimer == null || _activeScreenshotPermissionId != activePerm.id) {
                  _screenshotAutoExpireTimer?.cancel();
                  _activeScreenshotPermissionId = activePerm.id;
                  _screenshotAutoExpireTimer = Timer(const Duration(seconds: 60), () {
                    if (mounted) {
                      getIt<ScreenProtectionService>().enableProtection();
                      context.showInfoNotification('Screenshot permission window expired. Protection re-enabled.');
                      _chatBloc.add(ConsumeScreenPermissionEvent(requestId: activePerm.id));
                    }
                  });
                }
              }

              // Handle screen record timer auto turn off
              if (isScreenRecordAllowed && activePerm.durationSeconds != null) {
                if (_screenRecordTimer == null || _activeScreenRecordPermissionId != activePerm.id) {
                  _screenRecordTimer?.cancel();
                  _activeScreenRecordPermissionId = activePerm.id;
                  final duration = activePerm.durationSeconds!;
                  _screenRecordTimer = Timer(Duration(seconds: duration), () {
                    if (mounted) {
                      getIt<ScreenProtectionService>().enableProtection();
                      context.showInfoNotification('Screen recording permission duration (${duration}s) expired. Protection re-enabled.');
                      _chatBloc.add(ConsumeScreenPermissionEvent(requestId: activePerm.id));
                    }
                  });
                }
              }
            } else {
              _screenRecordTimer?.cancel();
              _screenRecordTimer = null;
              _activeScreenRecordPermissionId = null;
              _screenshotAutoExpireTimer?.cancel();
              _screenshotAutoExpireTimer = null;
              _activeScreenshotPermissionId = null;
              getIt<ScreenProtectionService>().enableProtection();
            }
          }

          if (state is ChatLoaded && state.incomingScreenPermissionRequest != null) {
            final incomingReq = state.incomingScreenPermissionRequest!;
            _chatBloc.add(const DismissIncomingScreenPermissionRequestEvent());
            getIt<InAppNotificationService>().showIncomingScreenPermissionBottomSheet(incomingReq);
          }
        },
        builder: (context, state) {
          final isLoading = state is ChatLoading || state is ChatInitial;
          final messages = state is ChatLoaded ? state.messages : <MessageModel>[];
          final displayedMessages = messages.where((m) {
            if (m.isDeletedForMe) return false;
            if (_isSearching && _searchQuery.isNotEmpty) {
              return m.content.toLowerCase().contains(_searchQuery.toLowerCase());
            }
            return true;
          }).toList();
          final isOtherUserTyping = state is ChatLoaded && state.isRecipientTyping;
          // Custom Wallpaper or Color Theme
          final customWallpaperUrl = state is ChatLoaded ? state.customWallpaperUrl : null;
          final apiThemeColor = state is ChatLoaded ? state.themeColor?.toColor() : null;
          final customBgColor = apiThemeColor ?? (state is ChatLoaded ? state.customBgColor : null);

          DecorationImage? bgDecorationImage;
          if (customWallpaperUrl != null && customWallpaperUrl.isNotEmpty) {
            ImageProvider? imgProvider;
            final cleanUrl = customWallpaperUrl.replaceFirst('file://', '');
            if (customWallpaperUrl.startsWith('http://') || customWallpaperUrl.startsWith('https://')) {
              var networkUrl = customWallpaperUrl;
              if (networkUrl.contains('minio')) {
                try {
                  final serverUri = Uri.parse(CommonEndpoints.baseUrl);
                  if (serverUri.host.isNotEmpty) {
                    networkUrl = networkUrl.replaceAll('minio', serverUri.host);
                  }
                } catch (_) {}
              }
              imgProvider = NetworkImage(networkUrl);
            } else if (customWallpaperUrl.startsWith('assets/')) {
              imgProvider = AssetImage(customWallpaperUrl);
            } else if (!kIsWeb && (customWallpaperUrl.startsWith('/') || customWallpaperUrl.startsWith('file:'))) {
              final file = File(cleanUrl);
              if (file.existsSync()) {
                imgProvider = FileImage(file);
              }
            } else {
              imgProvider = NetworkImage(customWallpaperUrl);
            }
            if (imgProvider != null) {
              bgDecorationImage = DecorationImage(
                image: imgProvider,
                fit: BoxFit.cover,
              );
            }
          }
          if (bgDecorationImage == null && customBgColor == null) {
            bgDecorationImage = DecorationImage(
              image: const AssetImage('assets/images/chat_bg.png'),
              fit: BoxFit.cover,
              opacity: context.colors.isDark ? 0.05 : 0.08,
              colorFilter: context.colors.isDark
                  ? const ColorFilter.matrix(<double>[
                      -1.0, 0.0, 0.0, 0.0, 255.0, // red
                      0.0, -1.0, 0.0, 0.0, 255.0, // green
                      0.0, 0.0, -1.0, 0.0, 255.0, // blue
                      0.0, 0.0, 0.0, 1.0, 0.0,   // alpha
                    ])
                  : null,
            );
          }

          return Scaffold(
            backgroundColor: customBgColor ?? context.colors.scaffoldBackground,
            appBar: _buildAppBar(context, state),
            body: Container(
              decoration: BoxDecoration(
                image: bgDecorationImage,
              ),
              child: Column(
                children: [
                  SafeArea(
                    bottom: false,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildPinnedMessageBanner(state),
                        _buildActiveScreenPermissionBanner(state),
                      ],
                    ),
                  ),
                  Expanded(
                    child: NotificationListener<ScrollNotification>(
                      onNotification: (ScrollNotification notification) {
                        if (notification is ScrollUpdateNotification) {
                          if (_scrollController.hasClients) {
                            final pixels = _scrollController.position.pixels;
                            final maxScroll = _scrollController.position.maxScrollExtent;
                            if (pixels >= maxScroll - 200) {
                              _chatBloc.add(LoadMoreMessagesEvent(conversationId: widget.conversationId));
                            }
                          }
                        }
                        return false;
                      },
                      child: isLoading
                          ? Center(child: CircularProgressIndicator(color: context.colors.primary))
                          : displayedMessages.isEmpty 
                              ? SingleChildScrollView(
                                  physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                                  controller: _scrollController,
                                  child: Container(
                                    height: MediaQuery.of(context).size.height * 0.7,
                                    alignment: Alignment.center,
                                    child: _buildEmptyScreen(context),
                                  ),
                                )
                          : Builder(
                              builder: (context) {
                                final groupedItems = _groupChatMessages(displayedMessages);
                                return ListView.builder(
                                  controller: _scrollController,
                                  reverse: true,
                                  physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  itemCount: groupedItems.length + (isOtherUserTyping ? 1 : 0),
                                  itemBuilder: (context, index) {
                                    if (isOtherUserTyping && index == 0) {
                                      return _buildTypingIndicator();
                                    }

                                    final adjustedIndex = isOtherUserTyping ? index - 1 : index;
                                    final item = groupedItems[groupedItems.length - 1 - adjustedIndex];
                                    final msg = item.primaryMessage;
                                    final isMe = state is ChatLoaded && msg.senderId == state.myId;
                                    final isGrouped = item.groupedImages != null && item.groupedImages!.length > 1;
                                    final groupedList = item.groupedImages;
                                    final allGroupIds = isGrouped ? groupedList!.map((m) => m.id).toSet() : {msg.id};
                                    final isSelected = allGroupIds.any((id) => _selectedMessageIds.contains(id));

                                    String? replySenderName;
                                    String? replyBody;
                                    if (msg.isReply && msg.replyMessageId != null) {
                                      try {
                                        final parent = messages.firstWhere((m) => m.id == msg.replyMessageId);
                                        replySenderName = (state is ChatLoaded && parent.senderId == state.myId)
                                            ? 'You'
                                            : (widget.isGroup
                                                ? _resolveSenderName(parent.senderId, parent.senderName)
                                                : widget.contactName);
                                        replyBody = _getReplyMessageBody(parent);
                                      } catch (_) {
                                        replySenderName = isMe
                                            ? (widget.isGroup ? 'Group' : widget.contactName)
                                            : 'You';
                                        replyBody = msg.replyMessageBody;
                                      }
                                    }

                                    // --- Date separator logic ---
                                    final msgDate = _parseMessageDate(msg.createdAt);
                                    final msgDay = msgDate != null
                                        ? DateTime(msgDate.year, msgDate.month, msgDate.day)
                                        : null;

                                    bool showDateSeparator = false;
                                    if (msgDay != null) {
                                      final olderIndex = adjustedIndex + 1;
                                      if (olderIndex < groupedItems.length) {
                                        final olderItem = groupedItems[groupedItems.length - 1 - olderIndex];
                                        final olderDate = _parseMessageDate(olderItem.primaryMessage.createdAt);
                                        if (olderDate != null) {
                                          final olderDay = DateTime(olderDate.year, olderDate.month, olderDate.day);
                                          showDateSeparator = msgDay != olderDay;
                                        }
                                      } else {
                                        showDateSeparator = true;
                                      }
                                    }

                                    final bubble = Dismissible(
                                      key: ValueKey('dismiss_${msg.id}'),
                                      direction: DismissDirection.horizontal,
                                      confirmDismiss: (direction) async {
                                        if (direction == DismissDirection.startToEnd) {
                                          // Swipe right to delete
                                          _showDeleteDialog(context, isGrouped ? groupedList! : [msg]);
                                          return false;
                                        } else if (direction == DismissDirection.endToStart) {
                                          // Swipe left to reply
                                          setState(() {
                                            _replyingToMessage = msg;
                                            _editingMessage = null;
                                            _messageController.clear();
                                            _inputFocusNode.requestFocus();
                                          });
                                          return false;
                                        }
                                        return false;
                                      },
                                      background: Container(
                                        alignment: Alignment.centerLeft,
                                        padding: const EdgeInsets.only(left: 20.0),
                                        color: Colors.redAccent.withValues(alpha: 0.15),
                                        child: const Icon(CommonIcons.deleteOutline, color: Colors.redAccent),
                                      ),
                                      secondaryBackground: Container(
                                        alignment: Alignment.centerRight,
                                        padding: const EdgeInsets.only(right: 20.0),
                                        color: context.colors.primary.withValues(alpha: 0.15),
                                        child: Icon(CommonIcons.reply, color: context.colors.primary),
                                      ),
                                      child: GestureDetector(
                                        onTapDown: (details) {
                                          _tapPosition = details.globalPosition;
                                        },
                                        onLongPress: () {
                                          if (msg.isDeleted) return;
                                          if (_selectedMessageIds.isEmpty) {
                                            _showMessageMenu(context, msg, isMe, _tapPosition, state is ChatLoaded ? state.isRecipientOnline : false);
                                          }
                                        },
                                        onTap: () {
                                          if (msg.isDeleted) return;
                                          if (_selectedMessageIds.isNotEmpty) {
                                            setState(() {
                                              if (isSelected) {
                                                _selectedMessageIds.removeAll(allGroupIds);
                                              } else {
                                                _selectedMessageIds.addAll(allGroupIds);
                                              }
                                            });
                                          }
                                        },
                                        child: MessageBubble(
                                          messageId: msg.id,
                                          conversationId: widget.conversationId,
                                          message: msg.content,
                                          time: _formatTime(msg.isEdited && msg.updatedAt.isNotEmpty ? msg.updatedAt : msg.createdAt),
                                          isMe: isMe,
                                          isRead: msg.isRead,
                                          isDelivered: msg.isDelivered,
                                          isDeleted: msg.isDeleted,
                                          isGroup: widget.isGroup,
                                          senderName: widget.isGroup && !isMe ? _resolveSenderName(msg.senderId, msg.senderName) : null,
                                          senderProfilePictureUrl: widget.isGroup && !isMe ? _resolveSenderProfilePic(msg.senderId, msg.senderProfilePictureUrl) : null,
                                          type: (msg.messageType == 'system' || msg.messageType == 'group_event' || msg.messageType == 'notification') ? msg.messageType : (msg.mediaType ?? 'text'),
                                          latitude: msg.latitude,
                                          longitude: msg.longitude,
                                          address: msg.address,
                                          locationTitle: msg.locationTitle,
                                          attachmentPath: msg.mediaUrl,
                                          attachmentName: msg.attachmentName ?? (msg.content.isNotEmpty ? msg.content : 'File'),
                                          attachmentBytes: msg.attachmentBytes,
                                          groupedImages: groupedList,
                                          isReply: msg.isReply,
                                          replyMessageBody: replyBody ?? msg.replyMessageBody,
                                          replyMessageSenderName: replySenderName,
                                          isEdited: msg.isEdited,
                                          isPinned: msg.isPinned,
                                          isSelected: isSelected,
                                          isUploading: msg.isUploading,
                                          isFailed: msg.isFailed,
                                          onResendPressed: () => _resendMessage(msg),
                                          allowShare: msg.allowShare,
                                          allowDownload: msg.allowDownload,
                                          allowView: msg.allowView,
                                          isViewOnce: msg.isViewOnce,
                                          maxViews: msg.maxViews,
                                          isViewOnceOpened: msg.isViewOnceOpened,
                                          isFileViewed: msg.isFileViewed,
                                          isFileDownloaded: msg.isFileDownloaded,
                                          isFileShared: msg.isFileShared,
                                          onSharePressed: () => _showForwardBottomSheet(context, msg),
                                          fileSize: msg.fileSize,
                                          callMeta: msg.callMeta,
                                          expiry: msg.expiry,
                                          isRecipientOnline: state is ChatLoaded ? state.isRecipientOnline : false,
                                          onMentionTap: (mention) => _handleMentionTap(context, mention),
                                        ),
                                      ),
                                    );

                                    if (showDateSeparator && msgDay != null) {
                                      return Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          _buildDateSeparator(_getDateLabel(msgDay)),
                                          bubble,
                                        ],
                                      );
                                    }
                                    return bubble;
                                  },
                                );
                              },
                            ),
                    ),
                  ),
                  Container(
                    color: Colors.transparent,
                    child: SafeArea(
                      top: false,
                      child: _buildBottomSection(context),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: context.colors.lightBackground,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (index) {
                return _TypingDot(index: index);
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyScreen(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(CommonIcons.chatBubbleOutline, size: 80, color: context.colors.textHint.withValues(alpha: 0.5)),
          CommonSpaces.h16,
          Text(
            'No messages yet',
            style: context.titleMedium.copyWith(color: context.colors.textSecondary),
          ),
          CommonSpaces.h8,
          Text(
            'Send a message to start the conversation',
            style: context.bodySmall.copyWith(color: context.colors.textHint),
          ),
        ],
      ),
    );
  }

  /// Parses a createdAt string (unix timestamp or ISO 8601) into a local DateTime.
  DateTime? _parseMessageDate(String createdAt) {
    try {
      final parsedInt = int.tryParse(createdAt);
      if (parsedInt != null) {
        if (createdAt.length <= 10) {
          return DateTime.fromMillisecondsSinceEpoch(parsedInt * 1000).toLocal();
        } else {
          return DateTime.fromMillisecondsSinceEpoch(parsedInt).toLocal();
        }
      } else {
        return DateTime.parse(createdAt).toLocal();
      }
    } catch (_) {
      return null;
    }
  }

  /// Returns "Today", "Yesterday", or a formatted date string for a given day.
  String _getDateLabel(DateTime day) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final target = DateTime(day.year, day.month, day.day);

    if (target == today) return 'Today';
    if (target == yesterday) return 'Yesterday';

    // Format: "Mon, 2 Jun 2025"
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final weekday = weekdays[day.weekday - 1];
    final month = months[day.month - 1];
    return '$weekday, ${day.day} $month ${day.year}';
  }

  /// Builds a centered date chip separator, e.g. "Today", "Yesterday", "Mon, 2 Jun 2025".
  Widget _buildDateSeparator(String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          const Expanded(child: Divider(indent: 16, endIndent: 8)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: context.colors.lightBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: context.colors.border,
                width: 0.5,
              ),
            ),
            child: Text(
              label,
              style: context.bodySmall.copyWith(
                color: context.colors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const Expanded(child: Divider(indent: 8, endIndent: 16)),
        ],
      ),
    );
  }

  String _formatTime(String createdAt) {
    try {
      DateTime date;
      final parsedInt = int.tryParse(createdAt);
      if (parsedInt != null) {
        if (createdAt.length <= 10) {
          date = DateTime.fromMillisecondsSinceEpoch(parsedInt * 1000).toLocal();
        } else {
          date = DateTime.fromMillisecondsSinceEpoch(parsedInt).toLocal();
        }
      } else {
        date = DateTime.parse(createdAt).toLocal();
      }
      final hour = date.hour > 12 ? date.hour - 12 : (date.hour == 0 ? 12 : date.hour);
      final minute = date.minute.toString().padLeft(2, '0');
      final period = date.hour >= 12 ? 'PM' : 'AM';
      return '$hour:$minute $period';
    } catch (e) {
      return '';
    }
  }

  String _formatLastSeenStatus(String? lastSeenStr) {
    if (lastSeenStr == null || lastSeenStr.isEmpty) return '';
    try {
      DateTime date;
      final parsedInt = int.tryParse(lastSeenStr);
      if (parsedInt != null) {
        if (lastSeenStr.length <= 10) {
          date = DateTime.fromMillisecondsSinceEpoch(parsedInt * 1000).toLocal();
        } else {
          date = DateTime.fromMillisecondsSinceEpoch(parsedInt).toLocal();
        }
      } else {
        date = DateTime.parse(lastSeenStr).toLocal();
      }
      final now = DateTime.now();
      final diff = now.difference(date);

      if (diff.inSeconds < 60) {
        return 'last seen just now';
      } else if (diff.inMinutes < 60) {
        final m = diff.inMinutes;
        return 'last seen $m ${m == 1 ? 'min' : 'mins'} ago';
      } else if (diff.inHours < 24) {
        final h = diff.inHours;
        return 'last seen $h ${h == 1 ? 'hour' : 'hours'} ago';
      } else if (diff.inDays == 1) {
        return 'last seen 1 day ago';
      } else if (diff.inDays < 365) {
        final d = diff.inDays;
        return 'last seen $d days ago';
      } else {
        final y = (diff.inDays / 365).floor();
        return 'last seen $y ${y == 1 ? 'year' : 'years'} ago';
      }
    } catch (e) {
      return '';
    }
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, ChatState state) {
    if (_isSearching) {
      return AppBar(
        backgroundColor: context.colors.scaffoldBackground,
        elevation: 0,
        leading: IconButton(
          icon: Icon(CommonIcons.arrowBack, color: context.colors.textPrimary),
          onPressed: () {
            setState(() {
              _isSearching = false;
              _searchQuery = '';
              _searchController.clear();
            });
          },
        ),
        title: Container(
          height: 42,
          decoration: BoxDecoration(
            color: context.colors.isDark ? const Color(0xFF1E2822) : const Color(0xFFF0F4F2),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: context.colors.primary.withValues(alpha: 0.6),
              width: 1.2,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              Icon(Icons.search, size: 20, color: context.colors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _searchController,
                  autofocus: true,
                  style: TextStyle(
                    fontSize: 18,
                    fontFamily: CommonFonts.primaryFont,
                    color: context.colors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Search in conversation...',
                    hintStyle: TextStyle(
                      fontSize: 18,
                      fontFamily: CommonFonts.primaryFont,
                      color: context.colors.textHint,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
              ),
              if (_searchQuery.isNotEmpty)
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _searchQuery = '';
                      _searchController.clear();
                    });
                  },
                  child: Icon(Icons.close, size: 18, color: context.colors.textSecondary),
                ),
            ],
          ),
        ),
        actions: const [
          SizedBox(width: 8),
        ],
      );
    }

    if (_selectedMessageIds.isNotEmpty) {
      return AppBar(
        backgroundColor: context.colors.primary,
        elevation: 0,
        leading: IconButton(
          icon: Icon(CommonIcons.close, color: context.colors.pureWhite),
          onPressed: () {
            setState(() {
              _selectedMessageIds.clear();
            });
          },
        ),
        title: Text(
          '${_selectedMessageIds.length} selected',
          style: context.titleMedium.copyWith(color: context.colors.pureWhite, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: Icon(CommonIcons.copy, color: context.colors.pureWhite),
            onPressed: () {
              if (state is ChatLoaded) {
                final selectedMsgs = state.messages
                    .where((m) => _selectedMessageIds.contains(m.id))
                    .map((m) => m.content)
                    .join('\n');
                if (selectedMsgs.isNotEmpty) {
                  Clipboard.setData(ClipboardData(text: selectedMsgs));
                  context.showSuccessNotification('Messages copied to clipboard');
                }
              }
              setState(() {
                _selectedMessageIds.clear();
              });
            },
          ),
          IconButton(
            icon: Icon(CommonIcons.delete, color: context.colors.pureWhite),
            onPressed: () {
              if (state is ChatLoaded) {
                final selectedMsgs = state.messages
                    .where((m) => _selectedMessageIds.contains(m.id))
                    .toList();
                _showDeleteDialog(context, selectedMsgs);
              }
            },
          ),
          CommonSpaces.w8,
        ],
      );
    }

    final isBlocked = state is ChatLoaded && state.isBlocked;
    final isOnline = (state is ChatLoaded ? state.isRecipientOnline : widget.isOnline) && !isBlocked;
    final isTyping = (state is ChatLoaded && state.isRecipientTyping) && !isBlocked;
    final lastSeen = isBlocked ? null : (state is ChatLoaded ? state.lastSeen : null);
    final effectivePicUrl = isBlocked ? null : (_effectiveProfilePic ?? widget.profilePictureUrl);
    final isGroup = _effectiveIsGroup || widget.isGroup;
    final displayTitle = _effectiveContactName.isNotEmpty && _effectiveContactName != 'sChat' && _effectiveContactName != 'Chat' && _effectiveContactName != 'New Message'
        ? _effectiveContactName
        : (widget.contactName.isNotEmpty && widget.contactName != 'sChat' && widget.contactName != 'Chat' && widget.contactName != 'New Message'
            ? widget.contactName
            : (isGroup ? 'Group Chat' : 'User'));

    return AppBar(
      backgroundColor: context.colors.scaffoldBackground,
      elevation: 0,
      iconTheme: IconThemeData(color: context.colors.textPrimary),
      titleSpacing: 0,
      title: GestureDetector(
        onTap: () {
          if (isGroup) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => BlocProvider.value(
                  value: _chatBloc,
                  child: GroupInfoPage(
                    conversationId: widget.conversationId,
                    groupName: displayTitle,
                    groupColor: widget.contactColor,
                  ),
                ),
              ),
            );
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => BlocProvider.value(
                  value: _chatBloc,
                  child: ContactProfilePage(
                    conversationId: widget.conversationId,
                    contactName: displayTitle,
                    contactColor: widget.contactColor,
                    isOnline: isOnline,
                    recipientId: widget.recipientId,
                    profilePictureUrl: effectivePicUrl,
                  ),
                ),
              ),
            );
          }
        },
        child: Row(
          children: [
            GestureDetector(
              onTap: () {
                if (effectivePicUrl != null &&
                    effectivePicUrl.isNotEmpty) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FullScreenImagePage(
                        imageUrl: effectivePicUrl,
                      ),
                    ),
                  );
                }
              },
              child: Stack(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: widget.contactColor.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: ClipOval(
                      child: (effectivePicUrl != null &&
                              effectivePicUrl.isNotEmpty)
                          ? CachedNetworkImage(
                              imageUrl: effectivePicUrl,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Center(
                                child: Text(
                                  displayTitle.isNotEmpty
                                      ? displayTitle.substring(0, 1)
                                      : '?',
                                  style: context.titleMedium.copyWith(
                                    color: widget.contactColor,
                                  ),
                                ),
                              ),
                              errorWidget: (context, url, error) => Center(
                                child: Text(
                                  displayTitle.isNotEmpty
                                      ? displayTitle.substring(0, 1)
                                      : '?',
                                  style: context.titleMedium.copyWith(
                                    color: widget.contactColor,
                                  ),
                                ),
                              ),
                            )
                          : Center(
                              child: Text(
                                displayTitle.isNotEmpty
                                    ? displayTitle.substring(0, 1)
                                    : '?',
                                style: context.titleMedium.copyWith(
                                  color: widget.contactColor,
                                ),
                              ),
                            ),
                    ),
                  ),
                  if (isOnline)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: context.colors.success,
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: context.colors.scaffoldBackground,
                              width: 2),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            CommonSpaces.w12,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    displayTitle,
                    style: context.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (!isGroup && isBlocked)
                    const SizedBox.shrink()
                  else
                    Text(
                      isTyping
                          ? 'Typing...'
                          : (isGroup
                              ? 'Group Chat'
                              : (isOnline
                                  ? 'Online'
                                  : _formatLastSeenStatus(lastSeen))),
                      style: context.bodyMedium.copyWith(
                        color: (isTyping || (!isGroup && isOnline))
                            ? context.colors.success
                            : context.colors.textHint,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        if (widget.isReadOnly)
          Center(
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: context.colors.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: context.colors.primary.withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.lock_outline_rounded, size: 14, color: context.colors.primary),
                  const SizedBox(width: 4),
                  Text(
                    'Read Only',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: context.colors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        if (!widget.isReadOnly)
          IconButton(
            icon: Icon(CommonIcons.videocam),
            onPressed: () async {
              if (state is ChatLoaded && state.isBlocked) {
                context.showErrorNotification(state.isBlockedByMe
                    ? 'You blocked this contact. Unblock to make calls.'
                    : 'Cannot call this contact.');
                return;
              }
              final hasPermission = await PermissionHelper.checkCallPermissions(isVideo: true);
              if (!hasPermission) {
                if (mounted) {
                  context.showErrorNotification('Camera and Microphone permissions are required for video calls');
                }
                return;
              }
              
              final isAlreadyInCall = _callWebRtcBloc.isCallActiveFor(widget.conversationId);
              
              if (!mounted) return;
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => BlocProvider.value(
                    value: _callWebRtcBloc,
                    child: VideoCallPage(
                      conversationId: widget.conversationId,
                      contactName: widget.contactName,
                      contactColor: widget.contactColor,
                      recipientId: widget.recipientId,
                      isOutgoing: !isAlreadyInCall,
                      profilePictureUrl: effectivePicUrl,
                      myProfilePictureUrl: getIt<StorageService>().getProfilePic(),
                      isGroup: widget.isGroup,
                      groupName: widget.isGroup ? widget.contactName : null,
                      extraParticipants: widget.isGroup ? _groupParticipants : const [],
                    ),
                  ),
                ),
              );
            },
          ),
        if (!widget.isReadOnly)
          IconButton(
            icon: Icon(CommonIcons.phone),
            onPressed: () async {
              if (state is ChatLoaded && state.isBlocked) {
                context.showErrorNotification(state.isBlockedByMe
                    ? 'You blocked this contact. Unblock to make calls.'
                    : 'Cannot call this contact.');
                return;
              }
              final hasPermission = await PermissionHelper.checkCallPermissions(isVideo: false);
              if (!hasPermission) {
                if (mounted) {
                  context.showErrorNotification('Microphone permission is required for audio calls');
                }
                return;
              }

              final isAlreadyInCall = _callWebRtcBloc.isCallActiveFor(widget.conversationId);

              if (!mounted) return;
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => BlocProvider.value(
                    value: _callWebRtcBloc,
                    child: AudioCallPage(
                      conversationId: widget.conversationId,
                      contactName: widget.contactName,
                      contactColor: widget.contactColor,
                      recipientId: widget.recipientId,
                      isOutgoing: !isAlreadyInCall,
                      profilePictureUrl: effectivePicUrl,
                      myProfilePictureUrl: getIt<StorageService>().getProfilePic(),
                      isGroup: widget.isGroup,
                      groupName: widget.isGroup ? widget.contactName : null,
                      extraParticipants: widget.isGroup ? _groupParticipants : const [],
                    ),
                  ),
                ),
              );
            },
          ),
        PopupMenuButton<String>(
          icon: Icon(CommonIcons.moreVert),
          color: context.colors.scaffoldBackground,
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          onSelected: (value) async {
            if (value == 'background_color') {
              _showBackgroundColorBottomSheet(context);
            } else if (value == 'search') {
              setState(() => _isSearching = true);
            } else if (value == 'view_contact' || value == 'group_info') {
              if (widget.isGroup) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BlocProvider.value(
                      value: _chatBloc,
                      child: GroupInfoPage(
                        conversationId: widget.conversationId,
                        groupName: widget.contactName,
                        groupColor: widget.contactColor,
                      ),
                    ),
                  ),
                );
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MultiBlocProvider(
                      providers: [
                        BlocProvider.value(value: _chatBloc),
                        BlocProvider.value(value: _callWebRtcBloc),
                      ],
                      child: ContactProfilePage(
                        conversationId: widget.conversationId,
                        contactName: widget.contactName,
                        contactColor: widget.contactColor,
                        isOnline: isOnline,
                        recipientId: widget.recipientId,
                        profilePictureUrl: widget.profilePictureUrl,
                      ),
                    ),
                  ),
                );
              }
            } else if (value == 'disappearing') {
              final currentTimer = state is ChatLoaded ? state.disappearingTimer : null;
              _showDisappearingMessagesBottomSheet(context, currentTimer);
            } else if (value == 'mute') {
              final isMuted = state is ChatLoaded && state.isMuted;
              _chatBloc.add(ToggleMuteEvent(isMuted: !isMuted));
              context.showInfoNotification(isMuted ? 'Notifications unmuted' : 'Notifications muted');
            } else if (value == 'media') {
              if (state is ChatLoaded) {
                _navigateToSharedMedia(context, state);
              }
            } else if (value == 'favourite') {
              final isFav = state is ChatLoaded && state.isFavorite;
              _chatBloc.add(ToggleFavoriteEvent(isFavorite: !isFav));
              context.showSuccessNotification(isFav ? 'Removed from favorites' : 'Added to favorites');
            } else if (value == 'new_group') {
              final chat = await showModalBottomSheet<ChatModel>(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (dialogCtx) => BlocProvider.value(
                  value: getIt<ContactsBloc>()..add(const LoadContacts()),
                  child: const CreateGroupBottomSheet(),
                ),
              );
              if (chat != null && context.mounted) {
                context.showSuccessNotification('Group created successfully');
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatPage(
                      conversationId: chat.id,
                      contactName: chat.groupName ?? 'Group',
                      contactColor: context.colors.primary,
                      isOnline: false,
                      recipientId: chat.id,
                      isGroup: true,
                    ),
                  ),
                );
              }
            } else if (value == 'clear_chat') {
              _showClearChatBottomSheet(context);
            } else if (value == 'scheduled') {
              _showScheduleMessageBottomSheet(context);
            } else if (value == 'screen_permission') {
              _showRequestScreenPermissionBottomSheet(context);
            } else if (value == 'chat_privacy') {
              _showChatPrivacyBottomSheet(context);
            } else if (value == 'lock_chat') {
              final isCurrentlyLocked = state is ChatLoaded && state.isLocked;
              final changed = await ChatLockBottomSheet.show(
                context,
                conversationId: widget.conversationId,
                contactName: widget.contactName,
                isCurrentlyLocked: isCurrentlyLocked,
              );
              if (changed == true && context.mounted) {
                _chatBloc.add(ToggleLockEvent(isLocked: !isCurrentlyLocked));
                if (!isCurrentlyLocked) {
                  Navigator.of(context).pop();
                }
              }
            }
          },
          itemBuilder: (BuildContext context) {
            if (widget.isGroup) {
              return [
                _buildMenuItem('search', CommonIcons.search, 'Search'),
                _buildMenuItem('group_info', CommonIcons.infoOutline, 'Group info'),
                _buildMenuItem('media', CommonIcons.gallery, 'Group media'),
                _buildMenuItem('scheduled', Icons.schedule_rounded, 'Scheduled messages'),
                if (_isAdmin)
                  _buildMenuItem('background_color', Icons.color_lens_outlined, 'Chat theme'),
                if (_isAdmin) ...[
                  _buildMenuItem('disappearing', Icons.timer_outlined, 'Disappearing messages'),
                  _buildMenuItem('clear_chat', Icons.cleaning_services_rounded, 'Clear chat'),
                ],
              ];
            } else {
              return [
                _buildMenuItem('search', CommonIcons.search, 'Search message'),
                _buildMenuItem('screen_permission', Icons.security_rounded, 'Request Screenshot / Record'),
                _buildMenuItem('new_group', Icons.group_add_rounded, 'New group'),
                _buildMenuItem('view_contact', CommonIcons.personOutline, 'View contact'),
                _buildMenuItem('media', CommonIcons.gallery, 'Media, links, and docs'),
                _buildMenuItem('scheduled', Icons.schedule_rounded, 'Scheduled messages'),
                _buildMenuItem('background_color', Icons.color_lens_outlined, 'Chat theme'),
                _buildMenuItem('disappearing', Icons.timer_outlined, 'Disappearing messages'),
                _buildMenuItem('clear_chat', Icons.cleaning_services_rounded, 'Clear chat'),
              ];
            }
          },
        ),
        CommonSpaces.w8,
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1.0),
        child: Container(
          color: context.colors.border,
          height: 1.0,
        ),
      ),
    );
  }

  Widget _buildMicButton() {
    final bool hasPreview = _recordedBytes != null;
    return GestureDetector(
      onTap: () {
        if (hasPreview) return;
        if (_isRecording) {
          _stopAndPreviewRecording();
        } else {
          _startRecording();
        }
      },
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: context.colors.primary,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (_isRecording)
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.85, end: 1.2),
                duration: const Duration(milliseconds: 600),
                builder: (_, value, child) => Transform.scale(
                  scale: value,
                  child: child,
                ),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            Icon(
              _isRecording ? Icons.stop_rounded : CommonIcons.mic,
              color: Colors.white,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _checkUnknownContactStatus() async {
    if (widget.isGroup || widget.recipientId.isEmpty) return;
    try {
      final box = await Hive.openBox('accepted_unknown_contacts');
      if (box.get(widget.recipientId) == true || box.get(widget.conversationId) == true) {
        if (mounted) setState(() => _showUnknownContactBanner = false);
        return;
      }
      final contactsRepo = getIt<ContactsRepository>();
      final cachedContacts = await contactsRepo.getCachedContacts();
      final isContact = cachedContacts.any((c) =>
          c.id == widget.recipientId ||
          (c.phoneNumber.isNotEmpty && c.phoneNumber == widget.contactName));
      
      if (!isContact && mounted) {
        final chatState = _chatBloc.state;
        final isBlocked = chatState is ChatLoaded ? chatState.isBlocked : false;
        if (!isBlocked) {
          setState(() {
            _showUnknownContactBanner = true;
          });
        }
      }
    } catch (e) {
      debugPrint('Error checking unknown contact status: $e');
    }
  }

  Future<void> _continueUnknownContact() async {
    try {
      final box = await Hive.openBox('accepted_unknown_contacts');
      await box.put(widget.recipientId, true);
      await box.put(widget.conversationId, true);
    } catch (_) {}
    if (mounted) {
      setState(() {
        _showUnknownContactBanner = false;
      });
      context.showSuccessNotification('Chat continued with ${_effectiveContactName.isNotEmpty ? _effectiveContactName : 'contact'}');
    }
  }

  Future<void> _blockContact(BuildContext context) async {
    if (widget.recipientId.isEmpty) return;
    try {
      final result = await getIt<ProfileRepository>().blockUser(widget.recipientId);
      await result.when(
        success: (_) async {
          final box = await Hive.openBox('blocked_users_box');
          final String? jsonString = box.get('blocked_list');
          List<dynamic> blockedList = [];
          if (jsonString != null) {
            blockedList = jsonDecode(jsonString);
          }
          final exists = blockedList.any((e) => e['id'] == widget.recipientId);
          if (!exists) {
            blockedList.add({
              'id': widget.recipientId,
              'name': widget.contactName,
              'profilePictureUrl': widget.profilePictureUrl,
              'colorValue': widget.contactColor.toARGB32(),
            });
            await box.put('blocked_list', jsonEncode(blockedList));
          }
          _chatBloc.add(const UpdateBlockStatusEvent(
            isBlocked: true,
            isBlockedByMe: true,
            isBlockedByOther: false,
          ));
          if (mounted) {
            setState(() {
              _showUnknownContactBanner = false;
            });
            context.showSuccessNotification('${_effectiveContactName.isNotEmpty ? _effectiveContactName : 'Contact'} blocked');
          }
        },
        failure: (error, _) {
          if (context.mounted) {
            context.showErrorNotification('Failed to block: $error');
          }
        },
      );
    } catch (e) {
      debugPrint('Error blocking contact: $e');
    }
  }

  void _showBlockConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: context.colors.lightBackground,
        title: Text(
          'Block ${_effectiveContactName.isNotEmpty ? _effectiveContactName : 'this contact'}?',
          style: context.bodyLarge.copyWith(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Blocked contacts will no longer be able to call you or send you messages.',
          style: context.bodyMedium.copyWith(color: context.colors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: context.colors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _blockContact(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Block'),
          ),
        ],
      ),
    );
  }

  Widget _buildUnknownContactBanner(BuildContext context) {
    final isDark = context.colors.isDark;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2428) : const Color(0xFFF0F4F8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: context.colors.border.withValues(alpha: 0.35),
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: context.colors.primary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.shield_outlined,
                  size: 18,
                  color: context.colors.primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Unknown Contact',
                      style: TextStyle(
                        color: context.colors.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 13.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'This sender is not in your contacts. Choose to continue or block them.',
                      style: TextStyle(
                        color: context.colors.textSecondary,
                        fontSize: 11.5,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              // Block Button
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showBlockConfirmationDialog(context),
                  icon: const Icon(Icons.block_rounded, size: 16, color: Colors.redAccent),
                  label: const Text(
                    'Block',
                    style: TextStyle(
                      color: Colors.redAccent,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    side: const BorderSide(color: Colors.redAccent, width: 1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Continue Button
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _continueUnknownContact,
                  icon: const Icon(Icons.check_circle_outline, size: 16, color: Colors.white),
                  label: const Text(
                    'Continue',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.colors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _unblockContact(BuildContext context) async {
    if (widget.recipientId.isEmpty) return;
    try {
      final result = await getIt<ProfileRepository>().unblockUser(widget.recipientId);
      await result.when(
        success: (_) async {
          final box = await Hive.openBox('blocked_users_box');
          final String? jsonString = box.get('blocked_list');
          if (jsonString != null) {
            final List<dynamic> blockedList = jsonDecode(jsonString);
            blockedList.removeWhere((e) => e['id'] == widget.recipientId);
            await box.put('blocked_list', jsonEncode(blockedList));
          }
          _chatBloc.add(const UpdateBlockStatusEvent(
            isBlocked: false,
            isBlockedByMe: false,
            isBlockedByOther: false,
          ));
          if (context.mounted) {
            context.showSuccessNotification('${widget.contactName} unblocked');
          }
        },
        failure: (error, _) {
          if (context.mounted) {
            context.showErrorNotification('Failed to unblock: $error');
          }
        },
      );
    } catch (e) {
      debugPrint('Error unblocking contact: $e');
    }
  }

  Widget _buildInputBar(BuildContext context) {
    final chatState = context.read<ChatBloc>().state;
    if (chatState is ChatLoaded && chatState.isBlocked) {
      final isBlockedByMe = chatState.isBlockedByMe;
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
        decoration: BoxDecoration(
          color: (context.colors.isDark ? const Color(0xFF24272C) : Colors.white).withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: context.colors.border.withValues(alpha: 0.2),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: isBlockedByMe
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.block_rounded,
                    color: Colors.redAccent,
                    size: 15,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'You blocked this contact.',
                      style: context.bodySmall.copyWith(
                        color: context.colors.textSecondary,
                        fontWeight: FontWeight.w600,
                        fontSize: 12.5,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  TextButton(
                    onPressed: () => _unblockContact(context),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      'Unblock',
                      style: TextStyle(
                        color: context.colors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.block_rounded,
                    color: context.colors.textSecondary,
                    size: 15,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      'You cannot message or call this contact',
                      style: context.bodySmall.copyWith(
                        color: context.colors.textSecondary,
                        fontWeight: FontWeight.w500,
                        fontSize: 12.5,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
      );
    }
    if (widget.isReadOnly) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
        decoration: BoxDecoration(
          color: (context.colors.isDark ? const Color(0xFF24272C) : Colors.white).withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: context.colors.primary.withValues(alpha: 0.2),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.lock_outline_rounded,
              color: context.colors.primary,
              size: 15,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                'This conversation is in read-only mode',
                style: context.bodySmall.copyWith(
                  color: context.colors.textSecondary,
                  fontWeight: FontWeight.w500,
                  fontSize: 12.5,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
    }

    final bool isOnlyAdminsRestricted = widget.isGroup &&
        (_onlyAdminsSendMessages || (chatState is ChatLoaded && chatState.onlyAdminsSendMessages)) &&
        !_isAdmin;

    if (isOnlyAdminsRestricted) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
        decoration: BoxDecoration(
          color: (context.colors.isDark ? const Color(0xFF24272C) : Colors.white).withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: context.colors.border.withValues(alpha: 0.2),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.lock_rounded,
              color: context.colors.textSecondary,
              size: 15,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                'Only admins can send messages',
                style: context.bodySmall.copyWith(
                  color: context.colors.textSecondary,
                  fontWeight: FontWeight.w500,
                  fontSize: 12.5,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_showMentionSuggestions && widget.isGroup)
          _buildMentionOverlay(context),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: context.colors.isDark ? const Color(0xFF2D2D2D) : Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  IconButton(
                    icon: Icon(
                      _showAttachmentGrid ? CommonIcons.close : CommonIcons.attach,
                      color: context.colors.primary,
                      size: 24,
                    ),
                    onPressed: () {
                      if (!_showAttachmentGrid) {
                        _inputFocusNode.unfocus();
                      }
                      setState(() {
                        _showAttachmentGrid = !_showAttachmentGrid;
                      });
                    },
                  ),
                  Expanded(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 120),
                      child: TextField(
                        focusNode: _inputFocusNode,
                        controller: _messageController,
                        textCapitalization: TextCapitalization.sentences,
                        maxLines: null,
                        style: TextStyle(
                          fontSize: 18.5,
                          fontWeight: FontWeight.w400,
                          fontFamily: CommonFonts.primaryFont,
                          color: context.colors.textPrimary,
                          height: 1.25,
                        ),
                        onChanged: _onTextChanged,
                        decoration: InputDecoration(
                          hintText: CommonStrings.typeMessage,
                          hintStyle: TextStyle(
                            fontSize: 18,
                            fontFamily: CommonFonts.primaryFont,
                            color: context.colors.textHint,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ),
                  if (!_isTyping)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(CommonIcons.camera, color: context.colors.primary, size: 24),
                          onPressed: () => _showCameraOptions(context),
                        )
                      ],
                    ),
                  CommonSpaces.w4,
                ],
              ),
            ),
          ),
          CommonSpaces.w8,
          if (!_isTyping)
            _buildMicButton(),
          if (_isTyping)
            GestureDetector(
              onTap: () => _sendMessage(context),
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: context.colors.primary,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  CommonIcons.send,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ),
        ],
      ),
    ),
    ],
    );
  }

  Widget _buildMentionOverlay(BuildContext context) {
    if (!_showMentionSuggestions || !widget.isGroup || _groupParticipants.isEmpty) {
      return const SizedBox.shrink();
    }
    final showAllOption = _mentionQuery.isEmpty || 'all'.contains(_mentionQuery) || 'everyone'.contains(_mentionQuery);

    final filtered = _groupParticipants.where((u) {
      if (_mentionQuery.isEmpty) return true;
      final name = u.displayName.toLowerCase();
      final uname = (u.username ?? '').toLowerCase();
      final phone = u.phoneNumber;
      return name.contains(_mentionQuery) ||
          uname.contains(_mentionQuery) ||
          phone.contains(_mentionQuery);
    }).toList();

    if (!showAllOption && filtered.isEmpty) return const SizedBox.shrink();

    final totalItems = (showAllOption ? 1 : 0) + filtered.length;

    return Container(
      constraints: const BoxConstraints(maxHeight: 220),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: context.colors.isDark ? const Color(0xFF2D2D2D) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(vertical: 6),
        itemCount: totalItems,
        separatorBuilder: (_, index) => Divider(height: 1, color: Colors.grey.withValues(alpha: 0.2)),
        itemBuilder: (ctx, index) {
          if (showAllOption && index == 0) {
            return ListTile(
              dense: true,
              leading: CircleAvatar(
                radius: 18,
                backgroundColor: const Color(0xFF1E88E5).withValues(alpha: 0.15),
                child: const Icon(
                  Icons.groups_rounded,
                  color: Color(0xFF1E88E5),
                  size: 20,
                ),
              ),
              title: Text(
                '@all',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  fontFamily: CommonFonts.primaryFont,
                  color: const Color(0xFF1E88E5),
                ),
              ),
              subtitle: Text(
                'Notify everyone in this group',
                style: TextStyle(
                  fontSize: 12,
                  fontFamily: CommonFonts.primaryFont,
                  color: context.colors.textSecondary,
                ),
              ),
              onTap: () => _insertRawMention('all'),
            );
          }

          final userIndex = showAllOption ? index - 1 : index;
          final user = filtered[userIndex];
          final hasUsername = (user.username ?? '').isNotEmpty;
          return ListTile(
            dense: true,
            leading: CircleAvatar(
              radius: 18,
              backgroundColor: context.colors.primary.withValues(alpha: 0.15),
              backgroundImage: (user.profilePictureUrl != null && user.profilePictureUrl!.isNotEmpty)
                  ? CachedNetworkImageProvider(user.profilePictureUrl!)
                  : null,
              child: (user.profilePictureUrl == null || user.profilePictureUrl!.isEmpty)
                  ? Text(
                      user.displayName.isNotEmpty ? user.displayName[0].toUpperCase() : '?',
                      style: TextStyle(
                        color: context.colors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    )
                  : null,
            ),
            title: Text(
              user.displayName,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
                fontFamily: CommonFonts.primaryFont,
                color: context.colors.textPrimary,
              ),
            ),
            subtitle: hasUsername
                ? Text(
                    '@${user.username}',
                    style: TextStyle(
                      fontSize: 13,
                      fontFamily: CommonFonts.primaryFont,
                      color: context.colors.textSecondary,
                    ),
                  )
                : null,
            onTap: () => _insertMention(user),
          );
        },
      ),
    );
  }

  Widget _buildAttachmentGrid(BuildContext context) {
    final items = [
      _AttachmentGridItem(
        icon: CommonIcons.document,
        label: 'Documents',
        color: const Color(0xFF7F56D9),
        onTap: () {
          setState(() => _showAttachmentGrid = false);
          _pickDocument();
        },
      ),
      _AttachmentGridItem(
        icon: CommonIcons.videoFile,
        label: 'Video',
        color: const Color(0xFFF04438),
        onTap: () {
          setState(() => _showAttachmentGrid = false);
          _pickVideo(ImageSource.gallery);
        },
      ),
      _AttachmentGridItem(
        icon: CommonIcons.gallery,
        label: 'Gallery',
        color: const Color(0xFF9E00FF),
        onTap: () {
          setState(() => _showAttachmentGrid = false);
          _pickImage(ImageSource.gallery);
        },
      ),
      _AttachmentGridItem(
        icon: CommonIcons.audio,
        label: 'Audio',
        color: const Color(0xFFF79009),
        onTap: () {
          setState(() => _showAttachmentGrid = false);
          _pickAudio();
        },
      ),
      _AttachmentGridItem(
        icon: CommonIcons.location,
        label: 'Location',
        color: const Color(0xFF12B76A),
        onTap: () {
          setState(() => _showAttachmentGrid = false);
          _showLocationPicker(context);
        },
      ),
      _AttachmentGridItem(
        icon: CommonIcons.person,
        label: 'Contact',
        color: const Color(0xFF0086C9),
        onTap: () {
          setState(() => _showAttachmentGrid = false);
          _showContactPicker(context);
        },
      ),
    ];

    return Container(
      height: 260,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: context.colors.lightBackground,
        border: Border(
          top: BorderSide(color: context.colors.border, width: 1),
        ),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 1.0,
            ),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return GestureDetector(
                onTap: item.onTap,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: item.color.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: item.color.withValues(alpha: 0.3),
                          width: 1.5,
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          item.icon,
                          color: item.color,
                          size: 24,
                        ),
                      ),
                    ),
                    CommonSpaces.h8,
                    Text(
                      item.label,
                      style: context.bodyMedium.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: context.colors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }



  void _navigateToSharedMedia(BuildContext context, ChatLoaded state) {
    final mediaMsgs = state.messages
        .where((m) => m.mediaUrl != null && m.mediaUrl!.isNotEmpty)
        .map((m) => ChatMediaModel(
              id: m.id,
              uploaderId: m.senderId,
              mediaType: _getMediaTypeFromMsg(m),
              mimeType: _getMimeTypeFromMsg(m),
              filename: m.attachmentName ?? 'File',
              fileSizeBytes: m.fileSize ?? 0,
              status: 'completed',
              createdAt: m.createdAt,
              url: m.mediaUrl!,
              thumbnails: [],
            ))
        .toList();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SharedMediaPage(
          conversationId: widget.conversationId,
          initialMediaList: mediaMsgs,
        ),
      ),
    );
  }

  String _getMimeType(String filename, String type) {
    final ext = filename.split('.').last.toLowerCase();
    if (type == 'image') {
      switch (ext) {
        case 'png':
          return 'image/png';
        case 'webp':
          return 'image/webp';
        case 'gif':
          return 'image/gif';
        case 'svg':
          return 'image/svg+xml';
        default:
          return 'image/jpeg';
      }
    } else if (type == 'video') {
      switch (ext) {
        case 'mov':
          return 'video/quicktime';
        case 'webm':
          return 'video/webm';
        case 'avi':
          return 'video/x-msvideo';
        case 'mkv':
          return 'video/x-matroska';
        case '3gp':
          return 'video/3gpp';
        default:
          return 'video/mp4';
      }
    } else if (type == 'audio' || type == 'voice_note' || type == 'voice') {
      switch (ext) {
        case 'mp3':
          return 'audio/mpeg';
        case 'm4a':
          return 'audio/mp4';
        case 'aac':
          return 'audio/aac';
        case 'wav':
          return 'audio/wav';
        case 'ogg':
          return 'audio/ogg';
        case 'opus':
          return 'audio/opus';
        case 'webm':
          return 'audio/webm';
        default:
          return 'audio/mpeg';
      }
    }

    switch (ext) {
      case 'png':
        return 'image/png';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      case 'svg':
        return 'image/svg+xml';
      case 'mov':
        return 'video/quicktime';
      case 'mp4':
        return 'video/mp4';
      case 'webm':
        return 'video/webm';
      case 'avi':
        return 'video/x-msvideo';
      case 'mkv':
        return 'video/x-matroska';
      case 'mp3':
        return 'audio/mpeg';
      case 'wav':
        return 'audio/wav';
      case 'm4a':
        return 'audio/mp4';
      case 'aac':
        return 'audio/aac';
      case 'ogg':
        return 'audio/ogg';
      case 'opus':
        return 'audio/opus';
      case 'pdf':
        return 'application/pdf';
      case 'txt':
        return 'application/pdf';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'xls':
        return 'application/vnd.ms-excel';
      case 'xlsx':
        return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      case 'ppt':
        return 'application/vnd.ms-powerpoint';
      case 'pptx':
        return 'application/vnd.openxmlformats-officedocument.presentationml.presentation';
      case 'csv':
        return 'text/csv';
      case 'json':
        return 'application/json';
      case 'zip':
        return 'application/zip';
      case 'xml':
        return 'application/xml';
      default:
        return 'application/octet-stream';
    }
  }

  List<_GroupedChatItem> _groupChatMessages(List<MessageModel> rawMessages) {
    final List<_GroupedChatItem> result = [];
    int i = 0;
    while (i < rawMessages.length) {
      final msg = rawMessages[i];
      final isImage = (msg.mediaType == 'image' || msg.messageType == 'image' || msg.mediaType == 'CHAT_IMAGE' || (msg.mediaUrl != null && msg.mediaUrl!.contains(RegExp(r'\.(jpg|jpeg|png|webp|gif|bmp)', caseSensitive: false)))) &&
          !msg.isDeleted &&
          !msg.isDeletedForMe &&
          !msg.isViewOnce;

      if (isImage) {
        final List<MessageModel> group = [msg];
        int j = i + 1;
        while (j < rawMessages.length) {
          final nextMsg = rawMessages[j];
          final isNextImage = (nextMsg.mediaType == 'image' || nextMsg.messageType == 'image' || nextMsg.mediaType == 'CHAT_IMAGE' || (nextMsg.mediaUrl != null && nextMsg.mediaUrl!.contains(RegExp(r'\.(jpg|jpeg|png|webp|gif|bmp)', caseSensitive: false)))) &&
              !nextMsg.isDeleted &&
              !nextMsg.isDeletedForMe &&
              !nextMsg.isViewOnce &&
              nextMsg.senderId == msg.senderId;

          if (!isNextImage) break;

          final t1 = DateTime.tryParse(msg.createdAt);
          final t2 = DateTime.tryParse(nextMsg.createdAt);
          if (t1 != null && t2 != null && t2.difference(t1).abs().inMinutes > 10) {
            break;
          }

          group.add(nextMsg);
          j++;
        }

        if (group.length > 1) {
          final primary = group.firstWhere((m) => m.content.isNotEmpty, orElse: () => group.last);
          result.add(_GroupedChatItem(
            primaryMessage: primary,
            groupedImages: group,
          ));
          i = j;
          continue;
        }
      }

      result.add(_GroupedChatItem(primaryMessage: msg));
      i++;
    }
    return result;
  }

  String _getMediaType(String type) {
    switch (type) {
      case 'image':
        return 'CHAT_IMAGE';
      case 'video':
        return 'CHAT_VIDEO';
      case 'audio':
      case 'voice_note':
        return 'VOICE_NOTE';
      default:
        return 'DOCUMENT';
    }
  }

  Future<void> _handleContactSelected(String name, String phone) async {
    final cleanPhone = phone.replaceAll(RegExp(r'\D'), '');

    // Set initial preview status assuming non-schat first (immediate UI feedback)
    setState(() {
      _selectedAttachmentPath = 'contact:$phone';
      _selectedAttachmentName = '$name · $phone';
      _selectedAttachmentType = 'contact';
      _selectedAttachmentBytes = null;
      _selectedAttachmentSize = 0;
      _attachmentAllowShare = false;
      _attachmentAllowDownload = false;
      _attachmentAllowView = true;
      _isTyping = true;
    });

    if (cleanPhone.isEmpty) return;

    try {
      // 1. Check local cache
      final cached = await getIt<ContactsRepository>().getCachedContacts();
      final matched = cached.firstWhereOrNull((u) => u.phoneNumber.replaceAll(RegExp(r'\D'), '') == cleanPhone);
      if (matched != null) {
        if (mounted) {
          setState(() {
            _selectedAttachmentPath = 'contact:$phone:${matched.id}';
          });
        }
        return;
      }

      // 2. Check server
      final result = await getIt<ContactsRepository>().syncContacts([
        {'phone_number': cleanPhone, 'contact_name': name},
      ]);
      result.when(
        success: (users) {
          if (users.isNotEmpty && mounted) {
            setState(() {
              _selectedAttachmentPath = 'contact:$phone:${users.first.id}';
            });
          }
        },
        failure: (_, _) {},
      );
    } catch (e) {
      debugPrint('Error checking contact: $e');
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      if (source == ImageSource.gallery) {
        final List<XFile> images = await picker.pickMultiImage(imageQuality: 80);
        if (images.isEmpty || !mounted) return;

        if (images.length == 1) {
          final image = images.first;
          final String name = image.name;
          final int size = await image.length();
          if (!mounted) return;
          final Uint8List bytes = await image.readAsBytes();
          if (!mounted) return;

          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AttachmentPreviewPage(
                path: kIsWeb ? null : image.path,
                bytes: bytes,
                name: name,
                type: 'image',
                size: size,
                contactName: widget.contactName,
              ),
            ),
          );

          if (result != null && result['send'] == true && mounted) {
            final caption = (result['caption'] as String?) ?? '';
            final sendBytes = (result['bytes'] as Uint8List?) ?? bytes;
            final sendPath = (result['path'] as String?) ?? (kIsWeb ? null : image.path);
            setState(() {
              _selectedAttachmentPath = sendPath;
              _selectedAttachmentBytes = sendBytes;
              _selectedAttachmentName = name;
              _selectedAttachmentType = 'image';
              _selectedAttachmentSize = sendBytes.length;
              _attachmentAllowShare = (result['allowShare'] as bool?) ?? false;
              _attachmentAllowDownload = (result['allowDownload'] as bool?) ?? false;
              _attachmentAllowView = (result['allowView'] as bool?) ?? true;
              _attachmentIsViewOnce = (result['isViewOnce'] as bool?) ?? false;
              _attachmentViewCount = (result['maxViews'] as int?) ?? 1;
              _messageController.text = caption;
            });
            _uploadAndSendAttachment(context);
          }
        } else {
          // Multiple images selected: open multi-item preview first
          final List<AttachmentPreviewItem> previewItems = [];
          for (final image in images) {
            final String name = image.name;
            final int size = await image.length();
            final Uint8List bytes = await image.readAsBytes();
            previewItems.add(AttachmentPreviewItem(
              path: kIsWeb ? null : image.path,
              bytes: bytes,
              name: name,
              type: 'image',
              size: size,
            ));
          }

          if (!mounted) return;
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AttachmentPreviewPage(
                path: previewItems.first.path,
                bytes: previewItems.first.bytes,
                name: previewItems.first.name,
                type: 'image',
                size: previewItems.first.size,
                contactName: widget.contactName,
                extraItems: previewItems,
              ),
            ),
          );

          if (result != null && result['send'] == true && mounted) {
            final caption = (result['caption'] as String?) ?? '';
            final allowShare = (result['allowShare'] as bool?) ?? false;
            final allowDownload = (result['allowDownload'] as bool?) ?? false;
            final allowView = (result['allowView'] as bool?) ?? true;
            final isViewOnce = (result['isViewOnce'] as bool?) ?? false;
            final maxViews = (result['maxViews'] as int?) ?? 1;

            final int batchBase = DateTime.now().millisecondsSinceEpoch;
            for (int i = 0; i < previewItems.length; i++) {
              final item = previewItems[i];
              final String tempId = 'temp_${batchBase}_$i';
              final itemCaption = (i == 0) ? caption : '';

              _chatBloc.add(SendMessageEvent(
                conversationId: widget.conversationId,
                text: itemCaption,
                type: 'image',
                attachmentPath: item.path,
                attachmentName: item.name,
                attachmentBytes: item.bytes,
                allowShare: allowShare,
                allowDownload: allowDownload,
                allowView: allowView,
                isViewOnce: isViewOnce,
                maxViews: maxViews,
                fileSize: item.size,
                messageId: tempId,
              ));

              _performBackgroundUploadAndSend(
                context: context,
                type: 'image',
                name: item.name,
                bytes: item.bytes,
                path: item.path,
                size: item.size,
                caption: itemCaption,
                allowShare: allowShare,
                allowDownload: allowDownload,
                allowView: allowView,
                isViewOnce: isViewOnce,
                viewCount: maxViews,
                tempId: tempId,
              );
            }
          }
        }
      } else {
        // Single camera photo
        final XFile? image = await picker.pickImage(source: source, imageQuality: 80);
        if (image == null || !mounted) return;

        final String name = image.name;
        final int size = await image.length();
        if (!mounted) return;

        final Uint8List bytes = await image.readAsBytes();
        if (!mounted) return;

        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AttachmentPreviewPage(
              path: kIsWeb ? null : image.path,
              bytes: bytes,
              name: name,
              type: 'image',
              size: size,
              contactName: widget.contactName,
            ),
          ),
        );

        if (result != null && result['send'] == true && mounted) {
          final caption = (result['caption'] as String?) ?? '';
          final sendBytes = (result['bytes'] as Uint8List?) ?? bytes;
          final sendPath = (result['path'] as String?) ?? (kIsWeb ? null : image.path);
          setState(() {
            _selectedAttachmentPath = sendPath;
            _selectedAttachmentBytes = sendBytes;
            _selectedAttachmentName = name;
            _selectedAttachmentType = 'image';
            _selectedAttachmentSize = sendBytes.length;
            _attachmentAllowShare = (result['allowShare'] as bool?) ?? false;
            _attachmentAllowDownload = (result['allowDownload'] as bool?) ?? false;
            _attachmentAllowView = (result['allowView'] as bool?) ?? true;
            _attachmentIsViewOnce = (result['isViewOnce'] as bool?) ?? false;
            _attachmentViewCount = (result['maxViews'] as int?) ?? 1;
            _messageController.text = caption;
          });
          _uploadAndSendAttachment(context);
        }
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      if (mounted) {
        context.showErrorNotification('Failed to pick image: $e');
      }
    }
  }

  /// Shows a bottom sheet with Photo / Video options when the camera icon is tapped.
  void _showCameraOptions(BuildContext ctx) {
    showModalBottomSheet(
      context: ctx,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return SafeArea(
          child: Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: ctx.colors.lightBackground,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: ctx.colors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(
                    'Camera',
                    style: ctx.bodyLarge.copyWith(
                      fontWeight: FontWeight.w600,
                      color: ctx.colors.textPrimary,
                    ),
                  ),
                ),
                const Divider(height: 1),
                // Photo option
                ListTile(
                  leading: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFF9E00FF).withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.photo_camera_rounded, color: Color(0xFF9E00FF), size: 22),
                  ),
                  title: Text(
                    'Take Photo',
                    style: ctx.bodyMedium.copyWith(
                      fontWeight: FontWeight.w500,
                      color: ctx.colors.textPrimary,
                    ),
                  ),
                  subtitle: Text(
                    'Capture a photo and send',
                    style: ctx.bodySmall.copyWith(color: ctx.colors.textHint),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickImage(ImageSource.camera);
                  },
                ),
                // Video option
                ListTile(
                  leading: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF04438).withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.videocam_rounded, color: Color(0xFFF04438), size: 22),
                  ),
                  title: Text(
                    'Record Video',
                    style: ctx.bodyMedium.copyWith(
                      fontWeight: FontWeight.w500,
                      color: ctx.colors.textPrimary,
                    ),
                  ),
                  subtitle: Text(
                    'Record a video and send',
                    style: ctx.bodySmall.copyWith(color: ctx.colors.textHint),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickVideo(ImageSource.camera);
                  },
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Records/picks a video from [source] and sets it as a pending attachment.
  Future<void> _pickVideo(ImageSource source) async {
    if (kIsWeb) {
      // Web: fall back to file picker for video
      setState(() => _showAttachmentGrid = false);
      _pickFile(FileType.video);
      return;
    }
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? video = await picker.pickVideo(
        source: source,
        maxDuration: const Duration(minutes: 5),
      );
      if (video == null || !mounted) return;

      final String name = video.name.isEmpty ? 'video_${DateTime.now().millisecondsSinceEpoch}.mp4' : video.name;
      final int size = await video.length();
      if (!mounted) return;

      final Uint8List bytes = await video.readAsBytes();
      if (!mounted) return;

      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AttachmentPreviewPage(
            path: video.path,
            bytes: bytes,
            name: name,
            type: 'video',
            size: size,
            contactName: widget.contactName,
          ),
        ),
      );

      if (result != null && result['send'] == true && mounted) {
        final caption = result['caption'] as String;
        setState(() {
          _selectedAttachmentPath = video.path;
          _selectedAttachmentBytes = bytes;
          _selectedAttachmentName = name;
          _selectedAttachmentType = 'video';
          _selectedAttachmentSize = size;
          _attachmentAllowShare = (result['allowShare'] as bool?) ?? false;
          _attachmentAllowDownload = (result['allowDownload'] as bool?) ?? false;
          _attachmentAllowView = (result['allowView'] as bool?) ?? true;
          _attachmentIsViewOnce = (result['isViewOnce'] as bool?) ?? false;
          _attachmentViewCount = (result['maxViews'] as int?) ?? 1;
          _messageController.text = caption;
        });
        _uploadAndSendAttachment(context);
      }
    } catch (e) {
      debugPrint('Video picker error: $e');
      if (mounted) {
        context.showErrorNotification('Failed to record video: $e');
      }
    }
  }

  Future<void> _pickDocument() async {
    const documentExtensions = [
      'pdf', 'doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx',
      'txt', 'csv', 'rtf', 'odt', 'ods', 'odp', 'zip', 'rar',
      '7z', 'tar', 'gz', 'json', 'xml', 'html', 'apk', 'enc'
    ];
    await _pickFile(FileType.custom, allowedExtensions: documentExtensions, explicitType: 'file');
  }

  Future<void> _pickAudio() async {
    const audioExtensions = [
      'mp3', 'wav', 'm4a', 'aac', 'ogg', 'opus', 'flac', 'amr', 'wma'
    ];
    await _pickFile(FileType.custom, allowedExtensions: audioExtensions, explicitType: 'audio');
  }

  Future<void> _pickFile(FileType type, {List<String>? allowedExtensions, String? explicitType}) async {
    try {
      FilePickerResult? result;
      try {
        if (type == FileType.custom && allowedExtensions != null && allowedExtensions.isNotEmpty) {
          result = await FilePicker.pickFiles(
            type: FileType.custom,
            allowedExtensions: allowedExtensions,
            allowMultiple: true,
            withData: true,
          );
        } else {
          result = await FilePicker.pickFiles(
            type: type,
            allowedExtensions: allowedExtensions,
            allowMultiple: true,
            withData: true,
          );
        }
      } catch (e) {
        debugPrint('FilePicker error, falling back: $e');
        result = await FilePicker.pickFiles(
          type: FileType.any,
          allowMultiple: true,
          withData: true,
        );
      }

      if (result == null || result.files.isEmpty || !mounted) return;

      if (result.files.length == 1) {
        PlatformFile file = result.files.single;

        // Automatically decrypt encrypted files selected from storage/downloads
        bool wasDecrypted = false;
        if (file.path != null) {
          try {
            var realName = file.name;
            while (realName.endsWith('.enc')) {
              realName = realName.substring(0, realName.length - 4);
            }
            if (realName.isEmpty) realName = 'attachment';

            final decryptedTemp = await getIt<SecureAttachmentService>().decryptToTemporaryFile(
              encryptedFilePath: file.path!,
              originalFileName: realName,
            );
            if (decryptedTemp.path != file.path) {
              final decBytes = await decryptedTemp.readAsBytes();
              file = PlatformFile(
                path: decryptedTemp.path,
                name: realName,
                size: decBytes.length,
                bytes: decBytes,
              );
              wasDecrypted = true;
              debugPrint('Auto-decrypted Schat attachment for re-upload: ${file.name} (${file.size} bytes)');
            }
          } catch (e) {
            debugPrint('Error auto-decrypting file during selection: $e');
          }
        }

        if (wasDecrypted && mounted) {
          context.showInfoNotification('Decrypted encrypted attachment: ${file.name}');
        }

        String fileType = explicitType ?? (type == FileType.audio
            ? 'audio'
            : type == FileType.video
                ? 'video'
                : type == FileType.image
                    ? 'image'
                    : 'file');

        if (explicitType == null && fileType == 'file' && file.name.contains('.')) {
          final ext = file.name.split('.').last.toLowerCase();
          if (['png', 'jpg', 'jpeg', 'gif', 'webp', 'svg'].contains(ext)) {
            fileType = 'image';
          } else if (['mp4', 'webm', 'ogg', 'avi', 'mov', 'mkv'].contains(ext)) {
            fileType = 'video';
          } else if (['mp3', 'wav', 'm4a', 'aac', 'flac'].contains(ext)) {
            fileType = 'audio';
          }
        }

        if (!mounted) return;
        final previewResult = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AttachmentPreviewPage(
              path: file.path,
              bytes: file.bytes,
              name: file.name,
              type: fileType,
              size: file.size,
              contactName: widget.contactName,
            ),
          ),
        );

        if (previewResult != null && previewResult['send'] == true && mounted) {
          final caption = (previewResult['caption'] as String?) ?? '';
          final sendBytes = (previewResult['bytes'] as Uint8List?) ?? file.bytes;
          final sendPath = (previewResult['path'] as String?) ?? file.path;
          setState(() {
            _selectedAttachmentPath = sendPath;
            _selectedAttachmentBytes = sendBytes;
            _selectedAttachmentName = file.name;
            _selectedAttachmentType = fileType;
            _selectedAttachmentSize = sendBytes?.length ?? file.size;
            _attachmentAllowShare = (previewResult['allowShare'] as bool?) ?? false;
            _attachmentAllowDownload = (previewResult['allowDownload'] as bool?) ?? false;
            _attachmentAllowView = (previewResult['allowView'] as bool?) ?? true;
            _attachmentIsViewOnce = (previewResult['isViewOnce'] as bool?) ?? false;
            _attachmentViewCount = (previewResult['maxViews'] as int?) ?? 1;
            _messageController.text = caption;
          });
          _uploadAndSendAttachment(context);
        }
      } else {
        // Multiple files selected: open multi-item preview first
        final List<AttachmentPreviewItem> previewItems = [];
        for (int i = 0; i < result.files.length; i++) {
          PlatformFile file = result.files[i];
          if (file.path != null) {
            try {
              var realName = file.name;
              while (realName.endsWith('.enc')) {
                realName = realName.substring(0, realName.length - 4);
              }
              if (realName.isEmpty) realName = 'attachment';

              final decryptedTemp = await getIt<SecureAttachmentService>().decryptToTemporaryFile(
                encryptedFilePath: file.path!,
                originalFileName: realName,
              );
              if (decryptedTemp.path != file.path) {
                final decBytes = await decryptedTemp.readAsBytes();
                file = PlatformFile(
                  path: decryptedTemp.path,
                  name: realName,
                  size: decBytes.length,
                  bytes: decBytes,
                );
              }
            } catch (_) {}
          }

          String fileType = explicitType ?? (type == FileType.audio
              ? 'audio'
              : type == FileType.video
                  ? 'video'
                  : type == FileType.image
                      ? 'image'
                      : 'file');

          if (explicitType == null && fileType == 'file' && file.name.contains('.')) {
            final ext = file.name.split('.').last.toLowerCase();
            if (['png', 'jpg', 'jpeg', 'gif', 'webp', 'svg'].contains(ext)) {
              fileType = 'image';
            } else if (['mp4', 'webm', 'ogg', 'avi', 'mov', 'mkv'].contains(ext)) {
              fileType = 'video';
            } else if (['mp3', 'wav', 'm4a', 'aac', 'flac'].contains(ext)) {
              fileType = 'audio';
            }
          }

          previewItems.add(AttachmentPreviewItem(
            path: file.path,
            bytes: file.bytes,
            name: file.name,
            type: fileType,
            size: file.size,
          ));
        }

        if (!mounted) return;
        final previewResult = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AttachmentPreviewPage(
              path: previewItems.first.path,
              bytes: previewItems.first.bytes,
              name: previewItems.first.name,
              type: previewItems.first.type,
              size: previewItems.first.size,
              contactName: widget.contactName,
              extraItems: previewItems,
            ),
          ),
        );

        if (previewResult != null && previewResult['send'] == true && mounted) {
          final caption = (previewResult['caption'] as String?) ?? '';
          final allowShare = (previewResult['allowShare'] as bool?) ?? false;
          final allowDownload = (previewResult['allowDownload'] as bool?) ?? false;
          final allowView = (previewResult['allowView'] as bool?) ?? true;
          final isViewOnce = (previewResult['isViewOnce'] as bool?) ?? false;
          final maxViews = (previewResult['maxViews'] as int?) ?? 1;

          final int batchBase = DateTime.now().millisecondsSinceEpoch;
          for (int i = 0; i < previewItems.length; i++) {
            final item = previewItems[i];
            final String tempId = 'temp_${batchBase}_$i';
            final itemCaption = (i == 0) ? caption : '';

            _chatBloc.add(SendMessageEvent(
              conversationId: widget.conversationId,
              text: itemCaption,
              type: item.type,
              attachmentPath: item.path,
              attachmentName: item.name,
              attachmentBytes: item.bytes,
              allowShare: allowShare,
              allowDownload: allowDownload,
              allowView: allowView,
              isViewOnce: isViewOnce,
              maxViews: maxViews,
              fileSize: item.size,
              messageId: tempId,
            ));

            _performBackgroundUploadAndSend(
              context: context,
              type: item.type,
              name: item.name,
              bytes: item.bytes,
              path: item.path,
              size: item.size,
              caption: itemCaption,
              allowShare: allowShare,
              allowDownload: allowDownload,
              allowView: allowView,
              isViewOnce: isViewOnce,
              viewCount: maxViews,
              tempId: tempId,
            );
          }
        }
      }
    } catch (e) {
      debugPrint('File picker error: $e');
      if (mounted) {
        context.showErrorNotification('Failed to open file picker: $e');
      }
    }
  }



  void _showLocationPicker(BuildContext ctx) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => LocationShareBottomSheet(
        onSendLocation: (lat, lng) {
          setState(() {
            _selectedAttachmentPath = '$lat,$lng';
            _selectedAttachmentName = 'My Location';
            _selectedAttachmentType = 'location';
            _selectedAttachmentBytes = null;
            _selectedAttachmentSize = 0;
            _attachmentAllowShare = false;
            _attachmentAllowDownload = false;
            _attachmentAllowView = true;
          });
          if (mounted) _uploadAndSendAttachment(context);
        },
      ),
    );
  }

  void _showContactPicker(BuildContext ctx) {
    String searchQuery = '';
    showModalBottomSheet(
      context: ctx,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => StatefulBuilder(
        builder: (context, setSheetState) {
          return DraggableScrollableSheet(
            initialChildSize: 0.7,
            minChildSize: 0.4,
            maxChildSize: 0.9,
            expand: false,
            builder: (context, scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: context.colors.scaffoldBackground,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: context.colors.textHint.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: context.colors.primary.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(CommonIcons.contacts, color: context.colors.primary, size: 24),
                          ),
                          CommonSpaces.w16,
                          Text('Send Contact', style: context.titleLarge.copyWith(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      child: Container(
                        height: 44,
                        decoration: BoxDecoration(
                          color: context.colors.lightBackground,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: TextField(
                          onChanged: (value) {
                            setSheetState(() {
                              searchQuery = value.toLowerCase();
                            });
                          },
                          style: TextStyle(
                            fontSize: 18,
                            fontFamily: CommonFonts.primaryFont,
                            color: context.colors.textPrimary,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Search contacts...',
                            hintStyle: TextStyle(
                              fontSize: 18,
                              fontFamily: CommonFonts.primaryFont,
                              color: context.colors.textHint,
                            ),
                            prefixIcon: Icon(CommonIcons.search, size: 20, color: context.colors.textHint),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: FutureBuilder<List<Contact>>(
                        future: getIt<ContactsRepository>().getContacts(),
                        builder: (context, snapshot) {
                          log("Siva Contacts get ");
                          log(snapshot.data.toString());
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(CommonIcons.person, size: 64, color: context.colors.textHint.withValues(alpha: 0.5)),
                                  CommonSpaces.h16,
                                  Text(
                                    'No contacts found',
                                    style: context.bodyMedium.copyWith(color: context.colors.textSecondary),
                                  ),
                                ],
                              ),
                            );
                          }

                          final allContacts = snapshot.data!;
                          final filteredContacts = allContacts.where((c) {
                            final name = c.displayName.toLowerCase();
                            final phone = c.phones.isNotEmpty ? c.phones.first.number.toLowerCase() : '';
                            return name.contains(searchQuery) || phone.contains(searchQuery);
                          }).toList();

                          if (filteredContacts.isEmpty) {
                            return Center(
                              child: Text('No results for "$searchQuery"', style: context.bodyMedium),
                            );
                          }

                          return ListView.separated(
                            controller: scrollController,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            itemCount: filteredContacts.length,
                            separatorBuilder: (context, index) => const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 24),
                              child: Divider(height: 1),
                            ),
                            itemBuilder: (context, index) {
                              final c = filteredContacts[index];
                              final name = c.displayName;
                              final phone = c.phones.isNotEmpty ? c.phones.first.number : 'No number';

                              return ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                                leading: CircleAvatar(
                                  radius: 24,
                                  backgroundColor: context.colors.primary.withValues(alpha: 0.1),
                                  child: Text(
                                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                                    style: context.titleMedium.copyWith(
                                      color: context.colors.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  name,
                                  style: context.titleSmall.copyWith(
                                    color: context.colors.textPrimary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: Text(
                                  phone,
                                  style: context.bodyMedium.copyWith(
                                    color: context.colors.textSecondary,
                                    fontSize: 13,
                                  ),
                                ),
                                trailing: Text(
                                  'Send',
                                  style: context.bodyMedium.copyWith(
                                    color: context.colors.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                onTap: () {
                                  Navigator.pop(ctx);
                                  _handleContactSelected(name, phone);
                                },
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  PopupMenuItem<String> _buildMenuItem(String value, IconData icon, String label) {
    return PopupMenuItem<String>(
      value: value,
      height: 42,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: context.colors.primary, size: 19),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: context.colors.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showScheduleMessageBottomSheet(BuildContext context) async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (dialogCtx) => ScheduleMessageBottomSheet(
        conversationId: widget.conversationId,
        contactName: widget.contactName,
      ),
    );

    if (result != null && mounted) {
      final DateTime scheduledTime = result['scheduledDateTime'] as DateTime;
      final String text = result['text'] ?? '';
      final File? attachment = result['attachment'] as File?;
      final ScheduledMessageType type = result['type'] as ScheduledMessageType;

      String messageTypeStr = 'text';
      String? fileKey;
      String? fileName;
      int fileSize = 0;
      String? mimeType;

      if (type == ScheduledMessageType.image) {
        messageTypeStr = 'image';
      } else if (type == ScheduledMessageType.video) {
        messageTypeStr = 'video';
      } else if (type == ScheduledMessageType.document) {
        messageTypeStr = 'document';
      } else if (type == ScheduledMessageType.audio) {
        messageTypeStr = 'audio';
      }

      if (attachment != null) {
        fileName = attachment.path.split('/').last;
        fileSize = await attachment.length();
        mimeType = _getMimeType(attachment.path, messageTypeStr);
        
        fileKey = await getIt<ChatRepository>().uploadMedia(
          conversationId: widget.conversationId,
          filePath: attachment.path,
          fileName: fileName,
          mediaType: _getMediaType(messageTypeStr),
          mimeType: mimeType,
          fileSizeBytes: fileSize,
        );
      }

      final requestData = {
        "conversationId": widget.conversationId,
        "messageType": messageTypeStr,
        "parentMessageId": null,
        "content": {
          "text": text,
          "fileKey": fileKey,
          "thumbnail": null,
          "fileName": fileName,
          "fileSize": fileSize,
          "mimeType": mimeType,
          "duration": 0,
          "isForwarded": false,
          "forwardedFromMessageId": null,
          "forwardCount": 0,
          "contactName": null,
          "phoneNumber": null,
          "latitude": null,
          "longitude": null,
          "address": null,
          "isEdited": false,
          "editedAt": null
        },
        "security": {
          "isLocked": false,
          "accessUsers": [],
          "allowDownload": true,
          "allowShare": true,
          "allowView": true
        },
        "viewControl": {
          "type": "normal",
          "maxViews": 1,
          "viewedBy": [],
          "isOpened": false,
          "openedAt": null
        },
        "expiry": {
          "isEnabled": false,
          "expireType": null,
          "expireAt": null,
          "disappearAfterRead": false,
          "readTimerSeconds": 0
        },
        "callMeta": null,
        "scheduledAt": scheduledTime.toUtc().toIso8601String()
      };

      _chatBloc.add(ScheduleMessageEvent(requestData));

      final formattedTime =
          '${scheduledTime.year}-${scheduledTime.month.toString().padLeft(2, '0')}-${scheduledTime.day.toString().padLeft(2, '0')} '
          '${scheduledTime.hour.toString().padLeft(2, '0')}:${scheduledTime.minute.toString().padLeft(2, '0')}:${scheduledTime.second.toString().padLeft(2, '0')}';

      context.showSuccessNotification('Message scheduled for $formattedTime');
    }
  }

  void _showRequestScreenPermissionBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (dialogCtx) => RequestScreenPermissionBottomSheet(
        conversationId: widget.conversationId,
        contactName: widget.contactName,
      ),
    );
  }

  Widget _buildActiveScreenPermissionBanner(ChatState state) {
    if (state is! ChatLoaded || state.activeScreenPermission == null) {
      return const SizedBox.shrink();
    }
    final perm = state.activeScreenPermission!;
    final isScreenshot = perm.isScreenshot;
    final remaining = perm.remainingCount ?? perm.allowedCount ?? 1;

    if (remaining <= 0 || perm.isCompleted || perm.isRejected) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: context.colors.primary.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.colors.primary.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(
            isScreenshot ? Icons.camera_alt_rounded : Icons.videocam_rounded,
            color: context.colors.primary,
            size: 20,
          ),
          CommonSpaces.w10,
          Expanded(
            child: Text(
              isScreenshot
                  ? 'Screenshot allowed: $remaining remaining'
                  : 'Screen recording allowed: ${perm.durationSeconds ?? 30}s',
              style: context.bodySmall.copyWith(
                color: context.colors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (isScreenshot)
            InkWell(
              onTap: () {
                final currentRemaining = perm.remainingCount ?? perm.allowedCount ?? 1;
                final newRemaining = currentRemaining - 1;
                if (newRemaining <= 0) {
                  getIt<ScreenProtectionService>().enableProtection();
                  context.showInfoNotification('All allowed screenshot(s) used. Protection re-enabled.');
                } else {
                  context.showSuccessNotification('Screenshot used ($newRemaining remaining)');
                }
                _chatBloc.add(ConsumeScreenPermissionEvent(requestId: perm.id));
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: context.colors.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Use 1',
                  style: context.bodySmall.copyWith(
                    color: context.colors.textLight,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showChatPrivacyBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return BlocBuilder<ChatBloc, ChatState>(
          bloc: _chatBloc,
          builder: (context, state) {
            final readReceiptsEnabled = state is ChatLoaded ? state.readReceiptsEnabled : null;
            final typingIndicatorsEnabled = state is ChatLoaded ? state.typingIndicatorsEnabled : null;
            final globalRead = getIt<StorageService>().getReadReceiptsEnabled();
            final globalTyping = getIt<StorageService>().getTypingIndicatorsEnabled();

            return Material(
              color: context.colors.scaffoldBackground,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              child: SafeArea(
                top: false,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 20),
                          decoration: BoxDecoration(
                            color: context.colors.textHint.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F5E9),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.security_rounded, color: Color(0xFF00873C), size: 20),
                          ),
                          CommonSpaces.w12,
                          Text(
                            'Chat Privacy',
                            style: context.titleLarge.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      CommonSpaces.h8,
                      Text(
                        'Customize privacy settings for this chat with ${widget.contactName}.',
                        style: context.bodySmall.copyWith(color: context.colors.textSecondary),
                      ),
                      CommonSpaces.h20,

                      // Read Receipts Section
                      Text(
                        'Read Receipts',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: context.colors.primary,
                        ),
                      ),
                      CommonSpaces.h8,
                      _buildPrivacyOptionTile(
                        context: context,
                        title: 'Default (App setting: ${globalRead ? "On" : "Off"})',
                        subtitle: 'Follows your global privacy setting',
                        isSelected: readReceiptsEnabled == null,
                        onTap: () {
                          _chatBloc.add(
                            UpdateChatPrivacyEvent(
                              conversationId: widget.conversationId,
                              clearReadReceipts: true,
                            ),
                          );
                          context.showInfoNotification('Read receipts set to Default for ${widget.contactName}');
                        },
                      ),
                      _buildPrivacyOptionTile(
                        context: context,
                        title: 'Always On',
                        subtitle: 'Show read receipts for this person only',
                        isSelected: readReceiptsEnabled == true,
                        onTap: () {
                          _chatBloc.add(
                            UpdateChatPrivacyEvent(
                              conversationId: widget.conversationId,
                              readReceiptsEnabled: true,
                            ),
                          );
                          context.showInfoNotification('Read receipts enabled for ${widget.contactName}');
                        },
                      ),
                      _buildPrivacyOptionTile(
                        context: context,
                        title: 'Off',
                        subtitle: 'Turn off read receipts for this person only',
                        isSelected: readReceiptsEnabled == false,
                        onTap: () {
                          _chatBloc.add(
                            UpdateChatPrivacyEvent(
                              conversationId: widget.conversationId,
                              readReceiptsEnabled: false,
                            ),
                          );
                          context.showInfoNotification('Read receipts disabled for ${widget.contactName}');
                        },
                      ),
                      CommonSpaces.h20,

                      // Typing Indicators Section
                      Text(
                        'Typing Indicator',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: context.colors.primary,
                        ),
                      ),
                      CommonSpaces.h8,
                      _buildPrivacyOptionTile(
                        context: context,
                        title: 'Default (App setting: ${globalTyping ? "On" : "Off"})',
                        subtitle: 'Follows your global privacy setting',
                        isSelected: typingIndicatorsEnabled == null,
                        onTap: () {
                          _chatBloc.add(
                            UpdateChatPrivacyEvent(
                              conversationId: widget.conversationId,
                              clearTypingIndicators: true,
                            ),
                          );
                          context.showInfoNotification('Typing indicator set to Default for ${widget.contactName}');
                        },
                      ),
                      _buildPrivacyOptionTile(
                        context: context,
                        title: 'Always On',
                        subtitle: 'Show typing indicator for this person only',
                        isSelected: typingIndicatorsEnabled == true,
                        onTap: () {
                          _chatBloc.add(
                            UpdateChatPrivacyEvent(
                              conversationId: widget.conversationId,
                              typingIndicatorsEnabled: true,
                            ),
                          );
                          context.showInfoNotification('Typing indicator enabled for ${widget.contactName}');
                        },
                      ),
                      _buildPrivacyOptionTile(
                        context: context,
                        title: 'Off',
                        subtitle: 'Turn off typing indicator for this person only',
                        isSelected: typingIndicatorsEnabled == false,
                        onTap: () {
                          _chatBloc.add(
                            UpdateChatPrivacyEvent(
                              conversationId: widget.conversationId,
                              typingIndicatorsEnabled: false,
                            ),
                          );
                          context.showInfoNotification('Typing indicator disabled for ${widget.contactName}');
                        },
                      ),
                      CommonSpaces.h16,
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPrivacyOptionTile({
    required BuildContext context,
    required String title,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final isDark = context.colors.isDark;
    final primaryColor = isDark ? const Color(0xFF00FF87) : const Color(0xFF00873C);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isSelected
            ? (isDark ? const Color(0xFF00FF87).withValues(alpha: 0.12) : const Color(0xFFE8F5E9))
            : (isDark ? context.colors.cardBackground : Colors.white),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isSelected ? primaryColor : context.colors.border.withValues(alpha: 0.3),
          width: isSelected ? 1.5 : 1.0,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 14.5,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            color: isSelected ? primaryColor : context.colors.textPrimary,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 12,
            color: isSelected
                ? (isDark ? Colors.white70 : const Color(0xFF027A48))
                : (isDark ? Colors.white54 : const Color(0xFF6B7280)),
          ),
        ),
        trailing: isSelected
            ? Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: primaryColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_rounded,
                  size: 15,
                  color: isDark ? Colors.black : Colors.white,
                ),
              )
            : null,
        onTap: onTap,
      ),
    );
  }

  void _showClearChatBottomSheet(BuildContext context) {
    final isDark = context.colors.isDark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return Material(
          color: sheetCtx.colors.scaffoldBackground,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: sheetCtx.colors.textHint.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEE4E2),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.cleaning_services_rounded,
                          color: Color(0xFFD92D20),
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          'Clear Chat',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: sheetCtx.colors.textPrimary,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Are you sure you want to clear messages in this chat? Choose whether to clear for yourself or for both participants.',
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.45,
                      color: isDark ? Colors.white70 : const Color(0xFF4B5563),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Button 1: Clear for me
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(sheetCtx);
                        _chatBloc.add(ClearChatEvent(
                          conversationId: widget.conversationId,
                          clearType: 'me',
                        ));
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                        alignment: Alignment.centerLeft,
                        side: BorderSide(
                          color: const Color(0xFFD92D20).withValues(alpha: 0.4),
                          width: 1.2,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        backgroundColor: isDark
                            ? const Color(0xFFD92D20).withValues(alpha: 0.08)
                            : const Color(0xFFFEF3F2),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.person_outline_rounded,
                            color: Color(0xFFD92D20),
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Clear for me',
                                  style: TextStyle(
                                    color: Color(0xFFD92D20),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Messages will be cleared for you only',
                                  style: TextStyle(
                                    color: isDark ? Colors.white60 : const Color(0xFF6B7280),
                                    fontSize: 12,
                                    fontWeight: FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Button 2: Clear for everyone
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(sheetCtx);
                        _chatBloc.add(ClearChatEvent(
                          conversationId: widget.conversationId,
                          clearType: 'everyone',
                        ));
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                        alignment: Alignment.centerLeft,
                        backgroundColor: const Color(0xFFD92D20),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.groups_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Clear for everyone',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Permanently clears messages for all participants',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                    fontWeight: FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Cancel Button
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () => Navigator.pop(sheetCtx),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          color: sheetCtx.colors.textSecondary,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showDisappearingMessagesBottomSheet(BuildContext context, int? currentTimer) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Material(
          color: context.colors.scaffoldBackground,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: context.colors.textHint.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Row(
                  children: [
                    Icon(Icons.timer_outlined, color: context.colors.primary, size: 24),
                    CommonSpaces.w12,
                    Text(
                      'Disappearing messages',
                      style: context.titleLarge.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                CommonSpaces.h16,
                Text(
                  'For more privacy and storage, all new messages will disappear from this chat for everyone after the selected duration.',
                  style: context.bodyMedium.copyWith(color: context.colors.textSecondary),
                ),
                CommonSpaces.h24,
                _buildDisappearingOption(context, 'Off', 0, currentTimer),
                _buildDisappearingOption(context, '24 hours', 86400, currentTimer),
                _buildDisappearingOption(context, '7 days', 604800, currentTimer),
                _buildDisappearingOption(context, '30 days', 2592000, currentTimer),
                _buildCustomDailyTimeOption(context, currentTimer),
                CommonSpaces.h20,
              ],
            ),
          ),
        );
      },
    );
  }

  int _encodeDailyCutoffTime(int hour, int minute) {
    return -((hour * 3600 + minute * 60) + 1);
  }

  TimeOfDay? _decodeDailyCutoffTime(int? encoded) {
    if (encoded == null || encoded >= 0) return null;
    final totalSeconds = (-encoded) - 1;
    final hour = totalSeconds ~/ 3600;
    final minute = (totalSeconds % 3600) ~/ 60;
    return TimeOfDay(hour: hour, minute: minute);
  }

  String _formatDailyCutoffText(int hour, int minute) {
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour % 12 == 0 ? 12 : hour % 12;
    final displayMinute = minute == 0 ? '' : ':${minute.toString().padLeft(2, '0')}';
    return 'Daily at $displayHour$displayMinute $period';
  }

  String _getDisappearingText(int? seconds) {
    if (seconds == null || seconds == 0) return 'Off';
    if (seconds < 0) {
      final tod = _decodeDailyCutoffTime(seconds);
      if (tod != null) {
        return _formatDailyCutoffText(tod.hour, tod.minute);
      }
      return 'Custom daily';
    }
    if (seconds == 1800) return '30 minutes';
    if (seconds == 86400) return '24 hours';
    if (seconds == 604800) return '7 days';
    if (seconds == 2592000) return '30 days';
    if (seconds == 7776000) return '90 days';
    if (seconds < 60) return '$seconds seconds';
    if (seconds < 3600) {
      return '${(seconds / 60).round()} minutes';
    } else if (seconds <= 86400) {
      return '${(seconds / 3600).round()} hours';
    } else {
      return '${(seconds / 86400).round()} days';
    }
  }

  Widget _buildCustomDailyTimeOption(BuildContext context, int? currentTimer) {
    final bool isCustom = currentTimer != null && currentTimer < 0;
    final customText = isCustom ? _getDisappearingText(currentTimer) : null;
    final presets = [
      {'label': '2 AM', 'h': 2, 'm': 0},
      {'label': '7 AM', 'h': 7, 'm': 0},
      {'label': '1 PM', 'h': 13, 'm': 0},
      {'label': '2 PM', 'h': 14, 'm': 0},
      {'label': '5 PM', 'h': 17, 'm': 0},
      {'label': '11 PM', 'h': 23, 'm': 0},
    ];

    void applyCustomTime(int encoded) {
      Navigator.pop(context);
      _chatBloc.add(SetDisappearingTimerEvent(seconds: encoded));
      context.showInfoNotification('Disappearing messages set to ${_getDisappearingText(encoded)}');
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: isCustom ? context.colors.primary.withValues(alpha: 0.08) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: isCustom ? Border.all(color: context.colors.primary.withValues(alpha: 0.3)) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.schedule, color: isCustom ? context.colors.primary : context.colors.textSecondary),
            title: Text(
              isCustom ? 'Custom ($customText)' : 'Custom daily time',
              style: context.bodyLarge.copyWith(
                fontWeight: isCustom ? FontWeight.bold : FontWeight.normal,
                color: isCustom ? context.colors.primary : null,
              ),
            ),
            subtitle: Text(
              'Clears last 24h chats daily at selected time',
              style: context.bodySmall.copyWith(fontSize: 11, color: context.colors.textSecondary),
            ),
            trailing: isCustom
                ? Icon(Icons.check_rounded, color: context.colors.primary)
                : const Icon(Icons.keyboard_arrow_down_rounded),
            onTap: () async {
              final picked = await showTimePicker(
                context: context,
                initialTime: isCustom
                    ? (_decodeDailyCutoffTime(currentTimer) ?? const TimeOfDay(hour: 14, minute: 0))
                    : const TimeOfDay(hour: 14, minute: 0),
              );
              if (picked != null) {
                final encoded = _encodeDailyCutoffTime(picked.hour, picked.minute);
                applyCustomTime(encoded);
              }
            },
          ),
          Padding(
            padding: const EdgeInsets.only(left: 4, right: 4, bottom: 8),
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                ...presets.map((p) {
                  final encoded = _encodeDailyCutoffTime(p['h'] as int, p['m'] as int);
                  final isSelected = currentTimer == encoded;
                  return InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => applyCustomTime(encoded),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: isSelected ? context.colors.primary : context.colors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? context.colors.primary : context.colors.primary.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        p['label'] as String,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? Colors.white : context.colors.primary,
                        ),
                      ),
                    ),
                  );
                }),
                InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: isCustom
                          ? (_decodeDailyCutoffTime(currentTimer) ?? const TimeOfDay(hour: 14, minute: 0))
                          : const TimeOfDay(hour: 14, minute: 0),
                    );
                    if (picked != null) {
                      final encoded = _encodeDailyCutoffTime(picked.hour, picked.minute);
                      applyCustomTime(encoded);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: context.colors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: context.colors.primary.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.more_time, size: 12, color: context.colors.primary),
                        const SizedBox(width: 4),
                        Text(
                          'Pick Time',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: context.colors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDisappearingOption(BuildContext context, String label, int? seconds, int? currentTimer) {
    final bool isSelected = (currentTimer == seconds) || (currentTimer == null && seconds == 0);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label, style: context.bodyLarge),
      trailing: isSelected
          ? Icon(Icons.check_rounded, color: context.colors.primary)
          : const Icon(Icons.chevron_right_rounded),
      onTap: () {
        int? finalSeconds = seconds == 0 ? null : seconds;
        Navigator.pop(context);
        _chatBloc.add(SetDisappearingTimerEvent(seconds: finalSeconds));
        context.showInfoNotification('Disappearing messages set to $label');
      },
    );
  }

  String _getMediaTypeFromMsg(MessageModel msg) {
    switch (msg.mediaType) {
      case 'image': return 'CHAT_IMAGE';
      case 'video': return 'CHAT_VIDEO';
      case 'audio':
      case 'voice_note': return 'VOICE_NOTE';
      default: return 'DOCUMENT';
    }
  }

  String _getMimeTypeFromMsg(MessageModel msg) {
    if (msg.attachmentName != null) {
      return _getMimeType(msg.attachmentName!, msg.mediaType ?? 'file');
    }
    switch (msg.mediaType) {
      case 'image': return 'image/jpeg';
      case 'video': return 'video/mp4';
      case 'audio':
      case 'voice_note': return 'audio/mpeg';
      default: return 'application/octet-stream';
    }
  }



  void _showBackgroundColorBottomSheet(BuildContext context) {
    // Fire LoadThemesEvent to populate themes from server
    _chatBloc.add(const LoadThemesEvent());

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetCtx) => BlocProvider.value(
        value: _chatBloc,
        child: ChatThemeBottomSheet(
          conversationId: widget.conversationId,
          isGroup: widget.isGroup,
        ),
      ),
    );
  }
}

class _TypingDot extends StatefulWidget {
  final int index;
  const _TypingDot({required this.index});

  @override
  State<_TypingDot> createState() => _TypingDotState();
}

class _TypingDotState extends State<_TypingDot> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(
          widget.index * 0.2,
          0.6 + widget.index * 0.2,
          curve: Curves.easeInOut,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, -4 * _animation.value),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 2),
            height: 6,
            width: 6,
            decoration: BoxDecoration(
              color: context.colors.primary.withValues(alpha: 0.4 + (0.6 * _animation.value)),
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }
}

class _AttachmentGridItem {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  _AttachmentGridItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
}

class _VideoPreviewThumbnail extends StatefulWidget {
  final String path;
  const _VideoPreviewThumbnail({required this.path});

  @override
  State<_VideoPreviewThumbnail> createState() => _VideoPreviewThumbnailState();
}

class _VideoPreviewThumbnailState extends State<_VideoPreviewThumbnail> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _controller = kIsWeb 
        ? VideoPlayerController.networkUrl(Uri.parse(widget.path))
        : VideoPlayerController.file(File(widget.path));
    
    _controller.initialize().then((_) {
      if (mounted) setState(() => _isInitialized = true);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Center(child: Icon(Icons.play_circle_outline, color: Colors.grey));
    }
    return VideoPlayer(_controller);
  }
}

class _GroupedChatItem {
  final MessageModel primaryMessage;
  final List<MessageModel>? groupedImages;

  _GroupedChatItem({
    required this.primaryMessage,
    this.groupedImages,
  });
}

class _HorizontalActionMenuEntry extends PopupMenuEntry<String> {
  final MessageModel msg;
  final bool isMe;
  final bool isText;

  const _HorizontalActionMenuEntry({
    required this.msg,
    required this.isMe,
    required this.isText,
  });

  @override
  double get height => 48;

  @override
  bool represents(String? value) => false;

  @override
  State<_HorizontalActionMenuEntry> createState() => _HorizontalActionMenuEntryState();
}

class _HorizontalActionMenuEntryState extends State<_HorizontalActionMenuEntry> {
  Widget _buildIconButton(
    BuildContext context, {
    required String action,
    required IconData icon,
    bool isDestructive = false,
    bool isActive = false,
    bool isFlipped = false,
  }) {
    final color = isDestructive
        ? context.colors.error
        : (isActive ? context.colors.primary : context.colors.textPrimary);

    Widget iconWidget = Icon(icon, size: 21, color: color);
    if (isFlipped) {
      iconWidget = Transform.flip(flipX: true, child: iconWidget);
    }

    return Material(
      color: Colors.transparent,
      child: Tooltip(
        message: action,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => Navigator.of(context).pop(action),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
            child: iconWidget,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final msg = widget.msg;
    final isMe = widget.isMe;
    final isText = widget.isText;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildIconButton(
            context,
            action: 'Reply',
            icon: Icons.reply_rounded,
          ),
          if (isText && msg.content.isNotEmpty)
            _buildIconButton(
              context,
              action: 'Copy',
              icon: Icons.content_copy_rounded,
            ),
          _buildIconButton(
            context,
            action: msg.isPinned ? 'Unpin' : 'Pin',
            icon: msg.isPinned ? Icons.push_pin_rounded : Icons.push_pin_outlined,
            isActive: msg.isPinned,
          ),
          if (isMe || msg.allowShare)
            _buildIconButton(
              context,
              action: 'Forward',
              icon: Icons.reply_rounded,
              isFlipped: true,
            ),
          _buildIconButton(
            context,
            action: 'Info',
            icon: Icons.info_outline_rounded,
          ),
          _buildIconButton(
            context,
            action: 'Select',
            icon: Icons.checklist_rounded,
          ),
          if (isMe)
            _buildIconButton(
              context,
              action: 'Delete',
              icon: Icons.delete_outline_rounded,
              isDestructive: true,
            ),
        ],
      ),
    );
  }
}

