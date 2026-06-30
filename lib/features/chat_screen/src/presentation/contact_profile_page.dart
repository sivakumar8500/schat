import 'package:schat/utils/common_fontstyles.dart';

import 'package:schat/utils/common_sizes.dart';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:schat/utils/common_colors.dart';
import 'package:schat/utils/common_icons.dart';
import 'package:schat/features/call_screen/call_screen.dart';
import 'package:schat/features/chat_screen/src/presentation/bloc/chat_bloc.dart';
import 'package:schat/features/chat_screen/src/presentation/bloc/chat_event.dart';
import 'package:schat/features/chat_screen/src/presentation/bloc/chat_state.dart';
import 'package:schat/injection.dart';
import 'package:schat/features/chat_screen/src/domain/repositories/chat_repository.dart';
import 'package:schat/features/chat_screen/src/domain/models/chat_media_model.dart';
import 'package:schat/features/chat_screen/src/presentation/shared_media_page.dart';
import 'package:schat/utils/permission_helper.dart';
import 'package:schat/utils/common_notifications.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:schat/utils/common_endpoints.dart';

import 'package:schat/features/chat_socket_screen/src/domain/chat_socket_repository.dart';
import 'package:schat/features/dashboard_screen/src/domain/repositories/dashboard_repository.dart';
import 'package:schat/features/chat_screen/chat_screen.dart';

class ContactProfilePage extends StatefulWidget {
  final String conversationId;
  final String contactName;
  final Color contactColor;
  final bool isOnline;
  final String? recipientId;
  final bool isFromGroup;

  const ContactProfilePage({
    super.key,
    required this.conversationId,
    required this.contactName,
    required this.contactColor,
    required this.isOnline,
    this.recipientId,
    this.isFromGroup = false,
  });

  @override
  State<ContactProfilePage> createState() => _ContactProfilePageState();
}

class _ContactProfilePageState extends State<ContactProfilePage> {
  List<ChatMediaModel> _mediaList = [];
  bool _isLoadingMedia = true;

  @override
  void initState() {
    super.initState();
    _fetchSharedMedia();
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
      debugPrint('Error loading shared media: $e');
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

  String _getThumbnailOrUrl(ChatMediaModel media) {
    if (media.thumbnails.isNotEmpty) {
      try {
        final thumb = media.thumbnails.first;
        if (thumb is Map && thumb.containsKey('url')) {
          return _resolveUrl(thumb['url'].toString());
        }
      } catch (_) {}
    }
    return _resolveUrl(media.url);
  }

  Future<void> _launchMedia(ChatMediaModel media) async {
    final rawUrl = media.url;
    final resolved = _resolveUrl(rawUrl);
    final uri = Uri.parse(resolved);
    try {
      final canLaunch = await canLaunchUrl(uri);
      if (!mounted) return;
      if (canLaunch) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        context.showErrorNotification('Could not open file URL');
      }
    } catch (e) {
      if (!mounted) return;
      context.showErrorNotification('Error opening file: $e');
    }
  }

