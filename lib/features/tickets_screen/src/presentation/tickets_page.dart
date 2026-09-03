import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:schat/features/tickets_screen/src/domain/models/ticket_model.dart';
import 'package:schat/features/tickets_screen/src/presentation/bloc/tickets_bloc.dart';
import 'package:schat/features/tickets_screen/src/presentation/bloc/tickets_event.dart';
import 'package:schat/features/tickets_screen/src/presentation/bloc/tickets_state.dart';
import 'package:schat/utils/common_colors.dart';
import 'package:schat/utils/common_fontstyles.dart';
import 'package:schat/utils/common_icons.dart';
import 'package:schat/utils/common_spaces.dart';
import 'package:schat/utils/common_notifications.dart';
import 'package:schat/injection.dart';

class TicketsPage extends StatefulWidget {
  const TicketsPage({super.key});

  @override
  State<TicketsPage> createState() => _TicketsPageState();
}

class _TicketsPageState extends State<TicketsPage> {
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    context.read<TicketsBloc>().add(const LoadTicketsEvent());
  }

  void _showRaiseTicketBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) {
        File? localAttachment;
        final nameController = TextEditingController();
        final descController = TextEditingController();
        
        return StatefulBuilder(
          builder: (context, setSheetState) {
            Future<void> pickFile() async {
              try {
                final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
                if (pickedFile != null) {
                  setSheetState(() {
                    localAttachment = File(pickedFile.path);
                  });
                }
              } catch (e) {
                debugPrint('Error picking image: $e');
              }
            }

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(bottomSheetContext).viewInsets.bottom,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: context.colors.scaffoldBackground,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Raise Support Ticket', style: context.titleLarge),
                    CommonSpaces.h16,
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: 'Ticket Name / Subject',
                        labelStyle: TextStyle(color: context.colors.textSecondary),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    CommonSpaces.h16,
                    TextField(
                      controller: descController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        labelText: 'Description',
                        labelStyle: TextStyle(color: context.colors.textSecondary),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    CommonSpaces.h16,
                    GestureDetector(
                      onTap: pickFile,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: context.colors.textSecondary.withValues(alpha: 0.3)),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(CommonIcons.attach, color: context.colors.primary),
                            CommonSpaces.w12,
                            Expanded(
                              child: Text(
                                localAttachment != null
                                    ? localAttachment!.path.split('/').last
                                    : 'Add Attachment (Image)',
                                overflow: TextOverflow.ellipsis,
                                style: context.bodyMedium.copyWith(
                                  color: localAttachment != null ? context.colors.textPrimary : context.colors.textHint,
                                ),
                              ),
                            ),
                            if (localAttachment != null) ...[
                              Icon(Icons.check_circle, color: context.colors.success, size: 20),
                              CommonSpaces.w8,
                              GestureDetector(
                                onTap: () {
                                  setSheetState(() {
                                    localAttachment = null;
                                  });
                                },
                                child: Icon(Icons.cancel, color: context.colors.error, size: 20),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    CommonSpaces.h24,
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () {
                          final title = nameController.text.trim();
                          final desc = descController.text.trim();

                          if (title.isEmpty || desc.isEmpty) {
                            context.showErrorNotification('Please fill in all fields');
                            return;
                          }

                          this.context.read<TicketsBloc>().add(CreateTicketEvent(
                            title: title,
                            description: desc,
                            attachmentPath: localAttachment?.path,
                          ));

                          Navigator.pop(bottomSheetContext);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: context.colors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Submit Ticket', style: TextStyle(color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<TicketsBloc, TicketsState>(
      listener: (context, state) {
        if (state is TicketCreateSuccess) {
          context.showSuccessNotification('Ticket raised successfully');
        } else if (state is TicketCreateError) {
          context.showErrorNotification(state.errorMessage);
        } else if (state is TicketsError) {
          context.showErrorNotification(state.errorMessage);
        }
      },
      child: Scaffold(
        backgroundColor: context.colors.scaffoldBackground,
        appBar: AppBar(
          title: const Text('Support Tickets'),
          backgroundColor: context.colors.scaffoldBackground,
          elevation: 0,
          foregroundColor: context.colors.textPrimary,
          leading: IconButton(
            icon: Icon(CommonIcons.arrowBack),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: RefreshIndicator(
          onRefresh: () async {
            context.read<TicketsBloc>().add(const LoadTicketsEvent());
          },
          child: BlocBuilder<TicketsBloc, TicketsState>(
            buildWhen: (previous, current) => 
                current is TicketsInitial || 
                current is TicketsLoading || 
                current is TicketsLoaded,
            builder: (context, state) {
              if (state is TicketsInitial || state is TicketsLoading) {
                return const Center(child: CircularProgressIndicator());
              } else if (state is TicketsLoaded) {
                if (state.tickets.isEmpty) {
                  return SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Container(
                      height: MediaQuery.of(context).size.height * 0.7,
                      alignment: Alignment.center,
                      child: _buildEmptyState(),
                    ),
                  );
                }
                return _buildTicketsList(state.tickets);
              }
              // Should not happen due to buildWhen, but fallback just in case
              return const SizedBox.shrink();
            },
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _showRaiseTicketBottomSheet(context),
          backgroundColor: context.colors.primary,
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text('Raise Ticket', style: TextStyle(color: Colors.white)),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.support_agent_rounded,
            size: 64,
            color: context.colors.textSecondary.withValues(alpha: 0.5),
          ),
          CommonSpaces.h16,
          Text(
            'No support tickets',
            style: context.titleMedium.copyWith(
              color: context.colors.textSecondary,
              fontWeight: FontWeight.bold,
            ),
          ),
          CommonSpaces.h8,
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Have an issue? Raise a new support ticket and our customer support team will help you.',
              textAlign: TextAlign.center,
              style: context.bodyMedium.copyWith(
                color: context.colors.textHint,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTicketsList(List<TicketModel> tickets) {
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: tickets.length,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
      itemBuilder: (context, index) {
        final ticket = tickets[index];

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: context.colors.textSecondary.withValues(alpha: 0.15)),
          ),
          color: context.colors.scaffoldBackground,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        ticket.title,
                        style: context.bodyMedium.copyWith(
                          fontWeight: FontWeight.bold,
                          color: context.colors.textPrimary,
                        ),
                      ),
                    ),
                    _buildStatusBadge(ticket.status),
                  ],
                ),
                CommonSpaces.h8,
                Text(
                  ticket.description,
                  style: context.bodyMedium.copyWith(
                    color: context.colors.textSecondary,
                  ),
                ),
                if (ticket.attachmentPath != null) ...[
                  CommonSpaces.h12,
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: context.colors.lightBackground,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.attachment, size: 14, color: context.colors.primary),
                        CommonSpaces.w6,
                        Text(
                          ticket.attachmentPath!.split('/').last,
                          style: context.bodySmall.copyWith(
                            color: context.colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                CommonSpaces.h12,
                Text(
                  'Created on: ${_formatDate(ticket.createdAtInt)}',
                  style: context.bodySmall.copyWith(
                    color: context.colors.textHint,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bgColor;
    Color textColor;

    switch (status) {
      case 'Open':
        bgColor = context.colors.success.withValues(alpha: 0.15);
        textColor = context.colors.success;
        break;
      case 'In Progress':
        bgColor = Colors.orange.withValues(alpha: 0.15);
        textColor = Colors.orange;
        break;
      case 'Resolved':
      default:
        bgColor = context.colors.textHint.withValues(alpha: 0.15);
        textColor = context.colors.textSecondary;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: textColor,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String _formatDate(int? timestamp) {
    if (timestamp == null) return 'Unknown';
    try {
      final dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
      return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return 'Unknown';
    }
  }
}
