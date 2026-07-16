import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';
import 'package:schat/core/storage/storage_service.dart';
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
import 'package:schat/utils/common_sizes.dart';
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
                    'colorValue': context.colors.primary.value,
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
    return Scaffold(
      backgroundColor: context.colors.scaffoldBackground,
      body: SafeArea(
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
            children: [
              isSelectionMode ? _buildSelectionHeader() : _buildHeader(),
              if (!isSelectionMode) _buildSearchBar(),
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
                      if (chatList.isEmpty) {
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
                      return _buildChatList(chatList);
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        ProfileSettingsPage(
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
                    width: CommonSizes.p32,
                    height: CommonSizes.p32,
                    decoration: BoxDecoration(
                      color: context.colors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: ClipOval(
                      child: (_profilePicUrl != null && _profilePicUrl!.isNotEmpty)
                          ? Image.network(
                              _profilePicUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Icon(CommonIcons.person, color: context.colors.primary, size: 20),
                            )
                          : Icon(CommonIcons.person, color: context.colors.primary, size: 20),
                    ),
                  ),
                  CommonSpaces.w12,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "S-Chat",
                          style: context.h2.copyWith(
                            fontSize: 22,
                            color: context.colors.primary,
                            fontWeight: FontWeight.w900,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          "How are you today?",
                          style: context.bodyMedium.copyWith(
                            color: context.colors.textSecondary,
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
              CommonIcons.moreVert,
              color: context.colors.textPrimary,
              size: 28,
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
    final searchBgColor = context.colors.isDark 
        ? context.colors.pureWhite.withValues(alpha: 0.1)
        : context.colors.primary.withValues(alpha: 0.05);
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
      final groupPic = chat.recipient.profilePictureUrl;
      if (groupPic != null && groupPic.isNotEmpty) {
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
                child: Image.network(
                  groupPic,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Center(
                      child: Icon(Icons.group_rounded, color: color, size: 24),
                    );
                  },
                ),
              ),
            ),
          ],
        );
      }

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
        if (chat.unreadCount > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: context.colors.primary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              chat.unreadCount.toString(),
              style: context.bodySmall.copyWith(
                color: context.colors.pureWhite,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          )
        else
          Icon(CommonIcons.doneAll, color: context.colors.primary, size: 18),
      ],
    );
  }

  Widget _buildChatList(List<ChatModel> chatList) {
    final visibleChats = chatList
        .where((c) => !_hiddenChatIds.contains(c.id) && !_deletedChatIds.contains(c.id))
        .toList();
    
    debugPrint('DEBUG: DashboardPage building chat list with ${visibleChats.length} visible chats');

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(top: 12, bottom: 80),
      itemCount: visibleChats.length,
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

        return _buildSwipeableChat(
          chat: chat,
          name: name,
          message: message,
        );
      },
    );
  }

  Widget _buildSwipeableChat({
    required ChatModel chat,
    required String name,
    required String message,
  }) {
    return _buildChatTile(chat: chat, name: name, message: message);
  }

  Widget _buildChatTile({
    required ChatModel chat,
    required String name,
    required String message,
  }) {
    final isSelected = _selectedChatIds.contains(chat.id);
    final isSelectionMode = _selectedChatIds.isNotEmpty;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
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
        color: isSelected ? context.colors.primary.withValues(alpha: 0.08) : Colors.transparent,
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
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          message,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.bodyMedium.copyWith(
                            color: chat.isTyping
                                ? const Color(0xFF34C759)
                                : (isSelected 
                                    ? context.colors.primary 
                                    : context.colors.textSecondary.withValues(alpha: 0.7)),
                            fontWeight: chat.isTyping ? FontWeight.w600 : FontWeight.normal,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      if (_mutedChatIds.contains(chat.id)) ...[
                        CommonSpaces.w8,
                        Icon(Icons.notifications_off_rounded, size: 16, color: context.colors.textHint),
                      ],
                    ],
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
            if (index == 0) {
              context.read<ChatsBloc>().add(const FetchChats());
            } else if (index == 3) {
              _onlyShowSynced = false; // Reset to show all when tapped manually
            }
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
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: context.bodyMedium.copyWith(
          fontSize: 11,
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
            width: 20,
            height: 20,
            color: isActive ? context.colors.primary : context.colors.textHint,
          ),
        ],
      ),
      label: label,
    );
  }
}
