import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:schat/features/status_screen/src/presentation/bloc/status_bloc.dart';
import 'package:schat/features/status_screen/src/presentation/bloc/status_event.dart';
import 'package:schat/utils/common_notifications.dart';

class VoiceStatusCreatorPage extends StatefulWidget {
  const VoiceStatusCreatorPage({super.key});

  @override
  State<VoiceStatusCreatorPage> createState() => _VoiceStatusCreatorPageState();
}

class _VoiceStatusCreatorPageState extends State<VoiceStatusCreatorPage> with SingleTickerProviderStateMixin {
  final AudioRecorder _audioRecorder = AudioRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();
  final TextEditingController _captionController = TextEditingController();

  final List<Color> _presetColors = const [
    Color(0xFF00695C), // Teal
    Color(0xFF4A148C), // Deep Purple
    Color(0xFF1A237E), // Navy Blue
    Color(0xFF880E4F), // Burgundy / Pink
    Color(0xFFE65100), // Orange
    Color(0xFF37474F), // Blue Grey
    Color(0xFFB71C1C), // Crimson Red
    Color(0xFF2E7D32), // Forest Green
  ];

  int _selectedColorIndex = 0;
  Color get _currentColor => _presetColors[_selectedColorIndex];

  String _colorToHex(Color color) {
    return '#${color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
  }

  bool _isRecording = false;
  int _recordDurationSeconds = 0;
  Timer? _recordingTimer;
  String? _recordedFilePath;

  bool _isPlayingPreview = false;
  Duration _playPosition = Duration.zero;
  Duration _totalAudioDuration = Duration.zero;
  StreamSubscription? _playerPosSub;
  StreamSubscription? _playerStateSub;
  StreamSubscription? _playerCompleteSub;

  late AnimationController _pulseController;

