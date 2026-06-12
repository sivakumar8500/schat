import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:schat/features/profile_screen/src/presentation/bloc/profile_bloc.dart';
import 'package:schat/features/profile_screen/src/presentation/bloc/profile_event.dart';
import 'package:schat/features/profile_screen/src/presentation/bloc/profile_state.dart';
import 'package:schat/features/subscription_screen/subscription_screen.dart';
import 'package:schat/features/intro_screen/intro_screen.dart';
import 'package:schat/utils/common_colors.dart';
import 'package:schat/utils/common_fontstyles.dart';
import 'package:schat/utils/common_icons.dart';
import 'package:schat/utils/common_spaces.dart';

class ProfilePage extends StatefulWidget {
  final bool isEditing;
  const ProfilePage({super.key, this.isEditing = false});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _aboutController = TextEditingController();
  
  File? _localImageFile;
  String? _remoteImageUrl;
  final ImagePicker _picker = ImagePicker();
  String? _errorText;

  @override
  void dispose() {
    _usernameController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _aboutController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _localImageFile = File(pickedFile.path);
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
          firstName: _firstNameController.text,
          lastName: _lastNameController.text,
          about: _aboutController.text,
          // If we have a local file, we'd normally upload it first and get a URL.
          // For now using the existing URL or local path as mock.
          imagePath: _localImageFile?.path ?? _remoteImageUrl,
        ));
  }

  @override
  Widget build(BuildContext context) {
    final fieldBgColor = Colors.white.withOpacity(0.1);

    return BlocProvider<ProfileBloc>(
      create: (context) => ProfileBloc()..add(const LoadProfileEvent()),
      child: Builder(
        builder: (context) {
          return BlocConsumer<ProfileBloc, ProfileState>(
            listener: (context, state) {
              if (state is ProfileLoaded) {
                setState(() {
                  _usernameController.text = state.username;
                  _firstNameController.text = state.user?.firstName ?? '';
                  _lastNameController.text = state.user?.lastName ?? '';
                  _aboutController.text = state.user?.about ?? '';
                  _remoteImageUrl = state.user?.profilePictureUrl;
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
              } else if (state is ProfileLogoutSuccess) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const IntroPage()),
                  (Route<dynamic> route) => false,
                );
              } else if (state is ProfileFailure) {
                setState(() {
                  _errorText = state.errorMessage;
                });
              }
            },
            builder: (context, state) {
              final isLoading = state is ProfileLoading;

              return Scaffold(
                backgroundColor: context.colors.pureBlack,
                body: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Top illustration area
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.4,
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: Image.asset(
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
                                      context.colors.pureBlack.withOpacity(0),
                                      context.colors.pureBlack,
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Content Area
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (widget.isEditing || Navigator.canPop(context)) ...[
                              InkWell(
                                onTap: () => Navigator.pop(context),
                                borderRadius: BorderRadius.circular(12),
                                child: Padding(
                                  padding: const EdgeInsets.all(4.0),
                                  child: Icon(CommonIcons.arrowBack, color: Colors.white, size: 24),
                                ),
                              ),
                              CommonSpaces.h16,
                            ],

                            Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text("Complete ", style: context.h1.copyWith(fontSize: 36, color: Colors.white)),
                                Text("Profile", style: context.h1Italic.copyWith(fontSize: 34, color: Colors.white)),
                              ],
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
                                        color: fieldBgColor,
                                        shape: BoxShape.circle,
                                        image: _localImageFile != null
                                            ? DecorationImage(image: FileImage(_localImageFile!), fit: BoxFit.cover)
                                            : (_remoteImageUrl != null && _remoteImageUrl!.isNotEmpty
                                                ? DecorationImage(image: NetworkImage(_remoteImageUrl!), fit: BoxFit.cover)
                                                : null),
                                      ),
                                      child: (_localImageFile == null && (_remoteImageUrl == null || _remoteImageUrl!.isEmpty))
                                          ? Icon(CommonIcons.person, size: 64, color: Colors.white.withOpacity(0.2))
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
                                          border: Border.all(color: context.colors.pureBlack, width: 2),
                                        ),
                                        child: Icon(CommonIcons.camera, color: Colors.white, size: 18),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            CommonSpaces.h24,

                            _buildLabel('Username'),
                            CommonSpaces.h8,
                            _buildTextField(_usernameController, 'Enter your username', prefixIcon: CommonIcons.personOutline),
                            CommonSpaces.h16,

                            _buildLabel('First Name'),
                            CommonSpaces.h8,
                            _buildTextField(_firstNameController, 'Enter your first name'),
                            CommonSpaces.h16,

                            _buildLabel('Last Name'),
                            CommonSpaces.h8,
                            _buildTextField(_lastNameController, 'Enter your last name'),
                            CommonSpaces.h16,

                            _buildLabel('About'),
                            CommonSpaces.h8,
                            _buildTextField(_aboutController, 'Hi! how was the day', maxLines: 3),
                            CommonSpaces.h32,

                            if (_errorText != null) ...[
                              Padding(
                                padding: const EdgeInsets.only(bottom: 16.0),
                                child: Text(_errorText!, style: context.bodySmall.copyWith(color: context.colors.error, fontWeight: FontWeight.bold)),
                              ),
                            ],

                            // Save Profile Button
                            SizedBox(
                              width: double.infinity,
                              height: 64,
                              child: ElevatedButton(
                                onPressed: isLoading ? null : () => _saveProfile(context),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: context.colors.primary,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                                  elevation: 0,
                                ),
                                child: isLoading 
                                  ? const CircularProgressIndicator(color: Colors.white)
                                  : Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text('Save Profile', style: context.titleMedium.copyWith(color: Colors.white, fontWeight: FontWeight.w600)),
                                        CommonSpaces.w8,
                                        Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                                          child: Icon(CommonIcons.arrowForward, color: context.colors.primary, size: 16),
                                        ),
                                      ],
                                    ),
                              ),
                            ),
                            CommonSpaces.h24,

                            if (widget.isEditing)
                              Center(
                                child: TextButton.icon(
                                  onPressed: () => _showLogoutDialog(context),
                                  icon: Icon(CommonIcons.logout, color: context.colors.error, size: 20),
                                  label: Text('Logout from account', style: context.bodyMedium.copyWith(color: context.colors.error, fontWeight: FontWeight.bold)),
                                ),
                              ),
                            CommonSpaces.h40,
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(text, style: context.titleSmall.copyWith(color: Colors.white));
  }

  Widget _buildTextField(TextEditingController controller, String hint, {IconData? prefixIcon, int maxLines = 1}) {
    return Container(
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        style: context.titleSmall.copyWith(color: Colors.white),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: context.bodyMedium.copyWith(color: Colors.white.withOpacity(0.4)),
          prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: Colors.white.withOpacity(0.5)) : null,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: context.colors.pureBlack,
        title: Text('Logout', style: context.titleMedium.copyWith(color: Colors.white)),
        content: Text('Are you sure you want to logout?', style: context.bodyMedium.copyWith(color: Colors.white.withOpacity(0.7))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text('Cancel', style: context.bodyMedium.copyWith(color: Colors.white))),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<ProfileBloc>().add(const LogoutEvent());
            },
            child: Text('Logout', style: context.bodyMedium.copyWith(color: context.colors.error, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
