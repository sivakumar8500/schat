import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:schat/utils/common_fontstyles.dart';

class ImageEditorCropView extends StatefulWidget {
  final Uint8List imageBytes;
  final Function(Uint8List croppedBytes) onCropped;
  final VoidCallback onCancel;

  const ImageEditorCropView({
    super.key,
    required this.imageBytes,
    required this.onCropped,
    required this.onCancel,
  });

  @override
  State<ImageEditorCropView> createState() => _ImageEditorCropViewState();
}

class _ImageEditorCropViewState extends State<ImageEditorCropView> {
  late img.Image _workingImage;
  bool _isLoading = true;

  // Normalized crop rectangle: 0.0 to 1.0 within image display
  Rect _cropRect = const Rect.fromLTWH(0.05, 0.05, 0.9, 0.9);
  double? _targetAspectRatio; // null = free, 1.0 = square, 4/3, 16/9

  @override
  void initState() {
    super.initState();
    _decodeImage();
  }

  Future<void> _decodeImage() async {
    final decoded = img.decodeImage(widget.imageBytes);
    if (decoded != null) {
      _workingImage = decoded;
      setState(() {
        _isLoading = false;
      });
    } else {
      widget.onCancel();
    }
  }

  void _rotateClockwise() {
    setState(() {
      _workingImage = img.copyRotate(_workingImage, angle: 90);
      _cropRect = const Rect.fromLTWH(0.05, 0.05, 0.9, 0.9);
    });
  }

  void _flipHorizontal() {
    setState(() {
      _workingImage = img.flipHorizontal(_workingImage);
    });
  }

  void _flipVertical() {
    setState(() {
      _workingImage = img.flipVertical(_workingImage);
    });
  }

  void _setAspectRatio(double? ratio) {
    setState(() {
      _targetAspectRatio = ratio;
      if (ratio == null) {
        _cropRect = const Rect.fromLTWH(0.05, 0.05, 0.9, 0.9);
      } else {
        // Center crop with ratio
        double w = 0.85;
        double h = w / ratio;
        if (h > 0.85) {
          h = 0.85;
          w = h * ratio;
        }
        final l = (1.0 - w) / 2;
        final t = (1.0 - h) / 2;
        _cropRect = Rect.fromLTWH(l, t, w, h);
      }
    });
  }

