import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:schat/common/widgets/auth_hero_header.dart';
import 'package:schat/common/widgets/mesh_background.dart';
import 'package:schat/common/widgets/primary_action_button.dart';
import 'package:schat/features/profile_screen/src/presentation/bloc/profile_bloc.dart';
import 'package:schat/features/profile_screen/src/presentation/bloc/profile_event.dart';
import 'package:schat/features/profile_screen/src/presentation/bloc/profile_state.dart';
import 'package:schat/features/subscription_screen/subscription_screen.dart';
import 'package:schat/features/intro_screen/intro_screen.dart';
import 'package:schat/features/dashboard_screen/dashboard_screen.dart';
import 'package:schat/features/permissions_screen/permissions_screen.dart';
import 'package:schat/utils/permission_helper.dart';
import 'package:schat/utils/common_colors.dart';
import 'package:schat/utils/common_fontstyles.dart';
import 'package:schat/utils/common_icons.dart';
import 'package:schat/utils/common_spaces.dart';
import 'package:schat/utils/common_notifications.dart';

class ProfilePage extends StatefulWidget {
  final bool isEditing;
  const ProfilePage({super.key, this.isEditing = false});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final TextEditingController _usernameController = TextEditingController();
  final FocusNode _usernameFocusNode = FocusNode();
  
  String? _selectedCategory;
  final List<String> _categories = [
    'Student',
    'Employee',
    'General public',
    'Celebrity',
  ];

