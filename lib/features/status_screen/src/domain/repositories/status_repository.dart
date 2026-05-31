import '../status_model.dart';

abstract class StatusRepository {
  Future<List<StatusContactModel>> getRecentUpdates();
  Future<List<StatusContactModel>> getViewedUpdates();
  Future<List<StatusContactModel>> getMutedUpdates();
  Future<void> muteContact(String contactId, bool mute);
}
