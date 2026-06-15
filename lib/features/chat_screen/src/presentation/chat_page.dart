import 'dart:async';
import 'package:schat/injection.dart';
import 'package:schat/features/chat_socket_screen/src/domain/chat_socket_repository.dart';
import 'package:schat/features/chat_socket_screen/src/presentation/bloc/chat_socket_state.dart';
import 'package:schat/utils/common_fontstyles.dart';
import 'package:schat/utils/common_sizes.dart';

import 'package:schat/utils/common_strings.dart';
import 'package:schat/utils/common_spaces.dart';
import 'package:schat/utils/common_colors.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:typed_data';
import 'package:schat/features/chat_screen/src/presentation/widgets/message_bubble.dart';
import 'package:schat/features/chat_screen/src/presentation/contact_profile_page.dart';
import 'package:schat/features/call_screen/call_screen.dart';
import 'package:schat/features/chat_screen/src/domain/models/message_model.dart';
import 'package:schat/features/chat_screen/src/presentation/bloc/chat_bloc.dart';
import 'package:schat/features/chat_screen/src/presentation/bloc/chat_event.dart';
import 'package:schat/features/chat_screen/src/presentation/bloc/chat_state.dart';
import 'package:schat/features/chat_socket_screen/src/presentation/bloc/chat_socket_bloc.dart';
import 'package:schat/features/chat_socket_screen/src/presentation/bloc/chat_socket_event.dart';


class ChatPage extends StatefulWidget {
  final String conversationId;
  final String contactName;
  final Color contactColor;
  final bool isOnline;
  final String? profilePictureUrl;

