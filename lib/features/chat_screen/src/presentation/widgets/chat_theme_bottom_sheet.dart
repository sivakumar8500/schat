import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:schat/features/chat_screen/src/domain/models/theme_color_model.dart';
import 'package:schat/features/chat_screen/src/domain/repositories/chat_repository.dart';
import 'package:schat/features/chat_screen/src/presentation/bloc/chat_bloc.dart';
import 'package:schat/features/chat_screen/src/presentation/bloc/chat_event.dart';
import 'package:schat/features/chat_screen/src/presentation/bloc/chat_state.dart';
import 'package:schat/injection.dart';
import 'package:schat/utils/common_colors.dart';
import 'package:schat/utils/common_fonts.dart';
import 'package:schat/utils/common_fontstyles.dart';
import 'package:schat/utils/common_notifications.dart';
import 'package:schat/utils/common_spaces.dart';

/// Pre-seeded curated wallpaper images
const List<Map<String, String>> kPresetWallpapers = [
  {
    'name': 'Dark Geometry',
    'url': 'https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?w=800&auto=format&fit=crop&q=80',
  },
  {
    'name': 'Emerald Waves',
    'url': 'https://images.unsplash.com/photo-1550684848-fac1c5b4e853?w=800&auto=format&fit=crop&q=80',
  },
  {
    'name': 'Cosmic Night',
    'url': 'https://images.unsplash.com/photo-1506703719100-a0f3a48c0f86?w=800&auto=format&fit=crop&q=80',
  },
  {
    'name': 'Soft Pastel',
    'url': 'https://images.unsplash.com/photo-1579546929518-9e396f3cc809?w=800&auto=format&fit=crop&q=80',
  },
  {
    'name': 'Minimalist Sand',
    'url': 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=800&auto=format&fit=crop&q=80',
  },
  {
    'name': 'Neon Cyber',
    'url': 'https://images.unsplash.com/photo-1518709268805-4e9042af9f23?w=800&auto=format&fit=crop&q=80',
  },
];

/// Pre-seeded fallback solid colors matching the API catalog
const List<ThemeColorModel> kDefaultPresetColors = [
  ThemeColorModel(id: 'snow_white', name: 'Snow White', hexCode: '#FFFAFA'),
  ThemeColorModel(id: 'powder_blue', name: 'Powder Blue', hexCode: '#B0E0E6'),
  ThemeColorModel(id: 'mint_green', name: 'Mint Green', hexCode: '#98FF98'),
  ThemeColorModel(id: 'lavender', name: 'Lavender', hexCode: '#E6E6FA'),
  ThemeColorModel(id: 'blush_pink', name: 'Blush Pink', hexCode: '#FFB6C1'),
  ThemeColorModel(id: 'peach', name: 'Peach', hexCode: '#FFDAB9'),
  ThemeColorModel(id: 'buttercup', name: 'Buttercup', hexCode: '#FFFDD0'),
  ThemeColorModel(id: 'slate_gray', name: 'Slate Gray', hexCode: '#708090'),
  ThemeColorModel(id: 'dark_charcoal', name: 'Dark Charcoal', hexCode: '#1E242B'),
  ThemeColorModel(id: 'deep_navy', name: 'Deep Navy', hexCode: '#0F172A'),
  ThemeColorModel(id: 'emerald_dark', name: 'Emerald Dark', hexCode: '#064E3B'),
  ThemeColorModel(id: 'plum_purple', name: 'Plum Purple', hexCode: '#3B0764'),
];

class ChatThemeBottomSheet extends StatefulWidget {
  final String conversationId;
  final bool isGroup;

  const ChatThemeBottomSheet({
    super.key,
    required this.conversationId,
    this.isGroup = false,
  });

  @override
  State<ChatThemeBottomSheet> createState() => _ChatThemeBottomSheetState();
}

