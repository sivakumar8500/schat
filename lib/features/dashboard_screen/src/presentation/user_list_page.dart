import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:schat/features/chat_screen/chat_screen.dart';
import 'package:schat/features/dashboard_screen/src/presentation/bloc/contacts_bloc.dart';
import 'package:schat/features/dashboard_screen/src/presentation/bloc/contacts_event.dart';
import 'package:schat/features/dashboard_screen/src/presentation/bloc/contacts_state.dart';
import 'package:schat/utils/common_colors.dart';
import 'package:schat/utils/common_fontstyles.dart';
import 'package:schat/utils/common_icons.dart';
import 'package:schat/utils/common_spaces.dart';
import 'package:permission_handler/permission_handler.dart';

class UserListPage extends StatelessWidget {
  const UserListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ContactsBloc()..add(LoadContacts()),
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
    );
  }

  Widget _buildBody(BuildContext context, ContactsState state) {
    if (state is ContactsLoading) {
      return const Center(child: CircularProgressIndicator());
    } else if (state is ContactsLoaded) {
      if (state.contacts.isEmpty) {
        return const Center(child: Text('No contacts found'));
      }
      return ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: state.contacts.length,
        separatorBuilder: (context, index) => const Divider(height: 1, indent: 72),
        itemBuilder: (context, index) {
          final contact = state.contacts[index];
          final name = contact.displayName;
          final phone = contact.phones.isNotEmpty ? contact.phones.first.number : '';

          return ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatPage(
                    contactName: name,
                    contactColor: Colors.blue, // Default color for real contacts
                    isOnline: false,
                  ),
                ),
              );
            },
            leading: CircleAvatar(
              radius: 28,
              backgroundColor: context.colors.primary.withOpacity(0.15),
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: TextStyle(
                  color: context.colors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
            title: Text(name, style: context.titleMedium.copyWith(fontWeight: FontWeight.bold)),
            subtitle: Text(phone, style: context.bodySmall.copyWith(color: context.colors.textSecondary)),
            trailing: Icon(CommonIcons.chatBubble, color: context.colors.primary.withOpacity(0.5), size: 20),
          );
        },
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
}
