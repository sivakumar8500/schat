import 'dart:io';

void main() {
  final dir = Directory('lib/features/call_screen/src/presentation');
  final files = dir.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'));

  for (final file in files) {
    String content = file.readAsStringSync();
    
    // Fix invalid shades
    content = content.replaceAll('context.colors.primary.shade50', 'context.colors.primary.withOpacity(0.1)');
    content = content.replaceAll('context.colors.textHint.shade100', 'context.colors.lightBackground');
    content = content.replaceAll('context.colors.textHint.shade900', 'context.colors.border');
    
    // Fix invalid opacity suffixes
    content = content.replaceAll('context.colors.scaffoldBackground10', 'context.colors.scaffoldBackground.withOpacity(0.1)');
    content = content.replaceAll('context.colors.scaffoldBackground24', 'context.colors.scaffoldBackground.withOpacity(0.24)');
    content = content.replaceAll('context.colors.scaffoldBackground54', 'context.colors.scaffoldBackground.withOpacity(0.54)');
    
    // Fix "Not a constant expression" caused by context.colors inside const
    // Remove "const Center(" where it's no longer const
    content = content.replaceAll('const Center(child: Icon(Icons.videocam_off', 'Center(child: Icon(Icons.videocam_off');
    content = content.replaceAll('const Center(child: Text(\\'You\\'', 'Center(child: Text(\\'You\\'');
    
    file.writeAsStringSync(content);
  }
  print('Done.');
}
