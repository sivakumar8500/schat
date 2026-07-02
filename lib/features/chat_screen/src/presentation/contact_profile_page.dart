import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
import 'package:schat/features/chat_screen/src/presentation/shared_media_page.dart';
import 'package:schat/features/chat_screen/src/presentation/full_screen_image_page.dart';
import 'package:schat/utils/common_endpoints.dart';
import 'package:schat/utils/common_notifications.dart';

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
              const Divider(height: 32),
              
              // Media Section
              _buildMediaSection(context),
              const Divider(height: 32),

              // Settings Section
              _buildSettingsSection(context, isMuted, isLocked),
              const Divider(height: 32),

              // Destructive Section
              _buildDestructiveSection(context),
              CommonSpaces.h40,
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeaderSection() {
    return Column(
      children: [
        GestureDetector(
          onTap: () {
            if (widget.profilePictureUrl != null && widget.profilePictureUrl!.isNotEmpty) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FullScreenImagePage(
                    imageUrl: widget.profilePictureUrl!,
                  ),
                ),
              );
            }
          },
          child: Hero(
            tag: widget.profilePictureUrl ?? 'profile',
            child: CircleAvatar(
              radius: 60,
              backgroundColor: widget.contactColor.withValues(alpha: 0.1),
              backgroundImage: (widget.profilePictureUrl != null && widget.profilePictureUrl!.isNotEmpty)
                  ? NetworkImage(widget.profilePictureUrl!)
                  : null,
              child: (widget.profilePictureUrl == null || widget.profilePictureUrl!.isEmpty)
                  ? Text(
                      widget.contactName.substring(0, 1),
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
          widget.isOnline ? 'Online' : 'Offline',
          style: context.bodyMedium.copyWith(
            color: widget.isOnline ? context.colors.primary : context.colors.textHint,
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
            _buildRoundActionButton(icon: Icons.message, label: 'Message', onTap: () => Navigator.pop(context)),
          ],
        ),
      ],
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
                      ),
                    ),
                  );
                },
                child: const Text('View All'),
              ),
            ],
          ),
        ),
        if (_isLoadingMedia)
          const Center(child: CircularProgressIndicator())
        else if (_mediaList.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text('No shared media'),
          )
        else
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _mediaList.length,
              itemBuilder: (context, index) {
                final media = _mediaList[index];
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 100,
                      height: 100,
                      color: context.colors.lightBackground,
                      child: Image.network(
                        _resolveUrl(media.url),
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(Icons.image),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildSettingsSection(BuildContext context, bool isMuted, bool isLocked) {
    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.notifications_off_outlined),
          title: const Text('Mute Notifications'),
          trailing: Switch(
            value: isMuted,
            onChanged: (val) => context.read<ChatBloc>().add(ToggleMuteEvent(isMuted: val)),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.lock_outline),
          title: const Text('Lock Chat'),
          trailing: Switch(
            value: isLocked,
            onChanged: (val) => context.read<ChatBloc>().add(ToggleLockEvent(isLocked: val)),
          ),
        ),
        ListTile(
          leading: const Icon(CommonIcons.history),
          title: const Text('Disappearing Messages'),
          trailing: const Text('Off'),
          onTap: () => _showDisappearingMessagesBottomSheet(context),
        ),
      ],
    );
  }

  Widget _buildDestructiveSection(BuildContext context) {
    return Column(
      children: [
        ListTile(
          leading: const Icon(CommonIcons.block, color: Colors.red),
          title: Text('Block ${widget.contactName}', style: const TextStyle(color: Colors.red)),
          onTap: () => _showBlockConfirmationDialog(context),
        ),
        ListTile(
          leading: const Icon(CommonIcons.report, color: Colors.red),
          title: Text('Report ${widget.contactName}', style: const TextStyle(color: Colors.red)),
          onTap: () => _showReportConfirmationDialog(context),
        ),
        ListTile(
          leading: const Icon(CommonIcons.deleteOutline, color: Colors.red),
          title: const Text('Delete Chat', style: TextStyle(color: Colors.red)),
          onTap: () => _showDeleteConfirmationDialog(context),
        ),
      ],
    );
  }

  void _showDisappearingMessagesBottomSheet(BuildContext context) {
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
              _buildDisappearingOption(context, 'Off', 0),
              _buildDisappearingOption(context, '24 hours', 86400),
              _buildDisappearingOption(context, '7 days', 604800),
              _buildDisappearingOption(context, '90 days', 7776000),
              CommonSpaces.h20,
            ],
          ),
        );
      },
    );
  }

  Widget _buildDisappearingOption(BuildContext context, String label, int seconds) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label, style: context.bodyLarge),
      trailing: const Icon(CommonIcons.arrowForward, size: 14),
      onTap: () {
        Navigator.pop(context);
        context.read<ChatBloc>().add(SetDisappearingTimerEvent(seconds: seconds == 0 ? null : seconds));
        context.showInfoNotification('Disappearing messages set to $label');
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
            onPressed: () {
              Navigator.pop(context);
              context.showSuccessNotification('${widget.contactName} blocked');
            },
            child: const Text('Block', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showReportConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.colors.scaffoldBackground,
        title: Text('Report ${widget.contactName}?', style: context.titleMedium),
        content: Text(
          'The last 5 messages from this contact will be forwarded to Schat. This contact will not be notified.',
          style: context.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: context.colors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.showSuccessNotification('Report sent');
            },
            child: const Text('Report', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _startAudioCall() async {
    final hasPermission = await PermissionHelper.checkCallPermissions(isVideo: false);
    if (!mounted || !hasPermission) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: getIt<CallWebRtcBloc>(),
          child: AudioCallPage(
            conversationId: widget.conversationId,
            contactName: widget.contactName,
            contactColor: widget.contactColor,
            recipientId: widget.recipientId ?? '',
            isOutgoing: true,
          ),
        ),
      ),
    );
  }

  void _startVideoCall() async {
    final hasPermission = await PermissionHelper.checkCallPermissions(isVideo: true);
    if (!mounted || !hasPermission) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: getIt<CallWebRtcBloc>(),
          child: VideoCallPage(
            conversationId: widget.conversationId,
            contactName: widget.contactName,
            contactColor: widget.contactColor,
            recipientId: widget.recipientId ?? '',
            isOutgoing: true,
          ),
        ),
      ),
    );
  }
}
