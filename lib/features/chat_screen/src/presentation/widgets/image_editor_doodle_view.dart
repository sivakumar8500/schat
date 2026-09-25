import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
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
  String text;
  Offset position;
  Color color;
  double fontSize;

  OverlayTextItem({
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
  final List<DrawnLine> _lines = [];
  final List<OverlayTextItem> _textOverlays = [];

  Color _selectedColor = Colors.redAccent;
  double _strokeWidth = 6.0;
  final bool _isTextMode = false;
  ui.Image? _decodedImage;
  bool _isLoading = true;

  final List<Color> _palette = const [
    Colors.white,
    Colors.black,
    Colors.redAccent,
    Colors.orangeAccent,
    Colors.amber,
    Colors.greenAccent,
    Colors.cyanAccent,
    Colors.blueAccent,
    Colors.purpleAccent,
    Colors.pinkAccent,
  ];

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    final codec = await ui.instantiateImageCodec(widget.imageBytes);
    final frame = await codec.getNextFrame();
    if (mounted) {
      setState(() {
        _decodedImage = frame.image;
        _isLoading = false;
      });
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

  void _showAddTextDialog() {
    final controller = TextEditingController();
    Color textColor = _selectedColor;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            backgroundColor: Colors.grey[900],
            title: Text('Add Text', style: context.titleMedium.copyWith(color: Colors.white)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: controller,
                  autofocus: true,
                  style: TextStyle(color: textColor, fontSize: 20, fontWeight: FontWeight.bold),
                  decoration: const InputDecoration(
                    hintText: 'Enter text here...',
                    hintStyle: TextStyle(color: Colors.white38),
                    border: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white54)),
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
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: c,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSel ? Colors.white : Colors.white24,
                            width: isSel ? 2.5 : 1,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.greenAccent),
                onPressed: () {
                  final txt = controller.text.trim();
                  if (txt.isNotEmpty) {
                    setState(() {
                      _textOverlays.add(
                        OverlayTextItem(
                          text: txt,
                          position: const Offset(50, 100),
                          color: textColor,
                        ),
                      );
                    });
                  }
                  Navigator.pop(ctx);
                },
                child: const Text('Add', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _renderAndSave(Size canvasSize) async {
    if (_decodedImage == null) {
      widget.onCancel();
      return;
    }

    setState(() => _isLoading = true);

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    final imgW = _decodedImage!.width.toDouble();
    final imgH = _decodedImage!.height.toDouble();

    // Draw background image full resolution
    canvas.drawImage(_decodedImage!, Offset.zero, Paint());

    // Compute scale factor between on-screen preview canvas and original image
    final scaleX = imgW / canvasSize.width;
    final scaleY = imgH / canvasSize.height;

    // Draw lines scaled
    for (final line in _lines) {
      final paint = Paint()
        ..color = line.color
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = line.width * scaleX
        ..style = PaintingStyle.stroke;

      final path = Path();
      if (line.points.isNotEmpty) {
        path.moveTo(line.points.first.dx * scaleX, line.points.first.dy * scaleY);
        for (int i = 1; i < line.points.length; i++) {
          path.lineTo(line.points[i].dx * scaleX, line.points[i].dy * scaleY);
        }
      }
      canvas.drawPath(path, paint);
    }

    // Draw text overlays scaled
    for (final item in _textOverlays) {
      final textSpan = TextSpan(
        text: item.text,
        style: TextStyle(
          color: item.color,
          fontSize: item.fontSize * scaleX,
          fontWeight: FontWeight.bold,
          shadows: const [
            Shadow(color: Colors.black87, blurRadius: 4, offset: Offset(2, 2)),
          ],
        ),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      )..layout();

      textPainter.paint(canvas, Offset(item.position.dx * scaleX, item.position.dy * scaleY));
    }

    final picture = recorder.endRecording();
    final renderedImg = await picture.toImage(imgW.toInt(), imgH.toInt());
    final byteData = await renderedImg.toByteData(format: ui.ImageByteFormat.png);

    if (byteData != null) {
      widget.onApplied(byteData.buffer.asUint8List());
    } else {
      widget.onCancel();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: const Center(child: CircularProgressIndicator(color: Colors.white)),
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
          _isTextMode ? 'Add Text' : 'Draw & Doodle',
          style: context.titleMedium.copyWith(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.undo, color: Colors.white),
            tooltip: 'Undo',
            onPressed: (_lines.isNotEmpty || _textOverlays.isNotEmpty) ? _undo : null,
          ),
          IconButton(
            icon: const Icon(Icons.title, color: Colors.white),
            tooltip: 'Add Text',
            onPressed: _showAddTextDialog,
          ),
          LayoutBuilder(
            builder: (ctx, constraints) {
              return TextButton.icon(
                onPressed: () {
                  final renderBox = ctx.findRenderObject() as RenderBox?;
                  final size = renderBox?.size ?? const Size(360, 600);
                  _renderAndSave(size);
                },
                icon: const Icon(Icons.check, color: Colors.greenAccent),
                label: Text(
                  'Done',
                  style: context.bodyMedium.copyWith(
                    color: Colors.greenAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Drawing Canvas Area
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Center(
                  child: Container(
                    margin: const EdgeInsets.all(12),
                    constraints: BoxConstraints(
                      maxWidth: constraints.maxWidth - 24,
                      maxHeight: constraints.maxHeight - 24,
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Background image
                        Image.memory(
                          widget.imageBytes,
                          fit: BoxFit.contain,
                        ),

                        // Interactive Drawing Gesture Area
                        Positioned.fill(
                          child: GestureDetector(
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

                        // Draggable Text Overlays
                        ..._textOverlays.map((item) {
                          return Positioned(
                            left: item.position.dx,
                            top: item.position.dy,
                            child: GestureDetector(
                              onPanUpdate: (details) {
                                setState(() {
                                  item.position += details.delta;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.black45,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.white30, width: 1),
                                ),
                                child: Text(
                                  item.text,
                                  style: TextStyle(
                                    color: item.color,
                                    fontSize: item.fontSize,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Palette and Stroke Width bar
          Container(
            color: Colors.black,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: c,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSel ? Colors.white : Colors.white24,
                                width: isSel ? 3 : 1,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 12),

                // Stroke Width Picker
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
      selectedColor: Colors.white,
      backgroundColor: Colors.white12,
      labelStyle: TextStyle(
        color: isSelected ? Colors.black : Colors.white,
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
      final paint = Paint()
        ..color = line.color
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = line.width
        ..style = PaintingStyle.stroke;

      final path = Path();
      if (line.points.isNotEmpty) {
        path.moveTo(line.points.first.dx, line.points.first.dy);
        for (int i = 1; i < line.points.length; i++) {
          path.lineTo(line.points[i].dx, line.points[i].dy);
        }
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _DoodlePainter oldDelegate) => true;
}
