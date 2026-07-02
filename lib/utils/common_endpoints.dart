class CommonEndpoints {
  CommonEndpoints._();

  static const String baseUrl = 'http://13.201.205.176:8000/api/v1';
  static const String socketUrl = 'ws://13.201.205.176:8000/ws';

  // Auth
  static const String sendOtp = '/auth/send-otp';
  static const String verifyOtp = '/auth/verify-otp';

  // Profile
  static const String profileMe = '/users/me';
  static const String updateProfile = '/users/me';
  static const String syncContacts = '/users/sync-contacts';
  static String getUserProfile(String userId) => '/users/$userId';
  static const String deleteAccount = '/users/me';

  // Subscriptions
  static const String getPlans = '/subscriptions/plans';
  static const String enrollSubscription = '/subscriptions/';

  // Chats
  static const String getChats = '/chats/';
  static const String createGroup = '/groups/';
  static const String getMessages = '/messages/';
  static String getGroupDetails(String groupId) => '/groups/$groupId';
  static String deleteGroup(String groupId) => '/groups/$groupId';

  // Chat Actions
  static String favoriteChat(String conversationId) => '/chats/$conversationId/favorite';
  static String unfavoriteChat(String conversationId) => '/chats/$conversationId/unfavorite';
  static String muteChat(String conversationId) => '/chats/$conversationId/mute';
  static String unmuteChat(String conversationId) => '/chats/$conversationId/unmute';
  static String setDisappearingTimer(String conversationId) => '/chats/$conversationId/disappearing-timer';
  
  // Message Actions
  static String forwardMessage(String messageId) => '/messages/$messageId/forward';
  static String pinMessage(String messageId) => '/messages/$messageId/pin';
  static String unpinMessage(String messageId) => '/messages/$messageId/unpin';
  static String getPinnedMessages(String conversationId) => '/messages/$conversationId/pinned';
  static String editMessage(String messageId) => '/messages/$messageId';
  static String deleteMessage(String messageId) => '/messages/$messageId';

  // Media Upload
  static const String requestUpload = '/media/request-upload';
  static String completeUpload(String mediaId) => '/media/$mediaId/complete';
  static String getConversationMedia(String conversationId) => '/chats/$conversationId/media';
}
