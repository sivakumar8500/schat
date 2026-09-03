import '../status_model.dart';

abstract class StatusRepository {
  Future<List<StatusContactModel>> getRecentUpdates();
  Future<List<StatusContactModel>> getViewedUpdates();
  Future<List<StatusContactModel>> getMutedUpdates();
  Future<void> muteContact(String contactId, bool mute);
  
  // New API Methods
  Future<void> createStatus({
    required String statusType,
    String? textContent,
    String? mediaFileId,
    String? filePath,
    String? fileName,
    String? mimeType,
    int? fileSizeBytes,
    dynamic fileBytes, // Uint8List
    String? privacyType,
    List<String>? privacyUserIds,
  });
  Future<List<StatusItemModel>> getMyStatuses();
  Future<void> deleteStatus(String statusId);
  Future<void> viewStatus(String statusId);
}
