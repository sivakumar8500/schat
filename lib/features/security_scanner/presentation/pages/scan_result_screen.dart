import 'package:flutter/material.dart';
import 'package:schat/core/security/security_scanner_service.dart';
import 'package:schat/features/security_scanner/domain/entities/scan_report_model.dart';
import 'package:schat/features/security_scanner/presentation/controllers/scan_progress_controller.dart';
import 'package:schat/injection.dart';
import 'package:schat/utils/common_colors.dart';
import 'package:schat/utils/common_fontstyles.dart';
import 'package:schat/utils/common_spaces.dart';
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
    return Scaffold(
      backgroundColor: context.colors.scaffoldBackground,
      appBar: AppBar(
        title: const Text('Device Security Scan'),
        backgroundColor: context.colors.scaffoldBackground,
        elevation: 0,
        foregroundColor: context.colors.textPrimary,
      ),
      body: ValueListenableBuilder<ScanProgressState?>(
        valueListenable: _controller,
        builder: (context, state, _) {
          if (state == null) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.isCompleted && state.report != null) {
            return _buildReportView(context, state.report!);
          }

          return _buildProgressView(context, state);
        },
      ),
    );
  }

  Widget _buildProgressView(BuildContext context, ScanProgressState state) {
    final percentageInt = (state.progressPercentage * 100).toInt();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Radar Scan Animation Widget
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: RadarScanWidget(
                  size: 160,
                  statusText: 'SCANNING IN PROGRESS...',
                ),
              ),
            ),
            CommonSpaces.h12,

            // Progress Header Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: context.colors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: context.colors.primary.withValues(alpha: 0.2)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          state.currentTaskTitle,
                          style: context.titleMedium.copyWith(fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '$percentageInt%',
                        style: context.titleLarge.copyWith(
                          color: context.colors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  CommonSpaces.h12,
                  LinearProgressIndicator(
                    value: state.progressPercentage,
                    backgroundColor: context.colors.textHint.withValues(alpha: 0.2),
                    valueColor: AlwaysStoppedAnimation<Color>(context.colors.primary),
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  CommonSpaces.h16,
                  // Counter Metrics Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildMetricItem(context, 'Files Scanned', '${state.filesScanned}'),
                      _buildMetricItem(context, 'Links Scanned', '${state.linksScanned}'),
                      _buildMetricItem(context, 'Elapsed Time', _formatDuration(state.elapsedTime)),
                    ],
                  ),
                ],
              ),
            ),
            CommonSpaces.h16,

            // 14 Steps Sequential List
            Expanded(
              child: ListView.separated(
                itemCount: state.steps.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final step = state.steps[index];
                  final isCurrent = index == state.currentStepIndex && !state.isCompleted;

                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    leading: _buildStepStatusIcon(context, step.status, isCurrent),
                    title: Text(
                      step.title,
                      style: context.bodyMedium.copyWith(
                        fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                        color: isCurrent ? context.colors.primary : context.colors.textPrimary,
                      ),
                    ),
                    subtitle: Text(
                      step.description,
                      style: context.bodySmall.copyWith(color: context.colors.textSecondary, fontSize: 11),
                    ),
                  );
                },
              ),
            ),

            CommonSpaces.h12,
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
                    side: BorderSide(color: context.colors.error),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('Cancel Scan', style: TextStyle(color: context.colors.error, fontWeight: FontWeight.bold)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepStatusIcon(BuildContext context, StepStatus status, bool isCurrent) {
    if (isCurrent) {
      return SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(strokeWidth: 2.5, color: context.colors.primary),
      );
    }
    switch (status) {
      case StepStatus.success:
        return Icon(Icons.check_circle, color: context.colors.success, size: 24);
      case StepStatus.warning:
        return const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 24);
      case StepStatus.failed:
        return Icon(Icons.error_outline, color: context.colors.error, size: 24);
      case StepStatus.inProgress:
        return SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2.5, color: context.colors.primary),
        );
      case StepStatus.pending:
      default:
        return Icon(Icons.radio_button_unchecked, color: context.colors.textHint.withValues(alpha: 0.4), size: 24);
    }
  }

  Widget _buildMetricItem(BuildContext context, String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: context.titleMedium.copyWith(fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: context.bodySmall.copyWith(color: context.colors.textSecondary, fontSize: 10),
        ),
      ],
    );
  }

  Widget _buildReportView(BuildContext context, ScanReportModel report) {
    final Color scoreColor = report.overallScore >= 90
        ? context.colors.success
        : (report.overallScore >= 70 ? Colors.orange : context.colors.error);

    final String statusTitle = report.overallScore >= 90
        ? 'Device & App Safe'
        : (report.overallScore >= 70 ? 'Security Attention Recommended' : 'Security Threats Found');

    final String formattedDate =
        '${report.scanTimestamp.day}/${report.scanTimestamp.month}/${report.scanTimestamp.year} ${report.scanTimestamp.hour}:${report.scanTimestamp.minute.toString().padLeft(2, '0')}';

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Score Card Header
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: scoreColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: scoreColor.withValues(alpha: 0.3), width: 1.5),
            ),
            child: Column(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 100,
                      height: 100,
                      child: CircularProgressIndicator(
                        value: report.overallScore / 100.0,
                        strokeWidth: 10,
                        backgroundColor: scoreColor.withValues(alpha: 0.2),
                        valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${report.overallScore}',
                          style: context.h1.copyWith(
                            color: scoreColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 32,
                          ),
                        ),
                        Text(
                          '/ 100',
                          style: context.bodySmall.copyWith(color: context.colors.textSecondary),
                        ),
                      ],
                    ),
                  ],
                ),
                CommonSpaces.h16,
                Text(
                  statusTitle,
                  style: context.titleLarge.copyWith(fontWeight: FontWeight.bold, color: scoreColor),
                  textAlign: TextAlign.center,
                ),
                CommonSpaces.h6,
                Text(
                  'Scan completed in ${_formatDuration(report.scanDuration)} on $formattedDate',
                  style: context.bodySmall.copyWith(color: context.colors.textSecondary),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          CommonSpaces.h20,

          // Summary Metrics Grid
          Text('Scan Summary', style: context.titleMedium.copyWith(fontWeight: FontWeight.bold)),
          CommonSpaces.h12,
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 2.2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            children: [
              _buildReportGridTile(context, 'Total Files Scanned', '${report.totalFilesScanned}', Icons.folder_outlined, context.colors.primary),
              _buildReportGridTile(context, 'Total Links Scanned', '${report.totalLinksScanned}', Icons.link, context.colors.primary),
              _buildReportGridTile(context, 'Safe Files', '${report.safeFilesCount}', Icons.verified_user_outlined, context.colors.success),
              _buildReportGridTile(context, 'Suspicious Files', '${report.suspiciousFilesCount}', Icons.warning_amber_rounded, Colors.orange),
              _buildReportGridTile(context, 'Infected Files', '${report.infectedFilesCount}', Icons.bug_report_outlined, context.colors.error),
              _buildReportGridTile(context, 'Phishing URLs', '${report.phishingUrlsCount}', Icons.g_translate_outlined, context.colors.error),
              _buildReportGridTile(context, 'Corrupted Files', '${report.corruptedFilesCount}', Icons.broken_image_outlined, Colors.orange),
              _buildReportGridTile(context, 'Duplicate Files', '${report.duplicateFilesCount}', Icons.copy_outlined, context.colors.textSecondary),
            ],
          ),
          CommonSpaces.h24,

          // Actions Buttons
          if (report.hasIssues) ...[
            ElevatedButton.icon(
              onPressed: () => _showIssueDetailsBottomSheet(context, report),
              icon: const Icon(Icons.search, color: Colors.white),
              label: const Text('View Details', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: context.colors.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            CommonSpaces.h12,
            ElevatedButton.icon(
              onPressed: () async {
                await _controller.deleteSuspiciousAndCorruptedFiles();
                if (mounted) {
                  context.showSuccessNotification('Suspicious & corrupted files deleted.');
                }
              },
              icon: const Icon(Icons.delete_forever, color: Colors.white),
              label: const Text('Delete Local Downloaded Copies', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: context.colors.error,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            CommonSpaces.h12,
          ],

          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Ignore & Close'),
                ),
              ),
              CommonSpaces.w12,
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _controller.startScan(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.colors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Rescan', style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
          CommonSpaces.h24,
        ],
      ),
    );
  }

  Widget _buildReportGridTile(BuildContext context, String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: context.colors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.colors.textHint.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          CommonSpaces.w8,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(value, style: context.titleMedium.copyWith(fontWeight: FontWeight.bold, color: color)),
                Text(title, style: context.bodySmall.copyWith(color: context.colors.textSecondary, fontSize: 10), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showIssueDetailsBottomSheet(BuildContext context, ScanReportModel report) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: ctx.colors.scaffoldBackground,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: ctx.colors.textHint.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(2)),
              ),
            ),
            CommonSpaces.h16,
            Text('Detected Issues & Warnings', style: ctx.titleLarge.copyWith(fontWeight: FontWeight.bold)),
            CommonSpaces.h16,
            Expanded(
              child: ListView.builder(
                itemCount: report.issueDetails.length,
                itemBuilder: (c, i) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: const Icon(Icons.warning, color: Colors.orange),
                    title: Text(report.issueDetails[i], style: ctx.bodyMedium),
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
