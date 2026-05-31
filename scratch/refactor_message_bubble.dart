import 'dart:io';

void main() {
  final file = File('lib/features/chat_screen/src/presentation/widgets/message_bubble.dart');
  String content = file.readAsStringSync();

  // Add imports
  if (!content.contains('import \\'dart:io\\';')) {
    content = 'import \\'dart:io\\';\\n$content';
  }

  // Add fields to MessageBubble class
  if (!content.contains('final String type;')) {
    content = content.replaceFirst(
      'final bool isRead;',
      'final bool isRead;\\n  final String type;\\n  final String? attachmentPath;\\n  final String? attachmentName;'
    );
    
    content = content.replaceFirst(
      'this.isRead = false,',
      'this.isRead = false,\\n    this.type = \\'text\\',\\n    this.attachmentPath,\\n    this.attachmentName,'
    );
  }

  // Add _buildAttachment logic inside Container column
  if (!content.contains('Widget _buildAttachment')) {
    final attachmentMethod = '''
  Widget _buildAttachment(BuildContext context) {
    if (attachmentPath == null) return const SizedBox.shrink();

    if (type == 'image') {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.file(
            File(attachmentPath!),
            height: 150,
            width: 200,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              height: 150,
              width: 200,
              color: Colors.grey.shade300,
              child: const Icon(Icons.image_not_supported, color: Colors.grey),
            ),
          ),
        ),
      );
    } else if (type == 'audio' || type == 'file') {
      return Container(
        margin: const EdgeInsets.only(bottom: 8.0),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isMe ? Colors.white.withOpacity(0.2) : context.colors.scaffoldBackground,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              type == 'audio' ? Icons.headset : Icons.insert_drive_file,
              color: isMe ? Colors.white : context.colors.primary,
            ),
            CommonSpaces.w8,
            Flexible(
              child: Text(
                attachmentName ?? 'File',
                style: TextStyle(
                  color: isMe ? Colors.white : context.colors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }
''';

    content = content.replaceFirst(
      '''                crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  Text(''',
      '''                crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  _buildAttachment(context),
                  if (text.isNotEmpty)
                    Text('''
    );
    
    // Insert method at end of class
    content = content.replaceFirst('}\\n}', '}\\n\\n$attachmentMethod}\\n');
  }

  file.writeAsStringSync(content);
}
