import 'package:flutter/material.dart';

class AnimatedTagline extends StatefulWidget {
  final double fontSize;
  final FontWeight fontWeight;
  final double letterSpacing;
  final Color? baseColor;
  final Color? highlightColor;
  final bool showShieldIcon;
  final MainAxisAlignment mainAxisAlignment;

  const AnimatedTagline({
    super.key,
    this.fontSize = 13.0,
    this.fontWeight = FontWeight.w600,
    this.letterSpacing = 0.4,
    this.baseColor,
    this.highlightColor,
    this.showShieldIcon = false,
    this.mainAxisAlignment = MainAxisAlignment.center,
  });

  @override
  State<AnimatedTagline> createState() => _AnimatedTaglineState();
}

class _AnimatedTaglineState extends State<AnimatedTagline>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultBase = widget.baseColor ??
        (isDark ? Colors.white70 : const Color(0xFF4B5563));
    final defaultHighlight = widget.highlightColor ??
        (isDark ? const Color(0xFF00A859) : const Color(0xFF00873C));

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final shimmerValue = _controller.value;
        return Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: widget.mainAxisAlignment,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (widget.showShieldIcon) ...[
              ShaderMask(
                shaderCallback: (bounds) {
                  return LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      defaultBase,
                      defaultHighlight,
                      defaultBase,
                    ],
                    stops: [
                      (shimmerValue - 0.3).clamp(0.0, 1.0),
                      shimmerValue.clamp(0.0, 1.0),
                      (shimmerValue + 0.3).clamp(0.0, 1.0),
                    ],
                  ).createShader(bounds);
                },
                child: Icon(
                  Icons.shield_outlined,
                  size: widget.fontSize + 2,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 5),
            ],
            ShaderMask(
              blendMode: BlendMode.srcIn,
              shaderCallback: (bounds) {
                return LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    defaultBase,
                    defaultHighlight,
                    defaultBase,
                  ],
                  stops: [
                    (shimmerValue - 0.35).clamp(0.0, 1.0),
                    shimmerValue.clamp(0.0, 1.0),
                    (shimmerValue + 0.35).clamp(0.0, 1.0),
                  ],
                ).createShader(bounds);
              },
              child: Text(
                'Secure today - Safe Tomorrow',
                style: TextStyle(
                  fontSize: widget.fontSize,
                  fontWeight: widget.fontWeight,
                  letterSpacing: widget.letterSpacing,
                  color: defaultBase,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        );
      },
    );
  }
}
