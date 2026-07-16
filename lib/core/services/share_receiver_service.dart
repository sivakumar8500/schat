import 'dart:async';
import 'package:flutter/material.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:schat/main.dart'; // For navigatorKey
import 'package:schat/injection.dart';
import 'package:schat/core/storage/storage_service.dart';
import 'package:schat/features/chat_screen/chat_screen.dart';
import 'package:schat/features/dashboard_screen/src/presentation/bloc/chats_bloc.dart';
import 'package:schat/features/dashboard_screen/src/presentation/bloc/chats_state.dart';
import 'package:schat/features/dashboard_screen/src/domain/repositories/contacts_repository.dart';
import 'package:schat/features/dashboard_screen/src/domain/repositories/dashboard_repository.dart';
import 'package:schat/features/dashboard_screen/src/domain/models/chat_model.dart';
import 'package:schat/features/profile_screen/src/domain/models/user_model.dart';
import 'package:schat/utils/common_colors.dart';
import 'package:schat/utils/common_spaces.dart';
import 'package:schat/utils/common_fontstyles.dart';

class ShareReceiverService {
  static final ShareReceiverService _instance = ShareReceiverService._internal();
  factory ShareReceiverService() => _instance;
  ShareReceiverService._internal();

  StreamSubscription? _intentSub;
  bool _isHandling = false;

  void init() {
    // 1. Listen to media sharing when app is running (foreground/background)
    _intentSub = ReceiveSharingIntent.instance.getMediaStream().listen((List<SharedMediaFile> value) {
      if (value.isNotEmpty) {
        _handleSharedMedia(value);
      }
    }, onError: (err) {
      debugPrint("ReceiveSharingIntent getMediaStream error: $err");
    });

    // 2. Handle sharing when app is opened from a closed state (cold start)
    ReceiveSharingIntent.instance.getInitialMedia().then((List<SharedMediaFile> value) {
      if (value.isNotEmpty) {
        _handleSharedMedia(value);
      }
      ReceiveSharingIntent.instance.reset();
    }).catchError((err) {
      debugPrint("ReceiveSharingIntent getInitialMedia error: $err");
    });
  }

  void dispose() {
    _intentSub?.cancel();
  }

  void _handleSharedMedia(List<SharedMediaFile> media) {
    if (_isHandling) return;
    _isHandling = true;

    // Reset lock after a small delay to allow future shares
    Future.delayed(const Duration(seconds: 1), () {
      _isHandling = false;
    });

    final context = navigatorKey.currentContext;
    if (context == null) {
      debugPrint("ShareReceiverService: No current context available");
      return;
    }

    // Ensure the user is logged in before allowing sharing
    final storage = getIt<StorageService>();
    if (!storage.hasToken()) {
      debugPrint("ShareReceiverService: User is not authenticated. Share ignored.");
      return;
    }

    final firstItem = media.first;
    final String path = firstItem.path;
    
    // Detect shared type
    final typeStr = firstItem.type.toString().toLowerCase();
    String type = 'file';
    if (typeStr.contains('image')) {
      type = 'image';
    } else if (typeStr.contains('video')) {
      type = 'video';
    } else if (typeStr.contains('text') || typeStr.contains('url')) {
      type = 'text';
    }

    // Extract file name
    String name = 'Shared File';
    if (type != 'text') {
      try {
        name = Uri.parse(path).pathSegments.last;
      } catch (_) {
        name = path.split('/').last;
      }
    }

    _showRecipientSelectionSheet(
      context: context,
      sharedText: type == 'text' ? path : null,
      sharedFilePath: type != 'text' ? path : null,
      sharedFileName: name,
      sharedFileType: type,
    );
  }

