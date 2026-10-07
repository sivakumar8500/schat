import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:schat/core/storage/storage_service.dart';
import 'package:schat/features/status_screen/src/domain/status_model.dart';
import 'package:schat/features/status_screen/src/presentation/bloc/status_bloc.dart';
import 'package:schat/features/status_screen/src/presentation/bloc/status_event.dart';
import 'package:schat/features/status_screen/src/presentation/bloc/status_state.dart';
import 'package:schat/features/status_screen/src/presentation/widgets/image_status_editor_page.dart';
import 'package:schat/features/status_screen/src/presentation/widgets/status_privacy_sheet.dart';
import 'package:schat/features/status_screen/src/presentation/widgets/text_status_creator_page.dart';
import 'package:schat/features/status_screen/src/presentation/widgets/voice_status_creator_page.dart';
import 'package:schat/features/status_screen/src/presentation/widgets/video_status_trimmer_page.dart';
import 'package:schat/features/status_screen/src/presentation/status_view_page.dart';
import 'package:schat/injection.dart';
import 'package:schat/utils/common_colors.dart';
import 'package:schat/utils/common_fontstyles.dart';
import 'package:schat/utils/common_notifications.dart';
import 'package:schat/utils/common_sizes.dart';

class StatusPage extends StatelessWidget {
  const StatusPage({super.key});

  @override
  Widget build(BuildContext context) {
    try {
      context.read<StatusBloc>();
      return const StatusPageContent();
    } catch (_) {
      return BlocProvider<StatusBloc>(
        create: (context) => StatusBloc()..add(const LoadStatusUpdatesEvent()),
        child: const StatusPageContent(),
      );
    }
  }
}

class StatusPageContent extends StatelessWidget {
  const StatusPageContent({super.key});

  Future<void> _pickStatusImage(BuildContext context) async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (image == null) return;

    final bytes = kIsWeb ? await image.readAsBytes() : null;
    final path = kIsWeb ? null : image.path;

