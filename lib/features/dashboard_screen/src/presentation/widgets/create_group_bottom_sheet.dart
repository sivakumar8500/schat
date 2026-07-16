import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:schat/features/dashboard_screen/src/domain/repositories/contacts_repository.dart';
import 'package:schat/features/profile_screen/src/domain/models/user_model.dart';
import 'package:schat/features/dashboard_screen/src/presentation/bloc/contacts_bloc.dart';
import 'package:schat/features/dashboard_screen/src/presentation/bloc/contacts_event.dart';
import 'package:schat/features/dashboard_screen/src/presentation/bloc/contacts_state.dart';
import 'package:schat/features/dashboard_screen/src/presentation/bloc/group_bloc.dart';
import 'package:schat/features/dashboard_screen/src/presentation/bloc/group_event.dart';
import 'package:schat/features/dashboard_screen/src/presentation/bloc/group_state.dart';
import 'package:schat/features/profile_screen/src/domain/repositories/profile_repository.dart';
import 'package:schat/injection.dart';
import 'package:schat/utils/common_colors.dart';
import 'package:schat/utils/common_fontstyles.dart';
import 'package:schat/utils/common_notifications.dart';
import 'package:schat/utils/common_spaces.dart';

class CreateGroupBottomSheet extends StatefulWidget {
  const CreateGroupBottomSheet({super.key});

  @override
  State<CreateGroupBottomSheet> createState() => _CreateGroupBottomSheetState();
}

class _CreateGroupBottomSheetState extends State<CreateGroupBottomSheet> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final Set<String> _selectedUserIds = {};
  XFile? _selectedImage;
  bool _isUploadingImage = false;

  List<UserModel> _cachedUsers = [];
  bool _isLoadingContacts = true;

  @override
  void initState() {
    super.initState();
    _loadLocalContacts();
  }

  Future<void> _loadLocalContacts() async {
    try {
      final repository = getIt<ContactsRepository>();
      final users = await repository.getCachedContacts();
      setState(() {
        _cachedUsers = users;
        _isLoadingContacts = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingContacts = false;
      });
    }
  }

  Future<void> _pickGroupImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (image != null) {
      setState(() {
        _selectedImage = image;
      });
    }
  }

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
            Navigator.pop(context, state.chat);
          } else if (state is GroupError) {
            context.showErrorNotification(state.message);
          }
        },
        builder: (context, state) {
          final isLoading = state is GroupLoading || _isUploadingImage;

          return Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            decoration: BoxDecoration(
              color: context.colors.scaffoldBackground,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: context.colors.textSecondary.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  CommonSpaces.h16,
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Create New Group',
                        style: context.titleLarge.copyWith(fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: Icon(Icons.refresh, color: context.colors.primary),
                        tooltip: 'Sync Contacts',
                        onPressed: () {
                          setState(() => _isLoadingContacts = true);
                          context.read<ContactsBloc>().add(const SyncContactsEvent());
                        },
                      ),
                    ],
                  ),
                  CommonSpaces.h16,
                  Center(
                    child: GestureDetector(
                      onTap: _pickGroupImage,
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundColor: context.colors.primary.withValues(alpha: 0.1),
                            backgroundImage: _selectedImage != null
                                ? FileImage(File(_selectedImage!.path))
                                : null,
                            child: _selectedImage == null
                                ? Icon(Icons.group_rounded, size: 40, color: context.colors.primary)
                                : null,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: context.colors.primary,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                            ),
                          ),
                        ],
                      ),
                    ),
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
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.4,
                    ),
                    child: BlocListener<ContactsBloc, ContactsState>(
                      listener: (context, contactsState) {
                        if (contactsState is ContactsLoaded) {
                          _loadLocalContacts();
                        } else if (contactsState is ContactsFailure) {
                          setState(() => _isLoadingContacts = false);
                          context.showErrorNotification('Failed to sync contacts: ${contactsState.errorMessage}');
                        }
                      },
                      child: Builder(
                        builder: (context) {
                          if (_isLoadingContacts) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          if (_cachedUsers.isEmpty) {
                            return Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text('No contacts found'),
                                  CommonSpaces.h12,
                                  ElevatedButton.icon(
                                    onPressed: () {
                                      setState(() => _isLoadingContacts = true);
                                      context.read<ContactsBloc>().add(const SyncContactsEvent());
                                    },
                                    icon: const Icon(Icons.sync, color: Colors.white, size: 18),
                                    label: const Text('Sync Contacts', style: TextStyle(color: Colors.white)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: context.colors.primary,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }
                          return RefreshIndicator(
                            onRefresh: () async {
                              context.read<ContactsBloc>().add(const SyncContactsEvent());
                            },
                            child: ListView.builder(
                              shrinkWrap: true,
                              physics: const AlwaysScrollableScrollPhysics(),
                              itemCount: _cachedUsers.length,
                              itemBuilder: (context, index) {
                                final user = _cachedUsers[index];
                                final isSelected = _selectedUserIds.contains(user.id);
                                return CheckboxListTile(
                                  value: isSelected,
                                  title: Text(user.displayName),
                                  secondary: CircleAvatar(
                                    backgroundColor: context.colors.primary.withValues(alpha: 0.1),
                                    child: Text(
                                      user.displayName.isNotEmpty ? user.displayName[0].toUpperCase() : '?',
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
                            ),
                          );
                        },
                      ),
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
                  CommonSpaces.h20,
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _createGroup(BuildContext context) async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      context.showErrorNotification('Please enter group name');
      return;
    }
    if (_selectedUserIds.length < 3) {
      context.showErrorNotification('Please select at least 3 members');
      return;
    }

    String? uploadedUrl;
    if (_selectedImage != null) {
      setState(() {
        _isUploadingImage = true;
      });
      try {
        final bytes = await _selectedImage!.readAsBytes();
        uploadedUrl = await getIt<ProfileRepository>().uploadProfilePicture(
          filePath: _selectedImage!.path,
          fileName: _selectedImage!.name,
          mimeType: 'image/jpeg',
          fileSizeBytes: bytes.length,
          fileBytes: bytes,
        );
      } catch (e) {
        if (mounted && context.mounted) {
          context.showErrorNotification('Failed to upload group image: $e');
          setState(() {
            _isUploadingImage = false;
          });
        }
        return;
      }
      if (mounted) {
        setState(() {
          _isUploadingImage = false;
        });
      }
    }

    if (mounted && context.mounted) {
      context.read<GroupBloc>().add(CreateGroupEvent(
        name: name,
        description: _descriptionController.text.trim(),
        participantIds: _selectedUserIds.toList(),
        groupPictureUrl: uploadedUrl,
        groupImageUrl: uploadedUrl,
      ));
    }
  }
}
