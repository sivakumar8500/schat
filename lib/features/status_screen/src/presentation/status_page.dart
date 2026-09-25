import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:schat/features/status_screen/src/domain/status_model.dart';
import 'package:schat/features/status_screen/src/presentation/bloc/status_bloc.dart';
import 'package:schat/features/status_screen/src/presentation/bloc/status_event.dart';
import 'package:schat/features/status_screen/src/presentation/bloc/status_state.dart';
import 'package:schat/features/status_screen/src/presentation/widgets/status_privacy_sheet.dart';
import 'package:schat/features/status_screen/src/presentation/widgets/text_status_creator_page.dart';
import 'package:schat/features/status_screen/src/presentation/status_view_page.dart';
import 'package:schat/utils/common_colors.dart';
import 'package:schat/utils/common_fontstyles.dart';
import 'package:schat/utils/common_notifications.dart';
import 'package:schat/utils/common_sizes.dart';

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


  void _showStatusTextDialog(BuildContext context, {Uint8List? bytes, String? path}) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: ctx.colors.cardBackground,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Add Caption', style: TextStyle(color: ctx.colors.textPrimary)),
          content: TextField(
            controller: controller,
            style: TextStyle(color: ctx.colors.textPrimary),
            decoration: InputDecoration(
              hintText: 'Add a caption... (optional)',
              hintStyle: TextStyle(color: ctx.colors.textHint),
              filled: true,
              fillColor: ctx.colors.scaffoldBackground,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                context.showInfoNotification('Uploading status...');
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
                context.showInfoNotification('Uploading status...');
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

              // 1. Photo / Video
              _buildUploadOptionRow(
                context: ctx,
                icon: Icons.image_outlined,
                title: 'Photo / Video',
                onTap: () {
                  Navigator.pop(ctx);
                  _pickStatusImage(context);
                },
              ),
              Divider(height: 1, color: colors.textHint.withValues(alpha: 0.08)),

              // 2. Text Status
              _buildUploadOptionRow(
                context: ctx,
                icon: Icons.title,
                title: 'Text Status',
                onTap: () {
                  Navigator.pop(ctx);
                  _addTextStatus(context);
                },
              ),
              Divider(height: 1, color: colors.textHint.withValues(alpha: 0.08)),

              // 3. Camera
              _buildUploadOptionRow(
                context: ctx,
                icon: Icons.camera_alt_outlined,
                title: 'Camera',
                onTap: () {
                  Navigator.pop(ctx);
                  _pickStatusCamera(context);
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
    required VoidCallback onTap,
  }) {
    final colors = context.colors;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                icon,
                color: const Color(0xFF00873C),
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: colors.textHint,
              size: 22,
            ),
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
    return BlocBuilder<StatusBloc, StatusState>(
      builder: (context, state) {
        final isLoading = state is StatusLoading || state is StatusInitial;
        final recentStatuses = state is StatusLoaded ? state.recentUpdates : <StatusContactModel>[];
        final mutedStatuses = state is StatusLoaded ? state.mutedUpdates : <StatusContactModel>[];
        final myStatuses = state is StatusLoaded ? state.myStatuses : <StatusItemModel>[];
        final myStatusBytes = state is StatusLoaded ? state.myStatusBytes : null;
        final myStatusPath = state is StatusLoaded ? state.myStatusPath : null;
        final myStatusText = state is StatusLoaded ? state.myStatusText : null;
        final myStatusTime = state is StatusLoaded ? state.myStatusTime : null;

        final hasMyStatus = myStatuses.isNotEmpty || myStatusBytes != null || myStatusPath != null || myStatusText != null;

        String myStatusSubtitle = 'Tap to add photo, video or text';
        if (myStatuses.isNotEmpty) {
          myStatusSubtitle = _formatTime(myStatuses.last.timestamp);
        } else if (myStatusTime != null) {
          myStatusSubtitle = _formatTime(myStatusTime);
        }

        final unviewedRecent = recentStatuses.where((c) => !c.allViewed).toList();
        final viewedRecent = recentStatuses.where((c) => c.allViewed).toList();
        final isDark = context.colors.isDark;

        return Scaffold(
          backgroundColor: Colors.transparent,
          body: RefreshIndicator(
            onRefresh: () async {
              context.read<StatusBloc>().add(const LoadStatusUpdatesEvent());
            },
            child: CustomScrollView(
              slivers: [
                // App Bar
                SliverAppBar(
                  floating: true,
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  title: Text(
                    'Status',
                    style: context.h2.copyWith(
                      fontWeight: FontWeight.bold,
                      color: context.colors.textPrimary,
                    ),
                  ),
                  actions: [
                    IconButton(
                      icon: Icon(Icons.search, color: context.colors.textPrimary, size: 24),
                      onPressed: () {},
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
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(left: 4, bottom: 8, top: 4),
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
                        Container(
                          decoration: BoxDecoration(
                            color: isDark ? context.colors.cardBackground : Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: context.colors.border.withValues(alpha: 0.35),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            leading: GestureDetector(
                              onTap: () => _viewMyStatus(context, myStatuses, myStatusBytes, myStatusPath, myStatusText),
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  Container(
                                    width: 52,
                                    height: 52,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: const Color(0xFFE8F5E9),
                                      border: hasMyStatus
                                          ? Border.all(color: const Color(0xFF00873C), width: 2.5)
                                          : null,
                                    ),
                                    child: ClipOval(
                                      child: myStatuses.isNotEmpty
                                          ? (myStatuses.last.imagePath != null && myStatuses.last.imagePath!.isNotEmpty
                                              ? Image.network(
                                                  myStatuses.last.imagePath!,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (_, _, _) => const Icon(
                                                    Icons.person,
                                                    color: Color(0xFF48A476),
                                                    size: 30,
                                                  ),
                                                )
                                              : Container(
                                                  color: myStatuses.last.parsedBackgroundColor,
                                                  child: Center(
                                                    child: Text(
                                                      myStatuses.last.text != null && myStatuses.last.text!.isNotEmpty
                                                          ? myStatuses.last.text![0].toUpperCase()
                                                          : 'T',
                                                      style: TextStyle(
                                                        fontSize: 22,
                                                        fontWeight: FontWeight.bold,
                                                        color: context.colors.textLight,
                                                      ),
                                                    ),
                                                  ),
                                                ))
                                          : hasMyStatus && myStatusBytes != null
                                              ? Image.memory(myStatusBytes, fit: BoxFit.cover)
                                              : hasMyStatus && myStatusPath != null && !kIsWeb
                                                  ? Image.asset(
                                                      myStatusPath,
                                                      fit: BoxFit.cover,
                                                      errorBuilder: (_, _, _) => const Icon(
                                                        Icons.person,
                                                        color: Color(0xFF48A476),
                                                        size: 30,
                                                      ),
                                                    )
                                                  : hasMyStatus && myStatusText != null
                                                      ? Container(
                                                          color: const Color(0xFF00873C),
                                                          child: Center(
                                                            child: Text(
                                                              'T',
                                                              style: TextStyle(
                                                                fontSize: 22,
                                                                fontWeight: FontWeight.bold,
                                                                color: context.colors.textLight,
                                                              ),
                                                            ),
                                                          ),
                                                        )
                                                      : const Icon(
                                                          Icons.person,
                                                          color: Color(0xFF48A476),
                                                          size: 30,
                                                        ),
                                    ),
                                  ),
                                  Positioned(
                                    right: -2,
                                    bottom: -2,
                                    child: GestureDetector(
                                      onTap: () => _showUploadOptions(context),
                                      child: Container(
                                        width: 22,
                                        height: 22,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF00873C),
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: Colors.white,
                                            width: 2,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.add,
                                          size: 13,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            title: Text(
                              hasMyStatus ? 'My Status' : 'Add to my status',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                color: context.colors.textPrimary,
                              ),
                            ),
                            subtitle: Text(
                              myStatusSubtitle,
                              style: TextStyle(
                                color: context.colors.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                            trailing: Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: const Color(0xFFE8F5E9),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: IconButton(
                                padding: EdgeInsets.zero,
                                icon: const Icon(
                                  Icons.camera_alt_outlined,
                                  color: Color(0xFF00873C),
                                  size: 20,
                                ),
                                onPressed: () => _showUploadOptions(context),
                              ),
                            ),
                            onTap: () => _viewMyStatus(context, myStatuses, myStatusBytes, myStatusPath, myStatusText),
                          ),
                        ),
                      ],
                    ),
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
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          return _buildStatusTile(context, unviewedRecent, index);
                        }, childCount: unviewedRecent.length),
                      ),
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
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          return _buildStatusTile(context, viewedRecent, index);
                        }, childCount: viewedRecent.length),
                      ),
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
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          return _buildStatusTile(context, mutedStatuses, index, muted: true);
                        }, childCount: mutedStatuses.length),
                      ),
                    ),
                  ],
                ],
                const SliverToBoxAdapter(child: SizedBox(height: CommonSizes.p100)),
              ],
            ),
          ),
          // FAB to add status
          floatingActionButton: FloatingActionButton.extended(
            heroTag: 'status_fab',
            onPressed: () => _showUploadOptions(context),
            backgroundColor: const Color(0xFF00873C),
            foregroundColor: Colors.white,
            elevation: 4,
            icon: const Icon(Icons.camera_alt_rounded, size: 20),
            label: const Text('Add Status', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        );
      },
    );
  }

  Widget _buildStatusTile(BuildContext context, List<StatusContactModel> list, int index, {bool muted = false}) {
    final contact = list[index];
    final allViewed = contact.allViewed;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isDark ? context.colors.cardBackground : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: context.colors.border.withValues(alpha: 0.35),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: GestureDetector(
          onTap: () => _viewStatus(context, list, index),
          child: _buildStatusRing(context, contact.profileColor, allViewed, contact.statusCount, contact.name[0]),
        ),
        title: Text(
          contact.name,
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: context.colors.textPrimary),
        ),
        subtitle: Text(
          _formatTime(contact.statuses.last.timestamp),
          style: TextStyle(color: context.colors.textSecondary, fontSize: 13),
        ),
        trailing: PopupMenuButton<String>(
          icon: Icon(Icons.more_vert, color: context.colors.textHint, size: 20),
          color: context.colors.cardBackground,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
      ),
    );
  }

  Widget _buildStatusRing(BuildContext context, Color color, bool viewed, int count, String initial) {
    return SizedBox(
      width: 56,
      height: 56,
      child: CustomPaint(
        painter: _StatusRingPainter(color: viewed ? Colors.grey : color, segmentCount: count, viewed: viewed),
        child: Center(
          child: Container(
            width: 48,
            height: 48,
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
