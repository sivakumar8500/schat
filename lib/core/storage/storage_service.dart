import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

@lazySingleton
class StorageService {
  static const String _tokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userIdKey = 'user_id';
  static const String _usernameKey = 'username';
  static const String _profilePicKey = 'profile_pic_url';
  static const String _hasSyncedContactsKey = 'has_synced_contacts';
  static const String _emailKey = 'email';
  static const String _phoneKey = 'phone_number';
  static const String _deviceIdKey = 'device_id';
  static const String _hasSeenPermissionsKey = 'has_seen_permissions';
  static const String _callRingtoneNameKey = 'call_ringtone_name';
  static const String _callRingtoneUrlKey = 'call_ringtone_url';
  static const String _messageToneNameKey = 'message_tone_name';
  static const String _messageToneUrlKey = 'message_tone_url';
  static const String _readReceiptsEnabledKey = 'read_receipts_enabled';
  static const String _typingIndicatorsEnabledKey = 'typing_indicators_enabled';
  static const String _lastSeenEnabledKey = 'last_seen_enabled';
  static const String _notificationsEnabledKey = 'notifications_enabled';
  static const String _defaultDisappearingTimerKey = 'default_disappearing_timer';
  static const String _mutedChatsKey = 'muted_chats_list';
  static const String _lockedChatsKey = 'locked_chats_list';
  static const String _hiddenChatsKey = 'hidden_chats_list';

  final SharedPreferences _prefs;

  @injectable
  StorageService(this._prefs);

  Future<void> saveTokens({required String accessToken, required String refreshToken}) async {
    await _prefs.setString(_tokenKey, accessToken);
    await _prefs.setString(_refreshTokenKey, refreshToken);
  }

  Future<void> saveUserId(String userId) async {
    await _prefs.setString(_userIdKey, userId);
  }

  Future<void> setHasSyncedContacts(bool value) async {
    await _prefs.setBool(_hasSyncedContactsKey, value);
  }

  bool hasSyncedContacts() {
    return _prefs.getBool(_hasSyncedContactsKey) ?? false;
  }

  Future<void> saveUsername(String? username) async {
    if (username != null && username.isNotEmpty) {
      await _prefs.setString(_usernameKey, username);
    }
  }

  Future<void> saveProfilePic(String? url) async {
    if (url != null && url.isNotEmpty) {
      await _prefs.setString(_profilePicKey, url);
    } else {
      await _prefs.remove(_profilePicKey);
    }
  }

  Future<void> savePhoneNumber(String? phone) async {
    if (phone != null && phone.isNotEmpty) {
      await _prefs.setString(_phoneKey, phone);
    } else {
      await _prefs.remove(_phoneKey);
    }
  }

  String? getPhoneNumber() {
    return _prefs.getString(_phoneKey);
  }

  String? getUsername() {
    return _prefs.getString(_usernameKey);
  }

  String? getProfilePic() {
    return _prefs.getString(_profilePicKey);
  }

  String? getUserId() {
    return _prefs.getString(_userIdKey);
  }

  String? getAccessToken() {
    return _prefs.getString(_tokenKey);
  }

  Future<void> clearTokens() async {
    await _prefs.remove(_tokenKey);
    await _prefs.remove(_refreshTokenKey);
    await _prefs.remove(_hasSyncedContactsKey);
  }

  Future<void> clearUser() async {
    await _prefs.remove(_userIdKey);
    await _prefs.remove(_usernameKey);
    await _prefs.remove(_profilePicKey);
    await _prefs.remove(_emailKey);
    await _prefs.remove(_hasSyncedContactsKey);
    await _prefs.remove(_defaultDisappearingTimerKey);
  }

  bool hasToken() {
    final token = getAccessToken();
    return token != null && token.isNotEmpty;
  }

  Future<void> saveEmail(String? email) async {
    if (email != null && email.isNotEmpty) {
      await _prefs.setString(_emailKey, email);
    } else {
      await _prefs.remove(_emailKey);
    }
  }

  String? getEmail() {
    return _prefs.getString(_emailKey);
  }

  String getOrGenerateDeviceId() {
    String? deviceId = _prefs.getString(_deviceIdKey);
    if (deviceId == null) {
      deviceId = const Uuid().v4();
      _prefs.setString(_deviceIdKey, deviceId);
    }
    return deviceId;
  }

  String getDeviceId() => getOrGenerateDeviceId();

  Future<void> setHasSeenPermissions(bool value) async {
    await _prefs.setBool(_hasSeenPermissionsKey, value);
  }

  bool hasSeenPermissions() {
    return _prefs.getBool(_hasSeenPermissionsKey) ?? false;
  }