  Future<void> _applyCrop() async {
    setState(() => _isLoading = true);

    final imgW = _workingImage.width;
    final imgH = _workingImage.height;

    final cropX = (_cropRect.left.clamp(0.0, 1.0) * imgW).round();
    final cropY = (_cropRect.top.clamp(0.0, 1.0) * imgH).round();
    final cropW = (_cropRect.width.clamp(0.05, 1.0) * imgW).round().clamp(1, imgW - cropX);
    final cropH = (_cropRect.height.clamp(0.05, 1.0) * imgH).round().clamp(1, imgH - cropY);

    final cropped = img.copyCrop(
      _workingImage,
      x: cropX,
      y: cropY,
      width: cropW,
      height: cropH,
    );

    final encoded = Uint8List.fromList(img.encodeJpg(cropped, quality: 92));
    widget.onCropped(encoded);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    final previewBytes = Uint8List.fromList(img.encodeJpg(_workingImage, quality: 75));

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: widget.onCancel,
        ),
        title: Text(
          'Crop & Rotate',
          style: context.titleMedium.copyWith(color: Colors.white),
        ),
        actions: [
          TextButton.icon(
            onPressed: _applyCrop,
            icon: const Icon(Icons.check, color: Colors.greenAccent),
            label: Text(
              'Done',
              style: context.bodyMedium.copyWith(
                color: Colors.greenAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Crop Viewport
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Center(
                  child: Container(
                    margin: const EdgeInsets.all(16),
                    constraints: BoxConstraints(
                      maxWidth: constraints.maxWidth - 32,
                      maxHeight: constraints.maxHeight - 32,
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Image
                        Image.memory(
                          previewBytes,
                          fit: BoxFit.contain,
                        ),

                        // Interactive Crop Box & Grid Overlay
                        Positioned.fill(
                          child: _buildCropOverlay(),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Aspect Ratio Presets
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            color: Colors.black87,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _buildRatioChip('Free', null),
                  _buildRatioChip('1:1 Square', 1.0),
                  _buildRatioChip('4:3', 4 / 3),
                  _buildRatioChip('16:9', 16 / 9),
                  _buildRatioChip('3:4', 3 / 4),
                  _buildRatioChip('9:16', 9 / 16),
                ],
              ),
            ),
          ),

          // Transform Toolbar (Rotate, Flip H, Flip V, Reset)
          Container(
            color: Colors.black,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildToolButton(
                  icon: Icons.rotate_right,
                  label: 'Rotate',
                  onTap: _rotateClockwise,
                ),
                _buildToolButton(
                  icon: Icons.flip,
                  label: 'Flip H',
                  onTap: _flipHorizontal,
                ),
                _buildToolButton(
                  icon: Icons.flip_camera_android,
                  label: 'Flip V',
                  onTap: _flipVertical,
                ),
                _buildToolButton(
                  icon: Icons.restart_alt,
                  label: 'Reset',
                  onTap: () {
                    _setAspectRatio(null);
                    _decodeImage();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCropOverlay() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;

        final left = _cropRect.left * w;
        final top = _cropRect.top * h;
        final rectW = _cropRect.width * w;
        final rectH = _cropRect.height * h;

        return Stack(
          children: [
            // Darkened Shroud outside crop rect
            Positioned(
              left: 0,
              top: 0,
              right: 0,
              bottom: 0,
              child: CustomPaint(
                painter: _ShroudPainter(
                  cropRect: Rect.fromLTWH(left, top, rectW, rectH),
                ),
              ),
            ),

            // Draggable Crop Box
            Positioned(
              left: left,
              top: top,
              width: rectW,
              height: rectH,
              child: GestureDetector(
                onPanUpdate: (details) {
                  setState(() {
                    final dx = details.delta.dx / w;
                    final dy = details.delta.dy / h;
                    double newL = (_cropRect.left + dx).clamp(0.0, 1.0 - _cropRect.width);
                    double newT = (_cropRect.top + dy).clamp(0.0, 1.0 - _cropRect.height);
                    _cropRect = Rect.fromLTWH(newL, newT, _cropRect.width, _cropRect.height);
                  });
                },
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                  child: Stack(
                    children: [
                      // Grid 3x3
                      Positioned.fill(
                        child: CustomPaint(
                          painter: _GridPainter(),
                        ),
                      ),

                      // Corner Handles
                      _buildCornerHandle(Alignment.topLeft, (dx, dy) {
                        setState(() {
                          double newL = (_cropRect.left + dx / w).clamp(0.0, _cropRect.right - 0.1);
                          double newT = (_cropRect.top + dy / h).clamp(0.0, _cropRect.bottom - 0.1);
                          _cropRect = Rect.fromLTRB(newL, newT, _cropRect.right, _cropRect.bottom);
                        });
                      }),
                      _buildCornerHandle(Alignment.topRight, (dx, dy) {
                        setState(() {
                          double newR = (_cropRect.right + dx / w).clamp(_cropRect.left + 0.1, 1.0);
                          double newT = (_cropRect.top + dy / h).clamp(0.0, _cropRect.bottom - 0.1);
                          _cropRect = Rect.fromLTRB(_cropRect.left, newT, newR, _cropRect.bottom);
                        });
                      }),
                      _buildCornerHandle(Alignment.bottomLeft, (dx, dy) {
                        setState(() {
                          double newL = (_cropRect.left + dx / w).clamp(0.0, _cropRect.right - 0.1);
                          double newB = (_cropRect.bottom + dy / h).clamp(_cropRect.top + 0.1, 1.0);
                          _cropRect = Rect.fromLTRB(newL, _cropRect.top, _cropRect.right, newB);
                        });
                      }),
                      _buildCornerHandle(Alignment.bottomRight, (dx, dy) {
                        setState(() {
                          double newR = (_cropRect.right + dx / w).clamp(_cropRect.left + 0.1, 1.0);
                          double newB = (_cropRect.bottom + dy / h).clamp(_cropRect.top + 0.1, 1.0);
                          _cropRect = Rect.fromLTRB(_cropRect.left, _cropRect.top, newR, newB);
                        });
                      }),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCornerHandle(Alignment align, Function(double dx, double dy) onDrag) {
    return Align(
      alignment: align,
      child: GestureDetector(
        onPanUpdate: (details) => onDrag(details.delta.dx, details.delta.dy),
        child: Container(
          width: 28,
          height: 28,
          color: Colors.transparent,
          child: Center(
            child: Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.black, width: 2),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRatioChip(String title, double? ratio) {
    final isSelected = _targetAspectRatio == ratio;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(title),
        selected: isSelected,
        onSelected: (_) => _setAspectRatio(ratio),
        selectedColor: Colors.white,
        backgroundColor: Colors.white12,
        labelStyle: context.bodySmall.copyWith(
          color: isSelected ? Colors.black : Colors.white,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildToolButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: context.bodySmall.copyWith(color: Colors.white70, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShroudPainter extends CustomPainter {
  final Rect cropRect;
  _ShroudPainter({required this.cropRect});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withValues(alpha: 0.55)
      ..style = PaintingStyle.fill;

    final fullPath = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final cropPath = Path()..addRect(cropRect);
    final combined = Path.combine(PathOperation.difference, fullPath, cropPath);

    canvas.drawPath(combined, paint);
  }

  @override
  bool shouldRepaint(covariant _ShroudPainter oldDelegate) =>
      oldDelegate.cropRect != cropRect;
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.35)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    final w1 = size.width / 3;
    final w2 = size.width * 2 / 3;
    final h1 = size.height / 3;
    final h2 = size.height * 2 / 3;

    canvas.drawLine(Offset(w1, 0), Offset(w1, size.height), paint);
    canvas.drawLine(Offset(w2, 0), Offset(w2, size.height), paint);
    canvas.drawLine(Offset(0, h1), Offset(size.width, h1), paint);
    canvas.drawLine(Offset(0, h2), Offset(size.width, h2), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
