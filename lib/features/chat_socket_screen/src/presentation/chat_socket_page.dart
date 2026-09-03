import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:schat/features/chat_socket_screen/src/domain/chat_socket_repository.dart';
import 'package:schat/features/chat_socket_screen/src/presentation/bloc/chat_socket_bloc.dart';
import 'package:schat/features/chat_socket_screen/src/presentation/bloc/chat_socket_event.dart';
import 'package:schat/features/chat_socket_screen/src/presentation/bloc/chat_socket_state.dart';
import 'package:schat/injection.dart';
import 'package:schat/utils/common_colors.dart';
import 'package:schat/utils/common_fontstyles.dart';
import 'package:schat/utils/common_icons.dart';
import 'package:schat/utils/common_spaces.dart';

class ChatSocketPage extends StatefulWidget {
  const ChatSocketPage({super.key});

  @override
  State<ChatSocketPage> createState() => _ChatSocketPageState();
}

class _ChatSocketPageState extends State<ChatSocketPage> with SingleTickerProviderStateMixin {
  late final ChatSocketRepository _repository;
  StreamSubscription<SocketEventLog>? _logSubscription;
  late final TabController _tabController;

  // Connection State
  bool _isConnected = false;

  // Logs
  final List<SocketEventLog> _logs = [];
  String _filterType = 'all'; // 'all', 'inbound', 'outbound', 'status'

  // Input Controllers
  final _conversationIdController = TextEditingController(text: 'ec925ee1-4687-481a-9b92-ab74006c0a18');
  final _textController = TextEditingController(text: 'Hello from WebSocket Tester!');
  final _messageIdController = TextEditingController();
  final _latitudeController = TextEditingController(text: '37.4275');
  final _longitudeController = TextEditingController(text: '-122.1697');
  final _addressController = TextEditingController(text: 'Stanford, CA');
  final _contactNameController = TextEditingController(text: 'John Doe');
  final _phoneNumberController = TextEditingController(text: '+15550199');

  // Form State
  String _messageType = 'text';
  bool _isTyping = false;
  final Set<int> _expandedLogIndexes = {};

