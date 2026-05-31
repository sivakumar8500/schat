import 'dart:io';

void main() {
  final libDir = Directory('lib');
  final files = libDir.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'));

  int replacedFiles = 0;

  for (final file in files) {
    if (file.path.contains('common_colors.dart')) continue;

    String content = file.readAsStringSync();
    String original = content;

    // Backgrounds
    content = content.replaceAll('Colors.white', 'context.colors.scaffoldBackground');
    content = content.replaceAll('Colors.black', 'context.colors.textPrimary');
    content = content.replaceAll('Colors.black87', 'context.colors.textPrimary');
    content = content.replaceAll('Colors.black54', 'context.colors.textSecondary');
    content = content.replaceAll('Colors.white70', 'context.colors.textSecondary');
    content = content.replaceAll('Colors.grey', 'context.colors.textHint');
    content = content.replaceAll(RegExp(r'Colors\.grey\.shade\d+'), 'context.colors.lightBackground');
    
    // Status
    content = content.replaceAll('Colors.green', 'context.colors.success');
    content = content.replaceAll(RegExp(r'Colors\.green\.shade\d+'), 'context.colors.success');
    content = content.replaceAll('Colors.red', 'context.colors.error');
    content = content.replaceAll('Colors.orange', 'context.colors.warning');

    // Brand
    content = content.replaceAll('Colors.blueAccent', 'context.colors.primary');
    content = content.replaceAll('Colors.blue', 'context.colors.primary');
    
    // Remove invalid consts left over
    content = content.replaceAll(RegExp(r'const\s+BoxDecoration\('), 'BoxDecoration(');
    content = content.replaceAll(RegExp(r'const\s+Icon\('), 'Icon(');
    content = content.replaceAll(RegExp(r'const\s+Text\('), 'Text(');
    content = content.replaceAll(RegExp(r'const\s+TextStyle\('), 'TextStyle(');
    content = content.replaceAll(RegExp(r'const\s+CircularProgressIndicator\('), 'CircularProgressIndicator(');

    // Make sure we have the import
    if (content != original) {
      if (!content.contains("import 'package:schat/utils/common_colors.dart';")) {
        content = "import 'package:schat/utils/common_colors.dart';\n$content";
      }
      file.writeAsStringSync(content);
      replacedFiles++;
      print('Updated \${file.path}');
    }
  }

  print('Replaced colors in \$replacedFiles files.');
}
