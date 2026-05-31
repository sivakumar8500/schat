import 'dart:io';

void main() {
  final dir = Directory('d:/Siva_Pro/schat');
  
  // Update common_spaces.dart first
  final commonSpacesFile = File('d:/Siva_Pro/schat/lib/utils/common_spaces.dart');
  if (commonSpacesFile.existsSync()) {
    final newCommonSpacesContent = '''
import 'package:flutter/material.dart';
import 'package:schat/utils/common_sizes.dart';

class CommonSpaces {
  CommonSpaces._();

  // Vertical Spaces (Height)
  static const SizedBox h2 = SizedBox(height: CommonSizes.p2);
  static const SizedBox h4 = SizedBox(height: CommonSizes.p4);
  static const SizedBox h6 = SizedBox(height: CommonSizes.p6);
  static const SizedBox h8 = SizedBox(height: CommonSizes.p8);
  static const SizedBox h10 = SizedBox(height: CommonSizes.p10);
  static const SizedBox h12 = SizedBox(height: CommonSizes.p12);
  static const SizedBox h16 = SizedBox(height: CommonSizes.p16);
  static const SizedBox h20 = SizedBox(height: CommonSizes.p20);
  static const SizedBox h24 = SizedBox(height: CommonSizes.p24);
  static const SizedBox h30 = SizedBox(height: CommonSizes.p30);
  static const SizedBox h32 = SizedBox(height: CommonSizes.p32);
  static const SizedBox h40 = SizedBox(height: CommonSizes.p40);
  static const SizedBox h48 = SizedBox(height: CommonSizes.p48);
  static const SizedBox h50 = SizedBox(height: CommonSizes.p50);
  static const SizedBox h60 = SizedBox(height: CommonSizes.p60);
  static const SizedBox h64 = SizedBox(height: CommonSizes.p64);
  static const SizedBox h80 = SizedBox(height: CommonSizes.p80);
  static const SizedBox h100 = SizedBox(height: CommonSizes.p100);

  // Horizontal Spaces (Width)
  static const SizedBox w2 = SizedBox(width: CommonSizes.p2);
  static const SizedBox w4 = SizedBox(width: CommonSizes.p4);
  static const SizedBox w6 = SizedBox(width: CommonSizes.p6);
  static const SizedBox w8 = SizedBox(width: CommonSizes.p8);
  static const SizedBox w10 = SizedBox(width: CommonSizes.p10);
  static const SizedBox w12 = SizedBox(width: CommonSizes.p12);
  static const SizedBox w16 = SizedBox(width: CommonSizes.p16);
  static const SizedBox w20 = SizedBox(width: CommonSizes.p20);
  static const SizedBox w24 = SizedBox(width: CommonSizes.p24);
  static const SizedBox w30 = SizedBox(width: CommonSizes.p30);
  static const SizedBox w32 = SizedBox(width: CommonSizes.p32);
  static const SizedBox w40 = SizedBox(width: CommonSizes.p40);
  static const SizedBox w48 = SizedBox(width: CommonSizes.p48);
  static const SizedBox w50 = SizedBox(width: CommonSizes.p50);
  static const SizedBox w60 = SizedBox(width: CommonSizes.p60);
  static const SizedBox w64 = SizedBox(width: CommonSizes.p64);
  static const SizedBox w80 = SizedBox(width: CommonSizes.p80);
  static const SizedBox w100 = SizedBox(width: CommonSizes.p100);
}
''';
    commonSpacesFile.writeAsStringSync(newCommonSpacesContent);
    print('Updated common_spaces.dart');
  }

  // Regex patterns for finding SizedBox with raw numbers
  final regexHeight = RegExp(r'SizedBox\(\s*height:\s*([0-9]+)(\.0)?\s*\)');
  final regexWidth = RegExp(r'SizedBox\(\s*width:\s*([0-9]+)(\.0)?\s*\)');

  final files = dir.listSync(recursive: true);
  for (final file in files) {
    if (file is File && file.path.endsWith('.dart')) {
      if (file.path.contains('.dart_tool') || 
          file.path.contains('.git') || 
          file.path.endsWith('common_spaces.dart') ||
          file.path.endsWith('common_sizes.dart') ||
          file.path.contains('scratch/')) {
        continue;
      }

      String content = file.readAsStringSync();
      bool modified = false;

      // Replace SizedBox(height: X)
      if (regexHeight.hasMatch(content)) {
        content = content.replaceAllMapped(regexHeight, (match) {
          final val = match.group(1)!;
          return 'SizedBox(height: CommonSizes.p$val)';
        });
        modified = true;
      }

      // Replace SizedBox(width: Y)
      if (regexWidth.hasMatch(content)) {
        content = content.replaceAllMapped(regexWidth, (match) {
          final val = match.group(1)!;
          return 'SizedBox(width: CommonSizes.p$val)';
        });
        modified = true;
      }

      if (modified) {
        // Add import if not present
        if (!content.contains('common_sizes.dart')) {
          // Add it after first import or at top
          final importLine = "import 'package:schat/utils/common_sizes.dart';\n";
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
        print('Updated file: ${file.path}');
      }
    }
  }
}
