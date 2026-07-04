import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:schat/core/storage/storage_service.dart';
import 'package:schat/features/dashboard_screen/src/presentation/bloc/contacts_bloc.dart';
import 'package:schat/features/dashboard_screen/src/presentation/bloc/contacts_state.dart';
import 'package:schat/features/intro_screen/intro_screen.dart';
import 'package:schat/features/profile_screen/src/presentation/bloc/profile_bloc.dart';
import 'package:schat/features/profile_screen/src/presentation/bloc/profile_event.dart';
import 'package:schat/features/profile_screen/src/presentation/bloc/profile_state.dart';
import 'package:schat/features/profile_screen/src/presentation/profile_page.dart';
import 'package:schat/features/chat_screen/src/presentation/full_screen_image_page.dart';
import 'package:schat/presentation/pages/blocked_users_page.dart';
import 'package:schat/presentation/pages/tickets_page.dart';
import 'package:schat/injection.dart';
import 'package:schat/utils/common_colors.dart';
import 'package:schat/utils/common_fontstyles.dart';
import 'package:schat/utils/common_icons.dart';
import 'package:schat/utils/common_notifications.dart';
import 'package:schat/utils/common_spaces.dart';
import 'package:schat/utils/theme_controller.dart';

class ProfileSettingsPage extends StatefulWidget {
  final String username;
  final String? profilePicUrl;

  const ProfileSettingsPage({
    super.key,
    required this.username,
    this.profilePicUrl,
  });

  @override
  State<ProfileSettingsPage> createState() => _ProfileSettingsPageState();
}

