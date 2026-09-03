import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:schat/utils/common_colors.dart';
import 'package:schat/utils/common_fonts.dart';
import 'package:schat/utils/common_fontstyles.dart';
import 'package:schat/utils/common_icons.dart';
import 'package:schat/utils/common_spaces.dart';

enum ScheduledMessageType { text, image, document, audio }

class ScheduleMessageBottomSheet extends StatefulWidget {
  final String contactName;
  final Function(
    DateTime scheduledDateTime,
    String text,
    File? attachment,
    ScheduledMessageType type,
  )? onSchedule;

  const ScheduleMessageBottomSheet({
    super.key,
    required this.contactName,
    this.onSchedule,
  });

  @override
  State<ScheduleMessageBottomSheet> createState() => _ScheduleMessageBottomSheetState();
}

class _ScheduleMessageBottomSheetState extends State<ScheduleMessageBottomSheet> {
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

  @override
  void initState() {
    super.initState();
    final now = DateTime.now().add(const Duration(hours: 1));
    _selectedDate = DateTime(now.year, now.month, now.day);
    int hour24 = now.hour;
    _isPm = hour24 >= 12;
    _selectedHour = hour24 % 12 == 0 ? 12 : hour24 % 12;
    _selectedMinute = now.minute;
    _selectedSecond = 0;
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
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
      } else if (_selectedType == ScheduledMessageType.document || _selectedType == ScheduledMessageType.audio) {
        final result = await FilePicker.pickFiles(
          type: _selectedType == ScheduledMessageType.audio ? FileType.audio : FileType.any,
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

  void _validateAndSubmit() {
    setState(() {
      _errorMessage = null;
    });

    final text = _messageController.text.trim();
    if (text.isEmpty && _attachedFile == null) {
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

    if (widget.onSchedule != null) {
      widget.onSchedule!(scheduled, text, _attachedFile, _selectedType);
    }

    Navigator.pop(context, {
      'scheduledDateTime': scheduled,
      'text': text,
      'attachment': _attachedFile,
      'type': _selectedType,
    });
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

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.colors.scaffoldBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top drag indicator & title
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: context.colors.textHint.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              CommonSpaces.h16,
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.schedule_rounded, color: context.colors.primary, size: 24),
                      CommonSpaces.w8,
                      Text(
                        'Schedule Message',
                        style: context.titleLarge.copyWith(
                          color: context.colors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: Icon(CommonIcons.close, color: context.colors.textSecondary),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              Text(
                'Scheduling message for ${widget.contactName}',
                style: context.bodySmall.copyWith(color: context.colors.textSecondary),
              ),
              CommonSpaces.h16,

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
                CommonSpaces.h16,
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
              CommonSpaces.h16,

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
              CommonSpaces.h16,

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
                CommonSpaces.h16,
              ],

              // Date & Time Pickers Section
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              CommonSpaces.h16,

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
                        Text(':', style: context.titleLarge.copyWith(fontWeight: FontWeight.bold)),
                        // Minutes Spin Box
                        _buildSpinPicker(
                          label: 'MM',
                          value: _selectedMinute,
                          min: 0,
                          max: 59,
                          onChanged: (val) => setState(() => _selectedMinute = val),
                        ),
                        Text(':', style: context.titleLarge.copyWith(fontWeight: FontWeight.bold)),
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
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
              CommonSpaces.h24,

              // Action Buttons
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _validateAndSubmit,
                  icon: const Icon(Icons.schedule_send_rounded, size: 20),
                  label: Text(
                    'Confirm & Schedule',
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
      ),
    );
  }

  Widget _buildTypeChip(ScheduledMessageType type, String label, IconData icon) {
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
                color: isSelected ? context.colors.textLight : context.colors.textSecondary,
              ),
              CommonSpaces.h4,
              Text(
                label,
                style: context.bodySmall.copyWith(
                  color: isSelected ? context.colors.textLight : context.colors.textSecondary,
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
                  child: Icon(Icons.arrow_drop_up_rounded, color: context.colors.textPrimary),
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
                  child: Icon(Icons.arrow_drop_down_rounded, color: context.colors.textPrimary),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