  void _showRecipientSelectionSheet({
    required BuildContext context,
    String? sharedText,
    String? sharedFilePath,
    String? sharedFileName,
    String? sharedFileType,
  }) async {
    // Load contacts and chats
    final contactsRepo = getIt<ContactsRepository>();
    final dashboardRepo = getIt<DashboardRepository>();
    
    // Fetch contacts from cache or remote
    List<UserModel> contacts = await contactsRepo.getCachedContacts();
    if (contacts.isEmpty) {
      final res = await contactsRepo.fetchSyncedContacts();
      res.when(
        success: (list) => contacts = list,
        failure: (_, __) {},
      );
    }

    // Get active chats from ChatsBloc state
    List<ChatModel> recentChats = [];
    final chatsState = getIt<ChatsBloc>().state;
    if (chatsState is ChatsLoaded) {
      recentChats = chatsState.chats;
    }

    if (!context.mounted) return;

    String searchQuery = '';
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            // Filter both lists based on search query
            final filteredChats = recentChats.where((chat) {
              final name = chat.isGroup 
                  ? (chat.groupName ?? 'Group')
                  : chat.recipient.displayName;
              return name.toLowerCase().contains(searchQuery.toLowerCase());
            }).toList();

            final filteredContacts = contacts.where((contact) {
              return contact.displayName.toLowerCase().contains(searchQuery.toLowerCase());
            }).toList();

            return Material(
              color: context.colors.scaffoldBackground,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                ),
                child: Container(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.75,
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
                            Text(
                              'Share to...',
                              style: context.titleLarge.copyWith(
                                fontWeight: FontWeight.bold,
                                color: context.colors.textPrimary,
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              onPressed: () => Navigator.pop(sheetContext),
                              icon: const Icon(Icons.close),
                            ),
                          ],
                        ),
                      ),
                      // Search Bar
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: 'Search chats or contacts...',
                            prefixIcon: Icon(Icons.search, color: context.colors.textSecondary),
                            filled: true,
                            fillColor: context.colors.border.withValues(alpha: 0.1),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          onChanged: (val) {
                            setState(() {
                              searchQuery = val;
                            });
                          },
                        ),
                      ),
                      const Divider(),
                      Expanded(
                        child: ListView(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          children: [
                            if (filteredChats.isNotEmpty) ...[
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                child: Text(
                                  'Recent Chats',
                                  style: context.bodySmall.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: context.colors.primary,
                                  ),
                                ),
                              ),
                              ...filteredChats.map((chat) {
                                final name = chat.isGroup 
                                    ? (chat.groupName ?? 'Group')
                                    : chat.recipient.displayName;
                                return ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: context.colors.primary.withValues(alpha: 0.1),
                                    backgroundImage: chat.recipient.profilePictureUrl != null && chat.recipient.profilePictureUrl!.isNotEmpty
                                        ? NetworkImage(chat.recipient.profilePictureUrl!)
                                        : null,
                                    child: chat.recipient.profilePictureUrl == null || chat.recipient.profilePictureUrl!.isEmpty
                                        ? Text(name.isNotEmpty ? name[0].toUpperCase() : '?')
                                        : null,
                                  ),
                                  title: Text(name, style: context.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
                                  subtitle: Text(
                                    chat.isGroup ? 'Group Chat' : (chat.recipient.about ?? 'sChat User'),
                                    style: context.bodySmall.copyWith(color: context.colors.textSecondary),
                                  ),
                                  onTap: () {
                                    Navigator.pop(sheetContext);
                                    _navigateToChat(
                                      context: context,
                                      conversationId: chat.id,
                                      contactName: name,
                                      recipientId: chat.recipient.id.isNotEmpty ? chat.recipient.id : chat.id,
                                      isGroup: chat.isGroup,
                                      profilePictureUrl: chat.recipient.profilePictureUrl,
                                      sharedText: sharedText,
                                      sharedFilePath: sharedFilePath,
                                      sharedFileName: sharedFileName,
                                      sharedFileType: sharedFileType,
                                    );
                                  },
                                );
                              }),
                            ],
                            if (filteredContacts.isNotEmpty) ...[
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                child: Text(
                                  'All Contacts',
                                  style: context.bodySmall.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: context.colors.primary,
                                  ),
                                ),
                              ),
                              ...filteredContacts.map((contact) {
                                return ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: context.colors.primary.withValues(alpha: 0.1),
                                    backgroundImage: contact.profilePictureUrl != null && contact.profilePictureUrl!.isNotEmpty
                                        ? NetworkImage(contact.profilePictureUrl!)
                                        : null,
                                    child: contact.profilePictureUrl == null || contact.profilePictureUrl!.isEmpty
                                        ? Text(contact.displayName.isNotEmpty ? contact.displayName[0].toUpperCase() : '?')
                                        : null,
                                  ),
                                  title: Text(contact.displayName, style: context.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
                                  subtitle: Text(
                                    contact.about ?? 'Hey there! I am using sChat.',
                                    style: context.bodySmall.copyWith(color: context.colors.textSecondary),
                                  ),
                                  onTap: () async {
                                    Navigator.pop(sheetContext);
                                    
                                    // Show a loading dialog
                                    showDialog(
                                      context: context,
                                      barrierDismissible: false,
                                      builder: (_) => const Center(child: CircularProgressIndicator()),
                                    );

                                    final chatResult = await dashboardRepo.startDirectChat(contact.id);
                                    
                                    if (context.mounted) {
                                      Navigator.pop(context); // Dismiss loading
                                    }

                                    chatResult.when(
                                      success: (chat) {
                                        _navigateToChat(
                                          context: context,
                                          conversationId: chat.id,
                                          contactName: contact.displayName,
                                          recipientId: contact.id,
                                          isGroup: false,
                                          profilePictureUrl: contact.profilePictureUrl,
                                          sharedText: sharedText,
                                          sharedFilePath: sharedFilePath,
                                          sharedFileName: sharedFileName,
                                          sharedFileType: sharedFileType,
                                        );
                                      },
                                      failure: (err, _) {
                                        debugPrint("Failed to start chat for sharing: $err");
                                      },
                                    );
                                  },
                                );
                              }),
                            ],
                          ],
                        ),
                      ),
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

  void _navigateToChat({
    required BuildContext context,
    required String conversationId,
    required String contactName,
    required String recipientId,
    required bool isGroup,
    String? profilePictureUrl,
    String? sharedText,
    String? sharedFilePath,
    String? sharedFileName,
    String? sharedFileType,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatPage(
          conversationId: conversationId,
          contactName: contactName,
          contactColor: context.colors.primary,
          isOnline: false,
          recipientId: recipientId,
          isGroup: isGroup,
          profilePictureUrl: profilePictureUrl,
          initialSharedText: sharedText,
          initialSharedFilePath: sharedFilePath,
          initialSharedFileName: sharedFileName,
          initialSharedFileType: sharedFileType,
        ),
      ),
    );
  }
}