class _ChatThemeBottomSheetState extends State<ChatThemeBottomSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _onColorSelected(ThemeColorModel color) {
    _showApplyScopeDialog(
      title: 'Apply Color Theme',
      onApply: (applyToAll) {
        context.read<ChatBloc>().add(UpdateThemeEvent(
          themeColorId: color.id.startsWith('custom_') ? null : color.id,
          themeColor: color,
          clearWallpaper: true,
          applyToAll: applyToAll,
        ));
        Navigator.pop(context);
      },
    );
  }

  void _onWallpaperSelected(String wallpaperUrl) {
    _showApplyScopeDialog(
      title: 'Apply Wallpaper',
      onApply: (applyToAll) {
        context.read<ChatBloc>().add(UpdateThemeEvent(
          customWallpaperUrl: wallpaperUrl,
          applyToAll: applyToAll,
        ));
        Navigator.pop(context);
      },
    );
  }

  Future<void> _pickFromGallery() async {
    try {
      final pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 88,
      );
      if (pickedFile == null) return;

      if (!mounted) return;

      _showApplyScopeDialog(
        title: 'Apply Custom Photo',
        onApply: (applyToAll) async {
          setState(() => _isUploading = true);
          String persistentPath = pickedFile.path;

          // 1. Copy to persistent application document directory on mobile
          if (!kIsWeb) {
            try {
              final appDir = await getApplicationDocumentsDirectory();
              final wallpapersDir = Directory('${appDir.path}/wallpapers');
              if (!await wallpapersDir.exists()) {
                await wallpapersDir.create(recursive: true);
              }
              final targetFile = File('${wallpapersDir.path}/${DateTime.now().millisecondsSinceEpoch}_${pickedFile.name}');
              final savedFile = await File(pickedFile.path).copy(targetFile.path);
              persistentPath = savedFile.path;
            } catch (e) {
              debugPrint('Error persisting custom wallpaper locally: $e');
            }
          }

          // 2. Apply locally first so UI updates immediately and stays permanently
          if (mounted) {
            context.read<ChatBloc>().add(UpdateThemeEvent(
              customWallpaperUrl: persistentPath,
              applyToAll: applyToAll,
            ));
            context.showSuccessNotification('Custom wallpaper applied');
            Navigator.pop(context);
          }

          // 3. Upload to backend in background
          try {
            final repo = getIt<ChatRepository>();
            Uint8List? fileBytes;
            if (kIsWeb) {
              fileBytes = await pickedFile.readAsBytes();
            }

            final fileSize = await pickedFile.length();
            final isPng = pickedFile.name.toLowerCase().endsWith('.png');
            final mimeType = isPng ? 'image/png' : 'image/jpeg';

            final objectKey = await repo.uploadMedia(
              conversationId: applyToAll ? '' : widget.conversationId,
              filePath: persistentPath,
              fileName: pickedFile.name,
              mediaType: 'WALLPAPER',
              mimeType: mimeType,
              fileSizeBytes: fileSize,
              fileBytes: fileBytes,
            );

            if (objectKey != null && objectKey.isNotEmpty) {
              debugPrint('Custom wallpaper uploaded successfully: $objectKey');
            }
          } catch (e) {
            debugPrint('Failed to sync wallpaper to remote: $e');
          } finally {
            if (mounted) setState(() => _isUploading = false);
          }
        },
      );
    } catch (e) {
      if (mounted) {
        context.showErrorNotification('Error picking image: $e');
      }
    }
  }

  void _onResetTheme() {
    _showApplyScopeDialog(
      title: 'Reset Theme',
      subtitle: 'Reset wallpaper and colors back to system defaults?',
      onApply: (applyToAll) {
        context.read<ChatBloc>().add(ResetThemeEvent(resetAll: applyToAll));
        Navigator.pop(context);
      },
    );
  }

  void _showApplyScopeDialog({
    required String title,
    String? subtitle,
    required Function(bool applyToAll) onApply,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: sheetCtx.colors.scaffoldBackground,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(
            color: sheetCtx.colors.border.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: sheetCtx.titleLarge.copyWith(fontWeight: FontWeight.bold),
              ),
              CommonSpaces.h8,
              Text(
                subtitle ?? 'Choose whether to set this theme for this chat only or for all your chats.',
                style: TextStyle(
                  color: sheetCtx.colors.textSecondary,
                  fontSize: 14,
                ),
              ),
              CommonSpaces.h24,
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: BorderSide(color: sheetCtx.colors.primary),
                      ),
                      onPressed: () {
                        Navigator.pop(sheetCtx);
                        onApply(false);
                      },
                      child: Text(
                        'For This Chat',
                        style: TextStyle(
                          color: sheetCtx.colors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  CommonSpaces.w12,
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: sheetCtx.colors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      onPressed: () {
                        Navigator.pop(sheetCtx);
                        onApply(true);
                      },
                      child: const Text(
                        'For All Chats',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ChatBloc, ChatState>(
      builder: (context, state) {
        final loadedThemes = state is ChatLoaded ? state.availableThemes : <ThemeColorModel>[];
        final List<ThemeColorModel> displayColors = loadedThemes.isNotEmpty
            ? loadedThemes
            : kDefaultPresetColors;
        final selectedThemeId = state is ChatLoaded ? state.themeColor?.id : null;
        final currentWallpaper = state is ChatLoaded ? state.customWallpaperUrl : null;

        return Container(
          height: MediaQuery.of(context).size.height * 0.58,
          decoration: BoxDecoration(
            color: context.colors.scaffoldBackground,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Stack(
            children: [
              Column(
                children: [
                  // Handle Bar
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      margin: const EdgeInsets.only(top: 10, bottom: 4),
                      decoration: BoxDecoration(
                        color: context.colors.textSecondary.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),

                  // Header with Title & Reset Button
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 2, 8, 2),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: context.colors.primary.withValues(alpha: 0.12),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.color_lens_rounded,
                                  color: context.colors.primary,
                                  size: 18,
                                ),
                              ),
                              CommonSpaces.w8,
                              Flexible(
                                child: Text(
                                  'Chat Wallpaper & Theme',
                                  style: context.titleMedium.copyWith(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        TextButton.icon(
                          onPressed: _onResetTheme,
                          icon: const Icon(Icons.refresh_rounded, size: 14),
                          label: const Text('Reset'),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            foregroundColor: context.colors.error,
                            textStyle: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Compact Tab Bar (Colors & Wallpapers)
                  Container(
                    height: 38,
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: context.colors.cardBackground,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: context.colors.border.withValues(alpha: 0.5),
                        width: 1,
                      ),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      indicatorSize: TabBarIndicatorSize.tab,
                      dividerColor: Colors.transparent,
                      labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                      indicator: BoxDecoration(
                        color: context.colors.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      labelColor: Colors.white,
                      unselectedLabelColor: context.colors.textSecondary,
                      labelStyle: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        fontFamily: CommonFonts.primaryFont,
                      ),
                      unselectedLabelStyle: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        fontFamily: CommonFonts.primaryFont,
                      ),
                      tabs: const [
                        Tab(
                          height: 32,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.palette_outlined, size: 14),
                              SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  'Colors',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Tab(
                          height: 32,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.image_outlined, size: 14),
                              SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  'Wallpapers',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Tab Views
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        // ─── TAB 1: SOLID COLORS ───
                        _buildColorsTab(
                          displayColors: displayColors,
                          selectedThemeId: selectedThemeId,
                        ),

                        // ─── TAB 2: WALLPAPERS & GALLERY ───
                        _buildWallpapersTab(
                          currentWallpaper: currentWallpaper,
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Uploading overlay
              if (_isUploading)
                Container(
                  color: Colors.black.withValues(alpha: 0.45),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                      decoration: BoxDecoration(
                        color: context.colors.scaffoldBackground,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(color: context.colors.primary),
                          CommonSpaces.h16,
                          const Text(
                            'Uploading wallpaper...',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildColorsTab({
    required List<ThemeColorModel> displayColors,
    required String? selectedThemeId,
  }) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      children: [
        Text(
          'PRESET SOLID COLORS',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: context.colors.textSecondary,
          ),
        ),
        CommonSpaces.h12,
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 0.85,
          ),
          itemCount: displayColors.length,
          itemBuilder: (ctx, index) {
            final item = displayColors[index];
            final isSelected = item.id == selectedThemeId;
            final color = item.toColor();

            return GestureDetector(
              onTap: () => _onColorSelected(item),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected
                              ? context.colors.primary
                              : Colors.black.withValues(alpha: 0.15),
                          width: isSelected ? 3.5 : 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: isSelected
                          ? Center(
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.5),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.check_rounded,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                            )
                          : null,
                    ),
                  ),
                  CommonSpaces.h6,
                  Text(
                    item.name,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected
                          ? context.colors.primary
                          : context.colors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          },
        ),
        CommonSpaces.h24,
      ],
    );
  }

  Widget _buildWallpapersTab({required String? currentWallpaper}) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      children: [
        // Choose from Gallery Card
        GestureDetector(
          onTap: _pickFromGallery,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  context.colors.primary.withValues(alpha: 0.15),
                  context.colors.primary.withValues(alpha: 0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: context.colors.primary.withValues(alpha: 0.3),
                width: 1.2,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: context.colors.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.add_photo_alternate_rounded,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
                CommonSpaces.w16,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Choose from Gallery',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      CommonSpaces.h4,
                      Text(
                        'Upload your own photo or custom wallpaper',
                        style: TextStyle(
                          fontSize: 13,
                          color: context.colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: context.colors.textSecondary,
                ),
              ],
            ),
          ),
        ),
        CommonSpaces.h20,

        // Curated Wallpapers Section
        Text(
          'CURATED WALLPAPERS',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: context.colors.textSecondary,
          ),
        ),
        CommonSpaces.h12,

        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 14,
            crossAxisSpacing: 14,
            childAspectRatio: 0.68,
          ),
          itemCount: kPresetWallpapers.length,
          itemBuilder: (ctx, index) {
            final item = kPresetWallpapers[index];
            final url = item['url']!;
            final name = item['name']!;
            final isSelected = currentWallpaper == url;

            return GestureDetector(
              onTap: () => _onWallpaperSelected(url),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected
                              ? context.colors.primary
                              : context.colors.border.withValues(alpha: 0.5),
                          width: isSelected ? 3 : 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.network(
                              url,
                              fit: BoxFit.cover,
                              errorBuilder: (ctx, err, stack) => Container(
                                color: context.colors.cardBackground,
                                child: Icon(
                                  Icons.broken_image_rounded,
                                  color: context.colors.textSecondary,
                                ),
                              ),
                            ),
                            if (isSelected)
                              Container(
                                color: context.colors.primary.withValues(alpha: 0.3),
                                child: const Center(
                                  child: CircleAvatar(
                                    radius: 14,
                                    backgroundColor: Colors.white,
                                    child: Icon(
                                      Icons.check_rounded,
                                      color: Color(0xFF00873C),
                                      size: 18,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  CommonSpaces.h6,
                  Text(
                    name,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected
                          ? context.colors.primary
                          : context.colors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          },
        ),
        CommonSpaces.h24,
      ],
    );
  }
}
