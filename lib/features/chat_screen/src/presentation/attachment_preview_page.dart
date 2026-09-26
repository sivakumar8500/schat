import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:schat/utils/common_colors.dart';
import 'package:schat/utils/common_fontstyles.dart';
import 'package:schat/utils/common_icons.dart';
import 'package:schat/utils/common_spaces.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:schat/features/chat_screen/src/presentation/widgets/image_editor_crop_view.dart';
import 'package:schat/features/chat_screen/src/presentation/widgets/image_editor_filter_view.dart';
import 'package:schat/features/chat_screen/src/presentation/widgets/image_editor_doodle_view.dart';

class AttachmentPreviewPage extends StatefulWidget {
  final String? path;
  final Uint8List? bytes;
  final String name;
  final String type; // 'image', 'video', 'document', 'audio'
  final int size;
  final String contactName;

  const AttachmentPreviewPage({
    super.key,
    this.path,
    this.bytes,
    required this.name,
    required this.type,
    required this.size,
    required this.contactName,
  });

  @override
  State<AttachmentPreviewPage> createState() => _AttachmentPreviewPageState();
}

class _AttachmentPreviewPageState extends State<AttachmentPreviewPage> {
  final TextEditingController _captionController = TextEditingController();
  VideoPlayerController? _videoPlayerController;
  bool _isVideoPlaying = false;

  Uint8List? _currentBytes;
  Uint8List? _originalBytes;
  bool _hasEdits = false;

  @override
  void initState() {
    super.initState();
    if (widget.type == 'image' && widget.bytes != null) {
      _currentBytes = widget.bytes;
      _originalBytes = widget.bytes;
    }
    _initImageBytes();
    if (widget.type == 'video' && widget.path != null) {
      if (kIsWeb) {
        _videoPlayerController = VideoPlayerController.networkUrl(Uri.parse(widget.path!));
      } else {
        _videoPlayerController = VideoPlayerController.file(File(widget.path!));
      }
      _videoPlayerController!.initialize().then((_) {
        if (mounted) setState(() {});
        _videoPlayerController!.play();
        _isVideoPlaying = true;
      });
    }
  }

  Future<void> _initImageBytes() async {
    if (widget.type == 'image') {
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
  }

  @override
  void dispose() {
    _captionController.dispose();
    _videoPlayerController?.dispose();
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

  void _onSend() {
    Navigator.pop(context, {
      'send': true,
      'caption': _captionController.text.trim(),
      'bytes': _currentBytes ?? widget.bytes,
      'path': widget.path,
    });
  }

  @override
  Widget build(BuildContext context) {
    final isImage = widget.type == 'image';

    return Scaffold(
      backgroundColor: context.colors.pureBlack,
      appBar: AppBar(
        backgroundColor: context.colors.pureBlack.withValues(alpha: 0.7),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: context.colors.pureWhite),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (isImage && (_currentBytes != null || widget.bytes != null || widget.path != null)) ...[
            // Crop & Rotate
            IconButton(
              icon: const Icon(Icons.crop_rotate, color: Colors.white),
              tooltip: 'Crop & Rotate',
              onPressed: _openCrop,
            ),
            // Filters & Effects
            IconButton(
              icon: const Icon(Icons.auto_awesome, color: Colors.white),
              tooltip: 'Filters & Effects',
              onPressed: _openFilters,
            ),
            // Draw & Doodle
            IconButton(
              icon: const Icon(Icons.brush, color: Colors.white),
              tooltip: 'Draw & Text',
              onPressed: _openDoodle,
            ),
            // Reset edits button
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
                child: _buildPreview(),
              ),
            ),
            _buildBottomBar(context),
          ],
        ),
      ),
    );
  }

  Widget _buildPreview() {
    if (widget.type == 'image') {
      if (_currentBytes != null) {
        return Image.memory(
          _currentBytes!,
          fit: BoxFit.contain,
          key: ValueKey(_currentBytes!.hashCode),
        );
      } else if (widget.bytes != null) {
        return Image.memory(widget.bytes!, fit: BoxFit.contain);
      } else if (widget.path != null) {
        return kIsWeb
            ? Image.network(widget.path!, fit: BoxFit.contain)
            : Image.file(File(widget.path!), fit: BoxFit.contain);
      }
    } else if (widget.type == 'video') {
      if (_videoPlayerController != null && _videoPlayerController!.value.isInitialized) {
        return GestureDetector(
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
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(CommonIcons.playCircle, color: Colors.white, size: 48),
                ),
            ],
          ),
        );
      } else {
        return const CircularProgressIndicator();
      }
    } else if (widget.type == 'location') {
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

    // Document or Audio
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          widget.type == 'audio' ? CommonIcons.audio : CommonIcons.document,
          color: context.colors.primary,
          size: 80,
        ),
        CommonSpaces.h16,
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Text(
            widget.name,
            style: context.titleMedium.copyWith(color: context.colors.pureWhite),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        CommonSpaces.h8,
        Text(
          '${(widget.size / 1024 / 1024).toStringAsFixed(2)} MB',
          style: context.bodyMedium.copyWith(color: context.colors.textHint),
        ),
      ],
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    return Container(
      color: context.colors.scaffoldBackground,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: context.colors.lightBackground,
                    borderRadius: BorderRadius.circular(24),
                  ),
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
}
