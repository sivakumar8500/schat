import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:video_player/video_player.dart';
import 'package:schat/features/status_screen/src/presentation/bloc/status_bloc.dart';
import 'package:schat/features/status_screen/src/presentation/bloc/status_event.dart';
import 'package:schat/utils/common_notifications.dart';

class VideoStatusTrimmerPage extends StatefulWidget {
  final String? videoPath;
  final dynamic videoBytes;
  final Duration totalDuration;
  final bool exceedsLimit;

  const VideoStatusTrimmerPage({
    super.key,
    this.videoPath,
    this.videoBytes,
    required this.totalDuration,
    this.exceedsLimit = false,
  });

  @override
  State<VideoStatusTrimmerPage> createState() => _VideoStatusTrimmerPageState();
}

class _VideoStatusTrimmerPageState extends State<VideoStatusTrimmerPage> {
  late VideoPlayerController _controller;
  final TextEditingController _captionController = TextEditingController();
  bool _isInitialized = false;
  bool _isPlaying = false;
  bool _hasError = false;

  late double _startSec;
  late double _endSec;
  late double _maxSec;

  static const double maxAllowedDuration = 60.0; // 1 minute max

  @override
  void initState() {
    super.initState();
    _maxSec = widget.totalDuration.inMilliseconds / 1000.0;
    if (_maxSec < 1.0) _maxSec = 1.0;

    _startSec = 0.0;
    _endSec = _maxSec > maxAllowedDuration ? maxAllowedDuration : _maxSec;

    _initVideo();
  }

  Future<void> _initVideo() async {
    try {
      if (kIsWeb || widget.videoPath == null) {
        _isInitialized = true;
        setState(() {});
        return;
      }

      _controller = VideoPlayerController.file(File(widget.videoPath!));
      await _controller.initialize();

      final actualDur = _controller.value.duration.inMilliseconds / 1000.0;
      if (actualDur > 0) {
        _maxSec = actualDur;
        if (_endSec > _maxSec) _endSec = _maxSec;
        if (_endSec - _startSec > maxAllowedDuration) {
          _endSec = _startSec + maxAllowedDuration;
        }
      }

      _controller.addListener(_videoListener);
      _controller.setLooping(false);
      await _controller.play();

      if (mounted) {
        setState(() {
          _isInitialized = true;
          _isPlaying = true;
        });
      }
    } catch (e) {
      debugPrint('Error initializing VideoStatusTrimmerPage player: $e');
      if (mounted) {
        setState(() {
          _hasError = true;
          _isInitialized = true;
        });
      }
    }
  }

  void _videoListener() {
    if (!_controller.value.isInitialized) return;
    final pos = _controller.value.position.inMilliseconds / 1000.0;
    
    // If position reached or exceeded the end trim window, loop back to start
    if (pos >= _endSec) {
      _controller.seekTo(Duration(milliseconds: (_startSec * 1000).round()));
      if (!_controller.value.isPlaying) {
        _controller.play();
      }
    } else if (pos < _startSec - 0.5) {
      _controller.seekTo(Duration(milliseconds: (_startSec * 1000).round()));
    }

    if (mounted && _isPlaying != _controller.value.isPlaying) {
      setState(() {
        _isPlaying = _controller.value.isPlaying;
      });
    }
  }

  @override
  void dispose() {
    if (_isInitialized && !_hasError && !kIsWeb && widget.videoPath != null) {
      _controller.removeListener(_videoListener);
      _controller.dispose();
    }
    _captionController.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    if (!_isInitialized || _hasError) return;
    if (_controller.value.isPlaying) {
      _controller.pause();
    } else {
      _controller.play();
    }
    setState(() {
      _isPlaying = _controller.value.isPlaying;
    });
  }

