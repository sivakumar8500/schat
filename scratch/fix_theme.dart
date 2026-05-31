import 'dart:io';

void main() {
  final libDir = Directory('lib');
  final files = libDir.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'));

  int replacedFiles = 0;

  for (final file in files) {
    if (file.path.contains('common_colors.dart')) continue;

    String content = file.readAsStringSync();
    String original = content;

    content = content.replaceAll('context.colors.textPrimary87', 'context.colors.textPrimary');
    content = content.replaceAll('context.colors.textPrimary54', 'context.colors.textSecondary');
    content = content.replaceAll('context.colors.textPrimary26', 'context.colors.textPrimary.withOpacity(0.26)');
    content = content.replaceAll('context.colors.textPrimary12', 'context.colors.textPrimary.withOpacity(0.12)');
    content = content.replaceAll('context.colors.scaffoldBackground70', 'context.colors.textSecondary');
    
    // Remaining Colors.green.shade50
    content = content.replaceAll('Colors.green.shade50', 'context.colors.success.withOpacity(0.1)');
    content = content.replaceAll('Colors.grey.shade400', 'context.colors.border');
    content = content.replaceAll('Colors.grey.shade100', 'context.colors.lightBackground');
    content = content.replaceAll('Colors.blue.shade100', 'context.colors.primary.withOpacity(0.2)');
    content = content.replaceAll('Colors.blue.shade50', 'context.colors.primary.withOpacity(0.1)');
    content = content.replaceAll('Colors.grey.shade50', 'context.colors.lightBackground');

    if (content != original) {
      file.writeAsStringSync(content);
      replacedFiles++;
      print('Updated \${file.path}');
    }
  }

  print('Fixed colors in \$replacedFiles files.');
}
