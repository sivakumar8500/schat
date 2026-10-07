import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:video_player/video_player.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:schat/core/storage/storage_service.dart';
import 'package:schat/features/chat_socket_screen/src/domain/chat_socket_repository.dart';
import 'package:schat/features/dashboard_screen/src/domain/repositories/dashboard_repository.dart';
import 'package:schat/features/status_screen/src/domain/repositories/status_repository.dart';
import 'package:schat/features/status_screen/src/domain/status_model.dart';
import 'package:schat/injection.dart';
import 'package:schat/utils/common_notifications.dart';

class StatusViewPage extends StatefulWidget {
  final List<StatusContactModel> contacts;
  final int initialIndex;

  // Optional fields for "My Status"
  final List<StatusItemModel>? myStatuses;
  final Uint8List? myBytes;
  final String? myPath;
  final String? myText;
  final bool isMyStatus;

  const StatusViewPage({
    super.key,
    required this.contacts,
    this.initialIndex = 0,
    this.myStatuses,
    this.myBytes,
    this.myPath,
    this.myText,
    this.isMyStatus = false,
  });

  @override
  State<StatusViewPage> createState() => _StatusViewPageState();
}

class _StatusViewPageState extends State<StatusViewPage> with TickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _progressController;
  late AnimationController _emojiBurstController;
  String? _burstEmoji;
  List<_EmojiBurstParticle> _emojiParticles = [];
  int _currentContactIndex = 0;
  int _currentStatusIndex = 0;
  bool _isHolding = false;
  bool _isMediaLoading = false;
  String? _currentMediaUrl;
  final Set<String> _viewedStatusIds = {};

  // Media Player Controllers
  VideoPlayerController? _videoController;
  AudioPlayer? _audioPlayer;
  double _customProgressValue = 0.0;
  bool _isCustomMedia = false;
  Duration _audioPosition = Duration.zero;
  Duration _audioDuration = Duration.zero;
  bool _isPlayingAudio = false;
  bool _videoError = false;
  bool _isAdvancing = false;

  void _markStatusViewed(String? statusId) {
    if (statusId == null || statusId.isEmpty || widget.isMyStatus) return;
    if (_viewedStatusIds.contains(statusId)) return;
    _viewedStatusIds.add(statusId);
    getIt<StatusRepository>().viewStatus(statusId).catchError((e) {
      debugPrint('Error marking status as viewed: $e');
    });
  }

  void _showStatusOptionsMenu(String? statusId) {
    _pauseCurrentPlayback();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1E1E1E),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white30,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            if (widget.isMyStatus && statusId != null && statusId.isNotEmpty) ...[
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.redAccent),
                title: const Text(
                  'Delete Status',
                  style: TextStyle(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _confirmAndDeleteStatus(statusId);
                },
              ),
            ] else ...[
              ListTile(
                leading: const Icon(Icons.close, color: Colors.white),
                title: const Text('Close', style: TextStyle(color: Colors.white)),
                onTap: () => Navigator.pop(ctx),
              ),
            ],
          ],
        ),
      ),
    ).then((_) {
      if (mounted && !_isMediaLoading) _resumeCurrentPlayback();
    });
  }

  Future<void> _confirmAndDeleteStatus(String statusId) async {
    _pauseCurrentPlayback();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2C2C2C),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Delete Status?',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'This status update will be deleted for all viewers.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Delete',
              style: TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) {
      if (mounted && !_isMediaLoading) _resumeCurrentPlayback();
      return;
    }

    try {
      await getIt<StatusRepository>().deleteStatus(statusId);
      if (!mounted) return;

      context.showSuccessNotification('Status deleted');

      final list = widget.myStatuses;
      if (list != null && list.isNotEmpty) {
        list.removeWhere((item) => item.id == statusId);
        if (list.isEmpty) {
          Navigator.pop(context);
          return;
        } else {
          setState(() {
            if (_currentStatusIndex >= list.length) {
              _currentStatusIndex = list.length - 1;
            }
          });
          _startProgress();
        }
      } else {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        context.showErrorNotification('Failed to delete status: $e');
        if (!_isMediaLoading) _resumeCurrentPlayback();
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _currentContactIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentContactIndex);
    
    _progressController = AnimationController(vsync: this, duration: const Duration(seconds: 5));
    _emojiBurstController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800));
    _startProgress();
    
    _progressController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _nextStatus();
      }
    });
  }

  void _cleanupMediaPlayers() {
    try {
      _videoController?.pause();
      _videoController?.dispose();
    } catch (_) {}
    _videoController = null;

    try {
      _audioPlayer?.stop();
      _audioPlayer?.dispose();
    } catch (_) {}
    _audioPlayer = null;

    _isPlayingAudio = false;
    _audioPosition = Duration.zero;
    _audioDuration = Duration.zero;
    _videoError = false;
  }

  void _pauseCurrentPlayback() {
    if (!_isMediaLoading) {
      _progressController.stop();
    }
    _videoController?.pause();
    _audioPlayer?.pause();
  }

  void _resumeCurrentPlayback() {
    if (_isCustomMedia) {
      _videoController?.play();
      _audioPlayer?.resume();
    } else {
      _progressController.forward();
    }
  }

  void _startProgress() {
    _cleanupMediaPlayers();
    _isAdvancing = false;
    _progressController.stop();
    _progressController.value = 0.0;
    _customProgressValue = 0.0;
    _isCustomMedia = false;

    String? mediaUrl;
    String? statusType;

    if (widget.isMyStatus) {
      final list = widget.myStatuses ?? [];
      if (list.isNotEmpty) {
        final item = list[_currentStatusIndex.clamp(0, list.length - 1)];
        mediaUrl = item.imagePath;
        statusType = item.statusType;
      } else if (widget.myPath != null) {
        mediaUrl = widget.myPath;
        final lower = (widget.myPath ?? '').toLowerCase();
        if (lower.endsWith('.mp4') || lower.endsWith('.mov') || lower.endsWith('.avi') || lower.endsWith('.mkv')) {
          statusType = 'video';
        }
      }
    } else if (widget.contacts.isNotEmpty) {
      final contact = widget.contacts[_currentContactIndex];
      if (contact.statuses.isNotEmpty) {
        final status = contact.statuses[_currentStatusIndex.clamp(0, contact.statuses.length - 1)];
        mediaUrl = status.imagePath;
        statusType = status.statusType;
      }
    }

    _currentMediaUrl = mediaUrl;

    final lower = (mediaUrl ?? '').toLowerCase();
    final isVideo = (statusType == 'video') ||
        lower.endsWith('.mp4') ||
        lower.endsWith('.mov') ||
        lower.endsWith('.avi') ||
        lower.endsWith('.mkv');

    final isAudio = (statusType == 'audio') ||
        lower.endsWith('.m4a') ||
        lower.endsWith('.mp3') ||
        lower.endsWith('.aac') ||
        lower.endsWith('.wav');

    if (isVideo && mediaUrl != null && mediaUrl.isNotEmpty) {
      _initVideoPlayer(mediaUrl);
    } else if (isAudio && mediaUrl != null && mediaUrl.isNotEmpty) {
      _initAudioPlayer(mediaUrl);
    } else if (mediaUrl != null && mediaUrl.isNotEmpty && !File(mediaUrl).existsSync() && !mediaUrl.startsWith('http')) {
      // Network media is loading; wait for _onMediaLoaded
      _isMediaLoading = true;
    } else {
      // Text or local media; start standard 5s timer
      _isMediaLoading = false;
      _progressController.duration = const Duration(seconds: 5);
      _progressController.forward(from: 0.0);
    }
  }

  Future<void> _initVideoPlayer(String url) async {
    _isCustomMedia = true;
    _isMediaLoading = true;
    _videoError = false;
    if (mounted) setState(() {});

    final isLocal = url.startsWith('file://') || (!url.startsWith('http') && File(url).existsSync());
    final effectivePath = url.replaceFirst('file://', '');
    final controller = isLocal
        ? VideoPlayerController.file(File(effectivePath))
        : VideoPlayerController.networkUrl(Uri.parse(url));

    _videoController = controller;

    try {
      await controller.initialize().timeout(const Duration(seconds: 15));
      if (!mounted || _videoController != controller) {
        await controller.dispose();
        return;
      }

      final rawDuration = controller.value.duration;
      // Cap maximum video duration to 1 minute (60 seconds)
      final duration = (rawDuration.inSeconds > 60)
          ? const Duration(seconds: 60)
          : (rawDuration.inMilliseconds > 0 ? rawDuration : const Duration(seconds: 5));

      controller.addListener(() {
        if (!mounted || _videoController != controller) return;
        final val = controller.value;
        if (!val.isInitialized) return;

        final pos = val.position;
        final progress = (duration.inMilliseconds > 0)
            ? (pos.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0)
            : 1.0;

        if (mounted) {
          setState(() {
            _customProgressValue = progress;
          });
        }

        final isEnded = val.isCompleted ||
            pos >= duration ||
            (!val.isPlaying && pos.inMilliseconds > 500 && pos >= duration - const Duration(milliseconds: 300));

        // Advance when reached end of video or 1-minute mark
        if (!_isAdvancing && isEnded) {
          _isAdvancing = true;
          _nextStatus();
        }
      });

      setState(() {
        _isMediaLoading = false;
        _videoError = false;
      });
      await controller.play();
    } catch (e) {
      debugPrint('Error initializing status video player ($url): $e');
      if (mounted) {
        setState(() {
          _isMediaLoading = false;
          _videoError = true;
        });
        _progressController.duration = const Duration(seconds: 5);
        _progressController.forward(from: 0.0);
      }
    }
  }

  Future<void> _initAudioPlayer(String url) async {
    _isCustomMedia = true;
    _isMediaLoading = true;
    if (mounted) setState(() {});

    final player = AudioPlayer();
    _audioPlayer = player;

    try {
      final isLocal = File(url).existsSync();
      final Source source = isLocal ? DeviceFileSource(url) : UrlSource(url);
      await player.setSource(source);

      final rawDuration = await player.getDuration() ?? const Duration(seconds: 15);
      final duration = (rawDuration.inSeconds > 60)
          ? const Duration(seconds: 60)
          : (rawDuration.inMilliseconds > 0 ? rawDuration : const Duration(seconds: 15));

      setState(() {
        _audioDuration = duration;
      });

      player.onPositionChanged.listen((pos) {
        if (!mounted || _audioPlayer != player) return;
        final progress = (pos.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0);
        setState(() {
          _audioPosition = pos;
          _customProgressValue = progress;
        });
        if (!_isAdvancing && pos >= duration) {
          _isAdvancing = true;
          _nextStatus();
        }
      });

      player.onPlayerComplete.listen((_) {
        if (!mounted || _audioPlayer != player || _isAdvancing) return;
        _isAdvancing = true;
        _nextStatus();
      });

      player.onPlayerStateChanged.listen((state) {
        if (mounted) {
          setState(() {
            _isPlayingAudio = (state == PlayerState.playing);
          });
        }
      });

      setState(() {
        _isMediaLoading = false;
      });
      await player.resume();
    } catch (e) {
      debugPrint('Error initializing status audio player: $e');
      if (mounted) {
        setState(() {
          _isMediaLoading = false;
          _isCustomMedia = false;
        });
        _progressController.duration = const Duration(seconds: 5);
        _progressController.forward(from: 0.0);
      }
    }
  }

  void _onMediaLoaded(String url) {
    if (!mounted) return;
    if (_currentMediaUrl == url && _isMediaLoading) {
      setState(() {
        _isMediaLoading = false;
      });
      _progressController.duration = const Duration(seconds: 5);
      _progressController.forward(from: 0.0);
    }
  }

  void _nextStatus() {
    _cleanupMediaPlayers();
    if (widget.isMyStatus) {
      final list = widget.myStatuses ?? [];
      if (list.isNotEmpty && _currentStatusIndex < list.length - 1) {
        setState(() {
          _currentStatusIndex++;
        });
        _startProgress();
      } else {
        if (mounted && Navigator.canPop(context)) {
          Navigator.pop(context);
        }
      }
      return;
    }

    if (widget.contacts.isEmpty) {
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      return;
    }

    final contact = widget.contacts[_currentContactIndex.clamp(0, widget.contacts.length - 1)];
    if (_currentStatusIndex < contact.statuses.length - 1) {
      setState(() {
        _currentStatusIndex++;
      });
      _startProgress();
    } else {
      _nextContact();
    }
  }

  void _previousStatus() {
    _cleanupMediaPlayers();
    if (widget.isMyStatus) {
      if (_currentStatusIndex > 0) {
        setState(() {
          _currentStatusIndex--;
        });
        _startProgress();
      }
      return;
    }

    if (_currentStatusIndex > 0) {
      setState(() {
        _currentStatusIndex--;
      });
      _startProgress();
    } else {
      _previousContact();
    }
  }

  void _nextContact() {
    _cleanupMediaPlayers();
    if (_currentContactIndex < widget.contacts.length - 1) {
      setState(() {
        _currentContactIndex++;
        _currentStatusIndex = 0;
      });
      _pageController.animateToPage(
        _currentContactIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      _startProgress();
    } else {
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    }
  }

  void _previousContact() {
    _cleanupMediaPlayers();
    if (_currentContactIndex > 0) {
      setState(() {
        _currentContactIndex--;
        _currentStatusIndex = 0;
      });
      _pageController.animateToPage(
        _currentContactIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      _startProgress();
    }
  }

  @override
  void dispose() {
    _cleanupMediaPlayers();
    _pageController.dispose();
    _progressController.dispose();
    _emojiBurstController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isMyStatus) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: _buildViewer(null),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.contacts.length,
        onPageChanged: (index) {
          if (_currentContactIndex != index) {
            setState(() {
              _currentContactIndex = index;
              _currentStatusIndex = 0;
            });
            _startProgress();
          }
        },
        itemBuilder: (context, index) {
          final contact = widget.contacts[index];
          return _buildViewer(contact);
        },
      ),
    );
  }

  Widget _buildViewer(StatusContactModel? contact) {
    Color bgColor = const Color(0xFF00897B);
    String name = "My Status";
    String time = "Just now";
    String initial = "M";
    String? avatarUrl;
    int total = 1;
    int current = 0;
    int viewCount = 0;
    List<StatusViewerModel> viewers = [];
    String? currentStatusId;
    
    Widget content;

    if (widget.isMyStatus) {
      avatarUrl = getIt<StorageService>().getProfilePic();
      final myStatusesList = widget.myStatuses ?? [];
      if (myStatusesList.isNotEmpty) {
        total = myStatusesList.length;
        current = _currentStatusIndex.clamp(0, total - 1);
        final item = myStatusesList[current];
        currentStatusId = item.id;
        time = _formatTime(item.timestamp);
        viewCount = item.viewCount ?? item.viewers.length;
        viewers = item.viewers;

        final lower = (item.imagePath ?? '').toLowerCase();
        final isVideo = (item.statusType == 'video') ||
            lower.endsWith('.mp4') ||
            lower.endsWith('.mov') ||
            lower.endsWith('.avi') ||
            lower.endsWith('.mkv');

        final isAudio = (item.statusType == 'audio') ||
            lower.endsWith('.m4a') ||
            lower.endsWith('.mp3') ||
            lower.endsWith('.aac') ||
            lower.endsWith('.wav');

        if (isVideo && item.imagePath != null && item.imagePath!.isNotEmpty) {
          content = _buildVideoStatusContent(
            videoUrl: item.imagePath!,
            caption: item.text,
            isMyStatus: true,
          );
        } else if (isAudio && item.imagePath != null && item.imagePath!.isNotEmpty) {
          content = _buildAudioStatusContent(
            audioUrl: item.imagePath!,
            caption: item.text,
            bgColor: item.parsedBackgroundColor,
          );
        } else if (item.imagePath != null && item.imagePath!.isNotEmpty) {
          content = _buildMediaStatusContent(
            imageUrl: item.imagePath!,
            caption: item.text,
            isMyStatus: true,
          );
        } else if (item.text != null && item.text!.isNotEmpty) {
          bgColor = item.parsedBackgroundColor;
          content = _buildTextStatusContent(
            text: item.text!,
            bgColor: bgColor,
          );
        } else {
          content = Container(
            color: Colors.black,
            alignment: Alignment.center,
            child: const Icon(Icons.photo, size: 80, color: Colors.white54),
          );
        }
      } else if (widget.myPath != null) {
        final lower = widget.myPath!.toLowerCase();
        final isVid = lower.endsWith('.mp4') || lower.endsWith('.mov') || lower.endsWith('.avi') || lower.endsWith('.mkv');
        if (isVid) {
          content = _buildVideoStatusContent(
            videoUrl: widget.myPath!,
            caption: null,
            isMyStatus: true,
          );
        } else {
          content = _buildMediaStatusContent(
            imageUrl: widget.myPath!,
            caption: null,
            isMyStatus: true,
          );
        }
      } else if (widget.myBytes != null) {
        content = Container(
          color: Colors.black,
          alignment: Alignment.center,
          child: Image.memory(widget.myBytes!, fit: BoxFit.contain),
        );
      } else if (widget.myText != null) {
        content = _buildTextStatusContent(
          text: widget.myText!,
          bgColor: const Color(0xFF00897B),
        );
      } else {
        content = Container(
          color: Colors.black,
          alignment: Alignment.center,
          child: const Icon(Icons.person, size: 80, color: Colors.white54),
        );
      }
    } else {
      bgColor = contact!.profileColor;
      name = contact.name;
      initial = name.isNotEmpty ? name[0].toUpperCase() : 'U';
      avatarUrl = contact.profilePictureUrl;
      final status = contact.statuses[_currentStatusIndex];
      currentStatusId = status.id;
      time = _formatTime(status.timestamp);
      total = contact.statuses.length;
      current = _currentStatusIndex;

      final lower = (status.imagePath ?? '').toLowerCase();
      final isVideo = (status.statusType == 'video') ||
          lower.endsWith('.mp4') ||
          lower.endsWith('.mov') ||
          lower.endsWith('.avi') ||
          lower.endsWith('.mkv');

      final isAudio = (status.statusType == 'audio') ||
          lower.endsWith('.m4a') ||
          lower.endsWith('.mp3') ||
          lower.endsWith('.aac') ||
          lower.endsWith('.wav');

      if (isVideo && status.imagePath != null && status.imagePath!.isNotEmpty) {
        content = _buildVideoStatusContent(
          videoUrl: status.imagePath!,
          caption: status.text,
          isMyStatus: false,
        );
      } else if (isAudio && status.imagePath != null && status.imagePath!.isNotEmpty) {
        content = _buildAudioStatusContent(
          audioUrl: status.imagePath!,
          caption: status.text,
          bgColor: status.parsedBackgroundColor,
        );
      } else if (status.imagePath != null && status.imagePath!.isNotEmpty) {
        content = _buildMediaStatusContent(
          imageUrl: status.imagePath!,
          caption: status.text,
          isMyStatus: false,
        );
      } else if (status.text != null && status.text!.isNotEmpty) {
        bgColor = status.parsedBackgroundColor;
        content = _buildTextStatusContent(
          text: status.text!,
          bgColor: bgColor,
        );
      } else {
        content = Container(
          color: bgColor,
          alignment: Alignment.center,
          child: Text(initial, style: const TextStyle(fontSize: 100, color: Colors.white, fontWeight: FontWeight.bold)),
        );
      }
    }

    _markStatusViewed(currentStatusId);

    return GestureDetector(
      onTapDown: (_) {
        _pauseCurrentPlayback();
      },
      onTapUp: (d) {
        final x = d.globalPosition.dx;
        final width = MediaQuery.of(context).size.width;
        if (x < width / 3) {
          _previousStatus();
        } else {
          _nextStatus();
        }
      },
      onLongPressStart: (_) {
        setState(() {
          _isHolding = true;
        });
        _pauseCurrentPlayback();
      },
      onLongPressEnd: (_) {
        setState(() {
          _isHolding = false;
        });
        if (!_isMediaLoading) {
          _resumeCurrentPlayback();
        }
      },
      onVerticalDragEnd: (details) {
        if (details.primaryVelocity != null && details.primaryVelocity! < -200) {
          _pauseCurrentPlayback();
          if (widget.isMyStatus) {
            _showViewersSheet(viewers, viewCount);
          } else if (contact != null) {
            final status = contact.statuses.isNotEmpty ? contact.statuses[_currentStatusIndex.clamp(0, contact.statuses.length - 1)] : null;
            _showReplySheet(contact, status);
          }
        }
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(child: content),
          if (!_isHolding) ...[
            _buildTopGradient(),
            _buildBottomGradient(),
            _buildTopHeader(total, current, name, initial, time, bgColor, avatarUrl, currentStatusId),
            if (widget.isMyStatus) _buildMyStatusBottomView(viewCount, viewers),
            if (!widget.isMyStatus && contact != null)
              _buildReplyBox(
                contact,
                contact.statuses.isNotEmpty ? contact.statuses[_currentStatusIndex.clamp(0, contact.statuses.length - 1)] : null,
              ),
          ],
          _buildEmojiBurstOverlay(),
        ],
      ),
    );
  }

  Widget _buildVideoStatusContent({
    required String videoUrl,
    String? caption,
    required bool isMyStatus,
  }) {
    final isInitialized = _videoController != null && _videoController!.value.isInitialized;

    return Container(
      color: Colors.black,
      width: double.infinity,
      height: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (isInitialized)
            Center(
              child: AspectRatio(
                aspectRatio: _videoController!.value.aspectRatio,
                child: VideoPlayer(_videoController!),
              ),
            )
          else if (_videoError)
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline_rounded, color: Colors.white70, size: 48),
                  const SizedBox(height: 12),
                  const Text(
                    'Failed to load video',
                    style: TextStyle(color: Colors.white70, fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 14),
                  ElevatedButton.icon(
                    onPressed: () => _initVideoPlayer(videoUrl),
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text('Retry'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00873C),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                  ),
                ],
              ),
            )
          else
            const Center(
              child: CircularProgressIndicator(color: Colors.white70, strokeWidth: 2.5),
            ),
          if (caption != null && caption.isNotEmpty)
            Positioned(
              bottom: isMyStatus ? 90 : 100,
              left: 0,
              right: 0,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                color: Colors.black.withValues(alpha: 0.6),
                child: Text(
                  caption,
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.white, height: 1.3),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAudioStatusContent({
    required String audioUrl,
    String? caption,
    required Color bgColor,
  }) {
    final posStr = _formatAudioTimer(_audioPosition.inSeconds);
    final durStr = _formatAudioTimer(_audioDuration.inSeconds);

    return Container(
      color: bgColor,
      width: double.infinity,
      height: double.infinity,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: Colors.white24, width: 1),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.graphic_eq_rounded, color: Colors.white, size: 28),
                    const SizedBox(width: 10),
                    Text(
                      'Voice Status',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        if (_isPlayingAudio) {
                          _audioPlayer?.pause();
                        } else {
                          _audioPlayer?.resume();
                        }
                      },
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _isPlayingAudio ? Icons.pause_rounded : Icons.play_arrow_rounded,
                          color: bgColor,
                          size: 32,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          LinearProgressIndicator(
                            value: _customProgressValue,
                            backgroundColor: Colors.white24,
                            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                            minHeight: 4,
                            borderRadius: BorderRadius.circular(2),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(posStr, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                              Text(durStr, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (caption != null && caption.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text(
              caption,
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white, height: 1.3),
            ),
          ],
        ],
      ),
    );
  }

  String _formatAudioTimer(int totalSecs) {
    final m = totalSecs ~/ 60;
    final s = totalSecs % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Widget _buildMediaStatusContent({
    required String imageUrl,
    String? caption,
    required bool isMyStatus,
  }) {
    final isLocalFile = File(imageUrl).existsSync();
    Widget imageWidget;
    if (isLocalFile) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _onMediaLoaded(imageUrl);
      });
      imageWidget = Image.file(
        File(imageUrl),
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.broken_image, size: 60, color: Colors.white54),
                SizedBox(height: 12),
                Text('Failed to load image', style: TextStyle(color: Colors.white54, fontSize: 14)),
              ],
            ),
          );
        },
      );
    } else {
      imageWidget = CachedNetworkImage(
        imageUrl: imageUrl,
        fit: BoxFit.contain,
        imageBuilder: (context, imageProvider) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _onMediaLoaded(imageUrl);
          });
          return Image(image: imageProvider, fit: BoxFit.contain);
        },
        placeholder: (ctx, url) => const Center(
          child: CircularProgressIndicator(color: Colors.white70, strokeWidth: 2.5),
        ),
        errorWidget: (context, url, error) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _onMediaLoaded(imageUrl);
          });
          return const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.broken_image, size: 60, color: Colors.white54),
                SizedBox(height: 12),
                Text('Failed to load image', style: TextStyle(color: Colors.white54, fontSize: 14)),
              ],
            ),
          );
        },
      );
    }

    return Container(
      color: Colors.black,
      width: double.infinity,
      height: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Center(child: imageWidget),
          if (caption != null && caption.isNotEmpty)
            Positioned(
              bottom: isMyStatus ? 90 : 100,
              left: 0,
              right: 0,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                color: Colors.black.withValues(alpha: 0.6),
                child: Text(
                  caption,
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.white, height: 1.3),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTextStatusContent({
    required String text,
    required Color bgColor,
  }) {
    return Container(
      color: bgColor,
      width: double.infinity,
      height: double.infinity,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 120),
      child: SingleChildScrollView(
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            height: 1.3,
          ),
        ),
      ),
    );
  }

  Widget _buildMyStatusBottomView(int viewCount, List<StatusViewerModel> viewers) {
    return Positioned(
      bottom: 20,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Center(
          child: GestureDetector(
            onTap: () {
              _pauseCurrentPlayback();
              _showViewersSheet(viewers, viewCount);
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.keyboard_arrow_up, color: Colors.white70, size: 24),
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.remove_red_eye, color: Colors.white, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        '$viewCount ${viewCount == 1 ? 'view' : 'views'}',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatViewedTime(String? viewedAt) {
    if (viewedAt == null || viewedAt.isEmpty) return 'Recently';
    try {
      final dt = DateTime.parse(viewedAt).toLocal();
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inHours < 1) return '${diff.inMinutes}m ago';
      if (diff.inDays < 1) {
        final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
        final minute = dt.minute.toString().padLeft(2, '0');
        final ampm = dt.hour >= 12 ? 'PM' : 'AM';
        return 'Today at $hour:$minute $ampm';
      }
      return 'Yesterday';
    } catch (_) {
      return 'Recently';
    }
  }

  void _showViewersSheet(List<StatusViewerModel> viewers, int count) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.45,
          minChildSize: 0.3,
          maxChildSize: 0.8,
          builder: (_, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Color(0xFF1E1E1E),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white30,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Row(
                      children: [
                        const Icon(Icons.remove_red_eye, color: Colors.white70, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Viewed by $count',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(color: Colors.white12, height: 1),
                  Expanded(
                    child: viewers.isEmpty
                        ? const Center(
                            child: Text(
                              'No views yet',
                              style: TextStyle(color: Colors.white54, fontSize: 15),
                            ),
                          )
                        : ListView.separated(
                            controller: scrollController,
                            itemCount: viewers.length,
                            separatorBuilder: (_, _) => const Divider(color: Colors.white10, height: 1, indent: 72),
                            itemBuilder: (context, idx) {
                              final v = viewers[idx];
                              final viewerName = (v.displayName != null && v.displayName!.isNotEmpty)
                                  ? v.displayName!
                                  : (v.username != null && v.username!.isNotEmpty ? v.username! : 'Unknown User');
                              final timeStr = _formatViewedTime(v.viewedAt);
                              return ListTile(
                                leading: CircleAvatar(
                                  radius: 20,
                                  backgroundColor: const Color(0xFF00897B),
                                  backgroundImage: (v.profilePictureUrl != null && v.profilePictureUrl!.isNotEmpty)
                                      ? NetworkImage(v.profilePictureUrl!)
                                      : null,
                                  child: (v.profilePictureUrl == null || v.profilePictureUrl!.isEmpty)
                                      ? Text(
                                          viewerName.isNotEmpty ? viewerName[0].toUpperCase() : 'U',
                                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                        )
                                      : null,
                                ),
                                title: Text(
                                  viewerName,
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15),
                                ),
                                subtitle: Text(
                                  timeStr,
                                  style: const TextStyle(color: Colors.white54, fontSize: 13),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    ).then((_) {
      if (mounted && !_isMediaLoading) _resumeCurrentPlayback();
    });
  }

  Widget _buildTopGradient() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      height: 120,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withValues(alpha: 0.7),
              Colors.transparent,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomGradient() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      height: 140,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              Colors.black.withValues(alpha: 0.7),
              Colors.transparent,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopHeader(
    int total,
    int current,
    String name,
    String initial,
    String time,
    Color bgColor,
    String? avatarUrl,
    String? statusId,
  ) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        bottom: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Segmented Progress Bars synced with Video/Audio player controls
            Padding(
              padding: const EdgeInsets.only(top: 8, left: 10, right: 10, bottom: 4),
              child: Row(
                children: List.generate(
                  total,
                  (i) => Expanded(
                    child: Container(
                      height: 2.5,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      child: AnimatedBuilder(
                        animation: _progressController,
                        builder: (_, _) => LinearProgressIndicator(
                          value: i < current
                              ? 1.0
                              : (i == current
                                  ? (_isCustomMedia ? _customProgressValue : _progressController.value)
                                  : 0.0),
                          backgroundColor: Colors.white.withValues(alpha: 0.35),
                          valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // Contact Header Bar
            Padding(
              padding: const EdgeInsets.only(left: 4, right: 8, top: 4, bottom: 4),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
                    onPressed: () => Navigator.pop(context),
                  ),
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: bgColor.withValues(alpha: 0.8),
                    backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
                    child: avatarUrl == null || avatarUrl.isEmpty
                        ? Text(initial, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14))
                        : null,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          time,
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.more_vert, color: Colors.white, size: 24),
                    onPressed: () => _showStatusOptionsMenu(statusId),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendReplyMessage(
    String contactId,
    String contactName,
    String text, {
    StatusItemModel? statusItem,
  }) async {
    try {
      final dashRepo = getIt<DashboardRepository>();
      final socketRepo = getIt<ChatSocketRepository>();

      String messageToSend = text;
      if (statusItem != null) {
        if (statusItem.imagePath != null && statusItem.imagePath!.isNotEmpty) {
          final caption = (statusItem.text != null && statusItem.text!.isNotEmpty)
              ? statusItem.text!
              : 'Media';
          messageToSend = '📷 Status: $caption\n$text';
        } else if (statusItem.text != null && statusItem.text!.isNotEmpty) {
          messageToSend = '📝 Status: "${statusItem.text}"\n$text';
        }
      }

      final result = await dashRepo.startDirectChat(contactId);
      result.when(
        success: (chat) {
          socketRepo.sendMessage(
            conversationId: chat.id,
            type: 'text',
            text: messageToSend,
          );
          if (mounted) {
            context.showSuccessNotification('Reply sent to $contactName');
          }
        },
        failure: (error, _) {
          if (mounted) {
            context.showErrorNotification('Failed to send reply: $error');
          }
        },
      );
    } catch (e) {
      if (mounted) {
        context.showErrorNotification('Failed to send reply: $e');
      }
    }
  }

  void _triggerEmojiBurst(String emoji) {
    final random = math.Random();
    _burstEmoji = emoji;
    _emojiParticles = List.generate(22, (i) {
      return _EmojiBurstParticle(
        startX: 0.15 + random.nextDouble() * 0.70,
        driftX: (random.nextDouble() - 0.5) * 140,
        size: 28 + random.nextDouble() * 26,
        speed: 0.75 + random.nextDouble() * 0.55,
        opacityPeak: 0.85 + random.nextDouble() * 0.15,
        delay: random.nextDouble() * 0.28,
        wobbleFreq: 2.0 + random.nextDouble() * 3.0,
      );
    });
    _emojiBurstController.forward(from: 0.0);
    try {
      HapticFeedback.mediumImpact();
    } catch (_) {}
    if (mounted) setState(() {});
  }

  Widget _buildEmojiBurstOverlay() {
    if (_burstEmoji == null) return const SizedBox.shrink();

    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _emojiBurstController,
        builder: (context, _) {
          final progress = _emojiBurstController.value;
          if (progress >= 1.0 || progress <= 0.0) {
            return const SizedBox.shrink();
          }

          final size = MediaQuery.of(context).size;

          // Central badge pop animation (0.0 -> 0.4 scale up, 0.4 -> 0.8 sustain, 0.8 -> 1.0 fade)
          double centerScale = 0.0;
          double centerOpacity = 0.0;
          if (progress < 0.25) {
            final t = progress / 0.25;
            centerScale = Curves.easeOutBack.transform(t) * 1.3;
            centerOpacity = t;
          } else if (progress < 0.65) {
            centerScale = 1.3;
            centerOpacity = 1.0;
          } else {
            final t = (progress - 0.65) / 0.35;
            centerScale = 1.3 + t * 0.3;
            centerOpacity = (1.0 - t).clamp(0.0, 1.0);
          }

          return Stack(
            fit: StackFit.expand,
            children: [
              // ─── Central Large Reaction Pop ───
              Center(
                child: Opacity(
                  opacity: centerOpacity,
                  child: Transform.scale(
                    scale: centerScale,
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.45),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.35),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Text(
                        _burstEmoji!,
                        style: const TextStyle(fontSize: 64),
                      ),
                    ),
                  ),
                ),
              ),

              // ─── Floating Particle Stream ───
              ..._emojiParticles.map((p) {
                if (progress < p.delay) return const SizedBox.shrink();

                final adjustedT = ((progress - p.delay) / (1.0 - p.delay)).clamp(0.0, 1.0);
                final curY = size.height * (0.85 - (adjustedT * p.speed * 0.85));
                final curX = (size.width * p.startX) +
                    (p.driftX * math.sin(adjustedT * math.pi * p.wobbleFreq));

                double particleOpacity = 1.0;
                if (adjustedT < 0.15) {
                  particleOpacity = (adjustedT / 0.15) * p.opacityPeak;
                } else if (adjustedT > 0.65) {
                  particleOpacity = ((1.0 - adjustedT) / 0.35) * p.opacityPeak;
                } else {
                  particleOpacity = p.opacityPeak;
                }

                final particleScale = 0.5 + (adjustedT * 0.7);

                return Positioned(
                  left: curX,
                  top: curY,
                  child: Opacity(
                    opacity: particleOpacity.clamp(0.0, 1.0),
                    child: Transform.scale(
                      scale: particleScale,
                      child: Text(
                        _burstEmoji!,
                        style: TextStyle(fontSize: p.size),
                      ),
                    ),
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }

  void _showReplySheet(StatusContactModel contact, StatusItemModel? statusItem) {
    _pauseCurrentPlayback();
    final textController = TextEditingController();
    final emojis = ['❤️', '😂', '😮', '😢', '🙏', '👏', '🔥', '💯'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            decoration: const BoxDecoration(
              color: Color(0xFF1E1E1E),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.white30,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                SizedBox(
                  height: 48,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: emojis.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 10),
                    itemBuilder: (context, idx) {
                      final emoji = emojis[idx];
                      return GestureDetector(
                        onTap: () {
                          Navigator.pop(ctx);
                          _triggerEmojiBurst(emoji);
                          _sendReplyMessage(contact.contactId, contact.name, emoji, statusItem: statusItem);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(22),
                          ),
                          child: Center(
                            child: Text(emoji, style: const TextStyle(fontSize: 24)),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: TextField(
                          controller: textController,
                          style: const TextStyle(color: Colors.white),
                          autofocus: true,
                          decoration: InputDecoration(
                            hintText: 'Reply to ${contact.name}...',
                            hintStyle: const TextStyle(color: Colors.white54),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.send_rounded, color: Color(0xFF00897B)),
                      onPressed: () {
                        final text = textController.text.trim();
                        if (text.isNotEmpty) {
                          Navigator.pop(ctx);
                          _sendReplyMessage(contact.contactId, contact.name, text, statusItem: statusItem);
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    ).then((_) {
      if (mounted && !_isMediaLoading) _resumeCurrentPlayback();
    });
  }

  Widget _buildReplyBox(StatusContactModel contact, StatusItemModel? statusItem) {
    return Positioned(
      bottom: 20,
      left: 16,
      right: 16,
      child: SafeArea(
        child: GestureDetector(
          onTap: () => _showReplySheet(contact, statusItem),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white24),
            ),
            child: Row(
              children: [
                const Icon(Icons.keyboard_arrow_up, color: Colors.white70, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Reply to ${contact.name}...',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.inMinutes < 1) return "Just now";
    if (diff.inHours < 1) return "${diff.inMinutes}m ago";
    if (diff.inDays < 1) {
      final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
      final minute = time.minute.toString().padLeft(2, '0');
      final ampm = time.hour >= 12 ? 'PM' : 'AM';
      return 'Today at $hour:$minute $ampm';
    }
    return "Yesterday";
  }
}

class _EmojiBurstParticle {
  final double startX;
  final double driftX;
  final double size;
  final double speed;
  final double opacityPeak;
  final double delay;
  final double wobbleFreq;

  _EmojiBurstParticle({
    required this.startX,
    required this.driftX,
    required this.size,
    required this.speed,
    required this.opacityPeak,
    required this.delay,
    required this.wobbleFreq,
  });
}
