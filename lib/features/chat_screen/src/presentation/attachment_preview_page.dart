import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:path_provider/path_provider.dart';
import 'package:schat/utils/common_colors.dart';
import 'package:schat/utils/common_fontstyles.dart';
import 'package:schat/utils/common_icons.dart';
import 'package:schat/utils/common_spaces.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:schat/features/chat_screen/src/presentation/widgets/image_editor_crop_view.dart';
import 'package:schat/features/chat_screen/src/presentation/widgets/image_editor_filter_view.dart';
import 'package:schat/features/chat_screen/src/presentation/widgets/image_editor_doodle_view.dart';
import 'package:schat/features/chat_screen/src/presentation/widgets/view_once_icon_widget.dart';
import 'package:schat/utils/common_notifications.dart';

class AttachmentPreviewItem {
  final String? path;
  final Uint8List? bytes;
  final String name;
  final String type;
  final int size;

  AttachmentPreviewItem({
    this.path,
    this.bytes,
    required this.name,
    required this.type,
    required this.size,
  });
}

class AttachmentPreviewPage extends StatefulWidget {
  final String? path;
  final Uint8List? bytes;
  final String name;
  final String type; // 'image', 'video', 'document', 'audio', 'file', 'location'
  final int size;
  final String contactName;
  final bool initialAllowView;
  final bool initialAllowDownload;
  final bool initialAllowShare;
  final bool initialIsViewOnce;
  final int initialViewCount;
  final List<AttachmentPreviewItem>? extraItems;

  const AttachmentPreviewPage({
    super.key,
    this.path,
    this.bytes,
    required this.name,
    required this.type,
    required this.size,
    required this.contactName,
    this.initialAllowView = true,
    this.initialAllowDownload = true,
    this.initialAllowShare = true,
    this.initialIsViewOnce = false,
    this.initialViewCount = 1,
    this.extraItems,
  });

  @override
  State<AttachmentPreviewPage> createState() => _AttachmentPreviewPageState();
}

class _AttachmentPreviewPageState extends State<AttachmentPreviewPage> {
  final TextEditingController _captionController = TextEditingController();
  
  // Video Player state
  VideoPlayerController? _videoPlayerController;
  bool _isVideoPlaying = false;
  bool _isVideoInitialized = false;
  bool _videoHasError = false;
  Duration _videoPosition = Duration.zero;
  Duration _videoDuration = Duration.zero;

  // Audio Player state
  AudioPlayer? _audioPlayer;
  bool _isAudioPlaying = false;
  bool _isAudioInitialized = false;
  Duration _audioPosition = Duration.zero;
  Duration _audioDuration = Duration.zero;

  // PDF Viewer state
  String? _resolvedPdfPath;
  int _pdfPages = 0;
  int _currentPdfPage = 0;
  bool _isPdfReady = false;
  bool _pdfHasError = false;

  // Text / Code preview state
  String? _textContentPreview;

  int _selectedIndex = 0;

  String? get _activePath => widget.extraItems != null && widget.extraItems!.isNotEmpty
      ? widget.extraItems![_selectedIndex].path
      : widget.path;

  Uint8List? get _activeInitialBytes => widget.extraItems != null && widget.extraItems!.isNotEmpty
      ? widget.extraItems![_selectedIndex].bytes
      : widget.bytes;

  String get _activeName => widget.extraItems != null && widget.extraItems!.isNotEmpty
      ? widget.extraItems![_selectedIndex].name
      : widget.name;

  String get _activeType => widget.extraItems != null && widget.extraItems!.isNotEmpty
      ? widget.extraItems![_selectedIndex].type
      : widget.type;

  int get _activeSize => widget.extraItems != null && widget.extraItems!.isNotEmpty
      ? widget.extraItems![_selectedIndex].size
      : widget.size;

  // Image editing state
  Uint8List? _currentBytes;
  Uint8List? _originalBytes;
  bool _hasEdits = false;
  
  // Security & permissions state
  late bool _allowView;
  late bool _allowDownload;
  late bool _allowShare;
  bool _isViewOnce = false;

  // Temporary files to cleanup
  final List<File> _tempFilesToCleanup = [];