  String _formatSeconds(double sec) {
    final total = sec.round();
    final m = total ~/ 60;
    final s = total % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  void _onRangeChanged(RangeValues values) {
    double newStart = values.start;
    double newEnd = values.end;

    // Enforce 60-second max duration window
    if (newEnd - newStart > maxAllowedDuration) {
      if (newStart != _startSec) {
        // Start moved forward -> shift end
        newEnd = (newStart + maxAllowedDuration).clamp(0.0, _maxSec);
      } else {
        // End moved backward -> shift start
        newStart = (newEnd - maxAllowedDuration).clamp(0.0, _maxSec);
      }
    }

    setState(() {
      _startSec = newStart;
      _endSec = newEnd;
    });

    if (_isInitialized && !_hasError) {
      _controller.seekTo(Duration(milliseconds: (_startSec * 1000).round()));
    }
  }

  void _onPostStatus() {
    final clipDuration = _endSec - _startSec;
    if (clipDuration > maxAllowedDuration + 0.5) {
      context.showErrorNotification(
        'Selected clip (${_formatSeconds(clipDuration)}) exceeds the 1-minute limit (60s). Please trim your video.',
      );
      return;
    }

    final caption = _captionController.text.trim();
    context.showInfoNotification('Uploading video status...');
    context.read<StatusBloc>().add(
          UploadMediaStatusEvent(
            path: widget.videoPath,
            bytes: widget.videoBytes,
            caption: caption.isNotEmpty ? caption : null,
            statusType: 'video',
            mimeType: 'video/mp4',
          ),
        );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final clipDuration = (_endSec - _startSec).clamp(0.0, _maxSec);
    final isExceeded = clipDuration > maxAllowedDuration;

    return Scaffold(
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Video Status (Max 1 min)',
          style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16, top: 10, bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isExceeded ? Colors.redAccent.withValues(alpha: 0.3) : const Color(0xFF00873C).withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isExceeded ? Colors.redAccent : const Color(0xFF00873C),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.timer_outlined,
                  size: 14,
                  color: isExceeded ? Colors.redAccent : const Color(0xFF00D084),
                ),
                const SizedBox(width: 4),
                Text(
                  '${_formatSeconds(clipDuration)} / 01:00',
                  style: TextStyle(
                    color: isExceeded ? Colors.redAccent : const Color(0xFF00D084),
                    fontWeight: FontWeight.bold,
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Exceeds warning banner if video is longer than 60s
            if (_maxSec > maxAllowedDuration)
              Container(
                margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF2C1600),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.withValues(alpha: 0.5)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.orangeAccent, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Total video is ${_formatSeconds(_maxSec)}. Use the slider below to select your 1-minute (60s) clip.',
                        style: const TextStyle(
                          color: Colors.orangeAccent,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Video Preview Area
            Expanded(
              child: GestureDetector(
                onTap: _togglePlayPause,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      color: Colors.black,
                      child: Center(
                        child: _isInitialized && !_hasError && _controller.value.isInitialized
                            ? AspectRatio(
                                aspectRatio: _controller.value.aspectRatio,
                                child: VideoPlayer(_controller),
                              )
                            : const CircularProgressIndicator(color: Color(0xFF00873C)),
                      ),
                    ),
                    if (_isInitialized && !_isPlaying)
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(
                          Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Video Trimmer Controls
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF161616),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Range Labels (Start, Duration, End)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.start_rounded, color: Colors.white70, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            'Start: ${_formatSeconds(_startSec)}',
                            style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      Text(
                        'Selected: ${_formatSeconds(clipDuration)}',
                        style: TextStyle(
                          color: isExceeded ? Colors.redAccent : const Color(0xFF00D084),
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            'End: ${_formatSeconds(_endSec)}',
                            style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.stop_circle_outlined, color: Colors.white70, size: 16),
                        ],
                      ),
                    ],
                  ),

                  // Range Slider for Trimming
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 6,
                      activeTrackColor: const Color(0xFF00873C),
                      inactiveTrackColor: Colors.white24,
                      thumbColor: Colors.white,
                      overlayColor: const Color(0xFF00873C).withValues(alpha: 0.2),
                      rangeThumbShape: const RoundRangeSliderThumbShape(enabledThumbRadius: 9),
                      rangeTrackShape: const RoundedRectRangeSliderTrackShape(),
                    ),
                    child: RangeSlider(
                      values: RangeValues(_startSec, _endSec),
                      min: 0.0,
                      max: _maxSec,
                      onChanged: _onRangeChanged,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Caption Input + Send Button
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF262626),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: Colors.white12),
                          ),
                          child: TextField(
                            controller: _captionController,
                            style: const TextStyle(color: Colors.white, fontSize: 15),
                            decoration: const InputDecoration(
                              hintText: 'Add a caption... (optional)',
                              hintStyle: TextStyle(color: Colors.white54, fontSize: 14),
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        width: 48,
                        height: 48,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFF00873C),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.send_rounded, color: Colors.white, size: 22),
                          tooltip: 'Post Video Status',
                          onPressed: _onPostStatus,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
