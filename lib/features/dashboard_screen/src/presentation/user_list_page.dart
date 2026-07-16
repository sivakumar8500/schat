import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fast_contacts/fast_contacts.dart';
import 'package:schat/common/widgets/primary_button.dart';
import 'package:schat/features/chat_screen/chat_screen.dart';
import 'package:schat/features/dashboard_screen/src/presentation/bloc/contacts_bloc.dart';
import 'package:schat/features/dashboard_screen/src/presentation/bloc/contacts_event.dart';
import 'package:schat/features/dashboard_screen/src/presentation/bloc/contacts_state.dart';
import 'package:schat/features/dashboard_screen/src/presentation/bloc/chats_bloc.dart';
import 'package:schat/features/dashboard_screen/src/presentation/bloc/chats_event.dart';
import 'package:schat/features/dashboard_screen/src/presentation/bloc/chats_state.dart';
import 'package:schat/features/profile_screen/src/domain/models/user_model.dart';
import 'package:schat/utils/common_colors.dart';
import 'package:schat/utils/common_fontstyles.dart';
import 'package:schat/utils/common_icons.dart';
import 'package:schat/utils/common_spaces.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:schat/injection.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:schat/utils/common_notifications.dart';

class UserListPage extends StatefulWidget {
  final bool forceSync;
  final bool showOnlySynced;
  final bool isPicker;
  final int maxSelection;
  final List<String>? excludeUserIds;

  const UserListPage({
    super.key,
    this.forceSync = false,
    this.showOnlySynced = false,
    this.isPicker = false,
    this.maxSelection = 10,
    this.excludeUserIds,
  });

  @override
  State<UserListPage> createState() => _UserListPageState();
}

class _UserListPageState extends State<UserListPage> {
  String? _pendingParticipantId;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  late ContactsBloc _contactsBloc;
  final List<UserModel> _selectedUsers = [];
  bool _isSyncInProgress = false;

  final String _appLink = 'https://schat.app';
  final String _inviteTitle = 'Join Schat - Secure Messaging';

  void _triggerSync() {
    setState(() {
      _isSyncInProgress = true;
    });
    _contactsBloc.add(const SyncContactsEvent());
  }

  @override
  void initState() {
    super.initState();
    _contactsBloc = getIt<ContactsBloc>();
    if (widget.forceSync) {
      _triggerSync();
    } else {
      _contactsBloc.add(const LoadContacts());
    }
  }

