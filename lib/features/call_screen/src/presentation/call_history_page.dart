import 'package:flutter/material.dart';
import 'package:schat/utils/common_fontstyles.dart';
import 'package:schat/utils/common_colors.dart';
import 'package:schat/utils/common_spaces.dart';

class CallLog {
  final String id;
  final String name;
  final String time;
  final Color avatarColor;
  final bool isIncoming;
  final bool isMissed;
  final bool isVideoCall;
  final int count;

  CallLog({
    required this.id,
    required this.name,
    required this.time,
    required this.avatarColor,
    required this.isIncoming,
    required this.isMissed,
    required this.isVideoCall,
    this.count = 1,
  });
}

class CallHistoryPage extends StatefulWidget {
  const CallHistoryPage({super.key});

  @override
  State<CallHistoryPage> createState() => _CallHistoryPageState();
}

class _CallHistoryPageState extends State<CallHistoryPage> {
  final Set<String> _selectedIds = {};

  List<CallLog> _calls = [];

  @override
  void initState() {
    super.initState();
    _calls = [
      CallLog(
        id: '1',
        name: 'Alice Smith',
        time: 'Today, 10:30 AM',
        avatarColor: Colors.pinkAccent,
        isIncoming: true,
        isMissed: false,
        isVideoCall: true,
      ),
      CallLog(
        id: '2',
        name: 'Bob Johnson',
        time: 'Yesterday, 8:45 PM',
        avatarColor: Colors.blueAccent,
        isIncoming: false,
        isMissed: false,
        isVideoCall: false,
      ),
      CallLog(
        id: '3',
        name: 'Charlie Brown',
        time: 'Yesterday, 6:15 PM',
        avatarColor: Colors.greenAccent,
        isIncoming: true,
        isMissed: true,
        isVideoCall: false,
        count: 2,
      ),
      CallLog(
        id: '4',
        name: 'Design Team',
        time: 'Monday, 2:00 PM',
        avatarColor: Colors.purpleAccent,
        isIncoming: false,
        isMissed: false,
        isVideoCall: true,
      ),
      CallLog(
        id: '5',
        name: 'Mom',
        time: 'Sunday, 11:00 AM',
        avatarColor: Colors.orangeAccent,
        isIncoming: true,
        isMissed: true,
        isVideoCall: false,
      ),
    ];
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

  void _deleteSelected() {
    setState(() {
      _calls.removeWhere((call) => _selectedIds.contains(call.id));
      _selectedIds.clear();
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedIds.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isSelectionMode = _selectedIds.isNotEmpty;

    return Column(
      children: [
        _buildHeader(isSelectionMode),
        Expanded(
          child: _calls.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.only(top: 8, bottom: 80),
                  itemCount: _calls.length,
                  itemBuilder: (context, index) {
                    final call = _calls[index];
                    final isSelected = _selectedIds.contains(call.id);

                    return InkWell(
                      onTap: () {
                        if (isSelectionMode) {
                          _toggleSelection(call.id);
                        } else {
                          // Handle normal tap, e.g., view call info or callback
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
                            : Colors.transparent,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                        child: Row(
                          children: [
                            // Avatar section with possible checkmark
                            Stack(
                              children: [
                                CircleAvatar(
                                  radius: 28,
                                  backgroundColor: call.avatarColor
                                      .withValues(alpha: 0.2),
                                  child: Text(
                                    call.name.substring(0, 1),
                                    style: context.h3.copyWith(
                                      color: call.avatarColor,
                                    ),
                                  ),
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
                                        Icons.check,
                                        size: 14,
                                        color: context.colors.textLight,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            CommonSpaces.w16,

                            // Name and Call status/time
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    call.count > 1
                                        ? '${call.name} (${call.count})'
                                        : call.name,
                                    style: TextStyle(
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
                                            ? Icons.call_received
                                            : Icons.call_made,
                                        size: 16,
                                        color: call.isMissed
                                            ? context.colors.error
                                            : (call.isIncoming
                                                ? context.colors.success
                                                : context.colors.primary),
                                      ),
                                      CommonSpaces.w4,
                                      Text(
                                        call.time,
                                        style: TextStyle(
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

                            // Audio/Video Icon
                            IconButton(
                              icon: Icon(
                                call.isVideoCall
                                    ? Icons.videocam_rounded
                                    : Icons.call_rounded,
                                color: context.colors.primary,
                              ),
                              onPressed: () {
                                // Initiate call directly
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildHeader(bool isSelectionMode) {
    if (isSelectionMode) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            IconButton(
              icon: Icon(Icons.close, color: context.colors.textPrimary),
              onPressed: _clearSelection,
            ),
            CommonSpaces.w8,
            Text(
              '${_selectedIds.length}',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: context.colors.textPrimary,
              ),
            ),
            const Spacer(),
            IconButton(
              icon: Icon(Icons.delete, color: context.colors.textPrimary),
              onPressed: _deleteSelected,
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
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
              color: context.colors.textPrimary,
            ),
          ),
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: context.colors.lightBackground,
            ),
            child: IconButton(
              icon: Icon(Icons.more_horiz, color: context.colors.textPrimary),
              onPressed: () {
                // Future: show menu like "Clear call log"
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.call_end,
            size: 64,
            color: context.colors.textHint.withValues(alpha: 0.5),
          ),
          CommonSpaces.h16,
          Text(
            'No call history',
            style: context.titleMedium.copyWith(
              color: context.colors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