  File? _localImageFile;
  Uint8List? _webImageBytes;
  String? _remoteImageUrl;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _usernameFocusNode.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _usernameFocusNode.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _webImageBytes = bytes;
          _localImageFile = kIsWeb ? null : File(pickedFile.path);
        });
      }
    } catch (e) {
      if (mounted) {
        context.showErrorNotification('Failed to pick image');
      }
    }
  }

  void _saveProfile(BuildContext context) {
    final username = _usernameController.text.trim();
    
    if (username.isEmpty) {
      context.showErrorNotification('Please enter your username.');
      return;
    }

    if (username.length < 3) {
      context.showErrorNotification('Username must be at least 3 characters long.');
      return;
    }

    if (username.length > 60) {
      context.showErrorNotification('Username cannot exceed 60 characters.');
      return;
    }

    if (!RegExp(r'^[a-zA-Z]').hasMatch(username)) {
      context.showErrorNotification('Username must start with an alphabetical letter.');
      return;
    }

    if (_selectedCategory == null || _selectedCategory!.isEmpty) {
      context.showErrorNotification('Please select your role / category.');
      return;
    }

    context.read<ProfileBloc>().add(UpdateProfileEvent(
          username: username,
          about: _selectedCategory,
          category: _selectedCategory,
          imagePath: _localImageFile?.path ?? _remoteImageUrl,
          fileBytes: _webImageBytes,
        ));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.colors.isDark;
    final inputBgColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : const Color(0xFFF3F4F6);

    return BlocProvider<ProfileBloc>(
      create: (context) => ProfileBloc()..add(const LoadProfileEvent()),
      child: Builder(
        builder: (context) {
          return BlocConsumer<ProfileBloc, ProfileState>(
            listener: (context, state) async {
              if (state is ProfileLoaded) {
                setState(() {
                  _usernameController.text = state.username;
                  _remoteImageUrl = state.user?.profilePictureUrl;
                  if (state.user?.about != null && _categories.contains(state.user!.about)) {
                    _selectedCategory = state.user!.about;
                  }
                });

                if (!widget.isEditing && state.user != null) {
                  final user = state.user!;
                  if (user.username != null && user.username!.isNotEmpty) {
                    if (user.isSubscribed) {
                      final showPermissions = await PermissionHelper.shouldShowPermissionsScreen();
                      if (!context.mounted) return;
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (context) => showPermissions ? const PermissionsPage() : const DashboardPage(),
                        ),
                        (Route<dynamic> route) => false,
                      );
                    } else {
                      if (!context.mounted) return;
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (context) => const SubscriptionPage()),
                        (Route<dynamic> route) => false,
                      );
                    }
                  }
                }
              } else if (state is ProfileSuccess) {
                if (widget.isEditing) {
                  Navigator.pop(context);
                } else {
                  if (state.user.isSubscribed) {
                    final showPermissions = await PermissionHelper.shouldShowPermissionsScreen();
                    if (!context.mounted) return;
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (context) => showPermissions ? const PermissionsPage() : const DashboardPage(),
                      ),
                      (Route<dynamic> route) => false,
                    );
                  } else {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => const SubscriptionPage()),
                      (Route<dynamic> route) => false,
                    );
                  }
                }
              } else if (state is ProfileLogoutSuccess) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const IntroPage()),
                  (Route<dynamic> route) => false,
                );
              } else if (state is ProfileFailure) {
                context.showErrorNotification(state.errorMessage);
              }
            },
            builder: (context, state) {
              final isLoading = state is ProfileLoading;

              return Scaffold(
                backgroundColor: context.colors.scaffoldBackground,
                body: MeshBackground(
                  child: SafeArea(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 26.0),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minHeight: constraints.maxHeight,
                            ),
                            child: IntrinsicHeight(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Back navigation row if editing or can pop
                                  if (widget.isEditing || Navigator.canPop(context)) ...[
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8.0),
                                      child: InkWell(
                                        onTap: () => Navigator.pop(context),
                                        borderRadius: BorderRadius.circular(12),
                                        child: Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: inputBgColor,
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(
                                              color: isDark
                                                  ? Colors.white.withValues(alpha: 0.1)
                                                  : Colors.black.withValues(alpha: 0.05),
                                            ),
                                          ),
                                          child: Icon(
                                            CommonIcons.arrowBack,
                                            color: context.colors.textPrimary,
                                            size: 20,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],

                                  const Spacer(flex: 1),

                                  // Brand Hero with embedded Avatar Picker
                                  AuthHeroHeader(
                                    centerWidget: GestureDetector(
                                      onTap: _pickImage,
                                      child: Stack(
                                        children: [
                                          Container(
                                            width: 90,
                                            height: 90,
                                            decoration: BoxDecoration(
                                              color: inputBgColor,
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: context.colors.primary,
                                                width: 2.5,
                                              ),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: context.colors.primary.withValues(alpha: 0.28),
                                                  blurRadius: 18,
                                                  spreadRadius: 2,
                                                ),
                                              ],
                                            ),
                                            child: ClipOval(
                                              child: _webImageBytes != null
                                                  ? Image.memory(_webImageBytes!, fit: BoxFit.cover)
                                                  : (_localImageFile != null
                                                      ? Image.file(_localImageFile!, fit: BoxFit.cover)
                                                      : (_remoteImageUrl != null && _remoteImageUrl!.isNotEmpty
                                                          ? Image.network(
                                                              _remoteImageUrl!,
                                                              fit: BoxFit.cover,
                                                              errorBuilder: (context, error, stackTrace) =>
                                                                  Icon(CommonIcons.person, size: 48, color: isDark ? Colors.white24 : Colors.black26),
                                                            )
                                                          : Icon(CommonIcons.person, size: 48, color: isDark ? Colors.white30 : Colors.black26))),
                                            ),
                                          ),
                                          Positioned(
                                            bottom: 0,
                                            right: 0,
                                            child: Container(
                                              padding: const EdgeInsets.all(6),
                                              decoration: BoxDecoration(
                                                color: context.colors.primary,
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                  color: isDark ? Colors.black : Colors.white,
                                                  width: 2,
                                                ),
                                              ),
                                              child: const Icon(
                                                Icons.camera_alt_rounded,
                                                color: Colors.white,
                                                size: 14,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    title: null,
                                    showTagline: true,
                                  ),

                                  const Spacer(flex: 2),

                                  // Headline
                                  Text.rich(
                                    TextSpan(
                                      children: [
                                        TextSpan(
                                          text: "Complete ",
                                          style: context.h1.copyWith(
                                            fontSize: 34,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: -0.5,
                                            color: context.colors.textPrimary,
                                          ),
                                        ),
                                        TextSpan(
                                          text: "your ",
                                          style: context.h1Italic.copyWith(
                                            fontSize: 34,
                                            fontWeight: FontWeight.w900,
                                            fontStyle: FontStyle.italic,
                                            color: context.colors.primary,
                                          ),
                                        ),
                                        TextSpan(
                                          text: "profile.",
                                          style: context.h1.copyWith(
                                            fontSize: 34,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: -0.5,
                                            color: context.colors.textPrimary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  CommonSpaces.h6,
                                  Text(
                                    'Set up your username and choose your role to start messaging.',
                                    style: context.bodyMedium.copyWith(
                                      color: context.colors.textSecondary,
                                      fontSize: 14,
                                      height: 1.35,
                                    ),
                                  ),
                                  CommonSpaces.h20,

                                  // Username Label
                                  Text(
                                    'Username',
                                    style: context.titleSmall.copyWith(
                                      color: context.colors.textSecondary,
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                  CommonSpaces.h8,

                                  // Username Field
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    height: 56,
                                    decoration: BoxDecoration(
                                      color: inputBgColor,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: _usernameFocusNode.hasFocus
                                            ? context.colors.primary
                                            : (isDark
                                                ? Colors.white.withValues(alpha: 0.12)
                                                : const Color(0xFFE5E7EB)),
                                        width: _usernameFocusNode.hasFocus ? 1.8 : 1.0,
                                      ),
                                      boxShadow: _usernameFocusNode.hasFocus
                                          ? [
                                              BoxShadow(
                                                color: context.colors.primary
                                                    .withValues(alpha: 0.22),
                                                blurRadius: 10,
                                                offset: const Offset(0, 2),
                                              ),
                                            ]
                                          : [
                                              BoxShadow(
                                                color: Colors.black.withValues(
                                                    alpha: isDark ? 0.2 : 0.03),
                                                blurRadius: 8,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                    ),
                                    child: Row(
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 14,
                                          ),
                                          child: Icon(
                                            CommonIcons.personOutline,
                                            color: _usernameFocusNode.hasFocus
                                                ? context.colors.primary
                                                : context.colors.textSecondary
                                                    .withValues(alpha: 0.7),
                                            size: 22,
                                          ),
                                        ),
                                        Container(
                                          height: 26,
                                          width: 1,
                                          color: isDark
                                              ? Colors.white
                                                  .withValues(alpha: 0.15)
                                              : const Color(0xFFD1D5DB),
                                        ),
                                        CommonSpaces.w8,
                                        Expanded(
                                          child: TextField(
                                            controller: _usernameController,
                                            focusNode: _usernameFocusNode,
                                            maxLength: 60,
                                            style: context.titleMedium.copyWith(
                                              color: context.colors.textPrimary,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 16,
                                            ),
                                            decoration: InputDecoration(
                                              hintText: 'Enter your username',
                                              counterText: '',
                                              hintStyle: context.bodyMedium.copyWith(
                                                color: context.colors.textSecondary
                                                    .withValues(alpha: 0.45),
                                                fontSize: 15.5,
                                              ),
                                              border: InputBorder.none,
                                              contentPadding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 14,
                                              ),
                                            ),
                                            onChanged: (_) => setState(() {}),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  CommonSpaces.h16,

                                  // Role / Category Dropdown Label (Mandatory)
                                  Row(
                                    children: [
                                      Text(
                                        'Role / Category',
                                        style: context.titleSmall.copyWith(
                                          color: context.colors.textSecondary,
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: 0.3,
                                        ),
                                      ),
                                      Text(
                                        ' *',
                                        style: TextStyle(
                                          color: context.colors.error,
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  CommonSpaces.h8,

                                  // Role / Category Dropdown Container
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    height: 56,
                                    decoration: BoxDecoration(
                                      color: inputBgColor,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: _selectedCategory != null
                                            ? context.colors.primary.withValues(alpha: 0.7)
                                            : (isDark
                                                ? Colors.white.withValues(alpha: 0.12)
                                                : const Color(0xFFE5E7EB)),
                                        width: 1.0,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(
                                              alpha: isDark ? 0.2 : 0.03),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    padding: const EdgeInsets.symmetric(horizontal: 14),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.badge_outlined,
                                          color: _selectedCategory != null
                                              ? context.colors.primary
                                              : context.colors.textSecondary
                                                  .withValues(alpha: 0.7),
                                          size: 22,
                                        ),
                                        CommonSpaces.w12,
                                        Container(
                                          height: 26,
                                          width: 1,
                                          color: isDark
                                              ? Colors.white
                                                  .withValues(alpha: 0.15)
                                              : const Color(0xFFD1D5DB),
                                        ),
                                        CommonSpaces.w12,
                                        Expanded(
                                          child: DropdownButtonHideUnderline(
                                            child: DropdownButton<String>(
                                              value: _selectedCategory,
                                              isExpanded: true,
                                              hint: Text(
                                                'Select role / category',
                                                style: context.bodyMedium.copyWith(
                                                  color: context.colors.textSecondary
                                                      .withValues(alpha: 0.45),
                                                  fontSize: 15.5,
                                                ),
                                              ),
                                              dropdownColor: isDark
                                                  ? const Color(0xFF1E232A)
                                                  : Colors.white,
                                              borderRadius: BorderRadius.circular(16),
                                              icon: Icon(
                                                Icons.keyboard_arrow_down_rounded,
                                                color: context.colors.textSecondary,
                                                size: 24,
                                              ),
                                              items: _categories.map((String category) {
                                                return DropdownMenuItem<String>(
                                                  value: category,
                                                  child: Text(
                                                    category,
                                                    style: context.titleMedium.copyWith(
                                                      color: context.colors.textPrimary,
                                                      fontWeight: FontWeight.w600,
                                                      fontSize: 15.5,
                                                    ),
                                                  ),
                                                );
                                              }).toList(),
                                              onChanged: (String? newValue) {
                                                setState(() {
                                                  _selectedCategory = newValue;
                                                });
                                              },
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  CommonSpaces.h24,

                                  // Continue Button
                                  PrimaryActionButton(
                                    title: 'Continue',
                                    isLoading: isLoading,
                                    onPressed: isLoading ? null : () => _saveProfile(context),
                                  ),

                                  CommonSpaces.h24,
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
