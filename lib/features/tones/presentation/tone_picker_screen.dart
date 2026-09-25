import 'package:flutter/material.dart';
import 'package:schat/core/storage/storage_service.dart';
import 'package:schat/features/tones/data/models/tone_model.dart';
import 'package:schat/features/tones/services/tone_api_service.dart';
import 'package:schat/features/tones/services/tone_preview_player.dart';
import 'package:schat/injection.dart';
import 'package:schat/utils/common_colors.dart';
import 'package:schat/utils/common_fonts.dart';
import 'package:schat/utils/common_fontstyles.dart';
import 'package:schat/features/dashboard_screen/src/presentation/dashboard_page.dart';
import 'package:schat/utils/common_notifications.dart';
import 'package:schat/utils/common_spaces.dart';

class TonePickerScreen extends StatefulWidget {
  final ToneType toneType;
  final String? initialSelectedToneId;
  final String? initialSelectedToneName;
  final Function(Tone selectedTone)? onToneSelected;

  const TonePickerScreen({
    super.key,
    required this.toneType,
    this.initialSelectedToneId,
    this.initialSelectedToneName,
    this.onToneSelected,
  });

  @override
  State<TonePickerScreen> createState() => _TonePickerScreenState();
}

class _TonePickerScreenState extends State<TonePickerScreen>
    with SingleTickerProviderStateMixin {
  final ToneApiService _apiService = getIt<ToneApiService>();
  final TonePreviewPlayer _player = TonePreviewPlayer();

  List<Tone> _tones = [];
  String? _selectedToneId;
  String? _playingToneId;
  bool _isLoading = true;
  bool _isSaving = false;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _selectedToneId = widget.initialSelectedToneId;

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.92, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _loadTones();
  }

  @override
  void dispose() {
    _player.stop();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _loadTones() async {
    setState(() => _isLoading = true);
    try {
      final list = await _apiService.getAvailableTones(type: widget.toneType);
      
      // If we don't have an initial ID but we have a name, match by name
      if (_selectedToneId == null && widget.initialSelectedToneName != null) {
        final match = list.where((t) => t.name.toLowerCase() == widget.initialSelectedToneName!.toLowerCase()).firstOrNull;
        if (match != null) {
          _selectedToneId = match.id;
        }
      }

      // If still null, fallback to default tone
      if (_selectedToneId == null && list.isNotEmpty) {
        final defaultTone = list.firstWhere(
          (t) => t.isDefault,
          orElse: () => list.first,
        );
        _selectedToneId = defaultTone.id;
      }

      if (mounted) {
        setState(() {
          _tones = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveSelection() async {
    if (_selectedToneId == null || _tones.isEmpty) return;
    final selectedTone = _tones.firstWhere(
      (t) => t.id == _selectedToneId,
      orElse: () => _tones.first,
    );

    setState(() => _isSaving = true);
    try {
      final storage = getIt<StorageService>();
      if (widget.toneType == ToneType.CALL) {
        await _apiService.updateMyTones(callRingtoneId: _selectedToneId);
        await storage.saveCallRingtone(
          name: selectedTone.name,
          url: selectedTone.fileUrl,
        );
      } else {
        await _apiService.updateMyTones(messageToneId: _selectedToneId);
        await storage.saveMessageTone(
          name: selectedTone.name,
          url: selectedTone.fileUrl,
        );
      }

      widget.onToneSelected?.call(selectedTone);
      await _player.stop();
      if (mounted) {
        context.showSuccessNotification('${widget.toneType == ToneType.CALL ? 'Ringtone' : 'Message tone'} updated');
        Navigator.pop(context, selectedTone);
      }
    } catch (e) {
      if (mounted) {
        context.showErrorNotification('Failed to update tone: $e');
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _resetToDefault() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Reset to Default?'),
        content: Text(
          'Are you sure you want to reset your ${widget.toneType == ToneType.CALL ? 'ringtone' : 'message tone'} to the system default?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: context.colors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isSaving = true);
    try {
      final result = await _apiService.resetMyTones();
      final defaultTone = widget.toneType == ToneType.CALL
          ? result?.callRingtone
          : result?.messageTone;

      final storage = getIt<StorageService>();
      if (defaultTone != null) {
        setState(() => _selectedToneId = defaultTone.id);
        widget.onToneSelected?.call(defaultTone);
        if (widget.toneType == ToneType.CALL) {
          await storage.saveCallRingtone(name: defaultTone.name, url: defaultTone.fileUrl);
        } else {
          await storage.saveMessageTone(name: defaultTone.name, url: defaultTone.fileUrl);
        }
      } else {
        if (widget.toneType == ToneType.CALL) {
          await storage.saveCallRingtone(name: 'Default', url: '');
        } else {
          await storage.saveMessageTone(name: 'Default', url: '');
        }
      }
      await _player.stop();
      if (mounted) {
        context.showSuccessNotification('Reset to system default');
        Navigator.pop(context, defaultTone);
      }
    } catch (e) {
      if (mounted) {
        context.showErrorNotification('Failed to reset: $e');
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _onPlayTap(Tone tone) {
    _player.playPreview(
      toneId: tone.id,
      fileUrl: tone.fileUrl,
      onStateChange: (playing) {
        if (mounted) {
          setState(() {
            _playingToneId = playing ? tone.id : null;
          });
        }
      },
    );
  }

  void _onSelectTone(Tone tone) {
    setState(() => _selectedToneId = tone.id);
    _onPlayTap(tone);
  }

  @override
  Widget build(BuildContext context) {
    final isCall = widget.toneType == ToneType.CALL;
    final title = isCall ? 'Call Ringtone' : 'Message Tone';
    final subtitle = isCall
        ? 'Choose the sound for incoming voice & video calls'
        : 'Choose the sound for new chat message alerts';
    final isDark = context.colors.isDark;

    return Scaffold(
      backgroundColor: context.colors.scaffoldBackground,
      body: Stack(
        children: [
          // Wave lines background matching Home & Emergency Contacts
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: HomeBackgroundWavePainter(isDark: isDark),
              ),
            ),
          ),

          // Main Screen Content
          SafeArea(
            child: Column(
              children: [
                _buildHeader(context, title),
                Expanded(
                  child: _isLoading
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const CircularProgressIndicator(color: Color(0xFF00873C)),
                              CommonSpaces.h16,
                              Text(
                                'Loading tones...',
                                style: TextStyle(color: context.colors.textSecondary),
                              ),
                            ],
                          ),
                        )
                      : _tones.isEmpty
                          ? _buildEmptyState()
                          : ListView(
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                              children: [
                                // Hero Header Card
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: isDark ? context.colors.cardBackground : Colors.white,
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(
                                      color: const Color(0xFF00873C).withValues(alpha: 0.25),
                                      width: 1,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                                        blurRadius: 10,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: const BoxDecoration(
                                          color: Color(0xFFE8F5E9),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          isCall ? Icons.ring_volume_rounded : Icons.notifications_active_rounded,
                                          color: const Color(0xFF00873C),
                                          size: 24,
                                        ),
                                      ),
                                      CommonSpaces.w16,
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              title,
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: context.colors.textPrimary,
                                              ),
                                            ),
                                            CommonSpaces.h4,
                                            Text(
                                              subtitle,
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: context.colors.textSecondary,
                                                height: 1.3,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                CommonSpaces.h20,

                                // Section Title
                                const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                                  child: Text(
                                    'AVAILABLE TONES',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.8,
                                      color: Color(0xFF00873C),
                                    ),
                                  ),
                                ),
                                CommonSpaces.h8,

                                // Tone List Card
                                Container(
                                  decoration: BoxDecoration(
                                    color: isDark ? context.colors.cardBackground : Colors.white,
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(
                                      color: context.colors.border.withValues(alpha: 0.35),
                                      width: 1,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                                        blurRadius: 10,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(18),
                                    child: ListView.separated(
                                      shrinkWrap: true,
                                      physics: const NeverScrollableScrollPhysics(),
                                      itemCount: _tones.length,
                                      separatorBuilder: (ctx, i) => Divider(
                                        height: 1,
                                        indent: 64,
                                        endIndent: 16,
                                        color: context.colors.border.withValues(alpha: 0.25),
                                      ),
                                      itemBuilder: (ctx, index) {
                                        final tone = _tones[index];
                                        final isSelected = tone.id == _selectedToneId;
                                        final isPlaying = tone.id == _playingToneId;

                                        return _buildToneTile(
                                          tone: tone,
                                          isSelected: isSelected,
                                          isPlaying: isPlaying,
                                        );
                                      },
                                    ),
                                  ),
                                ),
                                CommonSpaces.h32,
                              ],
                            ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'save_tone_fab',
        onPressed: _isSaving ? null : _saveSelection,
        backgroundColor: const Color(0xFF00873C),
        foregroundColor: Colors.white,
        elevation: 4,
        icon: _isSaving
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : const Icon(Icons.check_rounded, size: 20),
        label: Text(
          _isSaving ? 'Saving...' : 'Set as $title',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: context.colors.lightBackground,
              border: Border.all(
                color: context.colors.border.withValues(alpha: 0.3),
              ),
            ),
            child: IconButton(
              icon: Icon(Icons.arrow_back_rounded, color: context.colors.textPrimary, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          CommonSpaces.w12,
          Expanded(
            child: Text(
              title,
              style: context.h2.copyWith(
                fontWeight: FontWeight.bold,
                color: context.colors.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          TextButton.icon(
            onPressed: _isSaving ? null : _resetToDefault,
            icon: Icon(Icons.refresh_rounded, size: 16, color: context.colors.textSecondary),
            label: Text('Reset', style: TextStyle(color: context.colors.textSecondary, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Widget _buildToneTile({
    required Tone tone,
    required bool isSelected,
    required bool isPlaying,
  }) {
    return InkWell(
      onTap: () => _onSelectTone(tone),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            // Play / Stop Icon Button
            GestureDetector(
              onTap: () => _onPlayTap(tone),
              child: isPlaying
                  ? ScaleTransition(
                      scale: _pulseAnimation,
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFF3B30), Color(0xFFFF5E3A)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFF3B30).withValues(alpha: 0.35),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.stop_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    )
                  : Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? context.colors.primary.withValues(alpha: 0.15)
                            : context.colors.border.withValues(alpha: 0.3),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.play_arrow_rounded,
                        color: isSelected
                            ? context.colors.primary
                            : context.colors.textSecondary,
                        size: 26,
                      ),
                    ),
            ),
            CommonSpaces.w16,

            // Tone Name & Default Badge
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          tone.name,
                          style: TextStyle(
                            fontSize: 15.5,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected
                                ? context.colors.textPrimary
                                : context.colors.textPrimary.withValues(alpha: 0.9),
                            fontFamily: CommonFonts.primaryFont,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (tone.isDefault) ...[
                        CommonSpaces.w8,
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: context.colors.primary.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: context.colors.primary.withValues(alpha: 0.3),
                              width: 0.8,
                            ),
                          ),
                          child: Text(
                            'Default',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: context.colors.primary,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (isPlaying) ...[
                    CommonSpaces.h4,
                    Text(
                      'Playing preview...',
                      style: TextStyle(
                        fontSize: 12,
                        color: const Color(0xFFFF3B30),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            CommonSpaces.w12,

            // Radio / Checkmark Selection
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? context.colors.primary
                      : context.colors.textSecondary.withValues(alpha: 0.4),
                  width: isSelected ? 6.5 : 2,
                ),
                color: isSelected ? context.colors.primary : Colors.transparent,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.music_off_rounded,
              size: 56,
              color: context.colors.textSecondary,
            ),
            CommonSpaces.h16,
            Text(
              'No tones found',
              style: context.titleLarge,
            ),
            CommonSpaces.h8,
            Text(
              'Check your connection or try resetting to default.',
              textAlign: TextAlign.center,
              style: TextStyle(color: context.colors.textSecondary),
            ),
            CommonSpaces.h24,
            ElevatedButton(
              onPressed: _loadTones,
              style: ElevatedButton.styleFrom(
                backgroundColor: context.colors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
