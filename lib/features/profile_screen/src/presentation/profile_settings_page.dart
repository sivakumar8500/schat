import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:schat/features/dashboard_screen/src/presentation/bloc/contacts_bloc.dart';
import 'package:schat/features/dashboard_screen/src/presentation/bloc/contacts_state.dart';
import 'package:schat/features/intro_screen/intro_screen.dart';
import 'package:schat/features/profile_screen/src/presentation/bloc/profile_bloc.dart';
import 'package:schat/features/profile_screen/src/presentation/bloc/profile_event.dart';
import 'package:schat/features/profile_screen/src/presentation/bloc/profile_state.dart';
import 'package:schat/features/profile_screen/src/presentation/profile_page.dart';
import 'package:schat/features/chat_screen/src/presentation/full_screen_image_page.dart';
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

  @override
  void initState() {
    super.initState();
    _currentUsername = widget.username;
    _currentImageUrl = widget.profilePicUrl;
  }

  void _showUpdateAboutBottomSheet(BuildContext context) {
    final controller = TextEditingController(text: _currentAbout);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: context.colors.scaffoldBackground,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Update About', style: context.titleLarge),
              CommonSpaces.h16,
              TextField(
                controller: controller,
                autofocus: true,
                maxLength: 100,
                decoration: InputDecoration(
                  hintText: 'About',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              CommonSpaces.h16,
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    final newAbout = controller.text.trim();
                    if (newAbout.isNotEmpty) {
                      context.read<ProfileBloc>().add(UpdateAboutEvent(about: newAbout));
                      Navigator.pop(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.colors.primary,
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
        BlocProvider<ContactsBloc>(
          create: (context) => ContactsBloc(),
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
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ProfilePage(isEditing: true),
                          ),
                        );
                        if (context.mounted) {
                          context.read<ProfileBloc>().add(const LoadProfileEvent());
                        }
                      },
                    ),
                  ),
                  const Divider(),
                  
                  _buildSectionHeader('Account'),
                  _buildListTile(
                    context: context,
                    icon: Icons.info_outline,
                    title: 'About',
                    subtitle: _currentAbout,
                    onTap: () => _showUpdateAboutBottomSheet(context),
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
