import 'dart:io';

void main() {
  final file = File('lib/features/chat_screen/src/presentation/chat_page.dart');
  String content = file.readAsStringSync();

  // Add imports
  if (!content.contains('import \\'package:image_picker/image_picker.dart\\';')) {
    content = content.replaceFirst(
      'import \\'package:flutter/material.dart\\';', 
      'import \\'package:flutter/material.dart\\';\\nimport \\'package:image_picker/image_picker.dart\\';\\nimport \\'package:file_picker/file_picker.dart\\';'
    );
  }

  // Add image picker methods
  if (!content.contains('_pickImage')) {
    final newMethods = '''
  Future<void> _pickImage(ImageSource source) async {
    Navigator.pop(context); // Close bottom sheet
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: source);
    if (image != null) {
      _sendAttachment(image.path, image.name, 'image');
    }
  }

  Future<void> _pickFile(FileType type) async {
    Navigator.pop(context); // Close bottom sheet
    FilePickerResult? result = await FilePicker.pickFiles(type: type);
    if (result != null && result.files.single.path != null) {
      final String fileType = type == FileType.audio ? 'audio' : 'file';
      _sendAttachment(result.files.single.path!, result.files.single.name, fileType);
    }
  }

  Future<void> _sendAttachment(String path, String name, String type) async {
    final newMessage = MessageModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: type == 'image' ? 'Photo' : name,
      time: 'Just now',
      isMe: true,
      isRead: false,
      type: type,
      attachmentPath: path,
      attachmentName: name,
    );

    setState(() {
      _messages.add(newMessage);
    });

    await getIt<ChatRepository>().sendMessage(newMessage);
  }
''';
    content = content.replaceFirst('void _showAttachmentPopup', '$newMethods\\n  void _showAttachmentPopup');
  }

  // Update attachment option signatures
  content = content.replaceAll(
    'Widget _attachmentOption(BuildContext context, IconData icon, Color bgColor, String label)',
    'Widget _attachmentOption(BuildContext context, IconData icon, Color bgColor, String label, VoidCallback onTap)'
  );
  
  content = content.replaceFirst(
    '''    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        // Handle attachment selection here
      },''',
    '''    return GestureDetector(
      onTap: onTap,'''
  );

  // Update Wrap children
  content = content.replaceFirst(
    '''              _attachmentOption(context, Icons.insert_drive_file, context.colors.secondary, 'Document'),
              _attachmentOption(context, Icons.camera_alt, context.colors.error, 'Camera'),
              _attachmentOption(context, Icons.insert_photo, context.colors.secondary, 'Gallery'),
              _attachmentOption(context, Icons.headset, context.colors.warning, 'Audio'),
              _attachmentOption(context, Icons.location_pin, context.colors.success, 'Location'),
              _attachmentOption(context, Icons.person, context.colors.primary, 'Contact'),''',
    '''              _attachmentOption(context, Icons.insert_drive_file, context.colors.secondary, 'Document', () => _pickFile(FileType.any)),
              _attachmentOption(context, Icons.camera_alt, context.colors.error, 'Camera', () => _pickImage(ImageSource.camera)),
              _attachmentOption(context, Icons.insert_photo, context.colors.secondary, 'Gallery', () => _pickImage(ImageSource.gallery)),
              _attachmentOption(context, Icons.headset, context.colors.warning, 'Audio', () => _pickFile(FileType.audio)),
              _attachmentOption(context, Icons.location_pin, context.colors.success, 'Location', () => Navigator.pop(context)),
              _attachmentOption(context, Icons.person, context.colors.primary, 'Contact', () => Navigator.pop(context)),'''
  );

  // Update camera icon to open camera directly
  content = content.replaceFirst(
    '''          if (!_isTyping)
            IconButton(
              icon: Icon(Icons.camera_alt_rounded, color: context.colors.primary, size: 26),
              onPressed: () {},
            ),''',
    '''          if (!_isTyping)
            IconButton(
              icon: Icon(Icons.camera_alt_rounded, color: context.colors.primary, size: 26),
              onPressed: () {
                final ImagePicker picker = ImagePicker();
                picker.pickImage(source: ImageSource.camera).then((image) {
                  if (image != null) _sendAttachment(image.path, image.name, 'image');
                });
              },
            ),'''
  );

  file.writeAsStringSync(content);
}
