import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:schat/features/dashboard_screen/src/presentation/user_list_page.dart';
import 'package:schat/features/profile_screen/src/domain/models/user_model.dart';
import 'package:schat/features/profile_screen/src/domain/repositories/profile_repository.dart';
import 'package:schat/injection.dart';
import 'package:schat/utils/common_colors.dart';
import 'package:schat/utils/common_fontstyles.dart';
import 'package:schat/utils/common_icons.dart';
import 'package:schat/utils/common_spaces.dart';
import 'package:schat/utils/common_notifications.dart';

class BlockedUsersPage extends StatefulWidget {
  const BlockedUsersPage({super.key});

  @override
  State<BlockedUsersPage> createState() => _BlockedUsersPageState();
}

class _BlockedUsersPageState extends State<BlockedUsersPage> {
  List<dynamic> _blockedList = [];
  bool _isLoading = true;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadBlockedList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadBlockedList() async {
    // First load from local Hive as quick fallback
    try {
      final box = await Hive.openBox('blocked_users_box');
      final String? jsonString = box.get('blocked_list');
      if (jsonString != null) {
        setState(() {
          _blockedList = jsonDecode(jsonString);
          _isLoading = false;
        });
      }
    } catch (_) {}

    // Fetch from backend
    try {
      final result = await getIt<ProfileRepository>().getBlockedUsers();
      result.when(
        success: (users) async {
          final mappedList = users.map((user) => {
            'id': user.id,
            'name': user.displayName,
            'phoneNumber': user.phoneNumber,
            'profilePictureUrl': user.profilePictureUrl,
          }).toList();

          final box = await Hive.openBox('blocked_users_box');
          await box.put('blocked_list', jsonEncode(mappedList));

          if (mounted) {
            setState(() {
              _blockedList = mappedList;
              _isLoading = false;
            });
          }
        },
        failure: (error, _) {
          debugPrint('Backend blocked list fetch failed: $error');
          if (mounted) {
            setState(() => _isLoading = false);
          }
        },
      );
    } catch (e) {
      debugPrint('Error fetching blocked list: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _unblockUser(String userId, String userName) async {
    try {
      final result = await getIt<ProfileRepository>().unblockUser(userId);
      result.when(
        success: (_) async {
          final box = await Hive.openBox('blocked_users_box');
          final String? jsonString = box.get('blocked_list');
          if (jsonString != null) {
            final List<dynamic> blockedList = jsonDecode(jsonString);
            blockedList.removeWhere((e) => e['id'] == userId);
            await box.put('blocked_list', jsonEncode(blockedList));
            setState(() {
              _blockedList = blockedList;
            });
            if (mounted) {
              context.showSuccessNotification('$userName unblocked');
            }
          }
        },
        failure: (error, _) {
          if (mounted) {
            context.showErrorNotification('Failed to unblock: $error');
          }
        },
      );
    } catch (e) {
      debugPrint('Error unblocking user: $e');
    }
  }

  Future<void> _addBlockedUser() async {
    final List<UserModel>? selected = await Navigator.push<List<UserModel>>(
      context,
      MaterialPageRoute(
        builder: (context) => const UserListPage(
          isPicker: true,
          maxSelection: 1,
          showOnlySynced: true,
        ),
      ),
    );

    if (selected != null && selected.isNotEmpty) {
      final selectedUser = selected.first;
      final userName = selectedUser.username ?? selectedUser.phoneNumber;
      
      // Prevent blocking already blocked users
      if (_blockedList.any((u) => u['id'] == selectedUser.id)) {
        if (mounted) {
          context.showErrorNotification('$userName is already blocked');
        }
        return;
      }

      setState(() => _isLoading = true);
      try {
        final result = await getIt<ProfileRepository>().blockUser(selectedUser.id);
        result.when(
          success: (_) async {
            if (mounted) {
              context.showSuccessNotification('$userName blocked');
            }
            await _loadBlockedList();
          },
          failure: (error, _) {
            if (mounted) {
              context.showErrorNotification('Failed to block: $error');
            }
            setState(() => _isLoading = false);
          },
        );
      } catch (e) {
        debugPrint('Error blocking user: $e');
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  Future<void> _showUnblockDialog(String userId, String userName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.colors.scaffoldBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Unblock $userName?',
          style: context.titleLarge.copyWith(fontWeight: FontWeight.bold),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: TextStyle(color: context.colors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Unblock', style: TextStyle(color: context.colors.primary, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _unblockUser(userId, userName);
    }
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: context.colors.scaffoldBackground,
      elevation: 0,
      foregroundColor: context.colors.textPrimary,
      leading: IconButton(
        icon: Icon(CommonIcons.arrowBack),
        onPressed: () => Navigator.pop(context),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Blocked contacts',
            style: context.titleMedium.copyWith(fontWeight: FontWeight.bold),
          ),
          if (!_isLoading)
            Text(
              '${_blockedList.length} ${_blockedList.length == 1 ? 'contact' : 'contacts'}',
              style: context.bodySmall.copyWith(
                color: context.colors.textSecondary,
                fontSize: 12,
              ),
            ),
        ],
      ),
      actions: [
        IconButton(
          icon: Icon(CommonIcons.personAdd),
          tooltip: 'Add Blocked Contact',
          onPressed: _addBlockedUser,
        ),
      ],
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
        child: TextField(
          controller: _searchController,
          onChanged: (value) {
            setState(() {
              _searchQuery = value;
            });
          },
          decoration: InputDecoration(
            hintText: 'Search blocked contacts...',
            hintStyle: context.bodyLarge.copyWith(
              color: context.colors.textHint.withValues(alpha: 0.7),
            ),
            prefixIcon: Icon(
              CommonIcons.search,
              color: context.colors.textHint.withValues(alpha: 0.7),
            ),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: Icon(CommonIcons.close, size: 20),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {
                        _searchQuery = '';
                      });
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.scaffoldBackground,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _blockedList.isEmpty
                    ? _buildEmptyState()
                    : _buildBlockedList(),
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
            CommonIcons.block,
            size: 64,
            color: context.colors.textSecondary.withValues(alpha: 0.5),
          ),
          CommonSpaces.h16,
          Text(
            'No blocked users',
            style: context.titleMedium.copyWith(
              color: context.colors.textSecondary,
              fontWeight: FontWeight.bold,
            ),
          ),
          CommonSpaces.h8,
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Contacts you block will be listed here and will not be able to message or call you.',
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

  Widget _buildBlockedList() {
    final filteredList = _blockedList.where((user) {
      final String name = (user['name'] ?? '').toString().toLowerCase();
      final String phone = (user['phoneNumber'] ?? '').toString().toLowerCase();
      final query = _searchQuery.toLowerCase();
      return name.contains(query) || phone.contains(query);
    }).toList();

    if (filteredList.isEmpty) {
      return Center(
        child: Text(
          'No matching contacts found',
          style: context.bodyMedium.copyWith(color: context.colors.textSecondary),
        ),
      );
    }

    return ListView.separated(
      itemCount: filteredList.length,
      padding: const EdgeInsets.symmetric(vertical: 8),
      separatorBuilder: (context, index) => Divider(
        height: 1,
        color: context.colors.textHint.withValues(alpha: 0.1),
      ),
      itemBuilder: (context, index) {
        final user = filteredList[index];
        final String userId = user['id'] ?? '';
        final String name = user['name'] ?? 'Blocked User';
        final String? phone = user['phoneNumber'];
        final String? avatarUrl = user['profilePictureUrl'];

        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          onTap: () => _showUnblockDialog(userId, name),
          leading: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: context.colors.primary.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: ClipOval(
              child: (avatarUrl != null && avatarUrl.isNotEmpty)
                  ? Image.network(
                      avatarUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Center(
                        child: Text(
                          name.isNotEmpty ? name.substring(0, 1).toUpperCase() : 'B',
                          style: context.bodyMedium.copyWith(
                            color: context.colors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    )
                  : Center(
                      child: Text(
                        name.isNotEmpty ? name.substring(0, 1).toUpperCase() : 'B',
                        style: context.bodyMedium.copyWith(
                          color: context.colors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
            ),
          ),
          title: Text(
            name,
            style: context.bodyMedium.copyWith(
              fontWeight: FontWeight.bold,
              color: context.colors.textPrimary,
            ),
          ),
          subtitle: phone != null && phone.isNotEmpty
              ? Text(
                  phone,
                  style: context.bodySmall.copyWith(
                    color: context.colors.textSecondary,
                  ),
                )
              : null,
          trailing: OutlinedButton(
            onPressed: () => _showUnblockDialog(userId, name),
            style: OutlinedButton.styleFrom(
              foregroundColor: context.colors.primary,
              side: BorderSide(color: context.colors.primary),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
              minimumSize: const Size(80, 32),
            ),
            child: Text(
              'Unblock',
              style: context.bodySmall.copyWith(
                color: context.colors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      },
    );
  }
}
