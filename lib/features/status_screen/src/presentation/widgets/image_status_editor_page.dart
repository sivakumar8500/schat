import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:schat/features/status_screen/src/presentation/bloc/status_bloc.dart';
import 'package:schat/features/status_screen/src/presentation/bloc/status_event.dart';
import 'package:schat/utils/common_notifications.dart';

/// Represents a single continuous stroke drawn on the canvas
class _DoodleStroke {
  final List<Offset> points;
  final Color color;
  final double strokeWidth;

  _DoodleStroke({
    required this.points,
    required this.color,
    required this.strokeWidth,
  });
}

/// Custom painter to render doodle strokes on the image
class _DoodlePainter extends CustomPainter {
  final List<_DoodleStroke> strokes;
  final _DoodleStroke? currentStroke;

  _DoodlePainter({required this.strokes, this.currentStroke});

  @override
  void paint(Canvas canvas, Size size) {
    final all = [...strokes];
    if (currentStroke != null) all.add(currentStroke!);

    for (final stroke in all) {
      if (stroke.points.isEmpty) continue;
      final paint = Paint()
        ..color = stroke.color
        ..strokeWidth = stroke.strokeWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;

      if (stroke.points.length == 1) {
        canvas.drawCircle(stroke.points.first, stroke.strokeWidth / 2, paint..style = PaintingStyle.fill);
      } else {
        final path = Path();
        path.moveTo(stroke.points.first.dx, stroke.points.first.dy);
        for (int i = 1; i < stroke.points.length; i++) {
          path.lineTo(stroke.points[i].dx, stroke.points[i].dy);
        }
        canvas.drawPath(path, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DoodlePainter oldDelegate) => true;
}

/// Filter matrix definitions
class _FilterPreset {
  final String name;
  final List<double>? matrix;

  const _FilterPreset({required this.name, this.matrix});
}

class ImageStatusEditorPage extends StatefulWidget {
  final String? imagePath;
  final Uint8List? imageBytes;

  const ImageStatusEditorPage({
    super.key,
    this.imagePath,
    this.imageBytes,
  });

  @override
  State<ImageStatusEditorPage> createState() => _ImageStatusEditorPageState();
}

class _ImageStatusEditorPageState extends State<ImageStatusEditorPage> {
  final GlobalKey _repaintBoundaryKey = GlobalKey();
  final TextEditingController _captionController = TextEditingController();
  final FocusNode _captionFocus = FocusNode();

  // Rotation & Flip
  int _rotationQuarterTurns = 0; // 0, 1, 2, 3
  bool _flipHorizontal = false;

  // Drawing state
  bool _isDrawingMode = false;
  Color _selectedPenColor = const Color(0xFF00FF87);
  double _selectedStrokeWidth = 4.0;
  final List<_DoodleStroke> _strokes = [];
  _DoodleStroke? _activeStroke;

  // Filter state
  bool _showFiltersBar = false;
  int _selectedFilterIndex = 0;

  bool _isExporting = false;

  final List<Color> _penColors = const [
    Color(0xFFFFFFFF), // White
    Color(0xFF00FF87), // Emerald / Neon Green
    Color(0xFFFFD600), // Yellow
    Color(0xFFFF3D00), // Bright Orange
    Color(0xFFFF1744), // Crimson Red
    Color(0xFFE040FB), // Magenta / Purple
    Color(0xFF00E5FF), // Cyan Blue
    Color(0xFF212121), // Charcoal Black
  ];

  static const List<_FilterPreset> _filterPresets = [
    _FilterPreset(name: 'Normal', matrix: null),
    _FilterPreset(
      name: 'Vivid',
      matrix: [
        1.25, 0, 0, 0, -10,
        0, 1.25, 0, 0, -10,
        0, 0, 1.25, 0, -10,
        0, 0, 0, 1, 0,
      ],
    ),
    _FilterPreset(
      name: 'Warm',
      matrix: [
        1.15, 0, 0, 0, 15,
        0, 1.05, 0, 0, 5,
        0, 0, 0.90, 0, -15,
        0, 0, 0, 1, 0,
      ],
    ),
    _FilterPreset(
      name: 'Cool',
      matrix: [
        0.90, 0, 0, 0, -10,
        0, 1.05, 0, 0, 5,
        0, 0, 1.20, 0, 20,
        0, 0, 0, 1, 0,
      ],
    ),
    _FilterPreset(
      name: 'B&W',
      matrix: [
        0.2126, 0.7152, 0.0722, 0, 0,
        0.2126, 0.7152, 0.0722, 0, 0,
        0.2126, 0.7152, 0.0722, 0, 0,
        0, 0, 0, 1, 0,
      ],
    ),
    _FilterPreset(
      name: 'Sepia',
      matrix: [
        0.393, 0.769, 0.189, 0, 0,
        0.349, 0.686, 0.168, 0, 0,
        0.272, 0.534, 0.131, 0, 0,
        0, 0, 0, 1, 0,
      ],
    ),
    _FilterPreset(
      name: 'Dramatic',
      matrix: [
        1.35, 0, 0, 0, -35,
        0, 1.35, 0, 0, -35,
        0, 0, 1.35, 0, -35,
        0, 0, 0, 1, 0,
      ],
    ),
    _FilterPreset(
      name: 'Emerald',
      matrix: [
        0.8, 0, 0, 0, 0,
        0, 1.3, 0, 0, 20,
        0, 0, 0.9, 0, 10,
        0, 0, 0, 1, 0,
      ],
    ),
  ];

  @override
  void dispose() {
    _captionController.dispose();
    _captionFocus.dispose();
    super.dispose();
  }

  void _rotateClockwise() {
    setState(() {
      _rotationQuarterTurns = (_rotationQuarterTurns + 1) % 4;
    });
  }

  void _toggleFlip() {
    setState(() {
      _flipHorizontal = !_flipHorizontal;
    });
  }

  void _undoStroke() {
    if (_strokes.isNotEmpty) {
      setState(() {
        _strokes.removeLast();
      });
    }
  }

  void _resetEdits() {
    setState(() {
      _rotationQuarterTurns = 0;
      _flipHorizontal = false;
      _strokes.clear();
      _selectedFilterIndex = 0;
      _isDrawingMode = false;
      _showFiltersBar = false;
    });
  }

  bool get _hasVisualEdits =>
      _rotationQuarterTurns != 0 ||
      _flipHorizontal ||
      _strokes.isNotEmpty ||
      _selectedFilterIndex != 0;

  Future<void> _exportAndUpload() async {
    if (_isExporting) return;
    setState(() => _isExporting = true);

    final caption = _captionController.text.trim();
    final bloc = context.read<StatusBloc>();

    try {
      if (_hasVisualEdits) {
        // Capture rendered canvas with rotations, filters & doodles
        final boundary = _repaintBoundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
        if (boundary != null) {
          final ui.Image image = await boundary.toImage(pixelRatio: 2.5);
          final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
          if (byteData != null) {
            final editedBytes = byteData.buffer.asUint8List();

            String? editedPath;
            if (!kIsWeb) {
              final tempDir = await getTemporaryDirectory();
              final timestamp = DateTime.now().millisecondsSinceEpoch;
              final file = File('${tempDir.path}/edited_status_$timestamp.png');
              await file.writeAsBytes(editedBytes);
              editedPath = file.path;
            }

            if (!mounted) return;
            context.showInfoNotification('Uploading status...');
            bloc.add(UploadMediaStatusEvent(
              path: editedPath ?? widget.imagePath,
              bytes: editedBytes,
              caption: caption.isNotEmpty ? caption : null,
              statusType: 'image',
            ));
            Navigator.pop(context);
            return;
          }
        }
      }

      // Default upload without canvas re-render
      if (!mounted) return;
      context.showInfoNotification('Uploading status...');
      bloc.add(UploadMediaStatusEvent(
        path: widget.imagePath,
        bytes: widget.imageBytes,
        caption: caption.isNotEmpty ? caption : null,
        statusType: 'image',
      ));
      Navigator.pop(context);
    } catch (e) {
      debugPrint('Error exporting edited status image: $e');
      if (mounted) {
        context.showErrorNotification('Failed to process edited image: $e');
        setState(() => _isExporting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeFilter = _filterPresets[_selectedFilterIndex].matrix;

    return Scaffold(
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Center Image Canvas with Drawing & Filters
          Center(
            child: InteractiveViewer(
              minScale: 0.8,
              maxScale: 3.0,
              panEnabled: !_isDrawingMode,
              scaleEnabled: !_isDrawingMode,
              child: RepaintBoundary(
                key: _repaintBoundaryKey,
                child: RotatedBox(
                  quarterTurns: _rotationQuarterTurns,
                  child: Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.diagonal3Values(_flipHorizontal ? -1.0 : 1.0, 1.0, 1.0),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Image Widget with ColorFilter
                        ColorFiltered(
                          colorFilter: activeFilter != null
                              ? ColorFilter.matrix(activeFilter)
                              : const ColorFilter.mode(Colors.transparent, BlendMode.dst),
                          child: _buildSourceImage(),
                        ),

                        // Doodle Drawing Layer
                        Positioned.fill(
                          child: GestureDetector(
                            behavior: _isDrawingMode ? HitTestBehavior.opaque : HitTestBehavior.translucent,
                            onPanStart: _isDrawingMode
                                ? (details) {
                                    setState(() {
                                      _activeStroke = _DoodleStroke(
                                        points: [details.localPosition],
                                        color: _selectedPenColor,
                                        strokeWidth: _selectedStrokeWidth,
                                      );
                                    });
                                  }
                                : null,
                            onPanUpdate: _isDrawingMode
                                ? (details) {
                                    if (_activeStroke != null) {
                                      setState(() {
                                        _activeStroke!.points.add(details.localPosition);
                                      });
                                    }
                                  }
                                : null,
                            onPanEnd: _isDrawingMode
                                ? (_) {
                                    if (_activeStroke != null) {
                                      setState(() {
                                        _strokes.add(_activeStroke!);
                                        _activeStroke = null;
                                      });
                                    }
                                  }
                                : null,
                            child: CustomPaint(
                              painter: _DoodlePainter(
                                strokes: _strokes,
                                currentStroke: _activeStroke,
                              ),
                              size: Size.infinite,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // 2. Top Header Toolbar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _buildTopToolbar(),
          ),

          // 3. Optional Filter Selection Carousel
          if (_showFiltersBar && !_isDrawingMode)
            Positioned(
              bottom: 110,
              left: 0,
              right: 0,
              child: _buildFiltersBar(),
            ),

          // 4. Optional Pen Color & Size Selection Toolbar
          if (_isDrawingMode)
            Positioned(
              bottom: 110,
              left: 0,
              right: 0,
              child: _buildPenToolsBar(),
            ),

          // 5. Bottom Caption & Post Bar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildBottomCaptionBar(),
          ),

          // 6. Loading Overlay during Export
          if (_isExporting)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(color: Color(0xFF00FF87)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSourceImage() {
    if (widget.imageBytes != null) {
      return Image.memory(
        widget.imageBytes!,
        fit: BoxFit.contain,
      );
    } else if (widget.imagePath != null && widget.imagePath!.isNotEmpty) {
      return Image.file(
        File(widget.imagePath!),
        fit: BoxFit.contain,
      );
    } else {
      return const SizedBox(
        width: 300,
        height: 300,
        child: Center(
          child: Icon(Icons.broken_image, color: Colors.white54, size: 60),
        ),
      );
    }
  }

  Widget _buildTopToolbar() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: 0.8),
            Colors.transparent,
          ],
        ),
      ),
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        left: 12,
        right: 12,
        bottom: 24,
      ),
      child: Row(
        children: [
          // Close button
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white, size: 28),
            tooltip: 'Cancel',
            onPressed: () => Navigator.pop(context),
          ),
          const Spacer(),

          // Rotate Clockwise Tool
          IconButton(
            icon: const Icon(Icons.rotate_90_degrees_cw_outlined, color: Colors.white, size: 24),
            tooltip: 'Rotate',
            onPressed: _rotateClockwise,
          ),

          // Flip Horizontal Tool
          IconButton(
            icon: const Icon(Icons.flip_rounded, color: Colors.white, size: 24),
            tooltip: 'Flip',
            onPressed: _toggleFlip,
          ),

          // Filters Tool
          IconButton(
            icon: Icon(
              Icons.auto_fix_high_rounded,
              color: _showFiltersBar ? const Color(0xFF00FF87) : Colors.white,
              size: 24,
            ),
            tooltip: 'Filters',
            onPressed: () {
              setState(() {
                _showFiltersBar = !_showFiltersBar;
                if (_showFiltersBar) _isDrawingMode = false;
              });
            },
          ),

          // Draw / Pen Tool
          IconButton(
            icon: Icon(
              Icons.draw_rounded,
              color: _isDrawingMode ? const Color(0xFF00FF87) : Colors.white,
              size: 24,
            ),
            tooltip: 'Draw',
            onPressed: () {
              setState(() {
                _isDrawingMode = !_isDrawingMode;
                if (_isDrawingMode) _showFiltersBar = false;
              });
            },
          ),

          // Undo Stroke (when drawing exists)
          if (_strokes.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.undo_rounded, color: Colors.white, size: 24),
              tooltip: 'Undo Draw',
              onPressed: _undoStroke,
            ),

          // Reset all edits button
          if (_hasVisualEdits)
            IconButton(
              icon: const Icon(Icons.refresh_rounded, color: Colors.white70, size: 24),
              tooltip: 'Reset All',
              onPressed: _resetEdits,
            ),
        ],
      ),
    );
  }

  Widget _buildFiltersBar() {
    return Container(
      height: 76,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xDD1E1E1E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white12),
        boxShadow: const [
          BoxShadow(color: Colors.black45, blurRadius: 12, offset: Offset(0, 4)),
        ],
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _filterPresets.length,
        itemBuilder: (context, index) {
          final filter = _filterPresets[index];
          final isSelected = index == _selectedFilterIndex;
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedFilterIndex = index;
              });
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 6),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF00873C) : Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected ? const Color(0xFF00FF87) : Colors.transparent,
                  width: 1.5,
                ),
              ),
              child: Center(
                child: Text(
                  filter.name,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPenToolsBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
      decoration: BoxDecoration(
        color: const Color(0xDD1E1E1E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white12),
        boxShadow: const [
          BoxShadow(color: Colors.black45, blurRadius: 12, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Color circles
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: _penColors.map((color) {
              final isSelected = color == _selectedPenColor;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedPenColor = color;
                  });
                },
                child: Container(
                  width: isSelected ? 30 : 22,
                  height: isSelected ? 30 : 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color,
                    border: Border.all(
                      color: isSelected ? Colors.white : Colors.white38,
                      width: isSelected ? 2.5 : 1.2,
                    ),
                    boxShadow: isSelected
                        ? [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 8, spreadRadius: 1)]
                        : null,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 10),
          // Brush size selector
          Row(
            children: [
              const Icon(Icons.line_weight_rounded, color: Colors.white70, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 3,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                    activeTrackColor: _selectedPenColor,
                    thumbColor: _selectedPenColor,
                    inactiveTrackColor: Colors.white24,
                  ),
                  child: Slider(
                    value: _selectedStrokeWidth,
                    min: 2.0,
                    max: 16.0,
                    onChanged: (val) {
                      setState(() {
                        _selectedStrokeWidth = val;
                      });
                    },
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomCaptionBar() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            Colors.black.withValues(alpha: 0.9),
            Colors.black.withValues(alpha: 0.6),
            Colors.transparent,
          ],
        ),
      ),
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 18,
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Caption Text Form Field
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(color: Colors.white24, width: 0.8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.add_photo_alternate_outlined, color: Colors.white54, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _captionController,
                        focusNode: _captionFocus,
                        maxLines: 3,
                        minLines: 1,
                        style: const TextStyle(color: Colors.white, fontSize: 15),
                        cursorColor: const Color(0xFF00FF87),
                        decoration: const InputDecoration(
                          hintText: 'Add a caption...',
                          hintStyle: TextStyle(color: Colors.white54, fontSize: 14.5),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),

            // Send / Post Status Button
            GestureDetector(
              onTap: _exportAndUpload,
              child: Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Color(0xFF00C853), Color(0xFF00873C)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x6600C853),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(
                    Icons.send_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
