import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:schat/injection.dart';
import 'package:schat/utils/common_notifications.dart';
import 'package:schat/features/chat_screen/src/domain/models/scheduled_message_model.dart';
import 'package:schat/features/chat_screen/src/domain/repositories/chat_repository.dart';
import 'package:schat/utils/common_colors.dart';
import 'package:schat/utils/common_fonts.dart';
import 'package:schat/utils/common_fontstyles.dart';
import 'package:schat/utils/common_icons.dart';
import 'package:schat/utils/common_spaces.dart';

enum ScheduledMessageType { text, image, document, audio }

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

  late DateTime _selectedDate;
  int _selectedHour = 12;
  int _selectedMinute = 0;
  int _selectedSecond = 0;
  bool _isPm = true;

  String? _errorMessage;
  bool _isSubmitting = false;

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

  Future<void> _pickAttachment() async {
    try {
      if (_selectedType == ScheduledMessageType.image) {
        final picker = ImagePicker();
        final picked = await picker.pickImage(source: ImageSource.gallery);
        if (picked != null) {
          setState(() {
            _attachedFile = File(picked.path);
            _attachedFileName = picked.name;
            _errorMessage = null;
          });
        }
      } else if (_selectedType == ScheduledMessageType.document ||
          _selectedType == ScheduledMessageType.audio) {
        final result = await FilePicker.pickFiles(
          type: _selectedType == ScheduledMessageType.audio
              ? FileType.audio
              : FileType.any,
        );
        if (result != null && result.files.single.path != null) {
          setState(() {
            _attachedFile = File(result.files.single.path!);
            _attachedFileName = result.files.single.name;
            _errorMessage = null;
          });
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to pick attachment: $e';
      });
    }
  }

  void _startEditing(ScheduledMessageModel message) {
    setState(() {
      _editingMessage = message;
      _messageController.text = message.text;
      _attachedFile = null;
      _attachedFileName = message.fileName;

      if (message.messageType == 'image') {
        _selectedType = ScheduledMessageType.image;
      } else if (message.messageType == 'document') {
        _selectedType = ScheduledMessageType.document;
      } else if (message.messageType == 'audio') {
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
      _selectedType = ScheduledMessageType.text;
      _initDateTime(DateTime.now().add(const Duration(hours: 1)));
      _errorMessage = null;
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
      });

      try {
        if (getIt.isRegistered<ChatRepository>()) {
          final repo = getIt<ChatRepository>();
          final updatePayload = <String, dynamic>{
            'content': {
              'text': text,
              'fileName': _attachedFileName,
              'fileKey': _editingMessage!.fileKey,
              'fileSize': _editingMessage!.fileSize,
              'mimeType': _editingMessage!.mimeType,
            },
            'scheduledAt': scheduled.toUtc().toIso8601String(),
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
        });
        try {
          if (getIt.isRegistered<ChatRepository>()) {
            final repo = getIt<ChatRepository>();
            String typeStr = 'text';
            if (_selectedType == ScheduledMessageType.image) typeStr = 'image';
            if (_selectedType == ScheduledMessageType.document) typeStr = 'document';
            if (_selectedType == ScheduledMessageType.audio) typeStr = 'audio';

            final requestData = {
              "conversationId": widget.conversationId,
              "messageType": typeStr,
              "content": {
                "text": text,
                "fileName": _attachedFileName,
              },
              "scheduledAt": scheduled.toUtc().toIso8601String()
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
            });
          }
        }
      }
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
                CommonSpaces.w8,
                _buildTypeChip(ScheduledMessageType.image, 'Image', CommonIcons.gallery),
                CommonSpaces.w8,
                _buildTypeChip(ScheduledMessageType.document, 'Doc', CommonIcons.document),
                CommonSpaces.w8,
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

            // Attachment Selector (for Non-text types)
            if (_selectedType != ScheduledMessageType.text) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: context.colors.lightBackground,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: context.colors.primary.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    Icon(
                      _selectedType == ScheduledMessageType.image
                          ? CommonIcons.gallery
                          : (_selectedType == ScheduledMessageType.audio
                              ? CommonIcons.audio
                              : CommonIcons.document),
                      color: context.colors.primary,
                    ),
                    CommonSpaces.w12,
                    Expanded(
                      child: Text(
                        _attachedFileName ?? 'No attachment selected',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.bodyMedium.copyWith(
                          color: _attachedFileName != null
                              ? context.colors.textPrimary
                              : context.colors.textHint,
                        ),
                      ),
                    ),
                    if (_attachedFileName != null)
                      IconButton(
                        icon: Icon(CommonIcons.close, color: context.colors.error, size: 18),
                        onPressed: () => setState(() {
                          _attachedFile = null;
                          _attachedFileName = null;
                        }),
                      )
                    else
                      TextButton.icon(
                        onPressed: _pickAttachment,
                        icon: const Icon(Icons.attach_file_rounded, size: 18),
                        label: const Text('Choose'),
                        style: TextButton.styleFrom(
                          foregroundColor: context.colors.primary,
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
            CommonSpaces.h20,

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
                  _editingMessage != null
                      ? 'Update Scheduled Message'
                      : 'Confirm & Schedule',
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
    } else if (msg.messageType == 'audio') {
      typeIcon = CommonIcons.audio;
      typeColor = const Color(0xFF9C27B0);
    } else {
      typeIcon = CommonIcons.textFields;
      typeColor = context.colors.primary;
    }

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
          // Row 1: Type icon, Status badge, and Action Buttons
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
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
              const Spacer(),
              // Edit button
              IconButton(
                icon: Icon(Icons.edit_outlined,
                    color: context.colors.primary, size: 20),
                tooltip: 'Edit / Reschedule',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () => _startEditing(msg),
              ),
              CommonSpaces.w12,
              // Delete/Cancel button
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded,
                    color: Color(0xFFE53935), size: 20),
                tooltip: 'Cancel scheduled message',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () => _confirmCancelScheduledMessage(msg),
              ),
            ],
          ),
          CommonSpaces.h10,

          // Message Content
          if (msg.text.isNotEmpty) ...[
            Text(
              msg.text,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: context.bodyMedium.copyWith(
                color: context.colors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
            CommonSpaces.h8,
          ],

          if (msg.fileName != null && msg.fileName!.isNotEmpty) ...[
            Row(
              children: [
                Icon(Icons.attachment_rounded,
                    size: 14, color: context.colors.textSecondary),
                CommonSpaces.w4,
                Expanded(
                  child: Text(
                    msg.fileName!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.bodySmall.copyWith(
                      color: context.colors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            CommonSpaces.h8,
          ],

          const Divider(height: 14),

          // Scheduled Date & Time row
          Row(
            children: [
              Icon(Icons.access_time_rounded,
                  size: 14, color: context.colors.primary),
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
