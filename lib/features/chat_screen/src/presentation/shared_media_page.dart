import 'package:flutter/material.dart';
import 'package:schat/features/chat_screen/src/domain/models/chat_media_model.dart';
import 'package:schat/features/chat_screen/src/domain/repositories/chat_repository.dart';
import 'package:schat/features/chat_screen/src/presentation/widgets/in_app_viewer.dart';
import 'package:schat/injection.dart';
import 'package:schat/utils/common_colors.dart';
import 'package:schat/utils/common_icons.dart';
import 'package:schat/utils/common_fontstyles.dart';
import 'package:schat/utils/common_endpoints.dart';
import 'package:schat/utils/common_notifications.dart';
import 'package:schat/utils/common_spaces.dart';

class SharedMediaPage extends StatefulWidget {
  final String conversationId;
  final List<ChatMediaModel> initialMediaList;
  final bool shouldFetch;
  final bool isReadOnly;

  const SharedMediaPage({
    super.key,
    required this.conversationId,
    required this.initialMediaList,
    this.shouldFetch = true,
    this.isReadOnly = false,
  });

  @override
  State<SharedMediaPage> createState() => _SharedMediaPageState();
}

class _SharedMediaPageState extends State<SharedMediaPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<ChatMediaModel> _mediaList = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    // Show whatever was passed immediately, then fetch all from API
    _mediaList = List.of(widget.initialMediaList);
    if (widget.shouldFetch) {
      _fetchAllMedia();
    }
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
  }

  bool _isLoading = false;

  Future<void> _fetchAllMedia() async {
    setState(() => _isLoading = true);
    try {
      final repo = getIt<ChatRepository>();
      final all = await repo.getConversationMedia(widget.conversationId);
      if (mounted) {
        setState(() {
          _mediaList = all;
          _isLoading = false;
        });
      }
    } catch (e) {
      // Keep the initial list on error
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  String _resolveUrl(String rawUrl) {
    String url = rawUrl;
    if (url.contains('minio')) {
      try {
        final serverUri = Uri.parse(CommonEndpoints.baseUrl);
        final host = serverUri.host;
        if (host.isNotEmpty) {
          url = url.replaceAll('minio', host);
        }
      } catch (_) {}
    }
    return url;
  }

  String _getThumbnailOrUrl(ChatMediaModel media) {
    if (media.thumbnails.isNotEmpty) {
      try {
        final thumb = media.thumbnails.first;
        if (thumb is Map && thumb.containsKey('url')) {
          return _resolveUrl(thumb['url'].toString());
        }
      } catch (_) {}
    }
    return _resolveUrl(media.url);
  }

  void _openMedia(ChatMediaModel media) {
    final rawUrl = media.url;
    if (rawUrl.isEmpty) {
      context.showErrorNotification('Invalid file URL');
      return;
    }
    final resolved = _resolveUrl(rawUrl);

    String fileName = media.filename.trim();
    if (fileName.isEmpty) {
      try {
        final uri = Uri.parse(resolved);
        final segment = uri.pathSegments.isNotEmpty ? uri.pathSegments.last : '';
        if (segment.isNotEmpty) {
          fileName = Uri.decodeComponent(segment);
        }
      } catch (_) {}
    }
    if (fileName.isEmpty) {
      fileName = 'Shared Media';
    }

    final typeUpper = media.mediaType.toUpperCase();
    final mimeLower = media.mimeType.toLowerCase();
    final nameLower = fileName.toLowerCase();
    final urlLower = resolved.toLowerCase();

    String type = 'file';
    if (typeUpper.contains('IMAGE') ||
        mimeLower.startsWith('image/') ||
        ['.png', '.jpg', '.jpeg', '.gif', '.webp', '.bmp', '.svg', '.heic']
            .any((ext) => nameLower.endsWith(ext) || urlLower.contains(ext))) {
      type = 'image';
    } else if (typeUpper.contains('VIDEO') ||
        mimeLower.startsWith('video/') ||
        ['.mp4', '.mov', '.avi', '.mkv', '.webm', '.3gp']
            .any((ext) => nameLower.endsWith(ext) || urlLower.contains(ext))) {
      type = 'video';
    } else if (typeUpper.contains('VOICE') ||
        typeUpper.contains('AUDIO') ||
        mimeLower.startsWith('audio/') ||
        ['.mp3', '.wav', '.aac', '.m4a', '.ogg', '.opus']
            .any((ext) => nameLower.endsWith(ext) || urlLower.contains(ext))) {
      type = 'audio';
    } else if (mimeLower.contains('pdf') || nameLower.endsWith('.pdf') || urlLower.contains('.pdf')) {
      type = 'pdf';
    }

    InAppViewer.show(
      context,
      url: resolved,
      fileName: fileName,
      type: type,
      mediaId: media.id.isNotEmpty ? media.id : null,
      allowShare: false,
      allowDownload: false,
      isReadOnly: true,
    );
  }

  String _formatBytes(int bytes) {
    if (bytes <= 0) return "0 B";
    const suffixes = ["B", "KB", "MB", "GB"];
    var i = 0;
    double w = bytes.toDouble();
    while (w >= 1024 && i < suffixes.length - 1) {
      w /= 1024;
      i++;
    }
    return "${w.toStringAsFixed(1)} ${suffixes[i]}";
  }

  String _formatDate(String dateStr) {
    try {
      DateTime date;
      final parsedInt = int.tryParse(dateStr);
      if (parsedInt != null) {
        if (dateStr.length <= 10) {
          date = DateTime.fromMillisecondsSinceEpoch(parsedInt * 1000).toLocal();
        } else {
          date = DateTime.fromMillisecondsSinceEpoch(parsedInt).toLocal();
        }
      } else {
        date = DateTime.parse(dateStr).toLocal();
      }
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${months[date.month - 1]} ${date.day}, ${date.year}';
    } catch (_) {
      return dateStr;
    }
  }

  List<ChatMediaModel> _getFilteredList(String tabType) {
    return _mediaList.where((item) {
      // Filter by Search Query
      if (_searchQuery.isNotEmpty && !item.filename.toLowerCase().contains(_searchQuery)) {
        return false;
      }

      final typeUpper = item.mediaType.toUpperCase();
      final mimeLower = item.mimeType.toLowerCase();

      final isImage = typeUpper.contains('IMAGE') || mimeLower.startsWith('image/');
      final isVideo = typeUpper.contains('VIDEO') || mimeLower.startsWith('video/');
      final isAudio = typeUpper.contains('VOICE') || typeUpper.contains('AUDIO') || mimeLower.startsWith('audio/');

      if (tabType == 'media') {
        return isImage || isVideo;
      } else if (tabType == 'docs') {
        return !isImage && !isVideo && !isAudio;
      } else if (tabType == 'audio') {
        return isAudio;
      }
      return false;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: context.colors.scaffoldBackground,
        elevation: 0,
        iconTheme: IconThemeData(color: context.colors.textPrimary),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Shared Media',
              style: context.titleLarge.copyWith(fontWeight: FontWeight.bold),
            ),
            if (!_isLoading && _mediaList.isNotEmpty)
              Text(
                '${_mediaList.length} item${_mediaList.length == 1 ? '' : 's'}',
                style: context.bodySmall.copyWith(color: context.colors.textHint),
              ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(_isLoading ? 114.0 : 110.0),
          child: Column(
            children: [
              // Slim loading bar at top when fetching from server
              if (_isLoading)
                LinearProgressIndicator(
                  minHeight: 2,
                  color: context.colors.primary,
                  backgroundColor: context.colors.primary.withValues(alpha: 0.1),
                ),
              // Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: context.colors.searchBackground,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: context.colors.border.withValues(alpha: 0.5)),
                  ),
                  child: TextField(
                    controller: _searchController,
                    style: context.bodyMedium.copyWith(color: context.colors.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Search shared files...',
                      hintStyle: context.bodyMedium.copyWith(color: context.colors.textHint),
                      border: InputBorder.none,
                      icon: Icon(CommonIcons.search, color: context.colors.textHint, size: 20),
                    ),
                  ),
                ),
              ),
              // TabBar
              TabBar(
                controller: _tabController,
                indicatorColor: context.colors.primary,
                labelColor: context.colors.primary,
                unselectedLabelColor: context.colors.textHint,
                tabs: const [
                  Tab(text: 'Media'),
                  Tab(text: 'Docs'),
                  Tab(text: 'Audio'),
                ],
              ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildMediaTab(),
                _buildDocsTab(),
                _buildAudioTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaTab() {
    final list = _getFilteredList('media');
    if (list.isEmpty) {
      return _buildEmptyState('No shared media found');
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final item = list[index];
        final nameLower = item.filename.toLowerCase();
        final urlLower = item.url.toLowerCase();
        final isVideo = item.mediaType.toUpperCase().contains('VIDEO') ||
            item.mimeType.toLowerCase().startsWith('video/') ||
            ['.mp4', '.mov', '.avi', '.mkv', '.webm', '.3gp'].any((ext) => nameLower.endsWith(ext) || urlLower.contains(ext));

        return GestureDetector(
          onTap: () => _openMedia(item),
          child: Stack(
            fit: StackFit.expand,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  _getThumbnailOrUrl(item),
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: context.colors.lightBackground,
                    child: Center(
                      child: Icon(CommonIcons.brokenImage, color: context.colors.textHint),
                    ),
                  ),
                ),
              ),
              if (isVideo)
                Positioned(
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: context.colors.pureBlack.withValues(alpha: 0.45),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(CommonIcons.playCircle, color: context.colors.pureWhite, size: 28),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDocsTab() {
    final list = _getFilteredList('docs');
    if (list.isEmpty) {
      return _buildEmptyState('No shared documents found');
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      separatorBuilder: (context, index) => Divider(color: context.colors.border.withValues(alpha: 0.3)),
      itemBuilder: (context, index) {
        final item = list[index];
        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: context.colors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(CommonIcons.document, color: context.colors.primary),
          ),
          title: Text(
            item.filename,
            style: context.titleSmall.copyWith(fontWeight: FontWeight.w600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            '${_formatBytes(item.fileSizeBytes)} • ${_formatDate(item.createdAt)}',
            style: context.bodySmall.copyWith(color: context.colors.textSecondary),
          ),
          trailing: Icon(CommonIcons.arrowForward, color: context.colors.textHint, size: 18),
          onTap: () => _openMedia(item),
        );
      },
    );
  }

  Widget _buildAudioTab() {
    final list = _getFilteredList('audio');
    if (list.isEmpty) {
      return _buildEmptyState('No shared audio found');
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      separatorBuilder: (context, index) => Divider(color: context.colors.border.withValues(alpha: 0.3)),
      itemBuilder: (context, index) {
        final item = list[index];
        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: context.colors.secondary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(CommonIcons.audio, color: context.colors.secondary),
          ),
          title: Text(
            item.filename,
            style: context.titleSmall.copyWith(fontWeight: FontWeight.w600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            '${_formatBytes(item.fileSizeBytes)} • ${_formatDate(item.createdAt)}',
            style: context.bodySmall.copyWith(color: context.colors.textSecondary),
          ),
          trailing: Icon(CommonIcons.arrowForward, color: context.colors.textHint, size: 18),
          onTap: () => _openMedia(item),
        );
      },
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(CommonIcons.gallery, size: 64, color: context.colors.textHint.withValues(alpha: 0.4)),
          CommonSpaces.h12,
          Text(
            message,
            style: context.bodyMedium.copyWith(color: context.colors.textSecondary),
          ),
        ],
      ),
    );
  }
}
