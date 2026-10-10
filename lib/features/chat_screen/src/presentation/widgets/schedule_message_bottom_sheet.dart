import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:schat/core/security/secure_attachment_service.dart';
import 'package:schat/injection.dart';
import 'package:schat/utils/common_endpoints.dart';
import 'package:schat/utils/common_notifications.dart';
import 'package:schat/features/chat_screen/src/domain/models/scheduled_message_model.dart';
import 'package:schat/features/chat_screen/src/domain/repositories/chat_repository.dart';
import 'package:schat/utils/common_colors.dart';
import 'package:schat/utils/common_fonts.dart';
import 'package:schat/utils/common_fontstyles.dart';
import 'package:schat/utils/common_icons.dart';
import 'package:schat/utils/common_spaces.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:schat/features/chat_screen/src/presentation/widgets/in_app_viewer.dart';

enum ScheduledMessageType { text, image, video, document, audio }

class ScheduleMessageBottomSheet extends StatefulWidget {
  final String contactName;
  final String? conversationId;
  final Function(
    DateTime scheduledDateTime,
    String text,
    File? attachment,
    ScheduledMessageType type,
  )? onSchedule;

  const ScheduleMessageBottomSheet({
    super.key,
    required this.contactName,
    this.conversationId,
    this.onSchedule,
  });

  @override
  State<ScheduleMessageBottomSheet> createState() =>
      _ScheduleMessageBottomSheetState();
}

