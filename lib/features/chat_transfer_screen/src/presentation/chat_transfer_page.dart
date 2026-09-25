import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:schat/features/chat_transfer_screen/src/domain/models/chat_view_user_model.dart';
import 'package:schat/features/chat_transfer_screen/src/presentation/bloc/chat_transfer_bloc.dart';
import 'package:schat/features/chat_transfer_screen/src/presentation/bloc/chat_transfer_event.dart';
import 'package:schat/features/chat_transfer_screen/src/presentation/bloc/chat_transfer_state.dart';
import 'package:schat/features/chat_transfer_screen/src/presentation/pages/target_conversations_page.dart';
import 'package:schat/features/chat_transfer_screen/src/presentation/widgets/chat_view_request_card.dart';
import 'package:schat/features/chat_transfer_screen/src/presentation/widgets/chat_view_request_dialog.dart';
import 'package:schat/features/chat_transfer_screen/src/presentation/widgets/send_view_request_sheet.dart';
import 'package:schat/features/dashboard_screen/src/presentation/dashboard_page.dart';
import 'package:schat/injection.dart';
import 'package:schat/utils/common_colors.dart';
import 'package:schat/utils/common_fontstyles.dart';
import 'package:schat/utils/common_notifications.dart';
import 'package:schat/utils/common_spaces.dart';

class ChatTransferPage extends StatelessWidget {
  const ChatTransferPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ChatTransferBloc>()..add(const LoadChatTransferData()),
      child: const _ChatTransferView(),
    );
  }
}

class _ChatTransferView extends StatefulWidget {
  const _ChatTransferView();

  @override
  State<_ChatTransferView> createState() => _ChatTransferViewState();
}

