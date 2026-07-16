import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:schat/core/storage/storage_service.dart';
import 'package:schat/features/dashboard_screen/src/domain/models/chat_model.dart';
import 'package:schat/features/dashboard_screen/src/domain/repositories/dashboard_repository.dart';
import 'package:schat/features/dashboard_screen/src/presentation/bloc/chats_bloc.dart';
import 'package:schat/features/dashboard_screen/src/presentation/bloc/chats_event.dart';
import 'package:schat/features/chat_screen/chat_screen.dart';
import 'package:schat/injection.dart';
import 'package:schat/utils/common_colors.dart';
import 'package:schat/utils/common_fontstyles.dart';
import 'package:schat/utils/common_icons.dart';
import 'package:schat/utils/common_spaces.dart';
import 'package:schat/utils/common_notifications.dart';
import 'package:schat/utils/common_sizes.dart';

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
    final filteredChats = _hiddenChats.where((chat) {
      final name = chat.isGroup
          ? (chat.groupName ?? 'Group')
          : chat.recipient.displayName;
      return name.toLowerCase().contains(_searchQuery);
    }).toList();

    return Scaffold(
      backgroundColor: context.colors.scaffoldBackground,
      appBar: AppBar(
        title: const Text('Hidden Chats'),
        backgroundColor: context.colors.scaffoldBackground,
        elevation: 0,
        foregroundColor: context.colors.textPrimary,
        leading: IconButton(
          icon: Icon(CommonIcons.arrowBack),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _hiddenChats.isEmpty
              ? _buildEmptyState()
              : Column(
                  children: [
                    _buildSearchBar(),
                    Expanded(
                      child: filteredChats.isEmpty
                          ? _buildEmptySearchResultsState()
                          : _buildChatsList(filteredChats),
                    ),
                  ],
                ),
    );
  }

  Widget _buildSearchBar() {
    final searchBgColor = context.colors.isDark 
        ? context.colors.pureWhite.withValues(alpha: 0.1)
        : context.colors.primary.withValues(alpha: 0.05);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: searchBgColor,
          borderRadius: BorderRadius.circular(26),
        ),
        child: Row(
          children: [
            CommonSpaces.w16,
            Icon(
              CommonIcons.search,
              color: context.colors.textHint.withValues(alpha: 0.7),
            ),
            CommonSpaces.w12,
            Expanded(
              child: TextField(
                controller: _searchController,
                style: context.bodyLarge.copyWith(
                  color: context.colors.textPrimary,
                  fontSize: 16,
                ),
                decoration: InputDecoration(
                  hintText: 'Search hidden chats',
                  hintStyle: context.bodyLarge.copyWith(
                    color: context.colors.textHint.withValues(alpha: 0.7),
                    fontSize: 16,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                  isDense: true,
                ),
              ),
            ),
            if (_searchQuery.isNotEmpty) ...[
              IconButton(
                icon: const Icon(Icons.close_rounded),
                color: context.colors.textHint,
                onPressed: () {
                  _searchController.clear();
                },
              ),
              CommonSpaces.w8,
            ] else
              CommonSpaces.w16,
          ],
        ),
      ),
    );
  }

  Widget _buildEmptySearchResultsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 64,
            color: context.colors.textSecondary.withValues(alpha: 0.5),
          ),
          CommonSpaces.h16,
          Text(
            'No results found',
            style: context.titleMedium.copyWith(
              color: context.colors.textSecondary,
              fontWeight: FontWeight.bold,
            ),
          ),
          CommonSpaces.h8,
          Text(
            'No hidden chats match "$_searchQuery"',
            style: context.bodyMedium.copyWith(
              color: context.colors.textHint,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.archive_rounded,
            size: 64,
            color: context.colors.textSecondary.withValues(alpha: 0.5),
          ),
          CommonSpaces.h16,
          Text(
            'No hidden chats',
            style: context.titleMedium.copyWith(
              color: context.colors.textSecondary,
              fontWeight: FontWeight.bold,
            ),
          ),
          CommonSpaces.h8,
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Conversations you hide will appear here. You can unhide them anytime.',
              textAlign: TextAlign.center,
              style: context.bodyMedium.copyWith(
                color: context.colors.textHint,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatsList(List<ChatModel> filteredChats) {
    return ListView.builder(
      itemCount: filteredChats.length,
      padding: const EdgeInsets.symmetric(vertical: 8),
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
          message = chat.lastMessage?.content ?? chat.groupDescription ?? 'No messages';
        }

        return InkWell(
          borderRadius: BorderRadius.circular(16),
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
                ),
              ),
            );
            _fetchHiddenChats();
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Row(
              children: [
                _buildAvatar(chat),
                CommonSpaces.w16,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.titleSmall.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: context.colors.textPrimary,
                        ),
                      ),
                      CommonSpaces.h4,
                      Text(
                        message,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.bodyMedium.copyWith(
                          color: chat.isTyping
                              ? const Color(0xFF34C759)
                              : context.colors.textSecondary.withValues(alpha: 0.7),
                          fontWeight: chat.isTyping ? FontWeight.w600 : FontWeight.normal,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                CommonSpaces.w12,
                IconButton(
                  icon: Icon(Icons.unarchive_rounded, color: context.colors.primary),
                  tooltip: 'Unhide Chat',
                  onPressed: () => _unhideChat(chat),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAvatar(ChatModel chat) {
    final isGroup = chat.isGroup;
    final color = context.colors.primary;

    if (isGroup) {
      return SizedBox(
        width: CommonSizes.p48,
        height: CommonSizes.p48,
        child: Stack(
          children: [
            Positioned(
              left: 2,
              top: 2,
              child: _buildSmallAvatar(
                context.colors.primary.withValues(alpha: 0.4),
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
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: context.colors.primary,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: context.colors.scaffoldBackground,
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Text(
                    '+3',
                    style: context.bodySmall.copyWith(
                      color: context.colors.pureWhite,
                      fontSize: 9,
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

    return Stack(
      children: [
        Container(
          width: CommonSizes.p38,
          height: CommonSizes.p38,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: ClipOval(
            child: (imageUrl != null && imageUrl.isNotEmpty)
                ? Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Center(
                        child: Text(
                          name.isNotEmpty
                              ? name.substring(0, 1).toUpperCase()
                              : '?',
                          style: context.titleMedium.copyWith(
                            color: color,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    },
                  )
                : Center(
                    child: Text(
                      name.isNotEmpty
                          ? name.substring(0, 1).toUpperCase()
                          : '?',
                      style: context.titleMedium.copyWith(
                        color: color,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
          ),
        ),
        if (isOnline)
          Positioned(
            right: 2,
            bottom: 2,
            child: Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: context.colors.success,
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
      width: 24,
      height: 24,
      decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
      child: Center(
        child: Text(emoji, style: context.bodyMedium.copyWith(fontSize: 12)),
      ),
    );
  }
}