  @override
  void initState() {
    super.initState();
    _repository = getIt<ChatSocketRepository>();
    _isConnected = _repository.isConnected;
    _logs.addAll(_repository.eventLogs);
    _tabController = TabController(length: 2, vsync: this);

    _logSubscription = _repository.onEventLog.listen((event) {
      if (mounted) {
        setState(() {
          if (event.direction == 'status' && event.payload['status'] == 'logs_cleared') {
            _logs.clear();
            _expandedLogIndexes.clear();
            return;
          }
          _logs.insert(0, event);
          if (event.direction == 'status') {
            final statusStr = event.payload['status'];
            if (statusStr == 'connected') {
              _isConnected = true;
            } else if (statusStr == 'disconnected' ||
                statusStr == 'disconnected_manually' ||
                statusStr == 'error') {
              _isConnected = false;
            }
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _logSubscription?.cancel();
    _tabController.dispose();
    _conversationIdController.dispose();
    _textController.dispose();
    _messageIdController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _addressController.dispose();
    _contactNameController.dispose();
    _phoneNumberController.dispose();
    super.dispose();
  }

  List<SocketEventLog> get _filteredLogs {
    if (_filterType == 'all') return _logs;
    return _logs.where((log) => log.direction == _filterType).toList();
  }

  void _copyToClipboard(Map<String, dynamic> payload) {
    final jsonStr = const JsonEncoder.withIndent('  ').convert(payload);
    Clipboard.setData(ClipboardData(text: jsonStr));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Payload copied to clipboard'),
        backgroundColor: context.colors.primary,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.scaffoldBackground,
      appBar: AppBar(
        title: const Text('WebSocket Tester'),
        backgroundColor: context.colors.scaffoldBackground,
        foregroundColor: context.colors.textPrimary,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: context.colors.primary,
          unselectedLabelColor: context.colors.textSecondary,
          indicatorColor: context.colors.primary,
          tabs: const [
            Tab(icon: Icon(Icons.settings_input_component), text: 'Actions Panel'),
            Tab(icon: Icon(Icons.list_alt_rounded), text: 'Live Event Logs'),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(CommonIcons.delete, color: context.colors.error),
            tooltip: 'Clear Event Logs',
            onPressed: () {
              _repository.clearLogs();
            },
          ),
        ],
      ),
      body: BlocListener<ChatSocketBloc, ChatSocketState>(
        listener: (context, state) {
          // Additional listener if we want to handle Bloc transitions
        },
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildActionsPanel(),
            _buildLogsPanel(),
          ],
        ),
      ),
    );
  }

  Widget _buildActionsPanel() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildConnectionStatusCard(),
        CommonSpaces.h16,
        _buildConversationIdCard(),
        CommonSpaces.h16,
        _buildEventCategoryCard(
          title: '1. Send Message',
          icon: CommonIcons.chatBubble,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<String>(
                initialValue: _messageType,
                decoration: _inputDecoration('Message Type'),
                dropdownColor: context.colors.lightBackground,
                style: context.bodyLarge,
                items: ['text', 'image', 'video', 'file', 'call']
                    .map((type) => DropdownMenuItem(
                          value: type,
                          child: Text(type.toUpperCase()),
                        ))
                    .toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _messageType = val;
                    });
                  }
                },
              ),
              CommonSpaces.h12,
              TextField(
                controller: _textController,
                decoration: _inputDecoration('Text Content / Caption'),
                style: context.bodyLarge,
              ),
              CommonSpaces.h12,
              ElevatedButton.icon(
                onPressed: () {
                  context.read<ChatSocketBloc>().add(SendMessage(
                        conversationId: _conversationIdController.text.trim(),
                        type: _messageType,
                        text: _textController.text.trim(),
                      ));
                  _tabController.animateTo(1);
                },
                style: _buttonStyle(context.colors.primary),
                icon: Icon(CommonIcons.send, color: context.colors.pureWhite),
                label: const Text('Send Message Payload', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
        CommonSpaces.h16,
        _buildEventCategoryCard(
          title: '2. Typing Indicator',
          icon: Icons.keyboard_rounded,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Toggle Typing Status:', style: context.bodyLarge),
              Switch(
                value: _isTyping,
                activeThumbColor: context.colors.primary,
                onChanged: (val) {
                  setState(() {
                    _isTyping = val;
                  });
                  context.read<ChatSocketBloc>().add(SendTypingIndicator(
                        _conversationIdController.text.trim(),
                        isTyping: _isTyping,
                      ));
                },
              ),
            ],
          ),
        ),
        CommonSpaces.h16,
        _buildEventCategoryCard(
          title: '3. Read Receipt',
          icon: CommonIcons.doneAll,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _messageIdController,
                decoration: _inputDecoration('Message UUID'),
                style: context.bodyLarge,
              ),
              CommonSpaces.h12,
              ElevatedButton.icon(
                onPressed: () {
                  final msgId = _messageIdController.text.trim();
                  if (msgId.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please enter a message UUID')),
                    );
                    return;
                  }
                  context.read<ChatSocketBloc>().add(SendReadReceipt(
                        conversationId: _conversationIdController.text.trim(),
                        messageId: msgId,
                      ));
                  _tabController.animateTo(1);
                },
                style: _buttonStyle(context.colors.blue),
                icon: Icon(CommonIcons.doneAll, color: context.colors.pureWhite),
                label: const Text('Send Read Receipt', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
        CommonSpaces.h16,
        _buildEventCategoryCard(
          title: '4. Location Message',
          icon: CommonIcons.location,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _latitudeController,
                      decoration: _inputDecoration('Latitude'),
                      style: context.bodyLarge,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                  ),
                  CommonSpaces.w12,
                  Expanded(
                    child: TextField(
                      controller: _longitudeController,
                      decoration: _inputDecoration('Longitude'),
                      style: context.bodyLarge,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                  ),
                ],
              ),
              CommonSpaces.h12,
              TextField(
                controller: _addressController,
                decoration: _inputDecoration('Address (Optional)'),
                style: context.bodyLarge,
              ),
              CommonSpaces.h12,
              ElevatedButton.icon(
                onPressed: () {
                  context.read<ChatSocketBloc>().add(SendLocationMessage(
                        conversationId: _conversationIdController.text.trim(),
                        latitude: double.tryParse(_latitudeController.text) ?? 0.0,
                        longitude: double.tryParse(_longitudeController.text) ?? 0.0,
                        address: _addressController.text.trim(),
                      ));
                  _tabController.animateTo(1);
                },
                style: _buttonStyle(context.colors.orange),
                icon: Icon(CommonIcons.location, color: context.colors.pureWhite),
                label: const Text('Send Location Payload', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
        CommonSpaces.h16,
        _buildEventCategoryCard(
          title: '5. Contact Message',
          icon: CommonIcons.person,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _contactNameController,
                decoration: _inputDecoration('Contact Name'),
                style: context.bodyLarge,
              ),
              CommonSpaces.h12,
              TextField(
                controller: _phoneNumberController,
                decoration: _inputDecoration('Phone Number'),
                style: context.bodyLarge,
                keyboardType: TextInputType.phone,
              ),
              CommonSpaces.h12,
              ElevatedButton.icon(
                onPressed: () {
                  context.read<ChatSocketBloc>().add(SendContactMessage(
                        conversationId: _conversationIdController.text.trim(),
                        contactName: _contactNameController.text.trim(),
                        phoneNumber: _phoneNumberController.text.trim(),
                      ));
                  _tabController.animateTo(1);
                },
                style: _buttonStyle(context.colors.purple),
                icon: Icon(CommonIcons.person, color: context.colors.pureWhite),
                label: const Text('Send Contact Payload', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
        CommonSpaces.h16,
        _buildEventCategoryCard(
          title: '6. Connection Heartbeat',
          icon: Icons.favorite_rounded,
          child: ElevatedButton.icon(
            onPressed: () {
              _repository.sendPing();
              _tabController.animateTo(1);
            },
            style: _buttonStyle(context.colors.error),
            icon: Icon(Icons.favorite_rounded, color: context.colors.pureWhite),
            label: const Text('Send Manual Ping', style: TextStyle(color: Colors.white)),
          ),
        ),
        CommonSpaces.h40,
      ],
    );
  }

  Widget _buildConnectionStatusCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: context.colors.lightBackground,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isConnected ? context.colors.success : context.colors.error,
                  ),
                ),
                CommonSpaces.w12,
                Text(
                  _isConnected ? 'Connected ✅' : 'Disconnected ❌',
                  style: context.titleMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    color: _isConnected ? context.colors.success : context.colors.error,
                  ),
                ),
              ],
            ),
            CommonSpaces.h12,
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isConnected
                        ? null
                        : () {
                            context.read<ChatSocketBloc>().add(const ConnectSocket());
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.colors.primary,
                      disabledBackgroundColor: context.colors.grey.withValues(alpha: 0.3),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Connect Socket', style: TextStyle(color: Colors.white)),
                  ),
                ),
                CommonSpaces.w12,
                Expanded(
                  child: ElevatedButton(
                    onPressed: !_isConnected
                        ? null
                        : () {
                            context.read<ChatSocketBloc>().add(const DisconnectSocket());
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.colors.error,
                      disabledBackgroundColor: context.colors.grey.withValues(alpha: 0.3),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Disconnect Socket', style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildConversationIdCard() {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: context.colors.lightBackground,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Active Conversation Context', style: context.titleSmall),
            CommonSpaces.h8,
            TextField(
              controller: _conversationIdController,
              decoration: _inputDecoration('Conversation UUID'),
              style: context.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventCategoryCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: context.colors.lightBackground,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: context.colors.primary),
                CommonSpaces.w8,
                Text(title, style: context.titleSmall.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
            CommonSpaces.h12,
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildLogsPanel() {
    final logs = _filteredLogs;
    return Column(
      children: [
        _buildLogFiltersHeader(),
        Expanded(
          child: logs.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.terminal_rounded, size: 64, color: context.colors.textSecondary),
                      CommonSpaces.h16,
                      Text('No events recorded in this session', style: context.bodyLarge),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: logs.length,
                  itemBuilder: (context, index) {
                    final log = logs[index];
                    final isExpanded = _expandedLogIndexes.contains(index);
                    return _buildLogTile(log, index, isExpanded);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildLogFiltersHeader() {
    return Container(
      color: context.colors.lightBackground,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip('all', 'All Logs'),
            CommonSpaces.w8,
            _buildFilterChip('inbound', 'Inbound (Server ➔ Client)'),
            CommonSpaces.w8,
            _buildFilterChip('outbound', 'Outbound (Client ➔ Server)'),
            CommonSpaces.w8,
            _buildFilterChip('status', 'Status Changes'),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String type, String label) {
    final isSelected = _filterType == type;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _filterType = type;
            _expandedLogIndexes.clear();
          });
        }
      },
      selectedColor: context.colors.primary.withValues(alpha: 0.2),
      labelStyle: TextStyle(
        color: isSelected ? context.colors.primary : context.colors.textSecondary,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _buildLogTile(SocketEventLog log, int index, bool isExpanded) {
    final Color borderLeftColor;
    final IconData directionIcon;
    final Color iconColor;
    final String label;

    if (log.direction == 'inbound') {
      borderLeftColor = context.colors.success;
      directionIcon = Icons.arrow_downward_rounded;
      iconColor = context.colors.success;
      label = log.payload['type'] ?? 'inbound';
    } else if (log.direction == 'outbound') {
      borderLeftColor = context.colors.blue;
      directionIcon = Icons.arrow_upward_rounded;
      iconColor = context.colors.blue;
      label = log.payload['type'] ?? 'outbound';
    } else {
      borderLeftColor = context.colors.warning;
      directionIcon = Icons.info_outline_rounded;
      iconColor = context.colors.warning;
      label = log.payload['status'] != null ? 'STATUS: ${log.payload['status'].toString().toUpperCase()}' : 'status';
    }

    final formattedTime = '${log.timestamp.hour.toString().padLeft(2, '0')}:${log.timestamp.minute.toString().padLeft(2, '0')}:${log.timestamp.second.toString().padLeft(2, '0')}.${log.timestamp.millisecond.toString().padLeft(3, '0')}';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Container(
        decoration: BoxDecoration(
          border: Border(left: BorderSide(color: borderLeftColor, width: 4)),
        ),
        child: Column(
          children: [
            ListTile(
              dense: true,
              leading: CircleAvatar(
                radius: 14,
                backgroundColor: iconColor.withValues(alpha: 0.1),
                child: Icon(directionIcon, size: 16, color: iconColor),
              ),
              title: Text(
                label.toUpperCase(),
                style: context.titleSmall.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              subtitle: Text(formattedTime, style: context.caption),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.copy_rounded, size: 18),
                    onPressed: () => _copyToClipboard(log.payload),
                    tooltip: 'Copy Payload',
                  ),
                  Icon(
                    isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    size: 20,
                  ),
                ],
              ),
              onTap: () {
                setState(() {
                  if (isExpanded) {
                    _expandedLogIndexes.remove(index);
                  } else {
                    _expandedLogIndexes.add(index);
                  }
                });
              },
            ),
            if (isExpanded)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                color: context.colors.border.withValues(alpha: 0.05),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: context.colors.border),
                  ),
                  child: SelectableText(
                    const JsonEncoder.withIndent('  ').convert(log.payload),
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: context.colors.textSecondary, fontSize: 13),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: context.colors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: context.colors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: context.colors.primary),
      ),
    );
  }

  ButtonStyle _buttonStyle(Color color) {
    return ElevatedButton.styleFrom(
      backgroundColor: color,
      padding: const EdgeInsets.symmetric(vertical: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}
