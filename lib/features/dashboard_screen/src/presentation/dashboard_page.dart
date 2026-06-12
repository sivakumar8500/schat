import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:schat/common/widgets/primary_button.dart';
import 'package:schat/features/call_screen/call_screen.dart';
import 'package:schat/features/chat_search/src/presentation/chat_search_page.dart';
import 'package:schat/features/chat_screen/chat_screen.dart';
import 'package:schat/features/dashboard_screen/src/presentation/widgets/empty_chats_view.dart';
import 'package:schat/features/dashboard_screen/src/presentation/user_list_page.dart';
import 'package:schat/features/dashboard_screen/src/domain/chat_model.dart';
import 'package:schat/features/dashboard_screen/src/presentation/bloc/chats_bloc.dart';
import 'package:schat/features/dashboard_screen/src/presentation/bloc/chats_event.dart';
import 'package:schat/features/dashboard_screen/src/presentation/bloc/chats_state.dart';
import 'package:schat/features/intro_screen/intro_screen.dart';
import 'package:schat/features/profile_screen/src/presentation/bloc/profile_bloc.dart';
import 'package:schat/features/profile_screen/src/presentation/bloc/profile_event.dart';
import 'package:schat/features/profile_screen/src/presentation/bloc/profile_state.dart';
import 'package:schat/features/profile_screen/src/presentation/profile_page.dart';
import 'package:schat/features/status_screen/src/presentation/status_page.dart';
import 'package:schat/injection.dart';
import 'package:schat/utils/common_colors.dart';
import 'package:schat/utils/common_fontstyles.dart';
import 'package:schat/utils/common_icons.dart';
import 'package:schat/utils/common_sizes.dart';
import 'package:schat/utils/common_spaces.dart';
import 'package:schat/utils/theme_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  }

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _username = prefs.getString('username') ?? 'David';
    });
  }

  @override
  Widget build(BuildContext context) {
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
      floatingActionButton: _currentIndex == 0 || _currentIndex == 2
          ? FloatingActionButton(
              heroTag: 'dashboard_fab',
              onPressed: () {},
              backgroundColor: context.colors.primary,
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
              child: Icon(
                _currentIndex == 0 ? CommonIcons.edit : CommonIcons.addCall,
                color: context.colors.textLight,
              ),
            )
          : null,
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
                child: state.when(
                  initial: () => const Center(child: CircularProgressIndicator()),
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (message) => Center(child: Text(message)),
                  loaded: (chatList) {
                    if (chatList.isEmpty) {
                      return EmptyChatsView(
                        onChatNowPressed: () {
                          setState(() {
                            _currentIndex = 3; // Switch to New Chat tab
                          });
                        },
                      );
                    }
                    return _buildChatList(chatList);
                  },
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
              // Navigate to a dedicated Profile/Settings view
              await _showProfileSettings();
              _loadProfile();
            },
            child: Text.rich(
              TextSpan(
                text: "Hello ",
                children: [
                  TextSpan(
                    text: _username,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const TextSpan(text: " 👋"),
                ],
              ),
              style: TextStyle(
                fontSize: 26,
                color: context.colors.textPrimary,
              ),
            ),
          ),
          IconButton(
            icon: Icon(CommonIcons.moreVert, color: context.colors.textPrimary, size: 28),
            onPressed: () => _showProfileSettings(),
          ),
        ],
      ),
    );
  }

  Future<void> _showProfileSettings() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: BoxDecoration(
          color: context.colors.scaffoldBackground,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: _buildProfileContent(),
      ),
    );
  }

  Widget _buildProfileContent() {
    return BlocProvider<ProfileBloc>(
      create: (context) => ProfileBloc(),
      child: BlocListener<ProfileBloc, ProfileState>(
        listener: (context, state) {
          if (state is ProfileLogoutSuccess) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const IntroPage()),
              (Route<dynamic> route) => false,
            );
          }
        },
        child: Builder(builder: (context) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: context.colors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Text('Profile Settings', style: context.h2),
                CommonSpaces.h32,
                CircleAvatar(
                  radius: 60,
                  backgroundColor: context.colors.primary.withValues(alpha: 0.2),
                  child: Icon(CommonIcons.person, size: 60, color: context.colors.primary),
                ),
                CommonSpaces.h20,
                Text(
                  _username,
                  style: context.h2,
                ),
                CommonSpaces.h40,
                PrimaryButton(
                  text: 'Edit Profile',
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ProfilePage(isEditing: true)),
                    );
                    if (mounted) Navigator.pop(context);
                  },
                ),
                CommonSpaces.h16,
                TextButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (dialogContext) => AlertDialog(
                        backgroundColor: context.colors.pureBlack,
                        title: Text('Logout', style: context.titleMedium.copyWith(color: Colors.white)),
                        content: Text('Are you sure you want to logout?',
                            style: context.bodyMedium.copyWith(color: Colors.white.withValues(alpha: 0.7))),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(dialogContext),
                            child: Text('Cancel', style: context.bodyMedium.copyWith(color: Colors.white)),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(dialogContext);
                              context.read<ProfileBloc>().add(const LogoutEvent());
                            },
                            child: Text('Logout',
                                style: context.bodyMedium
                                    .copyWith(color: context.colors.error, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    );
                  },
                  icon: Icon(CommonIcons.logout, color: context.colors.error, size: 20),
                  label: Text(
                    'Logout from account',
                    style: context.bodyMedium.copyWith(
                      color: context.colors.error,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                CommonSpaces.h32,
                _buildSettingsTile(
                  icon: getIt<ThemeController>().themeMode == ThemeMode.dark ? Icons.light_mode : Icons.dark_mode,
                  title: getIt<ThemeController>().themeMode == ThemeMode.dark ? 'Light Mode' : 'Dark Mode',
                  trailing: Switch(
                    value: getIt<ThemeController>().themeMode == ThemeMode.dark,
                    activeThumbColor: context.colors.primary,
                    onChanged: (val) {
                      setState(() {
                        getIt<ThemeController>().toggleTheme();
                      });
                    },
                  ),
                ),
                CommonSpaces.h12,
                _buildSettingsTile(
                  icon: Icons.format_size_rounded,
                  title: 'Font Size',
                  trailing: DropdownButton<String>(
                    value: getIt<ThemeController>().fontSizeName,
                    dropdownColor: context.colors.lightBackground,
                    style: TextStyle(color: context.colors.textPrimary, fontWeight: FontWeight.bold),
                    underline: const SizedBox(),
                    items: const [
                      DropdownMenuItem(value: 'Small', child: Text('Small')),
                      DropdownMenuItem(value: 'Medium', child: Text('Medium')),
                      DropdownMenuItem(value: 'Large', child: Text('Large')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          getIt<ThemeController>().setFontSize(val);
                        });
                      }
                    },
                  ),
                ),
                CommonSpaces.h40,
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildSettingsTile({required IconData icon, required String title, required Widget trailing}) {
    return Material(
      color: context.colors.lightBackground,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        leading: Icon(icon, color: context.colors.textPrimary),
        title: Text(title, style: TextStyle(color: context.colors.textPrimary, fontWeight: FontWeight.bold)),
        trailing: trailing,
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
              Icon(CommonIcons.search, color: context.colors.textHint.withValues(alpha: 0.7)),
              CommonSpaces.w12,
              Text(
                'Search',
                style: TextStyle(
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
    final color = context.colors.primary; // Default color for API results

    if (isGroup) {
      return SizedBox(
        width: 56,
        height: 56,
        child: Stack(
          children: [
            Positioned(
              left: 2,
              top: 2,
              child: _buildSmallAvatar(context.colors.primary.withValues(alpha: 0.4), '👨🏻‍💻'),
            ),
            Positioned(
              right: 2,
              top: 2,
              child: _buildSmallAvatar(Colors.pinkAccent.withValues(alpha: 0.4), '👩🏼‍💻'),
            ),
            Positioned(
              left: 2,
              bottom: 2,
              child: _buildSmallAvatar(Colors.orangeAccent.withValues(alpha: 0.4), '👨🏽‍💻'),
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
                  border: Border.all(color: context.colors.scaffoldBackground, width: 2),
                ),
                child: const Center(
                  child: Text(
                    '+3',
                    style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    final name = chat.groupName ?? 'User';
    return Stack(
      children: [
        CircleAvatar(
          radius: 28,
          backgroundColor: color.withValues(alpha: 0.15),
          child: Text(
            name.isNotEmpty ? name.substring(0, 1) : 'U',
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.bold,
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
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(emoji, style: const TextStyle(fontSize: 12)),
      ),
    );
  }

  Widget _buildChatStatus(ChatModel chat) {
    final time = DateTime.parse(chat.updatedAt);
    final timeStr = "${time.hour}:${time.minute.toString().padLeft(2, '0')}";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          timeStr,
          style: TextStyle(
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
        final name = chat.groupName ?? 'Unknown Chat';
        final message = chat.groupDescription ?? 'No description';

        return InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChatPage(
                  contactName: name,
                  contactColor: context.colors.primary,
                  isOnline: false,
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
                        style: TextStyle(
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
                        style: TextStyle(
                          color: context.colors.textSecondary.withValues(alpha: 0.7),
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
        boxShadow: [
          BoxShadow(
            color: context.colors.textPrimary.withValues(
              alpha: getIt<ThemeController>().themeMode == ThemeMode.dark ? 0.3 : 0.05,
            ),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: context.colors.scaffoldBackground,
          selectedItemColor: context.colors.primary,
          unselectedItemColor: context.colors.textHint,
          showSelectedLabels: true,
          showUnselectedLabels: true,
          elevation: 0,
          selectedLabelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          unselectedLabelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
          items: [
            BottomNavigationBarItem(
              icon: Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Image.asset(
                  CommonIcons.home,
                  width: 24,
                  height: 24,
                  color: _currentIndex == 0 ? context.colors.primary : context.colors.textHint,
                ),
              ),
              label: 'Messages',
            ),
            BottomNavigationBarItem(
              icon: Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Image.asset(
                  CommonIcons.statusIcon,
                  width: 24,
                  height: 24,
                  color: _currentIndex == 1 ? context.colors.primary : context.colors.textHint,
                ),
              ),
              label: 'Status',
            ),
            BottomNavigationBarItem(
              icon: Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Image.asset(
                  CommonIcons.call,
                  width: 24,
                  height: 24,
                  color: _currentIndex == 2 ? context.colors.primary : context.colors.textHint,
                ),
              ),
              label: 'Calls',
            ),
            BottomNavigationBarItem(
              icon: Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Image.asset(
                  CommonIcons.newChat,
                  width: 24,
                  height: 24,
                  color: _currentIndex == 3 ? context.colors.primary : context.colors.textHint,
                ),
              ),
              label: 'New Chat',
            ),
          ],
        ),
      ),
    );
  }
}