class _ScheduleMessageBottomSheetState extends State<ScheduleMessageBottomSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _messageController = TextEditingController();

  ScheduledMessageType _selectedType = ScheduledMessageType.text;
  File? _attachedFile;
  String? _attachedFileName;
  int? _attachedFileSize;

  late DateTime _selectedDate;
  int _selectedHour = 12;
  int _selectedMinute = 0;
  int _selectedSecond = 0;
  bool _isPm = true;

  String? _errorMessage;
  bool _isSubmitting = false;
  double _uploadProgress = 0.0;
  String _uploadStatusText = '';
  int _uploadPercentage = 0;

  // Tab 2: Scheduled Messages List State
  List<ScheduledMessageModel> _scheduledMessages = [];
  bool _isLoadingList = false;
  String? _listErrorMessage;
  ScheduledMessageModel? _editingMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });

    _initDateTime(DateTime.now().add(const Duration(hours: 1)));
    _fetchScheduledMessages();
  }

  void _initDateTime(DateTime dt) {
    _selectedDate = DateTime(dt.year, dt.month, dt.day);
    int hour24 = dt.hour;
    _isPm = hour24 >= 12;
    _selectedHour = hour24 % 12 == 0 ? 12 : hour24 % 12;
    _selectedMinute = dt.minute;
    _selectedSecond = dt.second;
  }

  @override
  void dispose() {
    _tabController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _fetchScheduledMessages() async {
    if (!mounted) return;
    setState(() {
      _isLoadingList = true;
      _listErrorMessage = null;
    });

    try {
      if (getIt.isRegistered<ChatRepository>()) {
        final repo = getIt<ChatRepository>();
        final list = await repo.getScheduledMessages(
          conversationId: widget.conversationId,
        );
        if (mounted) {
          setState(() {
            _scheduledMessages = list;
            _isLoadingList = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoadingList = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _listErrorMessage = 'Could not load scheduled messages';
          _isLoadingList = false;
        });
      }
    }
  }

  DateTime get _computedDateTime {
    int hour24 = _selectedHour % 12;
    if (_isPm) {
      hour24 += 12;
    }
    return DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      hour24,
      _selectedMinute,
      _selectedSecond,
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate.isBefore(now) ? now : _selectedDate,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: context.colors.primary,
              onPrimary: context.colors.textLight,
              surface: context.colors.cardBackground,
              onSurface: context.colors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _errorMessage = null;
      });
    }
  }

  bool _isPickingFile = false;

  Future<void> _pickAttachment() async {
    if (_isPickingFile) return;
    _isPickingFile = true;
    try {
      if (_selectedType == ScheduledMessageType.image) {
        final picker = ImagePicker();
        final picked = await picker.pickImage(source: ImageSource.gallery);
        if (picked != null) {
          final f = File(picked.path);
          final size = await f.length();
          setState(() {
            _attachedFile = f;
            _attachedFileName = picked.name;
            _attachedFileSize = size;
            _errorMessage = null;
          });
        }
      } else if (_selectedType == ScheduledMessageType.video) {
        final picker = ImagePicker();
        final picked = await picker.pickVideo(source: ImageSource.gallery);
        if (picked != null) {
          final f = File(picked.path);
          final size = await f.length();
          setState(() {
            _attachedFile = f;
            _attachedFileName = picked.name;
            _attachedFileSize = size;
            _errorMessage = null;
          });
        }
      } else if (_selectedType == ScheduledMessageType.audio) {
        FilePickerResult? result;
        try {
          result = await FilePicker.pickFiles(
            type: FileType.custom,
            allowedExtensions: ['mp3', 'm4a', 'wav', 'aac', 'ogg', 'opus', 'flac', 'caf'],
          );
        } catch (_) {
          result = await FilePicker.pickFiles(type: FileType.audio);
        }
        final audioRes = result;
        if (audioRes != null && audioRes.files.isNotEmpty && audioRes.files.single.path != null) {
          final f = File(audioRes.files.single.path!);
          final size = audioRes.files.single.size > 0 ? audioRes.files.single.size : await f.length();
          setState(() {
            _attachedFile = f;
            _attachedFileName = audioRes.files.single.name;
            _attachedFileSize = size;
            _errorMessage = null;
          });
        }
      } else if (_selectedType == ScheduledMessageType.document) {
        final docRes = await FilePicker.pickFiles(type: FileType.any);
        if (docRes != null && docRes.files.isNotEmpty && docRes.files.single.path != null) {
          final f = File(docRes.files.single.path!);
          final size = docRes.files.single.size > 0 ? docRes.files.single.size : await f.length();
          setState(() {
            _attachedFile = f;
            _attachedFileName = docRes.files.single.name;
            _attachedFileSize = size;
            _errorMessage = null;
          });
        }
      }
    } catch (e) {
      if (!e.toString().contains('multiple_request')) {
        setState(() {
          _errorMessage = 'Failed to pick attachment: $e';
        });
      }
    } finally {
      _isPickingFile = false;
    }
  }

  void _startEditing(ScheduledMessageModel message) {
    setState(() {
      _editingMessage = message;
      _messageController.text = message.text;
      _attachedFile = null;
      _attachedFileName = message.fileName;
      _attachedFileSize = message.fileSize > 0 ? message.fileSize : null;

      if (message.messageType == 'image') {
        _selectedType = ScheduledMessageType.image;
      } else if (message.messageType == 'video') {
        _selectedType = ScheduledMessageType.video;
      } else if (message.messageType == 'document') {
        _selectedType = ScheduledMessageType.document;
      } else if (message.messageType == 'audio' || message.messageType == 'voice_note') {
        _selectedType = ScheduledMessageType.audio;
      } else {
        _selectedType = ScheduledMessageType.text;
      }

      _initDateTime(message.scheduledAt);
      _errorMessage = null;
    });

    _tabController.animateTo(0);
  }

  void _cancelEditing() {
    setState(() {
      _editingMessage = null;
      _messageController.clear();
      _attachedFile = null;
      _attachedFileName = null;
      _attachedFileSize = null;
      _selectedType = ScheduledMessageType.text;
      _initDateTime(DateTime.now().add(const Duration(hours: 1)));
      _errorMessage = null;
      _uploadProgress = 0.0;
      _uploadStatusText = '';
      _uploadPercentage = 0;
    });
  }

  Future<void> _validateAndSubmit() async {
    setState(() {
      _errorMessage = null;
    });

    final text = _messageController.text.trim();
    if (text.isEmpty && _attachedFile == null && (_attachedFileName == null || _attachedFileName!.isEmpty)) {
      setState(() {
        _errorMessage = 'Please enter a message or attach a file.';
      });
      return;
    }

    final scheduled = _computedDateTime;
    final now = DateTime.now();
    if (!scheduled.isAfter(now)) {
      setState(() {
        _errorMessage = 'Scheduled date & time must be in the future.';
      });
      return;
    }

    // If editing existing scheduled message
    if (_editingMessage != null) {
      setState(() {
        _isSubmitting = true;
        _uploadProgress = 0.0;
        _uploadPercentage = 0;
        _uploadStatusText = 'Updating scheduled message...';
      });

      try {
        if (getIt.isRegistered<ChatRepository>()) {
          final repo = getIt<ChatRepository>();
          String typeStr = 'text';
          if (_selectedType == ScheduledMessageType.image) typeStr = 'image';
          if (_selectedType == ScheduledMessageType.video) typeStr = 'video';
          if (_selectedType == ScheduledMessageType.document) typeStr = 'document';
          if (_selectedType == ScheduledMessageType.audio) typeStr = 'audio';

          String? fileKey = _editingMessage!.fileKey;
          String? fileName = _attachedFileName ?? _editingMessage!.fileName;
          int fileSize = _attachedFileSize ?? _editingMessage!.fileSize;
          String? mimeType = _editingMessage!.mimeType;

          if (_attachedFile != null) {
            fileName = _attachedFile!.path.split('/').last;
            fileSize = await _attachedFile!.length();
            mimeType = _getMimeType(_attachedFile!.path, typeStr);

            setState(() {
              _uploadProgress = 0.05;
              _uploadPercentage = 5;
              _uploadStatusText = 'Preparing $typeStr upload... 5%';
            });

            fileKey = await repo.uploadMedia(
              conversationId: widget.conversationId ?? _editingMessage!.conversationId,
              filePath: _attachedFile!.path,
              fileName: fileName,
              mediaType: _getMediaType(typeStr),
              mimeType: mimeType,
              fileSizeBytes: fileSize,
              onProgress: (p) {
                if (mounted) {
                  setState(() {
                    _uploadProgress = p;
                    _uploadPercentage = (p * 100).clamp(0, 100).toInt();
                    _uploadStatusText = 'Uploading $typeStr... $_uploadPercentage%';
                  });
                }
              },
            );

            if (mounted) {
              setState(() {
                _uploadProgress = 0.95;
                _uploadPercentage = 95;
                _uploadStatusText = 'Finalizing update... 95%';
              });
            }
          }

          final bool isMedia = _selectedType != ScheduledMessageType.text;
          final updatePayload = <String, dynamic>{
            'messageType': typeStr,
            'message_type': typeStr,
            'content': {
              'text': text,
              'fileName': fileName,
              'file_name': fileName,
              'fileKey': fileKey,
              'file_key': fileKey,
              'fileSize': fileSize,
              'file_size': fileSize,
              'mimeType': mimeType,
              'mime_type': mimeType,
            },
            'security': {
              'isLocked': false,
              'accessUsers': [],
              'allowDownload': isMedia ? false : true,
              'allowShare': isMedia ? false : true,
              'allowView': true,
            },
            'viewControl': {
              'type': 'normal',
              'maxViews': 1,
              'viewedBy': [],
              'isOpened': false,
              'allowDownload': isMedia ? false : true,
              'allowShare': isMedia ? false : true,
              'allowView': true,
            },
            'scheduledAt': scheduled.toUtc().toIso8601String(),
            'scheduled_at': scheduled.toUtc().toIso8601String(),
          };

          await repo.updateScheduledMessage(_editingMessage!.id, updatePayload);
          if (mounted) {
            context.showSuccessNotification('Scheduled message updated');
            _cancelEditing();
            await _fetchScheduledMessages();
            _tabController.animateTo(1);
          }
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _errorMessage = 'Failed to update scheduled message: $e';
          });
        }
      } finally {
        if (mounted) {
          setState(() {
            _isSubmitting = false;
            _uploadProgress = 0.0;
            _uploadPercentage = 0;
            _uploadStatusText = '';
          });
        }
      }
      return;
    }

    // New schedule submission
    if (widget.onSchedule != null) {
      widget.onSchedule!(scheduled, text, _attachedFile, _selectedType);
      Navigator.pop(context, {
        'scheduledDateTime': scheduled,
        'text': text,
        'attachment': _attachedFile,
        'type': _selectedType,
      });
    } else {
      // Direct API schedule if no callback provided
      if (widget.conversationId != null) {
        setState(() {
          _isSubmitting = true;
          _uploadProgress = 0.0;
          _uploadPercentage = 0;
          _uploadStatusText = 'Scheduling message...';
        });
        try {
          if (getIt.isRegistered<ChatRepository>()) {
            final repo = getIt<ChatRepository>();
            String typeStr = 'text';
            if (_selectedType == ScheduledMessageType.image) typeStr = 'image';
            if (_selectedType == ScheduledMessageType.video) typeStr = 'video';
            if (_selectedType == ScheduledMessageType.document) typeStr = 'document';
            if (_selectedType == ScheduledMessageType.audio) typeStr = 'audio';

            String? fileKey;
            String? fileName = _attachedFileName;
            int fileSize = _attachedFileSize ?? 0;
            String? mimeType;

            if (_attachedFile != null) {
              fileName = _attachedFile!.path.split('/').last;
              fileSize = await _attachedFile!.length();
              mimeType = _getMimeType(_attachedFile!.path, typeStr);

              setState(() {
                _uploadProgress = 0.05;
                _uploadPercentage = 5;
                _uploadStatusText = 'Preparing $typeStr upload... 5%';
              });

              fileKey = await repo.uploadMedia(
                conversationId: widget.conversationId ?? '',
                filePath: _attachedFile!.path,
                fileName: fileName,
                mediaType: _getMediaType(typeStr),
                mimeType: mimeType,
                fileSizeBytes: fileSize,
                onProgress: (p) {
                  if (mounted) {
                    setState(() {
                      _uploadProgress = p;
                      _uploadPercentage = (p * 100).clamp(0, 100).toInt();
                      _uploadStatusText = 'Uploading $typeStr... $_uploadPercentage%';
                    });
                  }
                },
              );

              if (mounted) {
                setState(() {
                  _uploadProgress = 0.95;
                  _uploadPercentage = 95;
                  _uploadStatusText = 'Saving scheduled message... 95%';
                });
              }
            }

            final bool isMedia = _selectedType != ScheduledMessageType.text;
            final requestData = <String, dynamic>{
              "conversationId": widget.conversationId,
              "conversation_id": widget.conversationId,
              "messageType": typeStr,
              "message_type": typeStr,
              "parentMessageId": null,
              "parent_message_id": null,
              "content": {
                "text": text,
                "fileKey": fileKey,
                "file_key": fileKey,
                "fileName": fileName,
                "file_name": fileName,
                "fileSize": fileSize,
                "file_size": fileSize,
                "mimeType": mimeType,
                "mime_type": mimeType,
                "duration": 0,
                "isForwarded": false,
                "forwardCount": 0,
                "isEdited": false,
              },
              "security": {
                "isLocked": false,
                "accessUsers": [],
                "allowDownload": isMedia ? false : true,
                "allowShare": isMedia ? false : true,
                "allowView": true,
              },
              "viewControl": {
                "type": "normal",
                "maxViews": 1,
                "viewedBy": [],
                "isOpened": false,
                "allowDownload": isMedia ? false : true,
                "allowShare": isMedia ? false : true,
                "allowView": true,
              },
              "expiry": {
                "isEnabled": false,
                "disappearAfterRead": false,
                "readTimerSeconds": 0,
              },
              "callMeta": null,
              "call_meta": null,
              "scheduledAt": scheduled.toUtc().toIso8601String(),
              "scheduled_at": scheduled.toUtc().toIso8601String(),
            };

            await repo.scheduleMessage(requestData);
            if (mounted) {
              context.showSuccessNotification('Message scheduled successfully');
              _cancelEditing();
              await _fetchScheduledMessages();
              _tabController.animateTo(1);
            }
          }
        } catch (e) {
          if (mounted) {
            setState(() {
              _errorMessage = 'Failed to schedule: $e';
            });
          }
        } finally {
          if (mounted) {
            setState(() {
              _isSubmitting = false;
              _uploadProgress = 0.0;
              _uploadPercentage = 0;
              _uploadStatusText = '';
            });
          }
        }
      }
    }
  }

  String _getMimeType(String path, String messageType) {
    final ext = path.split('.').last.toLowerCase();
    if (messageType == 'image') {
      if (ext == 'png') return 'image/png';
      if (ext == 'webp') return 'image/webp';
      if (ext == 'gif') return 'image/gif';
      return 'image/jpeg';
    } else if (messageType == 'video') {
      if (ext == 'mov') return 'video/quicktime';
      if (ext == 'webm') return 'video/webm';
      return 'video/mp4';
    } else if (messageType == 'audio' || messageType == 'voice_note') {
      if (ext == 'mp3') return 'audio/mpeg';
      if (ext == 'm4a') return 'audio/mp4';
      if (ext == 'aac') return 'audio/aac';
      if (ext == 'wav') return 'audio/wav';
      if (ext == 'ogg') return 'audio/ogg';
      if (ext == 'opus') return 'audio/opus';
      return 'audio/mpeg';
    } else {
      if (ext == 'pdf') return 'application/pdf';
      if (ext == 'txt') return 'text/plain';
      if (ext == 'csv') return 'text/csv';
      if (ext == 'doc') return 'application/msword';
      if (ext == 'docx') return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      if (ext == 'xls') return 'application/vnd.ms-excel';
      if (ext == 'xlsx') return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      if (ext == 'ppt') return 'application/vnd.ms-powerpoint';
      if (ext == 'pptx') return 'application/vnd.openxmlformats-officedocument.presentationml.presentation';
      if (ext == 'json') return 'application/json';
      if (ext == 'zip') return 'application/zip';
      return 'text/plain';
    }
  }

  String _getMediaType(String messageType) {
    switch (messageType) {
      case 'image':
        return 'CHAT_IMAGE';
      case 'video':
        return 'CHAT_VIDEO';
      case 'audio':
      case 'voice_note':
        return 'VOICE_NOTE';
      default:
        return 'DOCUMENT';
    }
  }

  Future<void> _confirmCancelScheduledMessage(ScheduledMessageModel msg) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.colors.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Color(0xFFE53935), size: 24),
            CommonSpaces.w8,
            Text(
              'Cancel Schedule?',
              style: context.titleMedium.copyWith(
                fontWeight: FontWeight.bold,
                color: context.colors.textPrimary,
              ),
            ),
          ],
        ),
        content: Text(
          'This scheduled message will be permanently deleted and will not be sent.',
          style: context.bodyMedium.copyWith(color: context.colors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Keep', style: TextStyle(color: context.colors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE53935),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Cancel Message'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        if (getIt.isRegistered<ChatRepository>()) {
          final repo = getIt<ChatRepository>();
          await repo.cancelScheduledMessage(msg.id);
          if (mounted) {
            context.showSuccessNotification('Scheduled message cancelled');
            setState(() {
              _scheduledMessages.removeWhere((item) => item.id == msg.id);
              if (_editingMessage?.id == msg.id) {
                _cancelEditing();
              }
            });
          }
        }
      } catch (e) {
        if (mounted) {
          context.showErrorNotification('Failed to cancel message: $e');
        }
      }
    }
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day.toString().padLeft(2, '0')}, ${date.year}';
  }

  String _formatTime() {
    final h = _selectedHour.toString().padLeft(2, '0');
    final m = _selectedMinute.toString().padLeft(2, '0');
    final s = _selectedSecond.toString().padLeft(2, '0');
    final period = _isPm ? 'PM' : 'AM';
    return '$h:$m:$s $period';
  }

  String _formatItemDateTime(DateTime dt) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final h24 = dt.hour;
    final period = h24 >= 12 ? 'PM' : 'AM';
    final h12 = h24 % 12 == 0 ? 12 : h24 % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    final s = dt.second.toString().padLeft(2, '0');
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year} at ${h12.toString().padLeft(2, '0')}:$m:$s $period';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.colors.isDark;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: BoxDecoration(
        color: context.colors.scaffoldBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top Drag Handle
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 8),
              child: Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: context.colors.textHint.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),

            // Header Row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: context.colors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.schedule_rounded,
                            color: context.colors.primary, size: 22),
                      ),
                      CommonSpaces.w12,
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Scheduled Messages',
                            style: context.titleLarge.copyWith(
                              color: context.colors.textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          Text(
                            widget.contactName,
                            style: context.bodySmall.copyWith(
                              color: context.colors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    icon: Icon(CommonIcons.close, color: context.colors.textSecondary),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Tabs Selector
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(14),
              ),
              child: TabBar(
                controller: _tabController,
                indicatorSize: TabBarIndicatorSize.tab,
                indicator: BoxDecoration(
                  color: context.colors.primary,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: context.colors.primary.withValues(alpha: 0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                labelColor: context.colors.textLight,
                unselectedLabelColor: context.colors.textSecondary,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                tabs: [
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _editingMessage != null
                              ? Icons.edit_note_rounded
                              : Icons.add_circle_outline_rounded,
                          size: 16,
                        ),
                        CommonSpaces.w6,
                        Text(_editingMessage != null ? 'Edit Message' : 'Schedule New'),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.list_alt_rounded, size: 16),
                        CommonSpaces.w6,
                        Text('Scheduled (${_scheduledMessages.length})'),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Tab Views Content
            Flexible(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Tab 1: Form to Schedule / Edit Message
                  _buildScheduleFormTab(context),

                  // Tab 2: List of Scheduled Messages
                  _buildScheduledListTab(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleFormTab(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 8,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Editing Active Banner
            if (_editingMessage != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber.withValues(alpha: 0.5)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.edit_rounded, color: Colors.amber, size: 18),
                    CommonSpaces.w8,
                    Expanded(
                      child: Text(
                        'Editing scheduled message',
                        style: context.bodySmall.copyWith(
                          color: Colors.amber[800] ?? Colors.amber,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: _cancelEditing,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.amber.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Cancel Edit',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.amber[900] ?? Colors.amber,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              CommonSpaces.h12,
            ],

            // Error Banner
            if (_errorMessage != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: context.colors.error.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: context.colors.error.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(CommonIcons.warning, color: context.colors.error, size: 18),
                    CommonSpaces.w8,
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: context.bodySmall.copyWith(
                          color: context.colors.error,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              CommonSpaces.h12,
            ],

            // Message Type Selector
            Text(
              'MESSAGE TYPE',
              style: context.bodySmall.copyWith(
                color: context.colors.textSecondary,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
              ),
            ),
            CommonSpaces.h8,
            Row(
              children: [
                _buildTypeChip(ScheduledMessageType.text, 'Text', CommonIcons.textFields),
                CommonSpaces.w6,
                _buildTypeChip(ScheduledMessageType.image, 'Image', CommonIcons.gallery),
                CommonSpaces.w6,
                _buildTypeChip(ScheduledMessageType.video, 'Video', Icons.videocam_rounded),
                CommonSpaces.w6,
                _buildTypeChip(ScheduledMessageType.document, 'Doc', CommonIcons.document),
                CommonSpaces.w6,
                _buildTypeChip(ScheduledMessageType.audio, 'Audio', CommonIcons.audio),
              ],
            ),
            CommonSpaces.h14,

            // Text / Caption Field
            TextFormField(
              controller: _messageController,
              maxLines: 3,
              minLines: 1,
              style: context.bodyMedium.copyWith(color: context.colors.textPrimary),
              decoration: InputDecoration(
                hintText: _selectedType == ScheduledMessageType.text
                    ? 'Type your scheduled message...'
                    : 'Add a caption (optional)...',
                hintStyle: context.bodyMedium.copyWith(color: context.colors.textHint),
                filled: true,
                fillColor: context.colors.lightBackground,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            CommonSpaces.h14,

            // Attachment Selector & Rich Preview (for Non-text types)
            if (_selectedType != ScheduledMessageType.text) ...[
              _buildAttachmentPickerAndPreview(context),
              CommonSpaces.h8,
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: context.colors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: context.colors.primary.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.visibility_outlined,
                      color: context.colors.primary,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'View-only: Download and Share will be disabled for recipients',
                        style: context.bodySmall.copyWith(
                          color: context.colors.textPrimary,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              CommonSpaces.h14,
            ],

            // Date Picker Section
            Text(
              'SCHEDULE DATE',
              style: context.bodySmall.copyWith(
                color: context.colors.textSecondary,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
              ),
            ),
            CommonSpaces.h6,
            InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: context.colors.lightBackground,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: context.colors.primary.withValues(alpha: 0.25),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today_rounded,
                        color: context.colors.primary, size: 18),
                    CommonSpaces.w8,
                    Expanded(
                      child: Text(
                        _formatDate(_selectedDate),
                        style: context.bodyMedium.copyWith(
                          color: context.colors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Icon(Icons.edit_calendar_rounded,
                        size: 18, color: context.colors.textHint),
                  ],
                ),
              ),
            ),
            CommonSpaces.h14,

            // Time Selection with Seconds (Hours, Minutes, Seconds, AM/PM)
            Text(
              'SCHEDULE TIME (WITH SECONDS)',
              style: context.bodySmall.copyWith(
                color: context.colors.textSecondary,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
              ),
            ),
            CommonSpaces.h8,
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: context.colors.lightBackground,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: context.colors.primary.withValues(alpha: 0.25),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Hours Spin Box
                      _buildSpinPicker(
                        label: 'HH',
                        value: _selectedHour,
                        min: 1,
                        max: 12,
                        onChanged: (val) => setState(() => _selectedHour = val),
                      ),
                      Text(':',
                          style: context.titleLarge.copyWith(fontWeight: FontWeight.bold)),
                      // Minutes Spin Box
                      _buildSpinPicker(
                        label: 'MM',
                        value: _selectedMinute,
                        min: 0,
                        max: 59,
                        onChanged: (val) => setState(() => _selectedMinute = val),
                      ),
                      Text(':',
                          style: context.titleLarge.copyWith(fontWeight: FontWeight.bold)),
                      // Seconds Spin Box
                      _buildSpinPicker(
                        label: 'SS',
                        value: _selectedSecond,
                        min: 0,
                        max: 59,
                        onChanged: (val) => setState(() => _selectedSecond = val),
                      ),
                      CommonSpaces.w8,
                      // AM/PM Toggle
                      GestureDetector(
                        onTap: () => setState(() => _isPm = !_isPm),
                        child: Container(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: context.colors.primary,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            _isPm ? 'PM' : 'AM',
                            style: context.titleSmall.copyWith(
                              color: context.colors.textLight,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  CommonSpaces.h8,
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.access_time_filled_rounded,
                          size: 14, color: context.colors.primary),
                      CommonSpaces.w4,
                      Text(
                        'Selected: ${_formatTime()}',
                        style: context.bodySmall.copyWith(
                          color: context.colors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            CommonSpaces.h16,

            // Live Upload Progress Bar with Percentage Card
            if (_isSubmitting) ...[
              _buildUploadProgressCard(context),
              CommonSpaces.h12,
            ],

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _isSubmitting ? null : _validateAndSubmit,
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Icon(
                        _editingMessage != null
                            ? Icons.check_circle_outline_rounded
                            : Icons.schedule_send_rounded,
                        size: 20,
                      ),
                label: Text(
                  _isSubmitting
                      ? (_uploadStatusText.isNotEmpty
                          ? _uploadStatusText
                          : 'Processing...')
                      : (_editingMessage != null
                          ? 'Update Scheduled Message'
                          : 'Confirm & Schedule'),
                  style: context.titleMedium.copyWith(
                    color: context.colors.textLight,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.colors.primary,
                  foregroundColor: context.colors.textLight,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  elevation: 2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadProgressCard(BuildContext context) {
    final isDark = context.colors.isDark;
    final fileName = _attachedFileName ?? (_attachedFile != null ? _attachedFile!.path.split('/').last : '');

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: context.colors.primary.withValues(alpha: 0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: context.colors.primary.withValues(alpha: 0.12),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: context.colors.primary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.cloud_upload_rounded,
                  color: context.colors.primary,
                  size: 20,
                ),
              ),
              CommonSpaces.w10,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _uploadStatusText.isNotEmpty
                          ? _uploadStatusText
                          : 'Uploading ${_selectedType.name}...',
                      style: context.bodyMedium.copyWith(
                        fontWeight: FontWeight.bold,
                        color: context.colors.textPrimary,
                        fontSize: 14,
                      ),
                    ),
                    if (fileName.isNotEmpty)
                      Text(
                        _attachedFileSize != null && _attachedFileSize! > 0
                            ? '$fileName • ${_formatFileSize(_attachedFileSize!)}'
                            : fileName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.bodySmall.copyWith(
                          color: context.colors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: context.colors.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$_uploadPercentage%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          CommonSpaces.h10,
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: _uploadProgress > 0 ? _uploadProgress : null,
              minHeight: 8,
              backgroundColor: context.colors.primary.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation<Color>(context.colors.primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttachmentPickerAndPreview(BuildContext context) {
    final isDark = context.colors.isDark;
    final hasAttachment = _attachedFile != null || (_attachedFileName != null && _attachedFileName!.isNotEmpty);

    if (!hasAttachment) {
      IconData pickerIcon;
      String pickerTitle;
      String pickerHint;
      Color pickerColor;

      switch (_selectedType) {
        case ScheduledMessageType.image:
          pickerIcon = CommonIcons.gallery;
          pickerTitle = 'Choose Image to Schedule';
          pickerHint = 'Supports JPG, PNG, WEBP, GIF';
          pickerColor = const Color(0xFF2196F3);
          break;
        case ScheduledMessageType.video:
          pickerIcon = Icons.videocam_rounded;
          pickerTitle = 'Choose Video to Schedule';
          pickerHint = 'Supports MP4, MOV, WEBM';
          pickerColor = Colors.red;
          break;
        case ScheduledMessageType.document:
          pickerIcon = CommonIcons.document;
          pickerTitle = 'Choose Document to Schedule';
          pickerHint = 'Supports PDF, DOC, XLS, PPT, TXT, ZIP';
          pickerColor = const Color(0xFFFF9800);
          break;
        case ScheduledMessageType.audio:
          pickerIcon = CommonIcons.audio;
          pickerTitle = 'Choose Audio to Schedule';
          pickerHint = 'Supports MP3, M4A, WAV, AAC, OGG';
          pickerColor = const Color(0xFF9C27B0);
          break;
        default:
          pickerIcon = Icons.attach_file_rounded;
          pickerTitle = 'Choose Attachment';
          pickerHint = 'Tap to select file';
          pickerColor = context.colors.primary;
      }

      return InkWell(
        onTap: _pickAttachment,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          decoration: BoxDecoration(
            color: context.colors.lightBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: pickerColor.withValues(alpha: 0.35),
              style: BorderStyle.solid,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: pickerColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(pickerIcon, color: pickerColor, size: 24),
              ),
              CommonSpaces.w12,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pickerTitle,
                      style: context.bodyMedium.copyWith(
                        fontWeight: FontWeight.bold,
                        color: context.colors.textPrimary,
                      ),
                    ),
                    CommonSpaces.h2,
                    Text(
                      pickerHint,
                      style: context.bodySmall.copyWith(
                        color: context.colors.textSecondary,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: pickerColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Select',
                  style: TextStyle(
                    color: pickerColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final fileName = _attachedFileName ?? (_attachedFile != null ? _attachedFile!.path.split('/').last : '');
    final fileSizeFormatted = _attachedFileSize != null && _attachedFileSize! > 0
        ? _formatFileSize(_attachedFileSize!)
        : (_editingMessage != null && _editingMessage!.fileSize > 0 ? _formatFileSize(_editingMessage!.fileSize) : '');

    // 1. Image Preview Card
    if (_selectedType == ScheduledMessageType.image) {
      final hasLocalFile = _attachedFile != null && _attachedFile!.existsSync();
      final resolvedUrl = _editingMessage?.fileKey != null ? _resolveMediaUrl(_editingMessage!.fileKey) : null;

      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            GestureDetector(
              onTap: () {
                final viewUrl = hasLocalFile ? _attachedFile!.path : (resolvedUrl ?? '');
                if (viewUrl.isNotEmpty) {
                  InAppViewer.show(
                    context,
                    url: viewUrl,
                    fileName: fileName.isNotEmpty ? fileName : 'Image',
                    type: 'image',
                  );
                }
              },
              child: Stack(
                children: [
                  SizedBox(
                    height: 180,
                    width: double.infinity,
                    child: hasLocalFile
                        ? Image.file(
                            _attachedFile!,
                            fit: BoxFit.cover,
                            errorBuilder: (c, o, s) => _buildMediaFallback(
                              context,
                              Icons.broken_image_rounded,
                              'Image preview error',
                            ),
                          )
                        : (resolvedUrl != null && resolvedUrl.isNotEmpty
                            ? Image.network(
                                resolvedUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (c, o, s) => _buildMediaFallback(
                                  context,
                                  Icons.image_rounded,
                                  fileName.isNotEmpty ? fileName : 'Attached Image',
                                ),
                              )
                            : _buildMediaFallback(
                                context,
                                Icons.image_rounded,
                                fileName.isNotEmpty ? fileName : 'Attached Image',
                              )),
                  ),
                  // Top Overlay Badges
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.zoom_in_rounded, color: Colors.white, size: 14),
                          SizedBox(width: 4),
                          Text(
                            'Tap to preview',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Remove Button (Top Right)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () => setState(() {
                        _attachedFile = null;
                        _attachedFileName = null;
                        _attachedFileSize = null;
                      }),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.7),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close_rounded, color: Colors.white, size: 18),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Bottom Info & Change Button Row
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              color: context.colors.lightBackground,
              child: Row(
                children: [
                  Icon(Icons.photo_outlined, size: 16, color: context.colors.primary),
                  CommonSpaces.w8,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          fileName.isNotEmpty ? fileName : 'Attached Image',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.bodySmall.copyWith(
                            color: context.colors.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (fileSizeFormatted.isNotEmpty)
                          Text(
                            fileSizeFormatted,
                            style: context.bodySmall.copyWith(
                              color: context.colors.textHint,
                              fontSize: 10.5,
                            ),
                          ),
                      ],
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _pickAttachment,
                    icon: const Icon(Icons.edit_rounded, size: 14),
                    label: const Text('Change', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    style: TextButton.styleFrom(
                      foregroundColor: context.colors.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      minimumSize: Size.zero,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // 2. Video Preview Card
    if (_selectedType == ScheduledMessageType.video) {
      final hasLocalFile = _attachedFile != null && _attachedFile!.existsSync();
      final resolvedUrl = _editingMessage?.fileKey != null ? _resolveMediaUrl(_editingMessage!.fileKey) : null;

      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            GestureDetector(
              onTap: () {
                final viewUrl = hasLocalFile ? _attachedFile!.path : (resolvedUrl ?? '');
                if (viewUrl.isNotEmpty) {
                  InAppViewer.show(
                    context,
                    url: viewUrl,
                    fileName: fileName.isNotEmpty ? fileName : 'Video',
                    type: 'video',
                  );
                }
              },
              child: Container(
                height: 150,
                width: double.infinity,
                color: const Color(0xFF0F172A),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    const Icon(Icons.videocam_rounded, color: Colors.white24, size: 64),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.redAccent,
                            blurRadius: 12,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 30),
                    ),
                    // Top Left Badge
                    Positioned(
                      top: 10,
                      left: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.65),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.play_circle_outline_rounded, color: Colors.white, size: 14),
                            SizedBox(width: 4),
                            Text(
                              'Tap to preview video',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Remove Button (Top Right)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: () => setState(() {
                          _attachedFile = null;
                          _attachedFileName = null;
                          _attachedFileSize = null;
                        }),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.7),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close_rounded, color: Colors.white, size: 18),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Bottom Info & Change Button Row
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              color: context.colors.lightBackground,
              child: Row(
                children: [
                  const Icon(Icons.videocam_outlined, size: 16, color: Colors.red),
                  CommonSpaces.w8,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          fileName.isNotEmpty ? fileName : 'Attached Video',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.bodySmall.copyWith(
                            color: context.colors.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (fileSizeFormatted.isNotEmpty)
                          Text(
                            fileSizeFormatted,
                            style: context.bodySmall.copyWith(
                              color: context.colors.textHint,
                              fontSize: 10.5,
                            ),
                          ),
                      ],
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _pickAttachment,
                    icon: const Icon(Icons.edit_rounded, size: 14),
                    label: const Text('Change', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      minimumSize: Size.zero,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // 3. Document Preview Card
    if (_selectedType == ScheduledMessageType.document) {
      final hasLocalFile = _attachedFile != null && _attachedFile!.existsSync();
      final resolvedUrl = _editingMessage?.fileKey != null ? _resolveMediaUrl(_editingMessage!.fileKey) : null;
      final ext = fileName.contains('.') ? fileName.split('.').last.toUpperCase() : 'DOC';

      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFFF9800).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFFF9800).withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: () {
                final viewUrl = hasLocalFile ? _attachedFile!.path : (resolvedUrl ?? '');
                if (viewUrl.isNotEmpty) {
                  InAppViewer.show(
                    context,
                    url: viewUrl,
                    fileName: fileName.isNotEmpty ? fileName : 'Document',
                    type: 'file',
                  );
                }
              },
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  color: Color(0xFFFF9800),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.description_rounded, color: Colors.white, size: 22),
              ),
            ),
            CommonSpaces.w12,
            Expanded(
              child: GestureDetector(
                onTap: () {
                  final viewUrl = hasLocalFile ? _attachedFile!.path : (resolvedUrl ?? '');
                  if (viewUrl.isNotEmpty) {
                    InAppViewer.show(
                      context,
                      url: viewUrl,
                      fileName: fileName.isNotEmpty ? fileName : 'Document',
                      type: 'file',
                    );
                  }
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF9800).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            ext,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFE65100),
                            ),
                          ),
                        ),
                        CommonSpaces.w6,
                        Expanded(
                          child: Text(
                            fileName.isNotEmpty ? fileName : 'Attached Document',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: context.bodyMedium.copyWith(
                              fontWeight: FontWeight.bold,
                              color: context.colors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    CommonSpaces.h4,
                    Text(
                      fileSizeFormatted.isNotEmpty
                          ? '$fileSizeFormatted • Tap to preview'
                          : 'Tap to preview document',
                      style: context.bodySmall.copyWith(
                        color: context.colors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit_rounded, color: Color(0xFFFF9800), size: 20),
              tooltip: 'Change Document',
              onPressed: _pickAttachment,
            ),
            IconButton(
              icon: Icon(Icons.close_rounded, color: context.colors.error, size: 20),
              tooltip: 'Remove',
              onPressed: () => setState(() {
                _attachedFile = null;
                _attachedFileName = null;
                _attachedFileSize = null;
              }),
            ),
          ],
        ),
      );
    }

    // 4. Audio Preview Card
    if (_selectedType == ScheduledMessageType.audio) {
      final hasLocalFile = _attachedFile != null && _attachedFile!.existsSync();
      final resolvedUrl = _editingMessage?.fileKey != null ? _resolveMediaUrl(_editingMessage!.fileKey) : null;

      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF9C27B0).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF9C27B0).withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: () {
                final viewUrl = hasLocalFile ? _attachedFile!.path : (resolvedUrl ?? '');
                if (viewUrl.isNotEmpty) {
                  InAppViewer.show(
                    context,
                    url: viewUrl,
                    fileName: fileName.isNotEmpty ? fileName : 'Audio',
                    type: 'audio',
                  );
                }
              },
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  color: Color(0xFF9C27B0),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.audiotrack_rounded, color: Colors.white, size: 22),
              ),
            ),
            CommonSpaces.w12,
            Expanded(
              child: GestureDetector(
                onTap: () {
                  final viewUrl = hasLocalFile ? _attachedFile!.path : (resolvedUrl ?? '');
                  if (viewUrl.isNotEmpty) {
                    InAppViewer.show(
                      context,
                      url: viewUrl,
                      fileName: fileName.isNotEmpty ? fileName : 'Audio',
                      type: 'audio',
                    );
                  }
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fileName.isNotEmpty ? fileName : 'Attached Audio',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.bodyMedium.copyWith(
                        fontWeight: FontWeight.bold,
                        color: context.colors.textPrimary,
                      ),
                    ),
                    CommonSpaces.h4,
                    Text(
                      fileSizeFormatted.isNotEmpty
                          ? '$fileSizeFormatted • Tap to play audio'
                          : 'Tap to play audio preview',
                      style: context.bodySmall.copyWith(
                        color: context.colors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit_rounded, color: Color(0xFF9C27B0), size: 20),
              tooltip: 'Change Audio',
              onPressed: _pickAttachment,
            ),
            IconButton(
              icon: Icon(Icons.close_rounded, color: context.colors.error, size: 20),
              tooltip: 'Remove',
              onPressed: () => setState(() {
                _attachedFile = null;
                _attachedFileName = null;
                _attachedFileSize = null;
              }),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildScheduledListTab(BuildContext context) {
    if (_isLoadingList) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: context.colors.primary),
              CommonSpaces.h12,
              Text(
                'Loading scheduled messages...',
                style: context.bodySmall.copyWith(color: context.colors.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    if (_listErrorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(CommonIcons.warning, color: context.colors.error, size: 36),
              CommonSpaces.h12,
              Text(_listErrorMessage!,
                  style: context.bodyMedium.copyWith(color: context.colors.error)),
              CommonSpaces.h16,
              ElevatedButton.icon(
                onPressed: _fetchScheduledMessages,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.colors.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_scheduledMessages.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: context.colors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.schedule_send_rounded,
                    size: 32, color: context.colors.primary),
              ),
              CommonSpaces.h16,
              Text(
                'No Scheduled Messages',
                style: context.titleMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  color: context.colors.textPrimary,
                ),
              ),
              CommonSpaces.h8,
              Text(
                'Messages scheduled for this chat will appear here. You can edit or cancel them anytime before delivery.',
                textAlign: TextAlign.center,
                style: context.bodySmall.copyWith(
                  color: context.colors.textSecondary,
                  height: 1.4,
                ),
              ),
              CommonSpaces.h20,
              ElevatedButton.icon(
                onPressed: () => _tabController.animateTo(0),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Schedule a Message'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.colors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchScheduledMessages,
      color: context.colors.primary,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        itemCount: _scheduledMessages.length,
        separatorBuilder: (ctx, idx) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final msg = _scheduledMessages[index];
          return _buildScheduledItemCard(context, msg);
        },
      ),
    );
  }

  String? _resolveMediaUrl(String? path) {
    if (path == null || path.trim().isEmpty) return null;
    String url = path.trim();

    if (url.contains('minio')) {
      try {
        final serverUri = Uri.parse(CommonEndpoints.baseUrl);
        final host = serverUri.host;
        if (host.isNotEmpty) {
          url = url.replaceAll('minio', host);
        }
      } catch (_) {}
    }

    return SecureAttachmentService.resolveFullUrl(url);
  }

  String _formatFileSize(int bytes) {
    if (bytes <= 0) return '';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Widget _buildMediaPreview(BuildContext context, ScheduledMessageModel msg) {
    final isDark = context.colors.isDark;
    final rawPath = msg.fileKey?.isNotEmpty == true
        ? msg.fileKey
        : (msg.thumbnail?.isNotEmpty == true
            ? msg.thumbnail
            : (msg.rawContent['fileKey'] ??
                    msg.rawContent['file_key'] ??
                    msg.rawContent['url'] ??
                    msg.rawContent['mediaUrl'] ??
                    msg.rawContent['media_url'] ??
                    msg.rawContent['path'] ??
                    msg.rawContent['filePath'] ??
                    msg.rawContent['file_path'])
                ?.toString());
    final resolvedUrl = _resolveMediaUrl(rawPath);
    final fileName = msg.fileName?.isNotEmpty == true
        ? msg.fileName!
        : (rawPath != null && rawPath.isNotEmpty ? rawPath.split('/').last : '');
    final isLocal = !kIsWeb &&
        ((resolvedUrl != null && File(resolvedUrl).existsSync()) ||
            (rawPath != null && File(rawPath).existsSync()));
    final localPath = isLocal
        ? (resolvedUrl != null && File(resolvedUrl).existsSync() ? resolvedUrl : rawPath)
        : null;
    final effectiveUrl = localPath ?? resolvedUrl ?? rawPath ?? '';

    // 1. Image Preview
    if (msg.messageType == 'image') {
      return GestureDetector(
        onTap: effectiveUrl.isNotEmpty
            ? () => InAppViewer.show(
                  context,
                  url: effectiveUrl,
                  fileName: fileName.isNotEmpty ? fileName : 'Image',
                  type: 'image',
                )
            : null,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (effectiveUrl.isNotEmpty)
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(13)),
                  child: SizedBox(
                    height: 180,
                    width: double.infinity,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        isLocal && localPath != null
                            ? Image.file(
                                File(localPath),
                                fit: BoxFit.cover,
                                errorBuilder: (c, o, s) => _buildMediaFallback(
                                    context, Icons.broken_image_rounded, 'Image Preview Unavailable'),
                              )
                            : CachedNetworkImage(
                                imageUrl: effectiveUrl,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(
                                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                                  child: const Center(
                                    child: SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    ),
                                  ),
                                ),
                                errorWidget: (context, url, error) => Image.network(
                                  effectiveUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (ctx, url, err) => _buildMediaFallback(
                                      context, Icons.image_rounded, fileName.isNotEmpty ? fileName : 'Image Attachment'),
                                ),
                              ),
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.65),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(Icons.zoom_in_rounded, color: Colors.white, size: 14),
                                SizedBox(width: 4),
                                Text(
                                  'Tap to view preview',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                _buildMediaFallback(context, Icons.image_rounded, fileName.isNotEmpty ? fileName : 'Attached Image'),
              if (fileName.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  child: Row(
                    children: [
                      Icon(Icons.photo_outlined, size: 14, color: context.colors.textSecondary),
                      CommonSpaces.w6,
                      Expanded(
                        child: Text(
                          fileName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.bodySmall.copyWith(
                            color: context.colors.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      if (msg.fileSize > 0)
                        Text(
                          _formatFileSize(msg.fileSize),
                          style: context.bodySmall.copyWith(
                            color: context.colors.textHint,
                            fontSize: 10,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    // 2. Audio Preview
    if (msg.messageType == 'audio' || msg.messageType == 'voice_note') {
      return GestureDetector(
        onTap: effectiveUrl.isNotEmpty
            ? () => InAppViewer.show(
                  context,
                  url: effectiveUrl,
                  fileName: fileName.isNotEmpty ? fileName : 'Audio',
                  type: 'audio',
                )
            : null,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF9C27B0).withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF9C27B0).withValues(alpha: 0.25)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  color: Color(0xFF9C27B0),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.audiotrack_rounded, color: Colors.white, size: 20),
              ),
              CommonSpaces.w12,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fileName.isNotEmpty ? fileName : 'Audio / Voice Note',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: context.colors.textPrimary,
                      ),
                    ),
                    CommonSpaces.h2,
                    Row(
                      children: [
                        const Icon(Icons.play_circle_outline_rounded, size: 14, color: Color(0xFF9C27B0)),
                        CommonSpaces.w4,
                        Text(
                          msg.fileSize > 0
                              ? '${_formatFileSize(msg.fileSize)} • Tap to play audio'
                              : 'Tap to play audio preview',
                          style: context.bodySmall.copyWith(
                            color: context.colors.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (effectiveUrl.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF9C27B0).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.play_arrow_rounded, color: Color(0xFF9C27B0), size: 18),
                      SizedBox(width: 2),
                      Text(
                        'Play',
                        style: TextStyle(
                          color: Color(0xFF9C27B0),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      );
    }

    // 3. Video Preview
    if (msg.messageType == 'video') {
      return GestureDetector(
        onTap: effectiveUrl.isNotEmpty
            ? () => InAppViewer.show(
                  context,
                  url: effectiveUrl,
                  fileName: fileName.isNotEmpty ? fileName : 'Video',
                  type: 'video',
                )
            : null,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 150,
                width: double.infinity,
                color: const Color(0xFF0F172A),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    const Icon(Icons.videocam_rounded, color: Colors.white24, size: 56),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.redAccent,
                            blurRadius: 10,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 28),
                    ),
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.65),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.play_circle_outline_rounded, color: Colors.white, size: 14),
                            SizedBox(width: 4),
                            Text(
                              'Tap to play video',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                child: Row(
                  children: [
                    const Icon(Icons.videocam_outlined, size: 14, color: Colors.red),
                    CommonSpaces.w6,
                    Expanded(
                      child: Text(
                        fileName.isNotEmpty ? fileName : 'Video File',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.bodySmall.copyWith(
                          color: context.colors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    if (msg.fileSize > 0)
                      Text(
                        _formatFileSize(msg.fileSize),
                        style: context.bodySmall.copyWith(
                          color: context.colors.textHint,
                          fontSize: 10,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    // 4. Document / Generic Attachment Preview
    if (msg.fileName != null || msg.fileKey != null || msg.messageType == 'document' || msg.messageType == 'file' || rawPath != null) {
      final ext = fileName.contains('.') ? fileName.split('.').last.toUpperCase() : 'DOC';

      return GestureDetector(
        onTap: effectiveUrl.isNotEmpty
            ? () => InAppViewer.show(
                  context,
                  url: effectiveUrl,
                  fileName: fileName.isNotEmpty ? fileName : 'Document',
                  type: 'file',
                )
            : null,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFFF9800).withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFFF9800).withValues(alpha: 0.25)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  color: Color(0xFFFF9800),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.description_rounded, color: Colors.white, size: 20),
              ),
              CommonSpaces.w12,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF9800).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            ext,
                            style: const TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFE65100),
                            ),
                          ),
                        ),
                        CommonSpaces.w6,
                        Expanded(
                          child: Text(
                            fileName.isNotEmpty ? fileName : 'Attached Document',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: context.bodyMedium.copyWith(
                              fontWeight: FontWeight.w600,
                              color: context.colors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    CommonSpaces.h2,
                    Text(
                      msg.fileSize > 0
                          ? '${_formatFileSize(msg.fileSize)} • Tap to view document'
                          : 'Document Attachment (Tap to view)',
                      style: context.bodySmall.copyWith(
                        color: context.colors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              if (effectiveUrl.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF9800).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.open_in_new_rounded, color: Color(0xFFFF9800), size: 16),
                      SizedBox(width: 4),
                      Text(
                        'View',
                        style: TextStyle(
                          color: Color(0xFFFF9800),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildMediaFallback(BuildContext context, IconData icon, String label) {
    final isDark = context.colors.isDark;
    return Container(
      height: 80,
      width: double.infinity,
      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: context.colors.textSecondary, size: 24),
          CommonSpaces.w8,
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.bodySmall.copyWith(color: context.colors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduledItemCard(BuildContext context, ScheduledMessageModel msg) {
    final isDark = context.colors.isDark;
    IconData typeIcon;
    Color typeColor;

    if (msg.messageType == 'image') {
      typeIcon = CommonIcons.gallery;
      typeColor = const Color(0xFF2196F3);
    } else if (msg.messageType == 'document') {
      typeIcon = CommonIcons.document;
      typeColor = const Color(0xFFFF9800);
    } else if (msg.messageType == 'audio' || msg.messageType == 'voice_note') {
      typeIcon = CommonIcons.audio;
      typeColor = const Color(0xFF9C27B0);
    } else if (msg.messageType == 'video') {
      typeIcon = Icons.videocam_rounded;
      typeColor = Colors.red;
    } else {
      typeIcon = CommonIcons.textFields;
      typeColor = context.colors.primary;
    }

    final rawPath = msg.fileKey?.isNotEmpty == true
        ? msg.fileKey
        : (msg.thumbnail?.isNotEmpty == true
            ? msg.thumbnail
            : (msg.rawContent['fileKey'] ??
                    msg.rawContent['file_key'] ??
                    msg.rawContent['url'] ??
                    msg.rawContent['mediaUrl'] ??
                    msg.rawContent['media_url'] ??
                    msg.rawContent['path'] ??
                    msg.rawContent['filePath'] ??
                    msg.rawContent['file_path'])
                ?.toString());
    final resolvedUrl = _resolveMediaUrl(rawPath);
    final fileName = msg.fileName?.isNotEmpty == true
        ? msg.fileName!
        : (rawPath != null && rawPath.isNotEmpty ? rawPath.split('/').last : '');
    final hasMedia = msg.messageType != 'text' || (rawPath != null && rawPath.isNotEmpty) || (fileName.isNotEmpty);
    final isLocal = !kIsWeb &&
        ((resolvedUrl != null && File(resolvedUrl).existsSync()) ||
            (rawPath != null && File(rawPath).existsSync()));
    final localPath = isLocal
        ? (resolvedUrl != null && File(resolvedUrl).existsSync() ? resolvedUrl : rawPath)
        : null;
    final effectiveUrl = localPath ?? resolvedUrl ?? rawPath ?? '';

    return Container(
      decoration: BoxDecoration(
        color: isDark ? context.colors.cardBackground : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Type icon and Pending Status badge
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: typeColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(typeIcon, color: typeColor, size: 18),
              ),
              CommonSpaces.w8,
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Pending',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4CAF50),
                  ),
                ),
              ),
            ],
          ),
          CommonSpaces.h10,

          // Message Text Content (if present)
          if (msg.text.isNotEmpty) ...[
            Text(
              msg.text,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: context.bodyMedium.copyWith(
                color: context.colors.textPrimary,
                fontWeight: FontWeight.w500,
                fontSize: 15,
              ),
            ),
            CommonSpaces.h10,
          ],

          // Rich Media Preview (Image / Audio / Document / Video)
          if (hasMedia) ...[
            _buildMediaPreview(context, msg),
          ],

          const Divider(height: 14),

          // Scheduled Date & Time row
          Row(
            children: [
              Icon(Icons.access_time_rounded,
                  size: 15, color: context.colors.primary),
              CommonSpaces.w6,
              Expanded(
                child: Text(
                  _formatItemDateTime(msg.scheduledAt),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: context.colors.primary,
                  ),
                ),
              ),
            ],
          ),
          CommonSpaces.h12,

          // Bottom Action Buttons: [Preview] (if media) + [Edit / Reschedule] + [Delete]
          Align(
            alignment: Alignment.centerRight,
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              alignment: WrapAlignment.end,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (hasMedia && effectiveUrl.isNotEmpty) ...[
                  OutlinedButton.icon(
                    onPressed: () {
                      InAppViewer.show(
                        context,
                        url: effectiveUrl,
                        fileName: fileName.isNotEmpty ? fileName : msg.messageType,
                        type: (msg.messageType == 'document' || msg.messageType == 'file')
                            ? 'file'
                            : msg.messageType,
                      );
                    },
                    icon: const Icon(Icons.visibility_outlined, size: 14, color: Color(0xFF2196F3)),
                    label: const Text(
                      'Preview',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2196F3),
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF2196F3),
                      side: BorderSide(color: const Color(0xFF2196F3).withValues(alpha: 0.5)),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                      minimumSize: Size.zero,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
                OutlinedButton.icon(
                  onPressed: () => _startEditing(msg),
                  icon: Icon(Icons.edit_outlined, size: 14, color: context.colors.primary),
                  label: Text(
                    'Edit / Reschedule',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: context.colors.primary,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: context.colors.primary,
                    side: BorderSide(color: context.colors.primary.withValues(alpha: 0.5)),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    minimumSize: Size.zero,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () => _confirmCancelScheduledMessage(msg),
                  icon: const Icon(Icons.delete_outline_rounded, size: 14, color: Color(0xFFE53935)),
                  label: const Text(
                    'Delete',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFE53935),
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFE53935),
                    side: const BorderSide(color: Color(0xFFFFCDD2)),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    minimumSize: Size.zero,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeChip(
      ScheduledMessageType type, String label, IconData icon) {
    final isSelected = _selectedType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedType = type;
            _attachedFile = null;
            _attachedFileName = null;
            _errorMessage = null;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? context.colors.primary
                : context.colors.lightBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? context.colors.primary
                  : context.colors.textHint.withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected
                    ? context.colors.textLight
                    : context.colors.textSecondary,
              ),
              CommonSpaces.h4,
              Text(
                label,
                style: context.bodySmall.copyWith(
                  color: isSelected
                      ? context.colors.textLight
                      : context.colors.textSecondary,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSpinPicker({
    required String label,
    required int value,
    required int min,
    required int max,
    required ValueChanged<int> onChanged,
  }) {
    return Column(
      children: [
        Text(
          label,
          style: context.bodySmall.copyWith(
            color: context.colors.textHint,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Column(
              children: [
                InkWell(
                  onTap: () {
                    int next = value + 1;
                    if (next > max) next = min;
                    onChanged(next);
                  },
                  child: Icon(Icons.arrow_drop_up_rounded,
                      color: context.colors.textPrimary),
                ),
                Container(
                  width: 38,
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  decoration: BoxDecoration(
                    color: context.colors.scaffoldBackground,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    value.toString().padLeft(2, '0'),
                    style: context.titleMedium.copyWith(
                      color: context.colors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontFamily: CommonFonts.primaryFont,
                    ),
                  ),
                ),
                InkWell(
                  onTap: () {
                    int prev = value - 1;
                    if (prev < min) prev = max;
                    onChanged(prev);
                  },
                  child: Icon(Icons.arrow_drop_down_rounded,
                      color: context.colors.textPrimary),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
