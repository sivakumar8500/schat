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

  // Subscriptions
  static const String getPlans = '/subscriptions/plans';
  static const String enrollSubscription = '/subscriptions/';

  // Chats
  static const String getChats = '/chats/';
  static const String getMessages = '/messages/';

  // Media Upload
  static const String requestUpload = '/media/request-upload';
  static String completeUpload(String mediaId) => '/media/$mediaId/complete';
  static String getConversationMedia(String conversationId) => '/media/$conversationId';
}

