import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:schat/features/chat_screen/src/presentation/bloc/chat_bloc.dart';
import 'package:schat/features/chat_screen/src/presentation/bloc/chat_state.dart';
import 'package:schat/utils/common_colors.dart';
import 'package:schat/utils/common_fontstyles.dart';
import 'package:schat/utils/common_icons.dart';
import 'package:schat/utils/common_spaces.dart';
import 'package:schat/utils/common_notifications.dart';

import 'package:schat/features/chat_screen/src/presentation/contact_profile_page.dart';
import 'package:schat/features/profile_screen/src/domain/models/user_model.dart';
import 'package:schat/core/storage/storage_service.dart';
import 'package:schat/features/chat_screen/src/domain/repositories/chat_repository.dart';
import 'package:schat/features/chat_screen/src/presentation/bloc/chat_event.dart';
import 'package:schat/features/dashboard_screen/src/presentation/user_list_page.dart';
import 'package:schat/features/dashboard_screen/src/presentation/bloc/contacts_bloc.dart';
import 'package:schat/features/profile_screen/src/domain/repositories/profile_repository.dart';
import 'package:schat/injection.dart';

class GroupInfoPage extends StatefulWidget {
  final String conversationId;
  final String groupName;
  final String? groupDescription;
  final Color groupColor;

  const GroupInfoPage({
    super.key,
    required this.conversationId,
    required this.groupName,
    this.groupDescription,
    required this.groupColor,
  });

  @override
  State<GroupInfoPage> createState() => _GroupInfoPageState();
}

class _GroupInfoPageState extends State<GroupInfoPage> {
  final String _myId = getIt<StorageService>().getUserId() ?? '';
  bool _isLoading = true;
  Map<String, dynamic>? _groupData;
  List<UserModel> _participants = [];
  bool _isAdmin = false;
  int? _disappearingTimer;

  @override
  void initState() {
    super.initState();
    _fetchGroupDetails();
  }

