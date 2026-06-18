import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:schat/features/profile_screen/src/presentation/bloc/profile_bloc.dart';
import 'package:schat/features/profile_screen/src/presentation/bloc/profile_event.dart';
import 'package:schat/features/profile_screen/src/presentation/bloc/profile_state.dart';
import 'package:schat/features/subscription_screen/subscription_screen.dart';
import 'package:schat/features/intro_screen/intro_screen.dart';
import 'package:schat/features/dashboard_screen/dashboard_screen.dart';
import 'package:schat/utils/common_colors.dart';
import 'package:schat/utils/common_fontstyles.dart';
import 'package:schat/utils/common_icons.dart';
import 'package:schat/utils/common_sizes.dart';
import 'package:schat/utils/common_spaces.dart';

class ProfilePage extends StatefulWidget {
  final bool isEditing;
  const ProfilePage({super.key, this.isEditing = false});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final TextEditingController _usernameController = TextEditingController();
  
  File? _localImageFile;
  String? _remoteImageUrl;
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
          // If we have a local file, we'd normally upload it first and get a URL.
          // For now using the existing URL or local path as mock.
          imagePath: _localImageFile?.path ?? _remoteImageUrl,
        ));
  }

  @override
  Widget build(BuildContext context) {
    final fieldBgColor = Colors.white.withValues(alpha: 0.1);

    return BlocProvider<ProfileBloc>(
      create: (context) => ProfileBloc()..add(const LoadProfileEvent()),
      child: Builder(
        builder: (context) {
          return BlocConsumer<ProfileBloc, ProfileState>(
            listener: (context, state) {
              if (state is ProfileLoaded) {
                setState(() {
                  _usernameController.text = state.username;
                  _remoteImageUrl = state.user?.profilePictureUrl;
                });

                if (!widget.isEditing && state.user != null) {
                  final user = state.user!;
                  if (user.username != null && user.username!.isNotEmpty) {
                    if (user.isSubscribed) {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (context) => const DashboardPage()),
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
                }
              } else if (state is ProfileSuccess) {
                _errorText = null;
                if (widget.isEditing) {
                  Navigator.pop(context);
                } else {
                  if (state.user.isSubscribed) {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => const DashboardPage()),
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
                setState(() {
                  _errorText = state.errorMessage;
                });
              }
            },
            builder: (context, state) {
              final isLoading = state is ProfileLoading;

              return Scaffold(
                backgroundColor: context.colors.pureBlack,
                body: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(minHeight: constraints.maxHeight),
                        child: IntrinsicHeight(
                          child: Column(
                            children: [
                              const Spacer(),
                              // Top illustration area
                              SizedBox(
                                height: MediaQuery.of(context).size.height * 0.35,
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
                                              context.colors.pureBlack.withValues(alpha: 0),
                                              context.colors.pureBlack,
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              CommonSpaces.h20,
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.center,
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
                                          CommonSpaces.w12,
                                        ],
                                        Expanded(
                                          child: Text.rich(
                                            TextSpan(
                                              children: [
                                                TextSpan(
                                                  text: "Complete ",
                                                  style: context.h1.copyWith(fontSize: 32, color: Colors.white),
                                                ),
                                                TextSpan(
                                                  text: "Profile",
                                                  style: context.h1Italic.copyWith(fontSize: 30, color: Colors.white),
                                                ),
                                              ],
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                    CommonSpaces.h24,
                                    Center(
                                      child: GestureDetector(
                                        onTap: _pickImage,
                                        child: Stack(
                                          children: [
                                            Container(
                                              width: CommonSizes.p100,
                                              height: CommonSizes.p100,
                                              decoration: BoxDecoration(
                                                color: fieldBgColor,
                                                shape: BoxShape.circle,
                                              ),
                                              child: ClipOval(
                                                child: _localImageFile != null
                                                    ? Image.file(_localImageFile!, fit: BoxFit.cover)
                                                    : (_remoteImageUrl != null && _remoteImageUrl!.isNotEmpty
                                                        ? Image.network(
                                                            _remoteImageUrl!,
                                                            fit: BoxFit.cover,
                                                            errorBuilder: (context, error, stackTrace) {
                                                              return Icon(CommonIcons.person, size: 64, color: Colors.white.withValues(alpha: 0.2));
                                                            },
                                                            loadingBuilder: (context, child, loadingProgress) {
                                                              if (loadingProgress == null) return child;
                                                              return Center(
                                                                child: CircularProgressIndicator(
                                                                  value: loadingProgress.expectedTotalBytes != null
                                                                      ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                                                      : null,
                                                                  strokeWidth: 2,
                                                                ),
                                                              );
                                                            },
                                                          )
                                                        : Icon(CommonIcons.person, size: 64, color: Colors.white.withValues(alpha: 0.2))),
                                              ),
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
                                    CommonSpaces.h12,
                                    _buildTextField(_usernameController, 'Enter your username', prefixIcon: CommonIcons.personOutline),
                                    if (_errorText != null) ...[
                                      CommonSpaces.h16,
                                      Text(_errorText!, style: context.bodySmall.copyWith(color: context.colors.error, fontWeight: FontWeight.bold)),
                                    ],
                                  ],
                                ),
                              ),
                              CommonSpaces.h20,
                            ],
                          ),
                        ),
                      ),
                    );

                  }
                ),
                bottomNavigationBar: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: SafeArea(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: double.infinity,
                          height: 46,
                          child: ElevatedButton(
                            onPressed: isLoading ? null : () => _saveProfile(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: context.colors.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                              elevation: 0,
                            ),
                            child: isLoading 
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
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
                        CommonSpaces.h14,
                      ],
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

  Widget _buildLabel(String text) {
    return Text(text, style: context.titleSmall.copyWith(color: Colors.white));
  }

  Widget _buildTextField(TextEditingController controller, String hint, {IconData? prefixIcon, int maxLines = 1}) {
    return Container(
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        style: context.titleSmall.copyWith(color: Colors.white),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: context.bodyMedium.copyWith(color: Colors.white.withValues(alpha: 0.4)),
          prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: Colors.white.withValues(alpha: 0.5)) : null,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        ),
      ),
    );
  }
}
