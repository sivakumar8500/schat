import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:schat/features/profile_screen/src/domain/repositories/profile_repository.dart';
import 'package:schat/features/profile_screen/src/presentation/bloc/emergency_contacts_cubit.dart';
import 'package:schat/features/profile_screen/src/presentation/bloc/emergency_contacts_state.dart';
import 'package:schat/injection.dart';
import 'package:schat/utils/common_colors.dart';
import 'package:schat/utils/common_fontstyles.dart';
import 'package:schat/utils/common_notifications.dart';
import 'package:schat/utils/common_spaces.dart';
import 'package:intl/intl.dart';

class EmergencyContactsPage extends StatelessWidget {
  const EmergencyContactsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => EmergencyContactsCubit(getIt<ProfileRepository>())..fetchContacts(),
      child: const _EmergencyContactsView(),
    );
  }
}

class _EmergencyContactsView extends StatefulWidget {
  const _EmergencyContactsView();

  @override
  State<_EmergencyContactsView> createState() => _EmergencyContactsViewState();
}

class _EmergencyContactsViewState extends State<_EmergencyContactsView> {
  void _showAddContactDialog(BuildContext context) {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          backgroundColor: context.colors.scaffoldBackground,
          title: Text('Add Emergency Contact', style: context.titleLarge),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Contact Name',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              CommonSpaces.h16,
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: Text('Cancel', style: TextStyle(color: context.colors.textSecondary)),
            ),
            ElevatedButton(
              onPressed: () {
                final name = nameController.text.trim();
                final phone = phoneController.text.trim();
                if (name.isEmpty || phone.isEmpty) {
                  context.showErrorNotification('Name and Phone are required');
                  return;
                }
                Navigator.pop(dialogCtx);
                context.read<EmergencyContactsCubit>().addContact(name, phone);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: context.colors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Add', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _showEditContactDialog(BuildContext context, String id, String initialName) {
    final nameController = TextEditingController(text: initialName);

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          backgroundColor: context.colors.scaffoldBackground,
          title: Text('Edit Contact', style: context.titleLarge),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Contact Name',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: Text('Cancel', style: TextStyle(color: context.colors.textSecondary)),
            ),
            ElevatedButton(
              onPressed: () {
                final name = nameController.text.trim();
                if (name.isEmpty) {
                  context.showErrorNotification('Name is required');
                  return;
                }
                Navigator.pop(dialogCtx);
                context.read<EmergencyContactsCubit>().updateContact(id, name);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: context.colors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Save', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteContactDialog(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          backgroundColor: context.colors.scaffoldBackground,
          title: Text('Delete Contact', style: context.titleLarge),
          content: const Text('Are you sure you want to delete this emergency contact?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: Text('Cancel', style: TextStyle(color: context.colors.textSecondary)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogCtx);
                context.read<EmergencyContactsCubit>().deleteContact(id);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Delete', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.scaffoldBackground,
      appBar: AppBar(
        title: const Text('Emergency Contacts'),
        backgroundColor: context.colors.scaffoldBackground,
        elevation: 0,
        foregroundColor: context.colors.textPrimary,
      ),
      body: BlocConsumer<EmergencyContactsCubit, EmergencyContactsState>(
        listener: (context, state) {
          if (state is EmergencyContactsAddSuccess) {
            context.showInfoNotification('Emergency contact operation successful');
          } else if (state is EmergencyContactsAddError) {
            context.showErrorNotification(state.message);
          } else if (state is EmergencyContactsError) {
            context.showErrorNotification(state.message);
          }
        },
        builder: (context, state) {
          if (state is EmergencyContactsLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is EmergencyContactsLoaded) {
            final response = state.response;
            final personalContacts = response.personalContacts;
            final defaultContacts = response.defaultContacts;
            
            if (personalContacts.isEmpty && defaultContacts.isEmpty) {
              return const Center(child: Text('No emergency contacts found.'));
            }
            
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (personalContacts.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Text('Personal Contacts', style: context.titleMedium.copyWith(fontWeight: FontWeight.bold)),
                  ),
                  ...personalContacts.map((contact) {
                    final date = contact.createdAtInt != null 
                        ? DateTime.fromMillisecondsSinceEpoch(contact.createdAtInt! * 1000)
                        : DateTime.now();
                    final formattedDate = DateFormat('MMM d, yyyy h:mm a').format(date.toLocal());
                    return Card(
                      color: Theme.of(context).cardColor,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: context.colors.primary.withValues(alpha: 0.1),
                          child: Icon(Icons.person, color: context.colors.primary),
                        ),
                        title: Text(contact.contactName, style: context.titleMedium),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(contact.phoneNumber),
                            Text('Added $formattedDate', style: context.bodySmall.copyWith(color: context.colors.textHint)),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, size: 20),
                              onPressed: () => _showEditContactDialog(context, contact.id, contact.contactName),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                              onPressed: () => _showDeleteContactDialog(context, contact.id),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
                if (defaultContacts.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
                    child: Text('Default Helplines', style: context.titleMedium.copyWith(fontWeight: FontWeight.bold)),
                  ),
                  ...defaultContacts.map((contact) {
                    return Card(
                      color: Theme.of(context).cardColor,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.red.withValues(alpha: 0.1),
                          child: const Icon(Icons.health_and_safety, color: Colors.red),
                        ),
                        title: Text(contact.name, style: context.titleMedium),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(contact.phoneNumber, style: const TextStyle(fontWeight: FontWeight.bold)),
                            Text(contact.description, style: context.bodySmall.copyWith(color: context.colors.textHint)),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ],
            );
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddContactDialog(context),
        backgroundColor: context.colors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
