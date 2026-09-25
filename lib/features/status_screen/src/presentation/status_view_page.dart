import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
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

class _StatusViewPageState extends State<StatusViewPage> with SingleTickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _progressController;
  int _currentContactIndex = 0;
  int _currentStatusIndex = 0;
  bool _isHolding = false;
  final Set<String> _viewedStatusIds = {};

  void _markStatusViewed(String? statusId) {
    if (statusId == null || statusId.isEmpty || widget.isMyStatus) return;
    if (_viewedStatusIds.contains(statusId)) return;
    _viewedStatusIds.add(statusId);
    getIt<StatusRepository>().viewStatus(statusId).catchError((e) {
      debugPrint('Error marking status as viewed: $e');
    });
  }

  void _showStatusOptionsMenu(String? statusId) {
    _progressController.stop();

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
      if (mounted) _progressController.forward();
    });
  }

  Future<void> _confirmAndDeleteStatus(String statusId) async {
    _progressController.stop();
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
      if (mounted) _progressController.forward();
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
        _progressController.forward();
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _currentContactIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentContactIndex);
    
    _progressController = AnimationController(vsync: this, duration: const Duration(seconds: 5));
    _startProgress();
    
    _progressController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _nextStatus();
      }
    });
  }

  void _startProgress() {
    _progressController.forward(from: 0.0);
  }

  void _nextStatus() {
    if (widget.isMyStatus) {
      final list = widget.myStatuses ?? [];
      if (list.isNotEmpty && _currentStatusIndex < list.length - 1) {
        setState(() {
          _currentStatusIndex++;
        });
        _startProgress();
      } else {
        Navigator.pop(context);
      }
      return;
    }

    final contact = widget.contacts[_currentContactIndex];
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
    if (_currentContactIndex < widget.contacts.length - 1) {
      _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    } else {
      Navigator.pop(context);
    }
  }

  void _previousContact() {
    if (_currentContactIndex > 0) {
      _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _progressController.dispose();
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
          setState(() {
            _currentContactIndex = index;
            _currentStatusIndex = 0;
          });
          _startProgress();
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
      final myStatusesList = widget.myStatuses ?? [];
      if (myStatusesList.isNotEmpty) {
        total = myStatusesList.length;
        current = _currentStatusIndex.clamp(0, total - 1);
        final item = myStatusesList[current];
        currentStatusId = item.id;
        time = _formatTime(item.timestamp);
        viewCount = item.viewCount ?? item.viewers.length;
        viewers = item.viewers;

        if (item.imagePath != null && item.imagePath!.isNotEmpty) {
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

      if (status.imagePath != null && status.imagePath!.isNotEmpty) {
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
        _progressController.stop();
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
        _progressController.stop();
      },
      onLongPressEnd: (_) {
        setState(() {
          _isHolding = false;
        });
        _progressController.forward();
      },
      onVerticalDragEnd: (details) {
        if (details.primaryVelocity != null && details.primaryVelocity! < -200) {
          _progressController.stop();
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
        ],
      ),
    );
  }

  Widget _buildMediaStatusContent({
    required String imageUrl,
    String? caption,
    required bool isMyStatus,
  }) {
    final isLocalFile = File(imageUrl).existsSync();
    Widget imageWidget;
    if (isLocalFile) {
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
      imageWidget = Image.network(
        imageUrl,
        fit: BoxFit.contain,
        loadingBuilder: (ctx, child, progress) {
          if (progress == null) return child;
          return const Center(child: CircularProgressIndicator(color: Colors.white70));
        },
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
              _progressController.stop();
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

  void _showViewersSheet(List<StatusViewerModel> viewers, int totalViews) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1E1E1E),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(color: Colors.white30, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            Row(
              children: [
                const Icon(Icons.remove_red_eye, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Text(
                  'Viewed by $totalViews',
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(color: Colors.white24, height: 24),
            if (viewers.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text('No views yet', style: TextStyle(color: Colors.white54, fontSize: 15)),
                ),
              )
            else
              LimitedBox(
                maxHeight: 250,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: viewers.length,
                  itemBuilder: (_, i) {
                    final v = viewers[i];
                    final vName = v.displayName ?? v.username ?? 'Contact';
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: Colors.purple.shade300,
                        child: Text(vName[0].toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                      title: Text(vName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                      subtitle: v.username != null ? Text('@${v.username}', style: const TextStyle(color: Colors.white54, fontSize: 12)) : null,
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    ).then((_) {
      if (mounted) _progressController.forward();
    });
  }

  Widget _buildTopGradient() {
    return Positioned(
      top: 0, left: 0, right: 0, height: 140,
      child: IgnorePointer(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter, end: Alignment.bottomCenter,
              colors: [Colors.black.withValues(alpha: 0.75), Colors.transparent],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomGradient() {
    return Positioned(
      bottom: 0, left: 0, right: 0, height: 150,
      child: IgnorePointer(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomCenter, end: Alignment.topCenter,
              colors: [Colors.black.withValues(alpha: 0.8), Colors.transparent],
            ),
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
            // Segmented Progress Bars
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
                          value: i < current ? 1.0 : (i == current ? _progressController.value : 0.0),
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
              : 'Photo';
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

  void _showReplySheet(StatusContactModel contact, StatusItemModel? statusItem) {
    _progressController.stop();
    final textController = TextEditingController();
    final emojis = ['❤️', '😂', '😮', '😢', '🙏', '👏', '🔥', '💯'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Container(
            decoration: const BoxDecoration(
              color: Color(0xFF1E1E1E),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle
                Center(
                  child: Container(
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white38,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Title
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Reply to ${contact.name}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white70, size: 20),
                      onPressed: () => Navigator.pop(ctx),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Quick Reactions
                SizedBox(
                  height: 48,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: emojis.length,
                    separatorBuilder: (context, index) => const SizedBox(width: 8),
                    itemBuilder: (_, i) {
                      final emoji = emojis[i];
                      return InkWell(
                        onTap: () {
                          Navigator.pop(ctx);
                          _sendReplyMessage(contact.contactId, contact.name, emoji, statusItem: statusItem);
                        },
                        borderRadius: BorderRadius.circular(24),
                        child: Container(
                          width: 44,
                          height: 44,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            emoji,
                            style: const TextStyle(fontSize: 22),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 14),

                // Text Reply Input
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: TextField(
                          controller: textController,
                          style: const TextStyle(color: Colors.white),
                          autofocus: true,
                          textInputAction: TextInputAction.send,
                          onSubmitted: (val) {
                            final text = val.trim();
                            if (text.isNotEmpty) {
                              Navigator.pop(ctx);
                              _sendReplyMessage(contact.contactId, contact.name, text, statusItem: statusItem);
                            }
                          },
                          decoration: const InputDecoration(
                            hintText: 'Type a reply...',
                            hintStyle: TextStyle(color: Colors.white54, fontSize: 14),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      decoration: const BoxDecoration(
                        color: Color(0xFF00873C),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                        onPressed: () {
                          final text = textController.text.trim();
                          if (text.isNotEmpty) {
                            Navigator.pop(ctx);
                            _sendReplyMessage(contact.contactId, contact.name, text, statusItem: statusItem);
                          }
                        },
                      ),
                    ),
                  ],
                ),
                SizedBox(height: MediaQuery.of(ctx).padding.bottom + 8),
              ],
            ),
          ),
        );
      },
    ).then((_) {
      if (mounted) _progressController.forward();
    });
  }

  Widget _buildReplyBox(StatusContactModel contact, StatusItemModel? statusItem) {
    return Positioned(
      bottom: 12, left: 0, right: 0,
      child: SafeArea(
        child: InkWell(
          onTap: () => _showReplySheet(contact, statusItem),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.keyboard_arrow_up, color: Colors.white70, size: 22),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: Colors.white30),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.reply, color: Colors.white70, size: 18),
                            SizedBox(width: 8),
                            Text('Reply', style: TextStyle(color: Colors.white70, fontSize: 14)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
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
}
