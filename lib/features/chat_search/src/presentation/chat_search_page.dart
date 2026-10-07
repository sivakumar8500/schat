import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:schat/features/dashboard_screen/src/presentation/bloc/chats_bloc.dart';
import 'package:schat/features/dashboard_screen/src/presentation/bloc/chats_event.dart';
import 'package:schat/features/dashboard_screen/src/presentation/bloc/chats_state.dart';
import 'package:schat/features/dashboard_screen/src/domain/models/chat_model.dart';
import 'package:schat/features/dashboard_screen/src/domain/models/recipient_model.dart';
import 'package:schat/features/dashboard_screen/src/presentation/dashboard_page.dart';
import 'package:schat/features/chat_screen/src/presentation/chat_page.dart';
import 'package:schat/features/chat_screen/src/presentation/locked_chats_page.dart';
import 'package:schat/features/chat_search/src/domain/models/global_search_model.dart';
import 'package:schat/core/network/api_service.dart';
import 'package:schat/core/storage/storage_service.dart';
import 'package:schat/utils/common_colors.dart';
import 'package:schat/utils/common_spaces.dart';
import 'package:schat/utils/common_endpoints.dart';
import 'package:schat/features/dashboard_screen/src/presentation/bloc/contacts_bloc.dart';
import 'package:schat/features/dashboard_screen/src/presentation/bloc/contacts_state.dart';
import 'package:collection/collection.dart';
import 'package:schat/injection.dart';

class ChatSearchPage extends StatefulWidget {
  const ChatSearchPage({super.key});

  @override
  State<ChatSearchPage> createState() => _ChatSearchPageState();
}

