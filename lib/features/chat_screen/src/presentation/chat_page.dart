import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import 'package:schat/injection.dart';
import 'package:schat/features/dashboard_screen/src/domain/repositories/dashboard_repository.dart';
import 'package:schat/features/profile_screen/src/domain/models/user_model.dart';
import 'package:schat/features/chat_socket_screen/src/domain/chat_socket_repository.dart';
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
import 'package:schat/features/chat_screen/src/presentation/widgets/message_bubble.dart';
import 'package:schat/features/chat_screen/src/presentation/contact_profile_page.dart';
import 'package:schat/features/call_screen/call_screen.dart';
import 'package:schat/features/chat_screen/src/domain/models/message_model.dart';
import 'package:schat/features/chat_screen/src/presentation/bloc/chat_bloc.dart';
import 'package:schat/features/chat_screen/src/presentation/bloc/chat_event.dart';
import 'package:schat/features/chat_screen/src/presentation/bloc/chat_state.dart';
import 'package:schat/features/chat_socket_screen/src/presentation/bloc/chat_socket_bloc.dart';
import 'package:schat/features/chat_socket_screen/src/presentation/bloc/chat_socket_event.dart';
import 'package:schat/features/chat_screen/src/domain/repositories/chat_repository.dart';


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

  final Set<String> _selectedMessageIds = {};
  MessageModel? _replyingToMessage;
  MessageModel? _editingMessage;
  Box? _pinnedBox;
  MessageModel? _pinnedMessage;

  String? _selectedAttachmentPath;
  String? _selectedAttachmentName;
  String? _selectedAttachmentType; // 'image', 'video', 'audio', 'file', 'location', 'contact'
  Uint8List? _selectedAttachmentBytes;
  int _selectedAttachmentSize = 0;
  bool _attachmentAllowShare = true;
  bool _attachmentAllowDownload = true;
  bool _attachmentAllowView = true;
  Offset? _tapPosition;

  @override
  void initState() {
    super.initState();
    debugPrint('DEBUG: ChatPage Initializing for conv: ${widget.conversationId}, recipient: ${widget.recipientId}, initialOnline: ${widget.isOnline}');
    _chatBloc = ChatBloc()..add(LoadMessagesEvent(
      conversationId: widget.conversationId,
      recipientId: widget.recipientId,
      initialIsOnline: widget.isOnline,
    ));
    _initHive();
  }

  void _initHive() async {
    final box = await Hive.openBox('pinned_messages');
    if (mounted) {
      setState(() {
        _pinnedBox = box;
        final cached = box.get(widget.conversationId);
        if (cached != null) {
          _pinnedMessage = MessageModel.fromJson(Map<String, dynamic>.from(cached));
        }
      });
    }
  }

  Future<List<UserModel>> _getForwardContacts() async {
    try {
      final box = await Hive.openBox('contacts_box');
      final String? jsonString = box.get('cached_contacts');
      if (jsonString != null) {
        final List<dynamic> decoded = jsonDecode(jsonString);
        return decoded.map((e) => UserModel.fromJson(e as Map<String, dynamic>)).toList();
      }
    } catch (e) {
      debugPrint('Error loading forward contacts: $e');
    }
    return [];
  }

  Widget _buildPinnedMessageBanner() {
    if (_pinnedMessage == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: context.colors.lightBackground,
        border: Border(
          bottom: BorderSide(
            color: context.colors.border,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(CommonIcons.pin, color: context.colors.primary, size: 20),
          CommonSpaces.w12,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Pinned Message',
                  style: context.bodySmall.copyWith(
                    fontWeight: FontWeight.bold,
                    color: context.colors.primary,
                  ),
                ),
                Text(
                  _pinnedMessage!.content,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.bodyMedium.copyWith(
                    color: context.colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(CommonIcons.close, color: context.colors.textSecondary, size: 18),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () async {
              _chatBloc.add(PinMessageEvent(
                messageId: _pinnedMessage!.id,
                conversationId: widget.conversationId,
                isPinned: false,
              ));
              if (_pinnedBox != null) {
                await _pinnedBox!.delete(widget.conversationId);
              }
              setState(() {
                _pinnedMessage = null;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildReplyPreview() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: context.colors.lightBackground,
        border: Border(
          top: BorderSide(color: context.colors.border, width: 1),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 36,
            color: context.colors.primary,
          ),
          CommonSpaces.w12,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Replying to Message',
                  style: context.bodySmall.copyWith(
                    fontWeight: FontWeight.bold,
                    color: context.colors.primary,
                  ),
                ),
                Text(
                  _replyingToMessage!.content,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.bodyMedium.copyWith(
                    color: context.colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(CommonIcons.close, color: context.colors.textSecondary, size: 20),
            onPressed: () {
              setState(() {
                _replyingToMessage = null;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEditPreview() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: context.colors.lightBackground,
        border: Border(
          top: BorderSide(color: context.colors.border, width: 1),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 36,
            color: context.colors.warning,
          ),
          CommonSpaces.w12,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Editing Message',
                  style: context.bodySmall.copyWith(
                    fontWeight: FontWeight.bold,
                    color: context.colors.warning,
                  ),
                ),
                Text(
                  _editingMessage!.content,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.bodyMedium.copyWith(
                    color: context.colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(CommonIcons.close, color: context.colors.textSecondary, size: 20),
            onPressed: () {
              setState(() {
                _editingMessage = null;
                _messageController.clear();
                _isTyping = false;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBottomSection(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_replyingToMessage != null) _buildReplyPreview(),
        if (_editingMessage != null) _buildEditPreview(),
        if (_selectedAttachmentType != null) _buildAttachmentPreview(),
        _buildInputBar(context),
      ],
    );
  }

  void _showMessageMenu(BuildContext context, MessageModel msg, bool isMe, Offset? tapPosition) async {
    final RenderBox overlay = Navigator.of(context).overlay!.context.findRenderObject() as RenderBox;
    final position = RelativeRect.fromRect(
      Rect.fromLTWH(
        tapPosition?.dx ?? overlay.size.width / 2,
        tapPosition?.dy ?? overlay.size.height / 2,
        0,
        0,
      ),
      Offset.zero & overlay.size,
    );

    final result = await showMenu<String>(
      context: context,
      position: position,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: context.colors.scaffoldBackground,
      elevation: 8,
      items: [
        _menuPopupItem(context, 'Reply', CommonIcons.reply),
        _menuPopupItem(context, 'Copy', CommonIcons.copy),
        if (isMe) _menuPopupItem(context, 'Edit', CommonIcons.edit),
        _menuPopupItem(context, msg.isPinned ? 'Unpin' : 'Pin', CommonIcons.pin),
        _menuPopupItem(context, 'Forward', CommonIcons.forward),
        _menuPopupItem(context, 'Info', CommonIcons.infoOutline),
        _menuPopupItem(context, 'Select', CommonIcons.selectAll),
        _menuPopupItem(context, 'Delete', CommonIcons.deleteOutline, isDestructive: true),
      ],
    );

    if (result == null || !context.mounted) return;

    if (result == 'Reply') {
      setState(() {
        _replyingToMessage = msg;
        _editingMessage = null;
      });
    } else if (result == 'Copy') {
      Clipboard.setData(ClipboardData(text: msg.content));
      context.showSuccessNotification('Message copied to clipboard');
    } else if (result == 'Edit') {
      setState(() {
        _editingMessage = msg;
        _replyingToMessage = null;
        _messageController.text = msg.content;
        _isTyping = true;
      });
    } else if (result == 'Pin' || result == 'Unpin') {
      final shouldPin = !msg.isPinned;
      _chatBloc.add(PinMessageEvent(
        messageId: msg.id,
        conversationId: widget.conversationId,
        isPinned: shouldPin,
      ));
      
      if (_pinnedBox != null) {
        if (shouldPin) {
          await _pinnedBox!.put(widget.conversationId, msg.copyWith(isPinned: true).toJson());
          setState(() {
            _pinnedMessage = msg.copyWith(isPinned: true);
          });
        } else {
          await _pinnedBox!.delete(widget.conversationId);
          setState(() {
            _pinnedMessage = null;
          });
        }
      }
    } else if (result == 'Forward') {
      _showForwardDialog(context, msg.content);
    } else if (result == 'Info') {
      _showMessageInfo(context, msg);
    } else if (result == 'Select') {
      setState(() {
        _selectedMessageIds.add(msg.id);
      });
    } else if (result == 'Delete') {
      _showDeleteDialog(context, [msg]);
    }
  }

  PopupMenuEntry<String> _menuPopupItem(
    BuildContext context,
    String value,
    IconData icon, {
    bool isDestructive = false,
  }) {
    return PopupMenuItem<String>(
      value: value,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              value,
              style: context.bodyMedium.copyWith(
                color: isDestructive ? context.colors.error : context.colors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
            Icon(
              icon,
              size: 16,
              color: isDestructive ? context.colors.error : context.colors.primary,
            ),
          ],
        ),
      ),
    );
  }

  void _showMessageInfo(BuildContext context, MessageModel msg) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            color: context.colors.scaffoldBackground,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: context.colors.textHint.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Text(
                    'Message Info',
                    style: context.titleLarge.copyWith(fontWeight: FontWeight.bold),
                  ),
                  CommonSpaces.h16,
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: context.colors.lightBackground,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      msg.content,
                      style: context.bodyLarge,
                    ),
                  ),
                  CommonSpaces.h20,
                  Divider(color: context.colors.primary.withValues(alpha: 0.3)),
                  CommonSpaces.h20,
                  Row(
                    children: [
                      Icon(CommonIcons.check, color: context.colors.primary, size: 20),
                      CommonSpaces.w12,
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Sent', style: context.titleSmall.copyWith(fontWeight: FontWeight.bold)),
                            Text(
                              _formatFullDateTime(msg.createdAt),
                              style: context.bodyMedium.copyWith(color: context.colors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  CommonSpaces.h16,
                  Row(
                    children: [
                      Icon(
                        msg.isRead ? CommonIcons.doneAll : CommonIcons.done,
                        color: msg.isRead ? context.colors.primary : context.colors.textSecondary,
                        size: 20,
                      ),
                      CommonSpaces.w12,
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Read', style: context.titleSmall.copyWith(fontWeight: FontWeight.bold)),
                            Text(
                              msg.isRead 
                                  ? _formatFullDateTime(msg.updatedAt)
                                  : 'Not read yet',
                              style: context.bodyMedium.copyWith(color: context.colors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  CommonSpaces.h20,
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _formatFullDateTime(String timestamp) {
    try {
      DateTime date;
      final parsedInt = int.tryParse(timestamp);
      if (parsedInt != null) {
        if (timestamp.length <= 10) {
          date = DateTime.fromMillisecondsSinceEpoch(parsedInt * 1000).toLocal();
        } else {
          date = DateTime.fromMillisecondsSinceEpoch(parsedInt).toLocal();
        }
      } else {
        date = DateTime.parse(timestamp).toLocal();
      }
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      final monthName = months[date.month - 1];
      final hour = date.hour > 12 ? date.hour - 12 : (date.hour == 0 ? 12 : date.hour);
      final minute = date.minute.toString().padLeft(2, '0');
      final period = date.hour >= 12 ? 'PM' : 'AM';
      return '$monthName ${date.day}, ${date.year} at $hour:$minute $period';
    } catch (e) {
      return timestamp;
    }
  }

  void _showForwardDialog(BuildContext context, String messageText) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    final contacts = await _getForwardContacts();
    
    if (context.mounted) {
      Navigator.pop(context);
    }

    if (contacts.isEmpty) {
      if (context.mounted) {
        context.showInfoNotification('No contacts available for forwarding');
      }
      return;
    }

    if (context.mounted) {
      showDialog(
        context: context,
        builder: (dialogCtx) {
          return AlertDialog(
            backgroundColor: context.colors.scaffoldBackground,
            title: Text(
              'Forward Message',
              style: context.titleLarge.copyWith(fontWeight: FontWeight.bold),
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: contacts.length,
                itemBuilder: (context, index) {
                  final user = contacts[index];
                  final name = user.username ?? user.phoneNumber;
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: context.colors.primary.withValues(alpha: 0.15),
                      child: Text(
                        name.isNotEmpty ? name[0].toUpperCase() : '?',
                        style: TextStyle(color: context.colors.primary, fontWeight: FontWeight.bold),
                      ),
                    ),
                    title: Text(
                      name,
                      style: context.titleSmall.copyWith(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      user.about ?? 'Hey there! I am using Schat.',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.bodySmall.copyWith(color: context.colors.textSecondary),
                    ),
                    trailing: TextButton(
                      child: Text('Send', style: TextStyle(color: context.colors.primary, fontWeight: FontWeight.bold)),
                      onPressed: () async {
                        Navigator.pop(dialogCtx);
                        
                        context.showInfoNotification('Forwarding to $name...');

                        try {
                          final dashboardRepo = getIt<DashboardRepository>();
                          final socketRepo = getIt<ChatSocketRepository>();
                          final result = await dashboardRepo.startDirectChat(user.id);
                          
                          result.when(
                            success: (chat) {
                              socketRepo.emit('message', {
                                'type': 'text',
                                'conversationId': chat.id,
                                'conversation_id': chat.id,
                                'text': messageText,
                              });
                              
                              context.showSuccessNotification('Message forwarded to $name');
                            },
                            failure: (error, statusCode) {
                              context.showErrorNotification('Failed to forward: $error');
                            },
                          );
                        } catch (e) {
                          context.showErrorNotification('Error: $e');
                        }
                      },
                    ),
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                child: Text('Cancel', style: TextStyle(color: context.colors.textSecondary)),
                onPressed: () => Navigator.pop(dialogCtx),
              ),
            ],
          );
        },
      );
    }
  }

  void _showDeleteDialog(BuildContext context, List<MessageModel> messages) {
    final myId = (_chatBloc.state as ChatLoaded).myId;
    final allFromMe = messages.every((msg) => msg.senderId == myId);

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          backgroundColor: context.colors.scaffoldBackground,
          title: Text(
            'Delete Message${messages.length > 1 ? "s" : ""}',
            style: context.titleLarge.copyWith(fontWeight: FontWeight.bold),
          ),
          content: Text(
            'Are you sure you want to delete ${messages.length > 1 ? "these messages" : "this message"}?',
            style: context.bodyMedium,
          ),
          actions: [
            TextButton(
              child: Text('Cancel', style: TextStyle(color: context.colors.textSecondary)),
              onPressed: () => Navigator.pop(dialogCtx),
            ),
            TextButton(
              child: Text('Delete for me', style: TextStyle(color: context.colors.error)),
              onPressed: () {
                Navigator.pop(dialogCtx);
                final ids = messages.map((m) => m.id).toList();
                _chatBloc.add(DeleteMessagesEvent(
                  messageIds: ids,
                  conversationId: widget.conversationId,
                  deleteType: 'me',
                ));
                setState(() {
                  _selectedMessageIds.clear();
                });
              },
            ),
            if (allFromMe)
              TextButton(
                child: Text('Delete for everyone', style: TextStyle(color: context.colors.error, fontWeight: FontWeight.bold)),
                onPressed: () {
                  Navigator.pop(dialogCtx);
                  final ids = messages.map((m) => m.id).toList();
                  _chatBloc.add(DeleteMessagesEvent(
                    messageIds: ids,
                    conversationId: widget.conversationId,
                    deleteType: 'everyone',
                  ));
                  setState(() {
                    _selectedMessageIds.clear();
                  });
                },
              ),
          ],
        );
      },
    );
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
    final hasAttachment = _selectedAttachmentType != null;
    final shouldShowSend = hasText || hasAttachment;
    if (shouldShowSend != _isTyping) {
      setState(() {
        _isTyping = shouldShowSend;
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

    if (_selectedAttachmentType != null) {
      await _uploadAndSendAttachment(context);
      return;
    }

    if (text.isEmpty) return;

    if (_editingMessage != null) {
      _chatBloc.add(EditMessageEvent(
        messageId: _editingMessage!.id,
        conversationId: widget.conversationId,
        newContent: text,
      ));
      setState(() {
        _editingMessage = null;
      });
    } else {
      // Send via socket
      context.read<ChatSocketBloc>().add(SendMessage(
        conversationId: widget.conversationId,
        type: 'text',
        text: text,
        replyMessageId: _replyingToMessage?.id,
      ));

      // Optimistically update UI
      _chatBloc.add(SendMessageEvent(
        conversationId: widget.conversationId,
        text: text,
        replyMessageId: _replyingToMessage?.id,
        replyMessageBody: _replyingToMessage?.content,
      ));

      setState(() {
        _replyingToMessage = null;
      });
    }

    _messageController.clear();
    _stopTypingTimer();
    context.read<ChatSocketBloc>().add(SendTypingIndicator(widget.conversationId, isTyping: false));
    setState(() {
      _isTyping = false;
    });
  }

  Future<void> _uploadAndSendAttachment(BuildContext context) async {
    final String type = _selectedAttachmentType!;
    final String name = _selectedAttachmentName ?? 'File';
    final Uint8List? bytes = _selectedAttachmentBytes;
    final String? path = _selectedAttachmentPath;
    final int size = _selectedAttachmentSize;
    final String caption = _messageController.text.trim();
    final bool allowShare = _attachmentAllowShare;
    final bool allowDownload = _attachmentAllowDownload;
    final bool allowView = _attachmentAllowView;

    // Clear preview states immediately so UI is responsive
    setState(() {
      _selectedAttachmentPath = null;
      _selectedAttachmentBytes = null;
      _selectedAttachmentName = null;
      _selectedAttachmentType = null;
      _selectedAttachmentSize = 0;
      _attachmentAllowShare = true;
      _attachmentAllowDownload = true;
      _attachmentAllowView = true;
      _messageController.clear();
      _isTyping = false;
    });

    if (type == 'location' || type == 'contact') {
      context.read<ChatBloc>().add(SendMessageEvent(
        conversationId: widget.conversationId,
        text: caption.isNotEmpty ? caption : name,
        type: type,
        attachmentPath: path,
        attachmentName: name,
        allowShare: allowShare,
        allowDownload: allowDownload,
        allowView: allowView,
        fileSize: size,
      ));

      context.read<ChatSocketBloc>().add(SendMessage(
        conversationId: widget.conversationId,
        type: type,
        text: caption.isNotEmpty ? caption : name,
        fileKey: path,
        viewControl: {
          'allowShare': allowShare,
          'allowDownload': allowDownload,
          'allowView': allowView,
        },
      ));
      return;
    }

    // 1. Send optimistic message event immediately to ChatBloc (shows loader)
    context.read<ChatBloc>().add(SendMessageEvent(
      conversationId: widget.conversationId,
      text: caption.isNotEmpty ? caption : (type == 'image' ? '' : name),
      type: type,
      attachmentPath: path,
      attachmentName: name,
      attachmentBytes: bytes,
      allowShare: allowShare,
      allowDownload: allowDownload,
      allowView: allowView,
      fileSize: size,
    ));

    // 2. Perform the upload and socket broadcast in the background
    _performBackgroundUploadAndSend(
      context: context,
      type: type,
      name: name,
      bytes: bytes,
      path: path,
      size: size,
      caption: caption,
      allowShare: allowShare,
      allowDownload: allowDownload,
      allowView: allowView,
    );
  }

  Future<void> _performBackgroundUploadAndSend({
    required BuildContext context,
    required String type,
    required String name,
    required Uint8List? bytes,
    required String? path,
    required int size,
    required String caption,
    required bool allowShare,
    required bool allowDownload,
    required bool allowView,
  }) async {
    String? fileKey;
    try {
      final repo = getIt<ChatRepository>();
      fileKey = await repo.uploadMedia(
        conversationId: widget.conversationId,
        filePath: path ?? '',
        fileName: name,
        mediaType: _getMediaType(type),
        mimeType: _getMimeType(name, type),
        fileSizeBytes: size,
        fileBytes: bytes,
      );
    } catch (e) {
      debugPrint('Background upload error: $e');
      if (context.mounted) {
        context.showErrorNotification('Upload failed: $e');
      }
      return;
    }

    if (fileKey != null && context.mounted) {
      context.read<ChatSocketBloc>().add(SendMessage(
        conversationId: widget.conversationId,
        type: type,
        text: caption.isNotEmpty ? caption : (type == 'image' ? '' : name),
        fileKey: fileKey,
        fileName: name,
        fileSize: size,
        mimeType: _getMimeType(name, type),
        viewControl: {
          'allowShare': allowShare,
          'allowDownload': allowDownload,
          'allowView': allowView,
        },
      ));
    }
  }

  Widget _buildAttachmentPreview() {
    final isImage = _selectedAttachmentType == 'image';
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: context.colors.lightBackground,
        border: Border(
          top: BorderSide(color: context.colors.border, width: 1),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Preview thumbnail/icon
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 56,
                  height: 56,
                  color: context.colors.scaffoldBackground,
                  child: isImage
                      ? (_selectedAttachmentBytes != null
                          ? Image.memory(
                              _selectedAttachmentBytes!,
                              fit: BoxFit.cover,
                            )
                          : const Icon(CommonIcons.gallery, size: 28))
                      : Center(
                          child: Icon(
                            _selectedAttachmentType == 'video'
                                ? CommonIcons.playCircle
                                : _selectedAttachmentType == 'audio'
                                    ? CommonIcons.audio
                                    : _selectedAttachmentType == 'location'
                                        ? CommonIcons.location
                                        : _selectedAttachmentType == 'contact'
                                            ? CommonIcons.person
                                            : CommonIcons.document,
                            color: context.colors.primary,
                            size: 28,
                          ),
                        ),
                ),
              ),
              CommonSpaces.w12,
              // Attachment Name / Size details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _selectedAttachmentName ?? 'Attachment',
                      style: context.bodyMedium.copyWith(
                        fontWeight: FontWeight.bold,
                        color: context.colors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    CommonSpaces.h4,
                    Text(
                      _selectedAttachmentType == 'location'
                          ? 'Location share'
                          : _selectedAttachmentType == 'contact'
                              ? 'Contact card'
                              : _formatBytes(_selectedAttachmentSize),
                      style: context.bodySmall.copyWith(
                        color: context.colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              // Clear Button
              IconButton(
                icon: Icon(CommonIcons.close, color: context.colors.textSecondary),
                onPressed: () {
                  setState(() {
                    _selectedAttachmentPath = null;
                    _selectedAttachmentBytes = null;
                    _selectedAttachmentName = null;
                    _selectedAttachmentType = null;
                    _selectedAttachmentSize = 0;
                    _attachmentAllowShare = true;
                    _attachmentAllowDownload = true;
                    _attachmentAllowView = true;
                    _isTyping = _messageController.text.trim().isNotEmpty;
                  });
                },
              ),
            ],
          ),
          if (_selectedAttachmentType != 'location' && _selectedAttachmentType != 'contact') ...[
            CommonSpaces.h12,
            const Divider(height: 1, thickness: 1),
            CommonSpaces.h12,
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildPermissionToggle(
                  icon: _attachmentAllowView ? Icons.visibility : Icons.visibility_off,
                  label: 'View',
                  isActive: _attachmentAllowView,
                  onTap: () {
                    setState(() {
                      _attachmentAllowView = !_attachmentAllowView;
                    });
                  },
                ),
                _buildPermissionToggle(
                  icon: _attachmentAllowDownload ? Icons.download : Icons.download_for_offline_outlined,
                  label: 'Download',
                  isActive: _attachmentAllowDownload,
                  onTap: () {
                    setState(() {
                      _attachmentAllowDownload = !_attachmentAllowDownload;
                    });
                  },
                ),
                _buildPermissionToggle(
                  icon: Icons.share,
                  label: 'Share',
                  isActive: _attachmentAllowShare,
                  onTap: () {
                    setState(() {
                      _attachmentAllowShare = !_attachmentAllowShare;
                    });
                  },
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPermissionToggle({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isActive
                ? context.colors.primary.withValues(alpha: 0.12)
                : context.colors.textHint.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isActive
                  ? context.colors.primary.withValues(alpha: 0.3)
                  : context.colors.textHint.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 18,
                color: isActive ? context.colors.primary : context.colors.textSecondary,
              ),
              CommonSpaces.w8,
              Text(
                label,
                style: context.bodyMedium.copyWith(
                  fontSize: 12,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  color: isActive ? context.colors.primary : context.colors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatBytes(int bytes) {
    if (bytes <= 0) return "0 B";
    const suffixes = ["B", "KB", "MB", "GB"];
    var i = 0;
    double w = bytes.toDouble();
    while (w >= 1024 && i < suffixes.length - 1) {
      w /= 1024;
      i++;
    }
    return "${w.toStringAsFixed(1)} ${suffixes[i]}";
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
          final customBgColor = state is ChatLoaded ? state.customBgColor : null;

          return Scaffold(
            backgroundColor: customBgColor ?? context.colors.scaffoldBackground,
            appBar: _buildAppBar(context, state),
            body: SafeArea(
              child: Column(
                children: [
                  _buildPinnedMessageBanner(),
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
                                  
                                  String? replySenderName;
                                  if (msg.isReply && msg.replyMessageId != null) {
                                    try {
                                      final parent = messages.firstWhere((m) => m.id == msg.replyMessageId);
                                      replySenderName = (state is ChatLoaded && parent.senderId == state.myId)
                                          ? 'You'
                                          : widget.contactName;
                                    } catch (_) {
                                      replySenderName = isMe ? widget.contactName : 'You';
                                    }
                                  }

                                   return GestureDetector(
                                    onTapDown: (details) {
                                      _tapPosition = details.globalPosition;
                                    },
                                    onLongPress: () {
                                      if (msg.isDeleted) return;
                                      if (_selectedMessageIds.isEmpty) {
                                        _showMessageMenu(context, msg, isMe, _tapPosition);
                                      }
                                    },
                                    onTap: () {
                                      if (msg.isDeleted) return;
                                      if (_selectedMessageIds.isNotEmpty) {
                                        setState(() {
                                          if (_selectedMessageIds.contains(msg.id)) {
                                            _selectedMessageIds.remove(msg.id);
                                          } else {
                                            _selectedMessageIds.add(msg.id);
                                          }
                                        });
                                      }
                                    },
                                    child: MessageBubble(
                                      messageId: msg.id,
                                      conversationId: widget.conversationId,
                                      message: msg.content,
                                      time: _formatTime(msg.createdAt),
                                      isMe: isMe,
                                      isRead: msg.isRead,
                                      type: msg.mediaType ?? 'text',
                                      attachmentPath: msg.mediaUrl,
                                      attachmentName: msg.attachmentName ?? (msg.content.isNotEmpty ? msg.content : 'File'),
                                      attachmentBytes: msg.attachmentBytes,
                                      isReply: msg.isReply,
                                      replyMessageBody: msg.replyMessageBody,
                                      replyMessageSenderName: replySenderName,
                                      isEdited: msg.isEdited,
                                      isSelected: _selectedMessageIds.contains(msg.id),
                                      isUploading: msg.isUploading,
                                      allowShare: msg.allowShare,
                                      allowDownload: msg.allowDownload,
                                      allowView: msg.allowView,
                                      onSharePressed: () => _showForwardDialog(context, msg.mediaUrl ?? msg.content),
                                      fileSize: msg.fileSize,
                                    ),
                                  );
                                },
                              ),
                  ),
                  _buildBottomSection(context),
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
      DateTime date;
      final parsedInt = int.tryParse(createdAt);
      if (parsedInt != null) {
        if (createdAt.length <= 10) {
          date = DateTime.fromMillisecondsSinceEpoch(parsedInt * 1000).toLocal();
        } else {
          date = DateTime.fromMillisecondsSinceEpoch(parsedInt).toLocal();
        }
      } else {
        date = DateTime.parse(createdAt).toLocal();
      }
      final hour = date.hour > 12 ? date.hour - 12 : (date.hour == 0 ? 12 : date.hour);
      final minute = date.minute.toString().padLeft(2, '0');
      final period = date.hour >= 12 ? 'PM' : 'AM';
      return '$hour:$minute $period';
    } catch (e) {
      return '';
    }
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, ChatState state) {
    if (_selectedMessageIds.isNotEmpty) {
      return AppBar(
        backgroundColor: context.colors.primary,
        elevation: 0,
        leading: IconButton(
          icon: Icon(CommonIcons.close, color: context.colors.pureWhite),
          onPressed: () {
            setState(() {
              _selectedMessageIds.clear();
            });
          },
        ),
        title: Text(
          '${_selectedMessageIds.length} selected',
          style: context.titleMedium.copyWith(color: context.colors.pureWhite, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: Icon(CommonIcons.copy, color: context.colors.pureWhite),
            onPressed: () {
              if (state is ChatLoaded) {
                final selectedMsgs = state.messages
                    .where((m) => _selectedMessageIds.contains(m.id))
                    .map((m) => m.content)
                    .join('\n');
                if (selectedMsgs.isNotEmpty) {
                  Clipboard.setData(ClipboardData(text: selectedMsgs));
                  context.showSuccessNotification('Messages copied to clipboard');
                }
              }
              setState(() {
                _selectedMessageIds.clear();
              });
            },
          ),
          IconButton(
            icon: Icon(CommonIcons.reply, color: context.colors.pureWhite),
            onPressed: () {
              if (state is ChatLoaded) {
                final selectedMsgs = state.messages
                    .where((m) => _selectedMessageIds.contains(m.id))
                    .toList();
                if (selectedMsgs.isNotEmpty) {
                  final combinedText = selectedMsgs.map((m) => m.content).join('\n');
                  _showForwardDialog(context, combinedText);
                }
              }
            },
          ),
          IconButton(
            icon: Icon(CommonIcons.delete, color: context.colors.pureWhite),
            onPressed: () {
              if (state is ChatLoaded) {
                final selectedMsgs = state.messages
                    .where((m) => _selectedMessageIds.contains(m.id))
                    .toList();
                _showDeleteDialog(context, selectedMsgs);
              }
            },
          ),
          CommonSpaces.w8,
        ],
      );
    }

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
                  conversationId: widget.conversationId,
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
        PopupMenuButton<String>(
          icon: Icon(CommonIcons.moreVert),
          color: context.colors.scaffoldBackground,
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          onSelected: (value) {
            if (value == 'background_color') {
              _showBackgroundColorBottomSheet(context);
            }
          },
          itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
            PopupMenuItem<String>(
              value: 'background_color',
              child: Row(
                children: [
                  Icon(Icons.color_lens_outlined, color: context.colors.primary, size: 20),
                  CommonSpaces.w8,
                  Text(
                    'Background Color',
                    style: context.bodyMedium.copyWith(
                      color: context.colors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
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

  void _showAttachmentPopup(BuildContext ctx) async {
    final RenderBox? button = ctx.findRenderObject() as RenderBox?;
    final RenderBox overlay = Navigator.of(ctx).overlay!.context.findRenderObject() as RenderBox;
    
    final offset = button?.localToGlobal(Offset.zero, ancestor: overlay) ?? Offset.zero;
    final position = RelativeRect.fromLTRB(
      offset.dx,
      offset.dy - 260, // position above the input field
      offset.dx + (button?.size.width ?? 0),
      offset.dy,
    );

    final result = await showMenu<String>(
      context: ctx,
      position: position,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: ctx.colors.scaffoldBackground,
      elevation: 8,
      constraints: const BoxConstraints(minWidth: 200, maxWidth: 200),
      items: [
        _attachmentPopupItem(ctx, 'Files', Icons.attachment),
        _attachmentPopupItem(ctx, 'Camera', Icons.camera_alt_outlined),
        _attachmentPopupItem(ctx, 'Poll', Icons.bar_chart_outlined),
        _attachmentPopupItem(ctx, 'Events', Icons.calendar_month_outlined),
        _attachmentPopupItem(ctx, 'Contact', Icons.person_outline_rounded),
      ],
    );

    if (result == null || !ctx.mounted) return;

    if (result == 'Files') {
      _pickFile(FileType.any);
    } else if (result == 'Camera') {
      _pickImage(ImageSource.camera);
    } else if (result == 'Poll') {
      ctx.showInfoNotification('Poll feature is coming soon!');
    } else if (result == 'Events') {
      ctx.showInfoNotification('Events feature is coming soon!');
    } else if (result == 'Contact') {
      _showContactPicker(ctx);
    }
  }

  PopupMenuEntry<String> _attachmentPopupItem(BuildContext context, String value, IconData icon) {
    return PopupMenuItem<String>(
      value: value,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              value,
              style: context.bodyMedium.copyWith(
                color: context.colors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
            Icon(
              icon,
              size: 18,
              color: context.colors.primary,
            ),
          ],
        ),
      ),
    );
  }



  String _getMimeType(String filename, String type) {
    final ext = filename.split('.').last.toLowerCase();
    switch (ext) {
      case 'png':
        return 'image/png';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      case 'svg':
        return 'image/svg+xml';
      case 'pdf':
        return 'application/pdf';
      case 'txt':
        return 'text/plain';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'xls':
        return 'application/vnd.ms-excel';
      case 'xlsx':
        return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      case 'csv':
        return 'text/csv';
      case 'mp3':
        return 'audio/mpeg';
      case 'wav':
        return 'audio/wav';
      case 'mp4':
        return 'video/mp4';
      case 'webm':
        return type == 'audio' ? 'audio/webm' : 'video/webm';
      case 'ogg':
        return type == 'audio' ? 'audio/ogg' : 'video/ogg';
      case 'avi':
        return 'video/x-msvideo';
      case 'json':
        return 'application/json';
      case 'zip':
        return 'application/zip';
      case 'xml':
        return 'application/xml';
      default:
        return 'application/octet-stream';
    }
  }

  String _getMediaType(String type) {
    switch (type) {
      case 'image':
        return 'CHAT_IMAGE';
      case 'video':
        return 'CHAT_VIDEO';
      case 'audio':
        return 'VOICE_NOTE';
      default:
        return 'DOCUMENT';
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: source, imageQuality: 80);
    if (image == null || !mounted) return;

    final String name = image.name;
    final int size = await image.length();
    if (!mounted) return;

    final Uint8List bytes = await image.readAsBytes();
    if (!mounted) return;

    setState(() {
      _selectedAttachmentPath = kIsWeb ? null : image.path;
      _selectedAttachmentBytes = bytes;
      _selectedAttachmentName = name;
      _selectedAttachmentType = 'image';
      _selectedAttachmentSize = size;
      _attachmentAllowShare = true;
      _attachmentAllowDownload = true;
      _attachmentAllowView = true;
      _isTyping = true;
    });
  }

  Future<void> _pickFile(FileType type) async {
    FilePickerResult? result = await FilePicker.pickFiles(
      type: type,
      withData: true,
    );
    if (result == null || !mounted) return;
    final PlatformFile file = result.files.single;
    final String fileType = type == FileType.audio
        ? 'audio'
        : type == FileType.video
            ? 'video'
            : 'file';

    setState(() {
      _selectedAttachmentPath = file.path;
      _selectedAttachmentBytes = file.bytes;
      _selectedAttachmentName = file.name;
      _selectedAttachmentType = fileType;
      _selectedAttachmentSize = file.size;
      _attachmentAllowShare = true;
      _attachmentAllowDownload = true;
      _attachmentAllowView = true;
      _isTyping = true;
    });
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
                Icon(CommonIcons.location, color: ctx.colors.primary, size: 28),
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
                    Icon(CommonIcons.location, color: ctx.colors.primary, size: 48),
                  ],
                ),
              ),
            ),
            const SizedBox(height: CommonSizes.p16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: Icon(CommonIcons.myLocation, color: ctx.colors.primary),
                    label: const Text('Current Location'),
                    onPressed: () {
                      Navigator.pop(ctx);
                      setState(() {
                        _selectedAttachmentPath = 'location';
                        _selectedAttachmentName = 'My Location';
                        _selectedAttachmentType = 'location';
                        _selectedAttachmentBytes = null;
                        _selectedAttachmentSize = 0;
                        _attachmentAllowShare = true;
                        _attachmentAllowDownload = true;
                        _attachmentAllowView = true;
                        _isTyping = true;
                      });
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
                  setState(() {
                    _selectedAttachmentPath = 'contact:${c['phone']}';
                    _selectedAttachmentName = '${c['name']} · ${c['phone']}';
                    _selectedAttachmentType = 'contact';
                    _selectedAttachmentBytes = null;
                    _selectedAttachmentSize = 0;
                    _attachmentAllowShare = true;
                    _attachmentAllowDownload = true;
                    _attachmentAllowView = true;
                    _isTyping = true;
                  });
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

  List<Color> _generateHarmoniousColors(bool isDark) {
    final random = Random();
    return List.generate(10, (index) {
      final double hue = random.nextDouble() * 360;
      final double saturation = 0.4 + random.nextDouble() * 0.25; // 40% - 65%
      final double lightness = isDark
          ? 0.12 + random.nextDouble() * 0.08 // 12% - 20% for dark background readability
          : 0.88 + random.nextDouble() * 0.06; // 88% - 94% for light background readability
      return HSLColor.fromAHSL(1.0, hue, saturation, lightness).toColor();
    });
  }

  void _showBackgroundColorBottomSheet(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorsList = _generateHarmoniousColors(isDark);
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              decoration: BoxDecoration(
                color: context.colors.scaffoldBackground,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 20),
                          decoration: BoxDecoration(
                            color: context.colors.textHint.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Choose Wallpaper',
                            style: context.titleLarge.copyWith(fontWeight: FontWeight.bold),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(sheetCtx);
                              // Reset to default
                              _chatBloc.add(ChangeBackgroundColorEvent(
                                color: context.colors.scaffoldBackground,
                                conversationId: widget.conversationId,
                              ));
                              // Notify other user to reset as well
                              context.read<ChatSocketBloc>().add(SendMessage(
                                conversationId: widget.conversationId,
                                type: 'change_background_color',
                                text: context.colors.scaffoldBackground.toARGB32().toString(),
                              ));
                            },
                            child: Text(
                              'Reset',
                              style: TextStyle(
                                color: context.colors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      CommonSpaces.h8,
                      Text(
                        'Select a custom background color to personalize this chat.',
                        style: context.bodyMedium.copyWith(color: context.colors.textSecondary),
                      ),
                      CommonSpaces.h20,
                      // Grid of 10 colors
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 5,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                        ),
                        itemCount: colorsList.length,
                        itemBuilder: (context, index) {
                          final color = colorsList[index];
                          final isSelected = _chatBloc.state is ChatLoaded &&
                              (_chatBloc.state as ChatLoaded).customBgColor?.toARGB32() == color.toARGB32();
                              
                          return GestureDetector(
                            onTap: () {
                              Navigator.pop(sheetCtx);
                              
                              // Local update and Hive save
                              _chatBloc.add(ChangeBackgroundColorEvent(
                                color: color,
                                conversationId: widget.conversationId,
                              ));
                              
                              // Send change via socket
                              context.read<ChatSocketBloc>().add(SendMessage(
                                conversationId: widget.conversationId,
                                type: 'change_background_color',
                                text: color.toARGB32().toString(),
                              ));
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected ? context.colors.primary : Colors.transparent,
                                  width: 3,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.1),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: isSelected
                                  ? Icon(
                                      Icons.check_circle_rounded,
                                      color: context.colors.primary,
                                      size: 24,
                                    )
                                  : null,
                            ),
                          );
                        },
                      ),
                      CommonSpaces.h12,
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
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