  @override
  void initState() {
    super.initState();
    _allowView = widget.initialAllowView;
    _allowDownload = widget.initialAllowDownload;
    _allowShare = widget.initialAllowShare;
    _isViewOnce = widget.initialIsViewOnce;

    final resolvedType = _resolveEffectiveType();

    if (resolvedType == 'image') {
      if (_activeInitialBytes != null) {
        _currentBytes = _activeInitialBytes;
        _originalBytes = _activeInitialBytes;
      }
      _initImageBytes();
    } else if (resolvedType == 'video') {
      _initVideo();
    } else if (resolvedType == 'audio') {
      _initAudio();
    } else if (resolvedType == 'pdf') {
      _initPdf();
    } else if (resolvedType == 'text') {
      _initTextPreview();
    }
  }

  void _selectItem(int index) {
    if (_selectedIndex == index || widget.extraItems == null || index >= widget.extraItems!.length) return;
    _videoPlayerController?.dispose();
    _videoPlayerController = null;
    _audioPlayer?.dispose();
    _audioPlayer = null;

    setState(() {
      _selectedIndex = index;
      _currentBytes = _activeInitialBytes;
      _originalBytes = _activeInitialBytes;
      _hasEdits = false;
      _isVideoInitialized = false;
      _isAudioInitialized = false;
      _isPdfReady = false;
    });

    final resolvedType = _resolveEffectiveType();
    if (resolvedType == 'image') {
      _initImageBytes();
    } else if (resolvedType == 'video') {
      _initVideo();
    } else if (resolvedType == 'audio') {
      _initAudio();
    } else if (resolvedType == 'pdf') {
      _initPdf();
    } else if (resolvedType == 'text') {
      _initTextPreview();
    }
  }

  String _resolveEffectiveType() {
    final explicitType = _activeType.toLowerCase();
    final nameLower = _activeName.toLowerCase();
    final ext = nameLower.contains('.') ? nameLower.split('.').last : '';

    if (explicitType == 'image' || ['png', 'jpg', 'jpeg', 'gif', 'webp', 'heic', 'bmp', 'svg'].contains(ext)) {
      return 'image';
    }
    if (explicitType == 'video' || ['mp4', 'mov', 'mkv', 'avi', '3gp', 'webm', 'flv'].contains(ext)) {
      return 'video';
    }
    if (explicitType == 'audio' || ['mp3', 'wav', 'm4a', 'aac', 'ogg', 'opus', 'flac', 'amr'].contains(ext)) {
      return 'audio';
    }
    if (ext == 'pdf') {
      return 'pdf';
    }
    if (['txt', 'csv', 'json', 'xml', 'log', 'dart', 'py', 'js', 'html', 'css', 'md', 'yaml', 'yml'].contains(ext)) {
      return 'text';
    }
    if (explicitType == 'location') {
      return 'location';
    }
    return 'document';
  }

  Future<String?> _resolveTempFilePath() async {
    if (_activePath != null && !kIsWeb && File(_activePath!).existsSync()) {
      return _activePath;
    }
    try {
      final bytes = _currentBytes ?? _activeInitialBytes;
      if (bytes != null && bytes.isNotEmpty) {
        final tempDir = await getTemporaryDirectory();
        final ext = _activeName.contains('.') ? _activeName.split('.').last : 'tmp';
        final tempFile = File('${tempDir.path}/schat_prev_${DateTime.now().millisecondsSinceEpoch}.$ext');
        await tempFile.writeAsBytes(bytes);
        _tempFilesToCleanup.add(tempFile);
        return tempFile.path;
      }
    } catch (e) {
      debugPrint('Error creating temp file for preview: $e');
    }
    return _activePath;
  }

  Future<void> _initImageBytes() async {
    if (widget.bytes != null) {
      if (mounted) {
        setState(() {
          _currentBytes = widget.bytes;
          _originalBytes = widget.bytes;
        });
      }
    } else if (widget.path != null && !kIsWeb) {
      try {
        final fileBytes = await File(widget.path!).readAsBytes();
        if (mounted) {
          setState(() {
            _currentBytes = fileBytes;
            _originalBytes = fileBytes;
          });
        }
      } catch (e) {
        debugPrint('Error reading image bytes: $e');
      }
    }
  }

