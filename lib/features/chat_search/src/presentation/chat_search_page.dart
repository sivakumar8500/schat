import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:schat/features/dashboard_screen/src/presentation/bloc/chats_bloc.dart';
import 'package:schat/features/dashboard_screen/src/presentation/bloc/chats_event.dart';
import 'package:schat/features/dashboard_screen/src/presentation/bloc/chats_state.dart';
import 'package:schat/features/dashboard_screen/src/domain/models/chat_model.dart';
import 'package:schat/features/chat_screen/src/presentation/chat_page.dart';
import 'package:schat/utils/common_colors.dart';
import 'package:schat/utils/common_spaces.dart';
import 'package:schat/core/storage/storage_service.dart';
import 'package:schat/injection.dart';

class ChatSearchPage extends StatefulWidget {
  const ChatSearchPage({super.key});

  @override
  State<ChatSearchPage> createState() => _ChatSearchPageState();
}

class _ChatSearchPageState extends State<ChatSearchPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedFilter = 'All';

  final List<Map<String, dynamic>> _filters = [
    {'key': 'All', 'label': 'All', 'icon': Icons.all_inclusive_rounded},
    {'key': 'Unread', 'label': 'Unread', 'icon': Icons.mark_chat_unread_outlined},
    {'key': 'Groups', 'label': 'Groups', 'icon': Icons.group_outlined},
    {'key': 'Photos', 'label': 'Photos', 'icon': Icons.photo_outlined},
    {'key': 'Videos', 'label': 'Videos', 'icon': Icons.videocam_outlined},
    {'key': 'Links', 'label': 'Links', 'icon': Icons.link_outlined},
    {'key': 'Audio', 'label': 'Audio', 'icon': Icons.audiotrack_outlined},
    {'key': 'Documents', 'label': 'Documents', 'icon': Icons.description_outlined},
  ];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.colors.isDark;

    return Scaffold(
      backgroundColor: context.colors.scaffoldBackground,
      body: SafeArea(
        child: Column(
          children: [
            _buildSearchHeader(isDark),
            _buildFilterChips(isDark),
            const SizedBox(height: 4),
            Expanded(
              child: BlocBuilder<ChatsBloc, ChatsState>(
                builder: (context, state) {
                  return state.maybeWhen(
                    loading: () => const Center(
                      child: CircularProgressIndicator(),
                    ),
                    loaded: (chatList) {
                      final filteredChats = _filterChats(chatList);

                      if (filteredChats.isEmpty) {
                        return _buildEmptyState(isDark);
                      }

                      return _buildChatList(filteredChats, isDark);
                    },
                    error: (msg) => Center(
                      child: Text(
                        'Error: $msg',
                        style: TextStyle(color: context.colors.textSecondary),
                      ),
                    ),
                    orElse: () => const Center(
                      child: CircularProgressIndicator(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchHeader(bool isDark) {
    final searchBgColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : const Color(0xFFEFF4F1);

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 16, 6),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: isDark ? Colors.white70 : const Color(0xFF374151),
              size: 20,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Container(
              height: 46,
              decoration: BoxDecoration(
                color: searchBgColor,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isDark ? Colors.white12 : const Color(0xFFE5E7EB),
                  width: 0.8,
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                children: [
                  Icon(
                    Icons.search_rounded,
                    color: isDark ? const Color(0xFF00FF87) : const Color(0xFF00873C),
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      autofocus: true,
                      style: TextStyle(
                        color: context.colors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Search chats, contacts, messages...',
                        hintStyle: TextStyle(
                          color: isDark ? Colors.white38 : const Color(0xFF9CA3AF),
                          fontSize: 18,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                  if (_searchQuery.isNotEmpty)
                    GestureDetector(
                      onTap: () {
                        _searchController.clear();
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: Icon(
                          Icons.cancel_rounded,
                          color: isDark ? Colors.white38 : const Color(0xFF9CA3AF),
                          size: 18,
                        ),
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

  Widget _buildFilterChips(bool isDark) {
    final activeColor = isDark ? const Color(0xFF00FF87) : const Color(0xFF00873C);
    final activeTextColor = isDark ? Colors.black : Colors.white;

    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        itemCount: _filters.length,
        separatorBuilder: (_, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = _filters[index];
          final isSelected = _selectedFilter == filter['key'];

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedFilter = filter['key'] as String;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
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
                  Icon(
                    filter['icon'] as IconData,
                    size: 15,
                    color: isSelected
                        ? activeTextColor
                        : (isDark ? Colors.white70 : const Color(0xFF4B5563)),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    filter['label'] as String,
                    style: TextStyle(
                      color: isSelected
                          ? activeTextColor
                          : (isDark ? Colors.white70 : const Color(0xFF374151)),
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
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

  static final RegExp _urlRegex = RegExp(
    r'(https?://[^\s]+|www\.[^\s]+|[a-zA-Z0-9.-]+\.(?:com|org|net|in|io|co|ai|dev|app|edu|gov|tech|xyz|me|info|biz|online|site|store|live|cloud|link)\b(?:/[^\s]*)?)',
    caseSensitive: false,
  );

  List<ChatModel> _filterChats(List<ChatModel> chatList) {
    return chatList.where((chat) {
      // 1. Filter by category
      if (_selectedFilter == 'Unread' && chat.unreadCount <= 0) {
        return false;
      }
      if (_selectedFilter == 'Groups' && !chat.isGroup) {
        return false;
      }
      if (_selectedFilter == 'Photos') {
        final type = (chat.lastMessage?.mediaType ?? '').toLowerCase();
        if (type != 'image' && type != 'photo') return false;
      }
      if (_selectedFilter == 'Videos') {
        final type = (chat.lastMessage?.mediaType ?? '').toLowerCase();
        if (type != 'video') return false;
      }
      if (_selectedFilter == 'Links') {
        final content = chat.lastMessage?.content ?? '';
        final mediaUrl = chat.lastMessage?.mediaUrl ?? '';
        final mediaType = (chat.lastMessage?.mediaType ?? '').toLowerCase();

        final hasUrlInContent = _urlRegex.hasMatch(content) ||
            content.toLowerCase().contains('http://') ||
            content.toLowerCase().contains('https://') ||
            content.toLowerCase().contains('www.') ||
            content.toLowerCase().contains('.in') ||
            content.toLowerCase().contains('.com');
        final hasMediaUrl = mediaUrl.isNotEmpty &&
            (mediaUrl.toLowerCase().contains('http') || mediaUrl.toLowerCase().contains('www.'));
        final isLinkType = mediaType == 'link' || mediaType == 'url';

        if (!hasUrlInContent && !hasMediaUrl && !isLinkType) return false;
      }
      if (_selectedFilter == 'Audio') {
        final type = (chat.lastMessage?.mediaType ?? '').toLowerCase();
        if (type != 'audio' && type != 'voice') return false;
      }
      if (_selectedFilter == 'Documents') {
        final type = (chat.lastMessage?.mediaType ?? '').toLowerCase();
        if (type != 'file' && type != 'document' && type != 'pdf') return false;
      }

      // 2. Filter by search query
      if (_searchQuery.isNotEmpty) {
        final name = (chat.isGroup ? (chat.groupName ?? '') : chat.recipient.displayName).toLowerCase();
        final phone = chat.recipient.phoneNumber.toLowerCase();
        final lastMsg = (chat.lastMessage?.content ?? '').toLowerCase();
        final mediaUrl = (chat.lastMessage?.mediaUrl ?? '').toLowerCase();

        final matchesName = name.contains(_searchQuery);
        final matchesPhone = phone.contains(_searchQuery);
        final matchesMsg = lastMsg.contains(_searchQuery);
        final matchesUrl = mediaUrl.contains(_searchQuery);

        return matchesName || matchesPhone || matchesMsg || matchesUrl;
      }

      return true;
    }).toList();
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF3F4F6),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.search_off_rounded,
              size: 36,
              color: isDark ? Colors.white38 : const Color(0xFF9CA3AF),
            ),
          ),
          CommonSpaces.h16,
          Text(
            _searchQuery.isNotEmpty
                ? 'No chats matching "$_searchQuery"'
                : 'No ${_selectedFilter.toLowerCase()} conversations found',
            style: TextStyle(
              color: context.colors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          CommonSpaces.h8,
          Text(
            'Try searching with a different name or keyword',
            style: TextStyle(
              color: isDark ? Colors.white38 : const Color(0xFF6B7280),
              fontSize: 13.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatList(List<ChatModel> visibleChats, bool isDark) {
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(top: 6, bottom: 40),
      itemCount: visibleChats.length,
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
        final chat = visibleChats[index];
        final name = chat.isGroup
            ? (chat.groupName ?? 'Group')
            : chat.recipient.displayName;

        final String message;
        if (chat.isTyping) {
          message = 'typing...';
        } else if (chat.lastMessage != null && chat.lastMessage!.isDeleted) {
          final myId = getIt<StorageService>().getUserId() ?? '';
          final isMe = chat.lastMessage!.senderId == myId;
          message = isMe ? 'You deleted this message' : 'This message was deleted';
        } else {
          message = chat.lastMessage?.content ?? chat.groupDescription ?? 'No messages yet';
        }

        return _buildChatTile(
          chat: chat,
          name: name,
          message: message,
          isDark: isDark,
        );
      },
    );
  }

  Widget _buildChatTile({
    required ChatModel chat,
    required String name,
    required String message,
    required bool isDark,
  }) {
    return InkWell(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatPage(
              conversationId: chat.id,
              contactName: name,
              contactColor: context.colors.primary,
              isOnline: chat.recipient.isOnline,
              profilePictureUrl: chat.recipient.profilePictureUrl,
              recipientId: chat.recipient.id,
              isGroup: chat.isGroup,
              initialThemeColor: chat.themeColor,
              initialDisappearingTimer: chat.disappearingTimer,
            ),
          ),
        );
        if (mounted) {
          context.read<ChatsBloc>().add(const FetchChats());
        }
      },
      child: Container(
        color: Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            _buildAvatar(chat, isDark),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: context.colors.textPrimary,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      if (_urlRegex.hasMatch(message) ||
                          message.toLowerCase().contains('http') ||
                          message.toLowerCase().contains('www.'))
                        Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: Icon(
                            Icons.link_rounded,
                            size: 14,
                            color: isDark ? const Color(0xFF00FF87) : const Color(0xFF00873C),
                          ),
                        ),
                      Expanded(
                        child: Text(
                          message,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: chat.isTyping
                                ? (isDark ? const Color(0xFF00FF87) : const Color(0xFF00873C))
                                : (isDark ? Colors.white54 : const Color(0xFF6B7280)),
                            fontSize: 13.5,
                            fontWeight: chat.isTyping
                                ? FontWeight.w600
                                : (chat.unreadCount > 0 ? FontWeight.w600 : FontWeight.w400),
                            fontStyle: chat.isTyping ? FontStyle.italic : FontStyle.normal,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            _buildChatStatus(chat, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(ChatModel chat, bool isDark) {
    final isGroup = chat.isGroup;
    final primaryColor = isDark ? const Color(0xFF00FF87) : const Color(0xFF00873C);
    final avatarBg = isDark ? const Color(0xFF1E3A2B) : const Color(0xFFD1FADF);
    final avatarTextColor = isDark ? const Color(0xFF00FF87) : const Color(0xFF027A48);

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
              placeholder: (context, url) => Center(
                child: Icon(Icons.group_rounded, color: primaryColor, size: 24),
              ),
              errorWidget: (context, url, error) => Center(
                child: Icon(Icons.group_rounded, color: primaryColor, size: 24),
              ),
            ),
          ),
        );
      }

      return SizedBox(
        width: 48,
        height: 48,
        child: Stack(
          children: [
            Positioned(
              left: 2,
              top: 2,
              child: _buildSmallAvatar(primaryColor.withValues(alpha: 0.25), '👨🏻‍💻'),
            ),
            Positioned(
              right: 2,
              top: 2,
              child: _buildSmallAvatar(context.colors.pinkAccent.withValues(alpha: 0.25), '👩🏼‍💻'),
            ),
            Positioned(
              left: 2,
              bottom: 2,
              child: _buildSmallAvatar(context.colors.orangeAccent.withValues(alpha: 0.25), '👨🏽‍💻'),
            ),
            Positioned(
              right: 2,
              bottom: 2,
              child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: primaryColor,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: context.colors.scaffoldBackground,
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Text(
                    '+3',
                    style: TextStyle(
                      color: isDark ? Colors.black : Colors.white,
                      fontSize: 8.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
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

  Widget _buildSmallAvatar(Color bgColor, String emoji) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
      child: Center(
        child: Text(emoji, style: const TextStyle(fontSize: 11)),
      ),
    );
  }

  Widget _buildChatStatus(ChatModel chat, bool isDark) {
    final timestamp = chat.lastMessage?.createdAt ?? chat.updatedAt;
    String timeStr = '--:--';
    try {
      if (timestamp.isNotEmpty) {
        DateTime time;
        final parsedInt = int.tryParse(timestamp);
        if (parsedInt != null) {
          if (timestamp.length <= 10) {
            time = DateTime.fromMillisecondsSinceEpoch(parsedInt * 1000).toLocal();
          } else {
            time = DateTime.fromMillisecondsSinceEpoch(parsedInt).toLocal();
          }
        } else {
          time = DateTime.parse(timestamp).toLocal();
        }
        timeStr = "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}";
      }
    } catch (e) {
      debugPrint('Error parsing timestamp: $e');
    }

    final primaryColor = isDark ? const Color(0xFF00FF87) : const Color(0xFF00873C);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          timeStr,
          style: TextStyle(
            fontSize: 12,
            color: isDark ? Colors.white54 : const Color(0xFF6B7280),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        if (chat.unreadCount > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: primaryColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              chat.unreadCount.toString(),
              style: TextStyle(
                color: isDark ? Colors.black : Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          )
        else
          const Icon(
            Icons.done_all_rounded,
            color: Color(0xFF12B76A),
            size: 18,
          ),
      ],
    );
  }
}
