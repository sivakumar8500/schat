import 'dart:io';
import 'package:flutter/material.dart';
import 'package:schat/injection.dart';
import 'package:schat/features/dashboard_screen/src/domain/models/chat_model.dart';
import 'package:schat/features/profile_screen/src/domain/models/user_model.dart';
import 'package:schat/features/dashboard_screen/src/domain/repositories/contacts_repository.dart';
import 'package:schat/features/dashboard_screen/src/domain/repositories/dashboard_repository.dart';
import 'package:schat/features/chat_screen/src/domain/repositories/chat_repository.dart';
import 'package:schat/features/chat_socket_screen/src/domain/chat_socket_repository.dart';
import 'package:schat/features/dashboard_screen/src/presentation/bloc/chats_bloc.dart';
import 'package:schat/features/dashboard_screen/src/presentation/bloc/chats_event.dart';
import 'package:schat/features/dashboard_screen/src/presentation/bloc/chats_state.dart';
import 'package:schat/features/dashboard_screen/src/presentation/dashboard_page.dart';
import 'package:schat/features/dashboard_screen/src/presentation/bloc/contacts_bloc.dart';
import 'package:schat/features/dashboard_screen/src/presentation/bloc/contacts_state.dart';
import 'package:schat/core/services/share_receiver_service.dart';
import 'package:schat/utils/common_colors.dart';
import 'package:schat/utils/common_spaces.dart';
import 'package:schat/utils/common_fontstyles.dart';

class SharedMediaItem {
  final String path;
  final String name;
  final String type; // 'image', 'video', 'audio', 'file', 'text'
  final int size;

  const SharedMediaItem({
    required this.path,
    required this.name,
    required this.type,
    required this.size,
  });
}

class ShareTarget {
  final String id;
  final String name;
  final String? avatarUrl;
  final String? subtitle;
  final bool isGroup;
  final String? recipientId;
  final UserModel? userModel;
  final ChatModel? chatModel;