    if (context.mounted) {
      final bloc = context.read<StatusBloc>();
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => BlocProvider.value(
            value: bloc,
            child: ImageStatusEditorPage(
              imagePath: path,
              imageBytes: bytes,
            ),
          ),
        ),
      );
    }
  }

  Future<void> _pickStatusVideo(BuildContext context, {ImageSource source = ImageSource.gallery}) async {
    final picker = ImagePicker();
    final XFile? video = await picker.pickVideo(
      source: source,
    );
    if (video == null) return;

    final path = video.path;
    final bytes = kIsWeb ? await video.readAsBytes() : null;

    Duration videoDuration = const Duration(seconds: 0);

    // Inspect video duration
    if (!kIsWeb && path.isNotEmpty) {
      try {
        final videoController = VideoPlayerController.file(File(path));
        await videoController.initialize();
        videoDuration = videoController.value.duration;
        await videoController.dispose();
      } catch (e) {
        debugPrint('Error inspecting video duration: $e');
      }
    }

    if (!context.mounted) return;

    final bloc = context.read<StatusBloc>();
    final exceedsLimit = videoDuration.inSeconds > 60;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: bloc,
          child: VideoStatusTrimmerPage(
            videoPath: path,
            videoBytes: bytes,
            totalDuration: videoDuration,
            exceedsLimit: exceedsLimit,
          ),
        ),
      ),
    );
  }

  void _addVoiceStatus(BuildContext context) {
    final bloc = context.read<StatusBloc>();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: bloc,
          child: const VoiceStatusCreatorPage(),
        ),
      ),
    );
  }

  void _addTextStatus(BuildContext context) {
    final bloc = context.read<StatusBloc>();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: bloc,
          child: const TextStatusCreatorPage(),
        ),
      ),
    );
  }

  Future<void> _pickStatusCamera(BuildContext context) async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.camera, imageQuality: 85);
    if (image == null) return;

    final bytes = kIsWeb ? await image.readAsBytes() : null;
    final path = kIsWeb ? null : image.path;

    if (context.mounted) {
      final bloc = context.read<StatusBloc>();
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => BlocProvider.value(
            value: bloc,
            child: ImageStatusEditorPage(
              imagePath: path,
              imageBytes: bytes,
            ),
          ),
        ),
      );
    }
  }

  void _showCameraOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final colors = ctx.colors;
        return Container(
          decoration: BoxDecoration(
            color: colors.cardBackground,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 16,
            bottom: MediaQuery.of(ctx).padding.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Camera',
                style: ctx.titleMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: colors.primary.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.camera_alt_outlined, color: colors.primary),
                ),
                title: Text('Take Photo', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickStatusCamera(context);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: colors.primary.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.videocam_outlined, color: colors.primary),
                ),
                title: Text('Record Video (Max 1 min)', style: TextStyle(color: colors.textPrimary, fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickStatusVideo(context, source: ImageSource.camera);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showUploadOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        final colors = ctx.colors;
        return Container(
          decoration: BoxDecoration(
            color: colors.cardBackground,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 12,
            bottom: MediaQuery.of(ctx).padding.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Pill drag handle
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colors.textHint.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Header: Title + Close 'X'
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Add Status',
                    style: ctx.titleLarge.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colors.textPrimary,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: colors.textSecondary, size: 22),
                    onPressed: () => Navigator.pop(ctx),
                    splashRadius: 20,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Divider(height: 1, color: colors.textHint.withValues(alpha: 0.12)),
              const SizedBox(height: 6),

              // 1. Photo
              _buildUploadOptionRow(
                context: ctx,
                icon: Icons.image_outlined,
                title: 'Photo',
                subtitle: 'Add a picture to your status',
                onTap: () {
                  Navigator.pop(ctx);
                  _pickStatusImage(context);
                },
              ),
              Divider(height: 1, color: colors.textHint.withValues(alpha: 0.08)),

              // 2. Video (Max 1 min)
              _buildUploadOptionRow(
                context: ctx,
                icon: Icons.videocam_outlined,
                title: 'Video (Max 1 min)',
                subtitle: 'Share video clips up to 60 seconds',
                onTap: () {
                  Navigator.pop(ctx);
                  _pickStatusVideo(context, source: ImageSource.gallery);
                },
              ),
              Divider(height: 1, color: colors.textHint.withValues(alpha: 0.08)),

              // 3. Voice Status (Max 1 min)
              _buildUploadOptionRow(
                context: ctx,
                icon: Icons.mic_none_outlined,
                title: 'Voice Status (Max 1 min)',
                subtitle: 'Record voice notes up to 60 seconds',
                onTap: () {
                  Navigator.pop(ctx);
                  _addVoiceStatus(context);
                },
              ),
              Divider(height: 1, color: colors.textHint.withValues(alpha: 0.08)),

              // 4. Text Status
              _buildUploadOptionRow(
                context: ctx,
                icon: Icons.title,
                title: 'Text Status',
                subtitle: 'Share thoughts with colorful background',
                onTap: () {
                  Navigator.pop(ctx);
                  _addTextStatus(context);
                },
              ),
              Divider(height: 1, color: colors.textHint.withValues(alpha: 0.08)),

              // 5. Camera
              _buildUploadOptionRow(
                context: ctx,
                icon: Icons.camera_alt_outlined,
                title: 'Camera',
                subtitle: 'Take a photo or record video',
                onTap: () {
                  Navigator.pop(ctx);
                  _showCameraOptions(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildUploadOptionRow({
    required BuildContext context,
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    final colors = context.colors;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: colors.primary, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w600,
                      color: colors.textPrimary,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 14, color: colors.textHint),
          ],
        ),
      ),
    );
  }

  void _viewStatus(BuildContext context, List<StatusContactModel> list, int index) async {
    final statusBloc = context.read<StatusBloc>();
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StatusViewPage(
          contacts: list,
          initialIndex: index,
        ),
      ),
    );
    statusBloc.add(const LoadStatusUpdatesEvent());
  }

  void _viewMyStatus(BuildContext context, List<StatusItemModel> myStatuses, Uint8List? bytes, String? path, String? text) {
    if (myStatuses.isEmpty && bytes == null && path == null && text == null) {
      _showUploadOptions(context);
      return;
    }
    final statusBloc = context.read<StatusBloc>();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StatusViewPage(
          contacts: const [],
          isMyStatus: true,
          myStatuses: myStatuses,
          myBytes: bytes,
          myPath: path,
          myText: text,
        ),
      ),
    ).then((_) => statusBloc.add(const LoadStatusUpdatesEvent()));
  }

  String _formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hr ago';
    return 'Yesterday';
  }

  void _showSettingsMenu(BuildContext context) {
    _showStatusPrivacySheet(context);
  }

  void _showStatusPrivacySheet(BuildContext context) {
    final bloc = context.read<StatusBloc>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: bloc,
        child: const StatusPrivacySheet(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<StatusBloc, StatusState>(
      listener: (context, state) {
        if (state is StatusLoaded) {
          if (state.uploadSuccessMessage != null && state.uploadSuccessMessage!.isNotEmpty) {
            context.showSuccessNotification(state.uploadSuccessMessage!);
          }
          if (state.uploadError != null && state.uploadError!.isNotEmpty) {
            context.showErrorNotification(state.uploadError!);
          }
        } else if (state is StatusFailure) {
          context.showErrorNotification(state.errorMessage);
        }
      },
      builder: (context, state) {
        final isLoading = state is StatusLoading || state is StatusInitial;
        final isUploading = state is StatusLoaded && state.isUploading;
        final uploadProgress = state is StatusLoaded ? state.uploadProgress : null;
        final percentInt = uploadProgress != null ? (uploadProgress * 100).clamp(0, 100).toInt() : null;
        final percentText = percentInt != null ? '$percentInt%' : null;
        final uploadStatusMessage = state is StatusLoaded ? state.uploadStatusMessage : null;
        final recentStatuses = state is StatusLoaded ? state.recentUpdates : <StatusContactModel>[];
        final mutedStatuses = state is StatusLoaded ? state.mutedUpdates : <StatusContactModel>[];
        final myStatuses = state is StatusLoaded ? state.myStatuses : <StatusItemModel>[];
        final myStatusBytes = state is StatusLoaded ? state.myStatusBytes : null;
        final myStatusPath = state is StatusLoaded ? state.myStatusPath : null;
        final myStatusText = state is StatusLoaded ? state.myStatusText : null;
        final myStatusTime = state is StatusLoaded ? state.myStatusTime : null;

        final hasMyStatus = myStatuses.isNotEmpty || myStatusBytes != null || myStatusPath != null || myStatusText != null;

        String myStatusSubtitle = 'Tap to add photo, video or text';
        if (isUploading) {
          if (percentText != null) {
            myStatusSubtitle = '$percentText • ${uploadStatusMessage ?? 'Sending status update...'}';
          } else {
            myStatusSubtitle = uploadStatusMessage ?? 'Sending status update...';
          }
        } else if (myStatuses.isNotEmpty) {
          myStatusSubtitle = _formatTime(myStatuses.last.timestamp);
        } else if (myStatusTime != null) {
          myStatusSubtitle = _formatTime(myStatusTime);
        }

        final unviewedRecent = recentStatuses.where((c) => !c.allViewed).toList();
        final viewedRecent = recentStatuses.where((c) => c.allViewed).toList();
        final isDark = context.colors.isDark;

        return Scaffold(
          backgroundColor: context.colors.scaffoldBackground,
          body: RefreshIndicator(
            onRefresh: () async {
              context.read<StatusBloc>().add(const LoadStatusUpdatesEvent());
            },
            child: CustomScrollView(
              slivers: [
                // App Bar
                SliverAppBar(
                  floating: true,
                  backgroundColor: context.colors.scaffoldBackground,
                  elevation: 0,
                  title: Text(
                    'Status',
                    style: context.h2.copyWith(
                      fontWeight: FontWeight.bold,
                      color: context.colors.textPrimary,
                    ),
                  ),
                  actions: [
                    Container(
                      width: 36,
                      height: 36,
                      margin: const EdgeInsets.only(right: 6),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFE8F5E9),
                        border: Border.all(
                          color: const Color(0xFF00873C).withValues(alpha: 0.3),
                        ),
                      ),
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        icon: const Icon(Icons.add_rounded, color: Color(0xFF00873C), size: 20),
                        tooltip: 'Add Status',
                        onPressed: () => _showUploadOptions(context),
                      ),
                    ),
                    PopupMenuButton<String>(
                      icon: Icon(Icons.more_vert, color: context.colors.textPrimary, size: 24),
                      color: context.colors.scaffoldBackground,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      onSelected: (value) {
                        if (value == 'privacy' || value == 'settings') {
                          _showSettingsMenu(context);
                        }
                      },
                      itemBuilder: (_) => [
                        PopupMenuItem(
                          value: 'privacy',
                          child: Row(
                            children: [
                              Icon(Icons.privacy_tip_outlined, color: context.colors.textPrimary, size: 20),
                              const SizedBox(width: CommonSizes.p12),
                              Text('Status Privacy', style: TextStyle(color: context.colors.textPrimary)),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'settings',
                          child: Row(
                            children: [
                              Icon(Icons.settings, color: context.colors.textPrimary, size: 20),
                              const SizedBox(width: CommonSizes.p12),
                              Text('Settings', style: TextStyle(color: context.colors.textPrimary)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                // My Status Section
                SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(left: 20, bottom: 4, top: 12),
                        child: Text(
                          'My Status',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF00873C),
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () => _viewMyStatus(context, myStatuses, myStatusBytes, myStatusPath, myStatusText),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Row(
                            children: [
                              GestureDetector(
                                onTap: () => _viewMyStatus(context, myStatuses, myStatusBytes, myStatusPath, myStatusText),
                                child: _buildMyStatusAvatar(
                                  context: context,
                                  hasStatus: hasMyStatus,
                                  count: myStatuses.isNotEmpty ? myStatuses.length : (hasMyStatus ? 1 : 0),
                                  myStatuses: myStatuses,
                                  myStatusBytes: myStatusBytes,
                                  myStatusPath: myStatusPath,
                                  myStatusText: myStatusText,
                                  isUploading: isUploading,
                                  uploadProgress: uploadProgress,
                                  percentInt: percentInt,
                                  isDark: isDark,
                                ),
                              ),
                              // Vertical Line between avatar and text
                              Container(
                                width: 1,
                                height: 38,
                                margin: const EdgeInsets.symmetric(horizontal: 14),
                                color: context.colors.border.withValues(alpha: isDark ? 0.35 : 0.5),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      isUploading
                                          ? 'Sending Status Update'
                                          : (hasMyStatus ? 'My Status' : 'Add to my status'),
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14.5,
                                        color: isUploading ? const Color(0xFF00873C) : context.colors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      myStatusSubtitle,
                                      style: TextStyle(
                                        color: isUploading ? const Color(0xFF00873C) : context.colors.textSecondary,
                                        fontSize: 12.5,
                                        fontWeight: isUploading ? FontWeight.w600 : FontWeight.normal,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE8F5E9),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: IconButton(
                                  padding: EdgeInsets.zero,
                                  icon: const Icon(
                                    Icons.add_photo_alternate_rounded,
                                    color: Color(0xFF00873C),
                                    size: 20,
                                  ),
                                  tooltip: 'Add Status',
                                  onPressed: isUploading ? null : () => _showUploadOptions(context),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Divider(
                        height: 1,
                        thickness: 0.8,
                        indent: 76,
                        endIndent: 16,
                        color: context.colors.border.withValues(alpha: isDark ? 0.15 : 0.25),
                      ),
                    ],
                  ),
                ),

                if (isLoading)
                  const SliverFillRemaining(child: Center(child: CircularProgressIndicator(color: Color(0xFF00873C))))
                else ...[
                  // Recent Updates
                  if (unviewedRecent.isNotEmpty) ...[
                    const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.only(left: 20, top: 16, bottom: 6),
                        child: Text(
                          'Recent Updates',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF00873C),
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: _buildStatusListCard(context, unviewedRecent),
                    ),
                  ],

                  // Viewed Updates
                  if (viewedRecent.isNotEmpty) ...[
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 20, top: 16, bottom: 6),
                        child: Text(
                          'Viewed Updates',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: context.colors.textHint,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: _buildStatusListCard(context, viewedRecent),
                    ),
                  ],

                  // Muted Updates
                  if (mutedStatuses.isNotEmpty) ...[
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 20, top: 16, bottom: 6),
                        child: Text(
                          'Muted Updates',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: context.colors.textHint,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: _buildStatusListCard(context, mutedStatuses, muted: true),
                    ),
                  ],
                ],
                const SliverToBoxAdapter(child: SizedBox(height: CommonSizes.p100)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusListCard(BuildContext context, List<StatusContactModel> list, {bool muted = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: list.length,
      separatorBuilder: (context, index) => Divider(
        height: 1,
        thickness: 0.8,
        indent: 76,
        endIndent: 16,
        color: context.colors.border.withValues(alpha: isDark ? 0.15 : 0.25),
      ),
      itemBuilder: (context, index) {
        return _buildStatusTile(context, list, index, muted: muted);
      },
    );
  }

  Widget _buildStatusTile(BuildContext context, List<StatusContactModel> list, int index, {bool muted = false}) {
    final contact = list[index];
    final allViewed = contact.allViewed;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: () => _viewStatus(context, list, index),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => _viewStatus(context, list, index),
              child: _buildStatusRing(
                context,
                contact.profileColor,
                allViewed,
                contact.statusCount,
                contact.name.isNotEmpty ? contact.name[0].toUpperCase() : '?',
                profilePictureUrl: contact.profilePictureUrl,
              ),
            ),
            // Vertical Line between avatar and text
            Container(
              width: 1,
              height: 38,
              margin: const EdgeInsets.symmetric(horizontal: 14),
              color: context.colors.border.withValues(alpha: isDark ? 0.35 : 0.5),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    contact.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14.5,
                      color: context.colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _formatTime(contact.statuses.last.timestamp),
                    style: TextStyle(
                      color: context.colors.textSecondary,
                      fontSize: 12.5,
                    ),
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert, color: context.colors.textHint, size: 20),
              color: context.colors.cardBackground,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'view',
                  height: 40,
                  child: Text('View Status', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w400, color: context.colors.textPrimary)),
                ),
                PopupMenuItem(
                  value: muted ? 'unmute' : 'mute',
                  height: 40,
                  child: Text(muted ? 'Unmute' : 'Mute', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w400, color: context.colors.textPrimary)),
                ),
              ],
              onSelected: (v) async {
                if (v == 'view') {
                  _viewStatus(context, list, index);
                } else if (v == 'mute') {
                  context.read<StatusBloc>().add(MuteContactEvent(contactId: contact.contactId, mute: true));
                } else if (v == 'unmute') {
                  context.read<StatusBloc>().add(MuteContactEvent(contactId: contact.contactId, mute: false));
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileFallback(String? profilePicUrl, String initial) {
    if (profilePicUrl != null && profilePicUrl.trim().isNotEmpty) {
      return Image.network(
        profilePicUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => Center(
          child: Text(
            initial,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF00873C)),
          ),
        ),
      );
    }
    return Center(
      child: Text(
        initial,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF00873C)),
      ),
    );
  }

  Widget _buildMyStatusAvatar({
    required BuildContext context,
    required bool hasStatus,
    required int count,
    required List<StatusItemModel> myStatuses,
    required Uint8List? myStatusBytes,
    required String? myStatusPath,
    required String? myStatusText,
    required bool isUploading,
    required double? uploadProgress,
    required int? percentInt,
    required bool isDark,
  }) {
    final profilePicUrl = getIt.isRegistered<StorageService>() ? getIt<StorageService>().getProfilePic() : null;
    final username = getIt.isRegistered<StorageService>() ? (getIt<StorageService>().getUsername() ?? '') : '';
    final initial = username.isNotEmpty ? username[0].toUpperCase() : 'M';

    Widget innerContent;
    if (myStatuses.isNotEmpty) {
      final lastItem = myStatuses.last;
      final path = lastItem.imagePath ?? '';
      final lower = path.toLowerCase();
      final isVid = lastItem.statusType == 'video' ||
          lower.endsWith('.mp4') ||
          lower.endsWith('.mov') ||
          lower.endsWith('.avi') ||
          lower.endsWith('.mkv');
      final isAud = lastItem.statusType == 'audio' ||
          lower.endsWith('.m4a') ||
          lower.endsWith('.mp3') ||
          lower.endsWith('.aac') ||
          lower.endsWith('.wav');

      if (isVid) {
        innerContent = Container(
          color: const Color(0xFF00873C),
          child: const Center(
            child: Icon(Icons.videocam_rounded, color: Colors.white, size: 20),
          ),
        );
      } else if (isAud) {
        innerContent = Container(
          color: lastItem.parsedBackgroundColor,
          child: const Center(
            child: Icon(Icons.graphic_eq_rounded, color: Colors.white, size: 20),
          ),
        );
      } else if (path.isNotEmpty) {
        innerContent = Image.network(
          path,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _buildProfileFallback(profilePicUrl, initial),
        );
      } else if (lastItem.text != null && lastItem.text!.isNotEmpty) {
        innerContent = Container(
          color: lastItem.parsedBackgroundColor,
          child: Center(
            child: Text(
              lastItem.text![0].toUpperCase(),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        );
      } else {
        innerContent = _buildProfileFallback(profilePicUrl, initial);
      }
    } else if (myStatusBytes != null) {
      innerContent = Image.memory(myStatusBytes, fit: BoxFit.cover);
    } else if (myStatusPath != null && !kIsWeb) {
      final lower = myStatusPath.toLowerCase();
      final isVid = lower.endsWith('.mp4') || lower.endsWith('.mov');
      if (isVid) {
        innerContent = Container(
          color: const Color(0xFF00873C),
          child: const Center(
            child: Icon(Icons.videocam_rounded, color: Colors.white, size: 20),
          ),
        );
      } else {
        innerContent = Image.file(
          File(myStatusPath),
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _buildProfileFallback(profilePicUrl, initial),
        );
      }
    } else if (myStatusText != null) {
      innerContent = Container(
        color: const Color(0xFF00873C),
        child: Center(
          child: Text(
            myStatusText.isNotEmpty ? myStatusText[0].toUpperCase() : 'T',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      );
    } else {
      innerContent = _buildProfileFallback(profilePicUrl, initial);
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        if (hasStatus)
          SizedBox(
            width: 48,
            height: 48,
            child: CustomPaint(
              painter: _StatusRingPainter(
                color: const Color(0xFF00873C),
                segmentCount: count,
                viewed: false,
              ),
              child: Center(
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFFE8F5E9),
                  ),
                  child: ClipOval(child: innerContent),
                ),
              ),
            ),
          )
        else
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFE8F5E9),
            ),
            child: ClipOval(child: innerContent),
          ),

        // Uploading Indicator Overlay
        if (isUploading)
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black54,
              ),
              child: Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 32,
                      height: 32,
                      child: CircularProgressIndicator(
                        value: uploadProgress,
                        strokeWidth: 2.8,
                        backgroundColor: Colors.white24,
                        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF48A476)),
                      ),
                    ),
                    if (percentInt != null)
                      Text(
                        '$percentInt%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),

        // Add (+) Badge when user has no status
        if (!hasStatus && !isUploading)
          Positioned(
            right: -2,
            bottom: -2,
            child: GestureDetector(
              onTap: () => _showUploadOptions(context),
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: const Color(0xFF00873C),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
                    width: 2,
                  ),
                ),
                child: const Icon(
                  Icons.add,
                  size: 12,
                  color: Colors.white,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildStatusRing(
    BuildContext context,
    Color color,
    bool viewed,
    int count,
    String initial, {
    String? profilePictureUrl,
  }) {
    final hasPic = profilePictureUrl != null && profilePictureUrl.trim().isNotEmpty;
    return SizedBox(
      width: 48,
      height: 48,
      child: CustomPaint(
        painter: _StatusRingPainter(color: viewed ? Colors.grey : color, segmentCount: count, viewed: viewed),
        child: Center(
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.15),
            ),
            child: ClipOval(
              child: hasPic
                  ? Image.network(
                      profilePictureUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Center(
                        child: Text(
                          initial,
                          style: context.titleMedium.copyWith(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                      ),
                    )
                  : Center(
                      child: Text(
                        initial,
                        style: context.titleMedium.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

// Custom painter for segmented status ring
class _StatusRingPainter extends CustomPainter {
  final Color color;
  final int segmentCount;
  final bool viewed;

  _StatusRingPainter({required this.color, required this.segmentCount, required this.viewed});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - 1.5;
    final gapAngle = segmentCount > 1 ? 0.15 : 0.0;
    final segmentAngle = (2 * pi - gapAngle * segmentCount) / segmentCount;
    const startOffset = -pi / 2;

    for (int i = 0; i < segmentCount; i++) {
      final startAngle = startOffset + i * (segmentAngle + gapAngle);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        segmentAngle,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_StatusRingPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.segmentCount != segmentCount;
}
