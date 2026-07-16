import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:schat/core/storage/storage_service.dart';
import 'package:schat/features/dashboard_screen/dashboard_screen.dart';
import 'package:schat/injection.dart';
import 'package:schat/utils/common_colors.dart';
import 'package:schat/utils/common_fontstyles.dart';
import 'package:schat/utils/common_sizes.dart';
import 'package:schat/utils/common_spaces.dart';

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

    final status = await permission.request();
    if (status.isPermanentlyDenied) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Permission permanently denied. Please enable it in Settings.'),
            backgroundColor: context.colors.error,
            action: SnackBarAction(
              label: 'Settings',
              textColor: context.colors.pureWhite,
              onPressed: () => openAppSettings(),
            ),
          ),
        );
      }
    }
    _checkStatuses();
  }

  Future<void> _onContinue() async {
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
    return Scaffold(
      backgroundColor: context.colors.pureBlack,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: CommonSizes.p24, vertical: CommonSizes.p16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CommonSpaces.h32,
              // Top Icon & Title
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(CommonSizes.p12),
                    decoration: BoxDecoration(
                      color: context.colors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.shield_outlined,
                      color: context.colors.primary,
                      size: CommonSizes.iconLarge,
                    ),
                  ),
                  CommonSpaces.w16,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Access Permissions',
                          style: context.h2.copyWith(
                            color: context.colors.pureWhite,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          'Enable features for secure chat & calls',
                          style: context.bodySmall.copyWith(
                            color: context.colors.textSecondary.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              CommonSpaces.h40,
              Text(
                'sChat requires these permissions to protect and route your calls, sync contacts, and enable camera capture.',
                style: context.bodyLarge.copyWith(
                  color: context.colors.pureWhite.withValues(alpha: 0.8),
                  height: 1.4,
                  fontSize: 15,
                ),
              ),
              CommonSpaces.h32,

              // Permissions List
              Expanded(
                child: ListView(
                  children: [
                    _buildPermissionItem(
                      title: 'Notifications',
                      description: 'Required for incoming call and message alerts.',
                      icon: Icons.notifications_none_rounded,
                      isGranted: _notificationGranted,
                      onTap: () => _requestPermission(Permission.notification),
                    ),
                    CommonSpaces.h16,
                    _buildPermissionItem(
                      title: 'Contacts',
                      description: 'Required to sync friends already on sChat.',
                      icon: Icons.people_outline_rounded,
                      isGranted: _contactsGranted,
                      onTap: () => _requestPermission(Permission.contacts),
                    ),
                    CommonSpaces.h16,
                    _buildPermissionItem(
                      title: 'Camera',
                      description: 'Required for video calls and taking photos.',
                      icon: Icons.camera_alt_outlined,
                      isGranted: _cameraGranted,
                      onTap: () => _requestPermission(Permission.camera),
                    ),
                    CommonSpaces.h16,
                    _buildPermissionItem(
                      title: 'Microphone (Audio)',
                      description: 'Required for audio calls and voice messages.',
                      icon: Icons.mic_none_rounded,
                      isGranted: _microphoneGranted,
                      onTap: () => _requestPermission(Permission.microphone),
                    ),
                  ],
                ),
              ),

              CommonSpaces.h16,
              // Continue button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _onContinue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.colors.primary,
                    foregroundColor: context.colors.pureWhite,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(CommonSizes.r24),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Continue',
                    style: context.buttonText.copyWith(
                      color: context.colors.pureWhite,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              CommonSpaces.h16,
            ],
          ),
        ),
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
    return Container(
      padding: const EdgeInsets.all(CommonSizes.p16),
      decoration: BoxDecoration(
        color: context.colors.pureWhite.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(CommonSizes.r16),
        border: Border.all(
          color: isGranted 
            ? context.colors.primary.withValues(alpha: 0.3)
            : context.colors.pureWhite.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(CommonSizes.p10),
            decoration: BoxDecoration(
              color: isGranted
                ? context.colors.primary.withValues(alpha: 0.1)
                : context.colors.pureWhite.withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: isGranted ? context.colors.primary : context.colors.textSecondary,
              size: CommonSizes.iconMedium,
            ),
          ),
          CommonSpaces.w16,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: context.titleSmall.copyWith(
                    color: context.colors.pureWhite,
                  ),
                ),
                CommonSpaces.h4,
                Text(
                  description,
                  style: context.bodyMedium.copyWith(
                    color: context.colors.textSecondary.withValues(alpha: 0.6),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          CommonSpaces.w16,
          if (isGranted)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.check_circle_rounded,
                  color: context.colors.primary,
                  size: 20,
                ),
                CommonSpaces.w4,
                Text(
                  'Allowed',
                  style: TextStyle(
                    color: context.colors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            )
          else
            ElevatedButton(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: context.colors.pureWhite.withValues(alpha: 0.1),
                foregroundColor: context.colors.pureWhite,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(CommonSizes.r12),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Grant',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
    );
  }
}
