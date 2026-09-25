import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:hive/hive.dart';
import 'package:schat/core/storage/storage_service.dart';
import 'package:schat/core/notifications/push_notification_service.dart';
import 'package:schat/core/notifications/call_notification_service.dart';
import 'package:schat/features/call_screen/call_screen.dart';
import 'package:schat/features/chat_search/src/presentation/chat_search_page.dart';
import 'package:schat/features/chat_screen/chat_screen.dart';
import 'package:schat/features/dashboard_screen/src/presentation/widgets/empty_chats_view.dart';
import 'package:schat/features/dashboard_screen/src/presentation/user_list_page.dart';
import 'package:schat/features/dashboard_screen/src/domain/models/chat_model.dart';
import 'package:schat/features/dashboard_screen/src/presentation/bloc/chats_bloc.dart';
import 'package:schat/features/dashboard_screen/src/domain/repositories/dashboard_repository.dart';
import 'package:schat/presentation/pages/hidden_chats_page.dart';
import 'package:schat/features/dashboard_screen/src/presentation/bloc/chats_event.dart';
import 'package:schat/features/dashboard_screen/src/presentation/bloc/chats_state.dart';
import 'package:schat/features/profile_screen/src/domain/repositories/profile_repository.dart';
import 'package:schat/features/profile_screen/src/presentation/profile_settings_page.dart';
import 'package:schat/features/status_screen/src/presentation/status_page.dart';
import 'package:schat/injection.dart';
import 'package:schat/utils/common_colors.dart';
import 'package:schat/utils/common_fontstyles.dart';
import 'package:schat/utils/common_icons.dart';
import 'package:schat/utils/common_notifications.dart';
import 'package:schat/utils/common_spaces.dart';
import 'package:schat/features/dashboard_screen/src/presentation/bloc/contacts_bloc.dart';
import 'package:schat/features/dashboard_screen/src/presentation/bloc/contacts_event.dart';
import 'package:schat/features/dashboard_screen/src/presentation/widgets/create_group_bottom_sheet.dart';
import 'package:schat/utils/theme_controller.dart';

