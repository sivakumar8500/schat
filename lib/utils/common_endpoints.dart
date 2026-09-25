class CommonEndpoints {
  CommonEndpoints._();

  static const String baseUrl = 'http://13.205.107.199:8000/api/v1';
  static const String socketUrl = 'ws://13.205.107.199:8000/ws';

  // Auth
  static const String sendOtp = '/auth/send-otp';
  static const String verifyOtp = '/auth/verify-otp';

  // Profile
  static const String profileMe = '/users/me';
  static const String updateProfile = '/users/me';
  static const String syncContacts = '/users/sync-contacts';
  static const String getContacts = '/users/contacts';
  static const String discoverUsers = '/users/discover';
  static String searchUsers({String? query}) => (query != null && query.isNotEmpty)
      ? '/users/discover?query=${Uri.encodeComponent(query)}'
      : '/users/discover';
  static String lookupUserByPhone(String phone) => '/users/lookup?phone_number=${Uri.encodeComponent(phone)}';
  static String getUserProfile(String userId) => '/users/$userId';
  static const String deleteAccount = '/users/me';
  static const String emergencyContacts = '/users/emergency-contacts';
  static const String defaultEmergencyContacts = '/users/emergency-contacts/default';
  static const String allEmergencyContacts = '/users/emergency-contacts/all';
  static String emergencyContact(String contactId) => '/users/emergency-contacts/$contactId';

  // Subscriptions
  static const String getPlans = '/subscriptions/plans';
  static const String enrollSubscription = '/subscriptions/';

  // Chats
  static const String getChats = '/chats/';
  static const String createGroup = '/groups/';
  static const String getMessages = '/messages/';
  static const String searchMessages = '/messages/search';
  static String searchMessagesInChat(String conversationId) => '/messages/search/$conversationId';
  static const String scheduleMessage = '/messages/scheduled';
  static String getScheduledMessages({String? conversationId}) =>
      conversationId != null
          ? '/messages/scheduled?conversation_id=$conversationId'
          : '/messages/scheduled';
  static String cancelScheduledMessage(String id) => '/messages/scheduled/$id';
  static String updateScheduledMessage(String id) => '/messages/scheduled/$id';
  static const String getCalls = '/messages/calls';
  static String getCallHistory({int limit = 50}) => '/messages/calls?limit=$limit';
  static String getGroupDetails(String groupId) => '/groups/$groupId';
  static String updateGroup(String groupId) => '/groups/$groupId';
  static String deleteGroup(String groupId) => '/groups/$groupId';
  static String addGroupParticipants(String groupId) => '/groups/$groupId/members';
  static String removeGroupParticipant(String groupId, String userId) => '/groups/$groupId/members/$userId';
  static String promoteGroupAdmin(String groupId, String userId) => '/groups/$groupId/admins/$userId';
  static String demoteGroupAdmin(String groupId, String userId) => '/groups/$groupId/admins/$userId';

  // Chat Actions
  static String favoriteChat(String conversationId) => '/chats/$conversationId/favorite';
  static String unfavoriteChat(String conversationId) => '/chats/$conversationId/unfavorite';
  static String muteChat(String conversationId) => '/chats/$conversationId/mute';
  static String unmuteChat(String conversationId) => '/chats/$conversationId/unmute';
  static String setDisappearingTimer(String conversationId) => '/chats/$conversationId/disappearing-timer';
  
  // Chat Transfer & View Requests
  static const String chatViewRequests = '/chats/view-requests';
  static String respondChatViewRequest(String requestId) => '/chats/view-requests/$requestId/respond';
  static String revokeChatViewRequest(String requestId) => '/chats/view-requests/$requestId/revoke';
  static String getTargetConversations(String targetUserId) => '/chats/target/$targetUserId';
  
  // --- Device & Push Notifications ---
  static const String registerFcmToken = '/notifications/register-device';

  // --- Tones & Sound Preferences ---
  static const String getTones = '/tones';
  static const String myTones = '/tones/me';

  // --- External Integrations ---
  // Message Actions
  static String forwardMessage(String messageId) => '/messages/$messageId/forward';
  static String pinMessage(String messageId) => '/messages/$messageId/pin';
  static String unpinMessage(String messageId) => '/messages/$messageId/unpin';
  static String getPinnedMessages(String conversationId) => '/messages/$conversationId/pinned';
  static String editMessage(String messageId) => '/messages/$messageId';
  static String deleteMessage(String messageId) => '/messages/$messageId';
  static String updateMessageSecurity(String messageId) => '/messages/$messageId';
  static String getMessageShares(String messageId) => '/messages/$messageId/shares';

  // Media Upload & Permissions
  static const String requestUpload = '/media/request-upload';
  static String completeUpload(String mediaId) => '/media/$mediaId/complete';
  static String getConversationMedia(String conversationId) => '/chats/$conversationId/media';
  static String mediaPermissions(String mediaId) => '/media/$mediaId/permissions';
  static String mediaAccessTree(String mediaId) => '/media/$mediaId/access-tree';
  static String shareMedia(String mediaId) => '/media/$mediaId/share';

  // User Lookup
  static const String lookupUser = '/users/lookup';

  // User Blocking
  static String blockUser(String targetUserId) => '/users/block/$targetUserId';
  static String unblockUser(String targetUserId) => '/users/unblock/$targetUserId';
  static const String getBlockedUsers = '/users/blocked';
  static const String getBlockedGroups = '/users/blocked-groups';

  // Hide / Unhide Conversations
  static String hideChat(String conversationId) => '/chats/$conversationId/hide';
  static String unhideChat(String conversationId) => '/chats/$conversationId/unhide';
  static String deleteChat(String conversationId) => '/chats/$conversationId';

  // Clear Chat
  static String clearChat(String conversationId) => '/chats/$conversationId/clear';

  // Tickets
  static const String createTicket = '/chats/tickets';
  static const String getTickets = '/chats/tickets';

  // Conversation Theme Colors & Wallpapers
  static const String getThemes = '/chats/themes';
  static const String defaultTheme = '/chats/themes/default';
  static String updateTheme(String conversationId) => '/chats/$conversationId/theme';
  static String resetConversationTheme(String conversationId) => '/chats/$conversationId/theme';

  // Notifications
  static const String registerDevice = '/notifications/register-device';

  // Status & Stories
  static const String getRecentStatuses = '/statuses/';
  static const String getMyStatuses = '/statuses/me';
  static const String createStatus = '/statuses/';
  static String deleteStatus(String statusId) => '/statuses/$statusId';
  static String viewStatus(String statusId) => '/statuses/$statusId/view';
  static String muteContactStatus(String contactId) => '/statuses/mute/$contactId';
  static String unmuteContactStatus(String contactId) => '/statuses/unmute/$contactId';
  static const String statusPrivacy = '/statuses/privacy';
  static const String statusPrivacyInclude = '/statuses/privacy/include';
  static String removeStatusPrivacyInclude(String contactId) => '/statuses/privacy/include/$contactId';
  static const String statusPrivacyExclude = '/statuses/privacy/exclude';
  static String removeStatusPrivacyExclude(String contactId) => '/statuses/privacy/exclude/$contactId';

  // Screen Capture Permission
  static const String screenPermissionRequest = '/chats/screen-permission/request';
  static String screenPermissionRespond(String requestId) => '/chats/screen-permission/$requestId/respond';
  static const String screenPermissionPending = '/chats/screen-permission/pending';
  static String screenPermissionActive(String conversationId) => '/chats/screen-permission/active/$conversationId';
  static String screenPermissionConsume(String requestId) => '/chats/screen-permission/$requestId/consume';
}

