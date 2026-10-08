import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:schat/common/widgets/auth_hero_header.dart';
import 'package:schat/common/widgets/primary_action_button.dart';
import 'package:schat/core/storage/storage_service.dart';
import 'package:schat/features/dashboard_screen/src/presentation/dashboard_page.dart';
import 'package:schat/injection.dart';
import 'package:schat/utils/common_colors.dart';
import 'package:schat/utils/common_fontstyles.dart';
import 'package:schat/utils/common_spaces.dart';
import 'package:schat/utils/permission_helper.dart';

class PermissionsPage extends StatefulWidget {
  const PermissionsPage({super.key});

  @override
  State<PermissionsPage> createState() => _PermissionsPageState();
}

class _PermissionsPageState extends State<PermissionsPage> with WidgetsBindingObserver {
  bool _notificationGranted = false;
  bool _contactsGranted = false;
  bool _cameraGranted = false;
  bool _microphoneGranted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkStatuses();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkStatuses();
    }
  }

  Future<void> _checkStatuses() async {
    bool notification = false;
    bool contacts = false;
    bool camera = false;
    bool microphone = false;

    if (!kIsWeb) {
      notification = await Permission.notification.isGranted;
      contacts = await Permission.contacts.isGranted;
      camera = await Permission.camera.isGranted;
      microphone = await Permission.microphone.isGranted;
    }

    if (mounted) {
      setState(() {
        _notificationGranted = notification;
        _contactsGranted = contacts;
        _cameraGranted = camera;
        _microphoneGranted = microphone;
      });
    }
  }

  Future<void> _requestPermission(Permission permission) async {
    if (kIsWeb) return;

    await permission.request();
    _checkStatuses();
  }

  Future<void> _onContinue() async {
    // Automatically prompt background call & battery optimization permissions
    await PermissionHelper.requestBackgroundCallPermissions();

    // Set permission seen flag to true
    final storage = getIt<StorageService>();
    await storage.setHasSeenPermissions(true);

    if (!mounted) return;

    // Navigate to Dashboard
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const DashboardPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.colors.isDark;
    final primaryColor = context.colors.primary;

    return Scaffold(
      backgroundColor: context.colors.scaffoldBackground,
      body: Stack(
        children: [
          // Wave background matching Home Screen
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: HomeBackgroundWavePainter(isDark: isDark),
              ),
            ),
          ),

          // Main Content
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                    children: [
                      CommonSpaces.h12,

                      // Brand Hero
                      const AuthHeroHeader(),

                      CommonSpaces.h24,

                      // Headline
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: "Allow ",
                              style: context.h1.copyWith(
                                fontSize: 32,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.5,
                                color: context.colors.textPrimary,
                              ),
                            ),
                            TextSpan(
                              text: "required ",
                              style: context.h1Italic.copyWith(
                                fontSize: 32,
                                fontWeight: FontWeight.w900,
                                fontStyle: FontStyle.italic,
                                color: primaryColor,
                              ),
                            ),
                            TextSpan(
                              text: "access.",
                              style: context.h1.copyWith(
                                fontSize: 32,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.5,
                                color: context.colors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      CommonSpaces.h8,
                      Text(
                        'Enable permissions to start messaging and calling smoothly.',
                        style: context.bodyMedium.copyWith(
                          color: context.colors.textSecondary,
                          fontSize: 14,
                          height: 1.35,
                        ),
                      ),
                      CommonSpaces.h20,

                      // Permissions List
                      _buildPermissionItem(
                        title: 'Notifications',
                        description: 'Required for incoming call and message alerts.',
                        icon: Icons.notifications_none_rounded,
                        isGranted: _notificationGranted,
                        onTap: () => _requestPermission(Permission.notification),
                      ),
                      CommonSpaces.h10,
                      _buildPermissionItem(
                        title: 'Contacts',
                        description: 'Required to sync friends already on sChat.',
                        icon: Icons.people_outline_rounded,
                        isGranted: _contactsGranted,
                        onTap: () => _requestPermission(Permission.contacts),
                      ),
                      CommonSpaces.h10,
                      _buildPermissionItem(
                        title: 'Camera',
                        description: 'Required for video calls and taking photos.',
                        icon: Icons.camera_alt_outlined,
                        isGranted: _cameraGranted,
                        onTap: () => _requestPermission(Permission.camera),
                      ),
                      CommonSpaces.h10,
                      _buildPermissionItem(
                        title: 'Microphone (Audio)',
                        description: 'Required for audio calls and voice messages.',
                        icon: Icons.mic_none_rounded,
                        isGranted: _microphoneGranted,
                        onTap: () => _requestPermission(Permission.microphone),
                      ),
                      CommonSpaces.h16,
                    ],
                  ),
                ),

                // Bottom Action Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                  child: SafeArea(
                    top: false,
                    child: PrimaryActionButton(
                      title: 'Continue',
                      onPressed: _onContinue,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionItem({
    required String title,
    required String description,
    required IconData icon,
    required bool isGranted,
    required VoidCallback onTap,
  }) {
    final isDark = context.colors.isDark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: context.colors.lightBackground.withValues(alpha: isDark ? 0.75 : 0.95),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isGranted
              ? const Color(0xFF00873C).withValues(alpha: 0.35)
              : context.colors.border.withValues(alpha: 0.2),
          width: isGranted ? 1.2 : 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isGranted
                  ? const Color(0xFF00873C).withValues(alpha: 0.12)
                  : context.colors.textSecondary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: isGranted ? const Color(0xFF00873C) : context.colors.textSecondary,
              size: 19,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: context.titleSmall.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: context.colors.textPrimary,
                  ),
                ),
                CommonSpaces.h2,
                Text(
                  description,
                  style: context.bodyMedium.copyWith(
                    color: context.colors.textSecondary.withValues(alpha: 0.8),
                    fontSize: 11.5,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
          CommonSpaces.w8,
          if (isGranted)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF00873C).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFF00873C).withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.check_circle_rounded,
                    color: Color(0xFF00873C),
                    size: 13,
                  ),
                  SizedBox(width: 3),
                  Text(
                    'Allowed',
                    style: TextStyle(
                      color: Color(0xFF00873C),
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            )
          else
            ElevatedButton(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: context.colors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Grant',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
