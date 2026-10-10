import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:schat/utils/common_fontstyles.dart';

class DrawnLine {
  final List<Offset> points;
  final Color color;
  final double width;

  DrawnLine({
    required this.points,
    required this.color,
    required this.width,
  });
}

class OverlayTextItem {
  String id;
  String text;
  Offset position;
  Color color;
  double fontSize;

  OverlayTextItem({
    required this.id,
    required this.text,
    required this.position,
    required this.color,
    this.fontSize = 24.0,
  });
}

class ImageEditorDoodleView extends StatefulWidget {
  final Uint8List imageBytes;
  final Function(Uint8List editedBytes) onApplied;
  final VoidCallback onCancel;

  const ImageEditorDoodleView({
    super.key,
    required this.imageBytes,
    required this.onApplied,
    required this.onCancel,
  });

  @override
  State<ImageEditorDoodleView> createState() => _ImageEditorDoodleViewState();
}

class _ImageEditorDoodleViewState extends State<ImageEditorDoodleView> {
  final GlobalKey _repaintBoundaryKey = GlobalKey();
  final List<DrawnLine> _lines = [];
  final List<OverlayTextItem> _textOverlays = [];

  Color _selectedColor = const Color(0xFF00E676);
  double _strokeWidth = 6.0;
  ui.Image? _decodedImage;
  bool _isLoading = true;
  bool _isSaving = false;

