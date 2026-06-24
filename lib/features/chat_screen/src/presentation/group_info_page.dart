import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:schat/features/chat_screen/src/presentation/bloc/chat_bloc.dart';
import 'package:schat/features/chat_screen/src/presentation/bloc/chat_state.dart';
import 'package:schat/utils/common_colors.dart';
import 'package:schat/utils/common_fontstyles.dart';
import 'package:schat/utils/common_icons.dart';
import 'package:schat/utils/common_sizes.dart';
import 'package:schat/utils/common_spaces.dart';
import 'package:schat/features/chat_screen/src/presentation/shared_media_page.dart';
import 'package:schat/features/chat_screen/src/domain/models/chat_media_model.dart';

import 'package:schat/features/chat_screen/src/presentation/contact_profile_page.dart';
import 'package:schat/features/profile_screen/src/domain/models/user_model.dart';
import 'package:schat/core/storage/storage_service.dart';
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

  // Better Mock participants
  final List<UserModel> _participants = [
    const UserModel(id: '1', firstName: 'Alice', username: 'alice_w', about: 'Available', isOnline: true),
    const UserModel(id: '2', firstName: 'Bob', username: 'bob_builder', about: 'At work', isOnline: false),
    const UserModel(id: '3', firstName: 'Charlie', username: 'charlie_brown', about: 'Sleeping', isOnline: true),
    const UserModel(id: '4', firstName: 'David', username: 'david_king', about: 'Hey there!', isOnline: false),
  ];

  @override
  Widget build(BuildContext context) {
    final cardBgColor = context.colors.cardBackground;
    final innerCardColor = context.colors.isDark ? context.colors.pureWhite.withValues(alpha: 0.05) : context.colors.pureWhite;

    return BlocBuilder<ChatBloc, ChatState>(
      builder: (context, state) {
        final isMuted = state is ChatLoaded ? state.isMuted : false;
        
        return Scaffold(
          backgroundColor: context.colors.scaffoldBackground,
          body: CustomScrollView(
            slivers: [
              // WhatsApp style Sliver AppBar
              SliverAppBar(
                expandedHeight: 300,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    widget.groupName,
                    style: context.titleMedium.copyWith(color: Colors.white, shadows: [
                      const Shadow(color: Colors.black45, blurRadius: 4, offset: Offset(0, 2)),
                    ]),
                  ),
                  background: Container(
                    color: widget.groupColor,
                    child: Center(
                      child: Icon(
                        Icons.group_rounded,
                        size: 100,
                        color: Colors.white.withValues(alpha: 0.5),
                      ),
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
                    if (widget.groupDescription != null && widget.groupDescription!.isNotEmpty)
                      _buildSectionCard(
                        innerCardColor,
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Add group description', style: context.bodyMedium.copyWith(color: context.colors.primary)),
                            CommonSpaces.h8,
                            Text(widget.groupDescription!, style: context.bodyLarge),
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
                              onChanged: (val) {},
                              activeColor: context.colors.primary,
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
                              '12 participants',
                              style: context.titleSmall.copyWith(color: context.colors.textSecondary),
                            ),
                          ),
                          ListTile(
                            leading: CircleAvatar(
                              backgroundColor: context.colors.primary,
                              child: const Icon(Icons.person_add_rounded, color: Colors.white, size: 20),
                            ),
                            title: Text('Add participants', style: context.bodyLarge.copyWith(color: context.colors.textPrimary)),
                            onTap: () {},
                          ),
                          // Real/Mock participants
                          ..._participants.map((user) {
                            final isMe = user.id == _myId;
                            final name = user.firstName ?? user.username ?? 'User';
                            
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: context.colors.primary.withValues(alpha: 0.1),
                                child: Text(
                                  name.substring(0, 1).toUpperCase(),
                                  style: TextStyle(color: context.colors.primary),
                                ),
                              ),
                              title: Text(isMe ? 'You' : name, style: context.bodyLarge),
                              subtitle: Text(user.about ?? 'Status message goes here...', style: context.bodySmall),
                              trailing: user.id == '1' ? Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  border: Border.all(color: context.colors.primary),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text('Group Admin', style: context.bodySmall.copyWith(color: context.colors.primary, fontSize: 9)),
                              ) : null,
                              onTap: isMe ? null : () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ContactProfilePage(
                                      conversationId: widget.conversationId,
                                      contactName: name,
                                      contactColor: context.colors.primary,
                                      isOnline: user.isOnline,
                                      recipientId: user.id,
                                      isFromGroup: true,
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
                      ListTile(
                        leading: const Icon(Icons.logout_rounded, color: Colors.red),
                        title: const Text('Exit group', style: TextStyle(color: Colors.red)),
                        onTap: () {},
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
      child: child,
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
