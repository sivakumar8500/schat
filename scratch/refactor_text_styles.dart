import 'dart:io';

void main() {
  final dir = Directory('d:/Siva_Pro/schat/lib');

  final regexH1 = RegExp(
    r'TextStyle\(\s*fontSize:\s*38,\s*fontWeight:\s*FontWeight\.w900,\s*color:\s*context\.colors\.textPrimary,\s*height:\s*1\.1,\s*letterSpacing:\s*-0\.5,?\s*\)',
  );
  
  final regexH1Italic = RegExp(
    r'TextStyle\(\s*fontSize:\s*32,\s*fontStyle:\s*FontStyle\.italic,\s*fontFamily:\s*CommonFonts\.accentFont,\s*color:\s*context\.colors\.primaryAccent,\s*height:\s*1\.1,?\s*\)',
  );

  final regexH1Italic34 = RegExp(
    r'TextStyle\(\s*fontSize:\s*34,\s*fontStyle:\s*FontStyle\.italic,\s*fontFamily:\s*CommonFonts\.accentFont,\s*color:\s*context\.colors\.primaryAccent,?\s*\)',
  );

  final regexH1_36 = RegExp(
    r'TextStyle\(\s*fontSize:\s*36,\s*fontWeight:\s*FontWeight\.w900,\s*color:\s*context\.colors\.textPrimary,\s*letterSpacing:\s*-0\.5,?\s*\)',
  );

  final regexBodyMedium16 = RegExp(
    r'TextStyle\(\s*fontSize:\s*16,\s*color:\s*context\.colors\.textSecondary,\s*height:\s*1\.4,?\s*\)',
  );

  final regexTitleSmall = RegExp(
    r'TextStyle\(\s*fontSize:\s*16,\s*fontWeight:\s*FontWeight\.bold,\s*color:\s*context\.colors\.textPrimary,?\s*\)',
  );

  final regexH2 = RegExp(
    r'TextStyle\(\s*fontSize:\s*28,\s*fontWeight:\s*FontWeight\.bold,\s*color:\s*context\.colors\.textPrimary,?\s*\)',
  );

  final regexH3 = RegExp(
    r'TextStyle\(\s*fontSize:\s*22,\s*fontWeight:\s*FontWeight\.bold,\s*color:\s*context\.colors\.textPrimary,?\s*\)',
  );

  final regexTitleMedium = RegExp(
    r'TextStyle\(\s*fontSize:\s*18,\s*fontWeight:\s*FontWeight\.bold,\s*color:\s*context\.colors\.textPrimary,?\s*\)',
  );

  final files = dir.listSync(recursive: true);
  for (final file in files) {
    if (file is File && file.path.endsWith('.dart')) {
      if (file.path.contains('.dart_tool') || 
          file.path.contains('.git') || 
          file.path.endsWith('common_fontstyles.dart') ||
          file.path.contains('scratch/')) {
        continue;
      }

      String content = file.readAsStringSync();
      bool modified = false;

      if (regexH1.hasMatch(content)) {
        content = content.replaceAll(regexH1, 'context.h1');
        modified = true;
      }
      if (regexH1Italic.hasMatch(content)) {
        content = content.replaceAll(regexH1Italic, 'context.h1Italic');
        modified = true;
      }
      if (regexH1Italic34.hasMatch(content)) {
        content = content.replaceAll(regexH1Italic34, 'context.h1Italic.copyWith(fontSize: 34)');
        modified = true;
      }
      if (regexH1_36.hasMatch(content)) {
        content = content.replaceAll(regexH1_36, 'context.h1.copyWith(fontSize: 36)');
        modified = true;
      }
      if (regexBodyMedium16.hasMatch(content)) {
        content = content.replaceAll(regexBodyMedium16, 'context.bodyMedium.copyWith(fontSize: 16)');
        modified = true;
      }
      if (regexTitleSmall.hasMatch(content)) {
        content = content.replaceAll(regexTitleSmall, 'context.titleSmall');
        modified = true;
      }
      if (regexH2.hasMatch(content)) {
        content = content.replaceAll(regexH2, 'context.h2');
        modified = true;
      }
      if (regexH3.hasMatch(content)) {
        content = content.replaceAll(regexH3, 'context.h3');
        modified = true;
      }
      if (regexTitleMedium.hasMatch(content)) {
        content = content.replaceAll(regexTitleMedium, 'context.titleMedium');
        modified = true;
      }

      if (modified) {
        // Add import if not present
        if (!content.contains('common_fontstyles.dart')) {
          final importLine = "import 'package:schat/utils/common_fontstyles.dart';\n";
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