  Widget _buildMediaCell(ChatMediaModel media, Color innerCardColor) {
    final isImage = media.mediaType == 'CHAT_IMAGE' || media.mimeType.startsWith('image/');
    final isVideo = media.mediaType == 'CHAT_VIDEO' || media.mimeType.startsWith('video/');
    final isAudio = media.mediaType == 'VOICE_NOTE' || media.mimeType.startsWith('audio/');
    
    Widget content;
    if (isImage) {
      content = Image.network(
        _getThumbnailOrUrl(media),
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (context, error, stackTrace) => Center(
          child: Icon(CommonIcons.brokenImage, color: context.colors.textHint, size: 24),
        ),
      );
    } else if (isVideo) {
      content = Container(
        color: context.colors.lightBackground,
        child: Center(
          child: Icon(CommonIcons.playCircle, color: context.colors.primary, size: 28),
        ),
      );
    } else if (isAudio) {
      content = Container(
        color: context.colors.lightBackground,
        child: Center(
          child: Icon(CommonIcons.audio, color: context.colors.primary, size: 28),
        ),
      );
    } else {
      content = Container(
        color: context.colors.lightBackground,
        child: Center(
          child: Icon(CommonIcons.document, color: context.colors.primary, size: 28),
        ),
      );
    }

    return Tooltip(
      message: media.filename,
      child: GestureDetector(
        onTap: () => _launchMedia(media),
        child: Container(
          width: (MediaQuery.of(context).size.width - 48 - 36) / 4,
          height: (MediaQuery.of(context).size.width - 48 - 36) / 4,
          decoration: BoxDecoration(
            color: innerCardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: context.colors.border.withValues(alpha: 0.5),
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(11),
            child: content,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cardBgColor = context.colors.cardBackground;
    final innerCardColor = context.colors.isDark ? context.colors.pureWhite.withValues(alpha: 0.05) : context.colors.pureWhite;

    return BlocBuilder<ChatBloc, ChatState>(
      builder: (context, state) {
        final isMuted = state is ChatLoaded ? state.isMuted : false;
        final isLocked = state is ChatLoaded ? state.isLocked : false;

        return Scaffold(
      backgroundColor: context.colors.scaffoldBackground,
      body: Column(
        children: [
          // Top Area: Back Button, Avatar, Name, Status Pill, Action Row
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Back button
                  Align(
                    alignment: Alignment.centerLeft,
                    child: InkWell(
                      onTap: () => Navigator.pop(context),
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: Icon(
                          CommonIcons.arrowBack,
                          color: context.colors.textPrimary,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: CommonSizes.p12),

                  // Avatar
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: widget.contactColor.withValues(alpha: 0.15),
                        child: Text(
                          widget.contactName.substring(0, 1),
                          style: context.h1.copyWith(
                            fontSize: 36,
                            color: widget.contactColor,
                          ),
                        ),
                      ),
                      if (widget.isOnline)
                        Positioned(
                          right: 4,
                          bottom: 4,
                          child: Container(
                            width: 18,
                            height: 18,
                            decoration: BoxDecoration(
                              color: context.colors.primary,
                              shape: BoxShape.circle,
                              border: Border.all(color: context.colors.scaffoldBackground, width: 3),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: CommonSizes.p16),

                  // Contact Name
                  Text(
                    widget.contactName,
                    style: context.h3,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: CommonSizes.p4),

                  // Status Quote
                  Text(
                    "Pursuing Goals 🤘",
                    style: context.bodyLarge.copyWith(
                      color: context.colors.textSecondary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: CommonSizes.p12),

                  // Online status badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: widget.isOnline
                          ? context.colors.primary.withValues(alpha: 0.12)
                          : context.colors.textHint.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      widget.isOnline ? 'Online' : 'Offline',
                      style: context.bodyMedium.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: widget.isOnline ? context.colors.primary : context.colors.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(height: CommonSizes.p24),

                  // Action Row (Circular buttons)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Call button
                      _buildRoundActionButton(
                        icon: CommonIcons.phone,
                        onTap: () async {
                          final hasPermission = await PermissionHelper.checkCallPermissions(isVideo: false);
                          if (!hasPermission) {
                            if (mounted) {
                              context.showErrorNotification('Microphone permission is required for audio calls');
                            }
                            return;
                          }
                          CallWebRtcBloc callBloc = getIt<CallWebRtcBloc>();
                          final isAlreadyInCall = callBloc.isCallActiveFor(widget.conversationId);
                          
                          if (!mounted) return;
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => BlocProvider.value(
                                value: callBloc,
                                child: AudioCallPage(
                                  conversationId: widget.conversationId,
                                  contactName: widget.contactName,
                                  contactColor: widget.contactColor,
                                  recipientId: widget.recipientId ?? '',
                                  isOutgoing: !isAlreadyInCall,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: CommonSizes.p16),

                      // Video call button
                      _buildRoundActionButton(
                        icon: CommonIcons.videocam,
                        onTap: () async {
                          final hasPermission = await PermissionHelper.checkCallPermissions(isVideo: true);
                          if (!hasPermission) {
                            if (mounted) {
                              context.showErrorNotification('Camera and Microphone permissions are required for video calls');
                            }
                            return;
                          }
                          CallWebRtcBloc callBloc = getIt<CallWebRtcBloc>();
                          final isAlreadyInCall = callBloc.isCallActiveFor(widget.conversationId);

                          if (!mounted) return;
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => BlocProvider.value(
                                value: callBloc,
                                child: VideoCallPage(
                                  conversationId: widget.conversationId,
                                  contactName: widget.contactName,
                                  contactColor: widget.contactColor,
                                  recipientId: widget.recipientId ?? '',
                                  isOutgoing: !isAlreadyInCall,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: CommonSizes.p16),

                      // Chat button (Back to chat)
                      _buildRoundActionButton(
                        icon: CommonIcons.chatBubble,
                        onTap: () {
                          if (widget.isFromGroup && widget.recipientId != null) {
                            _startDirectChat(context, widget.recipientId!);
                          } else {
                            Navigator.pop(context);
                          }
                        },
                      ),
                      const SizedBox(width: CommonSizes.p16),

                      // More options button
                      _buildRoundActionButton(
                        icon: CommonIcons.moreHoriz,
                        onTap: () {},
                      ),
                    ],
                  ),
                  const SizedBox(height: CommonSizes.p12),
                ],
              ),
            ),
          ),

          // Bottom card area
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: cardBgColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(40),
                ),
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(40),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 30.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Shared Media Section
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Shared media',
                            style: context.titleSmall,
                          ),
                          GestureDetector(
                            onTap: () {
                              if (_isLoadingMedia) return;
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => SharedMediaPage(
                                    conversationId: widget.conversationId,
                                    initialMediaList: _mediaList,
                                  ),
                                ),
                              );
                            },
                            child: Text(
                              'View all',
                              style: context.bodyLarge.copyWith(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: context.colors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: CommonSizes.p16),

                      if (_isLoadingMedia)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: List.generate(4, (index) {
                            return Container(
                              width: (MediaQuery.of(context).size.width - 48 - 36) / 4,
                              height: (MediaQuery.of(context).size.width - 48 - 36) / 4,
                              decoration: BoxDecoration(
                                color: innerCardColor,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: context.colors.border.withValues(alpha: 0.5),
                                ),
                              ),
                              child: const Center(
                                child: SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              ),
                            );
                          }),
                        )
                      else if (_mediaList.isEmpty)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          alignment: Alignment.center,
                          child: Text(
                            'No shared media',
                            style: context.bodyMedium.copyWith(
                              color: context.colors.textHint,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        )
                      else
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: List.generate(4, (index) {
                            if (index < _mediaList.length) {
                              return _buildMediaCell(_mediaList[index], innerCardColor);
                            } else {
                              return Container(
                                width: (MediaQuery.of(context).size.width - 48 - 36) / 4,
                                height: (MediaQuery.of(context).size.width - 48 - 36) / 4,
                                decoration: BoxDecoration(
                                  color: innerCardColor.withValues(alpha: 0.3),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: context.colors.border.withValues(alpha: 0.2),
                                  ),
                                ),
                              );
                            }
                          }),
                        ),
                      const SizedBox(height: CommonSizes.p24),

                      // Settings Options Card
                      Material(
                        color: innerCardColor,
                        borderRadius: BorderRadius.circular(24),
                        clipBehavior: Clip.antiAlias,
                        child: Column(
                          children: [
                            // Mute notifications
                            _buildSettingsTile(
                              icon: CommonIcons.notifications,
                              title: 'Mute notifications',
                              trailing: Switch(
                                value: isMuted,
                                activeThumbColor: context.colors.primary,
                                onChanged: (value) {
                                  context.read<ChatBloc>().add(ToggleMuteEvent(isMuted: value));
                                },
                              ),
                            ),
                            Divider(color: context.colors.border.withValues(alpha: 0.3), height: 1),

                            // Lock Chat
                            _buildSettingsTile(
                              icon: CommonIcons.lock,
                              title: 'Lock Chat',
                              trailing: Switch(
                                value: isLocked,
                                activeThumbColor: context.colors.primary,
                                onChanged: (value) {
                                  context.read<ChatBloc>().add(ToggleLockEvent(isLocked: value));
                                },
                              ),
                            ),
                            Divider(color: context.colors.border.withValues(alpha: 0.3), height: 1),

                            // Auto-delete messages
                            _buildSettingsTile(
                              icon: CommonIcons.history,
                              title: 'Auto-delete messages',
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '30s',
                                    style: context.bodyLarge.copyWith(
                                      color: context.colors.textSecondary,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(width: CommonSizes.p4),
                                  Icon(
                                    CommonIcons.arrowForward,
                                    size: 14,
                                    color: context.colors.textHint,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: CommonSizes.p16),

                      // Destructive Block/Report Card
                      Material(
                        color: context.colors.isDark
                            ? context.colors.error.withValues(alpha: 0.05)
                            : context.colors.error.withValues(alpha: 0.05),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                          side: BorderSide(
                            color: context.colors.error.withValues(alpha: 0.1),
                          ),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Column(
                          children: [
                            // Block Contact
                            _buildDestructiveTile(
                              icon: CommonIcons.block,
                              title: 'Block ${widget.contactName}',
                            ),
                            Divider(
                              color: context.colors.error.withValues(alpha: 0.08),
                              height: 1,
                            ),

                            // Report Contact
                            _buildDestructiveTile(
                              icon: CommonIcons.report,
                              title: 'Report the contact',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
      },
    );
  }

  Future<void> _startDirectChat(BuildContext context, String recipientId) async {
    try {
      final repo = getIt<DashboardRepository>();
      final result = await repo.startDirectChat(recipientId);
      
      result.when(
        success: (chat) {
          if (!mounted) return;
          // Navigate to ChatPage for this 1-to-1 conversation
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatPage(
                conversationId: chat.id,
                contactName: widget.contactName,
                contactColor: widget.contactColor,
                isOnline: widget.isOnline,
                recipientId: recipientId,
                isGroup: false,
              ),
            ),
          );
        },
        failure: (error, _) {
          if (mounted) {
            context.showErrorNotification('Failed to start chat: $error');
          }
        },
      );
    } catch (e) {
      if (mounted) {
        context.showErrorNotification('Error: $e');
      }
    }
  }

  Widget _buildRoundActionButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(25),
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: context.colors.primary,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: context.colors.pureWhite,
          size: 24,
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required Widget trailing,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: context.colors.scaffoldBackground,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: context.colors.textPrimary,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: context.titleSmall.copyWith(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: context.colors.textPrimary,
        ),
      ),
      trailing: trailing,
    );
  }

  Widget _buildDestructiveTile({
    required IconData icon,
    required String title,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: context.colors.pureWhite,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: context.colors.error,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: context.titleSmall.copyWith(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: context.colors.error,
        ),
      ),
      onTap: () {},
    );
  }
}
