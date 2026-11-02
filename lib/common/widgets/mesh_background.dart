import 'package:flutter/material.dart';
import 'package:schat/common/widgets/app_home_background.dart';

class MeshBackground extends StatelessWidget {
  final Widget child;
  const MeshBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // App background matching Home Screen
        const Positioned.fill(
          child: IgnorePointer(
            child: AppHomeBackground(),
          ),
        ),

        // Main content
        Positioned.fill(child: child),
      ],
    );
  }
}
