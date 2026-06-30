import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

@lazySingleton
class StorageService {
  static const String _tokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userIdKey = 'user_id';
  static const String _usernameKey = 'username';
  static const String _profilePicKey = 'profile_pic_url';
  static const String _hasSyncedContactsKey = 'has_synced_contacts';

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
  }

  bool hasToken() {
    final token = getAccessToken();
    return token != null && token.isNotEmpty;
  }
}
