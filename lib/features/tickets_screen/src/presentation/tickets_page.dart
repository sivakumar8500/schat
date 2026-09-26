import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:schat/features/dashboard_screen/src/presentation/dashboard_page.dart';
import 'package:schat/features/tickets_screen/src/domain/models/ticket_model.dart';
import 'package:schat/features/tickets_screen/src/presentation/bloc/tickets_bloc.dart';
import 'package:schat/features/tickets_screen/src/presentation/bloc/tickets_event.dart';
import 'package:schat/features/tickets_screen/src/presentation/bloc/tickets_state.dart';
import 'package:schat/utils/common_colors.dart';
import 'package:schat/utils/common_icons.dart';
import 'package:schat/utils/common_notifications.dart';

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
    final isDark = context.colors.isDark;
    final primaryColor = isDark ? const Color(0xFF00FF87) : const Color(0xFF00873C);

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
                  color: isDark ? context.colors.cardBackground : Colors.white,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 20,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 44,
                        height: 4,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white24 : Colors.black12,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Raise Support Ticket',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: context.colors.textPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: nameController,
                      style: TextStyle(color: context.colors.textPrimary, fontSize: 16),
                      decoration: InputDecoration(
                        labelText: 'Ticket Subject',
                        labelStyle: TextStyle(
                          color: isDark ? Colors.white60 : const Color(0xFF6B7280),
                          fontSize: 16,
                        ),
                        filled: true,
                        fillColor: isDark
                            ? Colors.white.withValues(alpha: 0.05)
                            : const Color(0xFFF9FAFB),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                            color: context.colors.border.withValues(alpha: 0.3),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                            color: context.colors.border.withValues(alpha: 0.3),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: primaryColor, width: 1.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: descController,
                      maxLines: 4,
                      style: TextStyle(color: context.colors.textPrimary, fontSize: 16),
                      decoration: InputDecoration(
                        labelText: 'Description',
                        labelStyle: TextStyle(
                          color: isDark ? Colors.white60 : const Color(0xFF6B7280),
                          fontSize: 16,
                        ),
                        filled: true,
                        fillColor: isDark
                            ? Colors.white.withValues(alpha: 0.05)
                            : const Color(0xFFF9FAFB),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                            color: context.colors.border.withValues(alpha: 0.3),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                            color: context.colors.border.withValues(alpha: 0.3),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: primaryColor, width: 1.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    GestureDetector(
                      onTap: pickFile,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.04)
                              : const Color(0xFFF9FAFB),
                          border: Border.all(
                            color: context.colors.border.withValues(alpha: 0.3),
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            Icon(CommonIcons.attach, color: primaryColor, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                localAttachment != null
                                    ? localAttachment!.path.split('/').last
                                    : 'Add Attachment (Optional Image)',
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: localAttachment != null
                                      ? context.colors.textPrimary
                                      : (isDark ? Colors.white54 : const Color(0xFF9CA3AF)),
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            if (localAttachment != null) ...[
                              Icon(Icons.check_circle_rounded, color: primaryColor, size: 20),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () {
                                  setSheetState(() {
                                    localAttachment = null;
                                  });
                                },
                                child: Icon(Icons.cancel_rounded,
                                    color: context.colors.error, size: 20),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () {
                          final title = nameController.text.trim();
                          final desc = descController.text.trim();

                          if (title.isEmpty || desc.isEmpty) {
                            context.showErrorNotification('Please fill in subject and description');
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
                          backgroundColor: primaryColor,
                          foregroundColor: isDark ? Colors.black : Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          'Submit Ticket',
                          style: TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.black : Colors.white,
                          ),
                        ),
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
    final isDark = context.colors.isDark;
    final primaryColor = isDark ? const Color(0xFF00FF87) : const Color(0xFF00873C);

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
        body: Stack(
          children: [
            // 1. Full screen wave background
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: HomeBackgroundWavePainter(isDark: isDark),
                ),
              ),
            ),

            // 2. Main Content in SafeArea
            SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(primaryColor),
                  Expanded(
                    child: RefreshIndicator(
                      color: primaryColor,
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
                            return Center(
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                              ),
                            );
                          } else if (state is TicketsLoaded) {
                            if (state.tickets.isEmpty) {
                              return SingleChildScrollView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                child: Container(
                                  height: MediaQuery.of(context).size.height * 0.7,
                                  alignment: Alignment.center,
                                  child: _buildEmptyState(primaryColor),
                                ),
                              );
                            }
                            return _buildTicketsList(state.tickets);
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _showRaiseTicketBottomSheet(context),
          backgroundColor: primaryColor,
          elevation: 3,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          icon: Icon(Icons.add_rounded, color: isDark ? Colors.black : Colors.white),
          label: Text(
            'Raise Ticket',
            style: TextStyle(
              color: isDark ? Colors.black : Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(Color primaryColor) {
    final isDark = context.colors.isDark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 20, 10),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: context.colors.textPrimary,
              size: 20,
            ),
            padding: const EdgeInsets.all(8),
            constraints: const BoxConstraints(),
            style: IconButton.styleFrom(
              backgroundColor: isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : const Color(0xFFEFF4F1),
              shape: const CircleBorder(),
            ),
          ),
          const SizedBox(width: 14),
          Text(
            'Support Tickets',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: context.colors.textPrimary,
              letterSpacing: -0.4,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: context.colors.textPrimary, size: 22),
            tooltip: 'Refresh',
            onPressed: () {
              context.read<TicketsBloc>().add(const LoadTicketsEvent());
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(Color primaryColor) {
    final isDark = context.colors.isDark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF00FF87).withValues(alpha: 0.12)
                    : const Color(0xFFD1FADF),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(
                  Icons.support_agent_rounded,
                  size: 42,
                  color: primaryColor,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Support Tickets',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: context.colors.textPrimary,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Have an issue or inquiry? Raise a new support ticket and our team will get right back to you.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                height: 1.45,
                color: isDark ? Colors.white60 : const Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTicketsList(List<TicketModel> tickets) {
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: tickets.length,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
      itemBuilder: (context, index) {
        final ticket = tickets[index];
        final isDark = context.colors.isDark;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: isDark ? context.colors.cardBackground : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: context.colors.border.withValues(alpha: 0.35),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
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
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: context.colors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildStatusBadge(ticket.status),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  ticket.description,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    color: isDark ? Colors.white70 : const Color(0xFF4B5563),
                  ),
                ),
                if (ticket.attachmentPath != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.06)
                          : const Color(0xFFEFF4F1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.attachment_rounded, size: 15, color: const Color(0xFF00873C)),
                        const SizedBox(width: 6),
                        Text(
                          ticket.attachmentPath!.split('/').last,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white70 : const Color(0xFF374151),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.access_time_rounded,
                      size: 13,
                      color: isDark ? Colors.white38 : const Color(0xFF9CA3AF),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Created ${_formatDate(ticket.createdAtInt)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white38 : const Color(0xFF9CA3AF),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusBadge(String status) {
    final lower = status.toLowerCase();
    Color bgColor;
    Color textColor;

    if (lower == 'open' || lower == 'pending') {
      bgColor = const Color(0xFFD1FADF);
      textColor = const Color(0xFF027A48);
    } else if (lower == 'in progress' || lower == 'in_progress') {
      bgColor = const Color(0xFFFEF0C7);
      textColor = const Color(0xFFB54708);
    } else if (lower == 'complete' || lower == 'completed' || lower == 'resolved') {
      bgColor = const Color(0xFFE0EAFF);
      textColor = const Color(0xFF3538CD);
    } else {
      bgColor = const Color(0xFFFEE4E2);
      textColor = const Color(0xFFD92D20);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: textColor,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.4,
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
