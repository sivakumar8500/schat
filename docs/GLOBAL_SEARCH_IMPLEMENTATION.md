# Home Screen Global Search Implementation Guide

This document provides the complete end-to-end technical implementation guide for the **Home Screen Global Search** in SChat (Flutter Frontend & FastAPI Backend).

---

## 📑 Table of Contents
1. [Architecture Overview](#1-architecture-overview)
2. [API Contract & Endpoints](#2-api-contract--endpoints)
3. [Flutter Frontend Data Layer](#3-flutter-frontend-data-layer)
4. [Flutter BLoC State Management](#4-flutter-bloc-state-management)
5. [Presentation Layer & UI Components](#5-presentation-layer--ui-components)
6. [Search Result Navigation & Deep Linking](#6-search-result-navigation--deep-linking)
7. [Testing & Performance Optimizations](#7-testing--performance-optimizations)

---

## 1. Architecture Overview

Global Search provides a unified, WhatsApp-style search experience from the top of the Home/Dashboard Screen.

```
┌────────────────────────────────────────────────────────────────────────┐
│                        Dashboard Search Bar                            │
│  [ 🔍 Search chats, contacts, messages...                    [ ✕ ] ]   │
├────────────────────────────────────────────────────────────────────────┤
│  (All)  (Unread)  (Photos)  (Videos)  (Links)  (Audio)  (Documents)   │
└──────────────────────────────────┬─────────────────────────────────────┘
                                   │
                    ┌──────────────▼──────────────┐
                    │      SearchBloc / Cubit     │
                    │   (Debounce 300ms + Stream) │
                    └──────────────┬──────────────┘
                                   │
                    ┌──────────────▼──────────────┐
                    │     GET /api/v1/search      │
                    │  ?q=keyword&filter=photos   │
                    └──────────────┬──────────────┘
                                   │
    ┌──────────────────────────────┼──────────────────────────────┐
    ▼                              ▼                              ▼
┌──────────────┐            ┌──────────────┐            ┌──────────────┐
│    CHATS     │            │   CONTACTS   │            │   MESSAGES   │
│ Convos/Groups│            │ Saved/Shared │            │ Text/Captions│
└──────────────┘            └──────────────┘            └──────────────┘
```

---

## 2. API Contract & Endpoints

### 2.1 Unified Search Endpoint
```http
GET /api/v1/search?q={query}&filter={filter}&limit={limit}&offset={offset}
```
**Headers:**
```http
Authorization: Bearer <access_token>
Accept: application/json
```

**Query Parameters:**
| Parameter | Type | Default | Description |
| :--- | :--- | :--- | :--- |
| `q` | `string` | `""` | Search query term (case-insensitive) |
| `filter` | `string` | `"all"` | Filter pill: `all`, `unread`, `photos`, `videos`, `links`, `audio`, `documents`, `contacts`, `polls` |
| `limit` | `integer`| `20` | Results per page (1 to 100) |
| `offset` | `integer`| `0` | Pagination offset |

**Response Schema (`200 OK`):**
```json
{
  "query": "meeting",
  "filter": "all",
  "total": 5,
  "limit": 20,
  "offset": 0,
  "hasMore": false,
  "counts": {
    "chats": 1,
    "contacts": 1,
    "messages": 3,
    "total": 5
  },
  "chats": [
    {
      "id": "7f8b9e10-1234-5678-9abc-def012345678",
      "isGroup": true,
      "name": "Team Standup",
      "phoneNumber": null,
      "pictureUrl": "https://...",
      "unreadCount": 0,
      "lastMessageSnippet": "See you at 10 AM",
      "lastMessageTimestamp": 1790316800,
      "updatedAt": 1790316800
    }
  ],
  "contacts": [
    {
      "id": "10d9a863-c9f2-491b-84ff-ad960e0547c5",
      "contactName": "Meeting Coordinator (John)",
      "fullName": "John Doe",
      "phoneNumber": "+1234567890",
      "profilePictureUrl": "https://...",
      "isRegistered": true,
      "conversationId": "3b2c1d0f-4567-89ab-cdef-0123456789ab"
    }
  ],
  "messages": [
    {
      "id": "e4f8d2fc-7326-407b-8ac0-cf9964023406",
      "conversationId": "7f8b9e10-1234-5678-9abc-def012345678",
      "conversationName": "Team Standup",
      "conversationPictureUrl": "https://...",
      "conversationType": "group",
      "isGroup": true,
      "senderId": "10d9a863-c9f2-491b-84ff-ad960e0547c5",
      "senderName": "Alice",
      "type": "text",
      "content": {
        "text": "The meeting notes are available in the link."
      },
      "matchSnippet": "...meeting notes are available...",
      "extractedUrls": ["https://..."],
      "createdAt": 1790316500
    }
  ]
}
```

---

### 2.2 Filter Pills Endpoint
```http
GET /api/v1/search/filters
```
Returns available dynamic search filters with keys, labels, and icon descriptors.

---

## 3. Flutter Frontend Data Layer

### 3.1 Model Classes (`global_search_model.dart`)

```dart
class GlobalSearchResponse {
  final String query;
  final String filter;
  final int total;
  final int limit;
  final int offset;
  final bool hasMore;
  final SearchCounts counts;
  final List<SearchChat> chats;
  final List<SearchContact> contacts;
  final List<SearchMessage> messages;

  GlobalSearchResponse({
    required this.query,
    required this.filter,
    required this.total,
    required this.limit,
    required this.offset,
    required this.hasMore,
    required this.counts,
    required this.chats,
    required this.contacts,
    required this.messages,
  });

  factory GlobalSearchResponse.fromJson(Map<String, dynamic> json) {
    return GlobalSearchResponse(
      query: (json['query'] ?? '').toString(),
      filter: (json['filter'] ?? 'all').toString(),
      total: int.tryParse((json['total'] ?? 0).toString()) ?? 0,
      limit: int.tryParse((json['limit'] ?? 20).toString()) ?? 20,
      offset: int.tryParse((json['offset'] ?? 0).toString()) ?? 0,
      hasMore: json['hasMore'] ?? json['has_more'] ?? false,
      counts: SearchCounts.fromJson(json['counts'] is Map ? json['counts'] : {}),
      chats: (json['chats'] as List? ?? [])
          .map((c) => SearchChat.fromJson(Map<String, dynamic>.from(c)))
          .toList(),
      contacts: (json['contacts'] as List? ?? [])
          .map((c) => SearchContact.fromJson(Map<String, dynamic>.from(c)))
          .toList(),
      messages: (json['messages'] as List? ?? [])
          .map((m) => SearchMessage.fromJson(Map<String, dynamic>.from(m)))
          .toList(),
    );
  }
}

class SearchCounts {
  final int chats;
  final int contacts;
  final int messages;
  final int total;

  SearchCounts({
    this.chats = 0,
    this.contacts = 0,
    this.messages = 0,
    this.total = 0,
  });

  factory SearchCounts.fromJson(Map<String, dynamic> json) {
    return SearchCounts(
      chats: json['chats'] ?? 0,
      contacts: json['contacts'] ?? 0,
      messages: json['messages'] ?? 0,
      total: json['total'] ?? 0,
    );
  }
}

class SearchChat {
  final String id;
  final bool isGroup;
  final String name;
  final String? phoneNumber;
  final String? pictureUrl;
  final int unreadCount;
  final String? lastMessageSnippet;
  final int? lastMessageTimestamp;

  SearchChat({
    required this.id,
    required this.isGroup,
    required this.name,
    this.phoneNumber,
    this.pictureUrl,
    this.unreadCount = 0,
    this.lastMessageSnippet,
    this.lastMessageTimestamp,
  });

  factory SearchChat.fromJson(Map<String, dynamic> json) {
    return SearchChat(
      id: (json['id'] ?? '').toString(),
      isGroup: json['isGroup'] ?? json['is_group'] ?? false,
      name: (json['name'] ?? 'Chat').toString(),
      phoneNumber: json['phoneNumber']?.toString(),
      pictureUrl: (json['pictureUrl'] ?? json['picture_url'])?.toString(),
      unreadCount: json['unreadCount'] ?? json['unread_count'] ?? 0,
      lastMessageSnippet: json['lastMessageSnippet']?.toString(),
      lastMessageTimestamp: json['lastMessageTimestamp'] ?? json['last_message_timestamp'],
    );
  }
}

class SearchContact {
  final String id;
  final String contactName;
  final String? fullName;
  final String phoneNumber;
  final String? profilePictureUrl;
  final bool isRegistered;
  final String? conversationId;

  SearchContact({
    required this.id,
    required this.contactName,
    this.fullName,
    required this.phoneNumber,
    this.profilePictureUrl,
    this.isRegistered = true,
    this.conversationId,
  });

  factory SearchContact.fromJson(Map<String, dynamic> json) {
    return SearchContact(
      id: (json['id'] ?? '').toString(),
      contactName: (json['contactName'] ?? json['contact_name'] ?? '').toString(),
      fullName: json['fullName']?.toString(),
      phoneNumber: (json['phoneNumber'] ?? json['phone_number'] ?? '').toString(),
      profilePictureUrl: (json['profilePictureUrl'] ?? json['profile_picture_url'])?.toString(),
      isRegistered: json['isRegistered'] ?? json['is_registered'] ?? true,
      conversationId: json['conversationId']?.toString(),
    );
  }
}

class SearchMessage {
  final String id;
  final String conversationId;
  final String conversationName;
  final String? conversationPictureUrl;
  final String conversationType;
  final bool isGroup;
  final String senderId;
  final String senderName;
  final String type;
  final Map<String, dynamic> content;
  final String? matchSnippet;
  final List<String> extractedUrls;
  final int createdAt;

  SearchMessage({
    required this.id,
    required this.conversationId,
    required this.conversationName,
    this.conversationPictureUrl,
    required this.conversationType,
    required this.isGroup,
    required this.senderId,
    required this.senderName,
    required this.type,
    required this.content,
    this.matchSnippet,
    this.extractedUrls = const [],
    required this.createdAt,
  });

  factory SearchMessage.fromJson(Map<String, dynamic> json) {
    return SearchMessage(
      id: (json['id'] ?? '').toString(),
      conversationId: (json['conversationId'] ?? json['conversation_id'] ?? '').toString(),
      conversationName: (json['conversationName'] ?? json['conversation_name'] ?? 'Chat').toString(),
      conversationPictureUrl: json['conversationPictureUrl']?.toString(),
      conversationType: (json['conversationType'] ?? 'direct').toString(),
      isGroup: json['isGroup'] ?? json['is_group'] ?? false,
      senderId: (json['senderId'] ?? json['sender_id'] ?? '').toString(),
      senderName: (json['senderName'] ?? json['sender_name'] ?? '').toString(),
      type: (json['type'] ?? 'text').toString(),
      content: json['content'] is Map ? Map<String, dynamic>.from(json['content']) : {},
      matchSnippet: json['matchSnippet']?.toString(),
      extractedUrls: (json['extractedUrls'] as List? ?? []).map((e) => e.toString()).toList(),
      createdAt: json['createdAt'] ?? json['created_at'] ?? 0,
    );
  }
}
```

---

## 4. Flutter BLoC State Management

### 4.1 Search Events & States (`search_bloc.dart`)

```dart
// Events
abstract class SearchEvent extends Equatable {
  const SearchEvent();
  @override
  List<Object?> get props => [];
}

class QueryChangedEvent extends SearchEvent {
  final String query;
  final String? filter;
  const QueryChangedEvent({required this.query, this.filter});
  @override
  List<Object?> get props => [query, filter];
}

class FilterChangedEvent extends SearchEvent {
  final String filter;
  const FilterChangedEvent({required this.filter});
  @override
  List<Object?> get props => [filter];
}

class ClearSearchEvent extends SearchEvent {}

// States
abstract class SearchState extends Equatable {
  const SearchState();
  @override
  List<Object?> get props => [];
}

class SearchInitial extends SearchState {}

class SearchLoading extends SearchState {
  final String query;
  final String filter;
  const SearchLoading({required this.query, required this.filter});
  @override
  List<Object?> get props => [query, filter];
}

class SearchSuccess extends SearchState {
  final GlobalSearchResponse response;
  const SearchSuccess({required this.response});
  @override
  List<Object?> get props => [response];
}

class SearchEmpty extends SearchState {
  final String query;
  final String filter;
  const SearchEmpty({required this.query, required this.filter});
  @override
  List<Object?> get props => [query, filter];
}

class SearchError extends SearchState {
  final String message;
  const SearchError({required this.message});
  @override
  List<Object?> get props => [message];
}
```

### 4.2 Debouncing Implementation with RxDart / Stream Transformers

```dart
EventTransformer<E> debounce<E>(Duration duration) {
  return (events, mapper) => events.debounceTime(duration).switchMap(mapper);
}

// In SearchBloc constructor:
on<QueryChangedEvent>(
  _onQueryChanged,
  transformer: debounce(const Duration(milliseconds: 300)),
);
```

---

## 5. Presentation Layer & UI Components

### 5.1 WhatsApp Filter Chips Row
Render a horizontal carousel of styled chips below the search bar:

```dart
final List<Map<String, dynamic>> filters = [
  {'key': 'all', 'label': 'All', 'icon': Icons.all_inclusive},
  {'key': 'unread', 'label': 'Unread', 'icon': Icons.mark_chat_unread_outlined},
  {'key': 'photos', 'label': 'Photos', 'icon': Icons.photo_outlined},
  {'key': 'videos', 'label': 'Videos', 'icon': Icons.videocam_outlined},
  {'key': 'links', 'label': 'Links', 'icon': Icons.link_outlined},
  {'key': 'audio', 'label': 'Audio', 'icon': Icons.audiotrack_outlined},
  {'key': 'documents', 'label': 'Documents', 'icon': Icons.description_outlined},
  {'key': 'contacts', 'label': 'Contacts', 'icon': Icons.person_outline},
  {'key': 'polls', 'label': 'Polls', 'icon': Icons.poll_outlined},
];

Widget _buildFilterChips() {
  return SizedBox(
    height: 38,
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: filters.length,
      separatorBuilder: (_, __) => const SizedBox(width: 8),
      itemBuilder: (context, index) {
        final filter = filters[index];
        final isSelected = _activeFilter == filter['key'];
        return FilterChip(
          selected: isSelected,
          avatar: Icon(filter['icon'], size: 16, color: isSelected ? Colors.white : Colors.grey),
          label: Text(filter['label']),
          selectedColor: const Color(0xFF00D084),
          onSelected: (selected) {
            setState(() {
              _activeFilter = filter['key'];
            });
            context.read<SearchBloc>().add(FilterChangedEvent(filter: _activeFilter));
          },
        );
      },
    ),
  );
}
```

---

### 5.2 Query Text Highlighting

Use a rich text builder to highlight the matched substring:

```dart
Widget buildHighlightedText({
  required String fullText,
  required String query,
  required TextStyle baseStyle,
  required TextStyle highlightStyle,
}) {
  if (query.trim().isEmpty) return Text(fullText, style: baseStyle);

  final spans = <TextSpan>[];
  final lowerFull = fullText.toLowerCase();
  final lowerQuery = query.toLowerCase();

  int start = 0;
  int index = lowerFull.indexOf(lowerQuery, start);

  while (index != -1) {
    if (index > start) {
      spans.add(TextSpan(text: fullText.substring(start, index), style: baseStyle));
    }
    spans.add(
      TextSpan(
        text: fullText.substring(index, index + query.length),
        style: highlightStyle,
      ),
    );
    start = index + query.length;
    index = lowerFull.indexOf(lowerQuery, start);
  }

  if (start < fullText.length) {
    spans.add(TextSpan(text: fullText.substring(start), style: baseStyle));
  }

  return RichText(text: TextSpan(children: spans));
}
```

---

## 6. Search Result Navigation & Deep Linking

When a user taps an item in the search results:

1. **Chats Section Tap:**
   - Navigates directly to `ChatPage` with `conversationId`.
2. **Contacts Section Tap:**
   - If contact has an existing `conversationId`, opens that chat.
   - If no conversation exists yet, initiates a new direct chat via `ChatSocketBloc.createDirectConversation`.
3. **Messages Section Tap:**
   - Opens `ChatPage` with `conversationId` and passes `highlightMessageId: message.id`.
   - `ChatPage` automatically scrolls to that message index and flashes a subtle highlight animation around the message bubble.

---

## 7. Testing & Performance Optimizations

1. **Debounce Input:**
   - User typing is debounced by **300ms** to prevent flooding backend search endpoints.
2. **Pagination:**
   - Infinite scroll triggered when reaching 80% scroll depth on long result lists (`offset += limit`).
3. **Memory Management:**
   - Image and avatar caching with `CachedNetworkImage` to ensure butter-smooth 60fps scrolling during rapid searches.
4. **Backend Indexing:**
   - Ensure Postgres indexes on `messages.text` (Trigram / GIN index) and `contacts.name` for sub-50ms search latency across large message histories.
