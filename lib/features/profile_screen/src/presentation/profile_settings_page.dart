import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:schat/features/intro_screen/intro_screen.dart';
import 'package:schat/features/profile_screen/src/presentation/bloc/profile_bloc.dart';
import 'package:schat/features/profile_screen/src/presentation/bloc/profile_event.dart';
import 'package:schat/features/profile_screen/src/presentation/bloc/profile_state.dart';
import 'package:schat/features/profile_screen/src/presentation/profile_page.dart';
import 'package:schat/injection.dart';
import 'package:schat/utils/common_colors.dart';
import 'package:schat/utils/common_fontstyles.dart';
import 'package:schat/utils/common_icons.dart';
import 'package:schat/utils/common_spaces.dart';
import 'package:schat/utils/theme_controller.dart';

class ProfileSettingsPage extends StatefulWidget {
  final String username;

  const ProfileSettingsPage({super.key, required this.username});

  @override
  State<ProfileSettingsPage> createState() => _ProfileSettingsPageState();
}

class _ProfileSettingsPageState extends State<ProfileSettingsPage> {
  @override
  Widget build(BuildContext context) {
    return BlocProvider<ProfileBloc>(
      create: (context) => ProfileBloc()..add(const LoadProfileEvent()),
      child: BlocConsumer<ProfileBloc, ProfileState>(
        listener: (context, state) {
          if (state is ProfileLogoutSuccess) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const IntroPage()),
              (Route<dynamic> route) => false,
            );
          }
        },
        builder: (context, state) {
          String? imageUrl;
          String currentUsername = widget.username;

          if (state is ProfileLoaded) {
            imageUrl = state.imagePath;
            currentUsername = state.username;
          }

          return SafeArea(
            child: Scaffold(
              backgroundColor: context.colors.scaffoldBackground,
              body: Stack(
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.50,
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: (imageUrl != null && imageUrl.isNotEmpty)
                              ? Image.network(
                                  imageUrl,
                                  fit: BoxFit.fill,
                                  errorBuilder:
                                      (context, error, stackTrace) =>
                                          Image.asset(
                                            'assets/main_bg_img.png',
                                            fit: BoxFit.cover,
                                          ),
                                )
                              : Image.asset(
                                  'assets/main_bg_img.png',
                                  fit: BoxFit.cover,
                                ),
                        ),
                        Positioned(
                          bottom: -1,
                          left: 0,
                          right: 0,
                          height: 150,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  context.colors.scaffoldBackground.withValues(alpha: 0),
                                  context.colors.scaffoldBackground,
                                ],
                              ),
                            ),
                          ),
                        ),
                        // Back button and Title
                        Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          child: SafeArea(
                            bottom: false,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16.0,
                                vertical: 8.0,
                              ),
                              child: Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      CommonIcons.arrowBack,
                                      color: Colors.white,
                                    ),
                                    onPressed: () => Navigator.pop(context),
                                  ),
                                  const Expanded(
                                    child: Center(
                                      child: Text(
                                        'Profile Settings',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.edit,
                                      color: Colors.white,
                                    ),
                                    onPressed: () async {
                                      await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const ProfilePage(isEditing: true),
                                        ),
                                      );
                                      if (mounted) {
                                        context.read<ProfileBloc>().add(
                                          const LoadProfileEvent(),
                                        );
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding:  EdgeInsets.only(left: 32.0,right: 32,top: MediaQuery.of(context).size.height * 0.45,),
                      child: SizedBox(
                        height: MediaQuery.of(context).size.height * 0.5,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              currentUsername,
                              style: context.h2,
                            ),
                            CommonSpaces.h40,
                            _buildSettingsTile(
                              context: context,
                              icon:
                                  getIt<ThemeController>().themeMode ==
                                      ThemeMode.dark
                                  ? Icons.light_mode
                                  : Icons.dark_mode,
                              title:
                                  getIt<ThemeController>().themeMode ==
                                      ThemeMode.dark
                                  ? 'Light Mode'
                                  : 'Dark Mode',
                              trailing: Switch(
                                value:
                                    getIt<ThemeController>().themeMode ==
                                    ThemeMode.dark,
                                activeThumbColor: context.colors.primary,
                                onChanged: (val) {
                                  setState(() {
                                    getIt<ThemeController>().toggleTheme();
                                  });
                                },
                              ),
                            ),
                            CommonSpaces.h12,
                            _buildSettingsTile(
                              context: context,
                              icon: Icons.format_size_rounded,
                              title: 'Font Size',
                              trailing: DropdownButton<String>(
                                value: getIt<ThemeController>().fontSizeName,
                                dropdownColor: context.colors.lightBackground,
                                style: TextStyle(
                                  color: context.colors.textPrimary,
                                  fontWeight: FontWeight.bold,
                                ),
                                underline: const SizedBox(),
                                items: const [
                                  DropdownMenuItem(
                                    value: 'Small',
                                    child: Text('Small'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'Medium',
                                    child: Text('Medium'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'Large',
                                    child: Text('Large'),
                                  ),
                                ],
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() {
                                      getIt<ThemeController>().setFontSize(val);
                                    });
                                  }
                                },
                              ),
                            ),
                            CommonSpaces.h12,
                            const _LogoutButton(),
                            CommonSpaces.h20,
                          ],
                        ),
                      ),
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

  Widget _buildSettingsTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required Widget trailing,
  }) {
    return Material(
      color: context.colors.textPrimary.withValues(alpha:0.05),
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        leading: Icon(icon, color: context.colors.textPrimary),
        title: Text(
          title,
          style: TextStyle(
            color: context.colors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        trailing: trailing,
      ),
    );
  }
}

class _LogoutButton extends StatelessWidget {
  const _LogoutButton();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.colors.error.withValues(alpha:0.1),
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        onTap: () {
          showDialog(
            context: context,
            builder: (dialogContext) => AlertDialog(
              backgroundColor: context.colors.scaffoldBackground,
              title: Text(
                'Logout',
                style: context.titleMedium,
              ),
              content: Text(
                'Are you sure you want to logout?',
                style: context.bodyMedium,
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text(
                    'Cancel',
                    style: context.bodyMedium,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                    context.read<ProfileBloc>().add(const LogoutEvent());
                  },
                  child: Text(
                    'Logout',
                    style: context.bodyMedium.copyWith(
                      color: context.colors.error,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
        leading: Icon(CommonIcons.logout, color: context.colors.error),
        title: Text(
          'Logout from account',
          style: TextStyle(
            color: context.colors.error,
            fontWeight: FontWeight.bold,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios_rounded,
          color: context.colors.error,
          size: 16,
        ),
      ),
    );
  }
}



