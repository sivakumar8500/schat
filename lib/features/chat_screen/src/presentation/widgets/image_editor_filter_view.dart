import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:schat/utils/common_fontstyles.dart';

enum ImageFilterPreset {
  original,
  vivid,
  warm,
  cool,
  grayscale,
  vintage,
  invert,
}

class ImageEditorFilterView extends StatefulWidget {
  final Uint8List imageBytes;
  final Function(Uint8List filteredBytes) onApplied;
  final VoidCallback onCancel;

  const ImageEditorFilterView({
    super.key,
    required this.imageBytes,
    required this.onApplied,
    required this.onCancel,
  });

  @override
  State<ImageEditorFilterView> createState() => _ImageEditorFilterViewState();
}

class _ImageEditorFilterViewState extends State<ImageEditorFilterView> {
  late img.Image _baseImage;
  Uint8List? _previewBytes;
  ImageFilterPreset _currentPreset = ImageFilterPreset.original;
  bool _isLoading = true;
  bool _isApplying = false;

  final List<_PresetItem> _presets = const [
    _PresetItem(ImageFilterPreset.original, 'Original', Icons.image),
    _PresetItem(ImageFilterPreset.vivid, 'Vivid', Icons.flash_on),
    _PresetItem(ImageFilterPreset.warm, 'Warm', Icons.wb_sunny),
    _PresetItem(ImageFilterPreset.cool, 'Cool', Icons.ac_unit),
    _PresetItem(ImageFilterPreset.grayscale, 'B&W', Icons.filter_b_and_w),
    _PresetItem(ImageFilterPreset.vintage, 'Vintage', Icons.camera_roll),
    _PresetItem(ImageFilterPreset.invert, 'Invert', Icons.invert_colors),
  ];

  @override
  void initState() {
    super.initState();
    _decode();
  }

  Future<void> _decode() async {
    final decoded = img.decodeImage(widget.imageBytes);
    if (decoded != null) {
      _baseImage = decoded;
      _previewBytes = widget.imageBytes;
      setState(() {
        _isLoading = false;
      });
    } else {
      widget.onCancel();
    }
  }

  Future<void> _selectPreset(ImageFilterPreset preset) async {
    if (preset == _currentPreset) return;
    setState(() {
      _currentPreset = preset;
      _isApplying = true;
    });

    final applied = _applyFilterToImage(_baseImage.clone(), preset);
    final encoded = Uint8List.fromList(img.encodeJpg(applied, quality: 80));

    if (mounted) {
      setState(() {
        _previewBytes = encoded;
        _isApplying = false;
      });
    }
  }

  img.Image _applyFilterToImage(img.Image src, ImageFilterPreset preset) {
    switch (preset) {
      case ImageFilterPreset.original:
        return src;
      case ImageFilterPreset.vivid:
        return img.adjustColor(src, contrast: 1.25, saturation: 1.35, brightness: 1.05);
      case ImageFilterPreset.warm:
        return img.sepia(src, amount: 0.55);
      case ImageFilterPreset.cool:
        return img.adjustColor(src, gamma: 1.1, saturation: 0.9);
      case ImageFilterPreset.grayscale:
        return img.grayscale(src);
      case ImageFilterPreset.vintage:
        final sep = img.sepia(src, amount: 0.35);
        return img.adjustColor(sep, contrast: 1.15, brightness: 0.95);
      case ImageFilterPreset.invert:
        return img.invert(src);
    }
  }

  void _onDone() {
    if (_currentPreset == ImageFilterPreset.original) {
      widget.onApplied(widget.imageBytes);
      return;
    }
    final applied = _applyFilterToImage(_baseImage.clone(), _currentPreset);
    final encoded = Uint8List.fromList(img.encodeJpg(applied, quality: 92));
    widget.onApplied(encoded);
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
          'Filters & Effects',
          style: context.titleMedium.copyWith(color: Colors.white),
        ),
        actions: [
          TextButton.icon(
            onPressed: _onDone,
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
          // Image Preview
          Expanded(
            child: Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (_previewBytes != null)
                    Image.memory(
                      _previewBytes!,
                      fit: BoxFit.contain,
                    ),
                  if (_isApplying)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const CircularProgressIndicator(color: Colors.white),
                    ),
                ],
              ),
            ),
          ),

          // Presets Carousel
          Container(
            color: Colors.black,
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: _presets.map((item) {
                  final isSelected = _currentPreset == item.preset;
                  return Padding(
                    padding: const EdgeInsets.only(right: 14),
                    child: InkWell(
                      onTap: () => _selectPreset(item.preset),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: 72,
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.white24 : Colors.white10,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? Colors.greenAccent : Colors.transparent,
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              item.icon,
                              color: isSelected ? Colors.greenAccent : Colors.white70,
                              size: 26,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              item.title,
                              style: context.bodySmall.copyWith(
                                color: isSelected ? Colors.white : Colors.white70,
                                fontSize: 11,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PresetItem {
  final ImageFilterPreset preset;
  final String title;
  final IconData icon;
  const _PresetItem(this.preset, this.title, this.icon);
}
