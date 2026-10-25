import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:schat/features/chat_screen/src/domain/models/theme_color_model.dart';
import 'package:schat/features/chat_screen/src/domain/repositories/chat_repository.dart';
import 'package:schat/injection.dart';
import 'package:schat/utils/common_colors.dart';
import 'package:schat/utils/common_fonts.dart';
import 'package:schat/utils/common_fontstyles.dart';
import 'package:schat/utils/common_notifications.dart';
import 'package:schat/utils/common_spaces.dart';
import 'package:schat/utils/theme_controller.dart';

/// Pre-seeded curated wallpaper images matching chat presets
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

class HomeThemeBottomSheet extends StatefulWidget {
  const HomeThemeBottomSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const HomeThemeBottomSheet(),
    );
  }

  @override
  State<HomeThemeBottomSheet> createState() => _HomeThemeBottomSheetState();
}

class _HomeThemeBottomSheetState extends State<HomeThemeBottomSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;
  bool _isLoadingThemes = false;
  List<String> _userUploadedWallpapers = [];
  List<ThemeColorModel> _apiThemes = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadUserUploadedWallpapers();
    _fetchApiThemes();
  }

  Future<void> _fetchApiThemes() async {
    setState(() => _isLoadingThemes = true);
    try {
      final repo = getIt<ChatRepository>();
      final themes = await repo.getThemes();
      if (mounted) {
        setState(() {
          _apiThemes = themes.isNotEmpty ? themes : kDefaultPresetColors;
          _isLoadingThemes = false;
        });
      }
    } catch (e) {
      debugPrint('Failed to load API themes for home, using fallbacks: $e');
      if (mounted) {
        setState(() {
          _apiThemes = kDefaultPresetColors;
          _isLoadingThemes = false;
        });
      }
    }
  }

  Future<void> _loadUserUploadedWallpapers() async {
    try {
      final List<String> loaded = [];
      // 1. Load from Hive box
      final box = await Hive.openBox('user_uploaded_wallpapers');
      final dynamic saved = box.get('wallpapers', defaultValue: <dynamic>[]);
      if (saved is List) {
        for (final item in saved) {
          if (item is String && item.isNotEmpty && !loaded.contains(item)) {
            loaded.add(item);
          }
        }
      }

      // 2. Load from local wallpapers directory on device
      if (!kIsWeb) {
        try {
          final appDir = await getApplicationDocumentsDirectory();
          final wallpapersDir = Directory('${appDir.path}/wallpapers');
          if (await wallpapersDir.exists()) {
            final files = wallpapersDir.listSync();
            for (final f in files) {
              if (f is File && !loaded.contains(f.path)) {
                final lower = f.path.toLowerCase();
                if (lower.endsWith('.jpg') ||
                    lower.endsWith('.jpeg') ||
                    lower.endsWith('.png') ||
                    lower.endsWith('.webp')) {
                  loaded.insert(0, f.path);
                }
              }
            }
          }
        } catch (_) {}
      }

      if (mounted) {
        setState(() {
          _userUploadedWallpapers = loaded;
        });
      }
    } catch (e) {
      debugPrint('Error loading user uploaded wallpapers: $e');
    }
  }

  Future<void> _saveUserUploadedWallpaper(String path) async {
    try {
      final box = await Hive.openBox('user_uploaded_wallpapers');
      final dynamic saved = box.get('wallpapers', defaultValue: <dynamic>[]);
      final list = saved is List ? List<String>.from(saved.whereType<String>()) : <String>[];
      if (!list.contains(path)) {
        list.insert(0, path);
        await box.put('wallpapers', list);
      }
      if (mounted) {
        setState(() {
          if (!_userUploadedWallpapers.contains(path)) {
            _userUploadedWallpapers.insert(0, path);
          }
        });
      }
    } catch (e) {
      debugPrint('Error saving user uploaded wallpaper: $e');
    }
  }

  Future<void> _deleteUserUploadedWallpaper(String path) async {
    try {
      final box = await Hive.openBox('user_uploaded_wallpapers');
      final dynamic saved = box.get('wallpapers', defaultValue: <dynamic>[]);
      final list = saved is List ? List<String>.from(saved.whereType<String>()) : <String>[];
      list.remove(path);
      await box.put('wallpapers', list);

      if (!kIsWeb && File(path).existsSync()) {
        try {
          await File(path).delete();
        } catch (_) {}
      }

      if (mounted) {
        setState(() {
          _userUploadedWallpapers.remove(path);
        });
        context.showSuccessNotification('Uploaded wallpaper removed');
      }
    } catch (e) {
      debugPrint('Error deleting user uploaded wallpaper: $e');
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _pickFromGallery() async {
    try {
      final pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 88,
      );
      if (pickedFile == null) return;
      if (!mounted) return;

      setState(() => _isUploading = true);
      String persistentPath = pickedFile.path;

      // Copy to persistent application document directory on mobile
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

      // Save to uploaded list
      await _saveUserUploadedWallpaper(persistentPath);

      // Apply to home background
      await getIt<ThemeController>().setHomeWallpaper(persistentPath);

      if (mounted) {
        setState(() => _isUploading = false);
        context.showSuccessNotification('Home wallpaper applied');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploading = false);
        context.showErrorNotification('Error picking image: $e');
      }
    }
  }

  void _onWallpaperSelected(String wallpaperUrl) {
    getIt<ThemeController>().setHomeWallpaper(wallpaperUrl);
    if (mounted) {
      context.showSuccessNotification('Home wallpaper applied');
      Navigator.pop(context);
    }
  }

  void _onColorSelected(ThemeColorModel color) {
    getIt<ThemeController>().setHomeThemeColor(color.hexCode);
    if (mounted) {
      context.showSuccessNotification('${color.name} theme applied to home screen');
      Navigator.pop(context);
    }
  }

  void _onResetToDefault() {
    getIt<ThemeController>().resetHomeBackground();
    if (mounted) {
      context.showSuccessNotification('Home background reset to default wave design');
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeController = getIt<ThemeController>();
    final currentWallpaper = themeController.homeWallpaperUrl;
    final currentThemeHex = themeController.homeThemeColorHex;
    final displayColors = _apiThemes.isNotEmpty ? _apiThemes : kDefaultPresetColors;

    return Container(
      height: MediaQuery.of(context).size.height * 0.74,
      decoration: BoxDecoration(
        color: context.colors.scaffoldBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
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
                  margin: const EdgeInsets.only(top: 10, bottom: 6),
                  decoration: BoxDecoration(
                    color: context.colors.textSecondary.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Header Row: Title & Reset Button
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 4, 12, 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              color: context.colors.primary.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.palette_rounded,
                              color: context.colors.primary,
                              size: 19,
                            ),
                          ),
                          CommonSpaces.w10,
                          Flexible(
                            child: Text(
                              'Home Background & Themes',
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
                      onPressed: _onResetToDefault,
                      icon: const Icon(Icons.refresh_rounded, size: 15),
                      label: const Text('Reset'),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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

              // Tab Bar (Wallpapers & Colors)
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
                          Icon(Icons.image_outlined, size: 15),
                          SizedBox(width: 6),
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
                    Tab(
                      height: 32,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.palette_outlined, size: 15),
                          SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              'Theme Colors',
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
                    // TAB 1: WALLPAPERS & GALLERY
                    _buildWallpapersTab(currentWallpaper: currentWallpaper),

                    // TAB 2: SOLID COLORS (API THEMES)
                    _buildColorsTab(
                      displayColors: displayColors,
                      currentThemeHex: currentThemeHex,
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Uploading / processing overlay
          if (_isUploading)
            Container(
              color: Colors.black.withValues(alpha: 0.5),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  decoration: BoxDecoration(
                    color: context.colors.cardBackground,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(context.colors.primary),
                        ),
                      ),
                      CommonSpaces.w16,
                      const Text(
                        'Applying wallpaper...',
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
  }

  Widget _buildWallpapersTab({required String? currentWallpaper}) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      children: [
        // 1. Choose from Gallery Card
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
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      CommonSpaces.h4,
                      Text(
                        'Set your personal photo as home background',
                        style: TextStyle(
                          fontSize: 12,
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
        CommonSpaces.h16,

        // 2. Default Waves Option
        GestureDetector(
          onTap: _onResetToDefault,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: context.colors.cardBackground,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: (currentWallpaper == null && getIt<ThemeController>().homeThemeColorHex == null)
                    ? context.colors.primary
                    : context.colors.border.withValues(alpha: 0.5),
                width: (currentWallpaper == null && getIt<ThemeController>().homeThemeColorHex == null)
                    ? 2
                    : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF00873C), Color(0xFF34D399)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: const Icon(Icons.waves_rounded, color: Colors.white, size: 20),
                ),
                CommonSpaces.w12,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Default Wave Pattern',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      CommonSpaces.h2,
                      Text(
                        'Classic Emerald organic vector waves',
                        style: TextStyle(
                          fontSize: 12,
                          color: context.colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (currentWallpaper == null && getIt<ThemeController>().homeThemeColorHex == null)
                  Icon(Icons.check_circle_rounded, color: context.colors.primary, size: 20),
              ],
            ),
          ),
        ),
        CommonSpaces.h20,

        // 3. User Uploaded Wallpapers (if any)
        if (_userUploadedWallpapers.isNotEmpty) ...[
          Text(
            'MY UPLOADED WALLPAPERS',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: context.colors.textSecondary,
            ),
          ),
          CommonSpaces.h10,
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.70,
            ),
            itemCount: _userUploadedWallpapers.length,
            itemBuilder: (ctx, index) {
              final path = _userUploadedWallpapers[index];
              final isSelected = currentWallpaper == path;

              return GestureDetector(
                onTap: () => _onWallpaperSelected(path),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? context.colors.primary : context.colors.border.withValues(alpha: 0.5),
                          width: isSelected ? 3 : 1,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: !kIsWeb && File(path).existsSync()
                            ? Image.file(
                                File(path),
                                fit: BoxFit.cover,
                              )
                            : Image.network(
                                path,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => const Center(
                                  child: Icon(Icons.broken_image_outlined),
                                ),
                              ),
                      ),
                    ),
                    if (isSelected)
                      Positioned(
                        top: 6,
                        right: 6,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: context.colors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.check, color: Colors.white, size: 14),
                        ),
                      ),
                    Positioned(
                      bottom: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: () => _deleteUserUploadedWallpaper(path),
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.6),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close_rounded, color: Colors.white, size: 13),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          CommonSpaces.h20,
        ],

        // 4. Curated Wallpapers Section
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
                            CachedNetworkImage(
                              imageUrl: url,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                color: context.colors.cardBackground,
                                child: const Center(
                                  child: SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                ),
                              ),
                              errorWidget: (context, url, error) => Container(
                                color: context.colors.cardBackground,
                                child: const Icon(Icons.broken_image_rounded, size: 24),
                              ),
                            ),
                            if (isSelected)
                              Positioned(
                                top: 6,
                                right: 6,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: context.colors.primary,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: 14,
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

  Widget _buildColorsTab({
    required List<ThemeColorModel> displayColors,
    required String? currentThemeHex,
  }) {
    if (_isLoadingThemes) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(context.colors.primary),
            ),
            CommonSpaces.h16,
            Text(
              'Loading API Themes...',
              style: TextStyle(
                color: context.colors.textSecondary,
                fontSize: 13,
              ),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      children: [
        Text(
          'API THEMES & PALETTES',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: context.colors.textSecondary,
          ),
        ),
        CommonSpaces.h14,
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 0.82,
          ),
          itemCount: displayColors.length,
          itemBuilder: (ctx, index) {
            final item = displayColors[index];
            final isSelected = currentThemeHex != null &&
                (item.hexCode.toLowerCase() == currentThemeHex.toLowerCase());
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
}
