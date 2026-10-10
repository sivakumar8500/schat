import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:schat/core/storage/storage_service.dart';
import 'package:schat/features/auth_screen/auth_screen.dart';
import 'package:schat/features/profile_screen/src/presentation/bloc/profile_bloc.dart';
import 'package:schat/features/profile_screen/src/presentation/bloc/profile_event.dart';
import 'package:schat/features/profile_screen/src/presentation/bloc/profile_state.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:schat/features/profile_screen/src/presentation/emergency_contacts_page.dart';
import 'package:schat/features/chat_screen/src/presentation/full_screen_image_page.dart';
import 'package:schat/presentation/pages/blocked_users_page.dart';
import 'package:schat/features/tickets_screen/src/presentation/tickets_page.dart';
import 'package:schat/features/tickets_screen/src/presentation/bloc/tickets_bloc.dart';
import 'package:schat/features/dashboard_screen/src/presentation/dashboard_page.dart';
import 'package:schat/injection.dart';
import 'package:schat/utils/common_colors.dart';
import 'package:schat/utils/common_fontstyles.dart';
import 'package:schat/utils/common_icons.dart';
import 'package:schat/utils/common_notifications.dart';
import 'package:schat/utils/common_spaces.dart';
import 'package:schat/utils/theme_controller.dart';
import 'package:schat/features/chat_socket_screen/chat_socket_screen.dart';
import 'package:schat/features/security_scanner/presentation/pages/scan_result_screen.dart';

import 'package:schat/features/tones/data/models/tone_model.dart';
import 'package:schat/features/tones/presentation/tone_picker_screen.dart';
import 'package:schat/features/tones/services/tone_api_service.dart';
import 'package:schat/features/chat_screen/src/presentation/widgets/chat_lock_bottom_sheet.dart';
import 'package:schat/features/chat_screen/src/presentation/widgets/forgot_chat_lock_bottom_sheet.dart';
import 'package:schat/features/chat_screen/src/presentation/locked_chats_page.dart';
import 'package:schat/common/widgets/animated_tagline.dart';
import 'package:schat/core/services/in_app_update_service.dart';

class ProfileSettingsPage extends StatelessWidget {
  final String username;
  final String? profilePicUrl;

  const ProfileSettingsPage({
    super.key,
    required this.username,
    this.profilePicUrl,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ProfileBloc>(
      create: (context) => ProfileBloc()..add(const LoadProfileEvent()),
      child: _ProfileSettingsPageContent(
        username: username,
        profilePicUrl: profilePicUrl,
      ),
    );
  }
}

class _ProfileSettingsPageContent extends StatefulWidget {
  final String username;
  final String? profilePicUrl;

  const _ProfileSettingsPageContent({
    required this.username,
    this.profilePicUrl,
  });

  @override
  State<_ProfileSettingsPageContent> createState() => _ProfileSettingsPageContentState();
}

class _ProfileSettingsPageContentState extends State<_ProfileSettingsPageContent> {
  late String _currentUsername;
  String? _currentImageUrl;
  String _currentAbout = "Hey there! I am using S-CHAT.";
  String _currentEmail = "";
  XFile? _localImageFile;
  final ImagePicker _picker = ImagePicker();
  int? _defaultDisappearingTimer;
  String _callRingtoneName = "Digital Horizon (Default)";
  String _messageToneName = "S-CHAT Pop (Default)";
  bool _readReceiptsEnabled = true;
  bool _typingIndicatorsEnabled = true;
  bool _lastSeenEnabled = true;
  bool _notificationsEnabled = true;
  String _appVersion = "v1.0.0 (6)";

  @override
  void initState() {
    super.initState();
    _loadAppVersion();
    _currentUsername = widget.username;
    _currentImageUrl = widget.profilePicUrl;
    _currentEmail = getIt<StorageService>().getEmail() ?? "";
    _defaultDisappearingTimer = getIt<StorageService>().getDefaultDisappearingTimer();
    _readReceiptsEnabled = getIt<StorageService>().getReadReceiptsEnabled();
    _typingIndicatorsEnabled = getIt<StorageService>().getTypingIndicatorsEnabled();
    _lastSeenEnabled = getIt<StorageService>().getLastSeenEnabled();
    _notificationsEnabled = getIt<StorageService>().getNotificationsEnabled();

    final cachedCallTone = getIt<StorageService>().getCallRingtoneName();
    if (cachedCallTone != null && cachedCallTone.isNotEmpty) {
      _callRingtoneName = cachedCallTone;
    }
    final cachedMsgTone = getIt<StorageService>().getMessageToneName();
    if (cachedMsgTone != null && cachedMsgTone.isNotEmpty) {
      _messageToneName = cachedMsgTone;
    }
    _loadUserTones();
  }

