import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:schat/features/status_screen/src/presentation/bloc/status_bloc.dart';
import 'package:schat/features/status_screen/src/presentation/bloc/status_event.dart';

class TextStatusCreatorPage extends StatefulWidget {
  const TextStatusCreatorPage({super.key});

  @override
  State<TextStatusCreatorPage> createState() => _TextStatusCreatorPageState();
}

class _TextStatusCreatorPageState extends State<TextStatusCreatorPage> {
  final TextEditingController _textController = TextEditingController();
  
  final List<Color> _presetColors = const [
    Color(0xFF4A148C), // Deep Purple
    Color(0xFF00695C), // Teal
    Color(0xFF1A237E), // Navy Blue
    Color(0xFF880E4F), // Pink / Burgundy
    Color(0xFFE65100), // Orange
    Color(0xFF37474F), // Blue Grey
    Color(0xFFB71C1C), // Crimson Red
    Color(0xFF2E7D32), // Forest Green
  ];

  int _selectedColorIndex = 0;

  Color get _currentColor => _presetColors[_selectedColorIndex];

  String _colorToHex(Color color) {
    return '#${color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
  }


  void _cycleColor() {
    setState(() {
      _selectedColorIndex = (_selectedColorIndex + 1) % _presetColors.length;
    });
  }

  void _postStatus() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    final hexColor = _colorToHex(_currentColor);
    context.read<StatusBloc>().add(
          UploadTextStatusEvent(
            text: text,
            textColor: hexColor,
          ),
        );
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      color: _currentColor,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close, color: Colors.white, size: 28),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            // Color palette switcher button
            IconButton(
              icon: const Icon(Icons.color_lens_outlined, color: Colors.white, size: 28),
              tooltip: 'Change Background Color',
              onPressed: _cycleColor,
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              children: [
                // Color dots bar at top
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_presetColors.length, (index) {
                      final isSelected = index == _selectedColorIndex;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedColorIndex = index;
                          });
                        },
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: isSelected ? 32 : 24,
                          height: isSelected ? 32 : 24,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _presetColors[index],
                            border: Border.all(
                              color: Colors.white,
                              width: isSelected ? 3 : 1.5,
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
                const SizedBox(height: 32),

                // Text Input area
                Expanded(
                  child: Center(
                    child: TextField(
                      controller: _textController,
                      maxLines: null,
                      textAlign: TextAlign.center,
                      autofocus: true,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        height: 1.3,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'Type a status...',
                        hintStyle: TextStyle(
                          color: Colors.white54,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _postStatus,
          backgroundColor: Colors.white,
          elevation: 6,
          child: Icon(
            Icons.send,
            color: _currentColor,
          ),
        ),
      ),
    );
  }
}
