import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:schat/utils/common_colors.dart';
import 'package:schat/utils/common_fontstyles.dart';
import 'package:schat/utils/common_icons.dart';
import 'package:schat/utils/common_spaces.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

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

  @override
  void initState() {
    super.initState();
    if (widget.type == 'video' && widget.path != null) {
      if (kIsWeb) {
        _videoPlayerController = VideoPlayerController.networkUrl(Uri.parse(widget.path!));
      } else {
        _videoPlayerController = VideoPlayerController.file(File(widget.path!));
      }
      _videoPlayerController!.initialize().then((_) {
        setState(() {});
        _videoPlayerController!.play();
        _isVideoPlaying = true;
      });
    }
  }

  @override
  void dispose() {
    _captionController.dispose();
    _videoPlayerController?.dispose();
    super.dispose();
  }

  void _onSend() {
    Navigator.pop(context, {
      'send': true,
      'caption': _captionController.text.trim(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.pureBlack,
      appBar: AppBar(
        backgroundColor: context.colors.pureBlack.withValues(alpha: 0.5),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: context.colors.pureWhite),
          onPressed: () => Navigator.pop(context),
        ),
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
      if (widget.bytes != null) {
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