  const ShareTarget({
    required this.id,
    required this.name,
    this.avatarUrl,
    this.subtitle,
    this.isGroup = false,
    this.recipientId,
    this.userModel,
    this.chatModel,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ShareTarget &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class ShareForwardTargetPage extends StatefulWidget {
  final List<SharedMediaItem> mediaItems;
  final String? sharedText;

  const ShareForwardTargetPage({
    super.key,
    required this.mediaItems,
    this.sharedText,
  });

  @override
  State<ShareForwardTargetPage> createState() => _ShareForwardTargetPageState();
}

class _ShareForwardTargetPageState extends State<ShareForwardTargetPage> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _captionController = TextEditingController();
  
  List<ShareTarget> _recentChats = [];
  List<ShareTarget> _contacts = [];
  final List<ShareTarget> _selectedTargets = [];
  
  bool _isLoading = true;
  bool _isSending = false;
  String _searchQuery = '';

  static const int _maxSelection = 5;
  static const int _minSelection = 1;

  @override
  void initState() {
    super.initState();
    _loadRecipients();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _captionController.dispose();
    ShareReceiverService().onShareScreenClosed();
    super.dispose();
  }

  Future<void> _loadRecipients() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 1. Get recent chats from ChatsBloc (excluding hidden chats)
      final chatsState = getIt<ChatsBloc>().state;
      List<ChatModel> chatModels = [];
      if (chatsState is ChatsLoaded) {
        chatModels = chatsState.chats.where((c) => !c.isHidden && !c.isHided).toList();
      }

      final recent = chatModels.map((chat) {
        final name = chat.isGroup
            ? (chat.groupName ?? 'Group')
            : chat.recipient.displayName;
        return ShareTarget(
          id: chat.id,
          name: name,
          avatarUrl: chat.recipient.profilePictureUrl,
          subtitle: chat.isGroup ? 'Group Chat' : (chat.recipient.about ?? 'sChat User'),
          isGroup: chat.isGroup,
          recipientId: chat.recipient.id.isNotEmpty ? chat.recipient.id : chat.id,
          chatModel: chat,
        );
      }).toList();

      // 2. Get contacts from ContactsBloc (which already filters out locked/hidden users)
      final contactsBloc = getIt<ContactsBloc>();
      List<UserModel> userList = [];
      if (contactsBloc.state is ContactsLoaded) {
        userList = (contactsBloc.state as ContactsLoaded).syncedContacts;
      }

      if (userList.isEmpty) {
        final contactsRepo = getIt<ContactsRepository>();
        userList = await contactsRepo.getCachedContacts();
        if (userList.isEmpty) {
          final res = await contactsRepo.fetchSyncedContacts();
          res.when(
            success: (list) => userList = list,
            failure: (_, _) {},
          );
        }
      }

      final contacts = userList.map((user) {
        return ShareTarget(
          id: user.id,
          name: user.displayName,
          avatarUrl: user.profilePictureUrl,
          subtitle: user.about ?? user.phoneNumber,
          isGroup: false,
          recipientId: user.id,
          userModel: user,
        );
      }).toList()
        ..sort((a, b) => a.name.trim().toLowerCase().compareTo(b.name.trim().toLowerCase()));

      if (mounted) {
        setState(() {
          _recentChats = recent;
          _contacts = contacts;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading recipients for sharing: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _onTargetTapped(ShareTarget target) {
    if (_isSending) return;

    final isSelected = _selectedTargets.any((t) => t.id == target.id);
    if (isSelected) {
      setState(() {
        _selectedTargets.removeWhere((t) => t.id == target.id);
      });
    } else {
      if (_selectedTargets.length >= _maxSelection) {
        _showToast(
          'Maximum $_maxSelection chats allowed',
          isWarning: true,
        );
        return;
      }
      setState(() {
        _selectedTargets.add(target);
      });
    }
  }

  void _showToast(String message, {bool isWarning = false}) {
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        backgroundColor: isWarning ? const Color(0xFFE53935) : context.colors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _onCancelClose() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const DashboardPage()),
        (route) => false,
      );
    }
  }

  String _getMediaType(String type) {
    switch (type.toLowerCase()) {
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

  String _getMimeType(String filename, String type) {
    final ext = filename.split('.').last.toLowerCase();
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      case 'mp4':
        return 'video/mp4';
      case 'mov':
        return 'video/quicktime';
      case 'mp3':
        return 'audio/mpeg';
      case 'wav':
        return 'audio/wav';
      case 'm4a':
        return 'audio/m4a';
      case 'pdf':
        return 'application/pdf';
      case 'doc':
      case 'docx':
        return 'application/msword';
      case 'xls':
      case 'xlsx':
        return 'application/vnd.ms-excel';
      case 'zip':
        return 'application/zip';
      default:
        if (type == 'image') return 'image/jpeg';
        if (type == 'video') return 'video/mp4';
        if (type == 'audio') return 'audio/mpeg';
        return 'application/octet-stream';
    }
  }

  Future<void> _handleSend() async {
    if (_selectedTargets.length < _minSelection) {
      _showToast('Please select at least 1 contact or group to share', isWarning: true);
      return;
    }

    setState(() {
      _isSending = true;
    });

    final caption = _captionController.text.trim();
    final dashboardRepo = getIt<DashboardRepository>();
    final chatRepo = getIt<ChatRepository>();
    final socketRepo = getIt<ChatSocketRepository>();

    try {
      // 1. Resolve conversation IDs for all selected targets
      final List<String> conversationIds = [];
      for (final target in _selectedTargets) {
        if (target.chatModel != null) {
          conversationIds.add(target.chatModel!.id);
        } else if (target.userModel != null) {
          final res = await dashboardRepo.startDirectChat(target.userModel!.id);
          res.when(
            success: (chat) => conversationIds.add(chat.id),
            failure: (err, _) => debugPrint('Error starting chat for ${target.name}: $err'),
          );
        }
      }

      if (conversationIds.isEmpty) {
        throw Exception('Could not connect to selected recipients.');
      }

      final primaryConvId = conversationIds.first;

      // 2. Upload and dispatch each media item
      if (widget.mediaItems.isNotEmpty) {
        for (final item in widget.mediaItems) {
          String? fileKey;
          try {
            fileKey = await chatRepo.uploadMedia(
              conversationId: primaryConvId,
              filePath: item.path,
              fileName: item.name,
              mediaType: _getMediaType(item.type),
              mimeType: _getMimeType(item.name, item.type),
              fileSizeBytes: item.size > 0 ? item.size : 1024,
            );
          } catch (uploadErr) {
            debugPrint('Upload error during share: $uploadErr');
          }

          final msgType = item.type == 'voice_note' ? 'audio' : item.type;

          for (final convId in conversationIds) {
            socketRepo.sendMessage(
              conversationId: convId,
              type: msgType,
              text: caption.isNotEmpty ? caption : (item.type == 'image' ? '' : item.name),
              fileKey: fileKey,
              fileName: item.name,
              fileSize: item.size,
              mimeType: _getMimeType(item.name, item.type),
              security: const {
                'allowShare': false,
                'allowDownload': false,
                'allowView': true,
              },
              viewControl: const {
                'type': 'normal',
                'maxViews': 1,
                'isViewOnce': false,
                'allowShare': false,
                'allowDownload': false,
                'allowView': true,
              },
            );
          }
        }
      } else if (widget.sharedText != null && widget.sharedText!.isNotEmpty) {
        // Shared text only
        final textToSend = caption.isNotEmpty ? '$caption\n\n${widget.sharedText!}' : widget.sharedText!;
        for (final convId in conversationIds) {
          socketRepo.sendMessage(
            conversationId: convId,
            type: 'text',
            text: textToSend,
          );
        }
      } else if (caption.isNotEmpty) {
        for (final convId in conversationIds) {
          socketRepo.sendMessage(
            conversationId: convId,
            type: 'text',
            text: caption,
          );
        }
      }

      // Refresh recent conversations
      getIt<ChatsBloc>().add(const FetchChats());

      if (mounted) {
        final count = _selectedTargets.length;
        _showToast('Sent successfully to $count ${count == 1 ? 'chat' : 'chats'}');
        
        // Navigate directly to Dashboard Home screen
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const DashboardPage()),
          (route) => false,
        );
      }
    } catch (e) {
      debugPrint('Error sending shared message: $e');
      if (mounted) {
        setState(() {
          _isSending = false;
        });
        _showToast('Failed to share: ${e.toString()}', isWarning: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredChats = _recentChats.where((t) {
      return t.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (t.subtitle != null && t.subtitle!.toLowerCase().contains(_searchQuery.toLowerCase()));
    }).toList();

    final filteredContacts = _contacts.where((t) {
      return t.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (t.subtitle != null && t.subtitle!.toLowerCase().contains(_searchQuery.toLowerCase()));
    }).toList();

    return Scaffold(
      backgroundColor: context.colors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: context.colors.scaffoldBackground,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close_rounded, color: context.colors.textPrimary, size: 28),
          onPressed: _onCancelClose,
          tooltip: 'Cancel',
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Share to...',
              style: context.titleMedium.copyWith(
                fontWeight: FontWeight.bold,
                color: context.colors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${_selectedTargets.length}/$_maxSelection selected',
              style: context.bodySmall.copyWith(
                color: _selectedTargets.isEmpty
                    ? context.colors.textSecondary
                    : context.colors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          if (_selectedTargets.isNotEmpty)
            TextButton(
              onPressed: () {
                setState(() {
                  _selectedTargets.clear();
                });
              },
              child: Text(
                'Clear',
                style: context.bodyMedium.copyWith(
                  color: context.colors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // Media Preview Card & Caption Field
              _buildMediaPreviewHeader(),

              // Search Box
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Container(
                  decoration: BoxDecoration(
                    color: context.colors.border.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) {
                      setState(() {
                        _searchQuery = val.trim();
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Search chats or contacts...',
                      hintStyle: context.bodyMedium.copyWith(color: context.colors.textSecondary),
                      prefixIcon: Icon(Icons.search_rounded, color: context.colors.textSecondary),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _searchQuery = '';
                                });
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                ),
              ),

              // Recipient List
              Expanded(
                child: _isLoading
                    ? Center(
                        child: CircularProgressIndicator(
                          color: context.colors.primary,
                        ),
                      )
                    : (filteredChats.isEmpty && filteredContacts.isEmpty)
                        ? Center(
                            child: Text(
                              _searchQuery.isNotEmpty ? 'No matches found' : 'No contacts available',
                              style: context.bodyMedium.copyWith(color: context.colors.textSecondary),
                            ),
                          )
                        : ListView(
                            padding: EdgeInsets.only(
                              left: 12,
                              right: 12,
                              top: 4,
                              bottom: _selectedTargets.isNotEmpty ? 120 : 90,
                            ),
                            children: [
                              if (filteredChats.isNotEmpty) ...[
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  child: Text(
                                    'Recent Chats',
                                    style: context.bodySmall.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: context.colors.primary,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                                ...filteredChats.map((target) => _buildTargetTile(target)),
                                CommonSpaces.h12,
                              ],
                              if (filteredContacts.isNotEmpty) ...[
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  child: Text(
                                    'All Contacts',
                                    style: context.bodySmall.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: context.colors.primary,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                                ...filteredContacts.map((target) => _buildTargetTile(target)),
                              ],
                            ],
                          ),
              ),
            ],
          ),

          // Bottom Action Bar
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildBottomActionBar(),
          ),

          // Sending Loading Overlay
          if (_isSending)
            Container(
              color: Colors.black.withValues(alpha: 0.6),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
                  decoration: BoxDecoration(
                    color: context.colors.cardBackground,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(context.colors.primary),
                      ),
                      CommonSpaces.h16,
                      Text(
                        'Sending to ${_selectedTargets.length} ${_selectedTargets.length == 1 ? 'chat' : 'chats'}...',
                        style: context.bodyMedium.copyWith(
                          fontWeight: FontWeight.bold,
                          color: context.colors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMediaPreviewHeader() {
    if (widget.mediaItems.isEmpty && (widget.sharedText == null || widget.sharedText!.isEmpty)) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.colors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: context.colors.border.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Media Chip / Item
          if (widget.mediaItems.isNotEmpty) ...[
            SizedBox(
              height: 72,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: widget.mediaItems.length,
                separatorBuilder: (_, index) => CommonSpaces.w8,
                itemBuilder: (context, index) {
                  final item = widget.mediaItems[index];
                  return _buildMediaThumbnail(item);
                },
              ),
            ),
            CommonSpaces.h8,
          ] else if (widget.sharedText != null && widget.sharedText!.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: context.colors.border.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(Icons.link_rounded, color: context.colors.primary, size: 20),
                  CommonSpaces.w8,
                  Expanded(
                    child: Text(
                      widget.sharedText!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: context.bodySmall.copyWith(color: context.colors.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
            CommonSpaces.h8,
          ],

          // Caption Input Field
          TextField(
            controller: _captionController,
            decoration: InputDecoration(
              hintText: 'Add a caption...',
              hintStyle: context.bodySmall.copyWith(color: context.colors.textSecondary),
              prefixIcon: Icon(Icons.edit_note_rounded, color: context.colors.primary, size: 22),
              isDense: true,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaThumbnail(SharedMediaItem item) {
    final isImage = item.type == 'image';
    final isVideo = item.type == 'video';
    final isAudio = item.type == 'audio' || item.type == 'voice_note';

    return Container(
      width: 200,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: context.colors.border.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 54,
              height: 54,
              child: isImage && File(item.path).existsSync()
                  ? Image.file(File(item.path), fit: BoxFit.cover)
                  : Container(
                      color: context.colors.primary.withValues(alpha: 0.15),
                      child: Center(
                        child: Icon(
                          isVideo
                              ? Icons.videocam_rounded
                              : isAudio
                                  ? Icons.audiotrack_rounded
                                  : Icons.insert_drive_file_rounded,
                          color: context.colors.primary,
                          size: 26,
                        ),
                      ),
                    ),
            ),
          ),
          CommonSpaces.w8,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.bodySmall.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Text(
                  item.size > 0 ? _formatBytes(item.size) : item.type.toUpperCase(),
                  style: context.bodySmall.copyWith(
                    color: context.colors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Widget _buildTargetTile(ShareTarget target) {
    final isSelected = _selectedTargets.any((t) => t.id == target.id);

    return InkWell(
      onTap: () => _onTargetTapped(target),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        margin: const EdgeInsets.symmetric(vertical: 2),
        decoration: BoxDecoration(
          color: isSelected ? context.colors.primary.withValues(alpha: 0.08) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            // Avatar
            Stack(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: context.colors.primary.withValues(alpha: 0.12),
                  backgroundImage: target.avatarUrl != null && target.avatarUrl!.isNotEmpty
                      ? NetworkImage(target.avatarUrl!)
                      : null,
                  child: target.avatarUrl == null || target.avatarUrl!.isEmpty
                      ? Text(
                          target.name.isNotEmpty ? target.name[0].toUpperCase() : '?',
                          style: context.bodyLarge.copyWith(
                            color: context.colors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
                if (target.isGroup)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: context.colors.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: context.colors.scaffoldBackground, width: 1.5),
                      ),
                      child: const Icon(Icons.groups_rounded, color: Colors.white, size: 10),
                    ),
                  ),
              ],
            ),
            CommonSpaces.w12,

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    target.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.bodyMedium.copyWith(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                      color: context.colors.textPrimary,
                    ),
                  ),
                  if (target.subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      target.subtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.bodySmall.copyWith(
                        color: context.colors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Selection Checkbox / Badge
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? context.colors.primary : Colors.transparent,
                border: Border.all(
                  color: isSelected
                      ? context.colors.primary
                      : context.colors.textSecondary.withValues(alpha: 0.35),
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Center(
                      child: Icon(Icons.check_rounded, color: Colors.white, size: 16),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomActionBar() {
    final hasSelection = _selectedTargets.isNotEmpty;

    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: context.colors.cardBackground,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Selected chips preview row (if any)
          if (hasSelection) ...[
            SizedBox(
              height: 42,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _selectedTargets.length,
                separatorBuilder: (_, index) => CommonSpaces.w8,
                itemBuilder: (context, index) {
                  final target = _selectedTargets[index];
                  return Chip(
                    avatar: CircleAvatar(
                      backgroundColor: context.colors.primary.withValues(alpha: 0.2),
                      backgroundImage: target.avatarUrl != null && target.avatarUrl!.isNotEmpty
                          ? NetworkImage(target.avatarUrl!)
                          : null,
                      child: target.avatarUrl == null || target.avatarUrl!.isEmpty
                          ? Text(
                              target.name.isNotEmpty ? target.name[0].toUpperCase() : '?',
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                            )
                          : null,
                    ),
                    label: Text(
                      target.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.bodySmall.copyWith(fontWeight: FontWeight.bold),
                    ),
                    deleteIcon: const Icon(Icons.cancel_rounded, size: 16),
                    onDeleted: () {
                      setState(() {
                        _selectedTargets.removeAt(index);
                      });
                    },
                    backgroundColor: context.colors.border.withValues(alpha: 0.12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                  );
                },
              ),
            ),
            CommonSpaces.h10,
          ],

          // Send Button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: hasSelection && !_isSending ? _handleSend : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: context.colors.primary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: context.colors.border.withValues(alpha: 0.3),
                disabledForegroundColor: context.colors.textSecondary.withValues(alpha: 0.6),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: hasSelection ? 2 : 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.send_rounded,
                    size: 20,
                    color: hasSelection ? Colors.white : context.colors.textSecondary.withValues(alpha: 0.6),
                  ),
                  CommonSpaces.w8,
                  Text(
                    !hasSelection
                        ? 'Select 1 to $_maxSelection chats'
                        : 'Send to ${_selectedTargets.length} ${_selectedTargets.length == 1 ? 'chat' : 'chats'}',
                    style: context.bodyLarge.copyWith(
                      fontWeight: FontWeight.bold,
                      color: hasSelection ? Colors.white : context.colors.textSecondary.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