  Future<void> _fetchGroupDetails() async {
    try {
      final repo = getIt<ChatRepository>();
      final data = await repo.getGroupDetails(widget.conversationId);
      
      if (mounted) {
        setState(() {
          _isAdmin = false;
          _groupData = data;
          _disappearingTimer = data['timer_seconds'] ?? data['disappearing_timer'];
          final participantsData = data['participants'];
          if (participantsData is List) {
            _participants = participantsData.map((p) {
              if (p is Map) {
                final userJson = p['user'] ?? p;
                if (userJson is Map) {
                  final user = UserModel.fromJson(Map<String, dynamic>.from(userJson));
                  if (user.id == _myId && p['is_admin'] == true) {
                    _isAdmin = true;
                  }
                  return user;
                }
              }
              return const UserModel();
            }).where((u) => u.id.isNotEmpty).toList();
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching group details: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading group info: $e')),
        );
      }
    }
  }

  Future<void> _editGroupName() => _showEditGroupBottomSheet();
  Future<void> _editGroupDescription() => _showEditGroupBottomSheet();
  Future<void> _updateGroupIcon() => _showEditGroupBottomSheet();

  Future<void> _showEditGroupBottomSheet() async {
    final currentName = _groupData?['name'] ?? widget.groupName;
    final currentDesc = _groupData?['description'] ?? _groupData?['group_description'] ?? widget.groupDescription;
    final currentIcon = _groupData?['groupPictureUrl'] ?? _groupData?['groupImageUrl'] ?? _groupData?['icon_url'] ?? _groupData?['group_picture_url'];

    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _EditGroupBottomSheet(
        groupId: widget.conversationId,
        currentName: currentName,
        currentDescription: currentDesc,
        currentIconUrl: currentIcon,
        groupColor: widget.groupColor,
      ),
    );

    if (result != null && mounted) {
      final String newName = result['name'];
      final String newDesc = result['description'];
      final String? newIcon = result['iconUrl'];

      context.read<ChatBloc>().add(UpdateGroupInfoEvent(
        groupId: widget.conversationId,
        name: newName != currentName ? newName : null,
        description: newDesc != currentDesc ? newDesc : null,
        iconUrl: newIcon != currentIcon ? newIcon : null,
      ));

      setState(() {
        if (_groupData != null) {
          _groupData!['name'] = newName;
          _groupData!['description'] = newDesc;
          _groupData!['group_description'] = newDesc;
          if (newIcon != null) {
            _groupData!['icon_url'] = newIcon;
            _groupData!['groupPictureUrl'] = newIcon;
            _groupData!['groupImageUrl'] = newIcon;
          }
        }
      });
    }
  }

  void _removeParticipant(String userId, String userName) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20,
        ),
        decoration: BoxDecoration(
          color: context.colors.scaffoldBackground,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: context.colors.textSecondary.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            CommonSpaces.h16,
            Text(
              'Remove Participant',
              style: context.titleLarge.copyWith(fontWeight: FontWeight.bold, color: Colors.red),
            ),
            CommonSpaces.h12,
            Text(
              'Are you sure you want to remove $userName from this group?',
              style: context.bodyLarge.copyWith(color: context.colors.textPrimary),
            ),
            CommonSpaces.h24,
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(sheetContext),
                  child: Text('Cancel', style: TextStyle(color: context.colors.textSecondary)),
                ),
                CommonSpaces.w12,
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(sheetContext);
                    context.read<ChatBloc>().add(RemoveGroupParticipantEvent(
                      groupId: widget.conversationId,
                      userId: userId,
                    ));
                    setState(() {
                      _participants.removeWhere((u) => u.id == userId);
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Remove', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _exitGroup() {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Exit Group'),
        content: const Text('Are you sure you want to exit this group?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogCtx);
              context.read<ChatBloc>().add(RemoveGroupParticipantEvent(
                groupId: widget.conversationId,
                userId: _myId,
              ));
              Navigator.pop(context); // Close group info page using outer context
              Navigator.pop(context); // Close chat page using outer context
            },
            child: const Text('Exit', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _deleteGroup() {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Delete Group'),
        content: const Text('Are you sure you want to delete this group? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogCtx);
              try {
                await getIt<ChatRepository>().deleteGroup(widget.conversationId);
                if (mounted) {
                  Navigator.pop(context); // Close group info page using outer context
                  Navigator.pop(context); // Close chat page using outer context
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to delete group: $e')),
                  );
                }
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final innerCardColor = context.colors.isDark ? context.colors.pureWhite.withValues(alpha: 0.05) : context.colors.pureWhite;

    return BlocListener<ChatBloc, ChatState>(
      listener: (context, state) {
        if (state is ChatLoaded) {
          if (state.notificationMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.notificationMessage!)),
            );
            if (state.notificationMessage!.contains('successfully') || 
                state.notificationMessage!.contains('added') || 
                state.notificationMessage!.contains('removed') ||
                state.notificationMessage!.contains('promoted') ||
                state.notificationMessage!.contains('admin') ||
                state.notificationMessage!.contains('rights')) {
              Future.delayed(const Duration(milliseconds: 500), () {
                if (mounted) {
                  _fetchGroupDetails();
                }
              });
            }
          }
          if (_groupData != null) {
            final stateName = state.groupName;
            final statePic = state.groupPictureUrl;
            if (stateName != null && stateName != _groupData!['name']) {
              setState(() {
                _groupData!['name'] = stateName;
              });
            }
            if (statePic != null) {
              setState(() {
                _groupData!['icon_url'] = statePic;
                _groupData!['groupPictureUrl'] = statePic;
                _groupData!['groupImageUrl'] = statePic;
              });
            }
          }
        }
      },
      child: BlocBuilder<ChatBloc, ChatState>(
        builder: (context, state) {
          final isMuted = state is ChatLoaded ? state.isMuted : false;
          final description = _groupData?['description'] ?? widget.groupDescription;
          final participantCount = _groupData?['participant_count'] ?? _participants.length;

          return Scaffold(
            backgroundColor: context.colors.scaffoldBackground,
            body: _isLoading 
                ? Center(child: CircularProgressIndicator(color: context.colors.primary))
                : CustomScrollView(
              slivers: [
                // WhatsApp style Sliver AppBar
                SliverAppBar(
                  expandedHeight: 300,
                  pinned: true,
                  flexibleSpace: FlexibleSpaceBar(
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _groupData?['name'] ?? widget.groupName,
                            style: context.titleMedium.copyWith(color: Colors.white, shadows: [
                              const Shadow(color: Colors.black45, blurRadius: 4, offset: Offset(0, 2)),
                            ]),
                          ),
                        ),
                      ],
                    ),
                    background: GestureDetector(
                      onTap: _isAdmin ? _updateGroupIcon : null,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Container(
                            color: widget.groupColor,
                            child: (() {
                              final groupPic = _groupData?['groupPictureUrl'] ?? _groupData?['groupImageUrl'] ?? _groupData?['icon_url'] ?? _groupData?['group_picture_url'];
                              return (groupPic != null && groupPic.toString().isNotEmpty)
                                  ? Image.network(groupPic.toString(), fit: BoxFit.cover)
                                  : Center(
                                      child: Icon(
                                        Icons.group_rounded,
                                        size: 100,
                                        color: Colors.white.withValues(alpha: 0.5),
                                      ),
                                    );
                            })(),
                          ),
                        ],
                      ),
                    ),
                  ),
                  leading: IconButton(
                    icon: const Icon(CommonIcons.arrowBack, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  actions: [
                    if (_isAdmin)
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.white),
                        tooltip: 'Edit Group Details',
                        onPressed: _showEditGroupBottomSheet,
                      ),
                  ],
                ),

                SliverToBoxAdapter(
                  child: Column(
                    children: [
                      if ((description != null && description.isNotEmpty) || _isAdmin)
                        _buildSectionCard(
                          innerCardColor,
                          InkWell(
                            onTap: _isAdmin ? _editGroupDescription : null,
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('Group description', style: context.bodyMedium.copyWith(color: context.colors.primary)),
                                      if (_isAdmin)
                                        Icon(Icons.edit, color: context.colors.primary, size: 18),
                                    ],
                                  ),
                                  CommonSpaces.h8,
                                  Text(
                                    (description != null && description.isNotEmpty)
                                        ? description
                                        : 'Add group description...',
                                    style: context.bodyLarge.copyWith(
                                      color: (description != null && description.isNotEmpty)
                                          ? context.colors.textPrimary
                                          : context.colors.textHint,
                                      fontStyle: (description != null && description.isNotEmpty)
                                          ? FontStyle.normal
                                          : FontStyle.italic,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                      _buildSectionCard(
                        innerCardColor,
                        Column(
                          children: [
                            _buildSettingsTile(
                              icon: CommonIcons.notifications,
                              title: 'Mute notifications',
                              trailing: Switch(
                                value: isMuted,
                                onChanged: (val) {
                                  context.read<ChatBloc>().add(ToggleMuteEvent(isMuted: val));
                                },
                                activeThumbColor: context.colors.primary,
                              ),
                            ),
                            _buildSettingsTile(
                              icon: Icons.music_note_rounded,
                              title: 'Custom notifications',
                              trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                            ),
                          ],
                        ),
                      ),

                      _buildSectionCard(
                        innerCardColor,
                        Column(
                          children: [
                            _buildSettingsTile(
                              icon: Icons.timer_outlined,
                              title: 'Disappearing messages',
                              trailing: Text(_getDisappearingText(_disappearingTimer), style: context.bodyMedium.copyWith(color: context.colors.textHint)),
                              onTap: _isAdmin ? () => _showDisappearingMessagesBottomSheet(context) : null,
                            ),
                          ],
                        ),
                      ),

                      // Participants Section
                      _buildSectionCard(
                        innerCardColor,
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              child: Text(
                                '$participantCount participants',
                                style: context.titleSmall.copyWith(color: context.colors.textSecondary),
                              ),
                            ),
                            if (_isAdmin)
                              ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: context.colors.primary,
                                  child: const Icon(Icons.person_add_rounded, color: Colors.white, size: 20),
                                ),
                                title: Text('Add participants', style: context.bodyLarge.copyWith(color: context.colors.textPrimary)),
                                onTap: () async {
                                  final List<UserModel>? selectedUsers = await showModalBottomSheet<List<UserModel>>(
                                    context: context,
                                    isScrollControlled: true,
                                    backgroundColor: Colors.transparent,
                                    builder: (dialogCtx) => BlocProvider.value(
                                      value: getIt<ContactsBloc>(),
                                      child: Container(
                                        height: MediaQuery.of(context).size.height * 0.85,
                                        decoration: BoxDecoration(
                                          color: context.colors.scaffoldBackground,
                                          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                                        ),
                                        clipBehavior: Clip.antiAliasWithSaveLayer,
                                        child: UserListPage(
                                          showOnlySynced: true,
                                          isPicker: true,
                                          excludeUserIds: _participants.map((u) => u.id).toList(),
                                        ),
                                      ),
                                    ),
                                  );
                                  
                                  if (selectedUsers != null && selectedUsers.isNotEmpty && mounted) {
                                    context.read<ChatBloc>().add(AddGroupParticipantsEvent(
                                      groupId: widget.conversationId,
                                      userIds: selectedUsers.map((u) => u.id).toList(),
                                    ));
                                    _fetchGroupDetails();
                                  }
                                },
                              ),
                            // Real participants
                            ..._participants.map((user) {
                              final isMe = user.id == _myId;
                              final name = user.displayName;

                              final isAdminParticipant = _groupData?['participants']?.any((p) => 
                                  (p['user_id'] == user.id || 
                                   p['id'] == user.id || 
                                   p['_id'] == user.id || 
                                   (p['user'] is Map && p['user']['id'] == user.id)) && 
                                  p['is_admin'] == true
                              ) ?? false;
                              
                              return ListTile(
                                leading: Stack(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: context.colors.primary.withValues(alpha: 0.1),
                                      child: (user.profilePictureUrl != null && user.profilePictureUrl!.isNotEmpty)
                                          ? ClipOval(
                                              child: Image.network(
                                                user.profilePictureUrl!,
                                                fit: BoxFit.cover,
                                                width: double.infinity,
                                                height: double.infinity,
                                                errorBuilder: (context, error, stackTrace) => Text(
                                                  name.isNotEmpty ? name.substring(0, 1).toUpperCase() : '?',
                                                  style: TextStyle(color: context.colors.primary),
                                                ),
                                              ),
                                            )
                                          : Text(
                                              name.isNotEmpty ? name.substring(0, 1).toUpperCase() : '?',
                                              style: TextStyle(color: context.colors.primary),
                                            ),
                                    ),
                                    if (user.isOnline)
                                      Positioned(
                                        right: 0,
                                        bottom: 0,
                                        child: Container(
                                          width: 12,
                                          height: 12,
                                          decoration: BoxDecoration(
                                            color: context.colors.success,
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: context.colors.scaffoldBackground,
                                              width: 2,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                title: Text(isMe ? '$name (You)' : name, style: context.bodyLarge),
                                subtitle: Text(
                                  isAdminParticipant
                                      ? 'Group Admin'
                                      : (user.phoneNumber.isNotEmpty 
                                          ? user.phoneNumber 
                                          : (user.about != null && user.about!.isNotEmpty 
                                              ? user.about! 
                                              : 'Hey there! I am using Schat.')),
                                  style: context.bodySmall.copyWith(
                                    color: isAdminParticipant ? context.colors.primary : context.colors.textSecondary,
                                    fontWeight: isAdminParticipant ? FontWeight.w500 : null,
                                  ),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                     if (_isAdmin && !isMe) ...[
                                       IconButton(
                                         icon: Icon(
                                           isAdminParticipant
                                               ? Icons.shield_outlined
                                               : Icons.shield,
                                           color: context.colors.primary,
                                         ),
                                         tooltip: isAdminParticipant
                                             ? 'Dismiss as admin'
                                             : 'Make group admin',
                                         onPressed: () {
                                           if (isAdminParticipant) {
                                             context.read<ChatBloc>().add(
                                               DemoteGroupAdminEvent(
                                                 groupId: widget.conversationId,
                                                 userId: user.id,
                                               ),
                                             );
                                           } else {
                                             context.read<ChatBloc>().add(
                                               PromoteGroupAdminEvent(
                                                 groupId: widget.conversationId,
                                                 userId: user.id,
                                               ),
                                             );
                                           }
                                           setState(() {
                                             if (_groupData != null && _groupData!['participants'] is List) {
                                               final list = _groupData!['participants'] as List;
                                               for (var p in list) {
                                                 if (p is Map && (p['user_id'] == user.id || p['id'] == user.id || p['_id'] == user.id || (p['user'] is Map && p['user']['id'] == user.id))) {
                                                   p['is_admin'] = !isAdminParticipant;
                                                 }
                                               }
                                             }
                                           });
                                         },
                                       ),
                                        IconButton(
                                          icon: const Icon(Icons.remove_circle_outline, color: Colors.red, size: 20),
                                          onPressed: () => _removeParticipant(user.id, name),
                                        ),
                                     ],
                                  ],
                                ),
                                onTap: isMe ? null : () {
                                  final chatBloc = context.read<ChatBloc>();
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (innerContext) => BlocProvider.value(
                                        value: chatBloc,
                                        child: ContactProfilePage(
                                          conversationId: widget.conversationId,
                                          contactName: name,
                                          contactColor: context.colors.primary,
                                          isOnline: user.isOnline,
                                          recipientId: user.id,
                                          isFromGroup: true,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              );
                            }),
                          ],
                        ),
                      ),

                      _buildSectionCard(
                        innerCardColor,
                        Column(
                          children: [
                            ListTile(
                              leading: const Icon(Icons.logout_rounded, color: Colors.red),
                              title: const Text('Exit group', style: TextStyle(color: Colors.red)),
                              onTap: () => _exitGroup(),
                            ),
                            if (_isAdmin)
                              ListTile(
                                leading: const Icon(Icons.delete_forever_rounded, color: Colors.red),
                                title: const Text('Delete group', style: TextStyle(color: Colors.red)),
                                onTap: () => _deleteGroup(),
                              ),
                          ],
                        ),
                      ),

                      CommonSpaces.h40,
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionCard(Color bgColor, Widget child) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 12),
      decoration: BoxDecoration(
        color: bgColor,
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 2, offset: const Offset(0, 1)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: child,
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required Widget trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: context.colors.textSecondary),
      title: Text(title, style: context.bodyLarge),
      trailing: trailing,
      onTap: onTap,
    );
  }

  String _getDisappearingText(int? seconds) {
    if (seconds == null || seconds == 0) return 'Off';
    if (seconds < 0) {
      final tod = _decodeDailyCutoffTime(seconds);
      if (tod != null) {
        return _formatDailyCutoffText(tod.hour, tod.minute);
      }
      return 'Custom daily';
    }
    if (seconds == 1800) return '30 minutes';
    if (seconds == 604800) return '7 days';
    if (seconds == 2592000) return '30 days';
    if (seconds < 60) return '$seconds seconds';
    if (seconds < 3600) {
      return '${(seconds / 60).round()} minutes';
    } else if (seconds < 86400) {
      return '${(seconds / 3600).round()} hours';
    } else {
      return '${(seconds / 86400).round()} days';
    }
  }

  int _encodeDailyCutoffTime(int hour, int minute) {
    return -((hour * 3600 + minute * 60) + 1);
  }

  TimeOfDay? _decodeDailyCutoffTime(int? encoded) {
    if (encoded == null || encoded >= 0) return null;
    final totalSeconds = (-encoded) - 1;
    final hour = totalSeconds ~/ 3600;
    final minute = (totalSeconds % 3600) ~/ 60;
    return TimeOfDay(hour: hour, minute: minute);
  }

  String _formatDailyCutoffText(int hour, int minute) {
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour % 12 == 0 ? 12 : hour % 12;
    final displayMinute = minute == 0 ? '' : ':${minute.toString().padLeft(2, '0')}';
    return 'Daily at $displayHour$displayMinute $period';
  }

  void _showDisappearingMessagesBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Material(
          color: context.colors.scaffoldBackground,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: context.colors.textHint.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Row(
                  children: [
                    Icon(Icons.timer_outlined, color: context.colors.primary, size: 24),
                    CommonSpaces.w12,
                    Text(
                      'Disappearing messages',
                      style: context.titleLarge.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                CommonSpaces.h16,
                Text(
                  'For more privacy and storage, all new messages will disappear from this chat for everyone after the selected duration.',
                  style: context.bodyMedium.copyWith(color: context.colors.textSecondary),
                ),
                CommonSpaces.h24,
                _buildDisappearingOption(context, 'Off', 0),
                _buildCustomDailyTimeOption(context),
                _buildDisappearingOption(context, '7 days', 604800),
                _buildDisappearingOption(context, '30 days', 2592000),
                CommonSpaces.h20,
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCustomDailyTimeOption(BuildContext context) {
    final bool isCustom = _disappearingTimer != null && _disappearingTimer! < 0;
    final customText = isCustom ? _getDisappearingText(_disappearingTimer) : null;
    final presets = [
      {'label': '2 AM', 'h': 2, 'm': 0},
      {'label': '7 AM', 'h': 7, 'm': 0},
      {'label': '1 PM', 'h': 13, 'm': 0},
      {'label': '2 PM', 'h': 14, 'm': 0},
      {'label': '5 PM', 'h': 17, 'm': 0},
      {'label': '11 PM', 'h': 23, 'm': 0},
    ];

    void applyCustomTime(int encoded) {
      Navigator.pop(context);
      context.read<ChatBloc>().add(SetDisappearingTimerEvent(seconds: encoded));
      setState(() {
        _disappearingTimer = encoded;
      });
      context.showInfoNotification('Disappearing messages set to ${_getDisappearingText(encoded)}');
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: isCustom ? context.colors.primary.withValues(alpha: 0.08) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: isCustom ? Border.all(color: context.colors.primary.withValues(alpha: 0.3)) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.schedule, color: isCustom ? context.colors.primary : context.colors.textSecondary),
            title: Text(
              isCustom ? 'Custom ($customText)' : 'Custom daily time',
              style: context.bodyLarge.copyWith(
                fontWeight: isCustom ? FontWeight.bold : FontWeight.normal,
                color: isCustom ? context.colors.primary : null,
              ),
            ),
            subtitle: Text(
              'Clears last 24h chats daily at selected time',
              style: context.bodySmall.copyWith(fontSize: 11, color: context.colors.textSecondary),
            ),
            trailing: isCustom
                ? Icon(Icons.check_rounded, color: context.colors.primary)
                : const Icon(Icons.keyboard_arrow_down_rounded),
            onTap: () async {
              final picked = await showTimePicker(
                context: context,
                initialTime: isCustom
                    ? (_decodeDailyCutoffTime(_disappearingTimer) ?? const TimeOfDay(hour: 14, minute: 0))
                    : const TimeOfDay(hour: 14, minute: 0),
              );
              if (picked != null) {
                final encoded = _encodeDailyCutoffTime(picked.hour, picked.minute);
                applyCustomTime(encoded);
              }
            },
          ),
          Padding(
            padding: const EdgeInsets.only(left: 4, right: 4, bottom: 8),
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                ...presets.map((p) {
                  final encoded = _encodeDailyCutoffTime(p['h'] as int, p['m'] as int);
                  final isSelected = _disappearingTimer == encoded;
                  return InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => applyCustomTime(encoded),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: isSelected ? context.colors.primary : context.colors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? context.colors.primary : context.colors.primary.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        p['label'] as String,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? Colors.white : context.colors.primary,
                        ),
                      ),
                    ),
                  );
                }),
                InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: isCustom
                          ? (_decodeDailyCutoffTime(_disappearingTimer) ?? const TimeOfDay(hour: 14, minute: 0))
                          : const TimeOfDay(hour: 14, minute: 0),
                    );
                    if (picked != null) {
                      final encoded = _encodeDailyCutoffTime(picked.hour, picked.minute);
                      applyCustomTime(encoded);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: context.colors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: context.colors.primary.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.more_time, size: 12, color: context.colors.primary),
                        const SizedBox(width: 4),
                        Text(
                          'Pick Time',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: context.colors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDisappearingOption(BuildContext context, String label, int? seconds) {
    final bool isSelected = (_disappearingTimer == seconds) || (_disappearingTimer == null && seconds == 0);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label, style: context.bodyLarge),
      trailing: isSelected
          ? Icon(Icons.check_rounded, color: context.colors.primary)
          : const Icon(Icons.chevron_right_rounded),
      onTap: () {
        int? finalSeconds = seconds == 0 ? null : seconds;
        Navigator.pop(context);
        context.read<ChatBloc>().add(SetDisappearingTimerEvent(seconds: finalSeconds));
        setState(() {
          _disappearingTimer = finalSeconds;
        });
        context.showInfoNotification('Disappearing messages set to $label');
      },
    );
  }
}

class _EditGroupBottomSheet extends StatefulWidget {
  final String groupId;
  final String currentName;
  final String? currentDescription;
  final String? currentIconUrl;
  final Color groupColor;

  const _EditGroupBottomSheet({
    required this.groupId,
    required this.currentName,
    this.currentDescription,
    this.currentIconUrl,
    required this.groupColor,
  });

  @override
  State<_EditGroupBottomSheet> createState() => _EditGroupBottomSheetState();
}

class _EditGroupBottomSheetState extends State<_EditGroupBottomSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  XFile? _selectedImage;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.currentName);
    _descriptionController = TextEditingController(text: widget.currentDescription ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (image != null) {
      setState(() {
        _selectedImage = image;
      });
    }
  }

