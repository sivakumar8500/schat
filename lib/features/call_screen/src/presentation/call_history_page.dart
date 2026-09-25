import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:schat/injection.dart';
import 'package:schat/utils/common_fontstyles.dart';
import 'package:schat/utils/common_colors.dart';
import 'package:schat/utils/common_spaces.dart';
import 'package:schat/utils/common_icons.dart';
import 'package:schat/utils/permission_helper.dart';
import 'package:schat/core/storage/storage_service.dart';
import 'package:schat/features/call_screen/src/domain/call_history.dart';
import 'package:schat/features/call_screen/src/domain/repositories/call_history_repository.dart';
import 'package:schat/features/call_screen/src/presentation/bloc/call_history_cubit.dart';
import 'package:schat/features/call_screen/src/presentation/bloc/call_history_state.dart';
import 'package:schat/features/call_screen/src/presentation/bloc/call_webrtc_bloc.dart';
import 'package:schat/features/call_screen/src/presentation/audio_call_page.dart';
import 'package:schat/features/call_screen/src/presentation/video_call_page.dart';
import 'package:schat/core/network/api_result.dart';
import 'package:schat/features/dashboard_screen/src/domain/repositories/dashboard_repository.dart';
import 'package:schat/features/dashboard_screen/src/domain/models/chat_model.dart';

enum CallFilter { all, missed, audio, video, incoming, outgoing }

class CallHistoryPage extends StatelessWidget {
  const CallHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<CallHistoryCubit>(
      create: (context) {
        if (getIt.isRegistered<CallHistoryCubit>()) {
          return getIt<CallHistoryCubit>()..fetchCallHistory();
        }
        return CallHistoryCubit(getIt<CallHistoryRepository>())..fetchCallHistory();
      },
      child: const _CallHistoryPageContent(),
    );
  }
}

class _CallHistoryPageContent extends StatefulWidget {
  const _CallHistoryPageContent();

  @override
  State<_CallHistoryPageContent> createState() => _CallHistoryPageContentState();
}