class _ProfileSettingsPageState extends State<ProfileSettingsPage> {
  late String _currentUsername;
  String? _currentImageUrl;
  String _currentAbout = "Hey there! I am using Schat.";
  String _currentEmail = "";
  XFile? _localImageFile;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _currentUsername = widget.username;
    _currentImageUrl = widget.profilePicUrl;
    _currentEmail = getIt<StorageService>().getEmail() ?? "";
  }

  void _showEditProfileBottomSheet(BuildContext context) {
    final usernameController = TextEditingController(text: _currentUsername);
    final aboutController = TextEditingController(text: _currentAbout);
    final emailController = TextEditingController(text: _currentEmail);
    _localImageFile = null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => StatefulBuilder(
        builder: (sheetCtx, setSheetState) {
          Future<void> pickImage() async {
            try {
              final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
              if (pickedFile != null) {
                setSheetState(() {
                  _localImageFile = pickedFile;
                });
              }
            } catch (e) {
              debugPrint('Error picking image: $e');
            }
          }

          ImageProvider? getImageProvider() {
            if (_localImageFile != null) {
              if (kIsWeb) {
                return NetworkImage(_localImageFile!.path);
              } else {
                return FileImage(File(_localImageFile!.path));
              }
            }
            if (_currentImageUrl != null && _currentImageUrl!.isNotEmpty) {
              return NetworkImage(_currentImageUrl!);
            }
            return null;
          }

          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(sheetCtx).viewInsets.bottom,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: sheetCtx.colors.scaffoldBackground,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text('Edit Profile', style: sheetCtx.titleLarge),
                  CommonSpaces.h24,
                  GestureDetector(
                    onTap: pickImage,
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: sheetCtx.colors.primary,
                          backgroundImage: getImageProvider(),
                          child: getImageProvider() == null
                              ? const Icon(Icons.person, size: 50, color: Colors.white)
                              : null,
                        ),
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: sheetCtx.colors.primary,
                            shape: BoxShape.circle,
                            border: Border.all(color: sheetCtx.colors.scaffoldBackground, width: 2),
                          ),
                          child: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                  CommonSpaces.h24,
                  TextField(
                    controller: usernameController,
                    maxLength: 60,
                    decoration: InputDecoration(
                      labelText: 'Username',
                      labelStyle: TextStyle(color: sheetCtx.colors.textSecondary),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  CommonSpaces.h16,
                  TextField(
                    controller: aboutController,
                    maxLength: 100,
                    decoration: InputDecoration(
                      labelText: 'About Us',
                      labelStyle: TextStyle(color: sheetCtx.colors.textSecondary),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  CommonSpaces.h16,
                  TextField(
                    controller: emailController,
                    decoration: InputDecoration(
                      labelText: 'Email (Optional)',
                      labelStyle: TextStyle(color: sheetCtx.colors.textSecondary),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  CommonSpaces.h24,
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () async {
                        final username = usernameController.text.trim();
                        final about = aboutController.text.trim();
                        final email = emailController.text.trim();

                        if (username.isEmpty) {
                          context.showErrorNotification('Username cannot be empty');
                          return;
                        }
                        if (username.length < 3) {
                          context.showErrorNotification('Username must be at least 3 characters long');
                          return;
                        }
                        if (username.length > 60) {
                          context.showErrorNotification('Username cannot exceed 60 characters');
                          return;
                        }
                        if (!RegExp(r'^[a-zA-Z]').hasMatch(username)) {
                          context.showErrorNotification('Username must start with an alphabetical character');
                          return;
                        }
                        if (about.length > 100) {
                          context.showErrorNotification('About Us cannot exceed 100 characters');
                          return;
                        }

                        getIt<StorageService>().saveEmail(email);

                        Uint8List? fileBytes;
                        if (_localImageFile != null) {
                          try {
                            fileBytes = await _localImageFile!.readAsBytes();
                          } catch (e) {
                            debugPrint('Error reading picked file bytes: $e');
                          }
                        }

                        if (context.mounted) {
                          context.read<ProfileBloc>().add(UpdateProfileEvent(
                                username: username,
                                about: about,
                                imagePath: _localImageFile?.path ?? _currentImageUrl,
                                fileBytes: fileBytes,
                              ));
                        }

                        Navigator.pop(sheetCtx);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: sheetCtx.colors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Save', style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<ProfileBloc>(
          create: (context) => ProfileBloc()..add(const LoadProfileEvent()),
        ),
        BlocProvider<ContactsBloc>.value(
          value: getIt<ContactsBloc>(),
        ),
      ],
      child: BlocListener<ContactsBloc, ContactsState>(
        listener: (context, state) {
          if (state is ContactsLoaded) {
            context.showSuccessNotification('Contacts synced successfully');
          } else if (state is ContactsFailure) {
            context.showErrorNotification('Failed to sync contacts: ${state.errorMessage}');
          }
        },
        child: BlocConsumer<ProfileBloc, ProfileState>(
          listener: (context, state) {
            if (state is ProfileLoaded) {
              setState(() {
                _currentUsername = state.username;
                _currentImageUrl = state.imagePath;
                _currentAbout = state.user?.about ?? "Hey there! I am using Schat.";
                _currentEmail = getIt<StorageService>().getEmail() ?? "";
              });
            } else if (state is ProfileLogoutSuccess) {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const IntroPage()),
                (Route<dynamic> route) => false,
              );
            } else if (state is ProfileSuccess) {
              context.read<ProfileBloc>().add(const LoadProfileEvent());
            }
          },
          builder: (context, state) {
            return Scaffold(
              backgroundColor: context.colors.scaffoldBackground,
              appBar: AppBar(
                title: const Text('Settings'),
                backgroundColor: context.colors.scaffoldBackground,
                elevation: 0,
                foregroundColor: context.colors.textPrimary,
              ),
              body: ListView(
                children: [
                  // Profile Header
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: GestureDetector(
                      onTap: () {
                        if (_currentImageUrl != null && _currentImageUrl!.isNotEmpty) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => FullScreenImagePage(
                                imageUrl: _currentImageUrl!,
                              ),
                            ),
                          );
                        }
                      },
                      child: CircleAvatar(
                        radius: 30,
                        backgroundImage: (_currentImageUrl != null && _currentImageUrl!.isNotEmpty)
                            ? NetworkImage(_currentImageUrl!)
                            : null,
                        child: (_currentImageUrl == null || _currentImageUrl!.isEmpty)
                            ? const Icon(Icons.person, size: 30)
                            : null,
                      ),
                    ),
                    title: Text(_currentUsername, style: context.titleLarge),
                    subtitle: Text(_currentAbout, maxLines: 1, overflow: TextOverflow.ellipsis),
                    trailing: IconButton(
                      icon: const Icon(Icons.edit, color: Colors.green),
                      onPressed: () => _showEditProfileBottomSheet(context),
                    ),
                  ),
                  const Divider(),
                  
                  _buildSectionHeader('Account'),
                  _buildListTile(
                    context: context,
                    icon: Icons.block_rounded,
                    title: 'Blocked Users',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const BlockedUsersPage()),
                    ),
                  ),
                  _buildListTile(
                    context: context,
                    icon: Icons.support_agent_rounded,
                    title: 'Support Tickets',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const TicketsPage()),
                    ),
                  ),
                  _buildListTile(
                    context: context,
                    icon: Icons.sync,
                    title: 'Sync Contacts',
                    onTap: () => Navigator.pop(context, 'sync'),
                  ),

                  _buildSectionHeader('App Settings'),
                  _buildListTile(
                    context: context,
                    icon: getIt<ThemeController>().themeMode == ThemeMode.dark ? Icons.light_mode : Icons.dark_mode,
                    title: 'Theme',
                    subtitle: getIt<ThemeController>().themeMode == ThemeMode.dark ? 'Dark Mode' : 'Light Mode',
                    trailing: Switch(
                      value: getIt<ThemeController>().themeMode == ThemeMode.dark,
                      activeColor: context.colors.primary,
                      onChanged: (val) {
                        setState(() {
                          getIt<ThemeController>().toggleTheme();
                        });
                      },
                    ),
                  ),
                  _buildListTile(
                    context: context,
                    icon: Icons.format_size,
                    title: 'Font Size',
                    subtitle: getIt<ThemeController>().fontSizeName,
                    onTap: () => _showFontSizeDialog(context),
                  ),

                  const Divider(),
                  _buildListTile(
                    context: context,
                    icon: Icons.logout,
                    title: 'Logout',
                    iconColor: Colors.red,
                    textColor: Colors.red,
                    onTap: () => _showLogoutDialog(context),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          color: context.colors.primary,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildListTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
    Color? iconColor,
    Color? textColor,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: iconColor ?? context.colors.textPrimary),
      title: Text(
        title,
        style: TextStyle(
          color: textColor ?? context.colors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing: trailing ?? const Icon(Icons.chevron_right, size: 20),
    );
  }

  void _showFontSizeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Font Size'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ['Small', 'Medium', 'Large'].map((size) {
            return RadioListTile<String>(
              title: Text(size),
              value: size,
              groupValue: getIt<ThemeController>().fontSizeName,
              onChanged: (val) {
                if (val != null) {
                  getIt<ThemeController>().setFontSize(val);
                  Navigator.pop(context);
                  setState(() {});
                }
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<ProfileBloc>().add(const LogoutEvent());
            },
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
