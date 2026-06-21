import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:schat/core/storage/storage_service.dart';
import 'package:schat/features/call_screen/call_screen.dart';
import 'package:schat/features/chat_search/src/presentation/chat_search_page.dart';
import 'package:schat/features/chat_screen/chat_screen.dart';
import 'package:schat/features/dashboard_screen/src/presentation/widgets/empty_chats_view.dart';
import 'package:schat/features/dashboard_screen/src/presentation/user_list_page.dart';
import 'package:schat/features/dashboard_screen/src/domain/chat_model.dart';
import 'package:schat/features/dashboard_screen/src/presentation/bloc/chats_bloc.dart';
import 'package:schat/features/dashboard_screen/src/presentation/bloc/chats_event.dart';
import 'package:schat/features/dashboard_screen/src/presentation/bloc/chats_state.dart';
import 'package:schat/features/profile_screen/src/domain/repositories/profile_repository.dart';
import 'package:schat/features/profile_screen/src/presentation/profile_settings_page.dart';
import 'package:schat/features/status_screen/src/presentation/status_page.dart';
import 'package:schat/injection.dart';
import 'package:schat/utils/common_colors.dart';
import 'package:schat/utils/common_fontstyles.dart';
import 'package:schat/utils/common_icons.dart';
import 'package:schat/utils/common_sizes.dart';
import 'package:schat/utils/common_spaces.dart';
import 'package:schat/utils/theme_controller.dart';

