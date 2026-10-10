import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:schat/features/chat_screen/src/domain/repositories/chat_repository.dart';
import 'package:schat/features/chat_screen/src/presentation/chat_page.dart';
import 'package:schat/features/chat_screen/src/presentation/widgets/chat_lock_bottom_sheet.dart';
import 'package:schat/features/chat_screen/src/presentation/widgets/forgot_chat_lock_bottom_sheet.dart';
import 'package:schat/features/chat_search/src/domain/models/global_search_model.dart';
import 'package:schat/injection.dart';
import 'package:schat/utils/common_colors.dart';
import 'package:schat/utils/common_fontstyles.dart';
import 'package:schat/utils/common_spaces.dart';

class LockedChatsPage extends StatefulWidget {
  final List<SearchChatItem>? initialLockedChats;

  const LockedChatsPage({
    super.key,
    this.initialLockedChats,
  });

  @override
  State<LockedChatsPage> createState() => _LockedChatsPageState();
}

class _LockedChatsPageState extends State<LockedChatsPage> {
  List<SearchChatItem> _lockedChats = [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.initialLockedChats != null && widget.initialLockedChats!.isNotEmpty) {
      _lockedChats = List.from(widget.initialLockedChats!);
    }
    _fetchLockedChats();
  }

  Future<void> _fetchLockedChats() async {
    setState(() {
      _isLoading = _lockedChats.isEmpty;
      _errorMessage = null;
    });

    try {
      final repo = getIt<ChatRepository>();
      final list = await repo.getLockedChats();
      if (mounted) {
        setState(() {
          _lockedChats = list.map((e) {
            if (e is SearchChatItem) return e;
            if (e is Map<String, dynamic>) return SearchChatItem.fromJson(e);
            if (e is Map) return SearchChatItem.fromJson(Map<String, dynamic>.from(e));
            return null;
          }).whereType<SearchChatItem>().toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to load locked chats: $e';
        });
      }
    }
  }

  void _openChat(SearchChatItem item) {
    if (item.id.isEmpty) return;

    final recId = (item.recipientId != null && item.recipientId!.isNotEmpty)
        ? item.recipientId!
        : item.id;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatPage(
          conversationId: item.id,
          recipientId: recId,
          contactName: item.name.isNotEmpty ? item.name : 'Chat',
          contactColor: Colors.transparent,
          isOnline: false,
          profilePictureUrl: item.pictureUrl,
          isGroup: item.isGroup,
          initialIsLocked: true,
        ),
      ),
    ).then((_) => _fetchLockedChats());
  }

  void _showChangePasscode() {
    ChatLockBottomSheet.show(
      context,
      conversationId: '',
      contactName: 'Locked Chats',
      isCurrentlyLocked: true,
    );
  }

  void _showForgotPasscode() {
    ForgotChatLockBottomSheet.show(
      context,
      onPasswordReset: () {
        _fetchLockedChats();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = colors.isDark;
    const primaryColor = Color(0xFF00873C);

    return Scaffold(
      backgroundColor: colors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: colors.scaffoldBackground,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: colors.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.lock_rounded, color: primaryColor, size: 18),
            ),
            CommonSpaces.w10,
            Text(
              'Locked Chats',
              style: context.titleMedium.copyWith(
                fontWeight: FontWeight.bold,
                color: colors.textPrimary,
              ),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert_rounded, color: colors.textPrimary),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            color: colors.cardBackground,
            onSelected: (val) {
              if (val == 'change_passcode') {
                _showChangePasscode();
              } else if (val == 'forgot_passcode') {
                _showForgotPasscode();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'change_passcode',
                child: Row(
                  children: [
                    Icon(Icons.password_rounded, size: 18, color: colors.textPrimary),
                    CommonSpaces.w10,
                    Text('Change Passcode', style: TextStyle(color: colors.textPrimary)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'forgot_passcode',
                child: Row(
                  children: [
                    Icon(Icons.lock_reset_rounded, size: 18, color: colors.textPrimary),
                    CommonSpaces.w10,
                    Text('Forgot Passcode', style: TextStyle(color: colors.textPrimary)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchLockedChats,
        color: primaryColor,
        child: _buildBody(colors, primaryColor, isDark),
      ),
    );
  }

  Widget _buildBody(dynamic colors, Color primaryColor, bool isDark) {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(color: primaryColor),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline_rounded, color: colors.error, size: 48),
              CommonSpaces.h12,
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: context.bodyMedium.copyWith(color: colors.textSecondary),
              ),
              CommonSpaces.h16,
              ElevatedButton(
                onPressed: _fetchLockedChats,
                style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
                child: const Text('Retry', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      );
    }

    if (_lockedChats.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E3A2B) : const Color(0xFFD1FADF),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.lock_open_rounded, color: primaryColor, size: 40),
            ),
            CommonSpaces.h16,
            Text(
              'No Locked Chats',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: colors.textPrimary,
              ),
            ),
            CommonSpaces.h6,
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                'Lock chats from their profile settings to keep them private and hidden.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: colors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _lockedChats.length,
      separatorBuilder: (_, _) => Divider(
        height: 1,
        indent: 76,
        color: colors.textHint.withValues(alpha: 0.1),
      ),
      itemBuilder: (context, index) {
        final item = _lockedChats[index];
        return _buildChatItem(item, colors, primaryColor, isDark);
      },
    );
  }

  Widget _buildChatItem(SearchChatItem item, dynamic colors, Color primaryColor, bool isDark) {
    final name = item.name.isNotEmpty ? item.name : 'Chat';
    final lastMsg = (item.lastMessageSnippet != null && item.lastMessageSnippet!.isNotEmpty)
        ? item.lastMessageSnippet!
        : 'Locked conversation';
    final profilePic = item.pictureUrl;
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

    String time = '';
    if (item.lastMessageTimestamp != null && item.lastMessageTimestamp! > 0) {
      time = _formatTime(DateTime.fromMillisecondsSinceEpoch(item.lastMessageTimestamp!).toLocal());
    } else if (item.updatedAt != null && item.updatedAt! > 0) {
      time = _formatTime(DateTime.fromMillisecondsSinceEpoch(item.updatedAt!).toLocal());
    }

    final avatarBg = isDark ? const Color(0xFF1E3A2B) : const Color(0xFFD1FADF);

    return InkWell(
      onTap: () => _openChat(item),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Stack(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: avatarBg,
                    shape: BoxShape.circle,
                  ),
                  child: profilePic != null && profilePic.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(25),
                          child: CachedNetworkImage(
                            imageUrl: profilePic,
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                            placeholder: (_, _) => Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: primaryColor),
                              ),
                            ),
                            errorWidget: (_, _, _) => Center(
                              child: Text(
                                initial,
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: primaryColor,
                                ),
                              ),
                            ),
                          ),
                        )
                      : Center(
                          child: Text(
                            initial,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: primaryColor,
                            ),
                          ),
                        ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: primaryColor,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: colors.cardBackground,
                        width: 1.5,
                      ),
                    ),
                    child: const Icon(
                      Icons.lock_rounded,
                      size: 10,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            CommonSpaces.w12,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: colors.textPrimary,
                          ),
                        ),
                      ),
                      if (time.isNotEmpty)
                        Text(
                          time,
                          style: TextStyle(
                            fontSize: 11.5,
                            color: colors.textHint,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    lastMsg,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime date) {
    final now = DateTime.now();
    if (date.year == now.year && date.month == now.month && date.day == now.day) {
      final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
      final minute = date.minute.toString().padLeft(2, '0');
      final period = date.hour >= 12 ? 'PM' : 'AM';
      return '$hour:$minute $period';
    }
    return '${date.day}/${date.month}/${date.year}';
  }
}