import 'package:schat/features/chat_socket_screen/src/presentation/bloc/chat_socket_bloc.dart';
import 'package:schat/features/chat_socket_screen/src/presentation/bloc/chat_socket_event.dart';
import 'package:schat/features/subscription_screen/subscription_screen.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _currentIndex = 0;
  int _filterIndex = 0; // 0: All, 1: Unread, 2: Groups
  String _username = 'David';
  String? _profilePicUrl;
  final Set<String> _hiddenChatIds = {};
  final Set<String> _deletedChatIds = {};
  final Set<String> _selectedChatIds = {};
  final Set<String> _mutedChatIds = {};
  bool _shouldSyncContacts = false;
  bool _onlyShowSynced = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _loadMutedChats();
    // Initialize socket connection when dashboard is loaded
    context.read<ChatSocketBloc>().add(const ConnectSocket());
    
    // Fetch conversations now that we are authenticated
    context.read<ChatsBloc>().add(const FetchChats());
    
    // Setup and sync push notifications & call tokens since we are authenticated
    _setupNotifications();
  }

  Future<void> _setupNotifications() async {
    final pushService = getIt<PushNotificationService>();
    final callService = getIt<CallNotificationService>();
    
    // Explicitly request notification permission using permission_handler (more reliable on Android 13+)
    if (!kIsWeb) {
      final status = await Permission.notification.status;
      if (status.isDenied) {
        await Permission.notification.request();
      }
    }
    
    await pushService.initialize();
    await pushService.registerToken();
    await callService.registerDevice();
  }

  Future<void> _loadMutedChats() async {
    try {
      final box = await Hive.openBox('muted_chats_box');
      final List<dynamic>? list = box.get('muted_list');
      if (list != null) {
        setState(() {
          _mutedChatIds.addAll(list.cast<String>());
        });
      }
    } catch (_) {}
  }

  bool _shouldShowBlockAction() {
    final chatsState = context.read<ChatsBloc>().state;
    if (chatsState is ChatsLoaded) {
      final selectedChats = chatsState.chats.where((c) => _selectedChatIds.contains(c.id));
      if (selectedChats.isEmpty) return false;
      return selectedChats.every((c) => !c.isGroup);
    }
    return false;
  }

  Widget _buildSelectionHeader() {
    const compactDensity = VisualDensity.compact;
    const tightPadding = EdgeInsets.all(6);

    return Container(
      color: context.colors.primary.withValues(alpha: 0.08),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          IconButton(
            icon: Icon(CommonIcons.arrowBack, color: context.colors.textPrimary),
            visualDensity: compactDensity,
            padding: tightPadding,
            onPressed: () => setState(() => _selectedChatIds.clear()),
          ),
          CommonSpaces.w8,
          Flexible(
            child: Text(
              '${_selectedChatIds.length} selected',
              overflow: TextOverflow.ellipsis,
              style: context.titleLarge.copyWith(
                fontWeight: FontWeight.bold,
                color: context.colors.textPrimary,
              ),
            ),
          ),
          const Spacer(),
          IconButton(
            icon: Icon(
              _selectedChatIds.every((id) => _mutedChatIds.contains(id))
                  ? Icons.notifications_active_rounded
                  : Icons.notifications_off_rounded,
              color: context.colors.textPrimary,
            ),
            tooltip: _selectedChatIds.every((id) => _mutedChatIds.contains(id))
                ? 'Unmute Notifications'
                : 'Mute Notifications',
            visualDensity: compactDensity,
            padding: tightPadding,
            onPressed: _handleMuteSelected,
          ),
          IconButton(
            icon: Icon(Icons.archive_rounded, color: context.colors.textPrimary),
            tooltip: 'Hide Chats',
            visualDensity: compactDensity,
            padding: tightPadding,
            onPressed: _handleHideSelected,
          ),
          if (_shouldShowBlockAction())
            IconButton(
              icon: Icon(CommonIcons.block, color: context.colors.textPrimary),
              tooltip: 'Block Recipient',
              visualDensity: compactDensity,
              padding: tightPadding,
              onPressed: _handleBlockSelected,
            ),
          IconButton(
            icon: Icon(CommonIcons.deleteOutline, color: context.colors.error),
            tooltip: 'Delete Chats',
            visualDensity: compactDensity,
            padding: tightPadding,
            onPressed: _handleDeleteSelected,
          ),
        ],
      ),
    );
  }

  Future<void> _handleMuteSelected() async {
    final allMuted = _selectedChatIds.every((id) => _mutedChatIds.contains(id));
    final selectedIds = Set<String>.from(_selectedChatIds);
    final count = selectedIds.length;
    final action = allMuted ? 'Unmute' : 'Mute';
    final actionLower = allMuted ? 'unmute' : 'mute';

    // Confirmation popup
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(ctx).colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              allMuted ? Icons.notifications_active_rounded : Icons.notifications_off_rounded,
              color: context.colors.primary,
              size: 24,
            ),
            const SizedBox(width: 12),
            Text('$action Notifications?', style: context.titleLarge.copyWith(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          'Are you sure you want to $actionLower notifications for $count ${count == 1 ? 'chat' : 'chats'}?',
          style: context.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: TextStyle(color: context.colors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: context.colors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(action),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    // Optimistic UI update
    setState(() {
      if (allMuted) {
        _mutedChatIds.removeAll(selectedIds);
      } else {
        _mutedChatIds.addAll(selectedIds);
      }
      _selectedChatIds.clear();
    });

    int successCount = 0;
    int failCount = 0;

    for (final id in selectedIds) {
      try {
        final result = allMuted
            ? await getIt<DashboardRepository>().unmuteChat(id)
            : await getIt<DashboardRepository>().muteChat(id);
        result.when(
          success: (_) => successCount++,
          failure: (error, _) {
            failCount++;
            debugPrint('Mute/Unmute failed for $id: $error');
          },
        );
      } catch (e) {
        failCount++;
        debugPrint('Mute/Unmute exception for $id: $e');
      }
    }

    // Persist muted state locally
    try {
      final box = await Hive.openBox('muted_chats_box');
      await box.put('muted_list', _mutedChatIds.toList());
    } catch (_) {}

    if (mounted) {
      if (failCount == 0) {
        context.showSuccessNotification(
          allMuted
              ? '$count ${count == 1 ? 'chat' : 'chats'} unmuted'
              : '$count ${count == 1 ? 'chat' : 'chats'} muted',
        );
      } else {
        context.showInfoNotification(
          '$successCount succeeded, $failCount failed',
        );
      }
      // Refresh the chat list to sync server state
      context.read<ChatsBloc>().add(const FetchChats());
    }
  }

  Future<void> _handleHideSelected() async {
    final count = _selectedChatIds.length;
    setState(() {
      _hiddenChatIds.addAll(_selectedChatIds);
    });
    for (final id in _selectedChatIds) {
      await getIt<DashboardRepository>().hideChat(id);
    }
    if (mounted) {
      context.showSuccessNotification('$count chats hidden');
      context.read<ChatsBloc>().add(const FetchChats());
    }
    setState(() => _selectedChatIds.clear());
  }

  Future<void> _handleBlockSelected() async {
    final count = _selectedChatIds.length;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.colors.scaffoldBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Block Contacts?',
          style: context.titleLarge.copyWith(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Block the recipients of the $count selected chats? They will no longer be able to message or call you.',
          style: context.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: TextStyle(color: context.colors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Block', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    if (!mounted) return;

    try {
      final currentState = context.read<ChatsBloc>().state;
      if (currentState is ChatsLoaded) {
        final box = await Hive.openBox('blocked_users_box');
        final String? jsonString = box.get('blocked_list');
        List<dynamic> blockedList = [];
        if (jsonString != null) {
          blockedList = jsonDecode(jsonString);
        }

        int blockedCount = 0;
        for (final id in _selectedChatIds) {
          final chat = currentState.chats.firstWhere((c) => c.id == id);
          if (!chat.isGroup) {
            final result = await getIt<ProfileRepository>().blockUser(chat.recipient.id);
            await result.when(
              success: (_) {
                final exists = blockedList.any((e) => e['id'] == chat.recipient.id);
                if (!exists) {
                  blockedList.add({
                    'id': chat.recipient.id,
                    'name': chat.recipient.displayName,
                    'profilePictureUrl': chat.recipient.profilePictureUrl,
                    'colorValue': context.colors.primary.toARGB32(),
                  });
                  blockedCount++;
                }
              },
              failure: (error, _) {
                debugPrint('Failed to block user ${chat.recipient.id}: $error');
              },
            );
          }
        }
        await box.put('blocked_list', jsonEncode(blockedList));
        if (mounted) {
          context.showSuccessNotification(
            blockedCount > 0 ? '$blockedCount recipients blocked' : 'Recipients already blocked',
          );
        }
      }
    } catch (e) {
      debugPrint('Error blocking from selection: $e');
    }

    setState(() => _selectedChatIds.clear());
  }

  Future<void> _handleDeleteSelected() async {
    final count = _selectedChatIds.length;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.colors.scaffoldBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Delete Chats?',
          style: context.titleLarge.copyWith(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Delete the $count selected chats? This action cannot be undone.',
          style: context.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: TextStyle(color: context.colors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Delete', style: TextStyle(color: context.colors.error, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    if (!mounted) return;

    final chatsState = context.read<ChatsBloc>().state;
    List<ChatModel> selectedChats = [];
    if (chatsState is ChatsLoaded) {
      selectedChats = chatsState.chats.where((c) => _selectedChatIds.contains(c.id)).toList();
    }

    final selectedIds = Set<String>.from(_selectedChatIds);

    setState(() {
      _deletedChatIds.addAll(selectedIds);
      _selectedChatIds.clear();
    });

    try {
      for (final chat in selectedChats) {
        if (chat.isGroup) {
          final result = await getIt<DashboardRepository>().deleteGroup(chat.id);
          result.when(
            success: (_) {},
            failure: (error, statusCode) {
              debugPrint('Failed to delete group ${chat.id}: $error');
            },
          );
        } else {
          final result = await getIt<DashboardRepository>().deleteChat(chat.id);
          result.when(
            success: (_) {},
            failure: (error, statusCode) {
              debugPrint('Failed to delete chat ${chat.id}: $error');
            },
          );
        }
      }
      if (mounted) {
        context.showSuccessNotification('$count chats deleted');
        context.read<ChatsBloc>().add(const FetchChats());
      }
    } catch (e) {
      debugPrint('Error deleting chats: $e');
    }
  }

  Future<void> _loadProfile() async {
    // Immediate load from storage
    if (mounted) {
      setState(() {
        _username = getIt<StorageService>().getUsername() ?? 'David';
        _profilePicUrl = getIt<StorageService>().getProfilePic();
      });
    }

    // Background refresh from API
    getIt<ProfileRepository>().getProfile().then((result) {
      result.when(
        success: (user) {
          if (mounted) {
            setState(() {
              _username = user.username ?? 'David';
              _profilePicUrl = user.profilePictureUrl;
            });
            if (!user.isSubscribed) {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => SubscriptionPage()),
                (Route<dynamic> route) => false,
              );
            }
          }
        },
        failure: (_, statusCode) {},
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('DEBUG: Building DashboardPage');
    final isDark = context.colors.isDark;

    return Scaffold(
      backgroundColor: context.colors.scaffoldBackground,
      body: Stack(
        children: [
          // Full-screen background waves spanning all tabs behind status bar & bottom bar
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: HomeBackgroundWavePainter(isDark: isDark),
              ),
            ),
          ),
          SafeArea(
            child: IndexedStack(
              index: _currentIndex,
              children: [
                _buildChatsTab(),
                const StatusPage(),
                const CallHistoryPage(),
                UserListPage(
                  forceSync: _shouldSyncContacts,
                  showOnlySynced: _onlyShowSynced,
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildChatsTab() {
    return BlocListener<ChatsBloc, ChatsState>(
      listener: (context, state) {
        if (state is ChatsLoaded) {
          setState(() {
            _hiddenChatIds.clear();
            // Sync muted state from server
            final serverMuted = state.chats
                .where((c) => c.isMuted)
                .map((c) => c.id)
                .toSet();
            _mutedChatIds
              ..addAll(serverMuted)
              ..removeWhere((id) =>
                  state.chats.any((c) => c.id == id) &&
                  !serverMuted.contains(id));
          });
          // Persist in local storage
          Hive.openBox('muted_chats_box').then((box) {
            box.put('muted_list', _mutedChatIds.toList());
          }).catchError((_) {});
        } else if (state is ChatsError) {
          final msg = state.message.toLowerCase();
          if (msg.contains('subscription') || msg.contains('payment required')) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => SubscriptionPage()),
              (Route<dynamic> route) => false,
            );
          }
        }
      },
      child: BlocBuilder<ChatsBloc, ChatsState>(
        builder: (context, state) {
          debugPrint('DEBUG: DashboardPage ChatsBloc state: ${state.runtimeType}');
          final isSelectionMode = _selectedChatIds.isNotEmpty;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              isSelectionMode ? _buildSelectionHeader() : _buildHeader(),
              if (!isSelectionMode) ...[
                _buildSearchBar(),
                _buildFilterChips(),
              ],
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    context.read<ChatsBloc>().add(const FetchChats());
                    await Future.delayed(const Duration(seconds: 1));
                  },
                  child: state.maybeWhen(
                    loading: () {
                      debugPrint('DEBUG: DashboardPage showing loading');
                      return const Center(child: CircularProgressIndicator());
                    },
                    error: (message) {
                      debugPrint('DEBUG: DashboardPage showing error: $message');
                      return SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: Container(
                          height: MediaQuery.of(context).size.height * 0.7,
                          alignment: Alignment.center,
                          child: Text('Error: $message'),
                        ),
                      );
                    },
                    loaded: (chatList) {
                      debugPrint('DEBUG: DashboardPage showing loaded with ${chatList.length} chats');
                      final visibleChats = chatList
                          .where((c) => !_hiddenChatIds.contains(c.id) && !_deletedChatIds.contains(c.id))
                          .where((c) {
                            if (_filterIndex == 1) return c.unreadCount > 0;
                            if (_filterIndex == 2) return c.isGroup;
                            return true;
                          })
                          .toList();

                      final totalUnreadCount = chatList
                          .where((c) => !_hiddenChatIds.contains(c.id) && !_deletedChatIds.contains(c.id))
                          .fold<int>(0, (sum, c) => sum + c.unreadCount);

                      if (visibleChats.isEmpty && chatList.isEmpty) {
                        return SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: Container(
                            height: MediaQuery.of(context).size.height * 0.7,
                            alignment: Alignment.center,
                            child: EmptyChatsView(
                              onChatNowPressed: () {
                                setState(() {
                                  _currentIndex = 3;
                                });
                              },
                            ),
                          ),
                        );
                      }
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (!isSelectionMode) _buildSectionHeader(totalUnreadCount),
                          Expanded(child: _buildChatListFromFiltered(visibleChats)),
                        ],
                      );
                    },
                    orElse: () {
                      debugPrint('DEBUG: DashboardPage state orElse: ${state.runtimeType}');
                      return const Center(child: CircularProgressIndicator());
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    final isDark = context.colors.isDark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 16, 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProfileSettingsPage(
                      username: _username,
                      profilePicUrl: _profilePicUrl,
                    ),
                  ),
                );
                
                if (result == 'sync') {
                  setState(() {
                    _currentIndex = 3;
                    _shouldSyncContacts = true;
                    _onlyShowSynced = true;
                  });
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) setState(() => _shouldSyncContacts = false);
                  });
                }
                _loadProfile();
              },
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF00FF87).withValues(alpha: 0.15)
                          : const Color(0xFF00873C).withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFF00FF87).withValues(alpha: 0.4)
                            : const Color(0xFF00873C).withValues(alpha: 0.25),
                        width: 1.5,
                      ),
                    ),
                    child: ClipOval(
                      child: (_profilePicUrl != null && _profilePicUrl!.isNotEmpty)
                          ? CachedNetworkImage(
                              imageUrl: _profilePicUrl!,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Center(
                                child: Text(
                                  _username.isNotEmpty
                                      ? _username.substring(0, 1).toUpperCase()
                                      : 'U',
                                  style: TextStyle(
                                    color: isDark
                                        ? const Color(0xFF00FF87)
                                        : const Color(0xFF00873C),
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              errorWidget: (context, url, error) => Center(
                                child: Text(
                                  _username.isNotEmpty
                                      ? _username.substring(0, 1).toUpperCase()
                                      : 'U',
                                  style: TextStyle(
                                    color: isDark
                                        ? const Color(0xFF00FF87)
                                        : const Color(0xFF00873C),
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            )
                          : Center(
                              child: Text(
                                _username.isNotEmpty
                                    ? _username.substring(0, 1).toUpperCase()
                                    : 'U',
                                style: TextStyle(
                                    color: isDark
                                        ? const Color(0xFF00FF87)
                                        : const Color(0xFF00873C),
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "S-Chat",
                          style: TextStyle(
                            fontSize: 22,
                            color: isDark ? const Color(0xFF00FF87) : const Color(0xFF00873C),
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          "How are you today?",
                          style: TextStyle(
                            color: isDark ? Colors.white60 : const Color(0xFF6B7280),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          PopupMenuButton<String>(
            icon: Icon(
              Icons.more_vert_rounded,
              color: context.colors.textPrimary,
              size: 24,
            ),
            color: context.colors.scaffoldBackground,
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            onSelected: (value) async {
              if (value == 'theme') {
                getIt<ThemeController>().toggleTheme();
                setState(() {});
              } else if (value == 'create_group') {
                final chat = await showModalBottomSheet<ChatModel>(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (dialogCtx) => BlocProvider.value(
                    value: getIt<ContactsBloc>()..add(const LoadContacts()),
                    child: const CreateGroupBottomSheet(),
                  ),
                );
                if (chat != null && mounted) {
                  context.showSuccessNotification('Group created successfully');
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatPage(
                        conversationId: chat.id,
                        contactName: chat.groupName ?? 'Group',
                        contactColor: context.colors.primary,
                        isOnline: false,
                        recipientId: chat.id,
                        isGroup: true,
                        initialThemeColor: chat.themeColor,
                        initialDisappearingTimer: chat.disappearingTimer,
                      ),
                    ),
                  );
                }
              } else if (value == 'settings') {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProfileSettingsPage(
                      username: _username,
                      profilePicUrl: _profilePicUrl,
                    ),
                  ),
                );
                if (result == 'sync') {
                  setState(() {
                    _currentIndex = 3;
                    _shouldSyncContacts = true;
                    _onlyShowSynced = true;
                  });
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) setState(() => _shouldSyncContacts = false);
                  });
                }
                _loadProfile();
              } else if (value == 'hidden_chats') {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const HiddenChatsPage(),
                  ),
                );
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'theme',
                child: Row(
                  children: [
                    Icon(
                      getIt<ThemeController>().themeMode == ThemeMode.dark
                          ? Icons.light_mode_rounded
                          : Icons.dark_mode_rounded,
                      color: context.colors.primary,
                      size: 20,
                    ),
                    CommonSpaces.w12,
                    Text('Theme', style: context.bodyMedium.copyWith(color: context.colors.textPrimary)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'create_group',
                child: Row(
                  children: [
                    Icon(Icons.group_add_rounded, color: context.colors.primary, size: 20),
                    CommonSpaces.w12,
                    Text('Create Group', style: context.bodyMedium.copyWith(color: context.colors.textPrimary)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'hidden_chats',
                child: Row(
                  children: [
                    Icon(Icons.archive_rounded, color: context.colors.primary, size: 20),
                    CommonSpaces.w12,
                    Text('Hidden Chats', style: context.bodyMedium.copyWith(color: context.colors.textPrimary)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(CommonIcons.settings, color: context.colors.primary, size: 20),
                    CommonSpaces.w12,
                    Text('Settings', style: context.bodyMedium.copyWith(color: context.colors.textPrimary)),
                  ],
                ),
              ),
            ],
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
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ChatSearchPage()),
          );
        },
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
              Text(
                'Search conversations',
                style: TextStyle(
                  color: isDark ? Colors.white54 : const Color(0xFF6B7280),
                  fontSize: 15,
                  fontWeight: FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    final isDark = context.colors.isDark;
    final filterOptions = ['All', 'Unread', 'Groups'];
    final activeColor = isDark ? const Color(0xFF00FF87) : const Color(0xFF00873C);
    final activeTextColor = isDark ? Colors.black : Colors.white;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 8),
      child: Row(
        children: List.generate(filterOptions.length, (index) {
          final isSelected = _filterIndex == index;
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _filterIndex = index;
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
                child: Text(
                  filterOptions[index],
                  style: TextStyle(
                    color: isSelected
                        ? activeTextColor
                        : (isDark ? Colors.white70 : const Color(0xFF374151)),
                    fontSize: 13.5,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildSectionHeader(int unreadCount) {
    final isDark = context.colors.isDark;
    final primaryColor = isDark ? const Color(0xFF00FF87) : const Color(0xFF00873C);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(
                'Messages',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: context.colors.textPrimary,
                ),
              ),
              if (unreadCount > 0) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF00FF87).withValues(alpha: 0.18)
                        : const Color(0xFFD1FADF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    unreadCount > 99 ? '99+' : unreadCount.toString(),
                    style: TextStyle(
                      color: primaryColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ],
          ),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const HiddenChatsPage()),
              );
            },
            child: Row(
              children: [
                Icon(
                  Icons.inventory_2_outlined,
                  size: 18,
                  color: primaryColor,
                ),
                const SizedBox(width: 6),
                Text(
                  'Archive',
                  style: TextStyle(
                    color: primaryColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
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
        return Stack(
          children: [
            Container(
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
            ),
          ],
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
                primaryColor.withValues(alpha: 0.25),
                '👨🏻‍💻',
              ),
            ),
            Positioned(
              right: 2,
              top: 2,
              child: _buildSmallAvatar(
                context.colors.pinkAccent.withValues(alpha: 0.25),
                '👩🏼‍💻',
              ),
            ),
            Positioned(
              left: 2,
              bottom: 2,
              child: _buildSmallAvatar(
                context.colors.orangeAccent.withValues(alpha: 0.25),
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

  Widget _buildChatListFromFiltered(List<ChatModel> visibleChats) {
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(top: 4, bottom: 80),
      itemCount: visibleChats.length,
      separatorBuilder: (context, index) => Divider(
        height: 1,
        thickness: 0.6,
        indent: 84,
        endIndent: 20,
        color: context.colors.isDark
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
        );
      },
    );
  }

  Widget _buildChatTile({
    required ChatModel chat,
    required String name,
    required String message,
  }) {
    final isSelected = _selectedChatIds.contains(chat.id);
    final isSelectionMode = _selectedChatIds.isNotEmpty;
    final isDark = context.colors.isDark;

    return InkWell(
      onTap: () async {
        if (isSelectionMode) {
          setState(() {
            if (isSelected) {
              _selectedChatIds.remove(chat.id);
            } else {
              _selectedChatIds.add(chat.id);
            }
          });
        } else {
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
        }
      },
      onLongPress: () {
        setState(() {
          if (isSelected) {
            _selectedChatIds.remove(chat.id);
          } else {
            _selectedChatIds.add(chat.id);
          }
        });
      },
      child: Container(
        color: isSelected
            ? context.colors.primary.withValues(alpha: 0.1)
            : Colors.transparent,
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
                    name,
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
                          message,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: chat.isTyping
                                ? const Color(0xFF12B76A)
                                : (isSelected
                                    ? context.colors.primary
                                    : (isDark ? Colors.white60 : const Color(0xFF6B7280))),
                            fontWeight: chat.isTyping ? FontWeight.w600 : FontWeight.normal,
                            fontSize: 13.5,
                          ),
                        ),
                      ),
                      if (_mutedChatIds.contains(chat.id)) ...[
                        const SizedBox(width: 8),
                        Icon(
                          Icons.notifications_off_rounded,
                          size: 16,
                          color: context.colors.textHint,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            _buildChatStatus(chat),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    final isDark = context.colors.isDark;
    return Container(
      decoration: BoxDecoration(
        color: context.colors.scaffoldBackground,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(
              index: 0,
              icon: Icons.chat_bubble_outline_rounded,
              activeIcon: Icons.chat_bubble_rounded,
              label: 'Messages',
            ),
            _buildNavItem(
              index: 1,
              icon: Icons.motion_photos_on_outlined,
              activeIcon: Icons.motion_photos_on_rounded,
              label: 'Status',
            ),
            _buildNavItem(
              index: 2,
              icon: Icons.call_outlined,
              activeIcon: Icons.phone_rounded,
              label: 'Calls',
            ),
            _buildNavItem(
              index: 3,
              icon: Icons.person_add_outlined,
              activeIcon: Icons.person_add_alt_1_rounded,
              label: 'New Chat',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
  }) {
    final isActive = _currentIndex == index;
    final isDark = context.colors.isDark;
    final primaryColor = isDark ? const Color(0xFF00FF87) : const Color(0xFF00873C);
    final activePillColor = isDark
        ? const Color(0xFF00FF87).withValues(alpha: 0.18)
        : const Color(0xFFD1FADF);

    return GestureDetector(
      onTap: () {
        setState(() {
          _currentIndex = index;
          if (index == 0) {
            context.read<ChatsBloc>().add(const FetchChats());
          } else if (index == 3) {
            _onlyShowSynced = false;
          }
        });
      },
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            decoration: BoxDecoration(
              color: isActive ? activePillColor : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              isActive ? activeIcon : icon,
              size: 22,
              color: isActive
                  ? primaryColor
                  : (isDark ? Colors.white60 : const Color(0xFF6B7280)),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              color: isActive
                  ? primaryColor
                  : (isDark ? Colors.white60 : const Color(0xFF6B7280)),
            ),
          ),
        ],
      ),
    );
  }
}

class HomeBackgroundWavePainter extends CustomPainter {
  final bool isDark;
  HomeBackgroundWavePainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    if (isDark) {
      _paintDarkTheme(canvas, size);
    } else {
      _paintLightTheme(canvas, size);
    }
  }

  void _paintLightTheme(Canvas canvas, Size size) {
    // 1. Soft mint background ambient glow for Top-Right
    final trGlowRect = Rect.fromLTWH(size.width * 0.4, 0, size.width * 0.6, 200);
    final trGlowPaint = Paint()
      ..shader = const RadialGradient(
        center: Alignment.topRight,
        radius: 1.1,
        colors: [
          Color(0x38D1FADF),
          Color(0x15D1FADF),
          Color(0x00FFFFFF),
        ],
        stops: [0.0, 0.6, 1.0],
      ).createShader(trGlowRect)
      ..style = PaintingStyle.fill;
    canvas.drawRect(trGlowRect, trGlowPaint);

    // 2. Top-Right flowing wave lines ribbon
    const int trLineCount = 22;
    for (int i = 0; i < trLineCount; i++) {
      final t = i / (trLineCount - 1);
      final alpha = (0.12 + 0.30 * (1 - (t - 0.5).abs() * 2)).clamp(0.08, 0.42);

      final Color lineColor;
      if (i % 3 == 0) {
        lineColor = const Color(0xFF00873C).withValues(alpha: alpha);
      } else if (i % 3 == 1) {
        lineColor = const Color(0xFF12B76A).withValues(alpha: alpha);
      } else {
        lineColor = const Color(0xFF34D399).withValues(alpha: alpha);
      }

      final linePaint = Paint()
        ..color = lineColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0 + 0.3 * (1 - t);

      final path = Path();
      final startX = size.width * (0.32 + 0.68 * t);
      final startY = 0.0;
      final control1X = size.width * (0.48 + 0.48 * t);
      final control1Y = 25.0 + 65.0 * (1 - t);
      final control2X = size.width * (0.72 + 0.26 * t);
      final control2Y = 35.0 + 75.0 * (1 - t);
      final endX = size.width;
      final endY = 10.0 + 115.0 * t;

      path.moveTo(startX, startY);
      path.cubicTo(control1X, control1Y, control2X, control2Y, endX, endY);
      canvas.drawPath(path, linePaint);
    }

    // 3. Soft mint background ambient glow for Bottom-Left
    final blGlowRect = Rect.fromLTWH(0, size.height - 220, size.width * 0.65, 220);
    final blGlowPaint = Paint()
      ..shader = const RadialGradient(
        center: Alignment.bottomLeft,
        radius: 1.1,
        colors: [
          Color(0x35D1FADF),
          Color(0x12D1FADF),
          Color(0x00FFFFFF),
        ],
        stops: [0.0, 0.6, 1.0],
      ).createShader(blGlowRect)
      ..style = PaintingStyle.fill;
    canvas.drawRect(blGlowRect, blGlowPaint);

    // 4. Bottom-Left flowing wave lines ribbon
    const int blLineCount = 22;
    for (int i = 0; i < blLineCount; i++) {
      final t = i / (blLineCount - 1);
      final alpha = (0.12 + 0.30 * (1 - (t - 0.5).abs() * 2)).clamp(0.08, 0.42);

      final Color lineColor;
      if (i % 3 == 0) {
        lineColor = const Color(0xFF00873C).withValues(alpha: alpha);
      } else if (i % 3 == 1) {
        lineColor = const Color(0xFF12B76A).withValues(alpha: alpha);
      } else {
        lineColor = const Color(0xFF34D399).withValues(alpha: alpha);
      }

      final linePaint = Paint()
        ..color = lineColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0 + 0.3 * (1 - t);

      final path = Path();
      final startX = 0.0;
      final startY = size.height - (165.0 * (1 - t) + 15.0);
      final control1X = size.width * (0.12 + 0.28 * t);
      final control1Y = size.height - (125.0 * (1 - t) + 20.0);
      final control2X = size.width * (0.32 + 0.32 * t);
      final control2Y = size.height - (55.0 * (1 - t) + 10.0);
      final endX = size.width * (0.28 + 0.44 * t);
      final endY = size.height - (8.0 + 15.0 * t);

      path.moveTo(startX, startY);
      path.cubicTo(control1X, control1Y, control2X, control2Y, endX, endY);
      canvas.drawPath(path, linePaint);
    }
  }

  void _paintDarkTheme(Canvas canvas, Size size) {
    // Top-Right Dark Mode Emerald lines
    const int trLineCount = 18;
    for (int i = 0; i < trLineCount; i++) {
      final t = i / (trLineCount - 1);
      final alpha = (0.06 + 0.14 * (1 - (t - 0.5).abs() * 2)).clamp(0.04, 0.20);
      final linePaint = Paint()
        ..color = const Color(0xFF00FF87).withValues(alpha: alpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;

      final path = Path();
      final startX = size.width * (0.35 + 0.65 * t);
      final startY = 0.0;
      final control1X = size.width * (0.50 + 0.46 * t);
      final control1Y = 25.0 + 65.0 * (1 - t);
      final control2X = size.width * (0.72 + 0.26 * t);
      final control2Y = 35.0 + 75.0 * (1 - t);
      final endX = size.width;
      final endY = 10.0 + 115.0 * t;

      path.moveTo(startX, startY);
      path.cubicTo(control1X, control1Y, control2X, control2Y, endX, endY);
      canvas.drawPath(path, linePaint);
    }

    // Bottom-Left Dark Mode Emerald lines
    const int blLineCount = 18;
    for (int i = 0; i < blLineCount; i++) {
      final t = i / (blLineCount - 1);
      final alpha = (0.06 + 0.14 * (1 - (t - 0.5).abs() * 2)).clamp(0.04, 0.20);
      final linePaint = Paint()
        ..color = const Color(0xFF00FF87).withValues(alpha: alpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;

      final path = Path();
      final startX = 0.0;
      final startY = size.height - (165.0 * (1 - t) + 15.0);
      final control1X = size.width * (0.12 + 0.28 * t);
      final control1Y = size.height - (125.0 * (1 - t) + 20.0);
      final control2X = size.width * (0.32 + 0.32 * t);
      final control2Y = size.height - (55.0 * (1 - t) + 10.0);
      final endX = size.width * (0.28 + 0.44 * t);
      final endY = size.height - (8.0 + 15.0 * t);

      path.moveTo(startX, startY);
      path.cubicTo(control1X, control1Y, control2X, control2Y, endX, endY);
      canvas.drawPath(path, linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant HomeBackgroundWavePainter oldDelegate) =>
      oldDelegate.isDark != isDark;
}
