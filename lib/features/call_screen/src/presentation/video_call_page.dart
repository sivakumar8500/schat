import 'package:schat/utils/common_colors.dart';
import 'package:schat/utils/common_spaces.dart';
import 'package:schat/utils/common_fontstyles.dart';
import 'package:schat/utils/common_icons.dart';
import 'package:flutter/material.dart';

class VideoCallPage extends StatefulWidget {
  final String contactName;

  const VideoCallPage({
    super.key,
    required this.contactName,
  });

  @override
  State<VideoCallPage> createState() => _VideoCallPageState();
}

class _VideoCallPageState extends State<VideoCallPage> {
  bool _isMuted = false;
  bool _isVideoOff = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.textPrimary,
      body: Stack(
        children: [
          // Simulated Remote Video Feed (Background)
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [context.colors.videoCallGradientStart, context.colors.videoCallGradientEnd],
              ),
            ),
            child: Center(
              child: Icon(CommonIcons.person, size: 200, color: context.colors.scaffoldBackground.withValues(alpha: 0.1)),
            ),
          ),
          
          // Simulated Local Video Feed (Picture in Picture)
          Positioned(
            top: 60,
            right: 24,
            child: Container(
              width: 110,
              height: 160,
              decoration: BoxDecoration(
                color: context.colors.border,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: context.colors.scaffoldBackground.withValues(alpha: 0.24), width: 2),
                boxShadow: [
                  BoxShadow(color: context.colors.textSecondary, blurRadius: 15, offset: const Offset(0, 5)),
                ],
              ),
              child: _isVideoOff
                  ? Center(child: Icon(CommonIcons.videocamOff, color: context.colors.scaffoldBackground.withValues(alpha: 0.54), size: 40))
                  : Center(child: Text('You', style: context.titleSmall.copyWith(color: context.colors.scaffoldBackground.withValues(alpha: 0.54), fontWeight: FontWeight.bold))),
            ),
          ),

          // Top Header (Contact Name & Back Button)
          Positioned(
            top: 60,
            left: 16,
            child: Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: context.colors.textSecondary,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: Icon(CommonIcons.arrowBack, color: context.colors.scaffoldBackground, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                CommonSpaces.w12,
                Text(
                  widget.contactName,
                  style: context.titleLarge.copyWith(
                    color: context.colors.scaffoldBackground,
                    shadows: [Shadow(color: context.colors.textSecondary, blurRadius: 10)],
                  ),
                ),
              ],
            ),
          ),

          // Bottom Controls
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildControlButton(
                  icon: CommonIcons.flipCamera,
                  onTap: () {},
                ),
                _buildControlButton(
                  icon: _isVideoOff ? CommonIcons.videocamOff : CommonIcons.videocam,
                  isActive: _isVideoOff,
                  onTap: () {
                    setState(() {
                      _isVideoOff = !_isVideoOff;
                    });
                  },
                ),
                _buildControlButton(
                  icon: _isMuted ? CommonIcons.micOff : CommonIcons.mic,
                  isActive: _isMuted,
                  onTap: () {
                    setState(() {
                      _isMuted = !_isMuted;
                    });
                  },
                ),
                _buildControlButton(
                  icon: CommonIcons.callEnd,
                  color: context.colors.error,
                  iconColor: context.colors.scaffoldBackground,
                  size: 64,
                  onTap: () {
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
        ],
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
          color: color ?? (isActive ? context.colors.scaffoldBackground : context.colors.textSecondary),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: iconColor ?? (isActive ? context.colors.textPrimary : context.colors.scaffoldBackground),
          size: size * 0.45,
        ),
      ),
    );
  }
}
