import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:schat/injection.dart';
import 'package:schat/utils/common_colors.dart';
import 'package:schat/utils/theme_controller.dart';

class AppHomeBackground extends StatelessWidget {
  final Widget? child;

  const AppHomeBackground({super.key, this.child});

  static const String defaultBackgroundAsset = 'assets/images/home_bg.jpg';

  @override
  Widget build(BuildContext context) {
    final isDark = context.colors.isDark;

    return AnimatedBuilder(
      animation: getIt<ThemeController>(),
      builder: (context, _) {
        final themeCtrl = getIt<ThemeController>();
        final wallpaper = themeCtrl.homeWallpaperUrl;
        final themeColor = themeCtrl.homeThemeColor;

        Widget background;

        if (wallpaper != null && wallpaper.isNotEmpty) {
          background = Stack(
            fit: StackFit.expand,
            children: [
              _buildWallpaperImage(wallpaper),
              // Soft scrim overlay for pristine readability of text & cards
              Container(
                color: (isDark ? Colors.black : Colors.white).withValues(
                  alpha: isDark ? 0.35 : 0.20,
                ),
              ),
            ],
          );
        } else {
          // Default uploaded pastel wave background image
          background = Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                defaultBackgroundAsset,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: context.colors.scaffoldBackground,
                ),
              ),
              if (isDark)
                Container(
                  color: Colors.black.withValues(alpha: 0.65),
                ),
            ],
          );
        }

        if (themeColor != null) {
          background = Stack(
            fit: StackFit.expand,
            children: [
              background,
              Container(
                color: themeColor.withValues(alpha: isDark ? 0.35 : 0.20),
              ),
            ],
          );
        }

        if (child != null) {
          return Stack(
            fit: StackFit.expand,
            children: [
              background,
              child!,
            ],
          );
        }

        return background;
      },
    );
  }

  Widget _buildWallpaperImage(String url) {
    if (url.startsWith('assets/')) {
      return Image.asset(
        url,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
      );
    }
    if (!kIsWeb && !url.startsWith('http://') && !url.startsWith('https://')) {
      final file = File(url);
      if (file.existsSync()) {
        return Image.file(
          file,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
        );
      }
    }

    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      errorWidget: (context, url, error) => const SizedBox.shrink(),
    );
  }
}

