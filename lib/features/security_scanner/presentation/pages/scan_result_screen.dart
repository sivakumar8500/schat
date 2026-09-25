import 'package:flutter/material.dart';
import 'package:schat/core/security/security_scanner_service.dart';
import 'package:schat/features/dashboard_screen/src/presentation/dashboard_page.dart';
import 'package:schat/features/security_scanner/domain/entities/scan_report_model.dart';
import 'package:schat/features/security_scanner/presentation/controllers/scan_progress_controller.dart';
import 'package:schat/injection.dart';
import 'package:schat/utils/common_colors.dart';
import 'package:schat/utils/common_notifications.dart';
import 'package:schat/features/security_scanner/presentation/widgets/radar_scan_widget.dart';

class ScanResultScreen extends StatefulWidget {
  const ScanResultScreen({super.key});

  static void navigateTo(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ScanResultScreen()),
    );
  }

  @override
  State<ScanResultScreen> createState() => _ScanResultScreenState();
}

class _ScanResultScreenState extends State<ScanResultScreen> {
  late final ScanProgressController _controller;

  @override
  void initState() {
    super.initState();
    _controller = getIt<ScanProgressController>();
    _controller.startScan();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.colors.isDark;
    final primaryColor = isDark ? const Color(0xFF00FF87) : const Color(0xFF00873C);

    return Scaffold(
      backgroundColor: context.colors.scaffoldBackground,
      body: Stack(
        children: [
          // 1. Full-screen Flowing Wave Background spanning status bar & bottom bar
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: HomeBackgroundWavePainter(isDark: isDark),
              ),
            ),
          ),

          // 2. Main Screen Content in SafeArea
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context, isDark),
                Expanded(
                  child: ValueListenableBuilder<ScanProgressState?>(
                    valueListenable: _controller,
                    builder: (context, state, _) {
                      if (state == null) {
                        return Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                          ),
                        );
                      }

                      if (state.isCompleted && state.report != null) {
                        return _buildReportView(context, state.report!, isDark, primaryColor);
                      }

                      return _buildProgressView(context, state, isDark, primaryColor);
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
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
          Expanded(
            child: Text(
              'Device Security Scan',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: context.colors.textPrimary,
                letterSpacing: -0.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressView(
      BuildContext context, ScanProgressState state, bool isDark, Color primaryColor) {
    final percentageInt = (state.progressPercentage * 100).toInt();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      child: Column(
        children: [
          // Radar Scan Animation Widget
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6.0),
              child: RadarScanWidget(
                size: 150,
                statusText: 'SCANNING IN PROGRESS...',
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Progress Header Card
          Container(
            padding: const EdgeInsets.all(16),
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
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        state.currentTaskTitle,
                        style: TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w700,
                          color: context.colors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF00FF87).withValues(alpha: 0.15)
                            : const Color(0xFFD1FADF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$percentageInt%',
                        style: TextStyle(
                          color: primaryColor,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: state.progressPercentage,
                    backgroundColor: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : const Color(0xFFEFF4F1),
                    valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                    minHeight: 7,
                  ),
                ),
                const SizedBox(height: 16),
                // Counter Metrics Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildMetricItem(context, 'Files Scanned', '${state.filesScanned}', isDark),
                    _buildMetricDivider(isDark),
                    _buildMetricItem(context, 'Links Scanned', '${state.linksScanned}', isDark),
                    _buildMetricDivider(isDark),
                    _buildMetricItem(context, 'Elapsed Time', _formatDuration(state.elapsedTime), isDark),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // 14 Steps Sequential List inside an elevated card
          Expanded(
            child: Container(
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
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  itemCount: state.steps.length,
                  separatorBuilder: (_, _) => Divider(
                    height: 1,
                    color: context.colors.border.withValues(alpha: 0.25),
                  ),
                  itemBuilder: (context, index) {
                    final step = state.steps[index];
                    final isCurrent = index == state.currentStepIndex && !state.isCompleted;

                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                      leading: _buildStepStatusIcon(context, step.status, isCurrent, primaryColor),
                      title: Text(
                        step.title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w600,
                          color: isCurrent ? primaryColor : context.colors.textPrimary,
                        ),
                      ),
                      subtitle: Text(
                        step.description,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white54 : const Color(0xFF6B7280),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),
          // Cancel Button
          if (!state.isCancelled)
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton(
                onPressed: () {
                  _controller.cancelScan();
                  Navigator.pop(context);
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFF04438), width: 1.2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text(
                  'Cancel Scan',
                  style: TextStyle(
                    color: Color(0xFFF04438),
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMetricDivider(bool isDark) {
    return Container(
      width: 1,
      height: 28,
      color: isDark ? Colors.white12 : const Color(0xFFE5E7EB),
    );
  }

  Widget _buildStepStatusIcon(
      BuildContext context, StepStatus status, bool isCurrent, Color primaryColor) {
    if (isCurrent) {
      return SizedBox(
        width: 22,
        height: 22,
        child: CircularProgressIndicator(strokeWidth: 2.5, color: primaryColor),
      );
    }
    switch (status) {
      case StepStatus.success:
        return const Icon(Icons.check_circle_rounded, color: Color(0xFF12B76A), size: 22);
      case StepStatus.warning:
        return const Icon(Icons.warning_amber_rounded, color: Color(0xFFF79009), size: 22);
      case StepStatus.failed:
        return const Icon(Icons.error_outline_rounded, color: Color(0xFFF04438), size: 22);
      case StepStatus.inProgress:
        return SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(strokeWidth: 2.5, color: primaryColor),
        );
      case StepStatus.pending:
      default:
        return Icon(
          Icons.radio_button_unchecked_rounded,
          color: context.colors.textHint.withValues(alpha: 0.35),
          size: 22,
        );
    }
  }

  Widget _buildMetricItem(BuildContext context, String label, String value, bool isDark) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: context.colors.textPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: isDark ? Colors.white54 : const Color(0xFF6B7280),
          ),
        ),
      ],
    );
  }

  Widget _buildReportView(
      BuildContext context, ScanReportModel report, bool isDark, Color primaryColor) {
    final Color scoreColor = report.overallScore >= 90
        ? const Color(0xFF12B76A)
        : (report.overallScore >= 70 ? const Color(0xFFF79009) : const Color(0xFFF04438));

    final String statusTitle = report.overallScore >= 90
        ? 'Device & App Safe'
        : (report.overallScore >= 70 ? 'Security Attention Recommended' : 'Security Threats Found');

    final String formattedDate =
        '${report.scanTimestamp.day}/${report.scanTimestamp.month}/${report.scanTimestamp.year} ${report.scanTimestamp.hour}:${report.scanTimestamp.minute.toString().padLeft(2, '0')}';

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
      children: [
        // Score Card Header
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: isDark ? context.colors.cardBackground : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: scoreColor.withValues(alpha: 0.35),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: scoreColor.withValues(alpha: 0.08),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 96,
                    height: 96,
                    child: CircularProgressIndicator(
                      value: report.overallScore / 100.0,
                      strokeWidth: 9,
                      backgroundColor: scoreColor.withValues(alpha: 0.15),
                      valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${report.overallScore}',
                        style: TextStyle(
                          color: scoreColor,
                          fontWeight: FontWeight.w900,
                          fontSize: 30,
                        ),
                      ),
                      Text(
                        '/ 100',
                        style: TextStyle(
                          color: isDark ? Colors.white54 : const Color(0xFF6B7280),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                statusTitle,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: scoreColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                'Completed in ${_formatDuration(report.scanDuration)} • $formattedDate',
                style: TextStyle(
                  fontSize: 12.5,
                  color: isDark ? Colors.white54 : const Color(0xFF6B7280),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Summary Metrics Grid
        Text(
          'Scan Summary',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: context.colors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 2.1,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          children: [
            _buildReportGridTile(context, 'Total Files', '${report.totalFilesScanned}',
                Icons.folder_outlined, primaryColor, isDark),
            _buildReportGridTile(context, 'Total Links', '${report.totalLinksScanned}',
                Icons.link_rounded, primaryColor, isDark),
            _buildReportGridTile(context, 'Safe Files', '${report.safeFilesCount}',
                Icons.verified_user_outlined, const Color(0xFF12B76A), isDark),
            _buildReportGridTile(context, 'Suspicious', '${report.suspiciousFilesCount}',
                Icons.warning_amber_rounded, const Color(0xFFF79009), isDark),
            _buildReportGridTile(context, 'Infected', '${report.infectedFilesCount}',
                Icons.bug_report_outlined, const Color(0xFFF04438), isDark),
            _buildReportGridTile(context, 'Phishing URLs', '${report.phishingUrlsCount}',
                Icons.shield_outlined, const Color(0xFFF04438), isDark),
            _buildReportGridTile(context, 'Corrupted Files', '${report.corruptedFilesCount}',
                Icons.broken_image_outlined, const Color(0xFFF79009), isDark),
            _buildReportGridTile(context, 'Duplicate Files', '${report.duplicateFilesCount}',
                Icons.copy_outlined, isDark ? Colors.white60 : const Color(0xFF6B7280), isDark),
          ],
        ),
        const SizedBox(height: 22),

        // Actions Buttons
        if (report.hasIssues) ...[
          ElevatedButton.icon(
            onPressed: () => _showIssueDetailsBottomSheet(context, report),
            icon: const Icon(Icons.search_rounded, size: 18),
            label: const Text('View Detailed Issues', style: TextStyle(fontWeight: FontWeight.w700)),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: isDark ? Colors.black : Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
          const SizedBox(height: 10),
          ElevatedButton.icon(
            onPressed: () async {
              await _controller.deleteSuspiciousAndCorruptedFiles();
              if (context.mounted) {
                context.showSuccessNotification('Suspicious & corrupted files deleted.');
              }
            },
            icon: const Icon(Icons.delete_forever_rounded, size: 18),
            label: const Text('Delete Corrupted Downloads', style: TextStyle(fontWeight: FontWeight.w700)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF04438),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
          const SizedBox(height: 10),
        ],

        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: BorderSide(color: context.colors.border.withValues(alpha: 0.35)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: Text(
                  'Close',
                  style: TextStyle(
                    color: context.colors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: () => _controller.startScan(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: isDark ? Colors.black : Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: Text(
                  'Rescan',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.black : Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildReportGridTile(BuildContext context, String title, String value,
      IconData icon, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? context.colors.cardBackground : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: context.colors.border.withValues(alpha: 0.35),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
                Text(
                  title,
                  style: TextStyle(
                    color: isDark ? Colors.white60 : const Color(0xFF6B7280),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showIssueDetailsBottomSheet(BuildContext context, ScanReportModel report) {
    final isDark = context.colors.isDark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        decoration: BoxDecoration(
          color: ctx.colors.scaffoldBackground,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: ctx.colors.textHint.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Detected Issues & Warnings',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: ctx.colors.textPrimary,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                physics: const BouncingScrollPhysics(),
                itemCount: report.issueDetails.length,
                itemBuilder: (c, i) => Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark ? ctx.colors.cardBackground : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFFF79009).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: Color(0xFFF79009), size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          report.issueDetails[i],
                          style: TextStyle(
                            fontSize: 13.5,
                            color: ctx.colors.textPrimary,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
