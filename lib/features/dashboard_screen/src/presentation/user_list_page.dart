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

class UserListPage extends StatefulWidget {
  const UserListPage({super.key});

  @override
  State<UserListPage> createState() => _UserListPageState();
}

class _UserListPageState extends State<UserListPage> {
  String? _pendingParticipantId;

  final String _appLink = 'https://schat.app';
  final String _inviteTitle = 'Join Schat - Secure Messaging';

  void _showInviteBottomSheet(String name, String phone) {
    final String baseMessage = 'Hey $name! I\'m using Schat for secure and private conversations. Join me there! 🔒\n\nDownload Schat at: $_appLink';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
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
                  icon: Icons.sms_outlined,
                  label: 'SMS',
                  onTap: () {
                    Navigator.pop(context);
                    _launchSms(phone, baseMessage);
                  },
                ),
                _buildShareOption(
                  icon: Icons.chat_bubble_outline,
                  label: 'WhatsApp',
                  onTap: () {
                    Navigator.pop(context);
                    _launchWhatsApp(phone, baseMessage);
                  },
                ),
                _buildShareOption(
                  icon: Icons.mail_outline,
                  label: 'Email',
                  onTap: () {
                    Navigator.pop(context);
                    _launchEmail(baseMessage);
                  },
                ),
                _buildShareOption(
                  icon: Icons.share_outlined,
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
        BlocProvider(
          create: (context) => ContactsBloc()..add(const LoadContacts()),
        ),
        BlocProvider(
          create: (context) => getIt<ChatsBloc>(),
        ),
      ],
      child: BlocListener<ChatsBloc, ChatsState>(
        listener: (context, state) {
          state.maybeWhen(
            chatCreated: (chat, contactName, profilePictureUrl) {
              if (_pendingParticipantId != null) {
                context.read<ContactsBloc>().add(RemoveContact(_pendingParticipantId!));
                _pendingParticipantId = null;
              }
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
                  ),
                ),
              );
            },
            error: (message) {
              _pendingParticipantId = null;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(message)),
              );
            },
            orElse: () {},
          );
        },
        child: Scaffold(
          backgroundColor: context.colors.scaffoldBackground,
          body: BlocBuilder<ContactsBloc, ContactsState>(
            builder: (context, state) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                    child: Text('New Chat', style: context.h1.copyWith(fontSize: 26)),
                  ),
                  Expanded(
                    child: _buildBody(context, state),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, ContactsState state) {
    if (state is ContactsLoading) {
      return const Center(child: CircularProgressIndicator());
    } else if (state is ContactsLoaded) {
      if (state.contacts.isEmpty && state.syncedContacts.isEmpty) {
        return _buildEmptyState(context);
      }

      final syncedUsers = state.syncedContacts;
      final allContacts = state.contacts;
      final hiddenPhones = state.hiddenPhoneNumbers;

      final inviteContacts = allContacts.where((contact) {
        // Exclude if phone number is in hidden list
        bool isHidden = contact.phones.any((phone) {
          String normalized = phone.number.replaceAll(RegExp(r'\D'), '');
          if (normalized.length > 10) {
            normalized = normalized.substring(normalized.length - 10);
          }
          return hiddenPhones.contains(normalized);
        });
        if (isHidden) return false;

        return !syncedUsers.any((user) {
          return contact.phones.any((phone) {
            String normalized = phone.number.replaceAll(RegExp(r'\D'), '');
            if (normalized.length > 10) {
              normalized = normalized.substring(normalized.length - 10);
            }
            return user.phoneNumber.contains(normalized);
          });
        });
      }).toList();

      if (syncedUsers.isEmpty && inviteContacts.isEmpty) {
        return _buildEmptyState(context);
      }

      return ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          if (syncedUsers.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              child: Text(
                'Contacts on Schat',
                style: context.titleMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  color: context.colors.primary,
                ),
              ),
            ),
            ...syncedUsers.map((user) => _buildSyncedUserTile(context, user)),
            const Divider(height: 32),
          ],
          if (inviteContacts.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              child: Text(
                'Invite to Schat',
                style: context.titleMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  color: context.colors.textSecondary,
                ),
              ),
            ),
            ...inviteContacts.map((contact) => _buildInviteContactTile(context, contact)),
          ],
        ],
      );
    } else if (state is ContactsPermissionDenied) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Contact permission is required to start a new chat.',
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
    } else if (state is ContactsFailure) {
      return Center(child: Text('Error: ${state.errorMessage}'));
    }
    return const SizedBox.shrink();
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/no_data/no_contacts.png',
              width: 250,
              errorBuilder: (context, error, stackTrace) => const Icon(
                Icons.contact_phone_outlined,
                size: 100,
                color: Colors.grey,
              ),
            ),
            CommonSpaces.h24,
            Text(
              'No contacts found',
              style: context.h3.copyWith(fontWeight: FontWeight.bold),
            ),
            CommonSpaces.h8,
            Text(
              'Sync your contacts to see who is on Schat.',
              textAlign: TextAlign.center,
              style: context.bodyMedium.copyWith(color: context.colors.textSecondary),
            ),
            CommonSpaces.h32,
            PrimaryButton(
              text: 'Sync Now',
              onPressed: () {
                context.read<ContactsBloc>().add(const SyncContactsEvent());
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSyncedUserTile(BuildContext context, UserModel user) {
    final name = user.username ?? user.phoneNumber;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      onTap: () {
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
            width: 56,
            height: 56,
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
                            style: TextStyle(
                              color: context.colors.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        );
                      },
                    )
                  : Center(
                      child: Text(
                        name.isNotEmpty ? name[0].toUpperCase() : '?',
                        style: TextStyle(
                          color: context.colors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
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
      trailing: Icon(
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
          style: TextStyle(
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
          style: TextStyle(
            color: context.colors.primary,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
