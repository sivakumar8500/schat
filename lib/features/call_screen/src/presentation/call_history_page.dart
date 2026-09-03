import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:schat/injection.dart';
import 'package:schat/utils/common_fontstyles.dart';
import 'package:schat/utils/common_colors.dart';
import 'package:schat/utils/common_spaces.dart';
import 'package:schat/utils/common_icons.dart';
import 'package:schat/features/call_screen/src/domain/call_history.dart';
import 'package:schat/features/call_screen/src/domain/repositories/call_history_repository.dart';
import 'package:schat/features/call_screen/src/presentation/bloc/call_history_cubit.dart';
import 'package:schat/features/call_screen/src/presentation/bloc/call_history_state.dart';

enum CallFilter { all, audio, video, missed, incoming, outgoing }

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

  @override
  Widget build(BuildContext context) {
    final bool isSelectionMode = _selectedIds.isNotEmpty;

    return Column(
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
                      padding: const EdgeInsets.only(top: 8, bottom: 80),
                      itemCount: filteredCalls.length,
                      itemBuilder: (context, index) {
                        final call = filteredCalls[index];
                        final isSelected = _selectedIds.contains(call.id);

                        return InkWell(
                          onTap: () {
                            if (isSelectionMode) {
                              _toggleSelection(call.id);
                            }
                          },
                          onLongPress: () {
                            if (!isSelectionMode) {
                              _toggleSelection(call.id);
                            }
                          },
                          child: Container(
                            color: isSelected
                                ? context.colors.primary.withValues(alpha: 0.1)
                                : context.colors.transparent,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            child: Row(
                              children: [
                                Stack(
                                  children: [
                                    CircleAvatar(
                                      radius: 28,
                                      backgroundColor: context.colors.primary.withValues(alpha: 0.15),
                                      backgroundImage: call.displayAvatar != null 
                                          ? NetworkImage(call.displayAvatar!) 
                                          : null,
                                      child: call.displayAvatar == null ? Text(
                                        call.displayName.isNotEmpty
                                            ? call.displayName.substring(0, 1).toUpperCase()
                                            : '?',
                                        style: context.h3.copyWith(
                                          color: context.colors.primary,
                                        ),
                                      ) : null,
                                    ),
                                    if (isSelected)
                                      Positioned(
                                        right: 0,
                                        bottom: 0,
                                        child: Container(
                                          width: 22,
                                          height: 22,
                                          decoration: BoxDecoration(
                                            color: context.colors.primary,
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: context.colors.scaffoldBackground,
                                              width: 2,
                                            ),
                                          ),
                                          child: Icon(
                                            CommonIcons.check,
                                            size: 14,
                                            color: context.colors.textLight,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                CommonSpaces.w16,
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        call.count > 1
                                            ? '${call.displayName} (${call.count})'
                                            : call.displayName,
                                        style: context.titleSmall.copyWith(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 16,
                                          color: call.isMissed
                                              ? context.colors.error
                                              : context.colors.textPrimary,
                                        ),
                                      ),
                                      CommonSpaces.h4,
                                      Row(
                                        children: [
                                          Icon(
                                            call.isIncoming
                                                ? CommonIcons.callReceived
                                                : CommonIcons.callMade,
                                            size: 16,
                                            color: call.isMissed
                                                ? context.colors.error
                                                : (call.isIncoming
                                                    ? context.colors.success
                                                    : context.colors.primary),
                                          ),
                                          CommonSpaces.w4,
                                          Text(
                                            _formatTime(call.createdAt),
                                            style: context.bodyLarge.copyWith(
                                              color: context.colors.textSecondary,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                CommonSpaces.w12,
                                IconButton(
                                  icon: Icon(
                                    call.isVideoCall
                                        ? CommonIcons.videocam
                                        : CommonIcons.phone,
                                    color: context.colors.primary,
                                  ),
                                  onPressed: () {},
                                ),
                              ],
                            ),
                          ),
                        );
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
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            IconButton(
              icon: Icon(CommonIcons.close, color: context.colors.textPrimary),
              onPressed: _clearSelection,
            ),
            CommonSpaces.w8,
            Text(
              '${_selectedIds.length}',
              style: context.h3.copyWith(
                fontSize: 24,
                color: context.colors.textPrimary,
              ),
            ),
            const Spacer(),
            IconButton(
              icon: Icon(CommonIcons.delete, color: context.colors.textPrimary),
              onPressed: () => _deleteSelected(currentCalls),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Calls',
            style: context.h2.copyWith(
              fontSize: 32,
              color: context.colors.textPrimary,
            ),
          ),
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: context.colors.lightBackground,
            ),
            child: PopupMenuButton<CallFilter>(
              icon: Icon(Icons.filter_list_rounded, color: context.colors.textPrimary),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              onSelected: (CallFilter filter) {
                setState(() {
                  _currentFilter = filter;
                });
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<CallFilter>>[
                const PopupMenuItem<CallFilter>(
                  value: CallFilter.all,
                  child: Text('All Calls'),
                ),
                const PopupMenuItem<CallFilter>(
                  value: CallFilter.audio,
                  child: Text('Audio Calls'),
                ),
                const PopupMenuItem<CallFilter>(
                  value: CallFilter.video,
                  child: Text('Video Calls'),
                ),
                const PopupMenuItem<CallFilter>(
                  value: CallFilter.missed,
                  child: Text('Missed Calls'),
                ),
                const PopupMenuItem<CallFilter>(
                  value: CallFilter.incoming,
                  child: Text('Incoming Calls'),
                ),
                const PopupMenuItem<CallFilter>(
                  value: CallFilter.outgoing,
                  child: Text('Outgoing Calls'),
                ),
              ],
            ),
          ),
        ],
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
            Icon(
              CommonIcons.errorOutline,
              size: 56,
              color: context.colors.error.withValues(alpha: 0.8),
            ),
            CommonSpaces.h16,
            Text(
              'Failed to load call history',
              style: context.titleMedium.copyWith(
                color: context.colors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            CommonSpaces.h8,
            Text(
              message,
              textAlign: TextAlign.center,
              style: context.bodyMedium.copyWith(
                color: context.colors.textSecondary,
              ),
            ),
            CommonSpaces.h24,
            ElevatedButton.icon(
              onPressed: () => context.read<CallHistoryCubit>().fetchCallHistory(),
              icon: Icon(CommonIcons.syncIcon, color: context.colors.textLight),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: context.colors.primary,
                foregroundColor: context.colors.textLight,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () => context.read<CallHistoryCubit>().fetchCallHistory(),
      color: context.colors.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.65,
          padding: const EdgeInsets.symmetric(horizontal: 36.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Empty State Illustration Icon Container
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      context.colors.primary.withValues(alpha: 0.15),
                      context.colors.primary.withValues(alpha: 0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: context.colors.primary.withValues(alpha: 0.08),
                      blurRadius: 24,
                      spreadRadius: 8,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Center(
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: context.colors.primary.withValues(alpha: 0.2),
                    ),
                    child: Icon(
                      CommonIcons.phoneMissed,
                      size: 38,
                      color: context.colors.primary,
                    ),
                  ),
                ),
              ),
              CommonSpaces.h32,
              Text(
                'No call history yet',
                style: context.h3.copyWith(
                  color: context.colors.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                ),
                textAlign: TextAlign.center,
              ),
              CommonSpaces.h12,
              Text(
                'Calls you make and receive will show up here. Pull down or tap below to refresh your call log.',
                style: context.bodyMedium.copyWith(
                  color: context.colors.textSecondary,
                  fontSize: 14,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              CommonSpaces.h32,
              OutlinedButton.icon(
                onPressed: () => context.read<CallHistoryCubit>().fetchCallHistory(),
                icon: Icon(CommonIcons.syncIcon, size: 18, color: context.colors.primary),
                label: Text(
                  'Refresh History',
                  style: context.titleSmall.copyWith(
                    color: context.colors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: context.colors.primary.withValues(alpha: 0.4), width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return 'Recent';
    try {
      final date = DateTime.parse(dateStr).toLocal();
      final now = DateTime.now();
      
      final String hour = (date.hour == 0 ? 12 : (date.hour > 12 ? date.hour - 12 : date.hour)).toString().padLeft(2, '0');
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