  // --- Tones Preferences ---
  Future<void> saveCallRingtone({required String name, required String url}) async {
    await _prefs.setString(_callRingtoneNameKey, name);
    await _prefs.setString(_callRingtoneUrlKey, url);
  }

  String? getCallRingtoneName() => _prefs.getString(_callRingtoneNameKey);
  String? getCallRingtoneUrl() => _prefs.getString(_callRingtoneUrlKey);

  Future<void> saveMessageTone({required String name, required String url}) async {
    await _prefs.setString(_messageToneNameKey, name);
    await _prefs.setString(_messageToneUrlKey, url);
  }

  String? getMessageToneName() => _prefs.getString(_messageToneNameKey);
  String? getMessageToneUrl() => _prefs.getString(_messageToneUrlKey);

  Future<void> clearTonePreferences() async {
    await _prefs.remove(_callRingtoneNameKey);
    await _prefs.remove(_callRingtoneUrlKey);
    await _prefs.remove(_messageToneNameKey);
    await _prefs.remove(_messageToneUrlKey);
  }

  // --- Privacy Preferences ---
  Future<void> saveReadReceiptsEnabled(bool enabled) async {
    await _prefs.setBool(_readReceiptsEnabledKey, enabled);
  }

  bool getReadReceiptsEnabled() {
    return _prefs.getBool(_readReceiptsEnabledKey) ?? true;
  }

  Future<void> saveTypingIndicatorsEnabled(bool enabled) async {
    await _prefs.setBool(_typingIndicatorsEnabledKey, enabled);
  }

  bool getTypingIndicatorsEnabled() {
    return _prefs.getBool(_typingIndicatorsEnabledKey) ?? true;
  }

  Future<void> saveLastSeenEnabled(bool enabled) async {
    await _prefs.setBool(_lastSeenEnabledKey, enabled);
  }

  bool getLastSeenEnabled() {
    return _prefs.getBool(_lastSeenEnabledKey) ?? true;
  }

  // --- Notification Preferences ---
  Future<void> saveNotificationsEnabled(bool enabled) async {
    await _prefs.setBool(_notificationsEnabledKey, enabled);
  }

  bool getNotificationsEnabled() {
    return _prefs.getBool(_notificationsEnabledKey) ?? true;
  }

  // --- Disappearing Messages Preference ---
  Future<void> saveDefaultDisappearingTimer(int? seconds) async {
    if (seconds != null && seconds != 0) {
      await _prefs.setInt(_defaultDisappearingTimerKey, seconds);
    } else {
      await _prefs.remove(_defaultDisappearingTimerKey);
    }
  }

  int? getDefaultDisappearingTimer() {
    final timer = _prefs.getInt(_defaultDisappearingTimerKey);
    return (timer == null || timer == 0) ? null : timer;
  }

  Future<void> saveChatMuted(String conversationId, bool isMuted) async {
    final list = List<String>.from(_prefs.getStringList(_mutedChatsKey) ?? []);
    if (isMuted) {
      if (!list.contains(conversationId)) {
        list.add(conversationId);
      }
    } else {
      list.remove(conversationId);
    }
    await _prefs.setStringList(_mutedChatsKey, list);
  }

  bool isChatMuted(String conversationId) {
    final list = _prefs.getStringList(_mutedChatsKey) ?? [];
    return list.contains(conversationId);
  }

  List<String> getMutedChats() {
    return _prefs.getStringList(_mutedChatsKey) ?? [];
  }

  Future<void> saveChatLocked(String conversationId, bool isLocked) async {
    final list = List<String>.from(_prefs.getStringList(_lockedChatsKey) ?? []);
    if (isLocked) {
      if (!list.contains(conversationId)) list.add(conversationId);
    } else {
      list.remove(conversationId);
    }
    await _prefs.setStringList(_lockedChatsKey, list);
  }

  bool isChatLocked(String conversationId) {
    final list = _prefs.getStringList(_lockedChatsKey) ?? [];
    return list.contains(conversationId);
  }

  Future<void> saveChatHidden(String conversationId, bool isHidden) async {
    final list = List<String>.from(_prefs.getStringList(_hiddenChatsKey) ?? []);
    if (isHidden) {
      if (!list.contains(conversationId)) list.add(conversationId);
    } else {
      list.remove(conversationId);
    }
    await _prefs.setStringList(_hiddenChatsKey, list);
  }

  bool isChatHidden(String conversationId) {
    final list = _prefs.getStringList(_hiddenChatsKey) ?? [];
    return list.contains(conversationId);
  }

  Future<void> clearAll() async {
    await _prefs.clear();
  }
}

