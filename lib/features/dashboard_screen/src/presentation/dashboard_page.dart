import 'package:schat/utils/common_fontstyles.dart';

import 'package:schat/utils/common_sizes.dart';

import 'package:schat/utils/common_spaces.dart';
import 'package:flutter/material.dart';
import 'package:schat/features/chat_screen/chat_screen.dart';
import 'package:schat/utils/common_colors.dart';
import 'package:schat/utils/theme_controller.dart';
import 'package:schat/injection.dart';
import 'package:schat/features/profile_screen/src/presentation/profile_page.dart';
import 'package:schat/common/widgets/primary_button.dart';
import 'package:schat/features/status_screen/src/presentation/status_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:schat/features/call_screen/call_screen.dart';

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

  // Dummy chat data matching the mockup names, unreads, status indicators, and tests
  List<Map<String, dynamic>> get _chats => [
    // Retaining Alice Smith and Bob Johnson at the beginning to ensure lazy list rendering in widget tests finds them
    {
      'name': 'Alice Smith',
      'message': 'Hey, are we still on for tomorrow?',
      'time': '10:30 AM',
      'unread': 2,
      'isOnline': true,
      'color': Colors.pinkAccent,
      'status': 'unread',
    },
    {
      'name': 'Bob Johnson',
      'message': 'Check out this new feature! It looks amazing.',
      'time': 'Yesterday',
      'unread': 0,
      'isOnline': false,
      'color': context.colors.primary,
      'status': 'sent_double_grey',
    },
    {
      'name': 'Olivia Grant',
      'message': 'Olivia is typing...',
      'time': '12:30',
      'unread': 3,
      'isOnline': true,
      'color': Colors.pinkAccent,
      'status': 'typing',
    },
    {
      'name': 'Product design',
      'message': 'When is the meeting scheduled ?',
      'time': '12:34',
      'unread': 3,
      'isOnline': false,
      'color': context.colors.primary,
      'status': 'unread',
      'isGroup': true,
    },
    {
      'name': 'John Alfaro',
      'message': 'Nice work, i love it 👍',
      'time': '12:30',
      'unread': 3,
      'isOnline': true,
      'color': Colors.redAccent,
      'status': 'unread',
    },
    {
      'name': 'Travis Colwell',
      'message': 'Unfortunaly, I won\'t be here today...',
      'time': '12:30',
      'unread': 0,
      'isOnline': false,
      'color': Colors.teal,
      'status': 'read_double_green',
    },
    {
      'name': 'Darcy Hooper',
      'message': 'Hi! How are you doing ?',
      'time': '12:30',
      'unread': 0,
      'isOnline': true,
      'color': Colors.orangeAccent,
      'status': 'read_double_green',
    },
    {
      'name': 'Emaly Cooper',
      'message': 'Emaly is typing...',
      'time': '12:30',
      'unread': 0,
      'isOnline': false,
      'color': Colors.indigo,
      'status': 'sent_double_grey',
    },
  ];

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
            _buildProfileTab(),
          ],
        ),
      ),
      floatingActionButton: _currentIndex == 0 || _currentIndex == 2
          ? FloatingActionButton(
              onPressed: () {},
              backgroundColor: context.colors.primary,
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
              child: Icon(
                _currentIndex == 0 ? Icons.edit : Icons.add_ic_call,
                color: context.colors.textLight,
              ),
            )
          : null,
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildChatsTab() {
    return Column(
      children: [
        _buildHeader(),
        _buildSearchBar(),
        Expanded(
          child: _buildChatList(),
        ),
      ],
    );
  }

  Widget _buildProfileTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CommonSpaces.h40,
          CircleAvatar(
            radius: 60,
            backgroundColor: context.colors.primary.withValues(alpha: 0.2),
            child: Icon(Icons.person, size: 60, color: context.colors.primary),
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
              _loadProfile(); // reload in case username changed
            },
          ),
          CommonSpaces.h20,
          Material(
            color: context.colors.lightBackground,
            borderRadius: BorderRadius.circular(16),
            clipBehavior: Clip.antiAlias,
            child: ListTile(
              leading: Icon(
                getIt<ThemeController>().themeMode == ThemeMode.dark ? Icons.light_mode : Icons.dark_mode,
                color: context.colors.textPrimary,
              ),
              title: Text(
                getIt<ThemeController>().themeMode == ThemeMode.dark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
                style: TextStyle(color: context.colors.textPrimary, fontWeight: FontWeight.bold),
              ),
              trailing: Switch(
                value: getIt<ThemeController>().themeMode == ThemeMode.dark,
                activeThumbColor: context.colors.primary,
                onChanged: (val) {
                  getIt<ThemeController>().toggleTheme();
                },
              ),
              onTap: () {
                getIt<ThemeController>().toggleTheme();
              },
            ),
          ),
          CommonSpaces.h16,
          Material(
            color: context.colors.lightBackground,
            borderRadius: BorderRadius.circular(16),
            clipBehavior: Clip.antiAlias,
            child: ListTile(
              leading: Icon(
                Icons.format_size_rounded,
                color: context.colors.textPrimary,
              ),
              title: Text(
                'Font Size',
                style: TextStyle(color: context.colors.textPrimary, fontWeight: FontWeight.bold),
              ),
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
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text.rich(
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
          IconButton(
            icon: Icon(Icons.more_vert_rounded, color: context.colors.textPrimary, size: 28),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    final searchBgColor = context.colors.searchBackground;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: searchBgColor,
          borderRadius: BorderRadius.circular(26),
        ),
        child: TextField(
          style: TextStyle(color: context.colors.textPrimary),
          decoration: InputDecoration(
            prefixIcon: Icon(Icons.search_rounded, color: context.colors.textHint.withValues(alpha: 0.7)),
            hintText: 'Search',
            hintStyle: TextStyle(
              color: context.colors.textHint.withValues(alpha: 0.7),
              fontSize: 16,
              fontWeight: FontWeight.normal,
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(Map<String, dynamic> chat) {
    final isGroup = chat['isGroup'] == true;
    final isOnline = chat['isOnline'] == true;
    final color = chat['color'] as Color;

    if (isGroup) {
      return SizedBox(
        width: 56,
        height: 56,
        child: Stack(
          children: [
            Positioned(
              left: 0,
              top: 0,
              child: CircleAvatar(
                radius: 18,
                backgroundColor: color.withValues(alpha: 0.25),
                child: const Text(
                  '👥',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: CircleAvatar(
                radius: 18,
                backgroundColor: Colors.pinkAccent.withValues(alpha: 0.25),
                child: const Text(
                  '👩‍💻',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Stack(
      children: [
        CircleAvatar(
          radius: 28,
          backgroundColor: color.withValues(alpha: 0.15),
          child: Text(
            chat['name'].substring(0, 1),
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
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
                color: context.colors.primary,
                shape: BoxShape.circle,
                border: Border.all(color: context.colors.scaffoldBackground, width: 2),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildChatStatus(Map<String, dynamic> chat) {
    final unread = chat['unread'] as int;
    final status = chat['status'] as String?;

    if (unread > 0) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            chat['time'],
            style: TextStyle(
              fontSize: 12,
              color: context.colors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: CommonSizes.p6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            decoration: BoxDecoration(
              color: context.colors.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            constraints: const BoxConstraints(
              minWidth: 20,
              minHeight: 20,
            ),
            child: Center(
              child: Text(
                unread.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      );
    } else {
      Widget statusIcon;
      if (status == 'read_double_green') {
        statusIcon = Icon(Icons.done_all_rounded, color: context.colors.primary, size: 18);
      } else if (status == 'sent_double_grey') {
        statusIcon = Icon(Icons.done_all_rounded, color: context.colors.textHint.withValues(alpha: 0.6), size: 18);
      } else {
        statusIcon = Icon(Icons.done_rounded, color: context.colors.textHint.withValues(alpha: 0.6), size: 18);
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            chat['time'],
            style: TextStyle(
              fontSize: 12,
              color: context.colors.textHint,
            ),
          ),
          const SizedBox(height: CommonSizes.p6),
          statusIcon,
        ],
      );
    }
  }

  Widget _buildChatList() {
    return ListView.builder(
      padding: const EdgeInsets.only(top: 12, bottom: 80),
      itemCount: _chats.length,
      itemBuilder: (context, index) {
        final chat = _chats[index];
        final isTyping = chat['status'] == 'typing';

        return InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChatPage(
                  contactName: chat['name'],
                  contactColor: chat['color'],
                  isOnline: chat['isOnline'],
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
                
                // Name and Message
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        chat['name'],
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: context.colors.textPrimary,
                        ),
                      ),
                      CommonSpaces.h4,
                      Text(
                        chat['message'],
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: isTyping
                              ? context.colors.primary
                              : (chat['unread'] > 0 ? context.colors.textPrimary : context.colors.textSecondary),
                          fontWeight: (chat['unread'] > 0 || isTyping) ? FontWeight.w600 : FontWeight.normal,
                          fontStyle: isTyping ? FontStyle.italic : FontStyle.normal,
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
          selectedLabelStyle: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: context.colors.primary,
          ),
          unselectedLabelStyle: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.normal,
            color: context.colors.textHint,
          ),
          items: const [
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Icon(Icons.chat_bubble_outline_rounded, size: 24),
              ),
              activeIcon: Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Icon(Icons.chat_bubble_rounded, size: 24),
              ),
              label: 'Messages',
            ),
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Icon(Icons.auto_awesome_mosaic_rounded, size: 24),
              ),
              label: 'Status',
            ),
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Icon(Icons.phone_outlined, size: 24),
              ),
              activeIcon: Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Icon(Icons.phone, size: 24),
              ),
              label: 'Calls',
            ),
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Icon(Icons.person_outline_rounded, size: 24),
              ),
              activeIcon: Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Icon(Icons.person_rounded, size: 24),
              ),
              label: 'New Chat',
            ),
          ],
        ),
      ),
    );
  }
}