import 'package:schat/features/chat_socket_screen/src/presentation/bloc/chat_socket_bloc.dart';
import 'package:schat/features/chat_socket_screen/src/presentation/bloc/chat_socket_event.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _currentIndex = 0;
  String _username = 'David';

  @override
  void initState() {
    super.initState();
    _loadProfile();
    // Initialize socket connection when dashboard is loaded
    context.read<ChatSocketBloc>().add(const ConnectSocket());
  }

  Future<void> _loadProfile() async {
    getIt<ProfileRepository>().getProfile().then((result) {
      result.when(
        success: (user) {
          if (mounted) {
            setState(() {
              _username = user.username ?? 'David';
            });
          }
        },
        failure: (_, statusCode) {},
      );
    });

    setState(() {
      _username = getIt<StorageService>().getUsername() ?? 'David';
    });
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('DEBUG: Building DashboardPage');
    return Scaffold(
      backgroundColor: context.colors.scaffoldBackground,
      body: SafeArea(
        child: IndexedStack(
          index: _currentIndex,
          children: [
            _buildChatsTab(),
            const StatusPage(),
            const CallHistoryPage(),
            const UserListPage(),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildChatsTab() {
    return BlocProvider(
      create: (context) => getIt<ChatsBloc>()..add(const FetchChats()),
      child: BlocBuilder<ChatsBloc, ChatsState>(
        builder: (context, state) {
          return Column(
            children: [
              _buildHeader(),
              _buildSearchBar(),
              Expanded(
                child: state.maybeWhen(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (message) => const SizedBox.shrink(),
                  loaded: (chatList) {
                    if (chatList.isEmpty) {
                      return EmptyChatsView(
                        onChatNowPressed: () {
                          setState(() {
                            _currentIndex = 3;
                          });
                        },
                      );
                    }
                    return _buildChatList(chatList);
                  },
                  orElse: () =>
                      const Center(child: CircularProgressIndicator()),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      ProfileSettingsPage(username: _username),
                ),
              );
              _loadProfile();
            },
            child: Text.rich(
              TextSpan(
                text: "Hello ",
                children: [
                  TextSpan(
                    text: _username,
                    style: context.bodyMedium.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const TextSpan(text: " 👋"),
                ],
              ),
              style: context.h2.copyWith(
                fontSize: 26,
                color: context.colors.textPrimary,
              ),
            ),
          ),
          IconButton(
            icon: Icon(
              CommonIcons.moreVert,
              color: context.colors.textPrimary,
              size: 28,
            ),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      ProfileSettingsPage(username: _username),
                ),
              );
              _loadProfile();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    final searchBgColor = context.colors.searchBackground;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ChatSearchPage()),
          );
        },
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
              Text(
                'Search',
                style: context.bodyLarge.copyWith(
                  color: context.colors.textHint.withValues(alpha: 0.7),
                  fontSize: 16,
                  fontWeight: FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(ChatModel chat) {
    final isGroup = chat.isGroup;
    final color = context.colors.primary;

    if (isGroup) {
      return SizedBox(
        width: 56,
        height: 56,
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
    final name = chat.recipient.username ?? chat.recipient.phoneNumber;
    final isOnline = chat.recipient.isOnline;

    return Stack(
      children: [
        Container(
          width: 56,
          height: 56,
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
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                              : null,
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

  Widget _buildChatStatus(ChatModel chat) {
    final timestamp = chat.lastMessage?.createdAt ?? chat.updatedAt;
    final time = DateTime.parse(timestamp);
    final timeStr = "${time.hour}:${time.minute.toString().padLeft(2, '0')}";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          timeStr,
          style: context.bodySmall.copyWith(
            fontSize: 12,
            color: context.colors.textHint,
          ),
        ),
        const SizedBox(height: CommonSizes.p6),
        Icon(CommonIcons.doneAll, color: context.colors.primary, size: 18),
      ],
    );
  }

  Widget _buildChatList(List<ChatModel> chatList) {
    return ListView.builder(
      padding: const EdgeInsets.only(top: 12, bottom: 80),
      itemCount: chatList.length,
      itemBuilder: (context, index) {
        final chat = chatList[index];
        final name = chat.isGroup
            ? (chat.groupName ?? 'Group')
            : (chat.recipient.username ?? chat.recipient.phoneNumber);
        final message =
            chat.lastMessage?.content ??
            chat.groupDescription ??
            'No messages yet';

        return InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChatPage(
                  conversationId: chat.id,
                  contactName: name,
                  contactColor: context.colors.primary,
                  isOnline: chat.recipient.isOnline,
                  profilePictureUrl: chat.recipient.profilePictureUrl,
                  recipientId: chat.recipient.id,
                ),
              ),
            );
          },
          child: Padding(
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
                          color: context.colors.textSecondary.withValues(
                            alpha: 0.7,
                          ),
                          fontWeight: FontWeight.normal,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                CommonSpaces.w12,
                _buildChatStatus(chat),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        color: context.colors.scaffoldBackground,
        boxShadow: [
          BoxShadow(
            color: context.colors.textPrimary.withValues(
              alpha: getIt<ThemeController>().themeMode == ThemeMode.dark
                  ? 0.3
                  : 0.05,
            ),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: context.colors.transparent,
        selectedItemColor: context.colors.primary,
        unselectedItemColor: context.colors.textHint,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        elevation: 0,
        selectedLabelStyle: context.bodyMedium.copyWith(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: context.bodyMedium.copyWith(
          fontSize: 12,
          fontWeight: FontWeight.normal,
        ),
        items: [
          _buildBottomNavItem(CommonIcons.home, 'Messages', 0),
          _buildBottomNavItem(CommonIcons.statusIcon, 'Status', 1),
          _buildBottomNavItem(CommonIcons.call, 'Calls', 2),
          _buildBottomNavItem(CommonIcons.newChat, 'New Chat', 3),
        ],
      ),
    );
  }

  BottomNavigationBarItem _buildBottomNavItem(
    String iconPath,
    String label,
    int index,
  ) {
    final isActive = _currentIndex == index;
    return BottomNavigationBarItem(
      icon: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: isActive ? 30 : 0,
            height: 3,
            decoration: BoxDecoration(
              color: context.colors.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          CommonSpaces.h6,
          Image.asset(
            iconPath,
            width: 24,
            height: 24,
            color: isActive ? context.colors.primary : context.colors.textHint,
          ),
        ],
      ),
      label: label,
    );
  }
}
