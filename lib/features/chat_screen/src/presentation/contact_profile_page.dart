import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:schat/core/storage/storage_service.dart';
import 'package:schat/utils/common_colors.dart';
import 'package:schat/utils/common_fontstyles.dart';
import 'package:schat/utils/common_icons.dart';
import 'package:schat/utils/common_spaces.dart';
import 'package:schat/utils/permission_helper.dart';
import 'package:schat/injection.dart';
import 'package:schat/features/call_screen/call_screen.dart';
import 'package:schat/features/chat_screen/src/presentation/bloc/chat_bloc.dart';
import 'package:schat/features/chat_screen/src/presentation/bloc/chat_event.dart';
import 'package:schat/features/chat_screen/src/presentation/bloc/chat_state.dart';
import 'package:schat/features/chat_screen/src/domain/repositories/chat_repository.dart';
import 'package:schat/features/chat_screen/src/domain/models/chat_media_model.dart';
import 'package:schat/features/chat_screen/src/domain/models/message_model.dart';
import 'package:schat/features/profile_screen/src/domain/repositories/profile_repository.dart';
import 'package:schat/features/profile_screen/src/domain/models/user_model.dart';
import 'package:schat/features/chat_screen/src/presentation/shared_media_page.dart';
import 'package:schat/features/chat_screen/src/presentation/full_screen_image_page.dart';
import 'package:schat/utils/common_endpoints.dart';
import 'package:schat/utils/common_notifications.dart';
import 'package:hive/hive.dart';
import 'package:schat/features/dashboard_screen/src/domain/repositories/dashboard_repository.dart';
import 'package:schat/features/dashboard_screen/src/domain/models/chat_model.dart';
import 'package:schat/core/network/api_result.dart';
import 'package:schat/features/chat_screen/src/presentation/chat_page.dart';
import 'package:schat/features/chat_screen/src/presentation/widgets/chat_lock_bottom_sheet.dart';
import 'dart:convert';

class ContactProfilePage extends StatefulWidget {
  final String conversationId;
  final String contactName;
  final Color contactColor;
  final bool isOnline;
  final String? recipientId;
  final bool isFromGroup;
  final String? profilePictureUrl;

  const ContactProfilePage({
    super.key,
    required this.conversationId,
    required this.contactName,
    required this.contactColor,
    required this.isOnline,
    this.recipientId,
    this.isFromGroup = false,
    this.profilePictureUrl,
  });

  @override
  State<ContactProfilePage> createState() => _ContactProfilePageState();
}

class _ContactProfilePageState extends State<ContactProfilePage> {
  List<ChatMediaModel> _mediaList = [];
  bool _isLoadingMedia = true;
  bool _isBlocked = false;
  UserModel? _recipientUser;
  bool _isLoadingUser = false;

  @override
  void initState() {
    super.initState();
    _fetchSharedMedia();
    _checkBlockedStatus();
    _checkLockStatus();
    _fetchUserDetails();
  }

  Future<void> _checkLockStatus() async {
    try {
      final isLocallyLocked = getIt<StorageService>().isChatLocked(widget.conversationId);
      if (isLocallyLocked && mounted) {
        context.read<ChatBloc>().add(const ToggleLockEvent(isLocked: true));
      }

      final repo = getIt<ChatRepository>();
      final lockedList = await repo.getLockedChats();
      final isServerLocked = lockedList.any((item) {
        final cid = (item is Map) ? (item['id'] ?? item['_id'])?.toString() : null;
        return cid == widget.conversationId;
      });

      if (mounted) {
        if (isServerLocked) {
          getIt<StorageService>().saveChatLocked(widget.conversationId, true);
          context.read<ChatBloc>().add(const ToggleLockEvent(isLocked: true));
        } else if (!isServerLocked && isLocallyLocked) {
          getIt<StorageService>().saveChatLocked(widget.conversationId, false);
          context.read<ChatBloc>().add(const ToggleLockEvent(isLocked: false));
        }
      }
    } catch (_) {}
  }

  Future<void> _fetchUserDetails() async {
    if (widget.recipientId == null) return;
    setState(() => _isLoadingUser = true);
    try {
      final result = await getIt<ProfileRepository>().getUserById(widget.recipientId!);
      result.when(
        success: (user) {
          if (mounted) {
            setState(() {
              _recipientUser = user;
              if (user.isBlocked) {
                _isBlocked = true;
              }
            });
          }
        },
        failure: (_, _) {},
      );
    } catch (_) {}
    if (mounted) setState(() => _isLoadingUser = false);
  }

