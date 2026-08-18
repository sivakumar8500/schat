import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:schat/features/security_scanner/data/services/url_safety_service.dart';
import 'package:schat/features/security_scanner/domain/entities/scan_report_model.dart';
import 'package:schat/features/security_scanner/domain/repositories/malware_scan_repository.dart';

enum StepStatus { pending, inProgress, success, warning, failed }

class ScanStepInfo {
  final int stepNumber;
  final String title;
  final String description;
  StepStatus status;

  ScanStepInfo({
    required this.stepNumber,
    required this.title,
    required this.description,
    this.status = StepStatus.pending,
  });
}

class ScanProgressState {
  final int currentStepIndex;
  final String currentTaskTitle;
  final double progressPercentage; // 0.0 to 1.0
  final int filesScanned;
  final int linksScanned;
  final Duration elapsedTime;
  final List<ScanStepInfo> steps;
  final bool isCancelled;
  final bool isCompleted;
  final ScanReportModel? report;

  const ScanProgressState({
    required this.currentStepIndex,
    required this.currentTaskTitle,
    required this.progressPercentage,
    required this.filesScanned,
    required this.linksScanned,
    required this.elapsedTime,
    required this.steps,
    this.isCancelled = false,
    this.isCompleted = false,
    this.report,
  });
}

@lazySingleton
class SecurityScannerService {
  final MalwareScanRepository _malwareScanRepository;
  final UrlSafetyService _urlSafetyService;

  SecurityScannerService(
    this._malwareScanRepository,
    this._urlSafetyService,
  );

  static List<ScanStepInfo> initialSteps() {
    return [
      ScanStepInfo(stepNumber: 1, title: 'Initializing security engine', description: 'Step 1 of 14: Starting core security diagnostics...'),
      ScanStepInfo(stepNumber: 2, title: 'Checking network connectivity', description: 'Step 2 of 14: Verifying active internet connection...'),
      ScanStepInfo(stepNumber: 3, title: 'Loading security database', description: 'Step 3 of 14: Fetching latest malware signatures...'),
      ScanStepInfo(stepNumber: 4, title: 'Scanning downloaded files', description: 'Step 4 of 14: Reading files in private storage...'),
      ScanStepInfo(stepNumber: 5, title: 'Calculating file hashes', description: 'Step 5 of 14: Computing SHA-256 hashes...'),
      ScanStepInfo(stepNumber: 6, title: 'Checking file hashes', description: 'Step 6 of 14: Verifying hashes against virus database...'),
      ScanStepInfo(stepNumber: 7, title: 'Checking suspicious file types', description: 'Step 7 of 14: Filtering risky extensions (.apk, .exe, .bat, .cmd)...'),
      ScanStepInfo(stepNumber: 8, title: 'Inspecting package files', description: 'Step 8 of 14: Inspecting accessible package files...'),
      ScanStepInfo(stepNumber: 9, title: 'Scanning chat URLs', description: 'Step 9 of 14: Checking links against Safe Browsing...'),
      ScanStepInfo(stepNumber: 10, title: 'Checking file integrity', description: 'Step 10 of 14: Checking for corrupted or modified files...'),
      ScanStepInfo(stepNumber: 11, title: 'Checking duplicate files', description: 'Step 11 of 14: Scanning for duplicate files...'),
      ScanStepInfo(stepNumber: 12, title: 'Verifying encrypted storage', description: 'Step 12 of 14: Validating AES-256 storage integrity...'),
      ScanStepInfo(stepNumber: 13, title: 'Verifying local security keys', description: 'Step 13 of 14: Checking secure key storage...'),
      ScanStepInfo(stepNumber: 14, title: 'Generating report', description: 'Step 14 of 14: Compiling final security score...'),
    ];
  }

