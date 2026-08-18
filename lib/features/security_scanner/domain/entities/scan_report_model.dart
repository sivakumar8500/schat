class ScanReportModel {
  final int overallScore;
  final int totalFilesScanned;
  final int totalLinksScanned;
  final int safeFilesCount;
  final int suspiciousFilesCount;
  final int infectedFilesCount;
  final int phishingUrlsCount;
  final int corruptedFilesCount;
  final int duplicateFilesCount;
  final Duration scanDuration;
  final DateTime scanTimestamp;
  final List<String> suspiciousFilePaths;
  final List<String> infectedFilePaths;
  final List<String> phishingUrls;
  final List<String> corruptedFilePaths;
  final List<String> duplicateFilePaths;
  final List<String> issueDetails;

  const ScanReportModel({
    required this.overallScore,
    required this.totalFilesScanned,
    required this.totalLinksScanned,
    required this.safeFilesCount,
    required this.suspiciousFilesCount,
    required this.infectedFilesCount,
    required this.phishingUrlsCount,
    required this.corruptedFilesCount,
    required this.duplicateFilesCount,
    required this.scanDuration,
    required this.scanTimestamp,
    this.suspiciousFilePaths = const [],
    this.infectedFilePaths = const [],
    this.phishingUrls = const [],
    this.corruptedFilePaths = const [],
    this.duplicateFilePaths = const [],
    this.issueDetails = const [],
  });

  bool get hasIssues =>
      suspiciousFilesCount > 0 ||
      infectedFilesCount > 0 ||
      phishingUrlsCount > 0 ||
      corruptedFilesCount > 0;
}
