import 'dart:math' as math;
import 'package:flutter/material.dart';

class RadarScanWidget extends StatefulWidget {
  final double size;
  final String? statusText;

  const RadarScanWidget({
    super.key,
    this.size = 200,
    this.statusText,
  });

  @override
  State<RadarScanWidget> createState() => _RadarScanWidgetState();
}

class _RadarScanWidgetState extends State<RadarScanWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: widget.size,
          height: widget.size,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return CustomPaint(
                painter: _RadarPainter(progress: _controller.value),
              );
            },
          ),
        ),
        if (widget.statusText != null) ...[
          const SizedBox(height: 12),
          Text(
            widget.statusText!,
            style: const TextStyle(
              color: Color(0xFF00FF66),
              fontFamily: 'monospace',
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ],
    );
  }
}

class _RadarPainter extends CustomPainter {
  final double progress;

  _RadarPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 4;

    // 1. Dark Radar Background Circle
    final bgPaint = Paint()
      ..color = const Color(0xFF021B0A)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, bgPaint);

    // 2. Concentric Green Target Rings
    final ringPaint = Paint()
      ..color = const Color(0xFF00FF66).withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    for (int i = 1; i <= 4; i++) {
      canvas.drawCircle(center, radius * (i / 4), ringPaint);
    }

    // Outer Border Ring
    final outerRingPaint = Paint()
      ..color = const Color(0xFF00FF66)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawCircle(center, radius, outerRingPaint);

    // 3. Radar Crosshairs (X and Y axes)
    final gridPaint = Paint()
      ..color = const Color(0xFF00FF66).withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawLine(
      Offset(center.dx - radius, center.dy),
      Offset(center.dx + radius, center.dy),
      gridPaint,
    );
    canvas.drawLine(
      Offset(center.dx, center.dy - radius),
      Offset(center.dx, center.dy + radius),
      gridPaint,
    );

    // Diagonal grid lines
    final diagRadius = radius * 0.7071; // radius * cos(45 deg)
    canvas.drawLine(
      Offset(center.dx - diagRadius, center.dy - diagRadius),
      Offset(center.dx + diagRadius, center.dy + diagRadius),
      gridPaint,
    );
    canvas.drawLine(
      Offset(center.dx - diagRadius, center.dy + diagRadius),
      Offset(center.dx + diagRadius, center.dy - diagRadius),
      gridPaint,
    );

    // 4. Outer Dial Tick Marks
    final tickPaint = Paint()
      ..color = const Color(0xFF00FF66).withValues(alpha: 0.6)
      ..strokeWidth = 1.5;

    const int totalTicks = 36;
    for (int i = 0; i < totalTicks; i++) {
      final angle = (i * 2 * math.pi) / totalTicks;
      final isMajor = i % 9 == 0;
      final tickLength = isMajor ? 8.0 : 4.0;

      final startX = center.dx + (radius - tickLength) * math.cos(angle);
      final startY = center.dy + (radius - tickLength) * math.sin(angle);
      final endX = center.dx + radius * math.cos(angle);
      final endY = center.dy + radius * math.sin(angle);

      canvas.drawLine(Offset(startX, startY), Offset(endX, endY), tickPaint);
    }

    // 5. Rotating Sweeping Beam (Sweep Gradient)
    final sweepAngle = progress * 2 * math.pi;

    final sweepPaint = Paint()
      ..shader = SweepGradient(
        center: Alignment.center,
        startAngle: 0.0,
        endAngle: math.pi / 2, // 90 degree sweep trailing beam
        colors: [
          const Color(0xFF00FF66).withValues(alpha: 0.0),
          const Color(0xFF00FF66).withValues(alpha: 0.15),
          const Color(0xFF00FF66).withValues(alpha: 0.55),
        ],
        stops: const [0.0, 0.5, 1.0],
        transform: GradientRotation(sweepAngle - math.pi / 2),
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawCircle(center, radius, sweepPaint);

    // Leading Sweep Line
    final sweepLinePaint = Paint()
      ..color = const Color(0xFF00FF66)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    final leadingLineEnd = Offset(
      center.dx + radius * math.cos(sweepAngle),
      center.dy + radius * math.sin(sweepAngle),
    );
    canvas.drawLine(center, leadingLineEnd, sweepLinePaint);

    // Center Bright Dot
    final centerDotPaint = Paint()
      ..color = const Color(0xFF00FF66)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 4, centerDotPaint);

    // 6. Blips / Threat Dots
    final blipPaint = Paint()
      ..color = const Color(0xFF00FF66)
      ..style = PaintingStyle.fill;

    final blips = [
      Offset(center.dx + radius * 0.4, center.dy - radius * 0.3),
      Offset(center.dx - radius * 0.5, center.dy + radius * 0.2),
      Offset(center.dx + radius * 0.2, center.dy + radius * 0.6),
    ];

    for (var blip in blips) {
      canvas.drawCircle(blip, 3.5, blipPaint);
      canvas.drawCircle(
        blip,
        6.0,
        Paint()
          ..color = const Color(0xFF00FF66).withValues(alpha: 0.3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RadarPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
