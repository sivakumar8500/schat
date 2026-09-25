import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:schat/core/storage/storage_service.dart';
import 'package:schat/features/dashboard_screen/src/domain/models/chat_model.dart';
import 'package:schat/features/dashboard_screen/src/domain/repositories/dashboard_repository.dart';
import 'package:schat/features/dashboard_screen/src/presentation/bloc/chats_bloc.dart';
import 'package:schat/features/dashboard_screen/src/presentation/bloc/chats_event.dart';
import 'package:schat/features/dashboard_screen/src/presentation/dashboard_page.dart';
import 'package:schat/features/chat_screen/chat_screen.dart';
import 'package:schat/injection.dart';
import 'package:schat/utils/common_colors.dart';
import 'package:schat/utils/common_notifications.dart';

class HiddenChatsPage extends StatefulWidget {
  const HiddenChatsPage({super.key});

  @override
  State<HiddenChatsPage> createState() => _HiddenChatsPageState();
}

class _HiddenChatsPageState extends State<HiddenChatsPage> {
  final TextEditingController _searchController = TextEditingController();
  List<ChatModel> _hiddenChats = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      if (mounted) {
        setState(() {
          _searchQuery = _searchController.text.trim().toLowerCase();
        });
      }
    });
    _fetchHiddenChats();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchHiddenChats() async {
    setState(() => _isLoading = true);
    try {
      final result = await getIt<DashboardRepository>().getHiddenChats();
      result.when(
        success: (chats) {
          if (mounted) {
            setState(() {
              _hiddenChats = chats;
              _isLoading = false;
            });
          }
        },
        failure: (error, _) {
          debugPrint('Failed to load hidden chats: $error');
          if (mounted) {
            setState(() => _isLoading = false);
          }
        },
      );
    } catch (e) {
      debugPrint('Error loading hidden chats: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _unhideChat(ChatModel chat) async {
    try {
      final result = await getIt<DashboardRepository>().unhideChat(chat.id);
      result.when(
        success: (_) {
          if (mounted) {
            context.showSuccessNotification('Chat unhidden');
            // Refresh local list
            _fetchHiddenChats();
            // Refresh global chats list
            context.read<ChatsBloc>().add(const FetchChats());
          }
        },
        failure: (error, _) {
          if (mounted) {
            context.showErrorNotification('Failed to unhide chat: $error');
          }
        },
      );
    } catch (e) {
      debugPrint('Error unhiding chat: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.colors.isDark;
    final primaryColor = isDark ? const Color(0xFF00FF87) : const Color(0xFF00873C);

    final filteredChats = _hiddenChats.where((chat) {
      final name = chat.isGroup
          ? (chat.groupName ?? 'Group')
          : chat.recipient.displayName;
      return name.toLowerCase().contains(_searchQuery);
    }).toList();

    return Scaffold(
      backgroundColor: context.colors.scaffoldBackground,
      body: Stack(
        children: [
          // 1. Flowing Wave Lines Background matching Home Screen (Full Screen)
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: HomeBackgroundWavePainter(isDark: isDark),
              ),
            ),
          ),

          // 2. Main Content in SafeArea
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(primaryColor),
                if (!_isLoading && _hiddenChats.isNotEmpty) _buildSearchBar(),
                Expanded(
                  child: _isLoading
                      ? Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                          ),
                        )
                      : _hiddenChats.isEmpty
                          ? _buildEmptyState(primaryColor)
                          : filteredChats.isEmpty
                              ? _buildEmptySearchResultsState()
                              : RefreshIndicator(
                                  color: primaryColor,
                                  onRefresh: _fetchHiddenChats,
                                  child: _buildChatsList(filteredChats),
                                ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(Color primaryColor) {
    final isDark = context.colors.isDark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 20, 10),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: context.colors.textPrimary,
              size: 20,
            ),
            padding: const EdgeInsets.all(8),
            constraints: const BoxConstraints(),
            style: IconButton.styleFrom(
              backgroundColor: isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : const Color(0xFFEFF4F1),
              shape: const CircleBorder(),
            ),
          ),
          const SizedBox(width: 14),
          Text(
            'Hidden Chats',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: context.colors.textPrimary,
              letterSpacing: -0.4,
            ),
          ),
          if (!_isLoading && _hiddenChats.isNotEmpty) ...[
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF00FF87).withValues(alpha: 0.18)
                    : const Color(0xFFD1FADF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _hiddenChats.length.toString(),
                style: TextStyle(
                  color: primaryColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
          const Spacer(),
          if (!_isLoading && _hiddenChats.isNotEmpty)
            IconButton(
              icon: Icon(Icons.refresh_rounded, color: context.colors.textPrimary, size: 22),
              tooltip: 'Refresh',
              onPressed: _fetchHiddenChats,
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
                style: TextStyle(
                  color: context.colors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.normal,
                ),
                decoration: InputDecoration(
                  hintText: 'Search hidden conversations',
                  hintStyle: TextStyle(
                    color: isDark ? Colors.white54 : const Color(0xFF6B7280),
                    fontSize: 15,
                    fontWeight: FontWeight.normal,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                  isDense: true,
                ),
              ),
            ),
            if (_searchQuery.isNotEmpty)
              GestureDetector(
                onTap: () => _searchController.clear(),
                child: Icon(
                  Icons.close_rounded,
                  color: isDark ? Colors.white54 : const Color(0xFF6B7280),
                  size: 20,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptySearchResultsState() {
    final isDark = context.colors.isDark;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.04)
                    : const Color(0xFFEFF4F1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.search_off_rounded,
                size: 48,
                color: isDark ? Colors.white38 : const Color(0xFF9CA3AF),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No results found',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: context.colors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'No hidden chats match "$_searchQuery"',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white54 : const Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(Color primaryColor) {
    final isDark = context.colors.isDark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF00FF87).withValues(alpha: 0.12)
                    : const Color(0xFFD1FADF),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(
                  Icons.archive_outlined,
                  size: 42,
                  color: primaryColor,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Hidden Chats',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: context.colors.textPrimary,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Conversations you hide from the home screen will safely appear here. You can unhide them anytime.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                height: 1.45,
                color: isDark ? Colors.white60 : const Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatsList(List<ChatModel> filteredChats) {
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
      itemCount: filteredChats.length,
      itemBuilder: (context, index) {
        final chat = filteredChats[index];
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
        );
      },
    );
  }

  Widget _buildChatTile({
    required ChatModel chat,
    required String name,
    required String message,
  }) {
    final isDark = context.colors.isDark;
    final primaryColor = const Color(0xFF00873C);

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
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChatPage(
                  conversationId: chat.id,
                  contactName: name,
                  contactColor: primaryColor,
                  isOnline: chat.recipient.isOnline,
                  profilePictureUrl: chat.recipient.profilePictureUrl,
                  recipientId: chat.recipient.id,
                  isGroup: chat.isGroup,
                  initialThemeColor: chat.themeColor,
                ),
              ),
            );
            _fetchHiddenChats();
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w700,
                          color: context.colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        message,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: chat.isTyping
                              ? const Color(0xFF00873C)
                              : isDark
                                  ? Colors.white60
                                  : context.colors.textSecondary,
                          fontSize: 13,
                          fontWeight: chat.isTyping ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                _buildChatStatus(chat),
                const SizedBox(width: 8),
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: const Icon(
                      Icons.unarchive_rounded,
                      color: Color(0xFF00873C),
                      size: 20,
                    ),
                    tooltip: 'Unhide Chat',
                    onPressed: () => _unhideChat(chat),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(ChatModel chat) {
    final isGroup = chat.isGroup;
    final isDark = context.colors.isDark;
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
              child: _buildSmallAvatar(
                primaryColor.withValues(alpha: 0.4),
                '👨🏻‍💻',
              ),
            ),
            Positioned(
              right: 2,
              top: 2,
              child: _buildSmallAvatar(
                context.colors.pinkAccent.withValues(alpha: 0.4),
                '👩🏼‍💻',
              ),
            ),
            Positioned(
              left: 2,
              bottom: 2,
              child: _buildSmallAvatar(
                context.colors.orangeAccent.withValues(alpha: 0.4),
                '👨🏽‍💻',
              ),
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

  Widget _buildChatStatus(ChatModel chat) {
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

    final isDark = context.colors.isDark;
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
