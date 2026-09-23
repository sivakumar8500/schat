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
import 'package:schat/injection.dart';
import 'package:schat/utils/common_colors.dart';
import 'package:schat/utils/common_fontstyles.dart';
import 'package:schat/utils/common_icons.dart';
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
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ChatTransferBloc, ChatTransferState>(
      listener: (context, state) {
        if (state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: context.colors.error,
            ),
          );
          context.read<ChatTransferBloc>().add(const ClearTransferMessages());
        }

        if (state.successMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.successMessage!),
              backgroundColor: context.colors.success,
            ),
          );
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
          appBar: AppBar(
            backgroundColor: context.colors.scaffoldBackground,
            elevation: 0,
            title: Text(
              'Chat Access & Monitoring',
              style: CommonFontStyles.titleMedium(context),
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.refresh, color: context.colors.primary),
                tooltip: 'Refresh',
                onPressed: () {
                  context.read<ChatTransferBloc>().add(const LoadChatTransferData());
                },
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: context.colors.primary,
              labelColor: context.colors.primary,
              unselectedLabelColor: context.colors.textSecondary,
              labelStyle: CommonFontStyles.buttonText(context).copyWith(fontSize: 13),
              tabs: [
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Monitored'),
                      if (state.activeMonitoredAccounts.isNotEmpty) ...[
                        CommonSpaces.w4,
                        _buildBadge(context, state.activeMonitoredAccounts.length),
                      ],
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('My Viewers'),
                      if (state.activeViewers.isNotEmpty) ...[
                        CommonSpaces.w4,
                        _buildBadge(context, state.activeViewers.length),
                      ],
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Requests'),
                      if (pendingCount > 0) ...[
                        CommonSpaces.w4,
                        _buildBadge(context, pendingCount, isAlert: true),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => SendViewRequestSheet.show(context),
            backgroundColor: context.colors.primary,
            foregroundColor: Colors.white,
            icon: const Icon(Icons.person_add_alt_1),
            label: const Text('Request Access'),
          ),
          body: state.status == ChatTransferStatus.loading && state.requests.isEmpty
              ? Center(child: CircularProgressIndicator(color: context.colors.primary))
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildMonitoredAccountsTab(context, state),
                    _buildMyViewersTab(context, state),
                    _buildRequestsTab(context, state),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildBadge(BuildContext context, int count, {bool isAlert = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isAlert ? context.colors.error : context.colors.primary,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$count',
        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildMonitoredAccountsTab(BuildContext context, ChatTransferState state) {
    final activeList = state.activeMonitoredAccounts;
    if (activeList.isEmpty) {
      return _buildEmptyState(
        context,
        icon: Icons.supervisor_account_outlined,
        title: 'No Monitored Accounts',
        subtitle: 'Send a request to a user (e.g. child or supervisee) to view and monitor their chat conversations.',
        buttonLabel: 'Request Chat Access',
        onButtonPressed: () => SendViewRequestSheet.show(context),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 12),
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
        icon: Icons.shield_outlined,
        title: 'No Active Viewers',
        subtitle: 'No one currently has permission to view or monitor your chat history.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 12),
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
        icon: Icons.mark_email_unread_outlined,
        title: 'No Pending Requests',
        subtitle: 'All chat access requests have been handled.',
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 12),
      children: [
        if (incoming.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'INCOMING REQUESTS (${incoming.length})',
              style: CommonFontStyles.caption(context).copyWith(
                color: context.colors.primary,
                fontWeight: FontWeight.bold,
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'OUTGOING REQUESTS (${outgoing.length})',
              style: CommonFontStyles.caption(context).copyWith(
                color: context.colors.textSecondary,
                fontWeight: FontWeight.bold,
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
            Icon(icon, size: 56, color: context.colors.grey),
            CommonSpaces.h16,
            Text(title, style: CommonFontStyles.titleMedium(context), textAlign: TextAlign.center),
            CommonSpaces.h8,
            Text(
              subtitle,
              style: CommonFontStyles.bodyMedium(context).copyWith(color: context.colors.textSecondary),
              textAlign: TextAlign.center,
            ),
            if (buttonLabel != null && onButtonPressed != null) ...[
              CommonSpaces.h20,
              ElevatedButton.icon(
                onPressed: onButtonPressed,
                icon: const Icon(Icons.add, color: Colors.white),
                label: Text(buttonLabel, style: const TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.colors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
        backgroundColor: context.colors.scaffoldBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Revoke Chat Access', style: CommonFontStyles.titleSmall(context)),
        content: Text(
          'Are you sure you want to revoke this access? The user will immediately lose the ability to view these conversations.',
          style: CommonFontStyles.bodyMedium(context),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogCtx);
              context.read<ChatTransferBloc>().add(RevokeChatTransferRequest(requestId));
            },
            style: ElevatedButton.styleFrom(backgroundColor: context.colors.error),
            child: const Text('Revoke', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