class _ChatTransferViewState extends State<_ChatTransferView> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.colors.isDark;

    return BlocConsumer<ChatTransferBloc, ChatTransferState>(
      listener: (context, state) {
        if (state.errorMessage != null) {
          context.showErrorNotification(state.errorMessage!);
          context.read<ChatTransferBloc>().add(const ClearTransferMessages());
        }

        if (state.successMessage != null) {
          context.showSuccessNotification(state.successMessage!);
          context.read<ChatTransferBloc>().add(const ClearTransferMessages());
        }

        if (state.newlyReceivedRequest != null) {
          final req = state.newlyReceivedRequest!;
          ChatViewRequestDialog.show(
            context,
            request: req,
            onAccept: () {
              context.read<ChatTransferBloc>().add(
                    RespondChatTransferRequest(requestId: req.id, accept: true),
                  );
            },
            onDecline: () {
              context.read<ChatTransferBloc>().add(
                    RespondChatTransferRequest(requestId: req.id, accept: false),
                  );
            },
          );
        }
      },
      builder: (context, state) {
        final pendingCount = state.incomingPendingRequests.length + state.outgoingPendingRequests.length;

        return Scaffold(
          backgroundColor: context.colors.scaffoldBackground,
          body: Stack(
            children: [
              // Wave background matching Home Screen
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: HomeBackgroundWavePainter(isDark: isDark),
                  ),
                ),
              ),

              // Content
              SafeArea(
                child: Column(
                  children: [
                    _buildHeader(context),
                    _buildSegmentedTabs(state, pendingCount),
                    Expanded(
                      child: state.status == ChatTransferStatus.loading && state.requests.isEmpty
                          ? const Center(child: CircularProgressIndicator(color: Color(0xFF00873C)))
                          : TabBarView(
                              controller: _tabController,
                              children: [
                                _buildMonitoredAccountsTab(context, state),
                                _buildMyViewersTab(context, state),
                                _buildRequestsTab(context, state),
                              ],
                            ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            heroTag: 'chat_access_fab',
            onPressed: () => SendViewRequestSheet.show(context),
            backgroundColor: const Color(0xFF00873C),
            foregroundColor: Colors.white,
            elevation: 4,
            icon: const Icon(Icons.person_add_alt_1_rounded, size: 20),
            label: const Text('Request Access', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
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
              'Chat Access & Monitoring',
              style: context.h2.copyWith(
                fontWeight: FontWeight.bold,
                color: context.colors.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFE8F5E9),
            ),
            child: IconButton(
              padding: EdgeInsets.zero,
              icon: const Icon(Icons.refresh_rounded, color: Color(0xFF00873C), size: 20),
              tooltip: 'Refresh',
              onPressed: () {
                context.read<ChatTransferBloc>().add(const LoadChatTransferData());
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentedTabs(ChatTransferState state, int pendingCount) {
    final tabs = [
      ('Monitored', state.activeMonitoredAccounts.length, false),
      ('My Viewers', state.activeViewers.length, false),
      ('Requests', pendingCount, true),
    ];

    return Container(
      height: 44,
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 10),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: context.colors.cardBackground.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: context.colors.border.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        children: List.generate(tabs.length, (index) {
          final (label, count, isAlert) = tabs[index];
          final isSelected = _tabController.index == index;

          return Expanded(
            child: GestureDetector(
              onTap: () {
                _tabController.animateTo(index);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF00873C) : Colors.transparent,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: const Color(0xFF00873C).withValues(alpha: 0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected ? Colors.white : context.colors.textSecondary,
                        ),
                      ),
                      if (count > 0) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.white.withValues(alpha: 0.25)
                                : (isAlert ? const Color(0xFFE53935) : const Color(0xFF00873C)),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '$count',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildMonitoredAccountsTab(BuildContext context, ChatTransferState state) {
    final activeList = state.activeMonitoredAccounts;
    if (activeList.isEmpty) {
      return _buildEmptyState(
        context,
        icon: Icons.supervisor_account_rounded,
        title: 'No Monitored Accounts',
        subtitle: 'Send a request to a user (e.g. child or supervisee) to view and monitor their chat conversations.',
        buttonLabel: 'Request Chat Access',
        onButtonPressed: () => SendViewRequestSheet.show(context),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(0, 4, 0, 100),
      itemCount: activeList.length,
      itemBuilder: (context, index) {
        final req = activeList[index];
        return ChatViewRequestCard(
          request: req,
          type: RequestCardType.activeMonitored,
          onRevoke: () => _confirmRevoke(context, req.id),
          onTap: () {
            final targetUser = req.receiver ?? ChatViewUserModel(id: req.receiverId);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => BlocProvider.value(
                  value: context.read<ChatTransferBloc>(),
                  child: TargetConversationsPage(targetUser: targetUser),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMyViewersTab(BuildContext context, ChatTransferState state) {
    final viewers = state.activeViewers;
    if (viewers.isEmpty) {
      return _buildEmptyState(
        context,
        icon: Icons.shield_rounded,
        title: 'No Active Viewers',
        subtitle: 'No one currently has permission to view or monitor your chat history.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(0, 4, 0, 100),
      itemCount: viewers.length,
      itemBuilder: (context, index) {
        final req = viewers[index];
        return ChatViewRequestCard(
          request: req,
          type: RequestCardType.activeViewer,
          onRevoke: () => _confirmRevoke(context, req.id),
        );
      },
    );
  }

  Widget _buildRequestsTab(BuildContext context, ChatTransferState state) {
    final incoming = state.incomingPendingRequests;
    final outgoing = state.outgoingPendingRequests;

    if (incoming.isEmpty && outgoing.isEmpty) {
      return _buildEmptyState(
        context,
        icon: Icons.mark_email_read_rounded,
        title: 'No Pending Requests',
        subtitle: 'All chat access requests have been handled.',
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(0, 4, 0, 100),
      children: [
        if (incoming.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Text(
              'INCOMING REQUESTS',
              style: TextStyle(
                color: Color(0xFF00873C),
                fontWeight: FontWeight.bold,
                fontSize: 12,
                letterSpacing: 0.5,
              ),
            ),
          ),
          ...incoming.map((req) => ChatViewRequestCard(
                request: req,
                type: RequestCardType.incomingPending,
                onAccept: () {
                  context.read<ChatTransferBloc>().add(
                        RespondChatTransferRequest(requestId: req.id, accept: true),
                      );
                },
                onReject: () {
                  context.read<ChatTransferBloc>().add(
                        RespondChatTransferRequest(requestId: req.id, accept: false),
                      );
                },
              )),
          CommonSpaces.h16,
        ],
        if (outgoing.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Text(
              'OUTGOING REQUESTS',
              style: TextStyle(
                color: context.colors.textSecondary,
                fontWeight: FontWeight.bold,
                fontSize: 12,
                letterSpacing: 0.5,
              ),
            ),
          ),
          ...outgoing.map((req) => ChatViewRequestCard(
                request: req,
                type: RequestCardType.outgoingPending,
                onRevoke: () => _confirmRevoke(context, req.id),
              )),
        ],
      ],
    );
  }

  Widget _buildEmptyState(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    String? buttonLabel,
    VoidCallback? onButtonPressed,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: Color(0xFFE8F5E9),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 40, color: const Color(0xFF00873C)),
            ),
            CommonSpaces.h20,
            Text(title, style: context.titleLarge.copyWith(fontWeight: FontWeight.bold), textAlign: TextAlign.center),
            CommonSpaces.h8,
            Text(
              subtitle,
              style: TextStyle(color: context.colors.textSecondary, fontSize: 14, height: 1.4),
              textAlign: TextAlign.center,
            ),
            if (buttonLabel != null && onButtonPressed != null) ...[
              CommonSpaces.h24,
              ElevatedButton.icon(
                onPressed: onButtonPressed,
                icon: const Icon(Icons.add_rounded, color: Colors.white, size: 20),
                label: Text(buttonLabel, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00873C),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                  elevation: 2,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _confirmRevoke(BuildContext context, String requestId) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: context.colors.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Text(
          'Revoke Chat Access',
          style: context.titleMedium.copyWith(fontWeight: FontWeight.bold, color: context.colors.textPrimary),
        ),
        content: Text(
          'Are you sure you want to revoke this access? The user will immediately lose the ability to view these conversations.',
          style: TextStyle(color: context.colors.textSecondary, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text('Cancel', style: TextStyle(color: context.colors.textHint)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogCtx);
              context.read<ChatTransferBloc>().add(RevokeChatTransferRequest(requestId));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE53935),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Revoke'),
          ),
        ],
      ),
    );
  }
}
