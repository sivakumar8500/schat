import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeController extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;
  String _fontSizeName = 'Medium';

  ThemeMode get themeMode => _themeMode;
  String get fontSizeName => _fontSizeName;

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
}
