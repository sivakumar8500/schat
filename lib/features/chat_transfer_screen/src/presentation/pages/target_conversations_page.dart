import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:schat/features/chat_screen/src/presentation/chat_page.dart';
import 'package:schat/features/chat_transfer_screen/src/domain/models/chat_view_user_model.dart';
import 'package:schat/features/chat_transfer_screen/src/presentation/bloc/chat_transfer_bloc.dart';
import 'package:schat/features/chat_transfer_screen/src/presentation/bloc/chat_transfer_event.dart';
import 'package:schat/features/chat_transfer_screen/src/presentation/bloc/chat_transfer_state.dart';
import 'package:schat/features/dashboard_screen/src/domain/models/chat_model.dart';
import 'package:schat/features/dashboard_screen/src/presentation/dashboard_page.dart';
import 'package:schat/utils/common_colors.dart';
import 'package:schat/utils/common_fontstyles.dart';
import 'package:schat/utils/common_spaces.dart';

class TargetConversationsPage extends StatefulWidget {
  final ChatViewUserModel targetUser;

  const TargetConversationsPage({
    super.key,
    required this.targetUser,
  });

  @override
  State<TargetConversationsPage> createState() => _TargetConversationsPageState();
}

class _TargetConversationsPageState extends State<TargetConversationsPage> {
  @override
  void initState() {
    super.initState();
    context.read<ChatTransferBloc>().add(
          LoadTargetConversations(
            targetUserId: widget.targetUser.id,
            targetUser: widget.targetUser,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.targetUser.name.isNotEmpty
        ? widget.targetUser.name
        : (widget.targetUser.username.isNotEmpty ? widget.targetUser.username : 'Monitored User');
    final isDark = context.colors.isDark;

    return Scaffold(
      backgroundColor: context.colors.scaffoldBackground,
      body: Stack(
        children: [
          // Wave canvas matching Home Screen
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: HomeBackgroundWavePainter(isDark: isDark),
              ),
            ),
          ),

          // Main Content
          SafeArea(
            child: Column(
              children: [
                _buildHeader(context, title),
                Expanded(
                  child: BlocBuilder<ChatTransferBloc, ChatTransferState>(
                    builder: (context, state) {
                      if (state.status == ChatTransferStatus.loading && state.monitoredConversations.isEmpty) {
                        return const Center(
                          child: CircularProgressIndicator(color: Color(0xFF00873C)),
                        );
                      }

                      if (state.errorMessage != null && state.monitoredConversations.isEmpty) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 72,
                                  height: 72,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFFFEBEE),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.lock_person_rounded, size: 36, color: Color(0xFFE53935)),
                                ),
                                CommonSpaces.h16,
                                Text(
                                  'Access Error',
                                  style: context.titleMedium.copyWith(fontWeight: FontWeight.bold),
                                ),
                                CommonSpaces.h8,
                                Text(
                                  state.errorMessage!,
                                  style: TextStyle(color: context.colors.textSecondary, fontSize: 13),
                                  textAlign: TextAlign.center,
                                ),
                                CommonSpaces.h20,
                                ElevatedButton(
                                  onPressed: () {
                                    context.read<ChatTransferBloc>().add(
                                          LoadTargetConversations(
                                            targetUserId: widget.targetUser.id,
                                            targetUser: widget.targetUser,
                                          ),
                                        );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF00873C),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                                  ),
                                  child: const Text('Retry'),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      final conversations = state.monitoredConversations;
                      if (conversations.isEmpty) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 80,
                                  height: 80,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFE8F5E9),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.chat_bubble_outline_rounded, size: 40, color: Color(0xFF00873C)),
                                ),
                                CommonSpaces.h16,
                                Text(
                                  'No Active Conversations',
                                  style: context.titleMedium.copyWith(fontWeight: FontWeight.bold),
                                ),
                                CommonSpaces.h8,
                                Text(
                                  '$title does not have any active conversations yet.',
                                  style: TextStyle(color: context.colors.textSecondary, fontSize: 14),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
                        itemCount: conversations.length,
                        itemBuilder: (context, index) {
                          final chat = conversations[index];
                          return _buildConversationCard(context, chat, isDark);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: context.colors.lightBackground,
              border: Border.all(
                color: context.colors.border.withValues(alpha: 0.3),
              ),
            ),
            child: IconButton(
              icon: Icon(Icons.arrow_back_rounded, color: context.colors.textPrimary, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          CommonSpaces.w12,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$title’s Chats',
                  style: context.h2.copyWith(
                    fontWeight: FontWeight.bold,
                    color: context.colors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: Color(0xFF00873C),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    const Text(
                      'Live Monitored Access',
                      style: TextStyle(
                        color: Color(0xFF00873C),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            width: 38,
            height: 38,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFE8F5E9),
            ),
            child: IconButton(
              padding: EdgeInsets.zero,
              icon: const Icon(Icons.refresh_rounded, color: Color(0xFF00873C), size: 20),
              tooltip: 'Refresh',
              onPressed: () {
                context.read<ChatTransferBloc>().add(
                      LoadTargetConversations(
                        targetUserId: widget.targetUser.id,
                        targetUser: widget.targetUser,
                      ),
                    );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConversationCard(BuildContext context, ChatModel chat, bool isDark) {
    final chatName = chat.isGroup
        ? (chat.groupName ?? 'Group Chat')
        : chat.recipient.displayName;

    final lastMessageText = chat.lastMessage?.content.isNotEmpty == true
        ? chat.lastMessage!.content
        : (chat.lastMessage?.mediaType != null
            ? '[${chat.lastMessage!.mediaType!.toUpperCase()}]'
            : 'No messages yet');

    final profilePic = chat.isGroup
        ? chat.recipient.profilePictureUrl
        : chat.recipient.profilePictureUrl;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isDark ? context.colors.cardBackground : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: context.colors.border.withValues(alpha: 0.35),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: const Color(0xFFE8F5E9),
          backgroundImage: profilePic != null && profilePic.isNotEmpty
              ? NetworkImage(profilePic)
              : null,
          child: profilePic == null || profilePic.isEmpty
              ? (chat.isGroup
                  ? const Icon(Icons.group_rounded, color: Color(0xFF00873C), size: 22)
                  : Text(
                      chatName.isNotEmpty ? chatName[0].toUpperCase() : '?',
                      style: const TextStyle(
                        color: Color(0xFF00873C),
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                      ),
                    ))
              : null,
        ),
        title: Text(
          chatName,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
            color: context.colors.textPrimary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          lastMessageText,
          style: TextStyle(
            color: context.colors.textSecondary,
            fontSize: 13,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Read Only',
                style: TextStyle(
                  color: Color(0xFF00873C),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right_rounded, size: 20, color: context.colors.textHint),
          ],
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChatPage(
                conversationId: chat.id,
                contactName: chatName,
                contactColor: const Color(0xFF00873C),
                isOnline: false,
                profilePictureUrl: profilePic,
                recipientId: chat.recipient.id,
                isGroup: chat.isGroup,
                isReadOnly: true,
              ),
            ),
          );
        },
      ),
    );
  }
}
