import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:fast_contacts/fast_contacts.dart';
import 'package:schat/features/chat_screen/chat_screen.dart';
import 'package:schat/features/dashboard_screen/src/presentation/bloc/contacts_bloc.dart';
import 'package:schat/features/dashboard_screen/src/presentation/bloc/contacts_event.dart';
import 'package:schat/features/dashboard_screen/src/presentation/bloc/contacts_state.dart';
import 'package:schat/features/dashboard_screen/src/presentation/bloc/chats_bloc.dart';
import 'package:schat/features/dashboard_screen/src/presentation/bloc/chats_event.dart';
import 'package:schat/features/dashboard_screen/src/presentation/bloc/chats_state.dart';
import 'package:schat/features/dashboard_screen/src/presentation/dashboard_page.dart';
import 'package:schat/features/profile_screen/src/domain/models/user_model.dart';
import 'package:schat/utils/common_colors.dart';
import 'package:schat/utils/common_fontstyles.dart';
import 'package:schat/utils/common_spaces.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:schat/injection.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class NewChatPage extends StatefulWidget {
  const NewChatPage({super.key});

  @override
  State<NewChatPage> createState() => _NewChatPageState();
}

class _NewChatPageState extends State<NewChatPage> with WidgetsBindingObserver {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _searchController.addListener(() {
      if (mounted) {
        setState(() {
          _searchQuery = _searchController.text.trim().toLowerCase();
        });
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      getIt<ContactsBloc>().add(const LoadContacts());
    }
  }

  final String _appLink = 'https://schat.app';
  final String _inviteTitle = 'Join Schat - Secure Messaging';

  void _showInviteBottomSheet(String name, String phone) {
    final String baseMessage =
        'Hey $name! I\'m using Schat for secure and private conversations. Join me there! 🔒\n\nDownload Schat at: $_appLink';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
        decoration: BoxDecoration(
          color: context.colors.scaffoldBackground,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
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
            CommonSpaces.h20,
            Text(
              'Invite $name',
              style: context.titleLarge.copyWith(fontWeight: FontWeight.bold),
            ),
            CommonSpaces.h20,
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildShareOption(
                  icon: Icons.sms_outlined,
                  label: 'SMS',
                  onTap: () {
                    Navigator.pop(context);
                    _launchSms(phone, baseMessage);
                  },
                ),
                _buildShareOption(
                  icon: Icons.chat_bubble_outline_rounded,
                  label: 'WhatsApp',
                  onTap: () {
                    Navigator.pop(context);
                    _launchWhatsApp(phone, baseMessage);
                  },
                ),
                _buildShareOption(
                  icon: Icons.mail_outline_rounded,
                  label: 'Email',
                  onTap: () {
                    Navigator.pop(context);
                    _launchEmail(baseMessage);
                  },
                ),
                _buildShareOption(
                  icon: Icons.share_rounded,
                  label: 'More',
                  onTap: () {
                    Navigator.pop(context);
                    Share.share(baseMessage, subject: _inviteTitle);
                  },
                ),
              ],
            ),
            CommonSpaces.h20,
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
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Column(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: const BoxDecoration(
                color: Color(0xFFE8F5E9),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: const Color(0xFF00873C), size: 26),
            ),
            CommonSpaces.h8,
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: context.colors.textPrimary,
              ),
            ),
          ],
        ),
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
    final String cleanPhone = phone.replaceAll(RegExp(r'\D'), '');
    final Uri uri = Uri.parse(
      'whatsapp://send?phone=$cleanPhone&text=${Uri.encodeComponent(message)}',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      final Uri webUri = Uri.parse(
        'https://wa.me/$cleanPhone?text=${Uri.encodeComponent(message)}',
      );
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
      queryParameters: {'subject': _inviteTitle, 'body': message},
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      Share.share(message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.colors.isDark;

    return MultiBlocProvider(
      providers: [
        BlocProvider.value(
          value: getIt<ContactsBloc>()..add(const LoadContacts()),
        ),
        BlocProvider.value(
          value: getIt<ChatsBloc>(),
        ),
      ],
      child: BlocListener<ChatsBloc, ChatsState>(
        listener: (context, state) {
          state.maybeWhen(
            chatCreated: (chat, contactName, profilePictureUrl) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatPage(
                    conversationId: chat.id,
                    contactName: contactName,
                    contactColor: const Color(0xFF00873C),
                    isOnline: false,
                    recipientId: chat.recipient.id,
                    profilePictureUrl: profilePictureUrl,
                    initialThemeColor: chat.themeColor,
                    initialDisappearingTimer: chat.disappearingTimer,
                  ),
                ),
              );
            },
            error: (message) {},
            orElse: () {},
          );
        },
        child: Scaffold(
          backgroundColor: context.colors.scaffoldBackground,
          body: Stack(
            children: [
              // Flowing Wave Lines Background matching Home Screen
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
                  children: [
                    _buildHeader(context),
                    _buildSearchBar(),
                    Expanded(
                      child: BlocBuilder<ContactsBloc, ContactsState>(
                        builder: (context, state) {
                          return _buildBody(context, state);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
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
          Text(
            'New Chat',
            style: context.h2.copyWith(
              fontWeight: FontWeight.bold,
              color: context.colors.textPrimary,
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
          style: TextStyle(color: context.colors.textPrimary),
          decoration: InputDecoration(
            hintText: 'Search contacts...',
            hintStyle: TextStyle(color: context.colors.textHint, fontSize: 14),
            prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF00873C), size: 20),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.clear, color: context.colors.textHint, size: 18),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
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

  Widget _buildBody(BuildContext context, ContactsState state) {
    if (state is ContactsLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF00873C)));
    } else if (state is ContactsLoaded) {
      final syncedUsers = state.syncedContacts.where((user) {
        if (_searchQuery.isEmpty) return true;
        final name = user.displayName.toLowerCase();
        final phone = user.phoneNumber.toLowerCase();
        return name.contains(_searchQuery) || phone.contains(_searchQuery);
      }).toList();

      final allContacts = state.contacts;
      final hiddenPhones = state.hiddenPhoneNumbers;

      final inviteContacts = allContacts.where((contact) {
        bool isHidden = contact.phones.any((phone) {
          String normalized = phone.number.replaceAll(RegExp(r'\D'), '');
          if (normalized.length > 10) {
            normalized = normalized.substring(normalized.length - 10);
          }
          return hiddenPhones.contains(normalized);
        });
        if (isHidden) return false;

        final notOnSchat = !syncedUsers.any((user) {
          return contact.phones.any((phone) {
            String normalized = phone.number.replaceAll(RegExp(r'\D'), '');
            if (normalized.length > 10) {
              normalized = normalized.substring(normalized.length - 10);
            }
            return user.phoneNumber.contains(normalized);
          });
        });
        if (!notOnSchat) return false;

        if (_searchQuery.isEmpty) return true;
        final name = contact.displayName.toLowerCase();
        final phones = contact.phones.map((p) => p.number.toLowerCase()).join(' ');
        return name.contains(_searchQuery) || phones.contains(_searchQuery);
      }).toList();

      if (syncedUsers.isEmpty && inviteContacts.isEmpty) {
        return _buildEmptyState(context);
      }

      return RefreshIndicator(
        onRefresh: () async {
          getIt<ContactsBloc>().add(const SyncContactsEvent());
          await Future.delayed(const Duration(seconds: 1));
        },
        color: const Color(0xFF00873C),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            if (syncedUsers.isNotEmpty) ...[
              const Padding(
                padding: EdgeInsets.only(left: 8, bottom: 8, top: 4),
                child: Text(
                  'Contacts on Schat',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF00873C),
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              ...syncedUsers.map((user) => _buildSyncedUserTile(context, user)),
              const SizedBox(height: 16),
            ],
            if (inviteContacts.isNotEmpty) ...[
              const Padding(
                padding: EdgeInsets.only(left: 8, bottom: 8, top: 4),
                child: Text(
                  'Invite to Schat',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF00873C),
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              ...inviteContacts.map((contact) => _buildInviteContactTile(context, contact)),
            ],
          ],
        ),
      );
    } else if (state is ContactsPermissionDenied) {
      return _buildPermissionDeniedState(context);
    }
    return const SizedBox.shrink();
  }

  Widget _buildSyncedUserTile(BuildContext context, UserModel user) {
    final name = user.displayName;
    final isDark = context.colors.isDark;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
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
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        onTap: () {
          context.read<ChatsBloc>().add(CreateChat(
            participantId: user.id,
            contactName: name,
            profilePictureUrl: user.profilePictureUrl,
          ));
        },
        leading: Stack(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: const Color(0xFFE8F5E9),
              backgroundImage: (user.profilePictureUrl != null && user.profilePictureUrl!.isNotEmpty)
                  ? CachedNetworkImageProvider(user.profilePictureUrl!)
                  : null,
              child: (user.profilePictureUrl == null || user.profilePictureUrl!.isEmpty)
                  ? Text(
                      name.isNotEmpty ? name[0].toUpperCase() : '?',
                      style: const TextStyle(
                        color: Color(0xFF00873C),
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                      ),
                    )
                  : null,
            ),
            if (user.isOnline)
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: const Color(0xFF00873C),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white,
                      width: 2,
                    ),
                  ),
                ),
              ),
          ],
        ),
        title: Text(
          name,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
            color: context.colors.textPrimary,
          ),
        ),
        subtitle: Text(
          user.about ?? 'Hey there! I am using Schat.',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: context.colors.textSecondary,
            fontSize: 13,
          ),
        ),
        trailing: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFFE8F5E9),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.chat_bubble_outline_rounded,
            color: Color(0xFF00873C),
            size: 18,
          ),
        ),
      ),
    );
  }

  Widget _buildInviteContactTile(BuildContext context, Contact contact) {
    final name = contact.displayName;
    final phone = contact.phones.isNotEmpty ? contact.phones.first.number : '';
    final isDark = context.colors.isDark;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
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
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        onTap: () => _showInviteBottomSheet(name, phone),
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: context.colors.textHint.withValues(alpha: 0.1),
          child: Text(
            name.isNotEmpty ? name[0].toUpperCase() : '?',
            style: TextStyle(
              color: context.colors.textSecondary,
              fontWeight: FontWeight.bold,
              fontSize: 17,
            ),
          ),
        ),
        title: Text(
          name,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
            color: context.colors.textPrimary,
          ),
        ),
        subtitle: Text(
          phone,
          style: TextStyle(
            color: context.colors.textSecondary,
            fontSize: 13,
          ),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFE8F5E9),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Text(
            'INVITE',
            style: TextStyle(
              color: Color(0xFF00873C),
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00873C).withValues(alpha: 0.15),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Icon(
                Icons.people_outline_rounded,
                size: 42,
                color: Color(0xFF00873C),
              ),
            ),
            CommonSpaces.h20,
            Text(
              'No contacts found',
              style: context.titleLarge.copyWith(fontWeight: FontWeight.bold),
            ),
            CommonSpaces.h8,
            Text(
              'Sync your address book to discover contacts and chat securely.',
              textAlign: TextAlign.center,
              style: TextStyle(color: context.colors.textSecondary, fontSize: 14, height: 1.4),
            ),
            CommonSpaces.h24,
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    getIt<ContactsBloc>().add(const DiscoverContactsEvent());
                  },
                  icon: const Icon(Icons.explore_rounded, size: 18),
                  label: const Text('Explore All Users'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00873C),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    elevation: 2,
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () {
                    getIt<ContactsBloc>().add(const SyncContactsEvent());
                  },
                  icon: const Icon(Icons.sync_rounded, size: 18),
                  label: const Text('Sync Contacts'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF00873C),
                    side: const BorderSide(color: Color(0xFF00873C)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionDeniedState(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: context.colors.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.contacts_rounded, size: 40, color: context.colors.error),
            ),
            CommonSpaces.h20,
            Text(
              'Contacts Access Required',
              style: context.titleLarge.copyWith(fontWeight: FontWeight.bold),
            ),
            CommonSpaces.h8,
            Text(
              'Allow Schat to access your contacts to start new conversations.',
              textAlign: TextAlign.center,
              style: TextStyle(color: context.colors.textSecondary, fontSize: 14),
            ),
            CommonSpaces.h24,
            ElevatedButton(
              onPressed: () => openAppSettings(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00873C),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text('Open Settings'),
            ),
          ],
        ),
      ),
    );
  }
}
