import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:schat/features/chat_screen/src/presentation/bloc/chat_bloc.dart';
import 'package:schat/features/chat_screen/src/presentation/bloc/chat_state.dart';
import 'package:schat/utils/common_colors.dart';
import 'package:schat/utils/common_fontstyles.dart';
import 'package:schat/utils/common_icons.dart';
import 'package:schat/utils/common_spaces.dart';

import 'package:schat/features/chat_screen/src/presentation/contact_profile_page.dart';
import 'package:schat/features/profile_screen/src/domain/models/user_model.dart';
import 'package:schat/core/storage/storage_service.dart';
import 'package:schat/features/chat_screen/src/domain/repositories/chat_repository.dart';
import 'package:schat/features/chat_screen/src/presentation/bloc/chat_event.dart';
import 'package:schat/features/dashboard_screen/src/presentation/user_list_page.dart';
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

  Future<void> _editGroupName() async {
    final controller = TextEditingController(text: _groupData?['name'] ?? widget.groupName);
    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Group Name'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Enter group name'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (newName != null && newName.isNotEmpty && newName != (_groupData?['name'] ?? widget.groupName)) {
      if (mounted) {
        context.read<ChatBloc>().add(UpdateGroupInfoEvent(
          groupId: widget.conversationId,
          name: newName,
        ));
        setState(() {
          if (_groupData != null) {
            _groupData!['name'] = newName;
          }
        });
      }
    }
  }

  Future<void> _updateGroupIcon() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    
    if (image != null) {
      try {
        final repo = getIt<ChatRepository>();
        final iconUrl = await repo.uploadMedia(
          conversationId: widget.conversationId,
          filePath: image.path,
          fileName: image.name,
          mediaType: 'GROUP_ICON',
          mimeType: 'image/jpeg',
          fileSizeBytes: await image.length(),
        );

        if (iconUrl != null && mounted) {
          context.read<ChatBloc>().add(UpdateGroupInfoEvent(
            groupId: widget.conversationId,
            iconUrl: iconUrl,
          ));
          _fetchGroupDetails(); // Refresh to show new icon
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to upload icon: $e')),
          );
        }
      }
    }
  }

  void _removeParticipant(String userId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Participant'),
        content: const Text('Are you sure you want to remove this participant from the group?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<ChatBloc>().add(RemoveGroupParticipantEvent(
                groupId: widget.conversationId,
                userId: userId,
              ));
              setState(() {
                _participants.removeWhere((u) => u.id == userId);
              });
            },
            child: const Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
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
        if (state is ChatLoaded && state.notificationMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.notificationMessage!)),
          );
          if (state.notificationMessage!.contains('successfully') || 
              state.notificationMessage!.contains('added') || 
              state.notificationMessage!.contains('removed')) {
            _fetchGroupDetails();
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
                        if (_isAdmin)
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.white, size: 20),
                            onPressed: _editGroupName,
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
                            child: (_groupData?['icon_url'] != null && _groupData!['icon_url'].toString().isNotEmpty)
                                ? Image.network(_groupData!['icon_url'], fit: BoxFit.cover)
                                : Center(
                              child: Icon(
                                Icons.group_rounded,
                                size: 100,
                                color: Colors.white.withValues(alpha: 0.5),
                              ),
                            ),
                          ),
                          if (_isAdmin)
                            Positioned(
                              bottom: 16,
                              right: 16,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: const BoxDecoration(color: Colors.black38, shape: BoxShape.circle),
                                child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  leading: IconButton(
                    icon: const Icon(CommonIcons.arrowBack, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),

                SliverToBoxAdapter(
                  child: Column(
                    children: [
                      if (description != null && description.isNotEmpty)
                        _buildSectionCard(
                          innerCardColor,
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Group description', style: context.bodyMedium.copyWith(color: context.colors.primary)),
                              CommonSpaces.h8,
                              Text(description, style: context.bodyLarge),
                            ],
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
                              trailing: Text('Off', style: context.bodyMedium.copyWith(color: context.colors.textHint)),
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
                                  final List<UserModel>? selectedUsers = await Navigator.push<List<UserModel>>(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => UserListPage(
                                        showOnlySynced: true,
                                        isPicker: true,
                                        excludeUserIds: _participants.map((u) => u.id).toList(),
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
                              final name = user.firstName ?? user.username ?? 'User';
                              final isAdminParticipant = _groupData?['participants']?.any((p) => (p['user_id'] == user.id || (p['user'] is Map && p['user']['id'] == user.id)) && p['is_admin'] == true) ?? false;
                              
                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: context.colors.primary.withValues(alpha: 0.1),
                                  child: (user.profilePictureUrl != null && user.profilePictureUrl!.isNotEmpty)
                                      ? ClipOval(child: Image.network(user.profilePictureUrl!, fit: BoxFit.cover))
                                      : Text(
                                          name.isNotEmpty ? name.substring(0, 1).toUpperCase() : '?',
                                          style: TextStyle(color: context.colors.primary),
                                        ),
                                ),
                                title: Text(isMe ? 'You' : name, style: context.bodyLarge),
                                subtitle: Text(user.about ?? 'Hey there! I am using Schat.', style: context.bodySmall),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (isAdminParticipant) 
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        margin: const EdgeInsets.only(right: 8),
                                        decoration: BoxDecoration(
                                          border: Border.all(color: context.colors.primary),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text('Group Admin', style: context.bodySmall.copyWith(color: context.colors.primary, fontSize: 9)),
                                      ),
                                    if (_isAdmin && !isMe)
                                      IconButton(
                                        icon: const Icon(Icons.remove_circle_outline, color: Colors.red, size: 20),
                                        onPressed: () => _removeParticipant(user.id),
                                      ),
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
  }) {
    return ListTile(
      leading: Icon(icon, color: context.colors.textSecondary),
      title: Text(title, style: context.bodyLarge),
      trailing: trailing,
    );
  }
}