  final List<Color> _palette = const [
    Colors.white,
    Color(0xFF212121),
    Color(0xFFFF1744),
    Color(0xFFFF5252),
    Color(0xFFFF9100),
    Color(0xFFFFEA00),
    Color(0xFF00E676),
    Color(0xFF00E5FF),
    Color(0xFF2979FF),
    Color(0xFFD500F9),
  ];

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    try {
      final codec = await ui.instantiateImageCodec(widget.imageBytes);
      final frame = await codec.getNextFrame();
      if (mounted) {
        setState(() {
          _decodedImage = frame.image;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error decoding image for doodle editor: $e');
      if (mounted) {
        widget.onCancel();
      }
    }
  }

  void _undo() {
    if (_lines.isNotEmpty) {
      setState(() {
        _lines.removeLast();
      });
    } else if (_textOverlays.isNotEmpty) {
      setState(() {
        _textOverlays.removeLast();
      });
    }
  }

  void _showAddTextDialog([OverlayTextItem? existingItem]) {
    final controller = TextEditingController(text: existingItem?.text ?? '');
    Color textColor = existingItem?.color ?? _selectedColor;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            backgroundColor: const Color(0xFF1E1E1E),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text(
              existingItem != null ? 'Edit Text' : 'Add Text',
              style: context.titleMedium.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: controller,
                  autofocus: true,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Enter text here...',
                    hintStyle: const TextStyle(color: Colors.white38),
                    filled: true,
                    fillColor: Colors.black26,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _palette.map((c) {
                    final isSel = textColor == c;
                    return GestureDetector(
                      onTap: () => setDialogState(() => textColor = c),
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: c,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSel ? Colors.white : Colors.white24,
                            width: isSel ? 3 : 1,
                          ),
                          boxShadow: isSel
                              ? [BoxShadow(color: c.withValues(alpha: 0.6), blurRadius: 6)]
                              : null,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
            actions: [
              if (existingItem != null)
                TextButton(
                  onPressed: () {
                    setState(() {
                      _textOverlays.removeWhere((item) => item.id == existingItem.id);
                    });
                    Navigator.pop(ctx);
                  },
                  child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
                ),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00873C),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  final txt = controller.text.trim();
                  if (txt.isNotEmpty) {
                    setState(() {
                      if (existingItem != null) {
                        existingItem.text = txt;
                        existingItem.color = textColor;
                      } else {
                        _textOverlays.add(
                          OverlayTextItem(
                            id: DateTime.now().millisecondsSinceEpoch.toString(),
                            text: txt,
                            position: const Offset(40, 80),
                            color: textColor,
                          ),
                        );
                      }
                    });
                  }
                  Navigator.pop(ctx);
                },
                child: Text(existingItem != null ? 'Save' : 'Add', style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _renderAndSave() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    try {
      final boundary = _repaintBoundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary != null) {
        // Calculate adaptive pixelRatio to preserve original image quality
        double pixelRatio = 3.0;
        if (_decodedImage != null && boundary.size.width > 0) {
          pixelRatio = (_decodedImage!.width / boundary.size.width).clamp(1.5, 4.0);
        }

        final ui.Image renderedImg = await boundary.toImage(pixelRatio: pixelRatio);
        final ByteData? byteData = await renderedImg.toByteData(format: ui.ImageByteFormat.png);

        if (byteData != null) {
          widget.onApplied(byteData.buffer.asUint8List());
          return;
        }
      }
    } catch (e) {
      debugPrint('Error rendering doodle: $e');
    }

    if (mounted) {
      setState(() => _isSaving = false);
      widget.onCancel();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Color(0xFF00873C))),
      );
    }

    final imgW = _decodedImage?.width.toDouble() ?? 1.0;
    final imgH = _decodedImage?.height.toDouble() ?? 1.0;
    final aspectRatio = imgW / imgH;

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
          'Draw & Edit',
          style: context.titleMedium.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.undo, color: Colors.white),
            tooltip: 'Undo',
            onPressed: (_lines.isNotEmpty || _textOverlays.isNotEmpty) ? _undo : null,
          ),
          IconButton(
            icon: const Icon(Icons.title_rounded, color: Colors.white),
            tooltip: 'Add Text',
            onPressed: () => _showAddTextDialog(),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton.icon(
              onPressed: _isSaving ? null : _renderAndSave,
              icon: _isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.check_circle_rounded, color: Color(0xFF00E676)),
              label: Text(
                'Done',
                style: context.bodyMedium.copyWith(
                  color: const Color(0xFF00E676),
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Drawing Canvas Area
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: AspectRatio(
                  aspectRatio: aspectRatio,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: RepaintBoundary(
                      key: _repaintBoundaryKey,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          // Background Image
                          Image.memory(
                            widget.imageBytes,
                            fit: BoxFit.fill,
                          ),

                          // Custom Brush Drawing Layer
                          Positioned.fill(
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onPanStart: (details) {
                                setState(() {
                                  _lines.add(
                                    DrawnLine(
                                      points: [details.localPosition],
                                      color: _selectedColor,
                                      width: _strokeWidth,
                                    ),
                                  );
                                });
                              },
                              onPanUpdate: (details) {
                                setState(() {
                                  if (_lines.isNotEmpty) {
                                    _lines.last.points.add(details.localPosition);
                                  }
                                });
                              },
                              child: CustomPaint(
                                painter: _DoodlePainter(lines: _lines),
                              ),
                            ),
                          ),

                          // Draggable & Editable Text Overlays
                          ..._textOverlays.map((item) {
                            return Positioned(
                              left: item.position.dx,
                              top: item.position.dy,
                              child: GestureDetector(
                                onTap: () => _showAddTextDialog(item),
                                onPanUpdate: (details) {
                                  setState(() {
                                    item.position += details.delta;
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.5),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.white38, width: 1),
                                  ),
                                  child: Text(
                                    item.text,
                                    style: TextStyle(
                                      color: item.color,
                                      fontSize: item.fontSize,
                                      fontWeight: FontWeight.bold,
                                      shadows: const [
                                        Shadow(color: Colors.black, blurRadius: 4, offset: Offset(1, 1)),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Palette and Stroke Width Controls
          Container(
            color: const Color(0xFF141414),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Color Palette
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _palette.map((c) {
                      final isSel = _selectedColor == c;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 5),
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedColor = c),
                          child: Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: c,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSel ? Colors.white : Colors.white24,
                                width: isSel ? 3.5 : 1,
                              ),
                              boxShadow: isSel
                                  ? [BoxShadow(color: c.withValues(alpha: 0.7), blurRadius: 8)]
                                  : null,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 12),

                // Stroke Width Chips
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildStrokeChip('Fine', 3.0),
                    const SizedBox(width: 12),
                    _buildStrokeChip('Medium', 6.0),
                    const SizedBox(width: 12),
                    _buildStrokeChip('Thick', 12.0),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStrokeChip(String title, double width) {
    final isSelected = _strokeWidth == width;
    return ChoiceChip(
      label: Text(title),
      selected: isSelected,
      onSelected: (_) => setState(() => _strokeWidth = width),
      selectedColor: const Color(0xFF00873C),
      backgroundColor: Colors.white12,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.white70,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        fontSize: 12,
      ),
    );
  }
}

class _DoodlePainter extends CustomPainter {
  final List<DrawnLine> lines;
  _DoodlePainter({required this.lines});

  @override
  void paint(Canvas canvas, Size size) {
    for (final line in lines) {
      if (line.points.isEmpty) continue;
      final paint = Paint()
        ..color = line.color
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = line.width
        ..style = PaintingStyle.stroke;

      if (line.points.length == 1) {
        canvas.drawCircle(line.points.first, line.width / 2, paint..style = PaintingStyle.fill);
      } else {
        final path = Path();
        path.moveTo(line.points.first.dx, line.points.first.dy);
        for (int i = 1; i < line.points.length; i++) {
          path.lineTo(line.points[i].dx, line.points[i].dy);
        }
        canvas.drawPath(path, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DoodlePainter oldDelegate) => true;
}
