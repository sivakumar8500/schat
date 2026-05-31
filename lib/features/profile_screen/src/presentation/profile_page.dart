import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:schat/features/profile_screen/src/presentation/bloc/profile_bloc.dart';
import 'package:schat/features/profile_screen/src/presentation/bloc/profile_event.dart';
import 'package:schat/features/profile_screen/src/presentation/bloc/profile_state.dart';
import 'package:schat/features/subscription_screen/subscription_screen.dart';
import 'package:schat/injection.dart';
import 'package:schat/utils/common_colors.dart';
import 'package:schat/utils/common_fontstyles.dart';
import 'package:schat/utils/common_icons.dart';
import 'package:schat/utils/common_spaces.dart';
import 'package:schat/utils/theme_controller.dart';

class ProfilePage extends StatefulWidget {
  final bool isEditing;
  const ProfilePage({super.key, this.isEditing = false});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final TextEditingController _usernameController = TextEditingController();
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();
  String? _errorText;

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to pick image')),
        );
      }
    }
  }

  void _saveProfile(BuildContext context) {
    context.read<ProfileBloc>().add(UpdateProfileEvent(
          username: _usernameController.text,
          imagePath: _imageFile?.path,
        ));
  }

  @override
  Widget build(BuildContext context) {
    final cardBgColor = context.colors.cardBackground;
    final fieldBgColor = context.colors.isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white;

    return BlocProvider<ProfileBloc>(
      create: (context) {
        final bloc = ProfileBloc();
        if (widget.isEditing) {
          bloc.add(const LoadProfileEvent());
        }
        return bloc;
      },
      child: Builder(
        builder: (context) {
          return BlocConsumer<ProfileBloc, ProfileState>(
            listener: (context, state) {
              if (state is ProfileLoaded) {
                setState(() {
                  _usernameController.text = state.username;
                  if (state.imagePath != null) {
                    _imageFile = File(state.imagePath!);
                  }
                });
              } else if (state is ProfileSuccess) {
                _errorText = null;
                if (widget.isEditing) {
                  Navigator.pop(context);
                } else {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const SubscriptionPage()),
                    (Route<dynamic> route) => false,
                  );
                }
              } else if (state is ProfileFailure) {
                setState(() {
                  _errorText = state.errorMessage;
                });
              }
            },
            builder: (context, state) {
              final isLoading = state is ProfileLoading;

              return Scaffold(
                backgroundColor: context.colors.scaffoldBackground,
                body: Column(
                  children: [
                    // Top illustration area
                    Expanded(
                      flex: 5,
                      child: Container(
                        color: context.colors.scaffoldBackground,
                        child: SafeArea(
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Image.asset(
                                'assets/images/secure_chats.png',
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Bottom card area
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: cardBgColor,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(40),
                        ),
                      ),
                      child: SafeArea(
                        top: false,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 30.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Back button (if isEditing or pop exists)
                              if (widget.isEditing || Navigator.canPop(context)) ...[
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: InkWell(
                                    onTap: () => Navigator.pop(context),
                                    borderRadius: BorderRadius.circular(12),
                                    child: Padding(
                                      padding: const EdgeInsets.all(4.0),
                                      child: Icon(
                                        CommonIcons.arrowBack,
                                        color: context.colors.textPrimary,
                                        size: 24,
                                      ),
                                    ),
                                  ),
                                ),
                                CommonSpaces.h16,
                              ],

                              // Header title
                              Text.rich(
                                TextSpan(
                                  text: "Complete ",
                                  children: [
                                    TextSpan(
                                      text: "Profile",
                                      style: context.h1Italic.copyWith(fontSize: 34),
                                    ),
                                  ],
                                ),
                                style: context.h1.copyWith(fontSize: 36),
                              ),
                              CommonSpaces.h24,

                              // Profile Image Selector
                              Center(
                                child: GestureDetector(
                                  onTap: _pickImage,
                                  child: Stack(
                                    children: [
                                      Container(
                                        width: 110,
                                        height: 110,
                                        decoration: BoxDecoration(
                                          color: context.colors.scaffoldBackground,
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: context.colors.textPrimary.withValues(alpha: 0.1),
                                              blurRadius: 15,
                                              offset: const Offset(0, 5),
                                            ),
                                          ],
                                          image: _imageFile != null
                                              ? DecorationImage(
                                                  image: FileImage(_imageFile!),
                                                  fit: BoxFit.cover,
                                                )
                                              : null,
                                        ),
                                        child: _imageFile == null
                                            ? Icon(CommonIcons.person, size: 64, color: context.colors.textPrimary.withValues(alpha: 0.2))
                                            : null,
                                      ),
                                      Positioned(
                                        bottom: 0,
                                        right: 0,
                                        child: Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: context.colors.primary,
                                            shape: BoxShape.circle,
                                            border: Border.all(color: cardBgColor, width: 2),
                                          ),
                                          child: Icon(CommonIcons.camera, color: context.colors.textLight, size: 18),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              CommonSpaces.h24,

                              // Username Label
                              Text(
                                'Username',
                                style: context.titleSmall,
                              ),
                              CommonSpaces.h12,

                              // Input Field (Username)
                              Container(
                                decoration: BoxDecoration(
                                  color: fieldBgColor,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: TextField(
                                  controller: _usernameController,
                                  onChanged: (value) {
                                    if (_errorText != null) {
                                      setState(() {
                                        _errorText = null;
                                      });
                                    }
                                  },
                                  style: context.titleSmall,
                                  decoration: InputDecoration(
                                    hintText: 'Enter your username',
                                    hintStyle: context.bodyMedium.copyWith(
                                      color: context.colors.textHint.withValues(alpha: 0.6),
                                    ),
                                    prefixIcon: Icon(CommonIcons.personOutline, color: context.colors.textSecondary),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide.none,
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                                  ),
                                ),
                              ),
                              if (_errorText != null) ...[
                                CommonSpaces.h8,
                                Padding(
                                  padding: const EdgeInsets.only(left: 4.0),
                                  child: Text(
                                    _errorText!,
                                    style: context.bodySmall.copyWith(
                                      color: context.colors.error,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                              CommonSpaces.h32,

                              // Save Profile Button
                              SizedBox(
                                width: double.infinity,
                                height: 56,
                                child: ElevatedButton(
                                  onPressed: isLoading ? null : () => _saveProfile(context),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: context.colors.primary,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(28),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'Save Profile',
                                        style: context.titleMedium.copyWith(color: Colors.white),
                                      ),
                                      CommonSpaces.w8,
                                      Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: const BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          CommonIcons.arrowForward,
                                          color: context.colors.primary,
                                          size: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              CommonSpaces.h16,

                              // Theme Mode Switcher
                              Center(
                                child: TextButton.icon(
                                  onPressed: () {
                                    getIt<ThemeController>().toggleTheme();
                                  },
                                  icon: Icon(
                                    getIt<ThemeController>().themeMode == ThemeMode.dark ? CommonIcons.lightMode : CommonIcons.darkMode,
                                    color: context.colors.textSecondary,
                                    size: 20,
                                  ),
                                  label: Text(
                                    getIt<ThemeController>().themeMode == ThemeMode.dark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
                                    style: context.bodyMedium.copyWith(
                                      color: context.colors.textSecondary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
