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
import 'package:schat/features/call_screen/src/presentation/bloc/call_webrtc_state.dart';
import 'package:schat/features/call_screen/src/presentation/audio_call_page.dart';
import 'package:schat/features/call_screen/src/presentation/video_call_page.dart';
import 'package:schat/core/network/api_result.dart';
import 'package:schat/features/dashboard_screen/src/domain/repositories/dashboard_repository.dart';
import 'package:schat/features/dashboard_screen/src/domain/models/chat_model.dart';
import 'package:schat/features/call_screen/src/domain/models/ongoing_group_call.dart';
import 'package:schat/features/profile_screen/src/domain/models/user_model.dart';
import 'package:schat/features/chat_screen/src/domain/repositories/chat_repository.dart';

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

  Future<void> _deleteSelected(List<CallHistoryModel> currentCalls) async {
    if (_selectedIds.isEmpty) return;

    final count = _selectedIds.length;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.colors.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Delete Call${count > 1 ? 's' : ''}?',
          style: context.titleMedium.copyWith(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to remove $count selected call ${count > 1 ? 'records' : 'record'} from your history?',
          style: context.bodyMedium.copyWith(color: context.colors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: TextStyle(color: context.colors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: context.colors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final idsToDelete = Set<String>.from(_selectedIds);
      _clearSelection();
      await context.read<CallHistoryCubit>().deleteMultipleCalls(idsToDelete);
    }
  }

  Future<bool> _confirmDeleteSingleCall(CallHistoryModel call) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.colors.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Delete Call Log?',
          style: context.titleMedium.copyWith(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Remove call history with ${call.displayName}?',
          style: context.bodyMedium.copyWith(color: context.colors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: TextStyle(color: context.colors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: context.colors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    return confirmed == true;
  }

  void _onCallItemTapped(CallHistoryModel call) {
    if (_selectedIds.isNotEmpty) {
      _toggleSelection(call.id);
    } else if (call.isGroup || (call.groupName != null && call.groupName!.isNotEmpty)) {
      _showGroupParticipantPicker(call);
    } else {
      _startCall(call, isVideo: call.isVideoCall);
    }
  }

  void _showGroupParticipantPicker(CallHistoryModel call) {
    final convoId = call.conversationId ?? '';
    if (convoId.isEmpty) {
      _startCall(call, isVideo: call.isVideoCall);
      return;
    }

    final myId = (getIt<StorageService>().getUserId() ?? '').trim();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) {
        return _GroupCallParticipantPickerSheet(
          conversationId: convoId,
          groupName: call.displayName,
          groupPictureUrl: call.displayAvatar,
          myId: myId,
          onStartCall: (selectedParticipants, isVideo) {
            _startGroupCall(
              conversationId: convoId,
              groupName: call.displayName,
              groupPictureUrl: call.displayAvatar,
              selectedParticipants: selectedParticipants,
              isVideo: isVideo,
            );
          },
        );
      },
    );
  }

  void _startGroupCall({
    required String conversationId,
    required String groupName,
    required String? groupPictureUrl,
    required List<UserModel> selectedParticipants,
    required bool isVideo,
  }) async {
    final hasPermission = await PermissionHelper.checkCallPermissions(isVideo: isVideo);
    if (!mounted || !hasPermission) return;

    if (isVideo) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => BlocProvider.value(
            value: getIt<CallWebRtcBloc>(),
            child: VideoCallPage(
              conversationId: conversationId,
              contactName: groupName,
              contactColor: const Color(0xFF00873C),
              recipientId: '',
              isOutgoing: true,
              profilePictureUrl: groupPictureUrl,
              myProfilePictureUrl: getIt<StorageService>().getProfilePic(),
              isGroup: true,
              groupName: groupName,
              extraParticipants: selectedParticipants,
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
              contactName: groupName,
              contactColor: const Color(0xFF00873C),
              recipientId: '',
              isOutgoing: true,
              profilePictureUrl: groupPictureUrl,
              myProfilePictureUrl: getIt<StorageService>().getProfilePic(),
              isGroup: true,
              groupName: groupName,
              extraParticipants: selectedParticipants,
            ),
          ),
        ),
      );
    }
  }

  void _startCall(CallHistoryModel call, {required bool isVideo}) async {
    if (call.isGroup || (call.groupName != null && call.groupName!.isNotEmpty)) {
      _showGroupParticipantPicker(call);
      return;
    }

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
        BlocBuilder<CallWebRtcBloc, CallWebRtcState>(
          builder: (context, _) {
            final ongoingCalls = getIt<CallWebRtcBloc>()
                .ongoingGroupCalls
                .values
                .where((c) => c.connectedParticipantIds.isNotEmpty)
                .toList();
            if (ongoingCalls.isEmpty) return const SizedBox.shrink();
            return _buildOngoingCallsSection(ongoingCalls);
          },
        ),
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
                    child: ListView.separated(
                      padding: const EdgeInsets.only(top: 4, bottom: 80),
                      itemCount: filteredCalls.length,
                      separatorBuilder: (context, index) => Divider(
                        height: 1,
                        indent: 72,
                        endIndent: 16,
                        color: context.colors.border.withValues(alpha: 0.15),
                      ),
                      itemBuilder: (context, index) {
                        final call = filteredCalls[index];
                        final isSelected = _selectedIds.contains(call.id);

                        return _buildCallListItem(call, isSelected, isSelectionMode);
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
      final allSelected = currentCalls.isNotEmpty && _selectedIds.length == currentCalls.length;
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
              icon: Icon(
                allSelected ? Icons.deselect_rounded : Icons.select_all_rounded,
                color: context.colors.textPrimary,
              ),
              tooltip: allSelected ? 'Deselect all' : 'Select all',
              onPressed: () {
                setState(() {
                  if (allSelected) {
                    _selectedIds.clear();
                  } else {
                    _selectedIds.addAll(currentCalls.map((c) => c.id));
                  }
                });
              },
            ),
            IconButton(
              icon: Icon(CommonIcons.delete, color: context.colors.error),
              tooltip: 'Delete selected',
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
              CommonSpaces.w8,
              // More Actions Button (Select Multiple / Clear All)
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
                child: PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert_rounded, color: context.colors.textPrimary, size: 20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  color: context.colors.cardBackground,
                  onSelected: (val) async {
                    if (val == 'select_multiple') {
                      if (currentCalls.isNotEmpty) {
                        _toggleSelection(currentCalls.first.id);
                      }
                    } else if (val == 'clear_all') {
                      if (currentCalls.isEmpty) return;
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          backgroundColor: context.colors.cardBackground,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          title: const Text('Clear Call Log?'),
                          content: const Text('Do you want to clear your entire call history? This cannot be undone.'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: Text('Cancel', style: TextStyle(color: context.colors.textSecondary)),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: context.colors.error,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              onPressed: () => Navigator.pop(ctx, true),
                              child: const Text('Clear All'),
                            ),
                          ],
                        ),
                      );
                      if (confirmed == true && mounted) {
                        final allIds = currentCalls.map((c) => c.id).toSet();
                        context.read<CallHistoryCubit>().deleteMultipleCalls(allIds);
                      }
                    }
                  },
                  itemBuilder: (ctx) => [
                    PopupMenuItem(
                      value: 'select_multiple',
                      child: Row(
                        children: [
                          Icon(Icons.checklist_rounded, size: 18, color: context.colors.textPrimary),
                          const SizedBox(width: 10),
                          Text('Select Multiple', style: TextStyle(color: context.colors.textPrimary)),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'clear_all',
                      child: Row(
                        children: [
                          Icon(Icons.delete_sweep_outlined, size: 18, color: context.colors.error),
                          const SizedBox(width: 10),
                          Text('Clear Call Log', style: TextStyle(color: context.colors.error)),
                        ],
                      ),
                    ),
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
          style: TextStyle(color: context.colors.textPrimary, fontSize: 16),
          decoration: InputDecoration(
            hintText: 'Search call history...',
            hintStyle: TextStyle(color: context.colors.textHint, fontSize: 16),
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

  Widget _buildCallListItem(CallHistoryModel call, bool isSelected, bool isSelectionMode) {
    final isGroup = call.isGroup || (call.groupName != null && call.groupName!.isNotEmpty);

    final Widget itemContent = InkWell(
      onTap: () => _onCallItemTapped(call),
      onLongPress: () {
        if (!isSelectionMode) {
          _toggleSelection(call.id);
        }
      },
      child: Container(
        color: isSelected
            ? context.colors.primary.withValues(alpha: 0.1)
            : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Avatar with Selection Badge
            Stack(
              children: [
                CircleAvatar(
                  radius: 25,
                  backgroundColor: const Color(0xFFE8F5E9),
                  backgroundImage: call.displayAvatar != null && call.displayAvatar!.isNotEmpty
                      ? NetworkImage(call.displayAvatar!)
                      : null,
                  child: (call.displayAvatar == null || call.displayAvatar!.isEmpty)
                      ? (isGroup
                          ? const Icon(
                              Icons.groups_rounded,
                              color: Color(0xFF00873C),
                              size: 26,
                            )
                          : Text(
                              call.displayName.isNotEmpty
                                  ? call.displayName.substring(0, 1).toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                color: Color(0xFF00873C),
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ))
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
            // Caller / Group Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
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
                      ),
                      if (isGroup) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: Text(
                            '|',
                            style: TextStyle(
                              color: context.colors.textSecondary.withValues(alpha: 0.4),
                              fontSize: 13,
                              fontWeight: FontWeight.w300,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00873C).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Group',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF00873C),
                            ),
                          ),
                        ),
                      ],
                    ],
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
                    ],
                  ),
                ],
              ),
            ),
            // Action Buttons / Selection Checkbox
            if (isSelectionMode)
              Checkbox(
                value: isSelected,
                activeColor: context.colors.primary,
                onChanged: (_) => _toggleSelection(call.id),
              )
            else
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(
                      call.isVideoCall ? Icons.videocam_rounded : Icons.phone_rounded,
                      color: const Color(0xFF00873C),
                      size: 22,
                    ),
                    onPressed: () {
                      if (isGroup) {
                        _showGroupParticipantPicker(call);
                      } else {
                        _startCall(call, isVideo: call.isVideoCall);
                      }
                    },
                  ),
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert_rounded, size: 18, color: context.colors.textSecondary),
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    color: context.colors.cardBackground,
                    itemBuilder: (ctx) => [
                      PopupMenuItem(
                        value: 'call',
                        child: Row(
                          children: [
                            Icon(call.isVideoCall ? Icons.videocam_outlined : Icons.phone_outlined, size: 18, color: context.colors.textPrimary),
                            const SizedBox(width: 10),
                            Text(call.isVideoCall ? 'Video Call' : 'Voice Call', style: TextStyle(color: context.colors.textPrimary)),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'select',
                        child: Row(
                          children: [
                            Icon(Icons.checklist_rounded, size: 18, color: context.colors.textPrimary),
                            const SizedBox(width: 10),
                            Text('Select', style: TextStyle(color: context.colors.textPrimary)),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline_rounded, size: 18, color: context.colors.error),
                            const SizedBox(width: 10),
                            Text('Delete', style: TextStyle(color: context.colors.error)),
                          ],
                        ),
                      ),
                    ],
                    onSelected: (action) async {
                      if (action == 'call') {
                        if (isGroup) {
                          _showGroupParticipantPicker(call);
                        } else {
                          _startCall(call, isVideo: call.isVideoCall);
                        }
                      } else if (action == 'select') {
                        _toggleSelection(call.id);
                      } else if (action == 'delete') {
                        final confirmed = await _confirmDeleteSingleCall(call);
                        if (confirmed && mounted) {
                          context.read<CallHistoryCubit>().deleteCall(call.id);
                        }
                      }
                    },
                  ),
                ],
              ),
          ],
        ),
      ),
    );

    if (isSelectionMode) {
      return itemContent;
    }

    return Dismissible(
      key: ValueKey(call.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        color: context.colors.error,
        child: const Icon(
          Icons.delete_outline_rounded,
          color: Colors.white,
          size: 24,
        ),
      ),
      confirmDismiss: (direction) async {
        return await _confirmDeleteSingleCall(call);
      },
      onDismissed: (direction) {
        context.read<CallHistoryCubit>().deleteCall(call.id);
      },
      child: itemContent,
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

  Widget _buildOngoingCallsSection(List<OngoingGroupCall> ongoingCalls) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: ongoingCalls.map((call) => _buildOngoingCallCard(call)).toList(),
      ),
    );
  }

  Widget _buildOngoingCallCard(OngoingGroupCall ongoingCall) {
    final activeCount = ongoingCall.connectedParticipantIds.isNotEmpty
        ? ongoingCall.connectedParticipantIds.length
        : (ongoingCall.participants.isNotEmpty ? ongoingCall.participants.length : 1);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF00873C).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF00873C).withValues(alpha: 0.4),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF00E676),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0xFF00E676),
                      blurRadius: 6,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
              CommonSpaces.w6,
              Text(
                'LIVE GROUP CALL',
                style: context.bodySmall.copyWith(
                  color: const Color(0xFF00E676),
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                  fontSize: 10,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () {
                  getIt<CallWebRtcBloc>().dismissOngoingGroupCall(ongoingCall.conversationId);
                  setState(() {});
                },
                child: Icon(
                  Icons.close,
                  size: 18,
                  color: context.colors.textSecondary.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
          CommonSpaces.h8,
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF00873C).withValues(alpha: 0.25),
                  border: Border.all(
                    color: const Color(0xFF00873C),
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: ongoingCall.profilePictureUrl != null && ongoingCall.profilePictureUrl!.isNotEmpty
                      ? ClipOval(
                          child: Image.network(
                            ongoingCall.profilePictureUrl!,
                            width: 44,
                            height: 44,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => const Icon(
                              Icons.group,
                              color: Color(0xFF00E676),
                              size: 22,
                            ),
                          ),
                        )
                      : const Icon(
                          Icons.group,
                          color: Color(0xFF00E676),
                          size: 22,
                        ),
                ),
              ),
              CommonSpaces.w12,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ongoingCall.groupName,
                      style: context.titleMedium.copyWith(
                        fontWeight: FontWeight.bold,
                        color: context.colors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    CommonSpaces.h2,
                    Row(
                      children: [
                        Icon(
                          ongoingCall.isVideo ? Icons.videocam : Icons.phone_in_talk,
                          size: 13,
                          color: const Color(0xFF00E676),
                        ),
                        CommonSpaces.w4,
                        Text(
                          '$activeCount active • ${ongoingCall.isVideo ? "Video" : "Audio"}',
                          style: context.bodySmall.copyWith(
                            color: context.colors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              CommonSpaces.w8,
              ElevatedButton.icon(
                onPressed: () => _rejoinGroupCall(ongoingCall),
                icon: Icon(
                  ongoingCall.isVideo ? Icons.videocam : Icons.call,
                  size: 16,
                  color: Colors.white,
                ),
                label: const Text(
                  'Join',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00873C),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  elevation: 2,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _rejoinGroupCall(OngoingGroupCall call) async {
    final hasPermission = await PermissionHelper.checkCallPermissions(isVideo: call.isVideo);
    if (!mounted || !hasPermission) return;

    if (call.isVideo) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => BlocProvider.value(
            value: getIt<CallWebRtcBloc>(),
            child: VideoCallPage(
              conversationId: call.conversationId,
              contactName: call.groupName,
              contactColor: const Color(0xFF00873C),
              recipientId: '',
              isOutgoing: true,
              isGroup: true,
              groupName: call.groupName,
              profilePictureUrl: call.profilePictureUrl,
              extraParticipants: call.participants,
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
              conversationId: call.conversationId,
              contactName: call.groupName,
              contactColor: const Color(0xFF00873C),
              recipientId: '',
              isOutgoing: true,
              isGroup: true,
              groupName: call.groupName,
              profilePictureUrl: call.profilePictureUrl,
              extraParticipants: call.participants,
            ),
          ),
        ),
      );
    }
  }
}

class _GroupCallParticipantPickerSheet extends StatefulWidget {
  final String conversationId;
  final String groupName;
  final String? groupPictureUrl;
  final String myId;
  final void Function(List<UserModel> selectedParticipants, bool isVideo) onStartCall;

  const _GroupCallParticipantPickerSheet({
    required this.conversationId,
    required this.groupName,
    this.groupPictureUrl,
    required this.myId,
    required this.onStartCall,
  });

  @override
  State<_GroupCallParticipantPickerSheet> createState() => _GroupCallParticipantPickerSheetState();
}

class _GroupCallParticipantPickerSheetState extends State<_GroupCallParticipantPickerSheet> {
  bool _isLoading = true;
  String? _errorMessage;
  List<UserModel> _participants = [];
  final Set<String> _selectedUserIds = {};

  @override
  void initState() {
    super.initState();
    _loadParticipants();
  }

  Future<void> _loadParticipants() async {
    try {
      final repo = getIt<ChatRepository>();
      final data = await repo.getGroupDetails(widget.conversationId);
      final participantsData = data['participants'];
      final List<UserModel> list = [];
      if (participantsData is List) {
        for (var p in participantsData) {
          if (p is Map) {
            final userJson = p['user'] ?? p;
            if (userJson is Map) {
              final user = UserModel.fromJson(Map<String, dynamic>.from(userJson));
              if (user.id.isNotEmpty && user.id != widget.myId) {
                list.add(user);
              }
            }
          }
        }
      }

      if (mounted) {
        setState(() {
          _participants = list;
          _selectedUserIds.addAll(list.map((u) => u.id));
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load group participants: $e';
          _isLoading = false;
        });
      }
    }
  }

  void _toggleAll() {
    setState(() {
      if (_selectedUserIds.length == _participants.length) {
        _selectedUserIds.clear();
      } else {
        _selectedUserIds.clear();
        _selectedUserIds.addAll(_participants.map((u) => u.id));
      }
    });
  }

  void _toggleUser(String id) {
    setState(() {
      if (_selectedUserIds.contains(id)) {
        _selectedUserIds.remove(id);
      } else {
        _selectedUserIds.add(id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final allSelected = _participants.isNotEmpty && _selectedUserIds.length == _participants.length;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      decoration: BoxDecoration(
        color: context.colors.cardBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: context.colors.border.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: const Color(0xFFE8F5E9),
                  backgroundImage: widget.groupPictureUrl != null && widget.groupPictureUrl!.isNotEmpty
                      ? NetworkImage(widget.groupPictureUrl!)
                      : null,
                  child: widget.groupPictureUrl == null || widget.groupPictureUrl!.isEmpty
                      ? const Icon(Icons.groups_rounded, color: Color(0xFF00873C), size: 20)
                      : null,
                ),
                CommonSpaces.w12,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.groupName,
                        style: context.titleMedium.copyWith(
                          fontWeight: FontWeight.bold,
                          color: context.colors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        _isLoading
                            ? 'Loading members...'
                            : '${_selectedUserIds.length} of ${_participants.length} selected',
                        style: context.bodySmall.copyWith(
                          color: context.colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_participants.isNotEmpty)
                  TextButton(
                    onPressed: _toggleAll,
                    child: Text(
                      allSelected ? 'Deselect All' : 'Select All',
                      style: const TextStyle(
                        color: Color(0xFF00873C),
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Body
          Flexible(
            child: _isLoading
                ? const Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Center(
                      child: CircularProgressIndicator(color: Color(0xFF00873C)),
                    ),
                  )
                : _errorMessage != null
                    ? Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _errorMessage!,
                              style: TextStyle(color: context.colors.error, fontSize: 13),
                              textAlign: TextAlign.center,
                            ),
                            CommonSpaces.h12,
                            ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  _isLoading = true;
                                  _errorMessage = null;
                                });
                                _loadParticipants();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF00873C),
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : _participants.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.all(32.0),
                            child: Center(
                              child: Text(
                                'No other participants in this group.',
                                style: TextStyle(color: context.colors.textSecondary),
                              ),
                            ),
                          )
                        : ListView.separated(
                            shrinkWrap: true,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            itemCount: _participants.length,
                            separatorBuilder: (context, index) => Divider(
                              height: 1,
                              indent: 68,
                              endIndent: 16,
                              color: context.colors.border.withValues(alpha: 0.15),
                            ),
                            itemBuilder: (context, index) {
                              final user = _participants[index];
                              final isChecked = _selectedUserIds.contains(user.id);
                              return CheckboxListTile(
                                value: isChecked,
                                activeColor: const Color(0xFF00873C),
                                checkboxShape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
                                secondary: CircleAvatar(
                                  radius: 20,
                                  backgroundColor: const Color(0xFFE8F5E9),
                                  backgroundImage: user.profilePictureUrl != null && user.profilePictureUrl!.isNotEmpty
                                      ? NetworkImage(user.profilePictureUrl!)
                                      : null,
                                  child: user.profilePictureUrl == null || user.profilePictureUrl!.isEmpty
                                      ? Text(
                                          user.displayName.isNotEmpty
                                              ? user.displayName.substring(0, 1).toUpperCase()
                                              : '?',
                                          style: const TextStyle(
                                            color: Color(0xFF00873C),
                                            fontWeight: FontWeight.bold,
                                          ),
                                        )
                                      : null,
                                ),
                                title: Text(
                                  user.displayName,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                    color: context.colors.textPrimary,
                                  ),
                                ),
                                subtitle: user.phoneNumber.isNotEmpty
                                    ? Text(
                                        user.phoneNumber,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: context.colors.textSecondary,
                                        ),
                                      )
                                    : null,
                                onChanged: (_) => _toggleUser(user.id),
                              );
                            },
                          ),
          ),
          // Action Buttons
          SafeArea(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: context.colors.cardBackground,
                border: Border(
                  top: BorderSide(
                    color: context.colors.border.withValues(alpha: 0.2),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _selectedUserIds.isEmpty
                          ? null
                          : () {
                              Navigator.pop(context);
                              final selected = _participants
                                  .where((u) => _selectedUserIds.contains(u.id))
                                  .toList();
                              widget.onStartCall(selected, false);
                            },
                      icon: const Icon(Icons.phone_rounded, size: 20),
                      label: const Text('Voice Call'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF00873C),
                        side: BorderSide(
                          color: _selectedUserIds.isEmpty
                              ? Colors.grey.withValues(alpha: 0.3)
                              : const Color(0xFF00873C),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                  CommonSpaces.w12,
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _selectedUserIds.isEmpty
                          ? null
                          : () {
                              Navigator.pop(context);
                              final selected = _participants
                                  .where((u) => _selectedUserIds.contains(u.id))
                                  .toList();
                              widget.onStartCall(selected, true);
                            },
                      icon: const Icon(Icons.videocam_rounded, size: 20),
                      label: const Text('Video Call'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00873C),
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey.withValues(alpha: 0.3),
                        disabledForegroundColor: Colors.grey,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}