  Future<void> _checkBlockedStatus() async {
    if (widget.recipientId == null) return;
    try {
      final box = await Hive.openBox('blocked_users_box');
      final String? jsonString = box.get('blocked_list');
      if (jsonString != null) {
        final List<dynamic> blockedList = jsonDecode(jsonString);
        if (mounted) {
          setState(() {
            _isBlocked = blockedList.any((e) => e['id'] == widget.recipientId) || (_recipientUser?.isBlocked ?? false);
          });
        }
      }
    } catch (_) {}
  }

  Future<bool> _blockUser() async {
    if (widget.recipientId == null) return false;
    try {
      final result = await getIt<ProfileRepository>().blockUser(widget.recipientId!);
      return await result.when(
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
          if (mounted) {
            setState(() {
              _isBlocked = true;
            });
            try {
              context.read<ChatBloc>().add(const UpdateBlockStatusEvent(
                isBlocked: true,
                isBlockedByMe: true,
                isBlockedByOther: false,
              ));
            } catch (_) {}
          }
          return true;
        },
        failure: (error, _) {
          if (mounted) {
            context.showErrorNotification('Failed to block: $error');
          }
          return false;
        },
      );
    } catch (e) {
      debugPrint('Error blocking user: $e');
      return false;
    }
  }

  Future<bool> _unblockUser() async {
    if (widget.recipientId == null) return false;
    try {
      final result = await getIt<ProfileRepository>().unblockUser(widget.recipientId!);
      return await result.when(
        success: (_) async {
          final box = await Hive.openBox('blocked_users_box');
          final String? jsonString = box.get('blocked_list');
          if (jsonString != null) {
            final List<dynamic> blockedList = jsonDecode(jsonString);
            blockedList.removeWhere((e) => e['id'] == widget.recipientId);
            await box.put('blocked_list', jsonEncode(blockedList));
          }
          if (mounted) {
            setState(() {
              _isBlocked = false;
            });
            try {
              context.read<ChatBloc>().add(const UpdateBlockStatusEvent(
                isBlocked: false,
                isBlockedByMe: false,
                isBlockedByOther: false,
              ));
            } catch (_) {}
            context.showSuccessNotification('${widget.contactName} unblocked');
          }
          return true;
        },
        failure: (error, _) {
          if (mounted) {
            context.showErrorNotification('Failed to unblock: $error');
          }
          return false;
        },
      );
    } catch (e) {
      debugPrint('Error unblocking user: $e');
      return false;
    }
  }

  Future<void> _fetchSharedMedia() async {
    try {
      final repo = getIt<ChatRepository>();
      final list = await repo.getConversationMedia(widget.conversationId);
      if (mounted) {
        setState(() {
          _mediaList = list;
          _isLoadingMedia = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingMedia = false;
        });
      }
    }
  }

  String _resolveUrl(String rawUrl) {
    String url = rawUrl;
    if (url.contains('minio')) {
      try {
        final serverUri = Uri.parse(CommonEndpoints.baseUrl);
        final host = serverUri.host;
        if (host.isNotEmpty) {
          url = url.replaceAll('minio', host);
        }
      } catch (_) {}
    }
    return url;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ChatBloc, ChatState>(
      builder: (context, state) {
        final isMuted = state is ChatLoaded ? state.isMuted : false;
        final isLocked = state is ChatLoaded ? state.isLocked : false;
        final disappearingTimer = state is ChatLoaded ? state.disappearingTimer : null;
        final readReceiptsEnabled = state is ChatLoaded ? state.readReceiptsEnabled : null;
        final typingIndicatorsEnabled = state is ChatLoaded ? state.typingIndicatorsEnabled : null;

        return Scaffold(
          backgroundColor: context.colors.scaffoldBackground,
          appBar: AppBar(
            backgroundColor: context.colors.scaffoldBackground,
            elevation: 0,
            foregroundColor: context.colors.textPrimary,
            title: const Text('Contact Info'),
          ),
          body: ListView(
            children: [
              // Header Section
              _buildHeaderSection(),
              const Divider(height: 1),

              // User Info Section
              _buildUserInfoSection(),
              const Divider(height: 32),

              // Media Section
              _buildMediaSection(context),

              // Settings Section (only in 1-on-1 direct chat)
              if (!widget.isFromGroup) ...[
                const Divider(height: 32),
                _buildSettingsSection(
                  context,
                  isMuted,
                  isLocked,
                  disappearingTimer,
                  readReceiptsEnabled,
                  typingIndicatorsEnabled,
                ),
              ],

              // Destructive Section (Block, Report, Delete Chat - only in 1-on-1 direct chat)
              if (!widget.isFromGroup) ...[
                const Divider(height: 32),
                _buildDestructiveSection(context),
              ],
              CommonSpaces.h40,
            ],
          ),
        );
      },
    );
  }

  String _formatLastSeen(String lastSeenStr) {
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
      return 'last seen ${timeago.format(date)}';
    } catch (e) {
      return 'Offline';
    }
  }

  Widget _buildHeaderSection() {
    final bool isUserBlocked = _isBlocked || (_recipientUser?.isBlocked ?? false);
    final isOnline = isUserBlocked ? false : (_recipientUser?.isOnline ?? widget.isOnline);
    final lastSeenStr = isUserBlocked ? null : _recipientUser?.lastSeen;
    final String? effectivePicUrl = isUserBlocked ? null : (widget.profilePictureUrl ?? _recipientUser?.profilePictureUrl);

    return Column(
      children: [
        CommonSpaces.h24,
        GestureDetector(
          onTap: () {
            if (effectivePicUrl != null && effectivePicUrl.isNotEmpty) {
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
          child: Hero(
            tag: effectivePicUrl ?? 'profile',
            child: CircleAvatar(
              radius: 60,
              backgroundColor: widget.contactColor.withValues(alpha: 0.1),
              backgroundImage: (effectivePicUrl != null && effectivePicUrl.isNotEmpty)
                  ? NetworkImage(effectivePicUrl)
                  : null,
              child: (effectivePicUrl == null || effectivePicUrl.isEmpty)
                  ? Text(
                      widget.contactName.isNotEmpty ? widget.contactName.substring(0, 1) : '?',
                      style: context.h1.copyWith(fontSize: 48, color: widget.contactColor),
                    )
                  : null,
            ),
          ),
        ),
        CommonSpaces.h16,
        Text(widget.contactName, style: context.h3),
        CommonSpaces.h4,
        Text(
          isOnline
              ? 'Online'
              : (lastSeenStr != null && lastSeenStr.isNotEmpty
                  ? _formatLastSeen(lastSeenStr)
                  : 'Offline'),
          style: context.bodyMedium.copyWith(
            color: isOnline ? context.colors.primary : context.colors.textHint,
            fontWeight: FontWeight.bold,
          ),
        ),
        CommonSpaces.h24,
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildRoundActionButton(icon: Icons.phone, label: 'Audio', onTap: _startAudioCall),
            CommonSpaces.w32,
            _buildRoundActionButton(icon: Icons.videocam, label: 'Video', onTap: _startVideoCall),
            CommonSpaces.w32,
            _buildRoundActionButton(icon: Icons.message, label: 'Message', onTap: _openDirectMessage),
          ],
        ),
        CommonSpaces.h24,
      ],
    );
  }

  /// Builds the user info section with phone, username, about, and subscription.
  Widget _buildUserInfoSection() {
    if (_isLoadingUser) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    final user = _recipientUser;
    if (user == null) return const SizedBox.shrink();

    final phone = user.phoneNumber;
    final username = user.username ?? '';
    final about = user.about ?? '';
    final subscriptionType = user.subscriptionType ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (phone.isNotEmpty)
          _buildInfoTile(
            icon: Icons.phone_outlined,
            label: 'Phone',
            value: phone,
          ),
        if (username.isNotEmpty)
          _buildInfoTile(
            icon: Icons.alternate_email_rounded,
            label: 'Username',
            value: username,
          ),
        if (about.isNotEmpty)
          _buildInfoTile(
            icon: Icons.info_outline_rounded,
            label: 'About',
            value: about,
          ),
        if (subscriptionType.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Icon(Icons.workspace_premium_rounded, color: context.colors.primary, size: 22),
                CommonSpaces.w12,
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Subscription',
                      style: context.bodySmall.copyWith(color: context.colors.textHint),
                    ),
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: subscriptionType.toLowerCase() == 'platinum'
                              ? [const Color(0xFF8EC5FC), const Color(0xFFE0C3FC)]
                              : [const Color(0xFFFFD700), const Color(0xFFFFA500)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        subscriptionType,
                        style: context.bodySmall.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        CommonSpaces.h8,
      ],
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String label,
    required String value,
    Widget? trailing,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: context.colors.primary, size: 22),
          CommonSpaces.w12,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: context.bodySmall.copyWith(color: context.colors.textHint),
                ),
                CommonSpaces.h2,
                Text(value, style: context.bodyMedium),
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }

  Widget _buildRoundActionButton({required IconData icon, required String label, required VoidCallback onTap}) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(30),
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: context.colors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: context.colors.primary),
          ),
        ),
        CommonSpaces.h8,
        Text(label, style: context.bodySmall.copyWith(color: context.colors.primary)),
      ],
    );
  }

  Widget _buildMediaSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Media, links, and docs', style: context.titleSmall),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SharedMediaPage(
                        conversationId: widget.conversationId,
                        initialMediaList: _mediaList,
                        shouldFetch: false,
                      ),
                    ),
                  );
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'See all',
                      style: TextStyle(
                        color: context.colors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.arrow_forward_ios_rounded,
                        size: 13, color: context.colors.primary),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (_isLoadingMedia)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_mediaList.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.photo_library_outlined,
                      size: 44, color: context.colors.textHint.withValues(alpha: 0.4)),
                  const SizedBox(height: 8),
                  Text(
                    'No shared media yet',
                    style: context.bodyMedium.copyWith(color: context.colors.textHint),
                  ),
                ],
              ),
            ),
          )
        else
          _buildMediaPreviewGrid(context),
      ],
    );
  }

  Widget _buildMediaPreviewGrid(BuildContext context) {
    // Prefer image media for the preview; fall back to all media
    final imageMedia = _mediaList
        .where((m) =>
            m.mediaType.toUpperCase().contains('IMAGE') ||
            m.mediaType.toUpperCase().contains('CHAT_IMAGE') ||
            m.mimeType.toLowerCase().startsWith('image/'))
        .toList();

    // Show up to 6 items in horizontal scroll
    final previewItems =
        (imageMedia.isNotEmpty ? imageMedia : _mediaList).take(6).toList();

    void goToAllMedia() {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SharedMediaPage(
            conversationId: widget.conversationId,
            initialMediaList: _mediaList,
            shouldFetch: false,
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        height: 50,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: previewItems.length,
          itemBuilder: (context, index) {
            final media = previewItems[index];
            final isImage = media.mediaType.toUpperCase().contains('IMAGE') ||
                media.mimeType.toLowerCase().startsWith('image/');

            return GestureDetector(
              onTap: goToAllMedia,
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    width: 50,
                    height: 50,
                    color: context.colors.lightBackground,
                    child: isImage
                        ? Image.network(
                            _resolveUrl(media.url),
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => Icon(
                              Icons.broken_image_rounded,
                              size: 24,
                              color: context.colors.textHint,
                            ),
                          )
                        : Icon(
                            media.mediaType.toUpperCase().contains('VIDEO')
                                ? Icons.videocam_rounded
                                : media.mediaType.toUpperCase().contains('VOICE') ||
                                        media.mediaType.toUpperCase().contains('AUDIO')
                                    ? Icons.mic_rounded
                                    : Icons.insert_drive_file_rounded,
                            color: context.colors.primary,
                            size: 24,
                          ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSettingsSection(
    BuildContext context,
    bool isMuted,
    bool isLocked,
    int? disappearingTimer,
    bool? readReceiptsEnabled,
    bool? typingIndicatorsEnabled,
  ) {
    final globalReadReceipts = getIt<StorageService>().getReadReceiptsEnabled();
    final globalTypingIndicators = getIt<StorageService>().getTypingIndicatorsEnabled();

    return Column(
      children: [
        ListTile(
          leading: Icon(
            isMuted ? Icons.notifications_active_rounded : Icons.notifications_off_rounded,
            color: isMuted ? context.colors.primary : context.colors.textSecondary,
          ),
          title: Text(
            isMuted ? 'Unmute Notifications' : 'Mute Notifications',
            style: context.bodyLarge,
          ),
          subtitle: Text(
            isMuted
                ? 'Tap to turn notifications back on'
                : 'Tap to silence notifications for this chat',
            style: context.bodySmall.copyWith(color: context.colors.textHint),
          ),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isMuted
                  ? context.colors.primary.withValues(alpha: 0.12)
                  : context.colors.textHint.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              isMuted ? 'Muted' : 'Active',
              style: context.bodySmall.copyWith(
                color: isMuted ? context.colors.primary : context.colors.textHint,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          onTap: () => _showMuteConfirmationDialog(context, isMuted),
        ),
        ListTile(
          leading: const Icon(Icons.lock_outline),
          title: const Text('Lock Chat'),
          subtitle: Text(
            isLocked ? 'Locked (Hidden from chats list)' : 'Off',
            style: context.bodySmall.copyWith(color: context.colors.textHint),
          ),
          trailing: Switch(
            value: isLocked,
            onChanged: (val) async {
              final changed = await ChatLockBottomSheet.show(
                context,
                conversationId: widget.conversationId,
                contactName: widget.contactName,
                isCurrentlyLocked: isLocked,
              );
              if (changed == true && context.mounted) {
                context.read<ChatBloc>().add(ToggleLockEvent(isLocked: val));
                if (val) {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                }
              }
            },
          ),
          onTap: () async {
            final changed = await ChatLockBottomSheet.show(
              context,
              conversationId: widget.conversationId,
              contactName: widget.contactName,
              isCurrentlyLocked: isLocked,
            );
            if (changed == true && context.mounted) {
              context.read<ChatBloc>().add(ToggleLockEvent(isLocked: !isLocked));
              if (!isLocked) {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              }
            }
          },
        ),
        ListTile(
          leading: const Icon(CommonIcons.history),
          title: const Text('Disappearing Messages'),
          trailing: Text(
            _getDisappearingText(disappearingTimer),
            style: TextStyle(color: context.colors.textSecondary),
          ),
          onTap: () => _showDisappearingMessagesBottomSheet(context, disappearingTimer),
        ),
        ListTile(
          leading: const Icon(Icons.done_all_rounded),
          title: const Text('Read Receipts'),
          subtitle: Text(
            _getPrivacyOptionSummary(readReceiptsEnabled, globalReadReceipts),
            style: context.bodySmall.copyWith(color: context.colors.textHint),
          ),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: () => _showReadReceiptsBottomSheet(context, readReceiptsEnabled),
        ),
        ListTile(
          leading: const Icon(Icons.keyboard_rounded),
          title: const Text('Typing Indicator'),
          subtitle: Text(
            _getPrivacyOptionSummary(typingIndicatorsEnabled, globalTypingIndicators),
            style: context.bodySmall.copyWith(color: context.colors.textHint),
          ),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: () => _showTypingIndicatorsBottomSheet(context, typingIndicatorsEnabled),
        ),
      ],
    );
  }

  String _getPrivacyOptionSummary(bool? setting, bool globalSetting) {
    if (setting == null) {
      return 'Default (${globalSetting ? "On" : "Off"})';
    }
    return setting ? 'Always On' : 'Off';
  }

  Widget _buildPrivacyChoiceTile({
    required BuildContext context,
    required String title,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final isDark = context.colors.isDark;
    final primaryColor = isDark ? const Color(0xFF00FF87) : const Color(0xFF00873C);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isSelected
            ? (isDark ? const Color(0xFF00FF87).withValues(alpha: 0.12) : const Color(0xFFE8F5E9))
            : (isDark ? context.colors.cardBackground : Colors.white),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? primaryColor : context.colors.border.withValues(alpha: 0.3),
          width: isSelected ? 1.5 : 1.0,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 15.5,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            color: isSelected ? primaryColor : context.colors.textPrimary,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 12.5,
            color: isSelected
                ? (isDark ? Colors.white70 : const Color(0xFF027A48))
                : (isDark ? Colors.white54 : const Color(0xFF6B7280)),
          ),
        ),
        trailing: isSelected
            ? Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: primaryColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_rounded,
                  size: 16,
                  color: isDark ? Colors.black : Colors.white,
                ),
              )
            : null,
        onTap: onTap,
      ),
    );
  }

  void _showReadReceiptsBottomSheet(BuildContext context, bool? currentSetting) {
    final globalSetting = getIt<StorageService>().getReadReceiptsEnabled();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetCtx) {
        return Material(
          color: sheetCtx.colors.scaffoldBackground,
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
                        color: sheetCtx.colors.textHint.withValues(alpha: 0.3),
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
                        child: const Icon(Icons.done_all_rounded, color: Color(0xFF00873C), size: 20),
                      ),
                      CommonSpaces.w12,
                      Text(
                        'Read Receipts',
                        style: sheetCtx.titleLarge.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  CommonSpaces.h16,
                  Text(
                    'Control whether ${widget.contactName} can see when you have read their messages.',
                    style: sheetCtx.bodyMedium.copyWith(color: sheetCtx.colors.textSecondary),
                  ),
                  CommonSpaces.h24,
                  _buildPrivacyChoiceTile(
                    context: sheetCtx,
                    title: 'Default (App setting)',
                    subtitle: 'Follows your global setting (${globalSetting ? "Currently On" : "Currently Off"})',
                    isSelected: currentSetting == null,
                    onTap: () {
                      Navigator.pop(sheetCtx);
                      context.read<ChatBloc>().add(
                        UpdateChatPrivacyEvent(
                          conversationId: widget.conversationId,
                          clearReadReceipts: true,
                        ),
                      );
                      context.showInfoNotification('Read receipts set to Default (App setting)');
                    },
                  ),
                  _buildPrivacyChoiceTile(
                    context: sheetCtx,
                    title: 'Always On',
                    subtitle: 'Show read receipts for this contact even if turned off globally',
                    isSelected: currentSetting == true,
                    onTap: () {
                      Navigator.pop(sheetCtx);
                      context.read<ChatBloc>().add(
                        UpdateChatPrivacyEvent(
                          conversationId: widget.conversationId,
                          readReceiptsEnabled: true,
                        ),
                      );
                      context.showInfoNotification('Read receipts enabled for ${widget.contactName}');
                    },
                  ),
                  _buildPrivacyChoiceTile(
                    context: sheetCtx,
                    title: 'Off',
                    subtitle: 'Never show read receipts for this contact',
                    isSelected: currentSetting == false,
                    onTap: () {
                      Navigator.pop(sheetCtx);
                      context.read<ChatBloc>().add(
                        UpdateChatPrivacyEvent(
                          conversationId: widget.conversationId,
                          readReceiptsEnabled: false,
                        ),
                      );
                      context.showInfoNotification('Read receipts disabled for ${widget.contactName}');
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
  }

  void _showTypingIndicatorsBottomSheet(BuildContext context, bool? currentSetting) {
    final globalSetting = getIt<StorageService>().getTypingIndicatorsEnabled();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetCtx) {
        return Material(
          color: sheetCtx.colors.scaffoldBackground,
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
                        color: sheetCtx.colors.textHint.withValues(alpha: 0.3),
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
                        child: const Icon(Icons.keyboard_rounded, color: Color(0xFF00873C), size: 20),
                      ),
                      CommonSpaces.w12,
                      Text(
                        'Typing Indicator',
                        style: sheetCtx.titleLarge.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  CommonSpaces.h16,
                  Text(
                    'Control whether ${widget.contactName} can see when you are typing.',
                    style: sheetCtx.bodyMedium.copyWith(color: sheetCtx.colors.textSecondary),
                  ),
                  CommonSpaces.h24,
                  _buildPrivacyChoiceTile(
                    context: sheetCtx,
                    title: 'Default (App setting)',
                    subtitle: 'Follows your global setting (${globalSetting ? "Currently On" : "Currently Off"})',
                    isSelected: currentSetting == null,
                    onTap: () {
                      Navigator.pop(sheetCtx);
                      context.read<ChatBloc>().add(
                        UpdateChatPrivacyEvent(
                          conversationId: widget.conversationId,
                          clearTypingIndicators: true,
                        ),
                      );
                      context.showInfoNotification('Typing indicator set to Default (App setting)');
                    },
                  ),
                  _buildPrivacyChoiceTile(
                    context: sheetCtx,
                    title: 'Always On',
                    subtitle: 'Show typing indicator for this contact even if turned off globally',
                    isSelected: currentSetting == true,
                    onTap: () {
                      Navigator.pop(sheetCtx);
                      context.read<ChatBloc>().add(
                        UpdateChatPrivacyEvent(
                          conversationId: widget.conversationId,
                          typingIndicatorsEnabled: true,
                        ),
                      );
                      context.showInfoNotification('Typing indicator enabled for ${widget.contactName}');
                    },
                  ),
                  _buildPrivacyChoiceTile(
                    context: sheetCtx,
                    title: 'Off',
                    subtitle: 'Never show typing indicator for this contact',
                    isSelected: currentSetting == false,
                    onTap: () {
                      Navigator.pop(sheetCtx);
                      context.read<ChatBloc>().add(
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

  void _showMuteConfirmationDialog(BuildContext context, bool isMuted) {
    final action = isMuted ? 'Unmute' : 'Mute';
    final icon = isMuted ? Icons.notifications_active_rounded : Icons.notifications_off_rounded;

    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(ctx).colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(icon, color: Theme.of(ctx).colorScheme.primary, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '$action Notifications?',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Text(
          isMuted
              ? 'You will start receiving notifications from ${widget.contactName} again.'
              : 'You will no longer receive notifications from ${widget.contactName}.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              Navigator.pop(ctx, true);
              context.read<ChatBloc>().add(ToggleMuteEvent(isMuted: !isMuted));
            },
            child: Text(action),
          ),
        ],
      ),
    );
  }

  Widget _buildDestructiveSection(BuildContext context) {
    return Column(
      children: [
        ListTile(
          leading: Icon(CommonIcons.block, color: _isBlocked ? Colors.green : Colors.red),
          title: Text(_isBlocked ? 'Unblock ${widget.contactName}' : 'Block ${widget.contactName}', style: TextStyle(color: _isBlocked ? Colors.green : Colors.red)),
          onTap: () {
            if (_isBlocked) {
              _unblockUser();
            } else {
              _showBlockConfirmationDialog(context);
            }
          },
        ),
        ListTile(
          leading: const Icon(CommonIcons.report, color: Colors.red),
          title: Text('Report ${widget.contactName}', style: const TextStyle(color: Colors.red)),
          onTap: () => _showReportConfirmationDialog(context),
        ),
        ListTile(
          leading: const Icon(Icons.cleaning_services_rounded, color: Colors.red),
          title: const Text('Clear Chat', style: TextStyle(color: Colors.red)),
          onTap: () => _showClearChatBottomSheet(context),
        ),
        ListTile(
          leading: const Icon(CommonIcons.deleteOutline, color: Colors.red),
          title: const Text('Delete Chat', style: TextStyle(color: Colors.red)),
          onTap: () => _showDeleteConfirmationDialog(context),
        ),
      ],
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
      context.read<ChatBloc>().add(SetDisappearingTimerEvent(seconds: encoded));
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
        context.read<ChatBloc>().add(SetDisappearingTimerEvent(seconds: finalSeconds));
        context.showInfoNotification('Disappearing messages set to $label');
      },
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
                        context.read<ChatBloc>().add(ClearChatEvent(
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
                        context.read<ChatBloc>().add(ClearChatEvent(
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

  void _showDeleteConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.colors.scaffoldBackground,
        title: Text('Delete Chat?', style: context.titleMedium),
        content: Text(
          'Are you sure you want to delete this chat? This action cannot be undone.',
          style: context.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: context.colors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              context.read<ChatBloc>().add(const CloseChatEvent());
              Navigator.pop(context); // Exit Profile Page
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showBlockConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.colors.scaffoldBackground,
        title: Text('Block ${widget.contactName}?', style: context.titleMedium),
        content: Text(
          'Blocked contacts will no longer be able to call you or send you messages.',
          style: context.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: context.colors.textSecondary)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await _blockUser();
              if (success) {
                setState(() {
                  _isBlocked = true;
                });
                if (mounted) {
                  context.showSuccessNotification('${widget.contactName} blocked');
                }
              }
            },
            child: const Text('Block', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showReportConfirmationDialog(BuildContext context) {
    bool blockUser = true;
    String selectedReason = 'Spam';
    final reasons = [
      'Spam',
      'Harassment or hate speech',
      'Inappropriate or adult content',
      'Scam or fraud',
      'Fake account / impersonation',
      'Other',
    ];
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final isDark = context.colors.isDark;
          return Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            decoration: BoxDecoration(
              color: context.colors.scaffoldBackground,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: context.colors.textSecondary.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  CommonSpaces.h16,
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.report_problem_rounded, color: Colors.red, size: 22),
                      ),
                      CommonSpaces.w12,
                      Expanded(
                        child: Text(
                          'Report ${widget.contactName}',
                          style: context.titleMedium.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  CommonSpaces.h12,
                  Text(
                    'The last 5 messages from this conversation will be securely sent to S-CHAT Admin for verification. The user will not be notified.',
                    style: context.bodyMedium.copyWith(color: context.colors.textSecondary, height: 1.3),
                  ),
                  CommonSpaces.h16,
                  Text(
                    'Why are you reporting this contact?',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: context.colors.textPrimary,
                    ),
                  ),
                  CommonSpaces.h8,
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: reasons.map((reason) {
                      final isSelected = selectedReason == reason;
                      return ChoiceChip(
                        label: Text(reason),
                        selected: isSelected,
                        selectedColor: isDark ? const Color(0xFF1E3A2B) : const Color(0xFFD1FADF),
                        labelStyle: TextStyle(
                          fontSize: 12,
                          color: isSelected
                              ? (isDark ? const Color(0xFF00FF87) : const Color(0xFF00873C))
                              : context.colors.textSecondary,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        ),
                        onSelected: (selected) {
                          if (selected) {
                            setModalState(() => selectedReason = reason);
                          }
                        },
                      );
                    }).toList(),
                  ),
                  CommonSpaces.h12,
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    title: Text(
                      'Block ${widget.contactName} and clear chat history',
                      style: TextStyle(fontSize: 13, color: context.colors.textPrimary),
                    ),
                    value: blockUser,
                    activeColor: Colors.red,
                    onChanged: (val) {
                      setModalState(() => blockUser = val ?? false);
                    },
                  ),
                  CommonSpaces.h16,
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: isSubmitting ? null : () => Navigator.pop(ctx),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text('Cancel', style: TextStyle(color: context.colors.textSecondary)),
                        ),
                      ),
                      CommonSpaces.w12,
                      Expanded(
                        child: ElevatedButton(
                          onPressed: isSubmitting
                              ? null
                              : () async {
                                  setModalState(() => isSubmitting = true);
                                  await _submitReport(
                                    reason: selectedReason,
                                    shouldBlock: blockUser,
                                  );
                                  if (ctx.mounted) {
                                    Navigator.pop(ctx);
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: isSubmitting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Text('Submit Report', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _submitReport({required String reason, required bool shouldBlock}) async {
    try {
      final repo = getIt<ChatRepository>();
      List<MessageModel> recentMsgs = [];
      try {
        recentMsgs = await repo.getMessages(widget.conversationId, limit: 5);
      } catch (_) {}

      final formattedMsgs = recentMsgs.map((m) => {
        'id': m.id,
        'sender_id': m.senderId,
        'sender_name': m.senderName ?? '',
        'content': m.content,
        'message_type': m.mediaType ?? (m.messageType.isNotEmpty ? m.messageType : 'text'),
        'media_url': m.mediaUrl ?? '',
        'created_at': m.createdAt,
        'is_deleted': m.isDeleted,
      }).toList();

      final targetId = widget.recipientId ?? _recipientUser?.id ?? '';
      await repo.reportConversation(
        conversationId: widget.conversationId,
        reportedUserId: targetId,
        reportedUserName: widget.contactName,
        reason: reason,
        description: 'Reported by user from Contact Profile',
        recentMessages: formattedMsgs,
        blockUser: shouldBlock,
      );

      if (shouldBlock && targetId.isNotEmpty) {
        await _blockUser();
      }

      if (mounted) {
        context.showSuccessNotification('Report submitted. Thank you for keeping S-CHAT safe.');
      }
    } catch (e) {
      if (mounted) {
        context.showSuccessNotification('Report submitted to S-CHAT Admin');
      }
    }
  }

  Future<String> _resolveDirectConversationId() async {
    final targetRecipientId = widget.recipientId ?? _recipientUser?.id ?? '';
    if (widget.isFromGroup || targetRecipientId.isNotEmpty) {
      if (targetRecipientId.isNotEmpty) {
        try {
          final result = await getIt<DashboardRepository>().startDirectChat(targetRecipientId);
          if (result is Success<ChatModel>) {
            return result.data.id;
          }
        } catch (e) {
          debugPrint('ContactProfilePage: Error resolving direct conversationId: $e');
        }
      }
    }
    return widget.conversationId;
  }

  void _openDirectMessage() async {
    final targetRecipientId = widget.recipientId ?? _recipientUser?.id ?? '';
    if (widget.isFromGroup && targetRecipientId.isNotEmpty) {
      try {
        final result = await getIt<DashboardRepository>().startDirectChat(targetRecipientId);
        if (result is Success<ChatModel> && mounted) {
          final chat = result.data;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChatPage(
                conversationId: chat.id,
                contactName: widget.contactName,
                contactColor: widget.contactColor,
                isOnline: widget.isOnline,
                recipientId: targetRecipientId,
                profilePictureUrl: widget.profilePictureUrl ?? _recipientUser?.profilePictureUrl,
                initialThemeColor: chat.themeColor,
                initialDisappearingTimer: chat.disappearingTimer,
                isBlocked: _isBlocked || (_recipientUser?.isBlocked ?? false) || chat.recipient.isBlocked,
                isBlockedByMe: _isBlocked || (_recipientUser?.isBlockedByMe ?? false) || chat.recipient.isBlockedByMe,
                isBlockedByOther: _recipientUser?.isBlockedByOther ?? chat.recipient.isBlockedByOther,
              ),
            ),
          );
          return;
        }
      } catch (e) {
        debugPrint('ContactProfilePage: Error opening direct chat: $e');
      }
    }
    if (!mounted) return;
    Navigator.pop(context);
  }

  void _startAudioCall() async {
    final bool isUserBlocked = _isBlocked || (_recipientUser?.isBlocked ?? false);
    if (isUserBlocked) {
      context.showErrorNotification('Cannot make calls to this contact.');
      return;
    }
    final hasPermission = await PermissionHelper.checkCallPermissions(isVideo: false);
    if (!mounted || !hasPermission) return;
    final targetRecipientId = widget.recipientId ?? _recipientUser?.id ?? '';
    final directConversationId = await _resolveDirectConversationId();
    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: getIt<CallWebRtcBloc>(),
          child: AudioCallPage(
            conversationId: directConversationId,
            contactName: widget.contactName,
            contactColor: widget.contactColor,
            recipientId: targetRecipientId,
            isOutgoing: true,
            isGroup: false,
            extraParticipants: const [],
            profilePictureUrl: widget.profilePictureUrl ?? _recipientUser?.profilePictureUrl,
            myProfilePictureUrl: getIt<StorageService>().getProfilePic(),
          ),
        ),
      ),
    );
  }

  void _startVideoCall() async {
    final bool isUserBlocked = _isBlocked || (_recipientUser?.isBlocked ?? false);
    if (isUserBlocked) {
      context.showErrorNotification('Cannot make calls to this contact.');
      return;
    }
    final hasPermission = await PermissionHelper.checkCallPermissions(isVideo: true);
    if (!mounted || !hasPermission) return;
    final targetRecipientId = widget.recipientId ?? _recipientUser?.id ?? '';
    final directConversationId = await _resolveDirectConversationId();
    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: getIt<CallWebRtcBloc>(),
          child: VideoCallPage(
            conversationId: directConversationId,
            contactName: widget.contactName,
            contactColor: widget.contactColor,
            recipientId: targetRecipientId,
            isOutgoing: true,
            isGroup: false,
            extraParticipants: const [],
            profilePictureUrl: widget.profilePictureUrl ?? _recipientUser?.profilePictureUrl,
            myProfilePictureUrl: getIt<StorageService>().getProfilePic(),
          ),
        ),
      ),
    );
  }
}
