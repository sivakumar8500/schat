import 'dart:async';
import 'package:schat/utils/common_fontstyles.dart';
import 'package:schat/utils/common_sizes.dart';

import 'package:schat/utils/common_strings.dart';
import 'package:schat/utils/common_spaces.dart';
import 'package:schat/utils/common_colors.dart';
import 'package:schat/utils/common_icons.dart';
import 'package:schat/utils/common_notifications.dart';
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
  final String recipientId;

  const ChatPage({
    super.key,
    required this.conversationId,
    required this.contactName,
    required this.contactColor,
    required this.isOnline,
    required this.recipientId,
    this.profilePictureUrl,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  bool _isTyping = false;

  late ChatBloc _chatBloc;
  Timer? _typingIndicatorTimer;

  @override
  void initState() {
    super.initState();
    debugPrint('DEBUG: ChatPage Initializing for conv: ${widget.conversationId}, recipient: ${widget.recipientId}, initialOnline: ${widget.isOnline}');
    _chatBloc = ChatBloc()..add(LoadMessagesEvent(
      conversationId: widget.conversationId,
      recipientId: widget.recipientId,
      initialIsOnline: widget.isOnline,
    ));
  }

  @override
  void dispose() {
    _stopTypingTimer();
    _messageController.dispose();
    _chatBloc.close();
    super.dispose();
  }

  void _onTextChanged(String value) {
    final hasText = value.trim().isNotEmpty;
    if (hasText != _isTyping) {
      setState(() {
        _isTyping = hasText;
      });
      // Immediately notify about change
      context.read<ChatSocketBloc>().add(SendTypingIndicator(widget.conversationId, isTyping: hasText));
    }

    if (hasText) {
      _startTypingTimer();
    } else {
      _stopTypingTimer();
    }
  }

  void _startTypingTimer() {
    if (_typingIndicatorTimer?.isActive ?? false) return;
    
    _typingIndicatorTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_messageController.text.trim().isNotEmpty) {
        context.read<ChatSocketBloc>().add(SendTypingIndicator(widget.conversationId, isTyping: true));
      } else {
        _stopTypingTimer();
      }
    });
  }

  void _stopTypingTimer() {
    _typingIndicatorTimer?.cancel();
    _typingIndicatorTimer = null;
  }

  Future<void> _sendMessage(BuildContext context) async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    // Send via socket
    context.read<ChatSocketBloc>().add(SendMessage(
      conversationId: widget.conversationId,
      type: 'text',
      text: text,
    ));

    // Optimistically update UI
    _chatBloc.add(SendMessageEvent(
      conversationId: widget.conversationId,
      text: text,
    ));

    _messageController.clear();
    _stopTypingTimer();
    context.read<ChatSocketBloc>().add(SendTypingIndicator(widget.conversationId, isTyping: false));
    setState(() {
      _isTyping = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ChatBloc>.value(
      value: _chatBloc,
      child: BlocConsumer<ChatBloc, ChatState>(
        listener: (context, state) {
          if (state is ChatError) {
            context.showErrorNotification(state.errorMessage);
          }
        },
        builder: (context, state) {
          final isLoading = state is ChatLoading || state is ChatInitial;
          final messages = state is ChatLoaded ? state.messages : <MessageModel>[];
          final isOtherUserTyping = state is ChatLoaded && state.isRecipientTyping;

          return Scaffold(
            backgroundColor: context.colors.scaffoldBackground,
            appBar: _buildAppBar(context, state),
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
                                itemCount: messages.length + (isOtherUserTyping ? 1 : 0),
                                itemBuilder: (context, index) {
                                  if (isOtherUserTyping && index == 0) {
                                    return _buildTypingIndicator();
                                  }

                                  final adjustedIndex = isOtherUserTyping ? index - 1 : index;
                                  
                                  // Since reverse is true, index 0 is the bottom-most item.
                                  // Assuming the 'messages' list is ordered oldest-to-newest,
                                  // we access it from the end.
                                  final msg = messages[messages.length - 1 - adjustedIndex];
                                  final isMe = state is ChatLoaded && msg.senderId == state.myId;
                                  return MessageBubble(
                                    message: msg.content,
                                    time: _formatTime(msg.createdAt),
                                    isMe: isMe,
                                    isRead: msg.isRead,
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

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: context.colors.lightBackground,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (index) {
                return _TypingDot(index: index);
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyScreen(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(CommonIcons.chatBubbleOutline, size: 80, color: context.colors.textHint.withValues(alpha: 0.5)),
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

  PreferredSizeWidget _buildAppBar(BuildContext context, ChatState state) {
    final isOnline = state is ChatLoaded ? state.isRecipientOnline : widget.isOnline;
    final isTyping = state is ChatLoaded && state.isRecipientTyping;

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
                  isOnline: isOnline,
                ),
              ),
            ),
          );
        },
        child: Row(
          children: [
            Stack(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: widget.contactColor.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: ClipOval(
                    child: (widget.profilePictureUrl != null && widget.profilePictureUrl!.isNotEmpty)
                        ? Image.network(
                            widget.profilePictureUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Center(
                                child: Text(
                                  widget.contactName.isNotEmpty ? widget.contactName.substring(0, 1) : '?',
                                  style: context.titleMedium.copyWith(
                                    color: widget.contactColor,
                                  ),
                                ),
                              );
                            },
                          )
                        : Center(
                            child: Text(
                              widget.contactName.isNotEmpty ? widget.contactName.substring(0, 1) : '?',
                              style: context.titleMedium.copyWith(
                                color: widget.contactColor,
                              ),
                            ),
                          ),
                  ),
                ),
                if (isOnline)
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
                    isTyping 
                        ? 'Typing...' 
                        : (isOnline ? 'Online' : 'Offline'),
                    style: context.bodyMedium.copyWith(
                      color: (isTyping || isOnline)
                          ? context.colors.success 
                          : context.colors.textHint,
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
          icon: Icon(CommonIcons.videocam),
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
          icon: Icon(CommonIcons.phone),
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
            icon: Icon(CommonIcons.add, color: context.colors.primary, size: 28),
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
                style: context.bodyMedium.copyWith(color: context.colors.textPrimary),
                onChanged: _onTextChanged,
                decoration: InputDecoration(
                  hintText: CommonStrings.typeMessage,
                  hintStyle: context.bodyMedium.copyWith(color: context.colors.textHint),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          CommonSpaces.w8,
          if (!_isTyping)
            IconButton(
              icon: Icon(CommonIcons.camera, color: context.colors.primary, size: 26),
              onPressed: () => _pickImage(ImageSource.camera),
            ),
          if (!_isTyping)
            IconButton(
              icon: Icon(CommonIcons.mic, color: context.colors.primary, size: 26),
              onPressed: () {},
            ),
          if (_isTyping)
            Container(
              decoration: BoxDecoration(
                color: context.colors.primary,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: Icon(CommonIcons.send, color: context.colors.textLight, size: 20),
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
      backgroundColor: ctx.colors.transparent,
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
                    _attachmentOption(ctx, CommonIcons.document, ctx.colors.secondary, 'Document',
                        () { Navigator.pop(sheetCtx); _pickFile(FileType.any); }),
                    _attachmentOption(ctx, CommonIcons.camera, ctx.colors.error, 'Camera',
                        () { Navigator.pop(sheetCtx); _pickImage(ImageSource.camera); }),
                    _attachmentOption(ctx, CommonIcons.gallery, ctx.colors.optionGallery, 'Gallery',
                        () { Navigator.pop(sheetCtx); _pickImage(ImageSource.gallery); }),
                    _attachmentOption(ctx, CommonIcons.audio, ctx.colors.warning, 'Audio',
                        () { Navigator.pop(sheetCtx); _pickFile(FileType.audio); }),
                    _attachmentOption(ctx, CommonIcons.videoFile, ctx.colors.optionVideo, 'Video',
                        () { Navigator.pop(sheetCtx); _pickFile(FileType.video); }),
                    _attachmentOption(ctx, CommonIcons.location, ctx.colors.success, 'Location',
                        () { Navigator.pop(sheetCtx); _showLocationPicker(ctx); }),
                    _attachmentOption(ctx, CommonIcons.person, ctx.colors.primary, 'Contact',
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
              child: Icon(icon, color: context.colors.pureWhite, size: 28),
            ),
            CommonSpaces.h8,
            Text(
              label,
              style: context.bodyMedium.copyWith(fontSize: 12, color: context.colors.textSecondary),
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
      type: type,
      text: type == 'text' ? (type == 'image' ? '' : name) : null,
      fileKey: type != 'text' ? name : null, // Should be real key after upload
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
      type: type,
      text: type == 'text' ? (type == 'image' ? '' : name) : null,
      fileKey: type != 'text' ? path : null, // Should be real key after upload
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
                Icon(CommonIcons.location, color: ctx.colors.success, size: 28),
                CommonSpaces.w12,
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
                    Icon(CommonIcons.location, color: ctx.colors.error, size: 48),
                  ],
                ),
              ),
            ),
            const SizedBox(height: CommonSizes.p16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: Icon(CommonIcons.myLocation),
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
                Icon(CommonIcons.contacts, color: ctx.colors.primary, size: 24),
                CommonSpaces.w12,
                Text('Send Contact', style: ctx.titleMedium),
              ],
            ),
            CommonSpaces.h12,
            ...contacts.map((c) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: ctx.colors.primary.withValues(alpha: 0.15),
                child: Text(
                  c['name']![0],
                  style: ctx.bodyMedium.copyWith(color: ctx.colors.primary, fontWeight: FontWeight.bold),
                ),
              ),
              title: Text(c['name']!, style: ctx.titleSmall.copyWith(color: ctx.colors.textPrimary, fontWeight: FontWeight.w600)),
              subtitle: Text(c['phone']!, style: ctx.bodyMedium.copyWith(color: ctx.colors.textSecondary, fontSize: 12)),
              trailing: TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  _sendAttachment(ctx, 'contact:${c['phone']}', '${c['name']} · ${c['phone']}', 'contact');
                },
                child: Text('Send', style: ctx.bodyMedium.copyWith(color: ctx.colors.primary)),
              ),
            )),
            const SizedBox(height: CommonSizes.p16),
          ],
        ),
      ),
    );
  }
}

class _TypingDot extends StatefulWidget {
  final int index;
  const _TypingDot({required this.index});

  @override
  State<_TypingDot> createState() => _TypingDotState();
}

class _TypingDotState extends State<_TypingDot> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(
          widget.index * 0.2,
          0.6 + widget.index * 0.2,
          curve: Curves.easeInOut,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, -4 * _animation.value),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 2),
            height: 6,
            width: 6,
            decoration: BoxDecoration(
              color: context.colors.primary.withValues(alpha: 0.4 + (0.6 * _animation.value)),
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }
}
