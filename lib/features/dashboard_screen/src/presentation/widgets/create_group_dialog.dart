import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:schat/features/dashboard_screen/src/presentation/bloc/contacts_bloc.dart';
import 'package:schat/features/dashboard_screen/src/presentation/bloc/contacts_state.dart';
import 'package:schat/features/dashboard_screen/src/presentation/bloc/group_bloc.dart';
import 'package:schat/features/dashboard_screen/src/presentation/bloc/group_event.dart';
import 'package:schat/features/dashboard_screen/src/presentation/bloc/group_state.dart';
import 'package:schat/utils/common_colors.dart';
import 'package:schat/utils/common_fontstyles.dart';
import 'package:schat/utils/common_notifications.dart';
import 'package:schat/utils/common_spaces.dart';

class CreateGroupDialog extends StatefulWidget {
  const CreateGroupDialog({super.key});

  @override
  State<CreateGroupDialog> createState() => _CreateGroupDialogState();
}

class _CreateGroupDialogState extends State<CreateGroupDialog> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final Set<String> _selectedUserIds = {};

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => GroupBloc(),
      child: BlocConsumer<GroupBloc, GroupState>(
        listener: (context, state) {
          if (state is GroupSuccess) {
            context.showSuccessNotification('Group created successfully');
            Navigator.pop(context, state.chat);
          } else if (state is GroupError) {
            context.showErrorNotification(state.message);
          }
        },
        builder: (context, state) {
          final isLoading = state is GroupLoading;

          return Dialog(
            backgroundColor: context.colors.scaffoldBackground,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Create New Group',
                    style: context.titleLarge.copyWith(fontWeight: FontWeight.bold),
                  ),
                  CommonSpaces.h16,
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      hintText: 'Group Name',
                      filled: true,
                      fillColor: context.colors.lightBackground,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  CommonSpaces.h12,
                  TextField(
                    controller: _descriptionController,
                    decoration: InputDecoration(
                      hintText: 'Description (Optional)',
                      filled: true,
                      fillColor: context.colors.lightBackground,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  CommonSpaces.h16,
                  Text(
                    'Select Members (Min 3)',
                    style: context.bodySmall.copyWith(fontWeight: FontWeight.bold),
                  ),
                  CommonSpaces.h8,
                  SizedBox(
                    height: 200,
                    child: BlocBuilder<ContactsBloc, ContactsState>(
                      builder: (context, contactsState) {
                        if (contactsState is ContactsLoaded) {
                          final users = contactsState.syncedContacts;
                          if (users.isEmpty) {
                            return const Center(child: Text('No contacts found'));
                          }
                          return ListView.builder(
                            shrinkWrap: true,
                            itemCount: users.length,
                            itemBuilder: (context, index) {
                              final user = users[index];
                              final isSelected = _selectedUserIds.contains(user.id);
                              return CheckboxListTile(
                                value: isSelected,
                                title: Text(user.username ?? user.phoneNumber),
                                secondary: CircleAvatar(
                                  backgroundColor: context.colors.primary.withValues(alpha: 0.1),
                                  child: Text(
                                    (user.username ?? user.phoneNumber)[0].toUpperCase(),
                                    style: TextStyle(color: context.colors.primary),
                                  ),
                                ),
                                onChanged: (value) {
                                  setState(() {
                                    if (value == true) {
                                      _selectedUserIds.add(user.id);
                                    } else {
                                      _selectedUserIds.remove(user.id);
                                    }
                                  });
                                },
                              );
                            },
                          );
                        }
                        return const Center(child: CircularProgressIndicator());
                      },
                    ),
                  ),
                  CommonSpaces.h20,
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: isLoading ? null : () => Navigator.pop(context),
                        child: Text('Cancel', style: TextStyle(color: context.colors.textSecondary)),
                      ),
                      CommonSpaces.w12,
                      ElevatedButton(
                        onPressed: isLoading ? null : () => _createGroup(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: context.colors.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : const Text('Create', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _createGroup(BuildContext context) {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      context.showErrorNotification('Please enter group name');
      return;
    }
    if (_selectedUserIds.length < 3) {
      context.showErrorNotification('Please select at least 3 members');
      return;
    }

    context.read<GroupBloc>().add(CreateGroupEvent(
      name: name,
      description: _descriptionController.text.trim(),
      participantIds: _selectedUserIds.toList(),
    ));
  }
}