class _ChatSearchPageState extends State<ChatSearchPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedFilter = 'All';

  Timer? _debounceTimer;
  bool _isSearchingServer = false;
  GlobalSearchResponse? _serverSearchResponse;

  final List<Map<String, dynamic>> _filters = [
    {'key': 'All', 'label': 'All', 'icon': Icons.all_inclusive_rounded},
    {'key': 'Unread', 'label': 'Unread', 'icon': Icons.mark_chat_unread_outlined},
    {'key': 'Groups', 'label': 'Groups', 'icon': Icons.group_outlined},
    {'key': 'Photos', 'label': 'Photos', 'icon': Icons.photo_outlined},
    {'key': 'Videos', 'label': 'Videos', 'icon': Icons.videocam_outlined},
    {'key': 'Links', 'label': 'Links', 'icon': Icons.link_outlined},
    {'key': 'Audio', 'label': 'Audio', 'icon': Icons.audiotrack_outlined},
    {'key': 'Documents', 'label': 'Documents', 'icon': Icons.description_outlined},
  ];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim();
    if (query != _searchQuery) {
      setState(() {
        _searchQuery = query;
      });
      _debounceServerSearch(query);
    }
  }

  void _debounceServerSearch(String query) {
    _debounceTimer?.cancel();
    if (query.isEmpty) {
      setState(() {
        _isSearchingServer = false;
        _serverSearchResponse = null;
      });
      return;
    }

    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _executeServerSearch(query);
    });
  }

  Future<void> _executeServerSearch(String query) async {
    if (!mounted || query.isEmpty) return;

    setState(() {
      _isSearchingServer = true;
    });

    try {
      final apiService = getIt<ApiService>();
      final filterParam = _selectedFilter == 'All' ? 'all' : _selectedFilter.toLowerCase();
      final result = await apiService.call<GlobalSearchResponse>(
        path: CommonEndpoints.searchGlobal,
        method: 'GET',
        queryParameters: {
          'q': query,
          'filter': filterParam,
          'limit': 40,
        },
        mapper: (data) => GlobalSearchResponse.fromJson(data as Map<String, dynamic>),
      );

      if (!mounted) return;

      result.when(
        success: (response) {
          if (mounted && _searchQuery == query) {
            if (response.isSecretCodeMatch || response.lockedChats.isNotEmpty) {
              // Immediately clear search bar so password is not visible after opening chats
              _searchController.clear();
              setState(() {
                _searchQuery = '';
                _serverSearchResponse = null;
                _isSearchingServer = false;
              });

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => LockedChatsPage(
                    initialLockedChats: response.lockedChats,
                  ),
                ),
              );
              return;
            }

            setState(() {
              _serverSearchResponse = response;
              _isSearchingServer = false;
            });
          }
        },
        failure: (msg, _) {
          if (mounted) {
            setState(() {
              _isSearchingServer = false;
            });
          }
        },
      );
    } catch (_) {
      if (mounted) {
        setState(() {
          _isSearchingServer = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.colors.isDark;

    return Scaffold(
      backgroundColor: context.colors.scaffoldBackground,
      body: Stack(
        children: [
          // Background wave pattern matching Home Screen
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: HomeBackgroundWavePainter(isDark: isDark),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildSearchHeader(isDark),
                if (_searchQuery.isEmpty) _buildFilterChips(isDark),
                const SizedBox(height: 4),
                Expanded(
                  child: BlocBuilder<ChatsBloc, ChatsState>(
                    builder: (context, state) {
                      return state.maybeWhen(
                        loading: () => Center(
                          child: CircularProgressIndicator(color: context.colors.primary),
                        ),
                        loaded: (chatList) {
                          // When query is entered, render query-based search results
                          if (_searchQuery.isNotEmpty) {
                            return _buildQueryResultList(chatList, isDark);
                          }

                          final filteredChats = _filterChats(chatList);
                          if (filteredChats.isEmpty) {
                            return _buildEmptyState(isDark);
                          }

                          // Render Grid View for Photos, Videos, and Audio
                          if (_selectedFilter == 'Photos' ||
                              _selectedFilter == 'Videos' ||
                              _selectedFilter == 'Audio') {
                            return _buildMediaGrid(filteredChats, isDark, _selectedFilter);
                          }

                          // Render dedicated Links view
                          if (_selectedFilter == 'Links') {
                            return _buildLinksList(filteredChats, isDark);
                          }

                          // Render dedicated Documents view
                          if (_selectedFilter == 'Documents') {
                            return _buildDocumentsList(filteredChats, isDark);
                          }

                          return _buildChatList(filteredChats, isDark);
                        },
                        error: (msg) => Center(
                          child: Text(
                            'Error: $msg',
                            style: TextStyle(color: context.colors.textSecondary),
                          ),
                        ),
                        orElse: () => Center(
                          child: CircularProgressIndicator(color: context.colors.primary),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchHeader(bool isDark) {
    final searchBgColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : const Color(0xFFEFF4F1);

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 16, 6),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              Icons.arrow_back,
              color: isDark ? Colors.white : const Color(0xFF111827),
              size: 24,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Container(
              height: 46,
              decoration: BoxDecoration(
                color: searchBgColor,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isDark ? Colors.white12 : const Color(0xFFE5E7EB),
                  width: 0.8,
                ),
              ),
              padding: const EdgeInsets.only(left: 14, right: 6),
              child: Row(
                children: [
                  Icon(
                    Icons.search_rounded,
                    color: isDark ? const Color(0xFF00FF87) : const Color(0xFF00873C),
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      autofocus: true,
                      style: TextStyle(
                        color: context.colors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Search chats, contacts, messages...',
                        hintStyle: TextStyle(
                          color: isDark ? Colors.white38 : const Color(0xFF9CA3AF),
                          fontSize: 16,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                  if (_searchQuery.isNotEmpty)
                    GestureDetector(
                      onTap: () {
                        _searchController.clear();
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(6.0),
                        child: Icon(
                          Icons.cancel_rounded,
                          color: isDark ? Colors.white38 : const Color(0xFF9CA3AF),
                          size: 18,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips(bool isDark) {
    final activeColor = isDark ? const Color(0xFF00FF87) : const Color(0xFF00873C);
    final activeTextColor = isDark ? Colors.black : Colors.white;

    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        itemCount: _filters.length,
        separatorBuilder: (_, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = _filters[index];
          final isSelected = _selectedFilter == filter['key'];

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedFilter = filter['key'] as String;
              });
              if (_searchQuery.isNotEmpty) {
                _executeServerSearch(_searchQuery);
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected
                    ? activeColor
                    : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.transparent),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? activeColor
                      : (isDark ? Colors.white24 : const Color(0xFFD1D5DB)),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    filter['icon'] as IconData,
                    size: 15,
                    color: isSelected
                        ? activeTextColor
                        : (isDark ? Colors.white70 : const Color(0xFF4B5563)),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    filter['label'] as String,
                    style: TextStyle(
                      color: isSelected
                          ? activeTextColor
                          : (isDark ? Colors.white70 : const Color(0xFF374151)),
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  bool _isSystemMessageText(String text, String? messageType) {
    final lowerType = (messageType ?? '').toLowerCase();
    if (lowerType == 'system' ||
        lowerType == 'group_event' ||
        lowerType == 'notification' ||
        lowerType == 'timer' ||
        lowerType == 'event') {
      return true;
    }
    final lower = text.toLowerCase().trim();
    if (lower.isEmpty) return false;
    if (lower.contains('disappearing messages') ||
        lower.contains('messages will disappear') ||
        lower.contains('updated the disappearing') ||
        lower.contains('turned on disappearing') ||
        lower.contains('turned off disappearing') ||
        lower.contains('changed the group name') ||
        lower.contains('changed group name') ||
        lower.contains('changed the group description') ||
        lower.contains('created the group') ||
        lower.contains('created this group') ||
        lower.contains('left the group') ||
        lower.contains('joined the group') ||
        lower.contains('removed from the group') ||
        lower.contains('security code changed') ||
        lower.contains('screenshot') ||
        lower.contains('screen recording') ||
        lower.contains('waiting for this message')) {
      return true;
    }
    return false;
  }

  bool _isRawMediaFileName(String text) {
    final lower = text.toLowerCase().trim();
    return lower.startsWith('image_picker_') ||
        lower.startsWith('scaled_image_picker') ||
        lower.startsWith('temp_') ||
        lower.startsWith('vid_') ||
        lower.startsWith('img_') ||
        RegExp(r'^\d{4,}\.(mp4|mov|jpg|jpeg|png|webp|m4a|mp3)$', caseSensitive: false).hasMatch(lower) ||
        RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}', caseSensitive: false).hasMatch(lower);
  }

  String _formatDisplayContent(String rawContent, String mediaType, {String? fileName}) {
    final type = mediaType.toLowerCase();
    final trimmed = rawContent.trim();

    if (trimmed.contains(' · ')) {
      final parts = trimmed.split(' · ');
      final filePart = parts[0].trim();
      final captionPart = parts.sublist(1).join(' · ').trim();

      if (_isRawMediaFileName(filePart)) {
        if (captionPart.isNotEmpty) {
          if (type == 'image' || type == 'photo') return '📷 $captionPart';
          if (type == 'video') return '🎥 $captionPart';
          if (type == 'audio' || type == 'voice') return '🎵 $captionPart';
          if (type == 'document' || type == 'file' || type == 'pdf') return '📄 $captionPart';
          return captionPart;
        }
      }
    }

    if (_isRawMediaFileName(trimmed)) {
      if (type == 'image' || type == 'photo') return '📷 Photo';
      if (type == 'video') return '🎥 Video';
      if (type == 'audio' || type == 'voice') return '🎵 Audio';
      if (type == 'document' || type == 'file' || type == 'pdf') return _formatDisplayFileName(fileName ?? 'Document');
      return 'Attachment';
    }

    if (trimmed.isEmpty) {
      if (type == 'image' || type == 'photo') return '📷 Photo';
      if (type == 'video') return '🎥 Video';
      if (type == 'audio' || type == 'voice') return '🎵 Audio';
      if (type == 'document' || type == 'file' || type == 'pdf') return _formatDisplayFileName(fileName ?? 'Document');
    }

    return trimmed;
  }

  String _formatDisplayFileName(String rawName) {
    final trimmed = rawName.trim();
    if (_isRawMediaFileName(trimmed)) {
      if (trimmed.toLowerCase().endsWith('.pdf')) return 'Document.pdf';
      return 'Document';
    }
    return trimmed;
  }

  bool _matchesQuery(String text, String query) {
    if (query.isEmpty) return false;
    final cleanQuery = query.toLowerCase().trim();
    final cleanText = text.toLowerCase();

    if (cleanQuery.length < 3) {
      // For short 1-2 character queries, match words that start with the query
      // (e.g. "he" matches "hello", "hey", "help", "he", but not "the" or "father")
      final words = cleanText.split(RegExp(r'[\s,.:;!?/\\-_#@()\[\]]+'));
      return words.any((w) => w.startsWith(cleanQuery));
    } else {
      return cleanText.contains(cleanQuery);
    }
  }

  // ==========================================
  // QUERY-BASED SEARCH RESULTS VIEW (MATCHING SCREENSHOT)
  // ==========================================
  Widget _buildQueryResultList(List<ChatModel> chatList, bool isDark) {
    final query = _searchQuery.toLowerCase();
    final myId = getIt<StorageService>().getUserId() ?? '';

    // Handle Secret Code unlock match
    final isSecretCodeMatch = _serverSearchResponse?.isSecretCodeMatch == true;
    final lockedChats = _serverSearchResponse?.lockedChats ?? [];
    if (isSecretCodeMatch || lockedChats.isNotEmpty) {
      return _buildLockedChatsResultView(lockedChats, isDark);
    }

    // Merge server search results or local filtered items
    final rawServerMessages = _serverSearchResponse?.messages ?? [];

    // Filter server messages to remove system messages, internal URLs/hashes, and require genuine match
    final serverMessages = rawServerMessages.where((msg) {
      if (_isSystemMessageText(msg.contentText, msg.messageType)) return false;

      final convTitle = msg.conversationName;
      final sender = msg.senderName ?? '';
      final formatted = _formatDisplayContent(msg.contentText, msg.messageType, fileName: msg.fileName);
      final file = msg.fileName ?? '';

      // Match conversation title / sender name
      if (convTitle.toLowerCase().contains(query) || sender.toLowerCase().contains(query)) {
        return true;
      }

      // Match formatted readable message, caption, or file name
      return _matchesQuery(formatted, query) || _matchesQuery(file, query);
    }).toList();

    // Local matched chat last messages
    final localMatches = chatList.where((chat) {
      final name = (chat.isGroup ? (chat.groupName ?? '') : chat.recipient.displayName).toLowerCase();
      final phone = chat.recipient.phoneNumber.toLowerCase();
      final username = (chat.recipient.username ?? '').toLowerCase();

      if (name.contains(query) || phone.contains(query) || username.contains(query)) {
        return true;
      }

      final rawMsg = chat.lastMessage?.content ?? '';
      final msgType = chat.lastMessage?.mediaType ?? '';
      if (_isSystemMessageText(rawMsg, msgType)) {
        return false;
      }

      final formatted = _formatDisplayContent(rawMsg, msgType);
      return _matchesQuery(formatted, query);
    }).toList();

    // If server has returned messages, show server results + local chats
    if (serverMessages.isNotEmpty) {
      return ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        itemCount: serverMessages.length,
        separatorBuilder: (context, index) => const SizedBox(height: 20),
        itemBuilder: (context, index) {
          final msg = serverMessages[index];
          final chat = chatList.firstWhere(
            (c) => c.id == msg.conversationId,
            orElse: () => ChatModel(
              id: msg.conversationId,
              isGroup: msg.isGroup,
              groupName: msg.conversationName,
              recipient: RecipientModel(
                id: msg.senderId,
                contactName: msg.conversationName,
                profilePictureUrl: msg.conversationPictureUrl,
              ),
            ),
          );

          return _buildQueryMessageItem(
            chat: chat,
            conversationTitle: msg.conversationName.isNotEmpty ? msg.conversationName : (chat.isGroup ? (chat.groupName ?? 'Group') : chat.recipient.displayName),
            messageId: msg.id,
            senderName: msg.senderName,
            senderId: msg.senderId,
            myId: myId,
            isGroup: msg.isGroup || chat.isGroup,
            contentText: msg.contentText,
            mediaType: msg.messageType,
            mediaUrl: _resolveMediaUrl(msg.mediaUrl),
            fileName: msg.fileName,
            fileSize: msg.fileSize,
            timestamp: msg.createdAt > 0 ? msg.createdAt : chat.updatedAt,
            query: _searchQuery,
            isDark: isDark,
          );
        },
      );
    }

    if (localMatches.isEmpty && !_isSearchingServer) {
      return _buildEmptyState(isDark);
    }

    // Render local matches instantly while server loads
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: localMatches.length,
      separatorBuilder: (context, index) => const SizedBox(height: 20),
      itemBuilder: (context, index) {
        final chat = localMatches[index];
        final name = chat.isGroup
            ? (chat.groupName ?? 'Group')
            : chat.recipient.displayName;

        final rawContent = chat.lastMessage?.content ?? chat.groupDescription ?? '';
        final mediaType = (chat.lastMessage?.mediaType ?? '').toLowerCase();
        final rawUrl = chat.lastMessage?.mediaUrl ?? '';
        final resolvedUrl = _resolveMediaUrl(rawUrl);

        return _buildQueryMessageItem(
          chat: chat,
          conversationTitle: name,
          messageId: chat.lastMessage?.id,
          senderName: chat.recipient.displayName,
          senderId: chat.lastMessage?.senderId ?? '',
          myId: myId,
          isGroup: chat.isGroup,
          contentText: rawContent,
          mediaType: mediaType,
          mediaUrl: resolvedUrl,
          fileName: rawContent.endsWith('.pdf') || mediaType == 'pdf' || mediaType == 'document' ? rawContent : null,
          fileSize: null,
          timestamp: chat.lastMessage?.createdAt ?? chat.updatedAt,
          query: _searchQuery,
          isDark: isDark,
        );
      },
    );
  }

  Widget _buildQueryMessageItem({
    required ChatModel chat,
    required String conversationTitle,
    String? messageId,
    required String? senderName,
    required String senderId,
    required String myId,
    required bool isGroup,
    required String contentText,
    required String mediaType,
    required String? mediaUrl,
    required String? fileName,
    required String? fileSize,
    required dynamic timestamp,
    required String query,
    required bool isDark,
  }) {
    final bool isMe = senderId.isNotEmpty && senderId == myId;
    final String timeStr = _formatMessageTime(timestamp);

    // Prefix construction
    String prefix = '';
    if (isMe) {
      prefix = 'You: ';
    } else if (isGroup && senderName != null && senderName.isNotEmpty) {
      prefix = '~ $senderName: ';
    }

    final displayContent = _formatDisplayContent(contentText, mediaType, fileName: fileName);

    final isPdfOrDoc = mediaType == 'pdf' ||
        mediaType == 'document' ||
        mediaType == 'file' ||
        contentText.toLowerCase().endsWith('.pdf') ||
        (fileName != null && fileName.toLowerCase().endsWith('.pdf'));

    final isMedia = (mediaType == 'image' || mediaType == 'photo' || mediaType == 'video') &&
        mediaUrl != null &&
        mediaUrl.isNotEmpty;

    return InkWell(
      onTap: () => _openChat(chat, conversationTitle, targetMessageId: messageId),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Chat Name + Timestamp
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    conversationTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF111827),
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  timeStr,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.white54 : const Color(0xFF6B7280),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),

            // Content Row
            if (isPdfOrDoc)
              _buildDocumentQueryCard(
                fileName: _formatDisplayFileName(fileName ?? contentText),
                fileSize: fileSize ?? '193 kB',
                query: query,
                isDark: isDark,
              )
            else if (isMedia)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildHighlightedText(
                      text: '$prefix$displayContent',
                      query: query,
                      baseStyle: TextStyle(
                        color: isDark ? Colors.white70 : const Color(0xFF4B5563),
                        fontSize: 14,
                        height: 1.35,
                      ),
                      highlightStyle: TextStyle(
                        backgroundColor: const Color(0xFFFFEB3B).withValues(alpha: 0.60),
                        color: const Color(0xFF111827),
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                        height: 1.35,
                      ),
                      maxLines: 4,
                    ),
                  ),
                  const SizedBox(width: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      imageUrl: mediaUrl,
                      width: 64,
                      height: 64,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        width: 64,
                        height: 64,
                        color: isDark ? Colors.white10 : Colors.black12,
                        child: const Icon(Icons.photo_outlined, size: 22, color: Colors.white38),
                      ),
                      errorWidget: (context, url, error) => Container(
                        width: 64,
                        height: 64,
                        color: isDark ? Colors.white10 : Colors.black12,
                        child: const Icon(Icons.photo_outlined, size: 22, color: Colors.white38),
                      ),
                    ),
                  ),
                ],
              )
            else
              _buildHighlightedText(
                text: '$prefix$displayContent',
                query: query,
                baseStyle: TextStyle(
                  color: isDark ? Colors.white70 : const Color(0xFF4B5563),
                  fontSize: 14,
                  height: 1.35,
                ),
                highlightStyle: TextStyle(
                  backgroundColor: const Color(0xFFFFEB3B).withValues(alpha: 0.60),
                  color: const Color(0xFF111827),
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                  height: 1.35,
                ),
                maxLines: 4,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentQueryCard({
    required String fileName,
    required String fileSize,
    required String query,
    required bool isDark,
  }) {
    return Container(
      margin: const EdgeInsets.only(top: 4, bottom: 2),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1B2028) : const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFE53935),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text(
              'PDF',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHighlightedText(
                  text: fileName,
                  query: query,
                  baseStyle: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  highlightStyle: TextStyle(
                    color: isDark ? Colors.white : Colors.black,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                  maxLines: 1,
                ),
                const SizedBox(height: 3),
                Text(
                  fileSize.isNotEmpty ? '$fileSize · PDF' : '193 kB · PDF',
                  style: TextStyle(
                    color: isDark ? Colors.white54 : const Color(0xFF6B7280),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHighlightedText({
    required String text,
    required String query,
    required TextStyle baseStyle,
    TextStyle? highlightStyle,
    int maxLines = 3,
  }) {
    if (query.isEmpty) {
      return Text(text, style: baseStyle, maxLines: maxLines, overflow: TextOverflow.ellipsis);
    }

    final matches = RegExp(RegExp.escape(query), caseSensitive: false).allMatches(text);
    if (matches.isEmpty) {
      return Text(text, style: baseStyle, maxLines: maxLines, overflow: TextOverflow.ellipsis);
    }

    final effectiveHighlightStyle = highlightStyle ??
        baseStyle.copyWith(
          backgroundColor: const Color(0xFFFFEB3B).withValues(alpha: 0.60),
          color: const Color(0xFF111827),
          fontWeight: FontWeight.w800,
        );

    final List<TextSpan> spans = [];
    int lastEnd = 0;

    for (final match in matches) {
      if (match.start > lastEnd) {
        spans.add(TextSpan(text: text.substring(lastEnd, match.start), style: baseStyle));
      }
      spans.add(TextSpan(text: text.substring(match.start, match.end), style: effectiveHighlightStyle));
      lastEnd = match.end;
    }

    if (lastEnd < text.length) {
      spans.add(TextSpan(text: text.substring(lastEnd), style: baseStyle));
    }

    return RichText(
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(children: spans),
    );
  }

  String _formatMessageTime(dynamic timestamp) {
    if (timestamp == null) return '';
    DateTime? dt;
    if (timestamp is int) {
      if (timestamp <= 0) return '';
      dt = DateTime.fromMillisecondsSinceEpoch(
        timestamp > 10000000000 ? timestamp : timestamp * 1000,
      ).toLocal();
    } else if (timestamp is String) {
      if (timestamp.isEmpty) return '';
      final parsedInt = int.tryParse(timestamp);
      if (parsedInt != null) {
        dt = DateTime.fromMillisecondsSinceEpoch(
          timestamp.length <= 10 ? parsedInt * 1000 : parsedInt,
        ).toLocal();
      } else {
        try {
          dt = DateTime.parse(timestamp).toLocal();
        } catch (_) {}
      }
    }

    if (dt == null) return '';

    final now = DateTime.now();
    final isToday = dt.year == now.year && dt.month == now.month && dt.day == now.day;
    final yesterday = now.subtract(const Duration(days: 1));
    final isYesterday = dt.year == yesterday.year && dt.month == yesterday.month && dt.day == yesterday.day;

    if (isToday) {
      int hour = dt.hour;
      final ampm = hour >= 12 ? 'pm' : 'am';
      hour = hour % 12;
      if (hour == 0) hour = 12;
      final min = dt.minute.toString().padLeft(2, '0');
      return '$hour:$min $ampm';
    } else if (isYesterday) {
      return 'Yesterday';
    } else {
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${dt.day} ${months[dt.month - 1]}';
    }
  }

  static final RegExp _urlRegex = RegExp(
    r'(https?://[^\s]+|www\.[^\s]+|[a-zA-Z0-9.-]+\.(?:com|org|net|in|io|co|ai|dev|app|edu|gov|tech|xyz|me|info|biz|online|site|store|live|cloud|link)\b(?:/[^\s]*)?)',
    caseSensitive: false,
  );

  List<ChatModel> _filterChats(List<ChatModel> chatList) {
    return chatList.where((chat) {
      // 1. Filter by category
      if (_selectedFilter == 'Unread' && chat.unreadCount <= 0) {
        return false;
      }
      if (_selectedFilter == 'Groups' && !chat.isGroup) {
        return false;
      }
      if (_selectedFilter == 'Photos') {
        final type = (chat.lastMessage?.mediaType ?? '').toLowerCase();
        if (type != 'image' && type != 'photo') return false;
      }
      if (_selectedFilter == 'Videos') {
        final type = (chat.lastMessage?.mediaType ?? '').toLowerCase();
        if (type != 'video') return false;
      }
      if (_selectedFilter == 'Links') {
        final mediaType = (chat.lastMessage?.mediaType ?? '').toLowerCase();
        if (mediaType == 'image' ||
            mediaType == 'photo' ||
            mediaType == 'video' ||
            mediaType == 'audio' ||
            mediaType == 'voice' ||
            mediaType == 'file' ||
            mediaType == 'document' ||
            mediaType == 'pdf') {
          return false;
        }

        final content = chat.lastMessage?.content ?? '';
        final hasUrlInContent = _urlRegex.hasMatch(content) ||
            content.toLowerCase().contains('http://') ||
            content.toLowerCase().contains('https://') ||
            content.toLowerCase().contains('www.');
        final isLinkType = mediaType == 'link' || mediaType == 'url';

        if (!hasUrlInContent && !isLinkType) return false;
      }
      if (_selectedFilter == 'Audio') {
        final type = (chat.lastMessage?.mediaType ?? '').toLowerCase();
        if (type != 'audio' && type != 'voice') return false;
      }
      if (_selectedFilter == 'Documents') {
        final type = (chat.lastMessage?.mediaType ?? '').toLowerCase();
        if (type != 'file' && type != 'document' && type != 'pdf' && type != 'doc' && type != 'docx' && type != 'zip') return false;
      }

      return true;
    }).toList();
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF3F4F6),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.search_off_rounded,
              size: 36,
              color: isDark ? Colors.white38 : const Color(0xFF9CA3AF),
            ),
          ),
          CommonSpaces.h16,
          Text(
            _searchQuery.isNotEmpty
                ? 'No chats or messages matching "$_searchQuery"'
                : 'No ${_selectedFilter.toLowerCase()} conversations found',
            style: TextStyle(
              color: context.colors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          CommonSpaces.h8,
          Text(
            'Try searching with a different name, message, or keyword',
            style: TextStyle(
              color: isDark ? Colors.white38 : const Color(0xFF6B7280),
              fontSize: 13.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatList(List<ChatModel> visibleChats, bool isDark) {
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(top: 6, bottom: 40),
      itemCount: visibleChats.length,
      separatorBuilder: (context, index) => Divider(
        height: 1,
        thickness: 0.6,
        indent: 84,
        endIndent: 20,
        color: isDark
            ? Colors.white.withValues(alpha: 0.08)
            : const Color(0xFFF0F0F0),
      ),
      itemBuilder: (context, index) {
        final chat = visibleChats[index];
        final name = chat.isGroup
            ? (chat.groupName ?? 'Group')
            : chat.recipient.displayName;

        final String rawMessage;
        if (chat.isTyping) {
          rawMessage = 'typing...';
        } else if (chat.lastMessage != null && chat.lastMessage!.isDeleted) {
          final myId = getIt<StorageService>().getUserId() ?? '';
          final isMe = chat.lastMessage!.senderId == myId;
          rawMessage = isMe ? 'You deleted this message' : 'This message was deleted';
        } else {
          rawMessage = chat.lastMessage?.content ?? chat.groupDescription ?? 'No messages yet';
        }

        final message = chat.isTyping
            ? 'typing...'
            : _formatDisplayContent(
                rawMessage,
                chat.lastMessage?.mediaType ?? '',
              );

        return _buildChatTile(
          chat: chat,
          name: name,
          message: message,
          isDark: isDark,
        );
      },
    );
  }

  Widget _buildChatTile({
    required ChatModel chat,
    required String name,
    required String message,
    required bool isDark,
  }) {
    return InkWell(
      onTap: () => _openChat(chat, name, targetMessageId: chat.lastMessage?.id),
      child: Container(
        color: Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            _buildAvatar(chat, isDark),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildHighlightedText(
                    text: name,
                    query: _searchQuery,
                    baseStyle: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: context.colors.textPrimary,
                      letterSpacing: -0.2,
                    ),
                    maxLines: 1,
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      if (_urlRegex.hasMatch(message) ||
                          message.toLowerCase().contains('http') ||
                          message.toLowerCase().contains('www.'))
                        Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: Icon(
                            Icons.link_rounded,
                            size: 14,
                            color: isDark ? const Color(0xFF00FF87) : const Color(0xFF00873C),
                          ),
                        ),
                      Expanded(
                        child: _buildHighlightedText(
                          text: message,
                          query: _searchQuery,
                          baseStyle: TextStyle(
                            color: chat.isTyping
                                ? (isDark ? const Color(0xFF00FF87) : const Color(0xFF00873C))
                                : (isDark ? Colors.white54 : const Color(0xFF6B7280)),
                            fontSize: 13.5,
                            fontWeight: chat.isTyping
                                ? FontWeight.w600
                                : (chat.unreadCount > 0 ? FontWeight.w600 : FontWeight.w400),
                            fontStyle: chat.isTyping ? FontStyle.italic : FontStyle.normal,
                          ),
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            _buildChatStatus(chat, isDark),
          ],
        ),
      ),
    );
  }

  void _openChat(ChatModel chat, String name, {String? targetMessageId}) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatPage(
          conversationId: chat.id,
          contactName: name,
          contactColor: context.colors.primary,
          isOnline: chat.recipient.isOnline,
          profilePictureUrl: chat.recipient.profilePictureUrl,
          recipientId: chat.recipient.id,
          isGroup: chat.isGroup,
          initialThemeColor: chat.themeColor,
          initialDisappearingTimer: chat.disappearingTimer,
          initialReadReceiptsEnabled: chat.readReceiptsEnabled,
          initialTypingIndicatorsEnabled: chat.typingIndicatorsEnabled,
          initialTargetMessageId: targetMessageId,
          initialSearchQuery: _searchQuery.isNotEmpty ? _searchQuery : null,
        ),
      ),
    );
    if (mounted) {
      context.read<ChatsBloc>().add(const FetchChats());
    }
  }

  Widget _buildAvatar(ChatModel chat, bool isDark) {
    final isGroup = chat.isGroup;
    final primaryColor = isDark ? const Color(0xFF00FF87) : const Color(0xFF00873C);
    final avatarBg = isDark ? const Color(0xFF1E3A2B) : const Color(0xFFD1FADF);

    if (isGroup) {
      final groupPic = chat.recipient.profilePictureUrl;
      if (groupPic != null && groupPic.isNotEmpty) {
        return Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: avatarBg,
            shape: BoxShape.circle,
          ),
          child: ClipOval(
            child: CachedNetworkImage(
              imageUrl: groupPic,
              fit: BoxFit.cover,
              placeholder: (context, url) => Center(
                child: Icon(Icons.group_rounded, color: primaryColor, size: 24),
              ),
              errorWidget: (context, url, error) => Center(
                child: Icon(Icons.group_rounded, color: primaryColor, size: 24),
              ),
            ),
          ),
        );
      }

      return SizedBox(
        width: 48,
        height: 48,
        child: Stack(
          children: [
            Positioned(
              left: 2,
              top: 2,
              child: _buildSmallAvatar(primaryColor.withValues(alpha: 0.25), '👨🏻‍💻'),
            ),
            Positioned(
              right: 2,
              top: 2,
              child: _buildSmallAvatar(context.colors.pinkAccent.withValues(alpha: 0.25), '👩🏼‍💻'),
            ),
            Positioned(
              left: 2,
              bottom: 2,
              child: _buildSmallAvatar(context.colors.orangeAccent.withValues(alpha: 0.25), '👨🏽‍💻'),
            ),
            Positioned(
              right: 2,
              bottom: 2,
              child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: primaryColor,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: context.colors.scaffoldBackground,
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Text(
                    '+3',
                    style: TextStyle(
                      color: isDark ? Colors.black : Colors.white,
                      fontSize: 8.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    final avatarUrl = chat.recipient.profilePictureUrl;
    if (avatarUrl != null && avatarUrl.isNotEmpty) {
      return Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: avatarBg,
          shape: BoxShape.circle,
        ),
        child: ClipOval(
          child: CachedNetworkImage(
            imageUrl: avatarUrl,
            fit: BoxFit.cover,
            placeholder: (context, url) => Center(
              child: Text(
                chat.recipient.displayName.isNotEmpty ? chat.recipient.displayName[0].toUpperCase() : '?',
                style: TextStyle(
                  color: primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
            errorWidget: (context, url, error) => Center(
              child: Text(
                chat.recipient.displayName.isNotEmpty ? chat.recipient.displayName[0].toUpperCase() : '?',
                style: TextStyle(
                  color: primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: avatarBg,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          chat.recipient.displayName.isNotEmpty ? chat.recipient.displayName[0].toUpperCase() : '?',
          style: TextStyle(
            color: primaryColor,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
    );
  }

  Widget _buildSmallAvatar(Color bgColor, String emoji) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          emoji,
          style: const TextStyle(fontSize: 11),
        ),
      ),
    );
  }

  Widget _buildChatStatus(ChatModel chat, bool isDark) {
    final timestamp = chat.lastMessage?.createdAt ?? chat.updatedAt;
    final timeStr = _formatMessageTime(timestamp);
    final primaryColor = isDark ? const Color(0xFF00FF87) : const Color(0xFF00873C);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          timeStr,
          style: TextStyle(
            fontSize: 12,
            color: isDark ? Colors.white54 : const Color(0xFF6B7280),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        if (chat.unreadCount > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: primaryColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              chat.unreadCount.toString(),
              style: TextStyle(
                color: isDark ? Colors.black : Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          )
        else
          _buildMessageStatusIcon(chat, isDark),
      ],
    );
  }

  Widget _buildMessageStatusIcon(ChatModel chat, bool isDark) {
    final lastMsg = chat.lastMessage;
    if (lastMsg == null || lastMsg.id.isEmpty) {
      return const SizedBox.shrink();
    }

    final myId = getIt.isRegistered<StorageService>() ? (getIt<StorageService>().getUserId() ?? '') : '';
    final isMe = myId.isNotEmpty && lastMsg.senderId == myId;

    // Incoming messages do not show sent status ticks
    if (!isMe) {
      return const SizedBox.shrink();
    }

    final greyColor = isDark ? Colors.white54 : const Color(0xFF9CA3AF);
    const blueColor = Color(0xFF34B7F1);

    if (lastMsg.isRead || lastMsg.status?.toLowerCase() == 'read') {
      return const Icon(
        Icons.done_all_rounded,
        color: blueColor,
        size: 16,
      );
    }

    if (lastMsg.isDelivered || lastMsg.status?.toLowerCase() == 'delivered') {
      return Icon(
        Icons.done_all_rounded,
        color: greyColor,
        size: 16,
      );
    }

    return Icon(
      Icons.done_rounded,
      color: greyColor,
      size: 16,
    );
  }

  String _resolveMediaUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    String url = path;
    if (url.contains('minio')) {
      try {
        final serverUri = Uri.parse(CommonEndpoints.baseUrl);
        final host = serverUri.host;
        if (host.isNotEmpty) {
          url = url.replaceAll('minio', host);
        }
      } catch (_) {}
    }
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      String s3BaseUrl;
      try {
        final serverUri = Uri.parse(CommonEndpoints.baseUrl);
        final host = serverUri.host;
        if (host.isNotEmpty && !host.contains('amazonaws.com')) {
          s3BaseUrl = 'http://$host:9000/qlyncs-docs/';
        } else {
          s3BaseUrl = 'https://qlyncs-docs.s3.amazonaws.com/';
        }
      } catch (_) {
        s3BaseUrl = 'https://qlyncs-docs.s3.amazonaws.com/';
      }
      url = '$s3BaseUrl$url';
    }
    return url;
  }

  Widget _buildMediaGrid(List<ChatModel> visibleChats, bool isDark, String filterType) {
    final double childAspectRatio = filterType == 'Audio' ? 1.15 : 0.82;
    return GridView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 40),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: childAspectRatio,
      ),
      itemCount: visibleChats.length,
      itemBuilder: (context, index) {
        final chat = visibleChats[index];
        final name = chat.isGroup
            ? (chat.groupName ?? 'Group')
            : chat.recipient.displayName;

        if (filterType == 'Photos') {
          return _buildPhotoGridTile(chat, name, isDark);
        } else if (filterType == 'Videos') {
          return _buildVideoGridTile(chat, name, isDark);
        } else {
          return _buildAudioGridTile(chat, name, isDark);
        }
      },
    );
  }

  Widget _buildPhotoGridTile(ChatModel chat, String name, bool isDark) {
    final rawUrl = chat.lastMessage?.mediaUrl ?? '';
    final resolvedUrl = _resolveMediaUrl(rawUrl);
    final cardBg = isDark ? const Color(0xFF1B2420) : Colors.white;
    final borderColor = isDark ? Colors.white12 : const Color(0xFFE5E9E7);
    final timestamp = chat.lastMessage?.createdAt ?? chat.updatedAt;
    final timeStr = _formatMessageTime(timestamp);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _openChat(chat, name, targetMessageId: chat.lastMessage?.id),
        child: Container(
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: resolvedUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: resolvedUrl,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFE5E7EB),
                          child: const Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: isDark ? const Color(0xFF16201B) : const Color(0xFFE5E7EB),
                          child: const Icon(Icons.broken_image_outlined, color: Colors.grey),
                        ),
                      )
                    : Container(
                        color: isDark ? const Color(0xFF16201B) : const Color(0xFFE5E7EB),
                        child: const Icon(Icons.photo_outlined, color: Colors.grey, size: 36),
                      ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),
                    Text(
                      timeStr,
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.white54 : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVideoGridTile(ChatModel chat, String name, bool isDark) {
    final rawUrl = chat.lastMessage?.mediaUrl ?? '';
    final resolvedUrl = _resolveMediaUrl(rawUrl);
    final cardBg = isDark ? const Color(0xFF1B2420) : Colors.white;
    final borderColor = isDark ? Colors.white12 : const Color(0xFFE5E9E7);
    final timestamp = chat.lastMessage?.createdAt ?? chat.updatedAt;
    final timeStr = _formatMessageTime(timestamp);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _openChat(chat, name, targetMessageId: chat.lastMessage?.id),
        child: Container(
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    resolvedUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: resolvedUrl,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFE5E7EB),
                            ),
                            errorWidget: (context, url, error) => Container(
                              color: isDark ? const Color(0xFF16201B) : const Color(0xFFE5E7EB),
                              child: const Icon(Icons.videocam_outlined, color: Colors.grey, size: 36),
                            ),
                          )
                        : Container(
                            color: isDark ? const Color(0xFF16201B) : const Color(0xFFE5E7EB),
                            child: const Icon(Icons.videocam_outlined, color: Colors.grey, size: 36),
                          ),
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 28),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),
                    Text(
                      timeStr,
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.white54 : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAudioGridTile(ChatModel chat, String name, bool isDark) {
    final cardBg = isDark ? const Color(0xFF1B2420) : Colors.white;
    final borderColor = isDark ? Colors.white12 : const Color(0xFFE5E9E7);
    final timestamp = chat.lastMessage?.createdAt ?? chat.updatedAt;
    final timeStr = _formatMessageTime(timestamp);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _openChat(chat, name, targetMessageId: chat.lastMessage?.id),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: (isDark ? const Color(0xFF00FF87) : const Color(0xFF00873C)).withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.audiotrack_rounded,
                      color: isDark ? const Color(0xFF00FF87) : const Color(0xFF00873C),
                      size: 20,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    timeStr,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? Colors.white54 : Colors.grey,
                    ),
                  ),
                ],
              ),
              Text(
                chat.lastMessage?.content ?? 'Voice Note',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11.5,
                  color: isDark ? Colors.white54 : const Color(0xFF6B7280),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLinksList(List<ChatModel> visibleChats, bool isDark) {
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
      itemCount: visibleChats.length,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final chat = visibleChats[index];
        final name = chat.isGroup
            ? (chat.groupName ?? 'Group')
            : chat.recipient.displayName;

        return _buildLinkCard(chat, name, isDark);
      },
    );
  }

  Widget _buildLinkCard(ChatModel chat, String name, bool isDark) {
    final rawContent = chat.lastMessage?.content ?? '';
    final cardBg = isDark ? const Color(0xFF1B2420) : Colors.white;
    final borderColor = isDark ? Colors.white12 : const Color(0xFFE5E9E7);
    final timestamp = chat.lastMessage?.createdAt ?? chat.updatedAt;
    final timeStr = _formatMessageTime(timestamp);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _openChat(chat, name, targetMessageId: chat.lastMessage?.id),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor, width: 1),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: (isDark ? const Color(0xFF00FF87) : const Color(0xFF00873C)).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.link_rounded,
                  color: isDark ? const Color(0xFF00FF87) : const Color(0xFF00873C),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          name,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        Text(
                          timeStr,
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? Colors.white54 : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      rawContent,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13.5,
                        color: isDark ? const Color(0xFF00FF87) : const Color(0xFF00873C),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDocumentsList(List<ChatModel> visibleChats, bool isDark) {
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
      itemCount: visibleChats.length,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final chat = visibleChats[index];
        final name = chat.isGroup
            ? (chat.groupName ?? 'Group')
            : chat.recipient.displayName;

        return _buildDocumentCard(chat, name, isDark);
      },
    );
  }

  Widget _buildDocumentCard(ChatModel chat, String name, bool isDark) {
    final rawContent = chat.lastMessage?.content ?? 'Document';
    final cardBg = isDark ? const Color(0xFF1B2420) : Colors.white;
    final borderColor = isDark ? Colors.white12 : const Color(0xFFE5E9E7);
    final timestamp = chat.lastMessage?.createdAt ?? chat.updatedAt;
    final timeStr = _formatMessageTime(timestamp);
    final displayFileName = _formatDisplayFileName(rawContent);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _openChat(chat, name, targetMessageId: chat.lastMessage?.id),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor, width: 1),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFE53935),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'PDF',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayFileName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '$name · $timeStr',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white54 : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLockedChatsResultView(List<SearchChatItem> lockedChats, bool isDark) {
    final primaryColor = isDark ? const Color(0xFF00FF87) : const Color(0xFF00873C);

    if (lockedChats.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E3A2B) : const Color(0xFFD1FADF),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.lock_open_rounded, color: primaryColor, size: 36),
            ),
            const SizedBox(height: 16),
            Text(
              'Secret Code Recognized',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: context.colors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'No locked chats found for this code',
              style: TextStyle(
                fontSize: 14,
                color: context.colors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.lock_rounded, size: 14, color: primaryColor),
                    const SizedBox(width: 5),
                    Text(
                      'Locked Chats (${lockedChats.length})',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                'Secret Code Unlocked',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: context.colors.textHint,
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        ...lockedChats.map((chat) => _buildLockedChatItem(chat, isDark)),
      ],
    );
  }

  Widget _buildLockedChatItem(SearchChatItem item, bool isDark) {
    final primaryColor = isDark ? const Color(0xFF00FF87) : const Color(0xFF00873C);
    final avatarBg = isDark ? const Color(0xFF1E3A2B) : const Color(0xFFD1FADF);
    final displayName = _resolveContactDisplayName(item);
    final messageSnippet = (item.lastMessageSnippet != null && item.lastMessageSnippet!.trim().isNotEmpty)
        ? item.lastMessageSnippet!.trim()
        : 'Locked conversation';

    return InkWell(
      onTap: () => _openSearchChatItem(item),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            Stack(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: avatarBg,
                    shape: BoxShape.circle,
                  ),
                  child: item.pictureUrl != null && item.pictureUrl!.isNotEmpty
                      ? ClipOval(
                          child: CachedNetworkImage(
                            imageUrl: item.pictureUrl!,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Center(
                              child: Icon(item.isGroup ? Icons.group_rounded : Icons.person_rounded, color: primaryColor, size: 26),
                            ),
                            errorWidget: (context, url, error) => Center(
                              child: Icon(item.isGroup ? Icons.group_rounded : Icons.person_rounded, color: primaryColor, size: 26),
                            ),
                          ),
                        )
                      : Center(
                          child: Icon(
                            item.isGroup ? Icons.group_rounded : Icons.person_rounded,
                            color: primaryColor,
                            size: 26,
                          ),
                        ),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1F2937) : Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Color(0xFF00873C),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.lock_rounded, size: 10, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: context.colors.textPrimary,
                          ),
                        ),
                      ),
                      if (item.updatedAt != null || item.lastMessageTimestamp != null)
                        Text(
                          _formatLockedChatTime(item.lastMessageTimestamp ?? item.updatedAt ?? 0),
                          style: TextStyle(
                            fontSize: 12,
                            color: context.colors.textHint,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          messageSnippet,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: isDark ? Colors.white54 : const Color(0xFF6B7280),
                            fontSize: 13.5,
                          ),
                        ),
                      ),
                      if (item.unreadCount > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: primaryColor,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${item.unreadCount}',
                            style: TextStyle(
                              color: isDark ? Colors.black : Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _resolveContactDisplayName(SearchChatItem item) {
    if (item.isGroup) return item.name;
    try {
      final contactsState = context.read<ContactsBloc>().state;
      if (contactsState is ContactsLoaded) {
        final phone = item.phoneNumber ?? '';
        final cleanPhone = phone.replaceAll(RegExp(r'\D'), '');
        final matched = contactsState.syncedContacts.firstWhereOrNull((u) {
          final uPhone = u.phoneNumber.replaceAll(RegExp(r'\D'), '');
          if (cleanPhone.isNotEmpty && uPhone.isNotEmpty) {
            return uPhone == cleanPhone || uPhone.endsWith(cleanPhone) || cleanPhone.endsWith(uPhone);
          }
          return u.id.isNotEmpty && u.id == item.id;
        });
        if (matched != null && matched.displayName.isNotEmpty) {
          return matched.displayName;
        }
      }
    } catch (_) {}
    return item.name;
  }

  void _openSearchChatItem(SearchChatItem item) async {
    final displayName = _resolveContactDisplayName(item);
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatPage(
          conversationId: item.id,
          contactName: displayName,
          contactColor: context.colors.primary,
          isOnline: false,
          profilePictureUrl: item.pictureUrl,
          recipientId: item.id,
          isGroup: item.isGroup,
          initialIsLocked: true,
          initialSearchQuery: _searchQuery.isNotEmpty ? _searchQuery : null,
        ),
      ),
    );
    if (mounted) {
      context.read<ChatsBloc>().add(const FetchChats());
    }
  }

  String _formatLockedChatTime(int timestamp) {
    if (timestamp <= 0) return '';
    final dt = DateTime.fromMillisecondsSinceEpoch(
      timestamp < 10000000000 ? timestamp * 1000 : timestamp,
    );
    final now = DateTime.now();
    if (dt.day == now.day && dt.month == now.month && dt.year == now.year) {
      final hour = dt.hour.toString().padLeft(2, '0');
      final minute = dt.minute.toString().padLeft(2, '0');
      return '$hour:$minute';
    }
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}

