import 'dart:math' as math;
import 'package:flutter/material.dart';

class AnimatedGlowingBorderCard extends StatefulWidget {
  final Widget child;
  final bool isSpeaking;
  final double borderRadius;
  final double borderWidth;
  final EdgeInsetsGeometry padding;
  final Color baseColor;

  const AnimatedGlowingBorderCard({
    super.key,
    required this.child,
    required this.isSpeaking,
    this.borderRadius = 20.0,
    this.borderWidth = 2.5,
    this.padding = const EdgeInsets.all(12.0),
    this.baseColor = const Color(0xFF1E2922),
  });

  @override
  State<AnimatedGlowingBorderCard> createState() => _AnimatedGlowingBorderCardState();
}

class _AnimatedGlowingBorderCardState extends State<AnimatedGlowingBorderCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );
    if (widget.isSpeaking) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant AnimatedGlowingBorderCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSpeaking && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.isSpeaking && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isSpeaking) {
      return Container(
        padding: widget.padding,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(widget.borderRadius),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.18),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: widget.child,
      );
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return CustomPaint(
          painter: _RotatingGradientBorderPainter(
            animationValue: _controller.value,
            borderRadius: widget.borderRadius,
            borderWidth: widget.borderWidth,
          ),
          child: Container(
            padding: widget.padding,
            decoration: BoxDecoration(
              color: widget.baseColor,
              borderRadius: BorderRadius.circular(widget.borderRadius),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00A859).withValues(alpha: 0.35),
                  blurRadius: 16,
                  spreadRadius: 1,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: widget.child,
          ),
        );
      },
    );
  }
}

class _RotatingGradientBorderPainter extends CustomPainter {
  final double animationValue;
  final double borderRadius;
  final double borderWidth;

  _RotatingGradientBorderPainter({
    required this.animationValue,
    required this.borderRadius,
    required this.borderWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(borderRadius));

    final sweepGradient = SweepGradient(
      center: Alignment.center,
      startAngle: 0.0,
      endAngle: math.pi * 2,
      transform: GradientRotation(animationValue * math.pi * 2),
      colors: const [
        Color(0xFF00A859),
        Color(0xFF34C759),
        Color(0xFF00E676),
        Color(0xFF10B981),
        Color(0xFF00A859),
      ],
      stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
    );

    final paint = Paint()
      ..shader = sweepGradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;

    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(covariant _RotatingGradientBorderPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}