  Future<void> _initVideo() async {
    try {
      final videoPath = await _resolveTempFilePath();
      if (videoPath == null) {
        if (mounted) setState(() => _videoHasError = true);
        return;
      }

      if (kIsWeb) {
        _videoPlayerController = VideoPlayerController.networkUrl(Uri.parse(videoPath));
      } else {
        _videoPlayerController = VideoPlayerController.file(File(videoPath));
      }

      await _videoPlayerController!.initialize();
      _videoPlayerController!.addListener(_onVideoPlayerUpdate);

      if (mounted) {
        setState(() {
          _isVideoInitialized = true;
          _videoDuration = _videoPlayerController!.value.duration;
        });
        _videoPlayerController!.play();
        _isVideoPlaying = true;
      }
    } catch (e) {
      debugPrint('Video player init error in AttachmentPreviewPage: $e');
      if (mounted) {
        setState(() => _videoHasError = true);
      }
    }
  }

  void _onVideoPlayerUpdate() {
    if (!mounted || _videoPlayerController == null) return;
    final val = _videoPlayerController!.value;
    final isPlaying = val.isPlaying;
    final pos = val.position;
    final dur = val.duration;

    if (isPlaying != _isVideoPlaying || (pos - _videoPosition).inMilliseconds.abs() > 300) {
      setState(() {
        _isVideoPlaying = isPlaying;
        _videoPosition = pos;
        if (dur > Duration.zero) {
          _videoDuration = dur;
        }
      });
    }
  }

  Future<void> _initAudio() async {
    try {
      final audioPath = await _resolveTempFilePath();
      if (audioPath == null) return;

      _audioPlayer = AudioPlayer();
      _audioPlayer!.onDurationChanged.listen((d) {
        if (mounted) setState(() => _audioDuration = d);
      });
      _audioPlayer!.onPositionChanged.listen((p) {
        if (mounted) setState(() => _audioPosition = p);
      });
      _audioPlayer!.onPlayerComplete.listen((_) {
        if (mounted) {
          setState(() {
            _isAudioPlaying = false;
            _audioPosition = Duration.zero;
          });
        }
      });

      if (kIsWeb) {
        await _audioPlayer!.setSource(UrlSource(audioPath));
      } else {
        await _audioPlayer!.setSource(DeviceFileSource(audioPath));
      }

      if (mounted) {
        setState(() => _isAudioInitialized = true);
      }
    } catch (e) {
      debugPrint('Audio player init error in AttachmentPreviewPage: $e');
    }
  }

  Future<void> _initPdf() async {
    try {
      final pdfPath = await _resolveTempFilePath();
      if (mounted && pdfPath != null) {
        setState(() {
          _resolvedPdfPath = pdfPath;
        });
      }
    } catch (e) {
      debugPrint('PDF init error in AttachmentPreviewPage: $e');
      if (mounted) setState(() => _pdfHasError = true);
    }
  }

  Future<void> _initTextPreview() async {
    try {
      Uint8List? bytes = _currentBytes ?? widget.bytes;
      if (bytes == null && widget.path != null && !kIsWeb && File(widget.path!).existsSync()) {
        bytes = await File(widget.path!).readAsBytes();
      }
      if (bytes != null && bytes.isNotEmpty) {
        final sampleBytes = bytes.length > 4096 ? bytes.sublist(0, 4096) : bytes;
        final decoded = utf8.decode(sampleBytes, allowMalformed: true);
        if (mounted) {
          setState(() {
            _textContentPreview = decoded;
          });
        }
      }
    } catch (e) {
      debugPrint('Text preview error in AttachmentPreviewPage: $e');
    }
  }

  @override
  void dispose() {
    _captionController.dispose();
    if (_videoPlayerController != null) {
      _videoPlayerController!.removeListener(_onVideoPlayerUpdate);
      _videoPlayerController!.dispose();
    }
    _audioPlayer?.dispose();

    for (final tempFile in _tempFilesToCleanup) {
      try {
        if (tempFile.existsSync()) {
          tempFile.deleteSync();
        }
      } catch (_) {}
    }

    super.dispose();
  }

  Future<Uint8List?> _resolveImageBytes() async {
    if (_currentBytes != null) return _currentBytes;
    if (widget.bytes != null) return widget.bytes;
    if (widget.path != null && !kIsWeb) {
      try {
        final bytes = await File(widget.path!).readAsBytes();
        if (mounted) {
          setState(() {
            _currentBytes = bytes;
            _originalBytes ??= bytes;
          });
        }
        return bytes;
      } catch (e) {
        debugPrint('Error reading file bytes: $e');
      }
    }
    return null;
  }

