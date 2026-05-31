import 'package:schat/utils/common_sizes.dart';

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:schat/features/status_screen/src/domain/status_model.dart';

class StatusViewPage extends StatefulWidget {
  final List<StatusContactModel> contacts;
  final int initialIndex;

  // Optional fields for "My Status" when it's not yet uploaded to a backend
  final Uint8List? myBytes;
  final String? myPath;
  final String? myText;
  final bool isMyStatus;

  const StatusViewPage({
    super.key,
    required this.contacts,
    this.initialIndex = 0,
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
      Navigator.pop(context);
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
    if (widget.isMyStatus) return;

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
      return _buildViewer(null);
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
    Color bgColor = Colors.black;
    String name = "My Status";
    String time = "Just now";
    String initial = "M";
    int total = 1;
    int current = 0;
    
    Widget content;

    if (widget.isMyStatus) {
      if (widget.myBytes != null) {
        content = Image.memory(widget.myBytes!, fit: BoxFit.contain);
      } else if (widget.myText != null) {
        bgColor = Colors.blueAccent;
        content = Container(
          color: bgColor,
          alignment: Alignment.center,
          padding: const EdgeInsets.all(40),
          child: Text(
            widget.myText!,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        );
      } else {
        content = const Center(child: Text('T', style: TextStyle(fontSize: 100, color: Colors.white)));
      }
    } else {
      bgColor = contact!.profileColor;
      name = contact.name;
      initial = name[0];
      final status = contact.statuses[_currentStatusIndex];
      time = _formatTime(status.timestamp);
      total = contact.statuses.length;
      current = _currentStatusIndex;

      if (status.text != null) {
        content = Container(
          color: status.backgroundColor,
          alignment: Alignment.center,
          padding: const EdgeInsets.all(40),
          child: Text(
            status.text!,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        );
      } else {
        content = Container(color: bgColor, child: Center(child: Text(initial, style: const TextStyle(fontSize: 100, color: Colors.white))));
      }
    }

    return GestureDetector(
      onTapDown: (_) => _progressController.stop(),
      onTapUp: (d) {
        final x = d.globalPosition.dx;
        final width = MediaQuery.of(context).size.width;
        if (x < width / 3) {
          _previousStatus();
        } else {
          _nextStatus();
        }
      },
      onLongPressStart: (_) => _progressController.stop(),
      onLongPressEnd: (_) => _progressController.forward(),
      child: Stack(
        children: [
          Positioned.fill(child: content),
          _buildTopGradient(),
          if (!widget.isMyStatus) _buildBottomGradient(),
          _buildProgressBars(total, current),
          _buildHeader(name, initial, time, bgColor),
          if (!widget.isMyStatus) _buildReplyBox(),
        ],
      ),
    );
  }

  Widget _buildTopGradient() {
    return Positioned(
      top: 0, left: 0, right: 0, height: 140,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
            colors: [Colors.black.withValues(alpha: 0.6), Colors.transparent],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomGradient() {
    return Positioned(
      bottom: 0, left: 0, right: 0, height: 100,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter, end: Alignment.topCenter,
            colors: [Colors.black.withValues(alpha: 0.6), Colors.transparent],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressBars(int total, int current) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(top: 8, left: 8, right: 8),
        child: Row(
          children: List.generate(total, (i) => Expanded(
            child: Container(
              height: 2.5,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              child: AnimatedBuilder(
                animation: _progressController,
                builder: (_, _) => LinearProgressIndicator(
                  value: i < current ? 1 : (i == current ? _progressController.value : 0),
                  backgroundColor: Colors.white.withValues(alpha: 0.3),
                  valueColor: const AlwaysStoppedAnimation(Colors.white),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          )),
        ),
      ),
    );
  }

  Widget _buildHeader(String name, String initial, String time, Color bgColor) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(top: 20, left: 16, right: 12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: bgColor.withValues(alpha: 0.7),
              child: Text(initial, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: CommonSizes.p12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                  Text(time, style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12)),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReplyBox() {
    return Positioned(
      bottom: 0, left: 0, right: 0,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                  ),
                  child: const Text('Reply to status...', style: TextStyle(color: Colors.white70)),
                ),
              ),
              const SizedBox(width: CommonSizes.p12),
              GestureDetector(
                onTap: () {},
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(color: Colors.white24, shape: BoxShape.circle),
                  child: const Icon(Icons.send_rounded, color: Colors.white),
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
