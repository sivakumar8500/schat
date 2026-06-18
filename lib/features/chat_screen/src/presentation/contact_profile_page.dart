import 'package:schat/utils/common_fontstyles.dart';

import 'package:schat/utils/common_sizes.dart';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:schat/utils/common_colors.dart';
import 'package:schat/utils/common_icons.dart';
import 'package:schat/features/call_screen/call_screen.dart';
import 'package:schat/features/chat_screen/src/presentation/bloc/chat_bloc.dart';
import 'package:schat/features/chat_screen/src/presentation/bloc/chat_event.dart';
import 'package:schat/features/chat_screen/src/presentation/bloc/chat_state.dart';

class ContactProfilePage extends StatefulWidget {
  final String contactName;
  final Color contactColor;
  final bool isOnline;

  const ContactProfilePage({
    super.key,
    required this.contactName,
    required this.contactColor,
    required this.isOnline,
  });

  @override
  State<ContactProfilePage> createState() => _ContactProfilePageState();
}

class _ContactProfilePageState extends State<ContactProfilePage> {
  @override
  Widget build(BuildContext context) {
    final cardBgColor = context.colors.cardBackground;
    final innerCardColor = context.colors.isDark ? context.colors.pureWhite.withValues(alpha: 0.05) : context.colors.pureWhite;

    return BlocBuilder<ChatBloc, ChatState>(
      builder: (context, state) {
        final isMuted = state is ChatLoaded ? state.isMuted : false;
        final isLocked = state is ChatLoaded ? state.isLocked : false;

        return Scaffold(
      backgroundColor: context.colors.scaffoldBackground,
      body: Column(
        children: [
          // Top Area: Back Button, Avatar, Name, Status Pill, Action Row
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Back button
                  Align(
                    alignment: Alignment.centerLeft,
                    child: InkWell(
                      onTap: () => Navigator.pop(context),
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: Icon(
                          CommonIcons.arrowBack,
                          color: context.colors.textPrimary,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: CommonSizes.p12),

                  // Avatar
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: widget.contactColor.withValues(alpha: 0.15),
                        child: Text(
                          widget.contactName.substring(0, 1),
                          style: context.h1.copyWith(
                            fontSize: 36,
                            color: widget.contactColor,
                          ),
                        ),
                      ),
                      if (widget.isOnline)
                        Positioned(
                          right: 4,
                          bottom: 4,
                          child: Container(
                            width: 18,
                            height: 18,
                            decoration: BoxDecoration(
                              color: context.colors.primary,
                              shape: BoxShape.circle,
                              border: Border.all(color: context.colors.scaffoldBackground, width: 3),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: CommonSizes.p16),

                  // Contact Name
                  Text(
                    widget.contactName,
                    style: context.h3,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: CommonSizes.p4),

                  // Status Quote
                  Text(
                    "Pursuing Goals 🤘",
                    style: context.bodyLarge.copyWith(
                      color: context.colors.textSecondary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: CommonSizes.p12),

                  // Online status badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: widget.isOnline
                          ? context.colors.primary.withValues(alpha: 0.12)
                          : context.colors.textHint.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      widget.isOnline ? 'Online' : 'Offline',
                      style: context.bodyMedium.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: widget.isOnline ? context.colors.primary : context.colors.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(height: CommonSizes.p24),

                  // Action Row (Circular buttons)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Call button
                      _buildRoundActionButton(
                        icon: CommonIcons.phone,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AudioCallPage(
                                contactName: widget.contactName,
                                contactColor: widget.contactColor,
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: CommonSizes.p16),

                      // Video call button
                      _buildRoundActionButton(
                        icon: CommonIcons.videocam,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => VideoCallPage(
                                contactName: widget.contactName,
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: CommonSizes.p16),

                      // Chat button (Back to chat)
                      _buildRoundActionButton(
                        icon: CommonIcons.chatBubble,
                        onTap: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: CommonSizes.p16),

                      // More options button
                      _buildRoundActionButton(
                        icon: CommonIcons.moreHoriz,
                        onTap: () {},
                      ),
                    ],
                  ),
                  const SizedBox(height: CommonSizes.p12),
                ],
              ),
            ),
          ),

          // Bottom card area
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: cardBgColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(40),
                ),
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(40),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 30.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Shared Media Section
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Shared media',
                            style: context.titleSmall,
                          ),
                          GestureDetector(
                            onTap: () {},
                            child: Text(
                              'View all',
                              style: context.bodyLarge.copyWith(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: context.colors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: CommonSizes.p16),

                      // 4 Media Grid Thumbnails
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(4, (index) {
                          return Container(
                            width: (MediaQuery.of(context).size.width - 48 - 36) / 4,
                            height: (MediaQuery.of(context).size.width - 48 - 36) / 4,
                            decoration: BoxDecoration(
                              color: innerCardColor,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: context.colors.border.withValues(alpha: 0.5),
                              ),
                            ),
                            child: Center(
                              child: Opacity(
                                opacity: 0.1,
                                child: GridView.builder(
                                  physics: const NeverScrollableScrollPhysics(),
                                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    mainAxisSpacing: 2,
                                    crossAxisSpacing: 2,
                                  ),
                                  itemCount: 4,
                                  itemBuilder: (_, index) => Container(
                                    color: context.colors.textPrimary,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: CommonSizes.p24),

                      // Settings Options Card
                      Material(
                        color: innerCardColor,
                        borderRadius: BorderRadius.circular(24),
                        clipBehavior: Clip.antiAlias,
                        child: Column(
                          children: [
                            // Mute notifications
                            _buildSettingsTile(
                              icon: CommonIcons.notifications,
                              title: 'Mute notifications',
                              trailing: Switch(
                                value: isMuted,
                                activeThumbColor: context.colors.primary,
                                onChanged: (value) {
                                  context.read<ChatBloc>().add(ToggleMuteEvent(isMuted: value));
                                },
                              ),
                            ),
                            Divider(color: context.colors.border.withValues(alpha: 0.3), height: 1),

                            // Lock Chat
                            _buildSettingsTile(
                              icon: CommonIcons.lock,
                              title: 'Lock Chat',
                              trailing: Switch(
                                value: isLocked,
                                activeThumbColor: context.colors.primary,
                                onChanged: (value) {
                                  context.read<ChatBloc>().add(ToggleLockEvent(isLocked: value));
                                },
                              ),
                            ),
                            Divider(color: context.colors.border.withValues(alpha: 0.3), height: 1),

                            // Auto-delete messages
                            _buildSettingsTile(
                              icon: CommonIcons.history,
                              title: 'Auto-delete messages',
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '30s',
                                    style: context.bodyLarge.copyWith(
                                      color: context.colors.textSecondary,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(width: CommonSizes.p4),
                                  Icon(
                                    CommonIcons.arrowForward,
                                    size: 14,
                                    color: context.colors.textHint,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: CommonSizes.p16),

                      // Destructive Block/Report Card
                      Material(
                        color: context.colors.isDark
                            ? context.colors.error.withValues(alpha: 0.05)
                            : context.colors.error.withValues(alpha: 0.05),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                          side: BorderSide(
                            color: context.colors.error.withValues(alpha: 0.1),
                          ),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Column(
                          children: [
                            // Block Contact
                            _buildDestructiveTile(
                              icon: CommonIcons.block,
                              title: 'Block ${widget.contactName}',
                            ),
                            Divider(
                              color: context.colors.error.withValues(alpha: 0.08),
                              height: 1,
                            ),

                            // Report Contact
                            _buildDestructiveTile(
                              icon: CommonIcons.report,
                              title: 'Report the contact',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
      },
    );
  }

  Widget _buildRoundActionButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(25),
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: context.colors.primary,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: context.colors.pureWhite,
          size: 24,
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required Widget trailing,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: context.colors.scaffoldBackground,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: context.colors.textPrimary,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: context.titleSmall.copyWith(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: context.colors.textPrimary,
        ),
      ),
      trailing: trailing,
    );
  }

  Widget _buildDestructiveTile({
    required IconData icon,
    required String title,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: context.colors.pureWhite,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: context.colors.error,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: context.titleSmall.copyWith(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: context.colors.error,
        ),
      ),
      onTap: () {},
    );
  }
}
