import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:schat/utils/common_fontstyles.dart';

/// Top-level isolate tasks for compute()
Map<String, dynamic>? _decodeImageInfoTask(Uint8List bytes) {
  final decoded = img.decodeImage(bytes);
  if (decoded == null) return null;
  return {
    'width': decoded.width,
    'height': decoded.height,
  };
}

Uint8List _rotateImageTask(Map<String, dynamic> params) {
  final bytes = params['bytes'] as Uint8List;
  final angle = params['angle'] as int;
  final decoded = img.decodeImage(bytes);
  if (decoded == null) return bytes;
  final rotated = img.copyRotate(decoded, angle: angle);
  return Uint8List.fromList(img.encodeJpg(rotated, quality: 90));
}

Uint8List _flipImageTask(Map<String, dynamic> params) {
  final bytes = params['bytes'] as Uint8List;
  final isHorizontal = params['horizontal'] as bool;
  final decoded = img.decodeImage(bytes);
  if (decoded == null) return bytes;
  final flipped = isHorizontal ? img.flipHorizontal(decoded) : img.flipVertical(decoded);
  return Uint8List.fromList(img.encodeJpg(flipped, quality: 90));
}

Uint8List _cropImageTask(Map<String, dynamic> params) {
  final bytes = params['bytes'] as Uint8List;
  final left = params['left'] as double;
  final top = params['top'] as double;
  final width = params['width'] as double;
  final height = params['height'] as double;
  final quality = params['quality'] as int;

  final decoded = img.decodeImage(bytes);
  if (decoded == null) return bytes;

  final imgW = decoded.width;
  final imgH = decoded.height;

  final cropX = (left.clamp(0.0, 1.0) * imgW).round().clamp(0, imgW - 1);
  final cropY = (top.clamp(0.0, 1.0) * imgH).round().clamp(0, imgH - 1);
  final cropW = (width.clamp(0.01, 1.0) * imgW).round().clamp(1, imgW - cropX);
  final cropH = (height.clamp(0.01, 1.0) * imgH).round().clamp(1, imgH - cropY);

  final cropped = img.copyCrop(
    decoded,
    x: cropX,
    y: cropY,
    width: cropW,
    height: cropH,
  );

  return Uint8List.fromList(img.encodeJpg(cropped, quality: quality));
}

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
  late Uint8List _workingBytes;
  int _imageWidth = 1;
  int _imageHeight = 1;
  bool _isLoading = true;
  bool _isProcessing = false;

  // Normalized crop rectangle: 0.0 to 1.0 within image bounds
  Rect _cropRect = const Rect.fromLTWH(0.05, 0.05, 0.9, 0.9);
  double? _targetAspectRatio; // null = free, 1.0 = square, 4/3, 16/9, etc.

  @override
  void initState() {
    super.initState();
    _workingBytes = widget.imageBytes;
    _decodeImage();
  }

  Future<void> _decodeImage() async {
    setState(() => _isLoading = true);
    try {
      final info = await compute(_decodeImageInfoTask, _workingBytes);
      if (info != null && mounted) {
        setState(() {
          _imageWidth = info['width'] as int;
          _imageHeight = info['height'] as int;
          _isLoading = false;
        });
      } else {
        widget.onCancel();
      }
    } catch (e) {
      debugPrint('Error decoding image info: $e');
      if (mounted) widget.onCancel();
    }
  }

  Future<void> _rotateClockwise() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);
    try {
      final result = await compute(_rotateImageTask, {
        'bytes': _workingBytes,
        'angle': 90,
      });
      if (!mounted) return;
      setState(() {
        _workingBytes = result;
        final temp = _imageWidth;
        _imageWidth = _imageHeight;
        _imageHeight = temp;
        _cropRect = const Rect.fromLTWH(0.05, 0.05, 0.9, 0.9);
        _isProcessing = false;
      });
    } catch (e) {
      debugPrint('Rotate error: $e');
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _flipHorizontal() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);
    try {
      final result = await compute(_flipImageTask, {
        'bytes': _workingBytes,
        'horizontal': true,
      });
      if (!mounted) return;
      setState(() {
        _workingBytes = result;
        _isProcessing = false;
      });
    } catch (e) {
      debugPrint('Flip H error: $e');
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _flipVertical() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);
    try {
      final result = await compute(_flipImageTask, {
        'bytes': _workingBytes,
        'horizontal': false,
      });
      if (!mounted) return;
      setState(() {
        _workingBytes = result;
        _isProcessing = false;
      });
    } catch (e) {
      debugPrint('Flip V error: $e');
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _setAspectRatio(double? ratio) {
    setState(() {
      _targetAspectRatio = ratio;
      if (ratio == null) {
        _cropRect = const Rect.fromLTWH(0.05, 0.05, 0.9, 0.9);
      } else {
        // Compute normalized width and height given visual aspect ratio
        // visualWidth / visualHeight = (normW * imgW) / (normH * imgH) = ratio
        // normW / normH = ratio * (imgH / imgW)
        final normRatio = ratio * (_imageHeight / _imageWidth);
        double w = 0.9;
        double h = w / normRatio;
        if (h > 0.9) {
          h = 0.9;
          w = h * normRatio;
        }
        final l = (1.0 - w) / 2;
        final t = (1.0 - h) / 2;
        _cropRect = Rect.fromLTWH(l, t, w, h);
      }
    });
  }

  Future<void> _applyCrop() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    try {
      final cropped = await compute(_cropImageTask, {
        'bytes': _workingBytes,
        'left': _cropRect.left,
        'top': _cropRect.top,
        'width': _cropRect.width,
        'height': _cropRect.height,
        'quality': 92,
      });

      if (mounted) {
        widget.onCropped(cropped);
      }
    } catch (e) {
      debugPrint('Apply crop error: $e');
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _reset() {
    setState(() {
      _workingBytes = widget.imageBytes;
      _targetAspectRatio = null;
      _cropRect = const Rect.fromLTWH(0.05, 0.05, 0.9, 0.9);
    });
    _decodeImage();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

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
            onPressed: _isProcessing ? null : _applyCrop,
            icon: _isProcessing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.greenAccent,
                    ),
                  )
                : const Icon(Icons.check, color: Colors.greenAccent),
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
      body: Stack(
        children: [
          Column(
            children: [
              // Main Viewport
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final availW = constraints.maxWidth - 32;
                    final availH = constraints.maxHeight - 32;
                    if (availW <= 0 || availH <= 0) return const SizedBox.shrink();

                    final imgAspect = _imageWidth / _imageHeight;
                    final containerAspect = availW / availH;

                    double renderedW;
                    double renderedH;
                    if (imgAspect > containerAspect) {
                      renderedW = availW;
                      renderedH = availW / imgAspect;
                    } else {
                      renderedH = availH;
                      renderedW = availH * imgAspect;
                    }

                    return Center(
                      child: SizedBox(
                        width: renderedW,
                        height: renderedH,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            // Base Image
                            Image.memory(
                              _workingBytes,
                              width: renderedW,
                              height: renderedH,
                              fit: BoxFit.fill,
                              gaplessPlayback: true,
                            ),

                            // Crop Overlay
                            _buildCropOverlay(renderedW, renderedH),
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

              // Transformation Toolbar
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
                      onTap: _reset,
                    ),
                  ],
                ),
              ),
            ],
          ),

          if (_isProcessing)
            Container(
              color: Colors.black45,
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCropOverlay(double w, double h) {
    final left = _cropRect.left * w;
    final top = _cropRect.top * h;
    final rectW = _cropRect.width * w;
    final rectH = _cropRect.height * h;

    const minNormalizedSize = 0.08;

    return Stack(
      children: [
        // Shroud: Dims the area outside crop box
        Positioned.fill(
          child: CustomPaint(
            painter: _ShroudPainter(
              cropRect: Rect.fromLTWH(left, top, rectW, rectH),
            ),
          ),
        ),

        // Interactive Box & Grid Area
        Positioned(
          left: left,
          top: top,
          width: rectW,
          height: rectH,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onPanUpdate: (details) {
              setState(() {
                final dx = details.delta.dx / w;
                final dy = details.delta.dy / h;
                final newL = (_cropRect.left + dx).clamp(0.0, 1.0 - _cropRect.width);
                final newT = (_cropRect.top + dy).clamp(0.0, 1.0 - _cropRect.height);
                _cropRect = Rect.fromLTWH(newL, newT, _cropRect.width, _cropRect.height);
              });
            },
            child: Stack(
              fit: StackFit.expand,
              children: [
                CustomPaint(
                  painter: _CropBoxPainter(),
                ),
              ],
            ),
          ),
        ),

        // 4 Corner Handles with expanded touch targets (44x44)
        _buildHandle(
          left: left - 22,
          top: top - 22,
          alignment: Alignment.topLeft,
          onPanUpdate: (dx, dy) {
            setState(() {
              if (_targetAspectRatio != null) {
                final normRatio = _targetAspectRatio! * (_imageHeight / _imageWidth);
                double deltaX = dx / w;
                double deltaY = dy / h;
                double effectiveDelta = (deltaX.abs() > deltaY.abs()) ? deltaX : deltaY * normRatio;
                double newL = (_cropRect.left + effectiveDelta).clamp(0.0, _cropRect.right - minNormalizedSize);
                double newW = _cropRect.right - newL;
                double newH = newW / normRatio;
                double newT = _cropRect.bottom - newH;
                if (newT < 0.0) {
                  newT = 0.0;
                  newH = _cropRect.bottom;
                  newW = newH * normRatio;
                  newL = _cropRect.right - newW;
                }
                if (newL >= 0.0 && newT >= 0.0 && newW >= minNormalizedSize && newH >= minNormalizedSize) {
                  _cropRect = Rect.fromLTRB(newL, newT, _cropRect.right, _cropRect.bottom);
                }
              } else {
                double newL = (_cropRect.left + dx / w).clamp(0.0, _cropRect.right - minNormalizedSize);
                double newT = (_cropRect.top + dy / h).clamp(0.0, _cropRect.bottom - minNormalizedSize);
                _cropRect = Rect.fromLTRB(newL, newT, _cropRect.right, _cropRect.bottom);
              }
            });
          },
        ),
        _buildHandle(
          left: left + rectW - 22,
          top: top - 22,
          alignment: Alignment.topRight,
          onPanUpdate: (dx, dy) {
            setState(() {
              if (_targetAspectRatio != null) {
                final normRatio = _targetAspectRatio! * (_imageHeight / _imageWidth);
                double deltaX = dx / w;
                double deltaY = -dy / h;
                double effectiveDelta = (deltaX.abs() > deltaY.abs()) ? deltaX : deltaY * normRatio;
                double newR = (_cropRect.right + effectiveDelta).clamp(_cropRect.left + minNormalizedSize, 1.0);
                double newW = newR - _cropRect.left;
                double newH = newW / normRatio;
                double newT = _cropRect.bottom - newH;
                if (newT < 0.0) {
                  newT = 0.0;
                  newH = _cropRect.bottom;
                  newW = newH * normRatio;
                  newR = _cropRect.left + newW;
                }
                if (newR <= 1.0 && newT >= 0.0 && newW >= minNormalizedSize && newH >= minNormalizedSize) {
                  _cropRect = Rect.fromLTRB(_cropRect.left, newT, newR, _cropRect.bottom);
                }
              } else {
                double newR = (_cropRect.right + dx / w).clamp(_cropRect.left + minNormalizedSize, 1.0);
                double newT = (_cropRect.top + dy / h).clamp(0.0, _cropRect.bottom - minNormalizedSize);
                _cropRect = Rect.fromLTRB(_cropRect.left, newT, newR, _cropRect.bottom);
              }
            });
          },
        ),
        _buildHandle(
          left: left - 22,
          top: top + rectH - 22,
          alignment: Alignment.bottomLeft,
          onPanUpdate: (dx, dy) {
            setState(() {
              if (_targetAspectRatio != null) {
                final normRatio = _targetAspectRatio! * (_imageHeight / _imageWidth);
                double deltaX = -dx / w;
                double deltaY = dy / h;
                double effectiveDelta = (deltaX.abs() > deltaY.abs()) ? deltaX : deltaY * normRatio;
                double newL = (_cropRect.left - effectiveDelta).clamp(0.0, _cropRect.right - minNormalizedSize);
                double newW = _cropRect.right - newL;
                double newH = newW / normRatio;
                double newB = _cropRect.top + newH;
                if (newB > 1.0) {
                  newB = 1.0;
                  newH = 1.0 - _cropRect.top;
                  newW = newH * normRatio;
                  newL = _cropRect.right - newW;
                }
                if (newL >= 0.0 && newB <= 1.0 && newW >= minNormalizedSize && newH >= minNormalizedSize) {
                  _cropRect = Rect.fromLTRB(newL, _cropRect.top, _cropRect.right, newB);
                }
              } else {
                double newL = (_cropRect.left + dx / w).clamp(0.0, _cropRect.right - minNormalizedSize);
                double newB = (_cropRect.bottom + dy / h).clamp(_cropRect.top + minNormalizedSize, 1.0);
                _cropRect = Rect.fromLTRB(newL, _cropRect.top, _cropRect.right, newB);
              }
            });
          },
        ),
        _buildHandle(
          left: left + rectW - 22,
          top: top + rectH - 22,
          alignment: Alignment.bottomRight,
          onPanUpdate: (dx, dy) {
            setState(() {
              if (_targetAspectRatio != null) {
                final normRatio = _targetAspectRatio! * (_imageHeight / _imageWidth);
                double deltaX = dx / w;
                double deltaY = dy / h;
                double effectiveDelta = (deltaX.abs() > deltaY.abs()) ? deltaX : deltaY * normRatio;
                double newR = (_cropRect.right + effectiveDelta).clamp(_cropRect.left + minNormalizedSize, 1.0);
                double newW = newR - _cropRect.left;
                double newH = newW / normRatio;
                double newB = _cropRect.top + newH;
                if (newB > 1.0) {
                  newB = 1.0;
                  newH = 1.0 - _cropRect.top;
                  newW = newH * normRatio;
                  newR = _cropRect.left + newW;
                }
                if (newR <= 1.0 && newB <= 1.0 && newW >= minNormalizedSize && newH >= minNormalizedSize) {
                  _cropRect = Rect.fromLTRB(_cropRect.left, _cropRect.top, newR, newB);
                }
              } else {
                double newR = (_cropRect.right + dx / w).clamp(_cropRect.left + minNormalizedSize, 1.0);
                double newB = (_cropRect.bottom + dy / h).clamp(_cropRect.top + minNormalizedSize, 1.0);
                _cropRect = Rect.fromLTRB(_cropRect.left, _cropRect.top, newR, newB);
              }
            });
          },
        ),

        // 4 Edge Handles (Available when aspect ratio is Free)
        if (_targetAspectRatio == null) ...[
          // Top Edge
          _buildEdgeHandle(
            left: left + 22,
            top: top - 15,
            width: rectW > 44 ? rectW - 44 : 10,
            height: 30,
            isHorizontal: true,
            onPanUpdate: (dx, dy) {
              setState(() {
                double newT = (_cropRect.top + dy / h).clamp(0.0, _cropRect.bottom - minNormalizedSize);
                _cropRect = Rect.fromLTRB(_cropRect.left, newT, _cropRect.right, _cropRect.bottom);
              });
            },
          ),
          // Bottom Edge
          _buildEdgeHandle(
            left: left + 22,
            top: top + rectH - 15,
            width: rectW > 44 ? rectW - 44 : 10,
            height: 30,
            isHorizontal: true,
            onPanUpdate: (dx, dy) {
              setState(() {
                double newB = (_cropRect.bottom + dy / h).clamp(_cropRect.top + minNormalizedSize, 1.0);
                _cropRect = Rect.fromLTRB(_cropRect.left, _cropRect.top, _cropRect.right, newB);
              });
            },
          ),
          // Left Edge
          _buildEdgeHandle(
            left: left - 15,
            top: top + 22,
            width: 30,
            height: rectH > 44 ? rectH - 44 : 10,
            isHorizontal: false,
            onPanUpdate: (dx, dy) {
              setState(() {
                double newL = (_cropRect.left + dx / w).clamp(0.0, _cropRect.right - minNormalizedSize);
                _cropRect = Rect.fromLTRB(newL, _cropRect.top, _cropRect.right, _cropRect.bottom);
              });
            },
          ),
          // Right Edge
          _buildEdgeHandle(
            left: left + rectW - 15,
            top: top + 22,
            width: 30,
            height: rectH > 44 ? rectH - 44 : 10,
            isHorizontal: false,
            onPanUpdate: (dx, dy) {
              setState(() {
                double newR = (_cropRect.right + dx / w).clamp(_cropRect.left + minNormalizedSize, 1.0);
                _cropRect = Rect.fromLTRB(_cropRect.left, _cropRect.top, newR, _cropRect.bottom);
              });
            },
          ),
        ],
      ],
    );
  }

  Widget _buildHandle({
    required double left,
    required double top,
    required Alignment alignment,
    required Function(double dx, double dy) onPanUpdate,
  }) {
    return Positioned(
      left: left,
      top: top,
      width: 44,
      height: 44,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanUpdate: (details) => onPanUpdate(details.delta.dx, details.delta.dy),
        child: Center(
          child: Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.black87, width: 2.5),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black45,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEdgeHandle({
    required double left,
    required double top,
    required double width,
    required double height,
    required bool isHorizontal,
    required Function(double dx, double dy) onPanUpdate,
  }) {
    return Positioned(
      left: left,
      top: top,
      width: width,
      height: height,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanUpdate: (details) => onPanUpdate(details.delta.dx, details.delta.dy),
        child: Center(
          child: Container(
            width: isHorizontal ? 28 : 5,
            height: isHorizontal ? 5 : 28,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(3),
              boxShadow: const [
                BoxShadow(color: Colors.black38, blurRadius: 2),
              ],
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
      ..color = Colors.black.withValues(alpha: 0.60)
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

class _CropBoxPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // 1. White boundary border
    final borderPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.85)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), borderPaint);

    // 2. Rule of thirds grid lines
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.35)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    final w1 = size.width / 3;
    final w2 = size.width * 2 / 3;
    final h1 = size.height / 3;
    final h2 = size.height * 2 / 3;

    canvas.drawLine(Offset(w1, 0), Offset(w1, size.height), gridPaint);
    canvas.drawLine(Offset(w2, 0), Offset(w2, size.height), gridPaint);
    canvas.drawLine(Offset(0, h1), Offset(size.width, h1), gridPaint);
    canvas.drawLine(Offset(0, h2), Offset(size.width, h2), gridPaint);

    // 3. Bold corner brackets for pro photo crop UX
    final cornerPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.square
      ..style = PaintingStyle.stroke;

    const cornerLength = 16.0;

    // Top-Left
    canvas.drawLine(const Offset(0, 0), const Offset(cornerLength, 0), cornerPaint);
    canvas.drawLine(const Offset(0, 0), const Offset(0, cornerLength), cornerPaint);

    // Top-Right
    canvas.drawLine(Offset(size.width, 0), Offset(size.width - cornerLength, 0), cornerPaint);
    canvas.drawLine(Offset(size.width, 0), Offset(size.width, cornerLength), cornerPaint);

    // Bottom-Left
    canvas.drawLine(Offset(0, size.height), Offset(cornerLength, size.height), cornerPaint);
    canvas.drawLine(Offset(0, size.height), Offset(0, size.height - cornerLength), cornerPaint);

    // Bottom-Right
    canvas.drawLine(Offset(size.width, size.height), Offset(size.width - cornerLength, size.height), cornerPaint);
    canvas.drawLine(Offset(size.width, size.height), Offset(size.width, size.height - cornerLength), cornerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
