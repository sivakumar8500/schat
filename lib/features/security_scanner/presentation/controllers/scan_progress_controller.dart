import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:schat/core/security/security_scanner_service.dart';
import 'package:schat/features/security_scanner/domain/repositories/malware_scan_repository.dart';

@injectable
class ScanProgressController extends ValueNotifier<ScanProgressState?> {
  final SecurityScannerService _scannerService;
  final MalwareScanRepository _malwareScanRepository;
  StreamSubscription<ScanProgressState>? _subscription;
  Timer? _timer;

  ScanProgressController(
    this._scannerService,
    this._malwareScanRepository,
  ) : super(null);

  void startScan() {
    _subscription?.cancel();
    _timer?.cancel();

    final steps = SecurityScannerService.initialSteps();
    value = ScanProgressState(
      currentStepIndex: 0,
      currentTaskTitle: steps[0].title,
      progressPercentage: 0.0,
      filesScanned: 0,
      linksScanned: 0,
      elapsedTime: Duration.zero,
      steps: steps,
    );

    // Periodic timer for updating elapsed time MM:SS
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (value != null && !value!.isCompleted && !value!.isCancelled) {
        value = ScanProgressState(
          currentStepIndex: value!.currentStepIndex,
          currentTaskTitle: value!.currentTaskTitle,
          progressPercentage: value!.progressPercentage,
          filesScanned: value!.filesScanned,
          linksScanned: value!.linksScanned,
          elapsedTime: value!.elapsedTime + const Duration(seconds: 1),
          steps: value!.steps,
          isCancelled: value!.isCancelled,
          isCompleted: value!.isCompleted,
          report: value!.report,
        );
      }
    });

    _subscription = _scannerService.runScanSequence().listen(
      (state) {
        value = state;
        if (state.isCompleted || state.isCancelled) {
          _timer?.cancel();
        }
      },
      onError: (e) {
        debugPrint('ScanProgressController error: $e');
        _timer?.cancel();
      },
    );
  }

  void cancelScan() {
    _subscription?.cancel();
    _timer?.cancel();
    if (value != null) {
      value = ScanProgressState(
        currentStepIndex: value!.currentStepIndex,
        currentTaskTitle: 'Scan Cancelled',
        progressPercentage: value!.progressPercentage,
        filesScanned: value!.filesScanned,
        linksScanned: value!.linksScanned,
        elapsedTime: value!.elapsedTime,
        steps: value!.steps,
        isCancelled: true,
      );
    }
  }

  Future<void> deleteSuspiciousAndCorruptedFiles() async {
    final report = value?.report;
    if (report == null) return;

    final List<String> toDelete = [
      ...report.suspiciousFilePaths,
      ...report.infectedFilePaths,
      ...report.corruptedFilePaths,
    ];

    if (toDelete.isNotEmpty) {
      await _malwareScanRepository.deleteSuspiciousFiles(toDelete);
      startScan(); // Rescan after deletion
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _timer?.cancel();
    super.dispose();
  }
}
