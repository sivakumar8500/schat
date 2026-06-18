import 'package:flutter/material.dart';
import 'package:schat/utils/common_colors.dart';
import 'package:schat/utils/common_fontstyles.dart';
import 'package:schat/utils/common_icons.dart';
import 'package:schat/utils/common_spaces.dart';
import 'package:schat/utils/common_sizes.dart';

class ChatSearchPage extends StatefulWidget {
  const ChatSearchPage({super.key});

  @override
  State<ChatSearchPage> createState() => _ChatSearchPageState();
}

class _ChatSearchPageState extends State<ChatSearchPage> {
  String selectedFilter = 'Unread';
  final List<String> filters = ['Unread', 'Photos', 'Videos', 'Links', 'GIFs', 'Audio'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.scaffoldBackground,
      body: SafeArea(
        child: Column(
          children: [
            _buildSearchHeader(),
            _buildFilterChips(),
            Expanded(
              child: _buildContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: CommonSizes.p16,
        vertical: CommonSizes.p8,
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(CommonIcons.arrowBack, color: context.colors.textPrimary, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: context.colors.searchBackground,
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                autofocus: true,
                style: context.bodyMedium.copyWith(color: context.colors.textPrimary),
                decoration: InputDecoration(
                  prefixIcon: Icon(CommonIcons.search, color: context.colors.textHint.withValues(alpha: 0.6)),
                  hintText: 'Search',
                  hintStyle: context.bodyMedium.copyWith(color: context.colors.textHint.withValues(alpha: 0.6)),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return SizedBox(
      height: 60,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = selectedFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(filter),
              selected: isSelected,
              onSelected: (bool selected) {
                setState(() {
                  selectedFilter = filter;
                });
              },
              backgroundColor: context.colors.primary.withValues(alpha: 0.05),
              selectedColor: context.colors.primary,
              labelStyle: context.bodyMedium.copyWith(
                color: isSelected ? context.colors.textLight : context.colors.primary,
                fontWeight: FontWeight.w600,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: context.colors.primary.withValues(alpha: 0.1)),
              ),
              showCheckmark: false,
              avatar: _getFilterIcon(filter, isSelected),
            ),
          );
        },
      ),
    );
  }

  Widget? _getFilterIcon(String filter, bool isSelected) {
    IconData? icon;
    switch (filter) {
      case 'Unread':
        icon = CommonIcons.chatBubbleOutline;
      case 'Photos':
        icon = CommonIcons.photoOutlined;
      case 'Videos':
        icon = CommonIcons.videocamOutlined;
      case 'Links':
        icon = CommonIcons.linkOutlined;
    }
    if (icon == null) return null;
    return Icon(icon, size: 16, color: isSelected ? context.colors.textLight : context.colors.primary);
  }

  Widget _buildContent() {
    switch (selectedFilter) {
      case 'Photos':
        return _buildPhotosGrid();
      case 'Links':
        return _buildLinksList();
      case 'Unread':
      default:
        return _buildUnreadChats();
    }
  }

  Widget _buildUnreadChats() {
    // Mocking the unread chats from screenshot
    final unreadChats = [
      {
        'name': 'Olivia Grant',
        'message': 'Olivia is typing...',
        'time': '12:30',
        'unread': 3,
        'color': context.colors.pinkAccent,
        'isTyping': true,
      },
      {
        'name': 'Product design',
        'message': 'When is the meeting scheduled ?',
        'time': '12:34',
        'unread': 3,
        'color': context.colors.primary,
        'isGroup': true,
      },
      {
        'name': 'John Alfaro',
        'message': 'Nice work, i love it 👍',
        'time': '12:30',
        'unread': 3,
        'color': context.colors.error,
      },
    ];

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: unreadChats.length,
      itemBuilder: (context, index) {
        final chat = unreadChats[index];
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(vertical: 8),
          leading: _buildAvatar(chat),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(chat['name'] as String, style: context.titleMedium.copyWith(fontWeight: FontWeight.bold)),
              Text(chat['time'] as String, style: context.bodySmall.copyWith(color: context.colors.textHint)),
            ],
          ),
          subtitle: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  chat['message'] as String,
                  style: context.bodyMedium.copyWith(
                    color: chat['isTyping'] == true ? context.colors.primary : context.colors.textSecondary,
                    fontStyle: chat['isTyping'] == true ? FontStyle.italic : FontStyle.normal,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: context.colors.primary, shape: BoxShape.circle),
                child: Text(
                  chat['unread'].toString(),
                  style: context.bodySmall.copyWith(color: context.colors.pureWhite, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAvatar(Map<String, dynamic> chat) {
    if (chat['isGroup'] == true) {
      return SizedBox(
        width: 48,
        height: 48,
        child: Stack(
          children: [
            Positioned(left: 0, top: 0, child: CircleAvatar(radius: 14, backgroundColor: context.colors.lightBackground)),
            Positioned(right: 0, top: 0, child: CircleAvatar(radius: 14, backgroundColor: context.colors.blue.withValues(alpha: 0.3))),
            Positioned(left: 0, bottom: 0, child: CircleAvatar(radius: 14, backgroundColor: context.colors.orange.withValues(alpha: 0.3))),
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(color: context.colors.primary, shape: BoxShape.circle),
                child: Text('+3', style: context.bodySmall.copyWith(color: context.colors.pureWhite, fontSize: 8)),
              ),
            ),
          ],
        ),
      );
    }
    return CircleAvatar(
      radius: 24,
      backgroundColor: (chat['color'] as Color).withValues(alpha: 0.2),
      child: Text((chat['name'] as String)[0], style: context.bodyMedium.copyWith(color: chat['color'] as Color, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildPhotosGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: 24,
      itemBuilder: (context, index) {
        return Container(
          decoration: BoxDecoration(
            color: context.colors.lightBackground,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(CommonIcons.photo, color: context.colors.textHint.withValues(alpha: 0.2), size: 32),
        );
      },
    );
  }

  Widget _buildLinksList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Column(
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(radius: 20, backgroundColor: context.colors.pinkAccent.withValues(alpha: 0.2)),
              title: Text('Olivia Grant', style: context.titleSmall.copyWith(fontWeight: FontWeight.bold)),
              trailing: Text('12:30', style: context.bodyMedium.copyWith(color: context.colors.textHint, fontSize: 12)),
            ),
            Text(
              'You: https://www.instagram.com/p/DXHF6eljI-b/?igsh=MTB1bjM2cDhpMmIsZA%3D%3D',
              style: context.bodyMedium.copyWith(color: context.colors.blue, fontSize: 13),
            ),
            CommonSpaces.h8,
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: context.colors.green.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Image.network(
                    'https://upload.wikimedia.org/wikipedia/commons/thumb/a/a5/Google_Meet_icon_%282020%29.svg/1024px-Google_Meet_icon_%282020%29.svg.png', 
                    width: 40, 
                    height: 40, 
                    errorBuilder: (c, e, s) => const Icon(CommonIcons.link),
                  ),
                  CommonSpaces.w12,
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Meet', style: context.titleSmall.copyWith(fontWeight: FontWeight.bold)),
                      Text('Video conferencing', style: context.bodyMedium.copyWith(fontSize: 12, color: context.colors.grey)),
                    ],
                  ),
                ],
              ),
            ),
            CommonSpaces.h16,
          ],
        );
      },
    );
  }
}