  const ChatPage({
    super.key,
    required this.conversationId,
    required this.contactName,
    required this.contactColor,
    required this.isOnline,
    this.profilePictureUrl,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  bool _isTyping = false;
  StreamSubscription? _socketSubscription;

  late ChatBloc _chatBloc;

  @override
  void initState() {
    super.initState();
    _chatBloc = ChatBloc()..add(LoadMessagesEvent(conversationId: widget.conversationId));
    
    _socketSubscription = getIt<ChatSocketRepository>().onMessage.listen((data) {
      if (mounted && data is Map<String, dynamic>) {
        if (data['type'] == 'new_message') {
          final message = data['message'] as Map<String, dynamic>?;
          if (message != null && message['conversation_id'] == widget.conversationId) {
            _chatBloc.add(ReceiveMessageEvent(messageData: message));
          }
        }
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _socketSubscription?.cancel();
    _chatBloc.close();
    super.dispose();
  }

  Future<void> _sendMessage(BuildContext context) async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    // Send via socket
    context.read<ChatSocketBloc>().add(SendMessage(
      conversationId: widget.conversationId,
      content: text,
    ));

    // Optimistically update UI
    _chatBloc.add(SendMessageEvent(
      conversationId: widget.conversationId,
      text: text,
    ));

    _messageController.clear();
    setState(() {
      _isTyping = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ChatBloc>.value(
      value: _chatBloc,
      child: BlocBuilder<ChatBloc, ChatState>(
        builder: (context, state) {
          final isLoading = state is ChatLoading || state is ChatInitial;
          final messages = state is ChatLoaded ? state.messages : <MessageModel>[];

          return Scaffold(
            backgroundColor: context.colors.scaffoldBackground,
            appBar: _buildAppBar(context),
            body: SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: isLoading
                        ? Center(child: CircularProgressIndicator(color: context.colors.primary))
                        : messages.isEmpty 
                            ? _buildEmptyScreen(context)
                            : ListView.builder(
                                reverse: true,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                itemCount: messages.length,
                                itemBuilder: (context, index) {
                                  // Since reverse is true, index 0 is the bottom-most item.
                                  // Assuming the 'messages' list is ordered oldest-to-newest,
                                  // we access it from the end.
                                  final msg = messages[messages.length - 1 - index];
                                  final isMe = state is ChatLoaded && msg.senderId == state.myId;
                                  return MessageBubble(
                                    message: msg.content,
                                    time: _formatTime(msg.createdAt),
                                    isMe: isMe,
                                    isRead: true, // TODO: actual logic
                                    type: msg.mediaType ?? 'text',
                                    attachmentPath: msg.mediaUrl,
                                    attachmentName: '',
                                    attachmentBytes: null,
                                  );
                                },
                              ),
                  ),
                  _buildInputBar(context),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyScreen(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 80, color: context.colors.textHint.withValues(alpha: 0.5)),
          CommonSpaces.h16,
          Text(
            'No messages yet',
            style: context.titleMedium.copyWith(color: context.colors.textSecondary),
          ),
          CommonSpaces.h8,
          Text(
            'Send a message to start the conversation',
            style: context.bodySmall.copyWith(color: context.colors.textHint),
          ),
        ],
      ),
    );
  }

  String _formatTime(String createdAt) {
    try {
      final date = DateTime.parse(createdAt).toLocal();
      final hour = date.hour > 12 ? date.hour - 12 : (date.hour == 0 ? 12 : date.hour);
      final minute = date.minute.toString().padLeft(2, '0');
      final period = date.hour >= 12 ? 'PM' : 'AM';
      return '$hour:$minute $period';
    } catch (e) {
      return '';
    }
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: context.colors.scaffoldBackground,
      elevation: 0,
      iconTheme: IconThemeData(color: context.colors.textPrimary),
      titleSpacing: 0,
      title: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BlocProvider.value(
                value: _chatBloc,
                child: ContactProfilePage(
                  contactName: widget.contactName,
                  contactColor: widget.contactColor,
                  isOnline: widget.isOnline,
                ),
              ),
            ),
          );
        },
        child: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: widget.contactColor.withValues(alpha: 0.2),
                  backgroundImage: (widget.profilePictureUrl != null && widget.profilePictureUrl!.isNotEmpty)
                      ? NetworkImage(widget.profilePictureUrl!)
                      : null,
                  child: (widget.profilePictureUrl == null || widget.profilePictureUrl!.isEmpty)
                      ? Text(
                          widget.contactName.isNotEmpty ? widget.contactName.substring(0, 1) : '?',
                          style: context.titleMedium.copyWith(
                            color: widget.contactColor,
                          ),
                        )
                      : null,
                ),
                if (widget.isOnline)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: context.colors.success,
                        shape: BoxShape.circle,
                        border: Border.all(color: context.colors.scaffoldBackground, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            CommonSpaces.w12,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.contactName,
                    style: context.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    widget.isOnline ? 'Online' : 'Offline',
                    style: TextStyle(
                      color: widget.isOnline ? context.colors.success : context.colors.textHint,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.videocam_rounded),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => VideoCallPage(contactName: widget.contactName),
              ),
            );
          },
        ),
        IconButton(
          icon: Icon(Icons.call_rounded),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AudioCallPage(
                  contactName: widget.contactName,
                  contactColor: widget.contactColor,
                ),
              ),
            );
          },
        ),
        CommonSpaces.w8,
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1.0),
        child: Container(
          color: context.colors.border,
          height: 1.0,
        ),
      ),
    );
  }

  Widget _buildInputBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: context.colors.scaffoldBackground,
        boxShadow: [
          BoxShadow(
            color: context.colors.textPrimary.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.add_rounded, color: context.colors.primary, size: 28),
            onPressed: () => _showAttachmentPopup(context),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: context.colors.lightBackground,
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _messageController,
                textCapitalization: TextCapitalization.sentences,
                style: TextStyle(color: context.colors.textPrimary),
                onChanged: (value) {
                  setState(() {
                    _isTyping = value.isNotEmpty;
                  });
                },
                decoration: InputDecoration(
                  hintText: CommonStrings.typeMessage,
                  hintStyle: TextStyle(color: context.colors.textHint),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          CommonSpaces.w8,
          if (!_isTyping)
            IconButton(
              icon: Icon(Icons.camera_alt_rounded, color: context.colors.primary, size: 26),
              onPressed: () => _pickImage(ImageSource.camera),
            ),
          if (!_isTyping)
            IconButton(
              icon: Icon(Icons.mic_rounded, color: context.colors.primary, size: 26),
              onPressed: () {},
            ),
          if (_isTyping)
            Container(
              decoration: BoxDecoration(
                color: context.colors.primary,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: Icon(Icons.send_rounded, color: context.colors.textLight, size: 20),
                onPressed: () => _sendMessage(context),
              ),
            ),
        ],
      ),
    );
  }

  void _showAttachmentPopup(BuildContext ctx) {
    showModalBottomSheet(
      context: ctx,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => Container(
        height: 300,
        margin: const EdgeInsets.only(bottom: 20, left: 16, right: 16),
        decoration: BoxDecoration(
          color: ctx.colors.scaffoldBackground,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: ctx.colors.textPrimary.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: ctx.colors.textHint.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8),
                child: Wrap(
                  spacing: 20,
                  runSpacing: 20,
                  alignment: WrapAlignment.center,
                  children: [
                    _attachmentOption(ctx, Icons.insert_drive_file, ctx.colors.secondary, 'Document',
                        () { Navigator.pop(sheetCtx); _pickFile(FileType.any); }),
                    _attachmentOption(ctx, Icons.camera_alt, ctx.colors.error, 'Camera',
                        () { Navigator.pop(sheetCtx); _pickImage(ImageSource.camera); }),
                    _attachmentOption(ctx, Icons.insert_photo, ctx.colors.optionGallery, 'Gallery',
                        () { Navigator.pop(sheetCtx); _pickImage(ImageSource.gallery); }),
                    _attachmentOption(ctx, Icons.headset, ctx.colors.warning, 'Audio',
                        () { Navigator.pop(sheetCtx); _pickFile(FileType.audio); }),
                    _attachmentOption(ctx, Icons.video_file, ctx.colors.optionVideo, 'Video',
                        () { Navigator.pop(sheetCtx); _pickFile(FileType.video); }),
                    _attachmentOption(ctx, Icons.location_pin, ctx.colors.success, 'Location',
                        () { Navigator.pop(sheetCtx); _showLocationPicker(ctx); }),
                    _attachmentOption(ctx, Icons.person, ctx.colors.primary, 'Contact',
                        () { Navigator.pop(sheetCtx); _showContactPicker(ctx); }),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _attachmentOption(BuildContext context, IconData icon, Color bgColor, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 70,
        child: Column(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: bgColor,
              child: Icon(icon, color: Colors.white, size: 28),
            ),
            CommonSpaces.h8,
            Text(
              label,
              style: TextStyle(fontSize: 12, color: context.colors.textSecondary),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: source, imageQuality: 80);
    if (image == null || !mounted) return;

    final String name = image.name;

    if (kIsWeb) {
      // On web, read bytes since file path is not available
      final Uint8List bytes = await image.readAsBytes();
      if (!mounted) return;
      _sendAttachmentWithBytes(context, bytes, name, 'image');
    } else {
      _sendAttachment(context, image.path, name, 'image');
    }
  }

  Future<void> _pickFile(FileType type) async {
    FilePickerResult? result = await FilePicker.pickFiles(
      type: type,
      withData: true, // always load bytes so it works on web too
    );
    if (result == null || !mounted) return;
    final PlatformFile file = result.files.single;
    final String fileType = type == FileType.audio
        ? 'audio'
        : type == FileType.video
            ? 'video'
            : 'file';
    if (!mounted) return;
    if (kIsWeb && file.bytes != null) {
      _sendAttachmentWithBytes(context, file.bytes!, file.name, fileType);
    } else if (file.path != null) {
      _sendAttachment(context, file.path!, file.name, fileType);
    }
  }

  void _sendAttachmentWithBytes(BuildContext context, Uint8List bytes, String name, String type) {
    context.read<ChatBloc>().add(SendMessageEvent(
      conversationId: widget.conversationId,
      text: type == 'image' ? '' : name,
      type: type,
      attachmentName: name,
      attachmentBytes: bytes,
    ));
    // Send via socket
    context.read<ChatSocketBloc>().add(SendMessage(
      conversationId: widget.conversationId,
      content: type == 'image' ? '' : name,
      mediaType: type,
      // mediaUrl: // upload first?
    ));
  }

  Future<void> _sendAttachment(BuildContext context, String path, String name, String type) async {
    context.read<ChatBloc>().add(SendMessageEvent(
      conversationId: widget.conversationId,
      text: type == 'image' ? '' : name,
      type: type,
      attachmentPath: path,
      attachmentName: name,
    ));
    // Send via socket
    context.read<ChatSocketBloc>().add(SendMessage(
      conversationId: widget.conversationId,
      content: type == 'image' ? '' : name,
      mediaType: type,
      mediaUrl: path,
    ));
  }

  void _showLocationPicker(BuildContext ctx) {
    showModalBottomSheet(
      context: ctx,
      backgroundColor: ctx.colors.scaffoldBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: ctx.colors.textHint.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Row(
              children: [
                Icon(Icons.location_pin, color: ctx.colors.success, size: 28),
                const SizedBox(width: CommonSizes.p12),
                Text('Share Location', style: ctx.titleMedium),
              ],
            ),
            const SizedBox(height: CommonSizes.p20),
            // Map placeholder
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Container(
                height: 180,
                color: ctx.colors.lightBackground,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Grid to simulate a map
                    GridView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 6),
                      itemCount: 36,
                      itemBuilder: (_, _) => Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: ctx.colors.textHint.withValues(alpha: 0.15)),
                          color: ctx.colors.lightBackground,
                        ),
                      ),
                    ),
                    Icon(Icons.location_pin, color: ctx.colors.error, size: 48),
                  ],
                ),
              ),
            ),
            const SizedBox(height: CommonSizes.p16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.my_location),
                    label: const Text('Current Location'),
                    onPressed: () {
                      Navigator.pop(ctx);
                      _sendAttachment(ctx, 'location', 'My Location', 'location');
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: ctx.colors.primary,
                      side: BorderSide(color: ctx.colors.primary),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showContactPicker(BuildContext ctx) {
    final contacts = [
      {'name': 'Alice Johnson', 'phone': '+1 234 567 8901'},
      {'name': 'Bob Smith', 'phone': '+1 987 654 3210'},
      {'name': 'Carol Williams', 'phone': '+44 20 7946 0958'},
      {'name': 'David Brown', 'phone': '+91 98765 43210'},
      {'name': 'Eva Martinez', 'phone': '+34 612 345 678'},
    ];
    showModalBottomSheet(
      context: ctx,
      backgroundColor: ctx.colors.scaffoldBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.only(top: 16, left: 24, right: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: ctx.colors.textHint.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Row(
              children: [
                Icon(Icons.contacts, color: ctx.colors.primary, size: 24),
                const SizedBox(width: CommonSizes.p12),
                Text('Send Contact', style: ctx.titleMedium),
              ],
            ),
            const SizedBox(height: CommonSizes.p12),
            ...contacts.map((c) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: ctx.colors.primary.withValues(alpha: 0.15),
                child: Text(
                  c['name']![0],
                  style: TextStyle(color: ctx.colors.primary, fontWeight: FontWeight.bold),
                ),
              ),
              title: Text(c['name']!, style: TextStyle(color: ctx.colors.textPrimary, fontWeight: FontWeight.w600)),
              subtitle: Text(c['phone']!, style: TextStyle(color: ctx.colors.textSecondary, fontSize: 12)),
              trailing: TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  _sendAttachment(ctx, 'contact:${c['phone']}', '${c['name']} · ${c['phone']}', 'contact');
                },
                child: Text('Send', style: TextStyle(color: ctx.colors.primary)),
              ),
            )),
            const SizedBox(height: CommonSizes.p16),
          ],
        ),
      ),
    );
  }
}
