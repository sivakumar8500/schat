import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:schat/features/chat_screen/src/presentation/chat_page.dart';
import 'package:schat/features/chat_transfer_screen/src/domain/models/chat_view_user_model.dart';
import 'package:schat/features/chat_transfer_screen/src/presentation/bloc/chat_transfer_bloc.dart';
import 'package:schat/features/chat_transfer_screen/src/presentation/bloc/chat_transfer_event.dart';
import 'package:schat/features/chat_transfer_screen/src/presentation/bloc/chat_transfer_state.dart';
import 'package:schat/features/dashboard_screen/src/domain/models/chat_model.dart';
import 'package:schat/utils/common_colors.dart';
import 'package:schat/utils/common_fontstyles.dart';
import 'package:schat/utils/common_icons.dart';
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

    return Scaffold(
      backgroundColor: context.colors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: context.colors.scaffoldBackground,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$title’s Chats',
              style: CommonFontStyles.titleMedium(context),
            ),
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: context.colors.success,
                    shape: BoxShape.circle,
                  ),
                ),
                CommonSpaces.w6,
                Text(
                  'Live Monitored Access',
                  style: CommonFontStyles.caption(context).copyWith(
                    color: context.colors.success,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: context.colors.primary),
            onPressed: () {
              context.read<ChatTransferBloc>().add(
                    LoadTargetConversations(
                      targetUserId: widget.targetUser.id,
                      targetUser: widget.targetUser,
                    ),
                  );
            },
          ),
        ],
      ),
      body: BlocBuilder<ChatTransferBloc, ChatTransferState>(
        builder: (context, state) {
          if (state.status == ChatTransferStatus.loading && state.monitoredConversations.isEmpty) {
            return Center(
              child: CircularProgressIndicator(color: context.colors.primary),
            );
          }

          if (state.errorMessage != null && state.monitoredConversations.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.lock_person_outlined, size: 48, color: context.colors.error),
                    CommonSpaces.h16,
                    Text(
                      'Access Error',
                      style: CommonFontStyles.titleMedium(context),
                    ),
                    CommonSpaces.h8,
                    Text(
                      state.errorMessage!,
                      style: CommonFontStyles.bodyMedium(context).copyWith(
                        color: context.colors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    CommonSpaces.h16,
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
                        backgroundColor: context.colors.primary,
                      ),
                      child: const Text('Retry', style: TextStyle(color: Colors.white)),
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
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(CommonIcons.chatBubble, size: 48, color: context.colors.grey),
                    CommonSpaces.h12,
                    Text(
                      'No Active Conversations',
                      style: CommonFontStyles.titleMedium(context),
                    ),
                    CommonSpaces.h6,
                    Text(
                      '$title does not have any active chats yet.',
                      style: CommonFontStyles.bodyMedium(context).copyWith(
                        color: context.colors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: conversations.length,
            separatorBuilder: (_, __) => Divider(
              color: context.colors.border.withValues(alpha: 0.2),
              height: 1,
              indent: 72,
            ),
            itemBuilder: (context, index) {
              final chat = conversations[index];
              return _buildConversationTile(context, chat);
            },
          );
        },
      ),
    );
  }

  Widget _buildConversationTile(BuildContext context, ChatModel chat) {
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

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: CircleAvatar(
        radius: 24,
        backgroundColor: context.colors.primary.withValues(alpha: 0.2),
        backgroundImage: profilePic != null && profilePic.isNotEmpty
            ? NetworkImage(profilePic)
            : null,
        child: profilePic == null || profilePic.isEmpty
            ? (chat.isGroup
                ? const Icon(Icons.group, color: Colors.green)
                : Text(
                    chatName.isNotEmpty ? chatName[0].toUpperCase() : '?',
                    style: CommonFontStyles.titleSmall(context).copyWith(
                      color: context.colors.primary,
                    ),
                  ))
            : null,
      ),
      title: Text(
        chatName,
        style: CommonFontStyles.titleSmall(context),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        lastMessageText,
        style: CommonFontStyles.bodySmall(context).copyWith(
          color: context.colors.textSecondary,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: context.colors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              'Read Only',
              style: CommonFontStyles.caption(context).copyWith(
                color: context.colors.primary,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          CommonSpaces.h4,
          Icon(Icons.chevron_right, size: 16, color: context.colors.grey),
        ],
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatPage(
              conversationId: chat.id,
              contactName: chatName,
              contactColor: context.colors.primary,
              isOnline: false,
              profilePictureUrl: profilePic,
              recipientId: chat.recipient.id ?? '',
              isGroup: chat.isGroup,
            ),
          ),
        );
      },
    );
  }
}
