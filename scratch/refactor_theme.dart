import 'dart:io';

void main() {
  final dir = Directory('d:/Siva_Pro/schat');

  final files = dir.listSync(recursive: true);
  for (final file in files) {
    if (file is File && file.path.endsWith('.dart')) {
      if (file.path.contains('.dart_tool') || 
          file.path.contains('.git') || 
          file.path.endsWith('common_colors.dart') ||
          file.path.endsWith('common_fonts.dart') ||
          file.path.contains('scratch/')) {
        continue;
      }

      String content = file.readAsStringSync();
      bool modified = false;
      bool needsFontsImport = false;
      bool needsColorsImport = false;

      // 1. Refactor font family 'serif'
      if (content.contains("fontFamily: CommonFonts.accentFont")) {
        content = content.replaceAll("fontFamily: CommonFonts.accentFont", "fontFamily: CommonFonts.accentFont");
        modified = true;
        needsFontsImport = true;
      }

      // 2. Refactor primaryAccent green title color
      final regexPrimaryAccent = RegExp(
        r'context\.colors\.isDark\s*\?\s*const\s*Color\(0xFF81C784\)\s*:\s*context\.colors\.primary',
      );
      if (regexPrimaryAccent.hasMatch(content)) {
        content = content.replaceAll(regexPrimaryAccent, 'context.colors.primaryAccent');
        modified = true;
        needsColorsImport = true;
      }

      // 3. Refactor cardBackground
      final regexCardBg = RegExp(
        r'context\.colors\.isDark\s*\?\s*const\s*Color\(0xFF1E2B22\)\s*:\s*const\s*Color\(0xFFF0FDF4\)',
      );
      if (regexCardBg.hasMatch(content)) {
        content = content.replaceAll(regexCardBg, 'context.colors.cardBackground');
        modified = true;
        needsColorsImport = true;
      }

      // 4. Refactor searchBackground
      final regexSearchBg = RegExp(
        r'context\.colors\.isDark\s*\?\s*Colors\.white\.withValues\(alpha:\s*0\.05\)\s*:\s*const\s*Color\(0xFFF3F4F6\)',
      );
      if (regexSearchBg.hasMatch(content)) {
        content = content.replaceAll(regexSearchBg, 'context.colors.searchBackground');
        modified = true;
        needsColorsImport = true;
      }

      // 5. Option gallery color
      if (content.contains('context.colors.optionGallery')) {
        content = content.replaceAll('context.colors.optionGallery', 'context.colors.optionGallery');
        modified = true;
        needsColorsImport = true;
      }

      // 6. Option video/camera color
      if (content.contains('context.colors.optionVideo')) {
        content = content.replaceAll('context.colors.optionVideo', 'context.colors.optionVideo');
        modified = true;
        needsColorsImport = true;
      }

      // 7. Option text color
      if (content.contains('context.colors.optionText')) {
        content = content.replaceAll('context.colors.optionText', 'context.colors.optionText');
        modified = true;
        needsColorsImport = true;
      }

      // 8. Video call gradient colors
      if (content.contains('context.colors.videoCallGradientStart')) {
        content = content.replaceAll('context.colors.videoCallGradientStart', 'context.colors.videoCallGradientStart');
        modified = true;
        needsColorsImport = true;
      }
      if (content.contains('context.colors.videoCallGradientEnd')) {
        content = content.replaceAll('context.colors.videoCallGradientEnd', 'context.colors.videoCallGradientEnd');
        modified = true;
        needsColorsImport = true;
      }

      if (modified) {
        // Add imports if needed
        if (needsFontsImport && !content.contains('common_fonts.dart')) {
          final importLine = "import 'package:schat/utils/common_fonts.dart';\n";
          final lines = content.split('\n');
          int insertIndex = 0;
          for (int i = 0; i < lines.length; i++) {
            if (lines[i].startsWith('import ')) {
              insertIndex = i;
              break;
            }
          }
          lines.insert(insertIndex, importLine);
          content = lines.join('\n');
        }

        if (needsColorsImport && !content.contains('common_colors.dart')) {
          final importLine = "import 'package:schat/utils/common_colors.dart';\n";
          final lines = content.split('\n');
          int insertIndex = 0;
          for (int i = 0; i < lines.length; i++) {
            if (lines[i].startsWith('import ')) {
              insertIndex = i;
              break;
            }
          }
          lines.insert(insertIndex, importLine);
          content = lines.join('\n');
        }

        file.writeAsStringSync(content);
        print('Updated: ${file.path}');
      }
    }
  }
}