  Future<void> _openCrop() async {
    final bytesToCrop = await _resolveImageBytes();
    if (bytesToCrop == null || !mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => ImageEditorCropView(
          imageBytes: bytesToCrop,
          onCropped: (croppedBytes) {
            Navigator.pop(ctx);
            setState(() {
              _currentBytes = croppedBytes;
              _hasEdits = true;
            });
          },
          onCancel: () => Navigator.pop(ctx),
        ),
      ),
    );
  }

  Future<void> _openFilters() async {
    final bytesToFilter = await _resolveImageBytes();
    if (bytesToFilter == null || !mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => ImageEditorFilterView(
          imageBytes: bytesToFilter,
          onApplied: (filteredBytes) {
            Navigator.pop(ctx);
            setState(() {
              _currentBytes = filteredBytes;
              _hasEdits = true;
            });
          },
          onCancel: () => Navigator.pop(ctx),
        ),
      ),
    );
  }

  Future<void> _openDoodle() async {
    final bytesToDoodle = await _resolveImageBytes();
    if (bytesToDoodle == null || !mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => ImageEditorDoodleView(
          imageBytes: bytesToDoodle,
          onApplied: (doodledBytes) {
            Navigator.pop(ctx);
            setState(() {
              _currentBytes = doodledBytes;
              _hasEdits = true;
            });
          },
          onCancel: () => Navigator.pop(ctx),
        ),
      ),
    );
  }

  void _resetEdits() {
    if (_originalBytes != null) {
      setState(() {
        _currentBytes = _originalBytes;
        _hasEdits = false;
      });
    }
  }

  void _toggleViewOnce() {
    setState(() {
      _isViewOnce = !_isViewOnce;
      if (_isViewOnce) {
        _allowDownload = false;
        _allowShare = false;
      }
    });

    if (_isViewOnce) {
      context.showSuccessNotification('Set to View Once');
    } else {
      context.showInfoNotification('View Once disabled');
    }
  }

  void _onSend() {
    Navigator.pop(context, {
      'send': true,
      'caption': _captionController.text.trim(),
      'bytes': _currentBytes ?? _activeInitialBytes,
      'path': _activePath,
      'items': widget.extraItems,
      'allowView': _allowView,
      'allowDownload': _isViewOnce ? false : _allowDownload,
      'allowShare': _isViewOnce ? false : _allowShare,
      'isViewOnce': _isViewOnce,
      'maxViews': 1,
    });
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes;
    final seconds = d.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String _formatFileSize(int bytes) {
    if (bytes <= 0) return '0 B';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  @override
  Widget build(BuildContext context) {
    final effectiveType = _resolveEffectiveType();
    final isImage = effectiveType == 'image';

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black.withValues(alpha: 0.8),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: context.colors.pureWhite),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.name,
              style: context.titleSmall.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              _formatFileSize(widget.size),
              style: context.bodySmall.copyWith(
                color: Colors.white70,
                fontSize: 11,
              ),
            ),
          ],
        ),
        actions: [
          if (isImage && (_currentBytes != null || widget.bytes != null || widget.path != null)) ...[
            IconButton(
              icon: const Icon(Icons.crop_rotate, color: Colors.white),
              tooltip: 'Crop & Rotate',
              onPressed: _openCrop,
            ),
            IconButton(
              icon: const Icon(Icons.auto_awesome, color: Colors.white),
              tooltip: 'Filters & Effects',
              onPressed: _openFilters,
            ),
            IconButton(
              icon: const Icon(Icons.brush, color: Colors.white),
              tooltip: 'Draw & Text',
              onPressed: _openDoodle,
            ),
            if (_hasEdits)
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.amberAccent),
                tooltip: 'Reset to Original',
                onPressed: _resetEdits,
              ),
            const SizedBox(width: 4),
          ],
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: _buildPreview(effectiveType),
              ),
            ),
            _buildBottomBar(context),
          ],
        ),
      ),
    );
  }

  Widget _buildPreview(String effectiveType) {
    switch (effectiveType) {
      case 'image':
        return _buildImagePreview();
      case 'video':
        return _buildVideoPreview();
      case 'audio':
        return _buildAudioPreview();
      case 'pdf':
        return _buildPdfPreview();
      case 'location':
        return _buildLocationPreview();
      case 'text':
        return _buildTextPreview();
      case 'document':
      default:
        return _buildDocumentCardPreview();
    }
  }

  Widget _buildImagePreview() {
    if (_currentBytes != null) {
      return Image.memory(
        _currentBytes!,
        fit: BoxFit.contain,
        key: ValueKey(_currentBytes!.hashCode),
      );
    } else if (_activeInitialBytes != null) {
      return Image.memory(_activeInitialBytes!, fit: BoxFit.contain);
    } else if (_activePath != null) {
      return kIsWeb
          ? Image.network(_activePath!, fit: BoxFit.contain)
          : Image.file(File(_activePath!), fit: BoxFit.contain);
    }
    return const Center(
      child: Icon(CommonIcons.brokenImage, color: Colors.white38, size: 64),
    );
  }

  Widget _buildVideoPreview() {
    if (_videoHasError) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 56),
          CommonSpaces.h12,
          Text(
            'Unable to preview video',
            style: context.titleSmall.copyWith(color: Colors.white),
          ),
          CommonSpaces.h4,
          Text(
            widget.name,
            style: context.bodySmall.copyWith(color: Colors.white70),
          ),
        ],
      );
    }

    if (_isVideoInitialized && _videoPlayerController != null && _videoPlayerController!.value.isInitialized) {
      return Column(
        children: [
          Expanded(
            child: Center(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    if (_videoPlayerController!.value.isPlaying) {
                      _videoPlayerController!.pause();
                      _isVideoPlaying = false;
                    } else {
                      _videoPlayerController!.play();
                      _isVideoPlaying = true;
                    }
                  });
                },
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    AspectRatio(
                      aspectRatio: _videoPlayerController!.value.aspectRatio,
                      child: VideoPlayer(_videoPlayerController!),
                    ),
                    if (!_isVideoPlaying)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(CommonIcons.playCircle, color: Colors.white, size: 52),
                      ),
                  ],
                ),
              ),
            ),
          ),
          // Interactive video progress timeline
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.black.withValues(alpha: 0.5),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        _isVideoPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                      onPressed: () {
                        setState(() {
                          if (_videoPlayerController!.value.isPlaying) {
                            _videoPlayerController!.pause();
                            _isVideoPlaying = false;
                          } else {
                            _videoPlayerController!.play();
                            _isVideoPlaying = true;
                          }
                        });
                      },
                    ),
                    Text(
                      _formatDuration(_videoPosition),
                      style: context.bodySmall.copyWith(color: Colors.white70, fontWeight: FontWeight.w600),
                    ),
                    Expanded(
                      child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 3.5,
                          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                          overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                          activeTrackColor: context.colors.primary,
                          inactiveTrackColor: Colors.white24,
                          thumbColor: context.colors.primary,
                        ),
                        child: Slider(
                          value: _videoPosition.inMilliseconds
                              .clamp(0, _videoDuration.inMilliseconds > 0 ? _videoDuration.inMilliseconds : 1)
                              .toDouble(),
                          min: 0.0,
                          max: _videoDuration.inMilliseconds > 0 ? _videoDuration.inMilliseconds.toDouble() : 1.0,
                          onChanged: (val) {
                            _videoPlayerController?.seekTo(Duration(milliseconds: val.round()));
                          },
                        ),
                      ),
                    ),
                    Text(
                      _formatDuration(_videoDuration),
                      style: context.bodySmall.copyWith(color: Colors.white70, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      );
    } else {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }
  }

  Widget _buildAudioPreview() {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Glowing audio icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFF79009), Color(0xFFDC6803)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFF79009).withValues(alpha: 0.35),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Icon(Icons.music_note_rounded, color: Colors.white, size: 40),
            ),
            CommonSpaces.h16,
            Text(
              widget.name,
              style: context.titleMedium.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            CommonSpaces.h6,
            Text(
              'Audio • ${_formatFileSize(widget.size)}',
              style: context.bodySmall.copyWith(color: Colors.white60),
            ),
            CommonSpaces.h24,
            // Waveform simulation bars
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(24, (index) {
                final heightMultiplier = [
                  0.3, 0.5, 0.8, 1.0, 0.6, 0.4, 0.9, 0.7,
                  0.4, 0.8, 1.0, 0.5, 0.7, 0.9, 0.4, 0.6,
                  0.8, 0.5, 0.3, 0.7, 0.9, 0.6, 0.4, 0.3
                ][index % 24];
                final isCurrent = _audioDuration.inMilliseconds > 0 &&
                    (_audioPosition.inMilliseconds / _audioDuration.inMilliseconds) >= (index / 24);
                return Container(
                  width: 3.5,
                  height: 28 * heightMultiplier,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: isCurrent ? const Color(0xFFF79009) : Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                );
              }),
            ),
            CommonSpaces.h20,
            // Play / Pause & Time Slider
            Row(
              children: [
                GestureDetector(
                  onTap: () async {
                    if (_audioPlayer == null) return;
                    if (_isAudioPlaying) {
                      await _audioPlayer!.pause();
                      setState(() => _isAudioPlaying = false);
                    } else {
                      await _audioPlayer!.resume();
                      setState(() => _isAudioPlaying = true);
                    }
                  },
                  child: Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF79009),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFF79009).withValues(alpha: 0.4),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: _isAudioInitialized
                        ? Icon(
                            _isAudioPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: 26,
                          )
                        : const Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            ),
                          ),
                  ),
                ),
                CommonSpaces.w12,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 3.5,
                          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                          overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                          activeTrackColor: const Color(0xFFF79009),
                          inactiveTrackColor: Colors.white12,
                          thumbColor: const Color(0xFFF79009),
                        ),
                        child: Slider(
                          value: _audioPosition.inMilliseconds
                              .clamp(0, _audioDuration.inMilliseconds > 0 ? _audioDuration.inMilliseconds : 1)
                              .toDouble(),
                          min: 0.0,
                          max: _audioDuration.inMilliseconds > 0 ? _audioDuration.inMilliseconds.toDouble() : 1.0,
                          onChanged: (val) {
                            _audioPlayer?.seek(Duration(milliseconds: val.round()));
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _formatDuration(_audioPosition),
                              style: context.bodySmall.copyWith(color: Colors.white60, fontSize: 11),
                            ),
                            Text(
                              _formatDuration(_audioDuration),
                              style: context.bodySmall.copyWith(color: Colors.white60, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPdfPreview() {
    if (_resolvedPdfPath != null && !kIsWeb && !_pdfHasError) {
      return Stack(
        children: [
          PDFView(
            filePath: _resolvedPdfPath,
            enableSwipe: true,
            swipeHorizontal: false,
            autoSpacing: true,
            pageFling: true,
            pageSnap: true,
            defaultPage: 0,
            fitPolicy: FitPolicy.BOTH,
            preventLinkNavigation: false,
            onRender: (pages) {
              if (mounted) {
                setState(() {
                  _pdfPages = pages ?? 0;
                  _isPdfReady = true;
                });
              }
            },
            onError: (error) {
              debugPrint('PDFView error: $error');
              if (mounted) setState(() => _pdfHasError = true);
            },
            onPageChanged: (int? page, int? total) {
              if (mounted) {
                setState(() {
                  _currentPdfPage = page ?? 0;
                  if (total != null) _pdfPages = total;
                });
              }
            },
          ),
          // Floating Page indicator badge
          if (_isPdfReady && _pdfPages > 0)
            Positioned(
              top: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.75),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white24),
                ),
                child: Text(
                  'Page ${_currentPdfPage + 1} of $_pdfPages',
                  style: context.bodySmall.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
        ],
      );
    }
    return _buildDocumentCardPreview(customType: 'PDF Document', customColor: const Color(0xFFEF4444));
  }

  Widget _buildTextPreview() {
    if (_textContentPreview != null && _textContentPreview!.isNotEmpty) {
      return Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF18181B),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF06B6D4).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'TEXT PREVIEW',
                    style: TextStyle(color: Color(0xFF06B6D4), fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
                CommonSpaces.w8,
                Expanded(
                  child: Text(
                    widget.name,
                    style: context.bodySmall.copyWith(color: Colors.white70),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const Divider(color: Colors.white12, height: 20),
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  _textContentPreview!,
                  style: const TextStyle(
                    color: Color(0xFFE4E4E7),
                    fontFamily: 'Courier',
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }
    return _buildDocumentCardPreview();
  }

  Widget _buildDocumentCardPreview({String? customType, Color? customColor}) {
    final meta = _getDocumentMetadata();
    final badgeColor = customColor ?? meta.color;
    final typeLabel = customType ?? meta.label;

    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.6),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Big colorful document icon
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [badgeColor, badgeColor.withValues(alpha: 0.7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: badgeColor.withValues(alpha: 0.35),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Icon(meta.icon, color: Colors.white, size: 44),
            ),
            CommonSpaces.h20,
            // Extension tag
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: badgeColor.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: badgeColor.withValues(alpha: 0.5), width: 1),
              ),
              child: Text(
                meta.extensionUpper,
                style: context.bodySmall.copyWith(
                  color: badgeColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                  letterSpacing: 0.8,
                ),
              ),
            ),
            CommonSpaces.h12,
            // File Name
            Text(
              _activeName,
              style: context.titleMedium.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            CommonSpaces.h8,
            // Type & Size
            Text(
              '$typeLabel • ${_formatFileSize(_activeSize)}',
              style: context.bodySmall.copyWith(color: Colors.white60),
            ),
            CommonSpaces.h20,
            // Ready to send indicator
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle_outline, color: context.colors.primary, size: 16),
                  CommonSpaces.w6,
                  Text(
                    'Ready to send securely',
                    style: context.bodySmall.copyWith(color: Colors.white70),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  _DocMetadata _getDocumentMetadata() {
    final nameLower = _activeName.toLowerCase();
    final ext = nameLower.contains('.') ? nameLower.split('.').last : 'file';

    if (ext == 'pdf') {
      return _DocMetadata(
        icon: Icons.picture_as_pdf_rounded,
        color: const Color(0xFFEF4444),
        label: 'PDF Document',
        extensionUpper: 'PDF',
      );
    }
    if (['xlsx', 'xls', 'csv'].contains(ext)) {
      return _DocMetadata(
        icon: Icons.table_chart_rounded,
        color: const Color(0xFF10B981),
        label: 'Excel Spreadsheet',
        extensionUpper: ext.toUpperCase(),
      );
    }
    if (['docx', 'doc', 'rtf', 'odt'].contains(ext)) {
      return _DocMetadata(
        icon: Icons.description_rounded,
        color: const Color(0xFF3B82F6),
        label: 'Word Document',
        extensionUpper: ext.toUpperCase(),
      );
    }
    if (['pptx', 'ppt', 'key'].contains(ext)) {
      return _DocMetadata(
        icon: Icons.slideshow_rounded,
        color: const Color(0xFFF97316),
        label: 'PowerPoint Presentation',
        extensionUpper: ext.toUpperCase(),
      );
    }
    if (['zip', 'rar', '7z', 'tar', 'gz'].contains(ext)) {
      return _DocMetadata(
        icon: Icons.folder_zip_rounded,
        color: const Color(0xFF8B5CF6),
        label: 'Compressed Archive',
        extensionUpper: ext.toUpperCase(),
      );
    }
    if (['txt', 'log', 'json', 'xml', 'md'].contains(ext)) {
      return _DocMetadata(
        icon: Icons.text_snippet_rounded,
        color: const Color(0xFF06B6D4),
        label: 'Text Document',
        extensionUpper: ext.toUpperCase(),
      );
    }
    if (['apk', 'bin', 'iso', 'exe', 'dmg'].contains(ext)) {
      return _DocMetadata(
        icon: Icons.android_rounded,
        color: const Color(0xFF22C55E),
        label: 'Application Package',
        extensionUpper: ext.toUpperCase(),
      );
    }

    return _DocMetadata(
      icon: Icons.insert_drive_file_rounded,
      color: const Color(0xFF6366F1),
      label: 'Document',
      extensionUpper: ext.isNotEmpty ? ext.toUpperCase() : 'FILE',
    );
  }

  Widget _buildLocationPreview() {
    double lat = 0.0;
    double lng = 0.0;
    if (widget.path != null && widget.path!.contains(',')) {
      final parts = widget.path!.split(',');
      if (parts.length == 2) {
        lat = double.tryParse(parts[0]) ?? 0.0;
        lng = double.tryParse(parts[1]) ?? 0.0;
      }
    }
    return SizedBox.expand(
      child: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: LatLng(lat, lng),
          zoom: 15,
        ),
        markers: {
          Marker(
            markerId: const MarkerId('preview_loc'),
            position: LatLng(lat, lng),
          ),
        },
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    final hasMultiItems = widget.extraItems != null && widget.extraItems!.length > 1;

    return Container(
      color: context.colors.scaffoldBackground,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Multi-item thumbnail strip if multiple attachments
          if (hasMultiItems)
            Container(
              height: 58,
              margin: const EdgeInsets.only(bottom: 12),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: widget.extraItems!.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final item = widget.extraItems![index];
                  final isSelected = index == _selectedIndex;
                  return GestureDetector(
                    onTap: () => _selectItem(index),
                    child: Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? context.colors.primary : Colors.white24,
                          width: isSelected ? 2.5 : 1.0,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: item.bytes != null
                            ? Image.memory(item.bytes!, fit: BoxFit.cover)
                            : (item.path != null
                                ? (kIsWeb
                                    ? Image.network(item.path!, fit: BoxFit.cover)
                                    : Image.file(File(item.path!), fit: BoxFit.cover))
                                : Center(
                                    child: Icon(
                                      Icons.insert_drive_file_rounded,
                                      color: Colors.white70,
                                      size: 24,
                                    ),
                                  )),
                      ),
                    ),
                  );
                },
              ),
            ),
          // Permission & View Once Controls
          Padding(
            padding: const EdgeInsets.only(bottom: 10.0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  _buildPermissionToggle(
                    icon: _allowView ? CommonIcons.visibility : CommonIcons.visibilityOff,
                    label: 'View',
                    isActive: _allowView,
                    onTap: () => setState(() => _allowView = !_allowView),
                  ),
                  CommonSpaces.w8,
                  _buildPermissionToggle(
                    icon: _allowDownload ? CommonIcons.download : CommonIcons.downloadOff,
                    label: 'Download',
                    isActive: _isViewOnce ? false : _allowDownload,
                    onTap: _isViewOnce
                        ? () => context.showInfoNotification('Download is disabled for View Once')
                        : () => setState(() => _allowDownload = !_allowDownload),
                  ),
                  CommonSpaces.w8,
                  _buildPermissionToggle(
                    icon: _allowShare ? CommonIcons.share : CommonIcons.shareOff,
                    label: 'Share',
                    isActive: _isViewOnce ? false : _allowShare,
                    onTap: _isViewOnce
                        ? () => context.showInfoNotification('Share is disabled for View Once')
                        : () => setState(() => _allowShare = !_allowShare),
                  ),
                ],
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: context.colors.lightBackground,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _captionController,
                          style: context.bodyLarge,
                          textCapitalization: TextCapitalization.sentences,
                          maxLines: 3,
                          minLines: 1,
                          decoration: InputDecoration(
                            hintText: 'Add a caption...',
                            hintStyle: context.bodyLarge.copyWith(color: context.colors.textHint),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          ),
                        ),
                      ),
                      // WhatsApp View Once circled '1' button in caption bar
                      Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: Tooltip(
                          message: _isViewOnce
                              ? 'View Once enabled'
                              : 'Set to View Once',
                          child: ViewOnceIconWidget(
                            count: 1,
                            isActive: _isViewOnce,
                            size: 26,
                            onTap: _toggleViewOnce,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              CommonSpaces.w12,
              GestureDetector(
                onTap: _onSend,
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: context.colors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(CommonIcons.send, color: context.colors.pureWhite, size: 20),
                ),
              ),
            ],
          ),
          CommonSpaces.h8,
          Text(
            'Send to ${widget.contactName}',
            style: context.bodySmall.copyWith(color: context.colors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionToggle({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isActive
              ? context.colors.primary.withValues(alpha: 0.15)
              : context.colors.border.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive ? context.colors.primary : context.colors.border.withValues(alpha: 0.4),
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isActive ? context.colors.primary : context.colors.textSecondary,
            ),
            CommonSpaces.w6,
            Text(
              label,
              style: context.bodySmall.copyWith(
                color: isActive ? context.colors.primary : context.colors.textSecondary,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DocMetadata {
  final IconData icon;
  final Color color;
  final String label;
  final String extensionUpper;

  const _DocMetadata({
    required this.icon,
    required this.color,
    required this.label,
    required this.extensionUpper,
  });
}