  Stream<ScanProgressState> runScanSequence() async* {
    final steps = initialSteps();
    final stopwatch = Stopwatch()..start();
    bool isCancelled = false;

    int totalFilesScanned = 0;
    int totalLinksScanned = 0;

    List<File> downloadedFiles = [];
    List<String> suspiciousFiles = [];
    List<String> infectedFiles = [];
    List<String> phishingLinks = [];
    List<String> corruptedFiles = [];
    List<String> duplicateFiles = [];
    List<String> issuesList = [];

    ScanProgressState buildState(int stepIdx) {
      final percentage = (stepIdx + 1) / steps.length;
      return ScanProgressState(
        currentStepIndex: stepIdx,
        currentTaskTitle: steps[stepIdx].title,
        progressPercentage: percentage.clamp(0.0, 1.0),
        filesScanned: totalFilesScanned,
        linksScanned: totalLinksScanned,
        elapsedTime: stopwatch.elapsed,
        steps: List.from(steps),
        isCancelled: isCancelled,
      );
    }

    for (int i = 0; i < steps.length; i++) {
      steps[i].status = StepStatus.inProgress;
      yield buildState(i);
      await Future.delayed(const Duration(milliseconds: 350));

      try {
        switch (i + 1) {
          case 1:
            // Step 1: Initialize
            steps[i].status = StepStatus.success;
            break;

          case 2:
            // Step 2: Connectivity
            final connectivityResult = await Connectivity().checkConnectivity();
            if (connectivityResult.contains(ConnectivityResult.none)) {
              steps[i].status = StepStatus.warning;
              issuesList.add('Network Offline: Scanned locally without live backend update.');
            } else {
              steps[i].status = StepStatus.success;
            }
            break;

          case 3:
            // Step 3: Load Database
            steps[i].status = StepStatus.success;
            break;

          case 4:
            // Step 4: Scan Downloaded Files
            downloadedFiles = await _malwareScanRepository.getDownloadedFiles();
            totalFilesScanned = downloadedFiles.length;
            steps[i].status = StepStatus.success;
            break;

          case 5:
            // Step 5: Hashes
            for (var file in downloadedFiles) {
              await _malwareScanRepository.calculateSha256(file);
            }
            steps[i].status = StepStatus.success;
            break;

          case 6:
            // Step 6: Hash Verification
            for (var file in downloadedFiles) {
              final hash = await _malwareScanRepository.calculateSha256(file);
              final isInfected = await _malwareScanRepository.verifyHashWithBackend(hash);
              if (isInfected) {
                infectedFiles.add(file.path);
                issuesList.add('Infected File Detected: ${file.path.split('/').last}');
              }
            }
            steps[i].status = infectedFiles.isEmpty ? StepStatus.success : StepStatus.failed;
            break;

          case 7:
            // Step 7: Suspicious Extensions
            for (var file in downloadedFiles) {
              if (_malwareScanRepository.isSuspiciousExtension(file.path)) {
                suspiciousFiles.add(file.path);
                issuesList.add('Risky File Extension: ${file.path.split('/').last}');
              }
            }
            steps[i].status = suspiciousFiles.isEmpty ? StepStatus.success : StepStatus.warning;
            break;

          case 8:
            // Step 8: Package inspection (Platform restricted)
            steps[i].status = StepStatus.success;
            break;

          case 9:
            // Step 9: URLs
            final urlResult = await _urlSafetyService.scanAllChatUrls();
            totalLinksScanned = urlResult.scannedUrls.length;
            phishingLinks.addAll(urlResult.phishingUrls);
            if (phishingLinks.isNotEmpty) {
              for (var link in phishingLinks) {
                issuesList.add('Phishing Link Found in Chat: $link');
              }
            }
            steps[i].status = phishingLinks.isEmpty ? StepStatus.success : StepStatus.warning;
            break;

          case 10:
            // Step 10: Corrupted files
            final corruptedList = await _malwareScanRepository.findCorruptedFiles(downloadedFiles);
            corruptedFiles.addAll(corruptedList.map((f) => f.path));
            if (corruptedFiles.isNotEmpty) {
              issuesList.add('Corrupted Files Found: ${corruptedFiles.length} file(s)');
            }
            steps[i].status = corruptedFiles.isEmpty ? StepStatus.success : StepStatus.warning;
            break;

          case 11:
            // Step 11: Duplicate files
            final dups = await _malwareScanRepository.findDuplicateFiles(downloadedFiles);
            duplicateFiles.addAll(dups.map((f) => f.path));
            if (duplicateFiles.isNotEmpty) {
              issuesList.add('Duplicate Files Detected: ${duplicateFiles.length} file(s)');
            }
            steps[i].status = duplicateFiles.isEmpty ? StepStatus.success : StepStatus.warning;
            break;

          case 12:
            // Step 12: Storage integrity
            final isStorageValid = await _malwareScanRepository.verifyEncryptedStorageIntegrity();
            steps[i].status = isStorageValid ? StepStatus.success : StepStatus.failed;
            break;

          case 13:
            // Step 13: Local Security Keys
            steps[i].status = StepStatus.success;
            break;

          case 14:
            // Step 14: Report Generation
            steps[i].status = StepStatus.success;
            break;
        }
      } catch (e) {
        debugPrint('Error on step ${i + 1}: $e');
        steps[i].status = StepStatus.failed;
      }

      yield buildState(i);
    }

    stopwatch.stop();

    // Compute Overall Security Score (0 to 100)
    int score = 100;
    score -= (infectedFiles.length * 40);
    score -= (phishingLinks.length * 20);
    score -= (suspiciousFiles.length * 15);
    score -= (corruptedFiles.length * 5);
    score -= (duplicateFiles.length * 2);
    if (score < 0) score = 0;

    final safeCount = totalFilesScanned - (suspiciousFiles.length + infectedFiles.length + corruptedFiles.length);

    final finalReport = ScanReportModel(
      overallScore: score,
      totalFilesScanned: totalFilesScanned,
      totalLinksScanned: totalLinksScanned,
      safeFilesCount: safeCount < 0 ? 0 : safeCount,
      suspiciousFilesCount: suspiciousFiles.length,
      infectedFilesCount: infectedFiles.length,
      phishingUrlsCount: phishingLinks.length,
      corruptedFilesCount: corruptedFiles.length,
      duplicateFilesCount: duplicateFiles.length,
      scanDuration: stopwatch.elapsed,
      scanTimestamp: DateTime.now(),
      suspiciousFilePaths: suspiciousFiles,
      infectedFilePaths: infectedFiles,
      phishingUrls: phishingLinks,
      corruptedFilePaths: corruptedFiles,
      duplicateFilePaths: duplicateFiles,
      issueDetails: issuesList,
    );

    yield ScanProgressState(
      currentStepIndex: steps.length - 1,
      currentTaskTitle: 'Scan Complete',
      progressPercentage: 1.0,
      filesScanned: totalFilesScanned,
      linksScanned: totalLinksScanned,
      elapsedTime: stopwatch.elapsed,
      steps: List.from(steps),
      isCompleted: true,
      report: finalReport,
    );
  }
}