  static const int maxDurationSeconds = 60; // 1 minute max

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _playerPosSub = _audioPlayer.onPositionChanged.listen((pos) {
      if (mounted) setState(() => _playPosition = pos);
    });
    _playerStateSub = _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() => _isPlayingPreview = (state == PlayerState.playing));
      }
    });
    _playerCompleteSub = _audioPlayer.onPlayerComplete.listen((_) {
      if (mounted) {
        setState(() {
          _isPlayingPreview = false;
          _playPosition = Duration.zero;
        });
      }
    });
  }

  @override
  void dispose() {
    _recordingTimer?.cancel();
    _audioRecorder.dispose();
    _playerPosSub?.cancel();
    _playerStateSub?.cancel();
    _playerCompleteSub?.cancel();
    _audioPlayer.dispose();
    _pulseController.dispose();
    _captionController.dispose();
    super.dispose();
  }

  void _cycleColor() {
    setState(() {
      _selectedColorIndex = (_selectedColorIndex + 1) % _presetColors.length;
    });
  }

  Future<void> _startRecording() async {
    final hasPerm = await _audioRecorder.hasPermission();
    if (!hasPerm) {
      if (mounted) context.showErrorNotification('Microphone permission required');
      return;
    }

    try {
      final dir = kIsWeb ? null : await getTemporaryDirectory();
      final path = kIsWeb
          ? 'voice_status_${DateTime.now().millisecondsSinceEpoch}.m4a'
          : '${dir!.path}/voice_status_${DateTime.now().millisecondsSinceEpoch}.m4a';

      await _audioRecorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        ),
        path: path,
      );

      setState(() {
        _isRecording = true;
        _recordDurationSeconds = 0;
        _recordedFilePath = null;
      });

      _recordingTimer?.cancel();
      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }
        setState(() => _recordDurationSeconds++);
        if (_recordDurationSeconds >= maxDurationSeconds) {
          _stopRecording();
        }
      });
    } catch (e) {
      if (mounted) context.showErrorNotification('Failed to start recording: $e');
    }
  }

  Future<void> _stopRecording() async {
    _recordingTimer?.cancel();
    _recordingTimer = null;
    if (!_isRecording) return;

    try {
      final path = await _audioRecorder.stop();
      setState(() {
        _isRecording = false;
        _recordedFilePath = path;
      });

      if (path != null) {
        // Load duration for preview
        await _audioPlayer.setSource(DeviceFileSource(path));
        final dur = await _audioPlayer.getDuration() ?? Duration(seconds: _recordDurationSeconds);
        setState(() {
          _totalAudioDuration = dur;
        });
      }
    } catch (e) {
      if (mounted) context.showErrorNotification('Error stopping recording: $e');
    }
  }

  void _retakeRecording() {
    _audioPlayer.stop();
    if (_recordedFilePath != null) {
      try {
        File(_recordedFilePath!).deleteSync();
      } catch (_) {}
    }
    setState(() {
      _recordedFilePath = null;
      _recordDurationSeconds = 0;
      _isPlayingPreview = false;
      _playPosition = Duration.zero;
      _totalAudioDuration = Duration.zero;
    });
  }

  void _togglePreviewPlayback() async {
    if (_recordedFilePath == null) return;
    if (_isPlayingPreview) {
      await _audioPlayer.pause();
    } else {
      await _audioPlayer.play(DeviceFileSource(_recordedFilePath!));
    }
  }

  void _postVoiceStatus() {
    if (_recordedFilePath == null) return;
    final caption = _captionController.text.trim();
    final hexColor = _colorToHex(_currentColor);

    context.showInfoNotification('Uploading voice status...');
    context.read<StatusBloc>().add(
          UploadMediaStatusEvent(
            path: _recordedFilePath,
            caption: caption.isNotEmpty ? caption : null,
            statusType: 'audio',
            mimeType: 'audio/m4a',
            textColor: hexColor,
          ),
        );
    Navigator.pop(context);
  }

  String _formatTime(int totalSecs) {
    final m = totalSecs ~/ 60;
    final s = totalSecs % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      color: _currentColor,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close, color: Colors.white, size: 28),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'Voice Status (Max 1 min)',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.color_lens_outlined, color: Colors.white, size: 28),
              tooltip: 'Change Background Color',
              onPressed: _cycleColor,
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              children: [
                // Color dots row
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_presetColors.length, (index) {
                      final isSelected = index == _selectedColorIndex;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedColorIndex = index),
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: _presetColors[index],
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? Colors.white : Colors.white38,
                              width: isSelected ? 3 : 1.5,
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
                const Spacer(),

                // Center Voice Card
                if (_recordedFilePath == null)
                  _buildRecordingView()
                else
                  _buildPreviewCard(),

                const Spacer(),

                // Caption TextField
                if (_recordedFilePath != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: TextField(
                      controller: _captionController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: 'Add a caption... (optional)',
                        hintStyle: TextStyle(color: Colors.white60),
                        border: InputBorder.none,
                      ),
                    ),
                  ),

                // Post Button
                if (_recordedFilePath != null)
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: _postVoiceStatus,
                      icon: const Icon(Icons.send_rounded, color: Colors.white),
                      label: const Text(
                        'Post Voice Status',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: 0.25),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
                        elevation: 0,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecordingView() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Timer
        Text(
          '${_formatTime(_recordDurationSeconds)} / 01:00',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          _isRecording ? 'Recording... Tap to finish' : 'Tap microphone to record voice status',
          style: const TextStyle(color: Colors.white70, fontSize: 15),
        ),
        const SizedBox(height: 36),

        // Big Mic Button
        GestureDetector(
          onTap: _isRecording ? _stopRecording : _startRecording,
          child: AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              final scale = _isRecording ? (1.0 + (_pulseController.value * 0.12)) : 1.0;
              return Transform.scale(
                scale: scale,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: _isRecording ? Colors.redAccent : Colors.white.withValues(alpha: 0.25),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: _isRecording ? Colors.redAccent.withValues(alpha: 0.5) : Colors.black26,
                        blurRadius: 16,
                        spreadRadius: _isRecording ? 4 : 2,
                      ),
                    ],
                  ),
                  child: Icon(
                    _isRecording ? Icons.stop_rounded : Icons.mic_rounded,
                    color: Colors.white,
                    size: 48,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPreviewCard() {
    final totalSecs = _totalAudioDuration.inSeconds > 0 ? _totalAudioDuration.inSeconds : _recordDurationSeconds;
    final posSecs = _playPosition.inSeconds;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white24, width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              // Play/Pause button
              GestureDetector(
                onTap: _togglePreviewPlayback,
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _isPlayingPreview ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    color: _currentColor,
                    size: 32,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Progress indicator & time
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 4,
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                        overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                        activeTrackColor: Colors.white,
                        inactiveTrackColor: Colors.white30,
                        thumbColor: Colors.white,
                      ),
                      child: Slider(
                        value: _totalAudioDuration.inMilliseconds > 0
                            ? (_playPosition.inMilliseconds / _totalAudioDuration.inMilliseconds).clamp(0.0, 1.0)
                            : 0.0,
                        onChanged: (val) {
                          if (_totalAudioDuration.inMilliseconds > 0) {
                            final targetMs = (val * _totalAudioDuration.inMilliseconds).toInt();
                            _audioPlayer.seek(Duration(milliseconds: targetMs));
                          }
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatTime(posSecs),
                            style: const TextStyle(color: Colors.white70, fontSize: 13),
                          ),
                          Text(
                            _formatTime(totalSecs),
                            style: const TextStyle(color: Colors.white70, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Retake button
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: _retakeRecording,
              icon: const Icon(Icons.refresh_rounded, color: Colors.white70, size: 18),
              label: const Text('Retake', style: TextStyle(color: Colors.white70)),
            ),
          ),
        ],
      ),
    );
  }
}