  Future<void> _loadAppVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      int? patchNum;
      try {
        patchNum = await getIt<InAppUpdateService>().getCurrentPatchNumber();
      } catch (_) {}
      if (mounted) {
        setState(() {
          final patchStr = patchNum != null ? ' • Patch $patchNum' : '';
          _appVersion = 'v${info.version} (${info.buildNumber})$patchStr';
        });
      }
    } catch (_) {}
  }

  Future<void> _loadUserTones() async {
    try {
      final pref = await getIt<ToneApiService>().getMyTones();
      if (pref != null && mounted) {
        final storage = getIt<StorageService>();
        if (pref.callRingtone != null) {
          await storage.saveCallRingtone(
            name: pref.callRingtone!.name,
            url: pref.callRingtone!.fileUrl,
          );
        }
        if (pref.messageTone != null) {
          await storage.saveMessageTone(
            name: pref.messageTone!.name,
            url: pref.messageTone!.fileUrl,
          );
        }
        setState(() {
          if (pref.callRingtone != null) {
            _callRingtoneName = pref.callRingtone!.name +
                (pref.callRingtone!.isDefault ? " (Default)" : "");
          }
          if (pref.messageTone != null) {
            _messageToneName = pref.messageTone!.name +
                (pref.messageTone!.isDefault ? " (Default)" : "");
          }
        });
      }
    } catch (_) {}
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
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: sheetCtx.colors.textHint.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Text(
                    'Edit Profile',
                    style: sheetCtx.titleLarge.copyWith(fontWeight: FontWeight.bold),
                  ),
                  CommonSpaces.h24,
                  // Profile Image Picker
                  GestureDetector(
                    onTap: pickImage,
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: const Color(0xFFE8F5E9),
                          backgroundImage: getImageProvider(),
                          child: getImageProvider() == null
                              ? const Icon(Icons.person, size: 50, color: Color(0xFF00873C))
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: Color(0xFF00873C),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              size: 18,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  CommonSpaces.h24,
                  // Username Field
                  TextField(
                    controller: usernameController,
                    style: TextStyle(color: sheetCtx.colors.textPrimary, fontSize: 16),
                    decoration: InputDecoration(
                      labelText: 'Username',
                      labelStyle: TextStyle(color: sheetCtx.colors.textSecondary, fontSize: 16),
                      prefixIcon: const Icon(Icons.person_outline, color: Color(0xFF00873C)),
                      filled: true,
                      fillColor: sheetCtx.colors.cardBackground,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  CommonSpaces.h16,
                  // Email Field
                  TextField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: TextStyle(color: sheetCtx.colors.textPrimary, fontSize: 16),
                    decoration: InputDecoration(
                      labelText: 'Email',
                      labelStyle: TextStyle(color: sheetCtx.colors.textSecondary, fontSize: 16),
                      prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFF00873C)),
                      filled: true,
                      fillColor: sheetCtx.colors.cardBackground,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  CommonSpaces.h16,
                  // About Field
                  TextField(
                    controller: aboutController,
                    maxLines: 2,
                    style: TextStyle(color: sheetCtx.colors.textPrimary, fontSize: 16),
                    decoration: InputDecoration(
                      labelText: 'About',
                      labelStyle: TextStyle(color: sheetCtx.colors.textSecondary, fontSize: 16),
                      prefixIcon: const Icon(Icons.info_outline, color: Color(0xFF00873C)),
                      filled: true,
                      fillColor: sheetCtx.colors.cardBackground,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  CommonSpaces.h24,
                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        final newUsername = usernameController.text.trim();
                        final newAbout = aboutController.text.trim();
                        final newEmail = emailController.text.trim();

                        if (newUsername.isEmpty) {
                          sheetCtx.showErrorNotification('Username cannot be empty');
                          return;
                        }

                        context.read<ProfileBloc>().add(
                              UpdateProfileEvent(
                                username: newUsername,
                                about: newAbout,
                                imagePath: _localImageFile?.path,
                              ),
                            );

                        setState(() {
                          _currentUsername = newUsername;
                          _currentAbout = newAbout;
                          _currentEmail = newEmail;
                          if (_localImageFile != null) {
                            _currentImageUrl = _localImageFile!.path;
                          }
                        });

                        Navigator.pop(sheetCtx);
                        context.showSuccessNotification('Profile updated');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00873C),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 2,
                      ),
                      child: const Text(
                        'Save Changes',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  CommonSpaces.h12,
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
    final isDark = context.colors.isDark;

    return BlocListener<ProfileBloc, ProfileState>(
      listener: (context, state) {
        if (state is ProfileLoaded) {
          setState(() {
            _currentUsername = state.username;
            _currentImageUrl = state.imagePath;
            _currentAbout = state.user?.about ?? "Hey there! I am using S-CHAT.";
            _currentEmail = getIt<StorageService>().getEmail() ?? "";
            if (state.user != null) {
              _readReceiptsEnabled = state.user!.readReceiptsEnabled;
              _typingIndicatorsEnabled = state.user!.typingIndicatorsEnabled;
              _lastSeenEnabled = state.user!.lastSeenEnabled;
              _notificationsEnabled = state.user!.notificationsEnabled;
              _defaultDisappearingTimer = state.user!.defaultDisappearingTimer;
              getIt<StorageService>().saveDefaultDisappearingTimer(state.user!.defaultDisappearingTimer);
            }
          });
        } else if (state is ProfileLogoutSuccess) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const MobileEntryPage()),
            (Route<dynamic> route) => false,
          );
        } else if (state is ProfileAccountDeleted) {
          context.showSuccessNotification('Your account has been deleted successfully');
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const MobileEntryPage()),
            (Route<dynamic> route) => false,
          );
        } else if (state is ProfileSuccess) {
          context.read<ProfileBloc>().add(const LoadProfileEvent());
        }
      },
      child: Scaffold(
        backgroundColor: context.colors.scaffoldBackground,
        body: Stack(
          children: [
            // Flowing Wave Lines Background matching Home Screen
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
                  _buildTopAppBar(context),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
                      children: [
                        // Hero Profile Card
                        _buildHeroProfileCard(context),
                        const SizedBox(height: 20),

                        // Section 1: Account & Chats
                        _buildSectionContainer(
                          title: 'Account & Security',
                          items: [
                            _buildSettingRow(
                              context: context,
                              icon: Icons.block_rounded,
                              title: 'Blocked Users',
                              subtitle: 'Contacts you have blocked',
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const BlockedUsersPage()),
                              ),
                            ),
                            _buildSettingRow(
                              context: context,
                              icon: Icons.health_and_safety_rounded,
                              title: 'Emergency Contacts',
                              subtitle: 'SOS trusted contacts',
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const EmergencyContactsPage()),
                              ),
                            ),
                            _buildSettingRow(
                              context: context,
                              icon: Icons.sync_rounded,
                              title: 'Sync Contacts',
                              subtitle: 'Refresh address book on server',
                              onTap: () => Navigator.pop(context, 'sync'),
                            ),
                            _buildSettingRow(
                              context: context,
                              icon: Icons.lock_reset_rounded,
                              title: 'Chat Lock & Secret Code',
                              subtitle: 'Manage, change or reset secret code with OTP',
                              onTap: () => _showChatLockSettingsSheet(context),
                            ),
                            _buildSettingRow(
                              context: context,
                              icon: Icons.support_agent_rounded,
                              title: 'Support Tickets',
                              subtitle: 'Help & reported queries',
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => BlocProvider(
                                    create: (_) => getIt<TicketsBloc>(),
                                    child: const TicketsPage(),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),

                        // Section: Privacy & Activity
                        _buildSectionContainer(
                          title: 'Privacy & Activity',
                          items: [
                            _buildSettingRow(
                              context: context,
                              icon: Icons.done_all_rounded,
                              title: 'Read Receipts',
                              subtitle: _readReceiptsEnabled
                                  ? 'Others can see when you have read messages'
                                  : 'Read receipts are turned off for all chats',
                              trailing: Switch.adaptive(
                                value: _readReceiptsEnabled,
                                activeThumbColor: const Color(0xFF00873C),
                                onChanged: (val) {
                                  setState(() {
                                    _readReceiptsEnabled = val;
                                  });
                                  getIt<StorageService>().saveReadReceiptsEnabled(val);
                                  context.read<ProfileBloc>().add(
                                    UpdateGlobalPrivacyEvent(readReceiptsEnabled: val),
                                  );
                                },
                              ),
                            ),
                            _buildSettingRow(
                              context: context,
                              icon: Icons.keyboard_rounded,
                              title: 'Typing Indicators',
                              subtitle: _typingIndicatorsEnabled
                                  ? 'Others can see when you are typing'
                                  : 'Typing indicators are turned off for all chats',
                              trailing: Switch.adaptive(
                                value: _typingIndicatorsEnabled,
                                activeThumbColor: const Color(0xFF00873C),
                                onChanged: (val) {
                                  setState(() {
                                    _typingIndicatorsEnabled = val;
                                  });
                                  getIt<StorageService>().saveTypingIndicatorsEnabled(val);
                                  context.read<ProfileBloc>().add(
                                    UpdateGlobalPrivacyEvent(typingIndicatorsEnabled: val),
                                  );
                                },
                              ),
                            ),
                            _buildSettingRow(
                              context: context,
                              icon: Icons.access_time_rounded,
                              title: 'Last Seen',
                              subtitle: _lastSeenEnabled
                                  ? 'Others can see when you were last active'
                                  : 'Your last seen timestamp is hidden from everyone',
                              trailing: Switch.adaptive(
                                value: _lastSeenEnabled,
                                activeThumbColor: const Color(0xFF00873C),
                                onChanged: (val) {
                                  setState(() {
                                    _lastSeenEnabled = val;
                                  });
                                  getIt<StorageService>().saveLastSeenEnabled(val);
                                  context.read<ProfileBloc>().add(
                                    UpdateGlobalPrivacyEvent(lastSeenEnabled: val),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),

                        // Section 2: Notifications & Sounds
                        _buildSectionContainer(
                          title: 'Notifications & Sounds',
                          items: [
                            _buildSettingRow(
                              context: context,
                              icon: _notificationsEnabled
                                  ? Icons.notifications_active_rounded
                                  : Icons.notifications_off_rounded,
                              title: 'Notifications',
                              subtitle: _notificationsEnabled
                                  ? 'Push notifications & message alerts are enabled'
                                  : 'All notifications are muted for this account',
                              trailing: Switch.adaptive(
                                value: _notificationsEnabled,
                                activeThumbColor: const Color(0xFF00873C),
                                onChanged: (val) {
                                  setState(() {
                                    _notificationsEnabled = val;
                                  });
                                  getIt<StorageService>().saveNotificationsEnabled(val);
                                  context.read<ProfileBloc>().add(
                                    UpdateGlobalPrivacyEvent(notificationsEnabled: val),
                                  );
                                },
                              ),
                            ),
                            _buildSettingRow(
                              context: context,
                              icon: Icons.ring_volume_rounded,
                              title: 'Call Ringtone',
                              subtitle: _callRingtoneName,
                              onTap: () async {
                                final Tone? selected = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => TonePickerScreen(
                                      toneType: ToneType.CALL,
                                      initialSelectedToneName:
                                          _callRingtoneName.replaceAll(' (Default)', ''),
                                    ),
                                  ),
                                );
                                if (selected != null && mounted) {
                                  setState(() {
                                    _callRingtoneName =
                                        selected.name + (selected.isDefault ? ' (Default)' : '');
                                  });
                                }
                              },
                            ),
                            _buildSettingRow(
                              context: context,
                              icon: Icons.notifications_active_rounded,
                              title: 'Message Tone',
                              subtitle: _messageToneName,
                              onTap: () async {
                                final Tone? selected = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => TonePickerScreen(
                                      toneType: ToneType.MESSAGE,
                                      initialSelectedToneName:
                                          _messageToneName.replaceAll(' (Default)', ''),
                                    ),
                                  ),
                                );
                                if (selected != null && mounted) {
                                  setState(() {
                                    _messageToneName =
                                        selected.name + (selected.isDefault ? ' (Default)' : '');
                                  });
                                }
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),

                        // Section 3: App Preferences
                        _buildSectionContainer(
                          title: 'App Preferences',
                          items: [
                            _buildSettingRow(
                              context: context,
                              icon: getIt<ThemeController>().themeMode == ThemeMode.dark
                                  ? Icons.dark_mode_rounded
                                  : Icons.light_mode_rounded,
                              title: 'Theme Mode',
                              subtitle: getIt<ThemeController>().themeMode == ThemeMode.dark
                                  ? 'Dark theme enabled'
                                  : 'Light theme enabled',
                              trailing: Switch.adaptive(
                                value: getIt<ThemeController>().themeMode == ThemeMode.dark,
                                activeThumbColor: const Color(0xFF00873C),
                                onChanged: (val) {
                                  setState(() {
                                    getIt<ThemeController>().toggleTheme();
                                  });
                                },
                              ),
                            ),
                            _buildSettingRow(
                              context: context,
                              icon: Icons.format_size_rounded,
                              title: 'Font Size',
                              subtitle: getIt<ThemeController>().fontSizeName,
                              onTap: () => _showFontSizeBottomSheet(context),
                            ),
                            _buildSettingRow(
                              context: context,
                              icon: Icons.timer_rounded,
                              title: 'Disappearing Messages',
                              subtitle: _getDisappearingTimerText(_defaultDisappearingTimer),
                              onTap: () => _showDisappearingMessagesBottomSheet(context),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),

                        // Section 4: Security & Tools
                        _buildSectionContainer(
                          title: 'Security & Diagnostics',
                          items: [
                            _buildSettingRow(
                              context: context,
                              icon: Icons.shield_rounded,
                              title: 'Scan Device Security',
                              subtitle: 'Verify attachments & device integrity',
                              onTap: () => _showSecurityScanConfirmationBottomSheet(context),
                            ),
                            _buildSettingRow(
                              context: context,
                              icon: CommonIcons.wifi,
                              title: 'WebSocket Diagnostics',
                              subtitle: 'Test server connection & event logs',
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const ChatSocketPage()),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),

                        // Section 5: Account Actions (Logout & Delete Account)
                        Container(
                          decoration: BoxDecoration(
                            color: isDark ? context.colors.cardBackground : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: const Color(0xFFE53935).withValues(alpha: 0.3),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                leading: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFEBEE),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.logout_rounded,
                                    color: Color(0xFFE53935),
                                    size: 20,
                                  ),
                                ),
                                title: const Text(
                                  'Logout',
                                  style: TextStyle(
                                    color: Color(0xFFE53935),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                                subtitle: Text(
                                  'Sign out of your account on this device',
                                  style: TextStyle(
                                    color: context.colors.textSecondary,
                                    fontSize: 13,
                                  ),
                                ),
                                trailing: const Icon(
                                  Icons.chevron_right_rounded,
                                  color: Color(0xFFE53935),
                                ),
                                onTap: () => _showLogoutBottomSheet(context),
                              ),
                              Divider(
                                height: 1,
                                thickness: 0.6,
                                color: context.colors.divider.withValues(alpha: 0.3),
                                indent: 16,
                                endIndent: 16,
                              ),
                              ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                leading: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFEBEE),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.delete_forever_rounded,
                                    color: Color(0xFFD92D20),
                                    size: 22,
                                  ),
                                ),
                                title: const Text(
                                  'Delete Account',
                                  style: TextStyle(
                                    color: Color(0xFFD92D20),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                                subtitle: Text(
                                  'Permanently erase your account, messages & data',
                                  style: TextStyle(
                                    color: context.colors.textSecondary,
                                    fontSize: 13,
                                  ),
                                ),
                                trailing: const Icon(
                                  Icons.chevron_right_rounded,
                                  color: Color(0xFFD92D20),
                                ),
                                onTap: () => _showDeleteAccountBottomSheet(context),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 28),
                        Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'S-CHAT',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.2,
                                  color: context.colors.textPrimary.withValues(alpha: 0.8),
                                ),
                              ),
                              const SizedBox(height: 6),
                              const AnimatedTagline(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                showShieldIcon: true,
                              ),
                              const SizedBox(height: 10),
                              InkWell(
                                onTap: () async {
                                  context.showSuccessNotification('Checking for new releases...');
                                  await getIt<InAppUpdateService>().checkForUpdate(
                                    context: context,
                                    isManualCheck: true,
                                  );
                                },
                                borderRadius: BorderRadius.circular(20),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                                  decoration: BoxDecoration(
                                    color: context.colors.lightBackground,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: context.colors.textHint.withValues(alpha: 0.2),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.system_update_rounded, size: 14, color: context.colors.primary),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Version $_appVersion',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: context.colors.textSecondary,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: context.colors.primary.withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          'Check Updates',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: context.colors.primary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: context.colors.lightBackground,
              border: Border.all(
                color: context.colors.border.withValues(alpha: 0.3),
              ),
            ),
            child: IconButton(
              padding: EdgeInsets.zero,
              icon: Icon(Icons.arrow_back_rounded, color: context.colors.textPrimary, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          CommonSpaces.w10,
          Text(
            'Settings',
            style: TextStyle(
              fontSize: 16.5,
              fontWeight: FontWeight.w700,
              color: context.colors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroProfileCard(BuildContext context) {
    final isDark = context.colors.isDark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? context.colors.cardBackground : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: context.colors.border.withValues(alpha: 0.4),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          // Avatar
          GestureDetector(
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
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 34,
                  backgroundColor: const Color(0xFFE8F5E9),
                  backgroundImage: (_currentImageUrl != null && _currentImageUrl!.isNotEmpty)
                      ? NetworkImage(_currentImageUrl!)
                      : null,
                  child: (_currentImageUrl == null || _currentImageUrl!.isEmpty)
                      ? const Icon(Icons.person_rounded, size: 36, color: Color(0xFF00873C))
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: const Color(0xFF00873C),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white,
                        width: 2,
                      ),
                    ),
                    child: const Icon(Icons.camera_alt_rounded, size: 12, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          CommonSpaces.w16,
          // User Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _currentUsername,
                  style: context.titleLarge.copyWith(
                    fontWeight: FontWeight.bold,
                    color: context.colors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  _currentAbout,
                  style: TextStyle(
                    color: context.colors.textSecondary,
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (_currentEmail.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    _currentEmail,
                    style: TextStyle(
                      color: context.colors.textHint,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          // Edit Button
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.edit_rounded, color: Color(0xFF00873C), size: 18),
              onPressed: () => _showEditProfileBottomSheet(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionContainer({
    required String title,
    required List<Widget> items,
  }) {
    final isDark = context.colors.isDark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 8),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Color(0xFF00873C),
              letterSpacing: 0.3,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: isDark ? context.colors.cardBackground : Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: context.colors.border.withValues(alpha: 0.35),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: List.generate(items.length, (index) {
              final isLast = index == items.length - 1;
              return Column(
                children: [
                  items[index],
                  if (!isLast)
                    Divider(
                      height: 1,
                      indent: 64,
                      endIndent: 16,
                      color: context.colors.border.withValues(alpha: 0.3),
                    ),
                ],
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildSettingRow({
    required BuildContext context,
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: const Color(0xFFE8F5E9),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          color: const Color(0xFF00873C),
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: context.colors.textPrimary,
          fontWeight: FontWeight.w600,
          fontSize: 15,
        ),
      ),
      subtitle: subtitle != null && subtitle.isNotEmpty
          ? Text(
              subtitle,
              style: TextStyle(
                color: context.colors.textSecondary,
                fontSize: 13,
              ),
            )
          : null,
      trailing: trailing ??
          Icon(
            Icons.chevron_right_rounded,
            color: context.colors.textHint,
            size: 22,
          ),
    );
  }

  void _showChatLockSettingsSheet(BuildContext context) {
    final colors = context.colors;
    final primaryColor = const Color(0xFF00873C);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => Container(
        decoration: BoxDecoration(
          color: colors.cardBackground,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.textHint.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            CommonSpaces.h16,
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.lock_rounded, color: primaryColor, size: 22),
                ),
                CommonSpaces.w12,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Chat Lock & Secret Code',
                        style: context.titleMedium.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colors.textPrimary,
                        ),
                      ),
                      Text(
                        'Manage your secret code to keep conversations secure',
                        style: context.bodySmall.copyWith(color: colors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            CommonSpaces.h20,

            // Option 1: Forgot Secret Code (OTP Reset)
            ListTile(
              onTap: () {
                Navigator.pop(sheetCtx);
                ForgotChatLockBottomSheet.show(context);
              },
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.lock_reset_rounded, color: primaryColor, size: 20),
              ),
              title: Text(
                'Forgot Secret Code / Password',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: colors.textPrimary,
                ),
              ),
              subtitle: Text(
                'Reset your secret code using OTP sent to registered mobile',
                style: TextStyle(fontSize: 12, color: colors.textSecondary),
              ),
              trailing: Icon(Icons.chevron_right_rounded, color: colors.textHint),
            ),
            const Divider(height: 16),

            // Option 2: Change / Set Secret Code
            ListTile(
              onTap: () {
                Navigator.pop(sheetCtx);
                ChatLockBottomSheet.show(
                  context,
                  conversationId: '',
                  contactName: 'Settings',
                  isCurrentlyLocked: false,
                );
              },
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.password_rounded, color: Colors.blue, size: 20),
              ),
              title: Text(
                'Change Secret Code',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: colors.textPrimary,
                ),
              ),
              subtitle: Text(
                'Change existing secret code with emojis, numbers, or text',
                style: TextStyle(fontSize: 12, color: colors.textSecondary),
              ),
              trailing: Icon(Icons.chevron_right_rounded, color: colors.textHint),
            ),
            const Divider(height: 16),

            // Option 3: View Locked Chats
            ListTile(
              onTap: () {
                Navigator.pop(sheetCtx);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LockedChatsPage()),
                );
              },
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.folder_special_rounded, color: Colors.amber, size: 20),
              ),
              title: Text(
                'View Locked Chats',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: colors.textPrimary,
                ),
              ),
              subtitle: Text(
                'View all conversations currently locked in your account',
                style: TextStyle(fontSize: 12, color: colors.textSecondary),
              ),
              trailing: Icon(Icons.chevron_right_rounded, color: colors.textHint),
            ),
          ],
        ),
      ),
    );
  }

  void _showFontSizeBottomSheet(BuildContext context) {
    final currentSize = getIt<ThemeController>().fontSizeName;
    final isDark = context.colors.isDark;
    final primaryColor = const Color(0xFF00873C);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(sheetCtx).size.height * 0.85,
          ),
          decoration: BoxDecoration(
            color: sheetCtx.colors.scaffoldBackground,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: sheetCtx.colors.textHint.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.format_size_rounded,
                          color: Color(0xFF00873C),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Font Size',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: sheetCtx.colors.textPrimary,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Choose a font size for messages and interface text across the app.',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.white60 : const Color(0xFF6B7280),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 20),
              ...[
                {'title': 'Small', 'desc': 'Compact text size for high density'},
                {'title': 'Medium', 'desc': 'Default standard font size'},
                {'title': 'Large', 'desc': 'Larger text for better legibility'},
              ].map((item) {
                final size = item['title']!;
                final desc = item['desc']!;
                final isSelected = size.toLowerCase() == currentSize.toLowerCase();

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? (isDark ? const Color(0xFF00873C).withValues(alpha: 0.15) : const Color(0xFFE8F5E9))
                        : (isDark ? sheetCtx.colors.cardBackground : Colors.white),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? primaryColor
                          : sheetCtx.colors.border.withValues(alpha: 0.3),
                      width: isSelected ? 1.5 : 1.0,
                    ),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    title: Text(
                      size,
                      style: TextStyle(
                        fontSize: 15.5,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                        color: isSelected ? primaryColor : sheetCtx.colors.textPrimary,
                      ),
                    ),
                    subtitle: Text(
                      desc,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: isSelected
                            ? (isDark ? Colors.white70 : const Color(0xFF027A48))
                            : (isDark ? Colors.white54 : const Color(0xFF6B7280)),
                      ),
                    ),
                    trailing: isSelected
                        ? Container(
                            width: 26,
                            height: 26,
                            decoration: BoxDecoration(
                              color: primaryColor,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.check_rounded,
                              size: 16,
                              color: isDark ? Colors.black : Colors.white,
                            ),
                          )
                        : null,
                    onTap: () {
                      getIt<ThemeController>().setFontSize(size);
                      Navigator.pop(sheetCtx);
                      setState(() {});
                    },
                  ),
                );
              }),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  },
);
}

  void _showLogoutBottomSheet(BuildContext context) {
    final isDark = context.colors.isDark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(sheetCtx).size.height * 0.85,
        ),
        decoration: BoxDecoration(
          color: sheetCtx.colors.scaffoldBackground,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: sheetCtx.colors.textHint.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEE4E2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.logout_rounded,
                        color: Color(0xFFD92D20),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Logout',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: sheetCtx.colors.textPrimary,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Are you sure you want to log out from this account on this device?',
                  style: TextStyle(
                    fontSize: 14.5,
                    height: 1.45,
                    color: isDark ? Colors.white70 : const Color(0xFF4B5563),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(sheetCtx),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: BorderSide(color: sheetCtx.colors.border.withValues(alpha: 0.4)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            color: sheetCtx.colors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(sheetCtx);
                          context.read<ProfileBloc>().add(const LogoutEvent());
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          backgroundColor: const Color(0xFFD92D20),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: const Text(
                          'Logout',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDeleteAccountBottomSheet(BuildContext context) {
    final isDark = context.colors.isDark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(sheetCtx).size.height * 0.85,
        ),
        decoration: BoxDecoration(
          color: sheetCtx.colors.scaffoldBackground,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: sheetCtx.colors.textHint.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEE4E2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.delete_forever_rounded,
                        color: Color(0xFFD92D20),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Delete Account',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: sheetCtx.colors.textPrimary,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  'Are you sure you want to delete your account? This action is permanent and cannot be undone.',
                  style: TextStyle(
                    fontSize: 14.5,
                    height: 1.45,
                    fontWeight: FontWeight.w600,
                    color: sheetCtx.colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF2C1618) : const Color(0xFFFFF1F0),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: const Color(0xFFFFA39E).withValues(alpha: 0.5),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDeletionWarningPoint('Your phone number registration and profile will be permanently deleted.'),
                      const SizedBox(height: 8),
                      _buildDeletionWarningPoint('All 1-on-1 chats, chat histories, and shared media files will be erased.'),
                      const SizedBox(height: 8),
                      _buildDeletionWarningPoint('You will be removed from all group chats.'),
                      const SizedBox(height: 8),
                      _buildDeletionWarningPoint('Your contacts sync, backups, and security settings will be deleted.'),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(sheetCtx),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: BorderSide(color: sheetCtx.colors.border.withValues(alpha: 0.4)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            color: sheetCtx.colors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(sheetCtx);
                          context.read<ProfileBloc>().add(const DeleteAccountEvent());
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          backgroundColor: const Color(0xFFD92D20),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: const Text(
                          'Delete Account',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDeletionWarningPoint(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 4),
          child: Icon(
            Icons.circle,
            size: 6,
            color: Color(0xFFCF1322),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              height: 1.4,
              color: Color(0xFFD92D20),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  int _encodeDailyCutoffTime(int hour, int minute) {
    return -((hour * 3600 + minute * 60) + 1);
  }

  TimeOfDay? _decodeDailyCutoffTime(int? encoded) {
    if (encoded == null || encoded >= 0) return null;
    final totalSeconds = (-encoded) - 1;
    final hour = totalSeconds ~/ 3600;
    final minute = (totalSeconds % 3600) ~/ 60;
    return TimeOfDay(hour: hour, minute: minute);
  }

  String _formatDailyCutoffText(int hour, int minute) {
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour % 12 == 0 ? 12 : hour % 12;
    final displayMinute = minute == 0 ? '' : ':${minute.toString().padLeft(2, '0')}';
    return 'Daily at $displayHour$displayMinute $period';
  }

  String _getDisappearingTimerText(int? seconds) {
    if (seconds == null || seconds == 0) {
      return 'Off';
    }
    if (seconds < 0) {
      final tod = _decodeDailyCutoffTime(seconds);
      if (tod != null) {
        return _formatDailyCutoffText(tod.hour, tod.minute);
      }
      return 'Custom daily';
    }
    if (seconds == 1800) {
      return '30 minutes';
    }
    if (seconds == 604800) {
      return '7 days';
    }
    if (seconds == 2592000) {
      return '30 days';
    }
    if (seconds < 60) return '$seconds seconds';
    if (seconds < 3600) return '${(seconds / 60).round()} minutes';
    if (seconds < 86400) return '${(seconds / 3600).round()} hours';
    final days = seconds ~/ 86400;
    if (days == 1) return '24 hours';
    if (days % 7 == 0) return '${days ~/ 7} weeks';
    return '$days days';
  }

  void _showDisappearingMessagesBottomSheet(BuildContext context) {
    final isDark = context.colors.isDark;
    final primaryColor = const Color(0xFF00873C);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(sheetCtx).size.height * 0.85,
          ),
          decoration: BoxDecoration(
            color: sheetCtx.colors.scaffoldBackground,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: sheetCtx.colors.textHint.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.timer_outlined,
                          color: Color(0xFF00873C),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Disappearing Messages',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: sheetCtx.colors.textPrimary,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'For more privacy and storage, all messages will disappear across all chats after the selected duration.',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.white60 : const Color(0xFF6B7280),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildDisappearingOption(context, sheetCtx, 'Off', null, primaryColor),
                  _buildDisappearingOption(context, sheetCtx, '24 hours', 86400, primaryColor),
                  _buildDisappearingOption(context, sheetCtx, '7 days', 604800, primaryColor),
                  _buildDisappearingOption(context, sheetCtx, '30 days', 2592000, primaryColor),
                  _buildCustomDailyTimeOption(context, sheetCtx, primaryColor),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCustomDailyTimeOption(BuildContext blocContext, BuildContext sheetCtx, Color primaryColor) {
    final bool isCustom = _defaultDisappearingTimer != null && _defaultDisappearingTimer! < 0;
    final isDark = sheetCtx.colors.isDark;
    final customText = isCustom ? _getDisappearingTimerText(_defaultDisappearingTimer) : null;
    final presets = [
      {'label': '2 AM', 'h': 2, 'm': 0},
      {'label': '7 AM', 'h': 7, 'm': 0},
      {'label': '1 PM', 'h': 13, 'm': 0},
      {'label': '2 PM', 'h': 14, 'm': 0},
      {'label': '5 PM', 'h': 17, 'm': 0},
      {'label': '11 PM', 'h': 23, 'm': 0},
    ];

    void applyCustom(int encoded) {
      Navigator.pop(sheetCtx);
      setState(() {
        _defaultDisappearingTimer = encoded;
      });
      getIt<StorageService>().saveDefaultDisappearingTimer(encoded);
      blocContext.read<ProfileBloc>().add(UpdateDefaultDisappearingTimerEvent(seconds: encoded));
      blocContext.showInfoNotification('Default disappearing messages set to ${_getDisappearingTimerText(encoded)}');
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isCustom
            ? (isDark ? const Color(0xFF00873C).withValues(alpha: 0.15) : const Color(0xFFE8F5E9))
            : (isDark ? sheetCtx.colors.cardBackground : Colors.white),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isCustom ? primaryColor : sheetCtx.colors.border.withValues(alpha: 0.3),
          width: isCustom ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
            title: Text(
              isCustom ? 'Custom ($customText)' : 'Custom daily time',
              style: TextStyle(
                fontSize: 15,
                fontWeight: isCustom ? FontWeight.w700 : FontWeight.w500,
                color: isCustom ? primaryColor : sheetCtx.colors.textPrimary,
              ),
            ),
            subtitle: Text(
              'Clears last 24h chats daily at selected time',
              style: TextStyle(fontSize: 12, color: sheetCtx.colors.textSecondary),
            ),
            trailing: isCustom
                ? Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(color: primaryColor, shape: BoxShape.circle),
                    child: Icon(Icons.check_rounded, size: 15, color: isDark ? Colors.black : Colors.white),
                  )
                : null,
            onTap: () async {
              final picked = await showTimePicker(
                context: sheetCtx,
                initialTime: isCustom
                    ? (_decodeDailyCutoffTime(_defaultDisappearingTimer) ?? const TimeOfDay(hour: 14, minute: 0))
                    : const TimeOfDay(hour: 14, minute: 0),
              );
              if (picked != null) {
                final encoded = _encodeDailyCutoffTime(picked.hour, picked.minute);
                applyCustom(encoded);
              }
            },
          ),
          Padding(
            padding: const EdgeInsets.only(left: 12, right: 12, bottom: 10),
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                ...presets.map((p) {
                  final encoded = _encodeDailyCutoffTime(p['h'] as int, p['m'] as int);
                  final isSelected = _defaultDisappearingTimer == encoded;
                  return InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => applyCustom(encoded),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: isSelected ? primaryColor : primaryColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected ? primaryColor : primaryColor.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        p['label'] as String,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? (isDark ? Colors.black : Colors.white) : primaryColor,
                        ),
                      ),
                    ),
                  );
                }),
                InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () async {
                    final picked = await showTimePicker(
                      context: sheetCtx,
                      initialTime: isCustom
                          ? (_decodeDailyCutoffTime(_defaultDisappearingTimer) ?? const TimeOfDay(hour: 14, minute: 0))
                          : const TimeOfDay(hour: 14, minute: 0),
                    );
                    if (picked != null) {
                      final encoded = _encodeDailyCutoffTime(picked.hour, picked.minute);
                      applyCustom(encoded);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: primaryColor.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.more_time, size: 12, color: primaryColor),
                        const SizedBox(width: 4),
                        Text(
                          'Pick Time',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: primaryColor,
                          ),
                        ),
                      ],
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

  Widget _buildDisappearingOption(
      BuildContext blocContext, BuildContext sheetCtx, String label, int? seconds, Color primaryColor) {
    final bool isSelected = _defaultDisappearingTimer == seconds;
    final isDark = sheetCtx.colors.isDark;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isSelected
            ? (isDark ? const Color(0xFF00873C).withValues(alpha: 0.15) : const Color(0xFFE8F5E9))
            : (isDark ? sheetCtx.colors.cardBackground : Colors.white),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isSelected
              ? primaryColor
              : sheetCtx.colors.border.withValues(alpha: 0.3),
          width: isSelected ? 1.5 : 1.0,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
        title: Text(
          label,
          style: TextStyle(
            fontSize: 15,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? primaryColor : sheetCtx.colors.textPrimary,
          ),
        ),
        trailing: isSelected
            ? Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: primaryColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_rounded,
                  size: 15,
                  color: isDark ? Colors.black : Colors.white,
                ),
              )
            : null,
        onTap: () {
          Navigator.pop(sheetCtx);
          setState(() {
            _defaultDisappearingTimer = seconds;
          });
          getIt<StorageService>().saveDefaultDisappearingTimer(seconds);
          blocContext.read<ProfileBloc>().add(UpdateDefaultDisappearingTimerEvent(seconds: seconds));
          blocContext.showInfoNotification('Default disappearing messages set to $label');
        },
      ),
    );
  }

  void _showSecurityScanConfirmationBottomSheet(BuildContext context) {
    final isDark = context.colors.isDark;
    final primaryColor = const Color(0xFF00873C);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(sheetCtx).size.height * 0.85,
        ),
        decoration: BoxDecoration(
          color: sheetCtx.colors.scaffoldBackground,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: sheetCtx.colors.textHint.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.shield_outlined,
                        color: Color(0xFF00873C),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Scan Device Security',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: sheetCtx.colors.textPrimary,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'This scan verifies user-accessible files, downloaded attachments, and links for known threats.\n\nIt runs as a local in-app security verification for your chats.',
                  style: TextStyle(
                    fontSize: 14.5,
                    height: 1.45,
                    color: isDark ? Colors.white70 : const Color(0xFF4B5563),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(sheetCtx),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: BorderSide(color: sheetCtx.colors.border.withValues(alpha: 0.4)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            color: sheetCtx.colors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(sheetCtx);
                          ScanResultScreen.navigateTo(context);
                        },
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          backgroundColor: primaryColor,
                          foregroundColor: isDark ? Colors.black : Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: Text(
                          'Start Scan',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.black : Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
