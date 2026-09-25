import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:schat/features/dashboard_screen/src/presentation/user_list_page.dart';
import 'package:schat/features/profile_screen/src/domain/models/user_model.dart';
import 'package:schat/features/profile_screen/src/domain/repositories/profile_repository.dart';
import 'package:schat/features/dashboard_screen/src/presentation/dashboard_page.dart';
import 'package:schat/injection.dart';
import 'package:schat/utils/common_colors.dart';
import 'package:schat/utils/common_fontstyles.dart';
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
        backgroundColor: context.colors.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Text(
          'Unblock $userName?',
          style: context.titleLarge.copyWith(fontWeight: FontWeight.bold, color: context.colors.textPrimary),
        ),
        content: Text(
          'They will be able to call you and send you messages.',
          style: TextStyle(color: context.colors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: TextStyle(color: context.colors.textHint)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00873C),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Unblock', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _unblockUser(userId, userName);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.colors.isDark;

    return Scaffold(
      backgroundColor: context.colors.scaffoldBackground,
      body: Stack(
        children: [
          // Home Wave Lines Background matching Home Screen
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: HomeBackgroundWavePainter(isDark: isDark),
              ),
            ),
          ),

          // Main Content
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context),
                _buildSearchBar(),
                Expanded(
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(color: Color(0xFF00873C)),
                        )
                      : _blockedList.isEmpty
                          ? _buildEmptyState()
                          : _buildBlockedList(),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addBlockedUser,
        backgroundColor: const Color(0xFF00873C),
        foregroundColor: Colors.white,
        elevation: 4,
        icon: const Icon(Icons.person_add_rounded, size: 22),
        label: const Text(
          'Block Contact',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: context.colors.lightBackground,
                  border: Border.all(
                    color: context.colors.border.withValues(alpha: 0.3),
                  ),
                ),
                child: IconButton(
                  icon: Icon(Icons.arrow_back_rounded, color: context.colors.textPrimary, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              CommonSpaces.w12,
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Blocked Contacts',
                    style: context.h2.copyWith(
                      fontWeight: FontWeight.bold,
                      color: context.colors.textPrimary,
                    ),
                  ),
                  if (!_isLoading && _blockedList.isNotEmpty)
                    Text(
                      '${_blockedList.length} ${_blockedList.length == 1 ? 'contact' : 'contacts'}',
                      style: TextStyle(
                        color: context.colors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ],
          ),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFE8F5E9),
              border: Border.all(
                color: const Color(0xFF00873C).withValues(alpha: 0.3),
              ),
            ),
            child: IconButton(
              icon: const Icon(Icons.person_add_rounded, color: Color(0xFF00873C), size: 20),
              tooltip: 'Add Blocked Contact',
              onPressed: _addBlockedUser,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Container(
        decoration: BoxDecoration(
          color: context.colors.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: context.colors.border.withValues(alpha: 0.4),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (value) {
            setState(() {
              _searchQuery = value;
            });
          },
          style: TextStyle(color: context.colors.textPrimary),
          decoration: InputDecoration(
            hintText: 'Search blocked contacts...',
            hintStyle: TextStyle(color: context.colors.textHint, fontSize: 14),
            prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF00873C), size: 20),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.clear, color: context.colors.textHint, size: 18),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {
                        _searchQuery = '';
                      });
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: const BoxDecoration(
                color: Color(0xFFE8F5E9),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.block_rounded,
                size: 42,
                color: Color(0xFF00873C),
              ),
            ),
            CommonSpaces.h20,
            Text(
              'No Blocked Contacts',
              style: context.titleLarge.copyWith(fontWeight: FontWeight.bold),
            ),
            CommonSpaces.h8,
            Text(
              'Contacts you block will appear here. They will not be able to message or call you on Schat.',
              textAlign: TextAlign.center,
              style: TextStyle(color: context.colors.textSecondary, fontSize: 14, height: 1.4),
            ),
            CommonSpaces.h24,
            ElevatedButton.icon(
              onPressed: _addBlockedUser,
              icon: const Icon(Icons.person_add_rounded, size: 20),
              label: const Text('Block a Contact'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00873C),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                elevation: 2,
              ),
            ),
          ],
        ),
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
          style: TextStyle(color: context.colors.textSecondary, fontSize: 14),
        ),
      );
    }

    final isDark = context.colors.isDark;

    return ListView.builder(
      itemCount: filteredList.length,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      itemBuilder: (context, index) {
        final user = filteredList[index];
        final String userId = user['id'] ?? '';
        final String name = user['name'] ?? 'Blocked User';
        final String? phone = user['phoneNumber'];
        final String? avatarUrl = user['profilePictureUrl'];

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
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: const Color(0xFFFFEBEE),
                  backgroundImage: (avatarUrl != null && avatarUrl.isNotEmpty)
                      ? NetworkImage(avatarUrl)
                      : null,
                  child: (avatarUrl == null || avatarUrl.isEmpty)
                      ? Text(
                          name.isNotEmpty ? name.substring(0, 1).toUpperCase() : 'B',
                          style: const TextStyle(
                            color: Color(0xFFE53935),
                            fontWeight: FontWeight.bold,
                            fontSize: 17,
                          ),
                        )
                      : null,
                ),
                CommonSpaces.w12,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: context.colors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (phone != null && phone.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          phone,
                          style: TextStyle(
                            color: context.colors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () => _showUnblockDialog(userId, name),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE8F5E9),
                    foregroundColor: const Color(0xFF00873C),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: const BorderSide(color: Color(0xFF00873C), width: 1),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  ),
                  child: const Text(
                    'Unblock',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
