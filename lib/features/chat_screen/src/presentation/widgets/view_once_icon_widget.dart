import 'dart:math';
import 'package:flutter/material.dart';

class ViewOnceIconWidget extends StatelessWidget {
  final int count;
  final bool isActive;
  final bool isOpened;
  final double size;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const ViewOnceIconWidget({
    super.key,
    this.count = 1,
    this.isActive = false,
    this.isOpened = false,
    this.size = 28.0,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    Color ringColor;
    Color textColor;
    Color? fillColor;

    if (isOpened) {
      ringColor = const Color(0xFF8696A0);
      textColor = const Color(0xFF8696A0);
      fillColor = Colors.transparent;
    } else if (isActive) {
      ringColor = const Color(0xFF00A884);
      textColor = Colors.white;
      fillColor = const Color(0xFF00A884);
    } else {
      ringColor = const Color(0xFF8696A0);
      textColor = const Color(0xFF8696A0);
      fillColor = Colors.transparent;
    }

    Widget content = SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _DashedCirclePainter(
          color: ringColor,
          fillColor: fillColor,
          strokeWidth: max(1.5, size * 0.075),
          dashCount: isOpened ? 16 : 8,
          isDashed: !isActive && !isOpened,
        ),
        child: Center(
          child: Text(
            '$count',
            style: TextStyle(
              color: textColor,
              fontSize: size * 0.48,
              fontWeight: FontWeight.w800,
              fontFamily: 'Inter',
              height: 1.0,
            ),
          ),
        ),
      ),
    );

    if (onTap != null || onLongPress != null) {
      content = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        onLongPress: onLongPress,
        child: content,
      );
    }

    return content;
  }
}

class _DashedCirclePainter extends CustomPainter {
  final Color color;
  final Color? fillColor;
  final double strokeWidth;
  final int dashCount;
  final bool isDashed;

  _DashedCirclePainter({
    required this.color,
    this.fillColor,
    required this.strokeWidth,
    required this.dashCount,
    required this.isDashed,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (min(size.width, size.height) - strokeWidth) / 2;

    if (fillColor != null && fillColor != Colors.transparent) {
      final fillPaint = Paint()
        ..color = fillColor!
        ..style = PaintingStyle.fill;
      canvas.drawCircle(center, radius + strokeWidth / 2, fillPaint);
    }

    final strokePaint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    if (!isDashed) {
      canvas.drawCircle(center, radius, strokePaint);
      return;
    }

    final totalCircumference = 2 * pi * radius;
    final dashLength = totalCircumference / (dashCount * 2);
    final sweepAngle = (dashLength / totalCircumference) * (2 * pi);
    final spaceAngle = sweepAngle;

    for (int i = 0; i < dashCount; i++) {
      final startAngle = -pi / 2 + (i * (sweepAngle + spaceAngle));
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        strokePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DashedCirclePainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.fillColor != fillColor ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.isDashed != isDashed;
  }
}
