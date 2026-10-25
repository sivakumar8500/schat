import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:schat/features/chat_screen/src/presentation/chat_page.dart';
import 'package:schat/features/chat_transfer_screen/src/domain/models/chat_view_user_model.dart';
import 'package:schat/features/chat_transfer_screen/src/presentation/bloc/chat_transfer_bloc.dart';
import 'package:schat/features/chat_transfer_screen/src/presentation/bloc/chat_transfer_event.dart';
import 'package:schat/features/chat_transfer_screen/src/presentation/bloc/chat_transfer_state.dart';
import 'package:schat/features/dashboard_screen/src/domain/models/chat_model.dart';
import 'package:schat/features/dashboard_screen/src/presentation/bloc/chats_bloc.dart';
import 'package:schat/features/dashboard_screen/src/presentation/dashboard_page.dart';
import 'package:schat/utils/common_colors.dart';
import 'package:schat/utils/common_fontstyles.dart';
import 'package:schat/utils/common_notifications.dart';
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
  int _selectedFilterIndex = 0; // 0 = All, 1 = Individual, 2 = Groups
  bool _isRefreshing = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

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
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refreshChats() async {
    if (_isRefreshing) return;
    setState(() => _isRefreshing = true);
    context.read<ChatTransferBloc>().add(
          LoadTargetConversations(
            targetUserId: widget.targetUser.id,
            targetUser: widget.targetUser,
          ),
        );
    await Future.delayed(const Duration(milliseconds: 650));
    if (mounted) {
      setState(() => _isRefreshing = false);
      context.showSuccessNotification('Latest chats updated');
    }
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
                _buildSearchBar(),
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

                      final rawConversations = state.monitoredConversations;
                      final conversations = List<ChatModel>.from(rawConversations)
                        ..sort((a, b) => ChatsBloc.getChatActivityTime(b).compareTo(ChatsBloc.getChatActivityTime(a)));

                      final oneToOneChats = conversations.where((c) => !c.isGroup).toList();
                      final groupChats = conversations.where((c) => c.isGroup).toList();

                      final List<ChatModel> tabFiltered;
                      if (_selectedFilterIndex == 1) {
                        tabFiltered = oneToOneChats;
                      } else if (_selectedFilterIndex == 2) {
                        tabFiltered = groupChats;
                      } else {
                        tabFiltered = conversations;
                      }

                      final displayedConversations = _searchQuery.isEmpty
                          ? tabFiltered
                          : tabFiltered.where((chat) {
                              final name = chat.isGroup
                                  ? (chat.groupName ?? 'Group')
                                  : chat.recipient.displayName;
                              final lastMsg = chat.lastMessage?.content ?? '';
                              return name.toLowerCase().contains(_searchQuery) ||
                                  lastMsg.toLowerCase().contains(_searchQuery);
                            }).toList();

                      return RefreshIndicator(
                        onRefresh: _refreshChats,
                        color: const Color(0xFF00873C),
                        child: Column(
                          children: [
                            if (conversations.isNotEmpty) ...[
                              _buildFilterChips(conversations),
                              _buildSectionHeader(displayedConversations.length),
                            ],
                            Expanded(
                              child: displayedConversations.isEmpty
                                  ? _buildEmptyState(
                                      context,
                                      title: title,
                                      isSearch: _searchQuery.isNotEmpty,
                                    )
                                  : ListView.separated(
                                      physics: const AlwaysScrollableScrollPhysics(),
                                      padding: const EdgeInsets.only(top: 4, bottom: 40),
                                      itemCount: displayedConversations.length,
                                      separatorBuilder: (context, index) => Divider(
                                        height: 1,
                                        thickness: 0.6,
                                        indent: 84,
                                        endIndent: 20,
                                        color: isDark
                                            ? Colors.white.withValues(alpha: 0.08)
                                            : const Color(0xFFF0F0F0),
                                      ),
                                      itemBuilder: (context, index) {
                                        final chat = displayedConversations[index];
                                        return _buildChatTile(chat);
                                      },
                                    ),
                            ),
                          ],
                        ),
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
    final isDark = context.colors.isDark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: context.colors.lightBackground,
              border: Border.all(
                color: context.colors.border.withValues(alpha: 0.3),
              ),
            ),
            child: IconButton(
              padding: EdgeInsets.zero,
              icon: Icon(Icons.arrow_back_rounded, color: context.colors.textPrimary, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          CommonSpaces.w12,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$title’s Chats',
                  style: TextStyle(
                    fontSize: 16.5,
                    fontWeight: FontWeight.w700,
                    color: context.colors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFF00873C),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
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
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark
                  ? const Color(0xFF1E2428)
                  : const Color(0xFFE8F5E9),
            ),
            child: IconButton(
              padding: EdgeInsets.zero,
              icon: _isRefreshing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFF00873C),
                      ),
                    )
                  : const Icon(Icons.refresh_rounded, color: Color(0xFF00873C), size: 19),
              tooltip: 'Pull latest chats',
              onPressed: _isRefreshing ? null : _refreshChats,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    final isDark = context.colors.isDark;
    final searchBgColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : const Color(0xFFEFF4F1);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: searchBgColor,
          borderRadius: BorderRadius.circular(24),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Icon(
              Icons.search_rounded,
              color: isDark ? Colors.white54 : const Color(0xFF4B5563),
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _searchController,
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val.trim().toLowerCase();
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Search conversations',
                  hintStyle: TextStyle(
                    color: isDark ? Colors.white54 : const Color(0xFF6B7280),
                    fontSize: 15,
                    fontWeight: FontWeight.normal,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
                style: TextStyle(
                  color: context.colors.textPrimary,
                  fontSize: 15,
                ),
              ),
            ),
            if (_searchQuery.isNotEmpty)
              GestureDetector(
                onTap: () {
                  _searchController.clear();
                  setState(() {
                    _searchQuery = '';
                  });
                },
                child: Icon(
                  Icons.close_rounded,
                  size: 20,
                  color: isDark ? Colors.white54 : const Color(0xFF6B7280),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChips(List<ChatModel> allConversations) {
    final isDark = context.colors.isDark;
    const activeColor = Color(0xFF00873C);
    const activeTextColor = Colors.white;

    final oneToOneCount = allConversations.where((c) => !c.isGroup).length;
    final groupCount = allConversations.where((c) => c.isGroup).length;

    final filterOptions = [
      ('All', allConversations.length),
      ('Individual', oneToOneCount),
      ('Groups', groupCount),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: List.generate(filterOptions.length, (index) {
            final (label, count) = filterOptions[index];
            final isSelected = _selectedFilterIndex == index;

            return Padding(
              padding: const EdgeInsets.only(right: 10),
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedFilterIndex = index;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? activeColor
                        : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.transparent),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? activeColor
                          : (isDark ? Colors.white24 : const Color(0xFFD1D5DB)),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          color: isSelected
                              ? activeTextColor
                              : (isDark ? Colors.white70 : const Color(0xFF374151)),
                          fontSize: 13.5,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                      if (count > 0) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.white.withValues(alpha: 0.25)
                                : (isDark ? Colors.white.withValues(alpha: 0.1) : const Color(0xFFE5E7EB)),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '$count',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                              color: isSelected
                                  ? Colors.white
                                  : (isDark ? Colors.white70 : const Color(0xFF374151)),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(int totalCount) {
    final isDark = context.colors.isDark;
    const primaryColor = Color(0xFF00873C);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(
                'Conversations',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: context.colors.textPrimary,
                ),
              ),
              if (totalCount > 0) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF00873C).withValues(alpha: 0.18)
                        : const Color(0xFFD1FADF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    totalCount > 99 ? '99+' : totalCount.toString(),
                    style: const TextStyle(
                      color: primaryColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF00873C).withValues(alpha: 0.18)
                  : const Color(0xFFD1FADF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.visibility_rounded, size: 13, color: primaryColor),
                SizedBox(width: 4),
                Text(
                  'Read Only',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: primaryColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(
    BuildContext context, {
    required String title,
    required bool isSearch,
  }) {
    if (isSearch) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  color: Color(0xFFE8F5E9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.search_off_rounded,
                  size: 36,
                  color: Color(0xFF00873C),
                ),
              ),
              CommonSpaces.h16,
              Text(
                'No Results Found',
                style: context.titleMedium.copyWith(fontWeight: FontWeight.bold),
              ),
              CommonSpaces.h8,
              Text(
                'No conversations matching "$_searchQuery"',
                style: TextStyle(color: context.colors.textSecondary, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

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
              child: Icon(
                _selectedFilterIndex == 2
                    ? Icons.group_outlined
                    : Icons.chat_bubble_outline_rounded,
                size: 40,
                color: const Color(0xFF00873C),
              ),
            ),
            CommonSpaces.h16,
            Text(
              _selectedFilterIndex == 1
                  ? 'No Individual Chats'
                  : (_selectedFilterIndex == 2
                      ? 'No Group Chats'
                      : 'No Active Conversations'),
              style: context.titleMedium.copyWith(fontWeight: FontWeight.bold),
            ),
            CommonSpaces.h8,
            Text(
              _selectedFilterIndex == 1
                  ? '$title does not have any 1-on-1 chats yet.'
                  : (_selectedFilterIndex == 2
                      ? '$title is not in any groups yet.'
                      : '$title does not have any active conversations yet.'),
              style: TextStyle(color: context.colors.textSecondary, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _formatMessageDateTime(ChatModel chat) {
    final activityTime = ChatsBloc.getChatActivityTime(chat);
    if (activityTime.year <= 2000) {
      return '';
    }

    final localTime = activityTime.toLocal();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final msgDate = DateTime(localTime.year, localTime.month, localTime.day);

    final hour = localTime.hour > 12
        ? localTime.hour - 12
        : (localTime.hour == 0 ? 12 : localTime.hour);
    final minute = localTime.minute.toString().padLeft(2, '0');
    final period = localTime.hour >= 12 ? 'PM' : 'AM';
    final timeStr = '$hour:$minute $period';

    if (msgDate == today) {
      return 'Today, $timeStr';
    } else if (msgDate == yesterday) {
      return 'Yesterday, $timeStr';
    } else if (now.year == localTime.year) {
      const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${localTime.day} ${months[localTime.month - 1]}, $timeStr';
    } else {
      return '${localTime.day}/${localTime.month}/${localTime.year}, $timeStr';
    }
  }

  Widget _buildChatTile(ChatModel chat) {
    final isDark = context.colors.isDark;
    final chatName = chat.isGroup
        ? (chat.groupName ?? 'Group')
        : chat.recipient.displayName;

    final lastMessageText = chat.lastMessage?.content.isNotEmpty == true
        ? chat.lastMessage!.content
        : (chat.lastMessage?.mediaType != null
            ? '[${chat.lastMessage!.mediaType!.toUpperCase()}]'
            : (chat.groupDescription ?? 'No messages yet'));

    final profilePic = chat.isGroup
        ? chat.recipient.profilePictureUrl
        : chat.recipient.profilePictureUrl;

    final dateTimeStr = _formatMessageDateTime(chat);

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatPage(
              conversationId: chat.id,
              contactName: chatName,
              contactColor: const Color(0xFF00873C),
              isOnline: chat.recipient.isOnline,
              profilePictureUrl: profilePic,
              recipientId: chat.recipient.id,
              isGroup: chat.isGroup,
              isReadOnly: true,
              targetUserId: widget.targetUser.id,
            ),
          ),
        );
      },
      child: Container(
        color: Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            _buildAvatar(chat),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    chatName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15.5,
                      color: context.colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          lastMessageText,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: isDark ? Colors.white60 : const Color(0xFF6B7280),
                            fontSize: 13.5,
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (dateTimeStr.isNotEmpty)
                  Text(
                    dateTimeStr,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white54 : const Color(0xFF6B7280),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF00873C).withValues(alpha: 0.18)
                        : const Color(0xFFD1FADF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'Read Only',
                    style: TextStyle(
                      color: Color(0xFF00873C),
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(ChatModel chat) {
    final isGroup = chat.isGroup;
    final isDark = context.colors.isDark;
    const primaryColor = Color(0xFF00873C);
    final avatarBg = isDark ? const Color(0xFF1E3A2B) : const Color(0xFFD1FADF);
    final avatarTextColor = isDark ? const Color(0xFF00873C) : const Color(0xFF027A48);

    if (isGroup) {
      final groupPic = chat.recipient.profilePictureUrl;
      if (groupPic != null && groupPic.isNotEmpty) {
        return Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: avatarBg,
            shape: BoxShape.circle,
          ),
          child: ClipOval(
            child: CachedNetworkImage(
              imageUrl: groupPic,
              fit: BoxFit.cover,
              useOldImageOnUrlChange: true,
              fadeInDuration: Duration.zero,
              fadeOutDuration: Duration.zero,
              memCacheWidth: 150,
              memCacheHeight: 150,
              placeholder: (context, url) => const Center(
                child: Icon(Icons.group_rounded, color: primaryColor, size: 24),
              ),
              errorWidget: (context, url, error) => const Center(
                child: Icon(Icons.group_rounded, color: primaryColor, size: 24),
              ),
            ),
          ),
        );
      }

      return Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: avatarBg,
          shape: BoxShape.circle,
        ),
        child: const Center(
          child: Icon(Icons.group_rounded, color: primaryColor, size: 24),
        ),
      );
    }

    final imageUrl = chat.recipient.profilePictureUrl;
    final name = chat.recipient.displayName;
    final isOnline = chat.recipient.isOnline;

    Widget buildInitialFallback() {
      return Center(
        child: Text(
          name.isNotEmpty ? name.substring(0, 1).toUpperCase() : '?',
          style: TextStyle(
            color: avatarTextColor,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: avatarBg,
            shape: BoxShape.circle,
          ),
          child: ClipOval(
            child: (imageUrl != null && imageUrl.isNotEmpty)
                ? CachedNetworkImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.cover,
                    useOldImageOnUrlChange: true,
                    fadeInDuration: Duration.zero,
                    fadeOutDuration: Duration.zero,
                    memCacheWidth: 150,
                    memCacheHeight: 150,
                    placeholder: (context, url) => buildInitialFallback(),
                    errorWidget: (context, url, error) => buildInitialFallback(),
                  )
                : buildInitialFallback(),
          ),
        ),
        if (isOnline)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: const Color(0xFF12B76A),
                shape: BoxShape.circle,
                border: Border.all(
                  color: context.colors.scaffoldBackground,
                  width: 2.5,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