class _CallHistoryPageContentState extends State<_CallHistoryPageContent> {
  final Set<String> _selectedIds = {};
  CallFilter _currentFilter = CallFilter.all;
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      if (mounted) {
        setState(() {
          _searchQuery = _searchController.text.trim().toLowerCase();
        });
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedIds.clear();
    });
  }

  void _deleteSelected(List<CallHistoryModel> currentCalls) {
    setState(() {
      currentCalls.removeWhere((call) => _selectedIds.contains(call.id));
      _selectedIds.clear();
    });
  }

  void _startCall(CallHistoryModel call, {required bool isVideo}) async {
    final hasPermission = await PermissionHelper.checkCallPermissions(isVideo: isVideo);
    if (!mounted || !hasPermission) return;

    final contactName = call.displayName;
    final myId = (getIt<StorageService>().getUserId() ?? '').trim();
    final recipientId = (call.callerId != null && call.callerId != myId && call.callerId!.isNotEmpty)
        ? call.callerId!
        : (call.receiverId ?? '');

    String conversationId = call.conversationId ?? '';

    if (conversationId.isEmpty && recipientId.isNotEmpty) {
      try {
        final result = await getIt<DashboardRepository>().startDirectChat(recipientId);
        if (result is Success<ChatModel>) {
          conversationId = result.data.id;
        }
      } catch (e) {
        debugPrint('CallHistoryPage: Error resolving conversationId: $e');
      }
    }

    if (!mounted) return;

    if (isVideo) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => BlocProvider.value(
            value: getIt<CallWebRtcBloc>(),
            child: VideoCallPage(
              conversationId: conversationId,
              contactName: contactName,
              contactColor: const Color(0xFF00873C),
              recipientId: recipientId,
              isOutgoing: true,
              profilePictureUrl: call.displayAvatar,
              myProfilePictureUrl: getIt<StorageService>().getProfilePic(),
            ),
          ),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => BlocProvider.value(
            value: getIt<CallWebRtcBloc>(),
            child: AudioCallPage(
              conversationId: conversationId,
              contactName: contactName,
              contactColor: const Color(0xFF00873C),
              recipientId: recipientId,
              isOutgoing: true,
              profilePictureUrl: call.displayAvatar,
              myProfilePictureUrl: getIt<StorageService>().getProfilePic(),
            ),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isSelectionMode = _selectedIds.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
            BlocBuilder<CallHistoryCubit, CallHistoryState>(
              builder: (context, state) {
                final currentCalls = state.maybeWhen(
                  loaded: (calls) => calls,
                  orElse: () => <CallHistoryModel>[],
                );
                return _buildHeader(isSelectionMode, currentCalls);
              },
            ),
            if (!_isSearching) _buildFilterPills(),
            if (_isSearching) _buildSearchBar(),
            Expanded(
              child: BlocBuilder<CallHistoryCubit, CallHistoryState>(
                builder: (context, state) {
                  return state.when(
                    initial: () => const Center(child: CircularProgressIndicator()),
                    loading: () => Center(
                      child: CircularProgressIndicator(
                        color: context.colors.primary,
                      ),
                    ),
                    error: (message) => _buildErrorState(context, message),
                    loaded: (calls) {
                      final filteredCalls = calls.where((call) {
                        if (_searchQuery.isNotEmpty) {
                          if (!call.displayName.toLowerCase().contains(_searchQuery)) {
                            return false;
                          }
                        }
                        switch (_currentFilter) {
                          case CallFilter.all:
                            return true;
                          case CallFilter.audio:
                            return !call.isVideoCall;
                          case CallFilter.video:
                            return call.isVideoCall;
                          case CallFilter.missed:
                            return call.isMissed;
                          case CallFilter.incoming:
                            return call.isIncoming;
                          case CallFilter.outgoing:
                            return !call.isIncoming;
                        }
                      }).toList();

                      if (filteredCalls.isEmpty) {
                        return _buildEmptyState(context);
                      }
                      return RefreshIndicator(
                        onRefresh: () => context.read<CallHistoryCubit>().fetchCallHistory(),
                        color: context.colors.primary,
                        child: ListView.builder(
                          padding: const EdgeInsets.only(top: 8, bottom: 80, left: 16, right: 16),
                          itemCount: filteredCalls.length,
                          itemBuilder: (context, index) {
                            final call = filteredCalls[index];
                            final isSelected = _selectedIds.contains(call.id);

                            return _buildCallCard(call, isSelected, isSelectionMode);
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        );
  }

  Widget _buildHeader(bool isSelectionMode, List<CallHistoryModel> currentCalls) {
    if (isSelectionMode) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: context.colors.cardBackground,
          border: Border(
            bottom: BorderSide(color: context.colors.border.withValues(alpha: 0.4)),
          ),
        ),
        child: Row(
          children: [
            IconButton(
              icon: Icon(CommonIcons.close, color: context.colors.textPrimary),
              onPressed: _clearSelection,
            ),
            CommonSpaces.w8,
            Text(
              '${_selectedIds.length} selected',
              style: context.titleMedium.copyWith(
                fontWeight: FontWeight.bold,
                color: context.colors.textPrimary,
              ),
            ),
            const Spacer(),
            IconButton(
              icon: Icon(CommonIcons.delete, color: context.colors.error),
              onPressed: () => _deleteSelected(currentCalls),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Calls',
            style: context.h2.copyWith(
              fontWeight: FontWeight.bold,
              color: context.colors.textPrimary,
            ),
          ),
          Row(
            children: [
              // Search Toggle Button
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: context.colors.lightBackground,
                  border: Border.all(
                    color: context.colors.border.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: IconButton(
                  icon: Icon(
                    _isSearching ? Icons.close : Icons.search,
                    color: context.colors.textPrimary,
                    size: 20,
                  ),
                  onPressed: () {
                    setState(() {
                      _isSearching = !_isSearching;
                      if (!_isSearching) {
                        _searchController.clear();
                        _searchQuery = '';
                      }
                    });
                  },
                ),
              ),
              CommonSpaces.w8,
              // Filter Menu Button
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: context.colors.lightBackground,
                  border: Border.all(
                    color: context.colors.border.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: PopupMenuButton<CallFilter>(
                  icon: Icon(Icons.filter_list_rounded, color: context.colors.textPrimary, size: 20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  color: context.colors.cardBackground,
                  onSelected: (CallFilter filter) {
                    setState(() {
                      _currentFilter = filter;
                    });
                  },
                  itemBuilder: (BuildContext context) => <PopupMenuEntry<CallFilter>>[
                    _buildPopupItem(CallFilter.all, 'All Calls', Icons.phone_callback_rounded),
                    _buildPopupItem(CallFilter.missed, 'Missed Calls', Icons.phone_missed_rounded),
                    _buildPopupItem(CallFilter.incoming, 'Incoming Calls', Icons.call_received_rounded),
                    _buildPopupItem(CallFilter.outgoing, 'Outgoing Calls', Icons.call_made_rounded),
                    _buildPopupItem(CallFilter.audio, 'Audio Calls', Icons.phone_outlined),
                    _buildPopupItem(CallFilter.video, 'Video Calls', Icons.videocam_outlined),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  PopupMenuItem<CallFilter> _buildPopupItem(CallFilter value, String label, IconData icon) {
    final isSelected = _currentFilter == value;
    return PopupMenuItem<CallFilter>(
      value: value,
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: isSelected ? context.colors.primary : context.colors.textSecondary,
          ),
          CommonSpaces.w12,
          Text(
            label,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? context.colors.primary : context.colors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterPills() {
    final filters = [
      (CallFilter.all, 'All'),
      (CallFilter.missed, 'Missed'),
      (CallFilter.incoming, 'Incoming'),
      (CallFilter.outgoing, 'Outgoing'),
      (CallFilter.audio, 'Audio'),
      (CallFilter.video, 'Video'),
    ];

    return Container(
      height: 42,
      margin: const EdgeInsets.only(bottom: 10),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: filters.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final (filter, label) = filters[index];
          final isSelected = _currentFilter == filter;

          return GestureDetector(
            onTap: () => setState(() => _currentFilter = filter),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF00873C)
                    : context.colors.cardBackground.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF00873C)
                      : context.colors.border.withValues(alpha: 0.4),
                  width: 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: const Color(0xFF00873C).withValues(alpha: 0.25),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        )
                      ]
                    : null,
              ),
              child: Center(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected ? Colors.white : context.colors.textSecondary,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Container(
        decoration: BoxDecoration(
          color: context.colors.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: context.colors.border.withValues(alpha: 0.4),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          autofocus: true,
          style: TextStyle(color: context.colors.textPrimary),
          decoration: InputDecoration(
            hintText: 'Search call history...',
            hintStyle: TextStyle(color: context.colors.textHint, fontSize: 14),
            prefixIcon: Icon(Icons.search, color: context.colors.primary, size: 20),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.clear, color: context.colors.textHint, size: 18),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ),
    );
  }

  Widget _buildCallCard(CallHistoryModel call, bool isSelected, bool isSelectionMode) {
    final isDark = context.colors.isDark;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isSelected
            ? context.colors.primary.withValues(alpha: 0.12)
            : (isDark ? context.colors.cardBackground : Colors.white),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isSelected
              ? context.colors.primary
              : context.colors.border.withValues(alpha: 0.35),
          width: isSelected ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          if (isSelectionMode) {
            _toggleSelection(call.id);
          } else {
            _startCall(call, isVideo: call.isVideoCall);
          }
        },
        onLongPress: () {
          if (!isSelectionMode) {
            _toggleSelection(call.id);
          }
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              // Avatar with Selection Badge
              Stack(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: const Color(0xFFE8F5E9),
                    backgroundImage: call.displayAvatar != null && call.displayAvatar!.isNotEmpty
                        ? NetworkImage(call.displayAvatar!)
                        : null,
                    child: (call.displayAvatar == null || call.displayAvatar!.isEmpty)
                        ? Text(
                            call.displayName.isNotEmpty
                                ? call.displayName.substring(0, 1).toUpperCase()
                                : '?',
                            style: const TextStyle(
                              color: Color(0xFF00873C),
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          )
                        : null,
                  ),
                  if (isSelected)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: context.colors.primary,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: 2,
                          ),
                        ),
                        child: const Icon(
                          Icons.check,
                          size: 12,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 14),
              // Caller Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      call.count > 1
                          ? '${call.displayName} (${call.count})'
                          : call.displayName,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: call.isMissed
                            ? const Color(0xFFE53935)
                            : context.colors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          call.isMissed
                              ? Icons.call_missed_rounded
                              : (call.isIncoming
                                  ? Icons.call_received_rounded
                                  : Icons.call_made_rounded),
                          size: 15,
                          color: call.isMissed
                              ? const Color(0xFFE53935)
                              : (call.isIncoming
                                  ? const Color(0xFF00873C)
                                  : const Color(0xFF12B76A)),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          _formatTime(call.createdAt),
                          style: TextStyle(
                            color: context.colors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                        if (call.isVideoCall) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: context.colors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Video',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: context.colors.primary,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              // Call Action Button
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: IconButton(
                  icon: Icon(
                    call.isVideoCall ? Icons.videocam_rounded : Icons.phone_rounded,
                    color: const Color(0xFF00873C),
                    size: 20,
                  ),
                  onPressed: () => _startCall(call, isVideo: call.isVideoCall),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00873C).withValues(alpha: 0.15),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.phone_in_talk_rounded,
                  size: 40,
                  color: Color(0xFF00873C),
                ),
              ),
              CommonSpaces.h20,
              Text(
                _currentFilter == CallFilter.all
                    ? 'No Call History'
                    : 'No ${_currentFilter.name.capitalize()} Calls',
                style: context.titleLarge.copyWith(
                  fontWeight: FontWeight.bold,
                  color: context.colors.textPrimary,
                ),
              ),
              CommonSpaces.h8,
              Text(
                'Calls you make and receive will appear here with instant callback actions.',
                style: TextStyle(
                  color: context.colors.textSecondary,
                  fontSize: 14,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              CommonSpaces.h24,
              ElevatedButton.icon(
                onPressed: () => context.read<CallHistoryCubit>().fetchCallHistory(),
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Refresh'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00873C),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(22),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  elevation: 2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: context.colors.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: 36,
                color: context.colors.error,
              ),
            ),
            CommonSpaces.h16,
            Text(
              'Failed to load calls',
              style: context.titleLarge.copyWith(
                fontWeight: FontWeight.bold,
                color: context.colors.textPrimary,
              ),
            ),
            CommonSpaces.h8,
            Text(
              message,
              style: TextStyle(color: context.colors.textSecondary, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            CommonSpaces.h20,
            ElevatedButton(
              onPressed: () => context.read<CallHistoryCubit>().fetchCallHistory(),
              style: ElevatedButton.styleFrom(
                backgroundColor: context.colors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return 'Recent';
    try {
      final date = DateTime.parse(dateStr).toLocal();
      final now = DateTime.now();

      final String hour = (date.hour == 0 ? 12 : (date.hour > 12 ? date.hour - 12 : date.hour))
          .toString()
          .padLeft(2, '0');
      final String minute = date.minute.toString().padLeft(2, '0');
      final String period = date.hour >= 12 ? 'PM' : 'AM';
      final String timeStr = '$hour:$minute $period';

      if (date.year == now.year && date.month == now.month && date.day == now.day) {
        return 'Today, $timeStr';
      } else if (date.year == now.year && date.month == now.month && date.day == now.day - 1) {
        return 'Yesterday, $timeStr';
      }

      final List<String> monthNames = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];

      return '${monthNames[date.month - 1]} ${date.day}, $timeStr';
    } catch (e) {
      return dateStr;
    }
  }
}

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}
