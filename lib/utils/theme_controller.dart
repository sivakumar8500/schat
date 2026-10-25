import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeController extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;
  String _fontSizeName = 'Medium';
  String? _homeWallpaperUrl;
  String? _homeThemeColorHex;

  ThemeMode get themeMode => _themeMode;
  String get fontSizeName => _fontSizeName;
  String? get homeWallpaperUrl => _homeWallpaperUrl;
  String? get homeThemeColorHex => _homeThemeColorHex;

  Color? get homeThemeColor {
    if (_homeThemeColorHex == null || _homeThemeColorHex!.isEmpty) return null;
    try {
      final hex = _homeThemeColorHex!.replaceAll('#', '');
      if (hex.length == 6) {
        return Color(int.parse('FF$hex', radix: 16));
      } else if (hex.length == 8) {
        return Color(int.parse(hex, radix: 16));
      }
    } catch (_) {}
    return null;
  }

  double get textScaleFactor {
    switch (_fontSizeName) {
      case 'Small':
        return 10 / 12; // Results in 10 for base 12
      case 'Large':
        return 14 / 12; // Results in 14 for base 12
      case 'Medium':
      default:
        return 1.0;
    }
  }

  Future<void> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool('isDarkTheme') ?? false;
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    _fontSizeName = prefs.getString('fontSizeName') ?? 'Medium';
    _homeWallpaperUrl = prefs.getString('home_wallpaper_url');
    _homeThemeColorHex = prefs.getString('home_theme_color_hex');
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    final prefs = await SharedPreferences.getInstance();
    if (_themeMode == ThemeMode.light) {
      _themeMode = ThemeMode.dark;
      await prefs.setBool('isDarkTheme', true);
    } else {
      _themeMode = ThemeMode.light;
      await prefs.setBool('isDarkTheme', false);
    }
    notifyListeners();
  }

  Future<void> setFontSize(String sizeName) async {
    final prefs = await SharedPreferences.getInstance();
    _fontSizeName = sizeName;
    await prefs.setString('fontSizeName', sizeName);
    notifyListeners();
  }

  Future<void> setHomeWallpaper(String? url) async {
    final prefs = await SharedPreferences.getInstance();
    _homeWallpaperUrl = url;
    _homeThemeColorHex = null;
    if (url != null) {
      await prefs.setString('home_wallpaper_url', url);
    } else {
      await prefs.remove('home_wallpaper_url');
    }
    await prefs.remove('home_theme_color_hex');
    notifyListeners();
  }

  Future<void> setHomeThemeColor(String? hex) async {
    final prefs = await SharedPreferences.getInstance();
    _homeThemeColorHex = hex;
    _homeWallpaperUrl = null;
    if (hex != null) {
      await prefs.setString('home_theme_color_hex', hex);
    } else {
      await prefs.remove('home_theme_color_hex');
    }
    await prefs.remove('home_wallpaper_url');
    notifyListeners();
  }

  Future<void> resetHomeBackground() async {
    final prefs = await SharedPreferences.getInstance();
    _homeWallpaperUrl = null;
    _homeThemeColorHex = null;
    await prefs.remove('home_wallpaper_url');
    await prefs.remove('home_theme_color_hex');
    notifyListeners();
  }
}
