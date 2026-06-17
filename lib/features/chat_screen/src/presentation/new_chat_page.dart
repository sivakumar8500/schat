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

class NewChatPage extends StatefulWidget {
  const NewChatPage({super.key});

  @override
  State<NewChatPage> createState() => _NewChatPageState();
}

class _NewChatPageState extends State<NewChatPage> {
  String? _pendingParticipantId;

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
            chatCreated: (chat, contactName, {profilePictureUrl}) {
              if (_pendingParticipantId != null) {
                context.read<ContactsBloc>().add(RemoveContact(_pendingParticipantId!));
                _pendingParticipantId = null;
              }
              Navigator.pushReplacement(
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
          appBar: AppBar(
            backgroundColor: context.colors.scaffoldBackground,
            elevation: 0,
            leading: IconButton(
              icon: Icon(CommonIcons.arrowBack, color: context.colors.textPrimary),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              'New Chat',
              style: context.h1.copyWith(fontSize: 22),
            ),
          ),
          body: BlocBuilder<ContactsBloc, ContactsState>(
            builder: (context, state) {
              return _buildBody(context, state);
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
        ));
      },
      leading: CircleAvatar(
        radius: 28,
        backgroundColor: context.colors.primary.withOpacity(0.15),
        backgroundImage: user.profilePictureUrl != null 
            ? NetworkImage(user.profilePictureUrl!) 
            : null,
        child: user.profilePictureUrl == null
            ? Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: TextStyle(
                  color: context.colors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              )
            : null,
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
      onTap: () {
        // Handle invite
      },
      leading: CircleAvatar(
        radius: 28,
        backgroundColor: context.colors.textHint.withOpacity(0.1),
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
        onPressed: () {
          // Handle invite
        },
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
