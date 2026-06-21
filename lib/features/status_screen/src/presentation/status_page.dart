import 'package:schat/utils/common_fontstyles.dart';
import 'package:schat/utils/common_sizes.dart';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:schat/utils/common_colors.dart';
import 'package:schat/utils/common_spaces.dart';
import 'package:schat/features/status_screen/src/domain/status_model.dart';
import 'package:schat/features/status_screen/src/presentation/status_view_page.dart';
import 'package:schat/features/status_screen/src/presentation/bloc/status_bloc.dart';
import 'package:schat/features/status_screen/src/presentation/bloc/status_event.dart';
import 'package:schat/features/status_screen/src/presentation/bloc/status_state.dart';
import 'package:schat/utils/common_notifications.dart';

class StatusPage extends StatelessWidget {
  const StatusPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<StatusBloc>(
      create: (context) => StatusBloc()..add(const LoadStatusUpdatesEvent()),
      child: const StatusPageContent(),
    );
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
      _showStatusTextDialog(context, bytes: bytes, path: path);
    }
  }

  Future<void> _addTextStatus(BuildContext context) async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ctx.colors.scaffoldBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Text Status', style: TextStyle(color: ctx.colors.textPrimary, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          maxLines: 3,
          maxLength: 140,
          style: TextStyle(color: ctx.colors.textPrimary),
          decoration: InputDecoration(
            hintText: "What's on your mind?",
            hintStyle: TextStyle(color: ctx.colors.textHint),
            filled: true,
            fillColor: ctx.colors.lightBackground,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: ctx.colors.textHint)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            style: ElevatedButton.styleFrom(
              backgroundColor: ctx.colors.primary,
              foregroundColor: ctx.colors.textLight,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Post'),
          ),
        ],
      ),
    );

    if (result != null && result.trim().isNotEmpty && context.mounted) {
      context.read<StatusBloc>().add(UploadTextStatusEvent(text: result.trim()));
    }
  }

  void _showStatusTextDialog(BuildContext context, {Uint8List? bytes, String? path}) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: ctx.colors.scaffoldBackground,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Add Caption', style: TextStyle(color: ctx.colors.textPrimary)),
          content: TextField(
            controller: controller,
            style: TextStyle(color: ctx.colors.textPrimary),
            decoration: InputDecoration(
              hintText: 'Add a caption... (optional)',
              hintStyle: TextStyle(color: ctx.colors.textHint),
              filled: true,
              fillColor: ctx.colors.lightBackground,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                context.read<StatusBloc>().add(UploadMediaStatusEvent(
                  path: path,
                  bytes: bytes,
                  caption: null,
                ));
              },
              child: Text('Skip', style: TextStyle(color: ctx.colors.textHint)),
            ),
            ElevatedButton(
              onPressed: () {
                final caption = controller.text.trim();
                Navigator.pop(ctx);
                context.read<StatusBloc>().add(UploadMediaStatusEvent(
                  path: path,
                  bytes: bytes,
                  caption: caption.isNotEmpty ? caption : null,
                ));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: ctx.colors.primary,
                foregroundColor: ctx.colors.textLight,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Post'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _pickStatusCamera(BuildContext context) async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.camera, imageQuality: 85);
    if (image == null) return;

    final bytes = kIsWeb ? await image.readAsBytes() : null;
    final path = kIsWeb ? null : image.path;

    if (context.mounted) {
      _showStatusTextDialog(context, bytes: bytes, path: path);
    }
  }

  void _showUploadOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: ctx.colors.scaffoldBackground,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(color: ctx.colors.textHint.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(2)),
              ),
              Text('Add Status', style: ctx.titleMedium),
              CommonSpaces.h20,
              _uploadOptionTile(ctx, Icons.photo_library, context.colors.optionGallery, 'Photo / Video', () {
                Navigator.pop(ctx);
                _pickStatusImage(context);
              }),
              _uploadOptionTile(ctx, Icons.text_fields, context.colors.optionText, 'Text Status', () {
                Navigator.pop(ctx);
                _addTextStatus(context);
              }),
              _uploadOptionTile(ctx, Icons.camera_alt, context.colors.optionVideo, 'Camera', () {
                Navigator.pop(ctx);
                _pickStatusCamera(context);
              }),
              CommonSpaces.h8,
            ],
          ),
        ),
      ),
    );
  }

  Widget _uploadOptionTile(BuildContext ctx, IconData icon, Color color, String label, VoidCallback onTap) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(radius: 24, backgroundColor: color.withValues(alpha: 0.15), child: Icon(icon, color: color)),
      title: Text(label, style: TextStyle(color: ctx.colors.textPrimary, fontWeight: FontWeight.w600)),
      onTap: onTap,
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

  void _viewMyStatus(BuildContext context, Uint8List? bytes, String? path, String? text) {
    if (bytes == null && path == null && text == null) {
      _showUploadOptions(context);
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StatusViewPage(
          contacts: const [],
          isMyStatus: true,
          myBytes: bytes,
          myPath: path,
          myText: text,
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hr ago';
    return 'Yesterday';
  }

  void _showSettingsMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: ctx.colors.scaffoldBackground,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(color: ctx.colors.textHint.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(2))),
            _menuTile(ctx, Icons.privacy_tip_outlined, 'Status Privacy', () => _showComingSoon(context)),
            _menuTile(ctx, Icons.block, 'Blocked Contacts', () => _showComingSoon(context)),
            _menuTile(ctx, Icons.delete_outline, 'Delete My Status', () {
              Navigator.pop(ctx);
              context.read<StatusBloc>().add(const DeleteMyStatusEvent());
              context.showErrorNotification('Status deleted');
            }),
            _menuTile(ctx, Icons.help_outline, 'Help', () => _showComingSoon(context)),
            CommonSpaces.h8,
          ],
        ),
      ),
    );
  }

  void _showComingSoon(BuildContext context) {
    Navigator.pop(context);
    context.showInfoNotification('Feature coming soon');
  }

  Widget _menuTile(BuildContext ctx, IconData icon, String label, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: ctx.colors.textPrimary),
      title: Text(label, style: TextStyle(color: ctx.colors.textPrimary, fontWeight: FontWeight.w500)),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<StatusBloc, StatusState>(
      builder: (context, state) {
        if (state is StatusFailure) {
          return const SizedBox.shrink();
        }
        final isLoading = state is StatusLoading || state is StatusInitial;
        final recentStatuses = state is StatusLoaded ? state.recentUpdates : <StatusContactModel>[];
        final mutedStatuses = state is StatusLoaded ? state.mutedUpdates : <StatusContactModel>[];
        
        final myStatusBytes = state is StatusLoaded ? state.myStatusBytes : null;
        final myStatusPath = state is StatusLoaded ? state.myStatusPath : null;
        final myStatusText = state is StatusLoaded ? state.myStatusText : null;
        final myStatusTime = state is StatusLoaded ? state.myStatusTime : null;
        
        final hasMyStatus = myStatusBytes != null || myStatusPath != null || myStatusText != null;

        final unviewedRecent = recentStatuses.where((c) => !c.allViewed).toList();
        final viewedRecent = recentStatuses.where((c) => c.allViewed).toList();

        return Scaffold(
          backgroundColor: context.colors.scaffoldBackground,
          body: CustomScrollView(
            slivers: [
              // App Bar
              SliverAppBar(
                floating: true,
                backgroundColor: context.colors.scaffoldBackground,
                elevation: 0,
                title: Text(
                  'Status',
                  style: context.h2,
                ),
                actions: [
                  IconButton(
                    icon: Icon(Icons.search, color: context.colors.textPrimary),
                    onPressed: () {},
                  ),
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert, color: context.colors.textPrimary),
                    color: context.colors.scaffoldBackground,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    onSelected: (value) {
                      if (value == 'settings') _showSettingsMenu(context);
                    },
                    itemBuilder: (_) => [
                      PopupMenuItem(
                        value: 'settings',
                        child: Row(children: [
                          Icon(Icons.settings, color: context.colors.textPrimary, size: 20),
                          const SizedBox(width: CommonSizes.p12),
                          Text('Settings', style: TextStyle(color: context.colors.textPrimary)),
                        ]),
                      ),
                    ],
                  ),
                ],
              ),

              // My Status
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 24, top: 8, bottom: 4),
                      child: Text('My Status',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold,
                            color: context.colors.textHint, letterSpacing: 0.5)),
                    ),
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                      leading: GestureDetector(
                        onTap: () => _viewMyStatus(context, myStatusBytes, myStatusPath, myStatusText),
                        child: Stack(
                          children: [
                            Container(
                              width: 56, height: 56,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: hasMyStatus
                                    ? Border.all(color: context.colors.primary, width: 2.5)
                                    : null,
                                color: context.colors.lightBackground,
                              ),
                              child: ClipOval(
                                child: hasMyStatus && myStatusBytes != null
                                    ? Image.memory(myStatusBytes, fit: BoxFit.cover)
                                    : hasMyStatus && myStatusPath != null && !kIsWeb
                                        ? Image.asset(myStatusPath, fit: BoxFit.cover,
                                            errorBuilder: (_, _, _) => Icon(Icons.person, color: context.colors.textHint, size: 30))
                                        : hasMyStatus && myStatusText != null
                                            ? Container(
                                                color: context.colors.primary,
                                                child: Center(
                                                  child: Text('T',
                                                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: context.colors.textLight)),
                                                ))
                                            : Icon(Icons.person, color: context.colors.textHint, size: 30),
                              ),
                            ),
                            Positioned(
                              right: 0, bottom: 0,
                              child: GestureDetector(
                                onTap: () => _showUploadOptions(context),
                                child: Container(
                                  width: 22, height: 22,
                                  decoration: BoxDecoration(
                                    color: context.colors.primary,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: context.colors.scaffoldBackground, width: 2),
                                  ),
                                  child: Icon(Icons.add, size: 14, color: context.colors.textLight),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      title: Text(
                        hasMyStatus ? 'My Status' : 'Add to my status',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: context.colors.textPrimary),
                      ),
                      subtitle: Text(
                        hasMyStatus && myStatusTime != null ? _formatTime(myStatusTime) : 'Tap to add photo, video or text',
                        style: TextStyle(color: context.colors.textSecondary, fontSize: 13),
                      ),
                      trailing: IconButton(
                        icon: Icon(Icons.add_photo_alternate_outlined, color: context.colors.primary, size: 26),
                        onPressed: () => _showUploadOptions(context),
                      ),
                      onTap: () => _viewMyStatus(context, myStatusBytes, myStatusPath, myStatusText),
                    ),
                    Divider(color: context.colors.textHint.withValues(alpha: 0.1), height: 1, indent: 24, endIndent: 24),
                  ],
                ),
              ),

              if (isLoading)
                const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
              else ...[
                // Recent Updates
                if (unviewedRecent.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 24, top: 20, bottom: 6),
                      child: Text('Recent Updates',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold,
                            color: context.colors.textHint, letterSpacing: 0.5)),
                    ),
                  ),
                  SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      return _buildStatusTile(context, unviewedRecent, index);
                    }, childCount: unviewedRecent.length),
                  ),
                ],

                // Viewed Updates
                if (viewedRecent.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 24, top: 20, bottom: 6),
                      child: Text('Viewed Updates',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold,
                            color: context.colors.textHint, letterSpacing: 0.5)),
                    ),
                  ),
                  SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      return _buildStatusTile(context, viewedRecent, index);
                    }, childCount: viewedRecent.length),
                  ),
                ],

                // Muted Updates
                if (mutedStatuses.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 24, top: 20, bottom: 6),
                      child: Text('Muted Updates',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold,
                            color: context.colors.textHint, letterSpacing: 0.5)),
                    ),
                  ),
                  SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      return _buildStatusTile(context, mutedStatuses, index, muted: true);
                    }, childCount: mutedStatuses.length),
                  ),
                ],
              ],
              const SliverToBoxAdapter(child: SizedBox(height: CommonSizes.p100)),
            ],
          ),

          // FAB to add status
          floatingActionButton: FloatingActionButton(
            heroTag: 'status_fab',
            onPressed: () => _showUploadOptions(context),
            backgroundColor: context.colors.primary,
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Icon(Icons.camera_alt, color: context.colors.textLight),
          ),
        );
      },
    );
  }

  Widget _buildStatusTile(BuildContext context, List<StatusContactModel> list, int index, {bool muted = false}) {
    final contact = list[index];
    final allViewed = contact.allViewed;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: GestureDetector(
        onTap: () => _viewStatus(context, list, index),
        child: _buildStatusRing(context, contact.profileColor, allViewed, contact.statusCount, contact.name[0]),
      ),
      title: Text(
        contact.name,
        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: context.colors.textPrimary),
      ),
      subtitle: Text(
        _formatTime(contact.statuses.last.timestamp),
        style: TextStyle(color: context.colors.textSecondary, fontSize: 13),
      ),
      trailing: PopupMenuButton<String>(
        icon: Icon(Icons.more_vert, color: context.colors.textHint, size: 20),
        color: context.colors.scaffoldBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        itemBuilder: (_) => [
          PopupMenuItem(value: 'view', child: Text('View Status', style: TextStyle(color: context.colors.textPrimary))),
          PopupMenuItem(
            value: muted ? 'unmute' : 'mute',
            child: Text(muted ? 'Unmute' : 'Mute', style: TextStyle(color: context.colors.textPrimary)),
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
      onTap: () => _viewStatus(context, list, index),
    );
  }

  Widget _buildStatusRing(BuildContext context, Color color, bool viewed, int count, String initial) {
    return SizedBox(
      width: 56, height: 56,
      child: CustomPaint(
        painter: _StatusRingPainter(color: viewed ? Colors.grey : color, segmentCount: count, viewed: viewed),
        child: Center(
          child: Container(
            width: 48, height: 48,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color.withValues(alpha: 0.15)),
            child: Center(
              child: Text(
                initial,
                style: context.titleMedium.copyWith(
                  fontSize: 20,
                  color: color,
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
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - 2;
    final gapAngle = segmentCount > 1 ? 0.15 : 0.0;
    final segmentAngle = (2 * pi - gapAngle * segmentCount) / segmentCount;
    const startOffset = -pi / 2;

    for (int i = 0; i < segmentCount; i++) {
      final startAngle = startOffset + i * (segmentAngle + gapAngle);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle, segmentAngle, false, paint,
      );
    }
  }

  @override
  bool shouldRepaint(_StatusRingPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.segmentCount != segmentCount;
}