  @override
  void didUpdateWidget(UserListPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.forceSync && !oldWidget.forceSync) {
      _triggerSync();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showInviteBottomSheet(String name, String phone) {
    final String baseMessage = 'Hey $name! I\'m using Schat for secure and private conversations. Join me there! 🔒\n\nDownload Schat at: $_appLink';

    showModalBottomSheet(
      context: context,
      backgroundColor: context.colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        decoration: BoxDecoration(
          color: context.colors.scaffoldBackground,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: context.colors.textHint.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            CommonSpaces.h24,
            Text(
              'Invite $name',
              style: context.titleLarge.copyWith(fontWeight: FontWeight.bold),
            ),
            CommonSpaces.h24,
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildShareOption(
                  icon: CommonIcons.smsOutlined,
                  label: 'SMS',
                  onTap: () {
                    Navigator.pop(context);
                    _launchSms(phone, baseMessage);
                  },
                ),
                _buildShareOption(
                  icon: CommonIcons.chatBubbleOutline,
                  label: 'WhatsApp',
                  onTap: () {
                    Navigator.pop(context);
                    _launchWhatsApp(phone, baseMessage);
                  },
                ),
                _buildShareOption(
                  icon: CommonIcons.mailOutline,
                  label: 'Email',
                  onTap: () {
                    Navigator.pop(context);
                    _launchEmail(baseMessage);
                  },
                ),
                _buildShareOption(
                  icon: CommonIcons.shareOutlined,
                  label: 'More',
                  onTap: () {
                    Navigator.pop(context);
                    Share.share(baseMessage, subject: _inviteTitle);
                  },
                ),
              ],
            ),
            CommonSpaces.h24,
          ],
        ),
      ),
    );
  }

  Widget _buildShareOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: context.colors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: context.colors.primary, size: 28),
          ),
          CommonSpaces.h8,
          Text(
            label,
            style: context.bodySmall.copyWith(
              fontWeight: FontWeight.w600,
              color: context.colors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _launchSms(String phone, String message) async {
    final Uri uri = Uri(
      scheme: 'sms',
      path: phone,
      queryParameters: {'body': message},
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      Share.share(message);
    }
  }

  Future<void> _launchWhatsApp(String phone, String message) async {
    // Standard WhatsApp link
    final String cleanPhone = phone.replaceAll(RegExp(r'\D'), '');
    final Uri uri = Uri.parse('whatsapp://send?phone=$cleanPhone&text=${Uri.encodeComponent(message)}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      // Try universal link as fallback
      final Uri webUri = Uri.parse('https://wa.me/$cleanPhone?text=${Uri.encodeComponent(message)}');
      if (await canLaunchUrl(webUri)) {
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
      } else {
        Share.share(message);
      }
    }
  }

  Future<void> _launchEmail(String message) async {
    final Uri uri = Uri(
      scheme: 'mailto',
      queryParameters: {
        'subject': _inviteTitle,
        'body': message,
      },
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      Share.share(message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(
          value: _contactsBloc,
        ),
        BlocProvider.value(
          value: getIt<ChatsBloc>(),
        ),
      ],
      child: MultiBlocListener(
        listeners: [
          BlocListener<ChatsBloc, ChatsState>(
            listener: (context, state) {
              state.maybeWhen(
                chatCreated: (chat, contactName, profilePictureUrl) {
                  _pendingParticipantId = null;
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatPage(
                        conversationId: chat.id,
                        contactName: contactName,
                        contactColor: context.colors.primary,
                        isOnline: false,
                        recipientId: chat.recipient.id,
                        profilePictureUrl: profilePictureUrl,
                        initialThemeColor: chat.themeColor,
                      ),
                    ),
                  ).then((_) {
                    if (context.mounted) {
                      context.read<ChatsBloc>().add(const FetchChats());
                    }
                  });
                },
                error: (message) {
                  _pendingParticipantId = null;
                },
                orElse: () {},
              );
            },
          ),
          BlocListener<ContactsBloc, ContactsState>(
            listener: (context, state) {
              if (_isSyncInProgress) {
                if (state is ContactsLoaded) {
                  setState(() {
                    _isSyncInProgress = false;
                  });
                  context.showSuccessNotification('Contacts synced successfully');
                } else if (state is ContactsFailure) {
                  setState(() {
                    _isSyncInProgress = false;
                  });
                  context.showErrorNotification('Failed to sync contacts: ${state.errorMessage}');
                }
              }
            },
          ),
        ],
        child: widget.showOnlySynced
            ? Scaffold(
                backgroundColor: context.colors.scaffoldBackground,
                appBar: AppBar(
                  backgroundColor: context.colors.scaffoldBackground,
                  elevation: 0,
                  automaticallyImplyLeading: false,
                  leading: widget.isPicker
                      ? IconButton(
                          icon: Icon(CommonIcons.arrowBack, color: context.colors.textPrimary),
                          onPressed: () => Navigator.pop(context),
                        )
                      : null,
                  title: Text(widget.isPicker ? 'Select Participants' : 'New Chat', style: context.h1.copyWith(fontSize: 26)),
                  actions: [
                    if (widget.isPicker)
                      TextButton(
                        onPressed: _selectedUsers.isEmpty ? null : () => Navigator.pop(context, _selectedUsers),
                        child: Text('Done (${_selectedUsers.length})', 
                          style: context.bodyLarge.copyWith(
                            color: _selectedUsers.isEmpty ? context.colors.textHint : context.colors.primary,
                            fontWeight: FontWeight.bold
                          )
                        ),
                      ),
                  ],
                ),
                body: BlocBuilder<ContactsBloc, ContactsState>(
                  builder: (context, state) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSearchBar(),
                        Expanded(
                          child: RefreshIndicator(
                            onRefresh: () async {
                              _triggerSync();
                              await Future.delayed(const Duration(seconds: 1));
                            },
                            child: _buildSchatUsersTab(context, state),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              )
            : DefaultTabController(
                length: 2,
                child: Scaffold(
                  backgroundColor: context.colors.scaffoldBackground,
                  appBar: AppBar(
                    backgroundColor: context.colors.scaffoldBackground,
                    elevation: 0,
                    automaticallyImplyLeading: false,
                    leading: widget.isPicker
                        ? IconButton(
                            icon: Icon(CommonIcons.arrowBack, color: context.colors.textPrimary),
                            onPressed: () => Navigator.pop(context),
                          )
                        : null,
                    title: Text(widget.isPicker ? 'Select Participants' : 'New Chat', style: context.h1.copyWith(fontSize: 26)),
                    actions: [
                      if (widget.isPicker)
                        TextButton(
                          onPressed: _selectedUsers.isEmpty ? null : () => Navigator.pop(context, _selectedUsers),
                          child: Text('Done (${_selectedUsers.length})', 
                            style: context.bodyLarge.copyWith(
                              color: _selectedUsers.isEmpty ? context.colors.textHint : context.colors.primary,
                              fontWeight: FontWeight.bold
                            )
                          ),
                        ),
                    ],
                    bottom: TabBar(
                      indicatorColor: context.colors.primary,
                      labelColor: context.colors.primary,
                      unselectedLabelColor: context.colors.textSecondary,
                      labelStyle: context.titleSmall.copyWith(fontWeight: FontWeight.bold),
                      tabs: const [
                        Tab(text: 'Schat Users'),
                        Tab(text: 'All Contacts'),
                      ],
                    ),
                  ),
                  body: BlocBuilder<ContactsBloc, ContactsState>(
                    builder: (context, state) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSearchBar(),
                          Expanded(
                            child: RefreshIndicator(
                              onRefresh: () async {
                                _triggerSync();
                                await Future.delayed(const Duration(seconds: 1));
                              },
                              child: TabBarView(
                                children: [
                                  _buildSchatUsersTab(context, state),
                                  _buildAllContactsTab(context, state),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
        ),
      );
  }

  Widget _buildSchatUsersTab(BuildContext context, ContactsState state) {
    if (state is ContactsLoading) {
      return const Center(child: CircularProgressIndicator());
    } else if (state is ContactsLoaded) {
      final query = _searchQuery.toLowerCase();
      final syncedUsers = state.syncedContacts.where((user) {
        if (widget.excludeUserIds != null && widget.excludeUserIds!.contains(user.id)) {
          return false;
        }
        if (query.isEmpty) return true;
        final name = user.displayName.toLowerCase();
        final phone = user.phoneNumber.toLowerCase();
        return name.contains(query) || phone.contains(query);
      }).toList();

      if (syncedUsers.isEmpty) {
        return _buildEmptyState(context, isSchatOnly: true);
      }

      return ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: syncedUsers.length,
        itemBuilder: (context, index) => _buildSyncedUserTile(context, syncedUsers[index]),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildAllContactsTab(BuildContext context, ContactsState state) {
    if (state is ContactsLoading) {
      return const Center(child: CircularProgressIndicator());
    } else if (state is ContactsLoaded || state is ContactsPermissionDenied || state is ContactsInitial) {
      final query = _searchQuery.toLowerCase();
      final allContacts = (state is ContactsLoaded) ? state.contacts : <Contact>[];
      final hiddenPhones = (state is ContactsLoaded) ? state.hiddenPhoneNumbers : <String>[];

      final inviteContacts = allContacts.where((contact) {
        bool isHidden = contact.phones.any((phone) {
          String normalized = phone.number.replaceAll(RegExp(r'\D'), '');
          if (normalized.length > 10) {
            normalized = normalized.substring(normalized.length - 10);
          }
          return hiddenPhones.contains(normalized);
        });
        if (isHidden) return false;

        if (query.isEmpty) return true;
        final name = contact.displayName.toLowerCase();
        final phones = contact.phones.map((p) => p.number.toLowerCase()).join(' ');
        return name.contains(query) || phones.contains(query);
      }).toList();

      if (inviteContacts.isEmpty) {
        if (state is ContactsPermissionDenied) {
          return _buildPermissionDeniedState(context);
        }
        return _buildEmptyState(context, isSchatOnly: false);
      }

      return ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: inviteContacts.length,
        itemBuilder: (context, index) => _buildInviteContactTile(context, inviteContacts[index]),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildPermissionDeniedState(BuildContext context) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.6,
        alignment: Alignment.center,
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(CommonIcons.contactPhoneOutlined, size: 80, color: context.colors.grey),
            CommonSpaces.h16,
            const Text(
              'Contact permission is required to see your phone contacts.',
              textAlign: TextAlign.center,
            ),
            CommonSpaces.h16,
            ElevatedButton(
              onPressed: () => openAppSettings(),
              child: const Text('Open Settings'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, {required bool isSchatOnly}) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.6,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/no_data/no_contacts.png',
              width: 150,
              errorBuilder: (context, error, stackTrace) => Icon(
                CommonIcons.contactPhoneOutlined,
                size: 80,
                color: context.colors.grey,
              ),
            ),
            CommonSpaces.h24,
            Text(
              isSchatOnly ? 'No Schat users found' : 'No contacts found',
              style: context.h3.copyWith(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            CommonSpaces.h8,
            Text(
              isSchatOnly 
                ? 'Sync your contacts to see who is on Schat.' 
                : 'Grant contact permission to see your address book.',
              textAlign: TextAlign.center,
              style: context.bodyMedium.copyWith(color: context.colors.textSecondary),
            ),
            CommonSpaces.h32,
            if (isSchatOnly)
              PrimaryButton(
                text: 'Sync Now',
                onPressed: () {
                  _triggerSync();
                },
              ),
          ],
        ),
      ),
    );
  }

  // Removed old _buildBody as it's replaced by TabBarView
  // Keeping _buildSearchBar, _buildSyncedUserTile, _buildInviteContactTile as they are used by tabs


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
            hintText: 'Search contacts...',
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

  Widget _buildSyncedUserTile(BuildContext context, UserModel user) {
    final name = user.displayName;
    final isSelected = _selectedUsers.any((u) => u.id == user.id);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      onTap: () {
        if (widget.isPicker) {
          setState(() {
            if (isSelected) {
              _selectedUsers.removeWhere((u) => u.id == user.id);
            } else {
              if (_selectedUsers.length < widget.maxSelection) {
                _selectedUsers.add(user);
              }
            }
          });
          return;
        }
        _pendingParticipantId = user.id;
        context.read<ChatsBloc>().add(CreateChat(
          participantId: user.id,
          contactName: name,
          profilePictureUrl: user.profilePictureUrl,
        ));
      },
      leading: Stack(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: context.colors.primary.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: ClipOval(
              child: (user.profilePictureUrl != null && user.profilePictureUrl!.isNotEmpty)
                  ? Image.network(
                      user.profilePictureUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Center(
                          child: Text(
                            name.isNotEmpty ? name[0].toUpperCase() : '?',
                            style: context.bodyMedium.copyWith(
                              color: context.colors.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        );
                      },
                    )
                  : Center(
                      child: Text(
                        name.isNotEmpty ? name[0].toUpperCase() : '?',
                        style: context.bodyMedium.copyWith(
                          color: context.colors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
            ),
          ),
          if (user.isOnline)
            Positioned(
              right: 2,
              bottom: 2,
              child: Container(
                width: 11,
                height: 11,
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
      title: Text(
        name, 
        style: context.titleMedium.copyWith(fontWeight: FontWeight.bold)
      ),
      subtitle: Text(
        user.about ?? 'Hey there! I am using Schat.',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: context.bodySmall.copyWith(color: context.colors.textSecondary),
      ),
      trailing: widget.isPicker
          ? Checkbox(
              value: isSelected,
              onChanged: (val) {
                setState(() {
                  if (val == true) {
                    if (_selectedUsers.length < widget.maxSelection) {
                      _selectedUsers.add(user);
                    }
                  } else {
                    _selectedUsers.removeWhere((u) => u.id == user.id);
                  }
                });
              },
              activeColor: context.colors.primary,
              shape: const CircleBorder(),
            )
          : Icon(
              CommonIcons.chatBubble, 
              color: context.colors.primary, 
              size: 20
            ),
    );
  }

  Widget _buildInviteContactTile(BuildContext context, Contact contact) {
    final name = contact.displayName;
    final phone = contact.phones.isNotEmpty ? contact.phones.first.number : '';

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      onTap: () => _showInviteBottomSheet(name, phone),
      leading: CircleAvatar(
        radius: 28,
        backgroundColor: context.colors.textHint.withValues(alpha: 0.1),
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: context.bodyMedium.copyWith(
            color: context.colors.textSecondary,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      title: Text(
        name, 
        style: context.titleMedium.copyWith(fontWeight: FontWeight.bold)
      ),
      subtitle: Text(
        phone, 
        style: context.bodySmall.copyWith(color: context.colors.textSecondary)
      ),
      trailing: TextButton(
        onPressed: () => _showInviteBottomSheet(name, phone),
        child: Text(
          'INVITE',
          style: context.bodySmall.copyWith(
            color: context.colors.primary,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