  Future<void> _saveChanges() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Group name cannot be empty')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      String? uploadedUrl = widget.currentIconUrl;
      if (_selectedImage != null) {
        final bytes = await _selectedImage!.readAsBytes();
        uploadedUrl = await getIt<ProfileRepository>().uploadProfilePicture(
          filePath: _selectedImage!.path,
          fileName: _selectedImage!.name,
          mimeType: 'image/jpeg',
          fileSizeBytes: bytes.length,
          fileBytes: bytes,
        );
      }

      if (mounted) {
        Navigator.pop(context, {
          'name': name,
          'description': _descriptionController.text.trim(),
          'iconUrl': uploadedUrl,
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save changes: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: BoxDecoration(
        color: context.colors.scaffoldBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: context.colors.textSecondary.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          CommonSpaces.h16,
          Text(
            'Edit Group Details',
            style: context.titleLarge.copyWith(fontWeight: FontWeight.bold),
          ),
          CommonSpaces.h20,
          Center(
            child: GestureDetector(
              onTap: _isLoading ? null : _pickImage,
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 45,
                    backgroundColor: widget.groupColor.withValues(alpha: 0.1),
                    backgroundImage: _selectedImage != null
                        ? FileImage(File(_selectedImage!.path))
                        : (widget.currentIconUrl != null && widget.currentIconUrl!.isNotEmpty)
                            ? NetworkImage(widget.currentIconUrl!)
                            : null,
                    child: (_selectedImage == null && (widget.currentIconUrl == null || widget.currentIconUrl!.isEmpty))
                        ? Icon(Icons.group_rounded, size: 45, color: widget.groupColor)
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: context.colors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                    ),
                  ),
                ],
              ),
            ),
          ),
          CommonSpaces.h20,
          TextField(
            controller: _nameController,
            enabled: !_isLoading,
            decoration: InputDecoration(
              labelText: 'Group Name',
              filled: true,
              fillColor: context.colors.lightBackground,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          CommonSpaces.h16,
          TextField(
            controller: _descriptionController,
            enabled: !_isLoading,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: 'Description (Optional)',
              filled: true,
              fillColor: context.colors.lightBackground,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          CommonSpaces.h24,
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: _isLoading ? null : () => Navigator.pop(context),
                child: Text('Cancel', style: TextStyle(color: context.colors.textSecondary)),
              ),
              CommonSpaces.w12,
              ElevatedButton(
                onPressed: _isLoading ? null : _saveChanges,
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.colors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('Save', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
