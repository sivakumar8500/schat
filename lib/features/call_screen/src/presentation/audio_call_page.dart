import 'package:schat/utils/common_colors.dart';
import 'package:schat/utils/common_fontstyles.dart';
import 'package:schat/utils/common_spaces.dart';
import 'dart:async';
import 'package:flutter/material.dart';

class AudioCallPage extends StatefulWidget {
  final String contactName;
  final Color contactColor;

  const AudioCallPage({
    super.key,
    required this.contactName,
    required this.contactColor,
  });

  @override
  State<AudioCallPage> createState() => _AudioCallPageState();
}

class _AudioCallPageState extends State<AudioCallPage> {
  int _seconds = 0;
  Timer? _timer;
  bool _isMuted = false;
  bool _isSpeaker = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _seconds++;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String get _formattedTime {
    final int minutes = _seconds ~/ 60;
    final int remainingSeconds = _seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.primary.withValues(alpha: 0.1),
      body: SafeArea(
        child: Column(
          children: [
            CommonSpaces.h60,
            Text(
              widget.contactName,
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: context.colors.textPrimary,
              ),
            ),
            CommonSpaces.h8,
            Text(
              _formattedTime,
              style: context.titleMedium.copyWith(
                fontWeight: FontWeight.w500,
                color: context.colors.textSecondary,
              ),
            ),
            const Spacer(),
            // Large Avatar
            Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.contactColor.withValues(alpha: 0.2),
                boxShadow: [
                  BoxShadow(
                    color: widget.contactColor.withValues(alpha: 0.3),
                    blurRadius: 40,
                    spreadRadius: 10,
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  widget.contactName.substring(0, 1),
                  style: context.h1.copyWith(
                    fontSize: 80,
                    color: widget.contactColor,
                  ),
                ),
              ),
            ),
            const Spacer(),
            
            // Controls
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 40),
              decoration: BoxDecoration(
                color: context.colors.scaffoldBackground,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(40),
                  topRight: Radius.circular(40),
                ),
                boxShadow: [
                  BoxShadow(
                    color: context.colors.textPrimary.withValues(alpha: 0.12),
                    blurRadius: 20,
                    offset: Offset(0, -10),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildControlButton(
                    icon: _isMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
                    isActive: _isMuted,
                    onTap: () {
                      setState(() {
                        _isMuted = !_isMuted;
                      });
                    },
                  ),
                  _buildControlButton(
                    icon: Icons.call_end_rounded,
                    color: context.colors.error,
                    iconColor: context.colors.scaffoldBackground,
                    size: 72,
                    onTap: () {
                      Navigator.pop(context);
                    },
                  ),
                  _buildControlButton(
                    icon: _isSpeaker ? Icons.volume_up_rounded : Icons.volume_down_rounded,
                    isActive: _isSpeaker,
                    onTap: () {
                      setState(() {
                        _isSpeaker = !_isSpeaker;
                      });
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onTap,
    bool isActive = false,
    Color? color,
    Color? iconColor,
    double size = 56,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color ?? (isActive ? context.colors.primary : context.colors.lightBackground),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: iconColor ?? (isActive ? context.colors.scaffoldBackground : context.colors.textSecondary),
          size: size * 0.45,
        ),
      ),
    );
  }
}
