import 'package:flutter/material.dart';
import 'package:schat/utils/common_colors.dart';
import 'package:schat/features/dashboard_screen/src/presentation/dashboard_page.dart';

class MeshBackground extends StatelessWidget {
  final Widget child;
  const MeshBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = context.colors.isDark;

    return Stack(
      children: [
        // Base background color
        Positioned.fill(
          child: Container(
            color: context.colors.scaffoldBackground,
          ),
        ),

        // Home Wave Lines Background matching Home Screen (Top-Right & Bottom-Left)
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: HomeBackgroundWavePainter(isDark: isDark),
            ),
          ),
        ),

        // Main content
        Positioned.fill(child: child),
      ],
    );
  }
}

