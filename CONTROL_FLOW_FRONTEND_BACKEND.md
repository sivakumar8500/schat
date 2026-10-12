# 🔄 SChat End-to-End Control Flow Architecture (Frontend & Backend)

This document provides a comprehensive blueprint of the control flow across the **SChat** ecosystem, detailing the end-to-end interactions between the **Flutter Client (Frontend)** and the **FastAPI Modular Monolith (Backend)**.

---

## 📑 Table of Contents
1. [System Topology & Architectural Overview](#1-system-topology--architectural-overview)
2. [Layer-by-Layer Execution Model](#2-layer-by-layer-execution-model)
3. [End-to-End Control Flows](#3-end-to-end-control-flows)
   - [Flow 1: App Bootstrapping & OTP Authentication](#flow-1-app-bootstrapping--otp-authentication)
   - [Flow 2: Real-time WebSocket Gateway & Connection Lifecycle](#flow-2-real-time-websocket-gateway--connection-lifecycle)
   - [Flow 3: Real-time Messaging (Send, Persist, Fanout)](#flow-3-real-time-messaging-send-persist-fanout)
   - [Flow 4: Message Delivery & Read Receipts Lifecycle](#flow-4-message-delivery--read-receipts-lifecycle)
   - [Flow 5: Media Upload & S3 Presigned URL Pipeline](#flow-5-media-upload--s3-presigned-url-pipeline)
   - [Flow 6: WebRTC Calling Signaling & Media Negotiation](#flow-6-webrtc-calling-signaling--media-negotiation)
   - [Flow 7: Contact Synchronization & Presence Detection](#flow-7-contact-synchronization--presence-detection)
   - [Flow 8: Disappearing Messages & Background TTL Expiry](#flow-8-disappearing-messages--background-ttl-expiry)
   - [Flow 9: Offline Push Notifications via FCM & Celery](#flow-9-offline-push-notifications-via-fcm--celery)
   - [Flow 10: Group Management & Access Control (RBAC)](#flow-10-group-management--access-control-rbac)
4. [Cross-Layer Component Mapping Matrix](#4-cross-layer-component-mapping-matrix)
5. [Protocol & Payload Specifications](#5-protocol--payload-specifications)

---

## 1. System Topology & Architectural Overview

The SChat platform utilizes a decoupled, real-time client-server architecture:

```
┌────────────────────────────────────────────────────────────────────────────────────────┐
│                                 FLUTTER CLIENT (FRONTEND)                              │
│  ┌───────────────────────┐   ┌──────────────────────┐   ┌───────────────────────────┐  │
│  │   UI Views / Widgets  │──>│  BLoC State Machine  │──>│ Repositories & Services   │  │
│  └───────────────────────┘   └──────────────────────┘   └───────────────────────────┘  │
│                                                               │            │           │
│                                         REST API (Dio) ───────┘            │ WebSockets│
└───────────────────────────────────────────────┬────────────────────────────┼───────────┘
                                                │                            │
                                                ▼                            ▼
┌────────────────────────────────────────────────────────────────────────────────────────┐
│                                 FASTAPI SERVER (BACKEND)                               │
│  ┌───────────────────────────┐                       ┌──────────────────────────────┐  │
│  │  REST Routers (app/api)   │                       │  WebSocket Gateway / Manager │  │
│  └─────────────┬─────────────┘                       └──────────────┬───────────────┘  │
│                │                                                    │                  │
│                ▼                                                    ▼                  │
│  ┌───────────────────────────┐                       ┌──────────────────────────────┐  │
│  │  Services & Dependencies  │                       │   Redis Pub/Sub Fanout Bus   │  │
│  └─────────────┬─────────────┘                       └──────────────┬───────────────┘  │
│                │                                                    │                  │
│                ▼                                                    │                  │
│  ┌───────────────────────────┐                                      │                  │
│  │ SQLAlchemy 2.0 Async ORM  │                                      │                  │
│  └─────────────┬─────────────┘                                      │                  │
└────────────────┼────────────────────────────────────────────────────┼──────────────────┘
                 │                                                    │
                 ▼                                                    ▼
┌─────────────────────────────────┐   ┌───────────────────┐   ┌──────────────────────────┐
│   PostgreSQL 15 (Relational DB) │   │ Redis 7.0 (Cache) │   │ Celery Workers + FCM     │
└─────────────────────────────────┘   └───────────────────┘   └──────────────────────────┘
```

---

## 2. Layer-by-Layer Execution Model

### Frontend (Flutter Client)
* **Presentation Layer**: Flutter Widgets observe state emissions via `BlocBuilder` and `BlocListener`. User interactions dispatch Events into feature BLoCs (`AuthBloc`, `ChatSocketBloc`, `CallWebRtcBloc`, `ChatBloc`).
* **Domain Layer**: Clean Architecture boundaries defining pure models (`ChatSocketModel`, `MessageEntity`), abstract repository contracts, and isolated UseCases.
* **Data Layer**:
  * **HTTP Client**: `Dio` configured with `ApiInterceptor` (`lib/core/network/api_interceptor.dart`) automatically injecting `Authorization: Bearer <Token>`.
  * **Realtime Sockets**: `IWebSocketService` / `WebSocketChannel` maintaining active connection, dispatching message streams to `ChatSocketRepository`.
  * **Calling**: `WebRtcService` wrapper around `flutter_webrtc` managing `RTCPeerConnection`, `MediaStream`, and SDP negotiations.
  * **Local Persistence**: `StorageService` (`shared_preferences`) for session tokens and flags; `Hive` for offline messages, contacts, and security rules.

### Backend (FastAPI Monolith)
* **API Ingress**: FastAPI application with CORS middleware, JWT security interceptors, and typed Pydantic v2 schemas.
* **WebSocket Ingress**: `app/websocket/router.py` authenticates via query token (`?token=...`), handles bidirectional JSON envelopes, and delegates to `ConnectionManager`.
* **Database & Persistence**: `asyncpg` engine driving async SQLAlchemy sessions. Unit of Work pattern managed via FastAPI `Depends(get_db)`.
* **Distributed Coordination**:
  * **Redis**: In-memory pub/sub message distribution across horizontal server instances and user presence tracking.
  * **Celery**: Background asynchronous tasks (delayed message deletion, offline push notifications, thumbnail generation).

---

## 3. End-to-End Control Flows

---

### Flow 1: App Bootstrapping & OTP Authentication

Controls client launch, local token check, phone number verification, and session bootstrap.

```mermaid
sequenceDiagram
    autonumber
    participant UI as Flutter View (OtpPage)
    participant Bloc as AuthBloc
    participant Repo as AuthRepository
    participant Storage as SharedPreferences / Hive
    participant API as FastAPI (/auth/*)
    participant DB as PostgreSQL

    UI->>Bloc: SendOtpEvent(phone="+1234567890")
    Bloc->>Repo: requestOtp(phone)
    Repo->>API: POST /api/v1/auth/send-otp
    API->>API: Generate OTP & dispatch SMS
    API-->>Repo: 200 OK { "message": "OTP sent" }
    Repo-->>Bloc: Success
    Bloc-->>UI: Emit AuthOtpSentState()

    UI->>Bloc: VerifyOtpEvent(phone, otp="123456")
    Bloc->>Repo: verifyOtp(phone, otp)
    Repo->>API: POST /api/v1/auth/verify-otp
    API->>DB: Validate OTP & Query/Create User
    API-->>Repo: 200 OK { access_token, refresh_token, user_id, profile }
    Repo->>Storage: Save access_token, refresh_token, user_id
    Repo-->>Bloc: AuthSuccess(UserSession)
    Bloc-->>UI: Emit AuthenticatedState()
    UI->>UI: Navigate to DashboardPage
```

**Control Steps:**
1. **App Startup**: `SplashScreen` reads `StorageService.getAccessToken()`. If absent, redirects to `PhoneNumberPage`.
2. **Send OTP**: User submits phone number. `AuthBloc` executes `POST /auth/send-otp`.
3. **Verification**: User inputs code. `POST /auth/verify-otp` validates against DB.
4. **Token Persistence**: JWT tokens (`access_token`, `refresh_token`), `user_id`, and `device_id` are stored locally in `SharedPreferences`.
5. **Dependency Injection Update**: `ApiInterceptor` reads stored token for subsequent HTTP requests; WebSocket client attaches token in handshake.

---

### Flow 2: Real-time WebSocket Gateway & Connection Lifecycle

Handles connection establishment, authentication guard, subscription entitlement check, and heartbeat keepalive.

```mermaid
sequenceDiagram
    autonumber
    participant Client as Flutter (ChatSocketBloc)
    participant SocketRepo as ChatSocketRepository
    participant WSGateway as FastAPI WS Gateway (/ws)
    participant ConnMgr as ConnectionManager
    participant Redis as Redis Pub/Sub
    participant DB as PostgreSQL

    Client->>SocketRepo: connectSocket()
    SocketRepo->>WSGateway: ws://<HOST>/ws?token=<JWT_TOKEN>
    
    WSGateway->>WSGateway: Decode & Validate JWT Token
    alt Token Invalid / Expired
        WSGateway-->>SocketRepo: Close 4001 (Unauthorized)
    else Active Subscription Check Failed
        WSGateway-->>SocketRepo: Close 1008 (Policy Violation)
    else Authorized
        WSGateway->>ConnMgr: register(user_id, websocket)
        ConnMgr->>Redis: SADD "online_users" user_id
        ConnMgr->>Redis: SUBSCRIBE user:<user_id>
        WSGateway-->>SocketRepo: Connection Established (HTTP 101 Switching Protocols)
        SocketRepo-->>Client: Emit ChatSocketConnectedState()
    end

    loop Every 30 seconds
        SocketRepo->>WSGateway: {"type": "ping"}
        WSGateway-->>SocketRepo: {"type": "pong"}
    end

    alt Connection Dropped / Network Loss
        SocketRepo->>ConnMgr: Connection Closed
        ConnMgr->>Redis: SREM "online_users" user_id
        SocketRepo->>SocketRepo: Trigger Exponential Backoff Reconnect
    end
```

---

### Flow 3: Real-time Messaging (Send, Persist, Fanout)

Traces the path of a text message from sender keystroke to optimistic local rendering, WebSocket dispatch, backend persistence, Redis relay, and recipient receipt.

```mermaid
sequenceDiagram
    autonumber
    participant SenderUI as Sender (ChatPage)
    participant SenderBloc as ChatSocketBloc
    participant SenderRepo as ChatSocketRepository
    participant Hive as Local Hive DB
    participant WS as FastAPI WebSocket Router
    participant DB as PostgreSQL
    participant Redis as Redis Pub/Sub
    participant RecipientWS as Recipient Connection
    participant RecipientApp as Recipient (ChatSocketBloc)

    SenderUI->>SenderBloc: SendTextMessageEvent(conversationId, text)
    SenderBloc->>Hive: Insert local message (status: "sending", temp_id)
    SenderBloc-->>SenderUI: Optimistic UI Update (Display single tick / grey)
    
    SenderBloc->>SenderRepo: sendMessage(payload)
    SenderRepo->>WS: Frame: {"type": "send_message", "temp_id": "...", "conversation_id": "...", "content": "..."}
    
    WS->>DB: INSERT into messages (status="sent", created_at=now())
    WS->>DB: UPDATE conversations SET last_message_id, updated_at
    
    WS-->>SenderRepo: Frame: {"type": "message_sent", "temp_id": "...", "message_id": "msg_987", "status": "sent"}
    SenderRepo->>Hive: Update temp_id -> msg_987 (status: "sent")
    SenderRepo-->>SenderUI: Update message indicator to single checkmark

    WS->>Redis: PUBLISH user:<recipient_id> {"type": "new_message", "message": {...}}
    Redis-->>RecipientWS: Deliver payload
    RecipientWS-->>RecipientApp: Frame: {"type": "new_message", ...}
    RecipientApp->>RecipientApp: Process message, store in Hive, play notification tone
    RecipientApp-->>RecipientApp: Update conversation list & active chat view
```

---

### Flow 4: Message Delivery & Read Receipts Lifecycle

Controls real-time message status transitions: `sending` ➔ `sent` ➔ `delivered` ➔ `read`.

```mermaid
sequenceDiagram
    autonumber
    participant Recipient as Recipient App
    participant WS as FastAPI WebSocket
    participant DB as PostgreSQL
    participant Redis as Redis
    participant Sender as Sender App

    Note over Recipient, WS: Recipient receives "new_message" while online
    Recipient->>WS: Frame: {"type": "delivery_receipt", "message_ids": ["msg_987"]}
    WS->>DB: UPDATE messages SET status = 'delivered', delivered_at = now()
    WS->>Redis: PUBLISH user:<sender_id> {"type": "message_delivered", "message_ids": ["msg_987"]}
    Redis-->>Sender: Frame: {"type": "message_delivered"}
    Sender->>Sender: Update UI (Double grey checkmark)

    Note over Recipient, WS: Recipient opens conversation view
    Recipient->>WS: Frame: {"type": "read_receipt", "conversation_id": "c_123", "message_ids": ["msg_987"]}
    WS->>DB: UPDATE messages SET status = 'read', read_at = now()
    WS->>DB: UPDATE conversation_participants SET unread_count = 0
    WS->>Redis: PUBLISH user:<sender_id> {"type": "read_receipt", "conversation_id": "c_123", "message_ids": ["msg_987"]}
    Redis-->>Sender: Frame: {"type": "read_receipt"}
    Sender->>Sender: Update UI (Double blue checkmark)
```

---

### Flow 5: Media Upload & S3 Presigned URL Pipeline

Binary attachments bypass WebSockets to ensure high throughput, zero memory bottlenecks on the socket server, and secure direct-to-S3 storage.

```mermaid
sequenceDiagram
    autonumber
    participant UI as Flutter Client
    participant MediaService as MediaUploadService
    participant API as FastAPI (/media/*)
    participant S3 as AWS S3 / MinIO
    participant WS as WebSocket Gateway

    UI->>MediaService: Pick image/video/doc from device
    MediaService->>API: POST /api/v1/media/request-upload<br/>{media_type: "CHAT_IMAGE", file_name: "photo.jpg", size: 204800}
    API->>API: Generate unique S3 object key & presigned PUT URL
    API->>API: Insert pending record in media table
    API-->>MediaService: 200 OK { upload_url, object_key, media_id }

    MediaService->>S3: PUT binary bytes directly to upload_url (multipart/octet-stream)
    S3-->>MediaService: HTTP 200 OK (ETag returned)

    MediaService->>API: POST /api/v1/media/{media_id}/complete
    API->>S3: Verify object exists & read metadata
    API->>API: Mark media status as 'ACTIVE'
    API-->>MediaService: 200 OK { media_url, media_id, thumbnail_url }

    MediaService->>WS: Send message with media attachment payload:<br/>{"type": "send_message", "attachment": {"media_id": "...", "url": "...", "security": {...}}}
```

---

### Flow 6: WebRTC Calling Signaling & Media Negotiation

The WebSocket gateway acts as the signaling channel for SDP exchange, while audio/video media streams flow peer-to-peer (or via LiveKit SFU).

```mermaid
sequenceDiagram
    autonumber
    participant Caller as Caller App (CallWebRtcBloc)
    participant WS as WebSocket Signaling Server
    participant Callee as Callee App (CallWebRtcBloc)
    participant P2P as WebRTC P2P Media Stream

    Caller->>Caller: Initialize local MediaStream (mic / camera)
    Caller->>Caller: Create RTCPeerConnection & generate SDP Offer
    Caller->>WS: Frame: {"type": "call_initiate", "callee_id": "u2", "call_type": "audio", "sdp": "..."}
    
    WS->>Callee: Frame: {"type": "call_incoming", "caller_id": "u1", "call_id": "call_99", "sdp": "..."}
    Callee->>Callee: Play Ringtone & display Incoming Call UI
    
    alt Callee Rejects
        Callee->>WS: Frame: {"type": "call_response", "action": "reject", "call_id": "call_99"}
        WS->>Caller: Frame: {"type": "call_rejected", "call_id": "call_99"}
        Caller->>Caller: Terminate session & play busy tone
    else Callee Accepts
        Callee->>Callee: Acquire local audio/video MediaStream
        Callee->>Callee: SetRemoteDescription(Offer) & Create SDP Answer
        Callee->>WS: Frame: {"type": "call_response", "action": "accept", "call_id": "call_99", "sdp": "..."}
        WS->>Caller: Frame: {"type": "call_answered", "call_id": "call_99", "sdp": "..."}
        Caller->>Caller: SetRemoteDescription(Answer)

        par ICE Candidate Exchange
            Caller->>WS: Frame: {"type": "ice_candidate", "candidate": "..."}
            WS->>Callee: Frame: {"type": "ice_candidate_received", "candidate": "..."}
            Callee->>WS: Frame: {"type": "ice_candidate", "candidate": "..."}
            WS->>Caller: Frame: {"type": "ice_candidate_received", "candidate": "..."}
        end

        Note over Caller, Callee: P2P Handshake Complete: Direct Audio/Video Stream Active
        Caller<<->>Callee: Direct RTP/SRTP Media Transmission (P2P)

        Caller->>WS: Frame: {"type": "call_hangup", "call_id": "call_99"}
        WS->>Callee: Frame: {"type": "call_disconnected", "call_id": "call_99"}
        Caller->>Caller: Dispose PeerConnection & audio tracks
        Callee->>Callee: Dispose PeerConnection & audio tracks
    end
```

---

### Flow 7: Contact Synchronization & Presence Detection

```mermaid
sequenceDiagram
    autonumber
    participant App as Flutter Client
    participant API as FastAPI (/users/*)
    participant DB as PostgreSQL
    participant Redis as Redis
    participant WS as WebSocket Gateway

    App->>App: Request contact book permission & read phone numbers
    App->>API: POST /api/v1/users/sync-contacts<br/>{contacts: ["+1234567890", "+1987654321"]}
    API->>DB: Query users matching normalized phone hashes
    API->>DB: Upsert into contact_books (user_id, contact_user_id)
    API-->>App: 200 OK [{user_id, name, phone, avatar, is_registered: true}]
    App->>App: Save registered contacts in local Hive box

    Note over App, WS: Presence Detection
    App->>WS: Frame: {"type": "subscribe_presence", "user_ids": ["u2", "u3"]}
    WS->>Redis: SMISMEMBER "online_users" "u2" "u3"
    Redis-->>WS: [1, 0] (u2 is Online, u3 is Offline)
    WS-->>App: Frame: {"type": "presence_state", "statuses": {"u2": "online", "u3": "offline"}}
```

---

### Flow 8: Disappearing Messages & Background TTL Expiry

```mermaid
sequenceDiagram
    autonumber
    participant ClientA as User A
    participant WS as WebSocket Router
    participant DB as PostgreSQL
    participant Celery as Celery Worker (Workers/Scheduler)
    participant ClientB as User B

    ClientA->>WS: Frame: {"type": "set_disappearing_timer", "conversation_id": "c1", "duration_seconds": 86400}
    WS->>DB: UPDATE conversations SET disappearing_timer = 86400
    WS-->>ClientA: Frame: {"type": "disappearing_timer_updated", "duration": 86400}
    WS-->>ClientB: Frame: {"type": "disappearing_timer_updated", "duration": 86400}

    ClientA->>WS: Send message in conversation c1
    WS->>DB: INSERT message with expires_at = now() + interval '86400 seconds'
    
    Note over Celery, DB: Celery Beat periodic task (runs every minute)
    Celery->>DB: SELECT id, conversation_id FROM messages WHERE expires_at <= now() AND is_deleted = false
    Celery->>DB: UPDATE messages SET is_deleted = true, content = 'This message was deleted'
    Celery->>WS: Broadcast deletion event to active sockets
    WS-->>ClientA: Frame: {"type": "message_deleted", "message_id": "msg_987"}
    WS-->>ClientB: Frame: {"type": "message_deleted", "message_id": "msg_987"}
```

---

### Flow 9: Offline Push Notifications via FCM & Celery

```mermaid
sequenceDiagram
    autonumber
    participant ClientA as Sender App
    participant WS as WebSocket Gateway
    participant ConnMgr as ConnectionManager
    participant Celery as Celery Worker
    participant FCM as Firebase Cloud Messaging
    participant DeviceB as Offline Recipient Device

    ClientA->>WS: Frame: {"type": "send_message", "recipient_id": "u2", "content": "Hello"}
    WS->>ConnMgr: Check if u2 has an active socket connection
    
    alt Recipient is Online
        ConnMgr->>ConnMgr: Deliver directly via WebSocket
    else Recipient is Offline
        WS->>Celery: Enqueue task: send_push_notification.delay(recipient_id="u2", payload={...})
        Celery->>Celery: Retrieve device FCM tokens for u2 from DB
        Celery->>FCM: Dispatch HTTP v1 Push Notification (Title, Body, Data)
        FCM->>DeviceB: Wakeup Push Notification displayed in system tray
        DeviceB->>DeviceB: User taps notification -> Opens app -> Establishes WS -> Pulls missed messages
    end
```

---

### Flow 10: Group Management & Access Control (RBAC)

```mermaid
sequenceDiagram
    autonumber
    participant AdminUI as Group Admin (Flutter)
    participant API as FastAPI (/groups/*)
    participant DB as PostgreSQL
    participant Redis as Redis Pub/Sub
    participant Members as Group Members (Sockets)

    AdminUI->>API: POST /api/v1/groups/<br/>{title: "Project Team", member_ids: ["u2", "u3"]}
    API->>DB: INSERT INTO conversations (is_group=true, title="Project Team")
    API->>DB: INSERT INTO group_members (user_id=Admin, role='ADMIN')
    API->>DB: INSERT INTO group_members (user_id IN ['u2', 'u3'], role='MEMBER')
    API-->>AdminUI: 201 Created { group_id: "g_55", ... }

    AdminUI->>API: POST /api/v1/groups/g_55/admins/u2 (Promote to Admin)
    API->>DB: Verify requester has 'ADMIN' or 'OWNER' role
    API->>DB: UPDATE group_members SET role = 'ADMIN' WHERE user_id = 'u2'
    API->>Redis: PUBLISH group:g_55 {"type": "member_promoted", "group_id": "g_55", "user_id": "u2"}
    Redis-->>Members: Broadcast event: u2 is now an Admin
```

---

## 4. Cross-Layer Component Mapping Matrix

| Functional Module | Frontend Component (`lib/`) | Backend Router (`app/`) | Service / Worker Layer | Persistence / Broker |
| :--- | :--- | :--- | :--- | :--- |
| **Authentication & OTP** | `features/auth_screen/`<br>`AuthBloc`, `AuthRepository` | `app/auth/router.py`<br>`/api/v1/auth/*` | `app/auth/service.py`<br>SMS gateway provider | PostgreSQL `users`, `otps`<br>`StorageService` (Tokens) |
| **User Profile & Contacts**| `features/profile_screen/`<br>`ProfileBloc` | `app/users/router.py`<br>`/api/v1/users/*` | `app/users/service.py` | PostgreSQL `users`, `contact_books`<br>Hive `contacts_box` |
| **Realtime Messaging** | `features/chat_socket_screen/`<br>`ChatSocketBloc`, `ChatSocketRepository` | `app/websocket/router.py`<br>`/ws` | `app/websocket/manager.py`<br>`ConnectionManager` | PostgreSQL `messages`<br>Redis Pub/Sub, Hive DB |
| **Conversations & Groups** | `features/chat_screen/`<br>`ChatBloc`, `ChatRepository` | `app/chats/router.py`<br>`app/groups/router.py` | `app/chats/service.py`<br>`app/groups/service.py` | PostgreSQL `conversations`, `group_members` |
| **Media Attachments** | `services/media_upload_service.dart` | `app/media/router.py`<br>`/api/v1/media/*` | `app/media/service.py`<br>Boto3 S3 Client | AWS S3 / MinIO<br>PostgreSQL `media` |
| **WebRTC Audio/Video Calls**| `features/call_screen/`<br>`CallWebRtcBloc`, `WebRtcService` | `app/websocket/router.py`<br>`app/calls/router.py` | Signaling handler<br>`LiveKit SFU Service` | Redis call sessions<br>PostgreSQL `call_logs` |
| **Background Auto-Delete** | Timer triggers in `ChatPage` | None (Worker scheduled) | `app/workers/tasks.py`<br>Celery Beat scheduler | PostgreSQL `messages` |
| **Push Notifications** | `services/notification_service.dart`<br>FCM SDK | `app/notifications/router.py`<br>`/api/v1/notifications/*` | Celery asynchronous worker<br>`firebase_admin` SDK | PostgreSQL `device_tokens`<br>FCM Gateway |
| **24h Status / Stories** | `features/status_screen/`<br>`StatusBloc` | `app/chats/status_router.py`<br>`/api/v1/statuses/*` | `app/chats/status_service.py` | PostgreSQL `statuses`<br>Redis temporary keys |
| **Subscriptions & Paywall**| `features/subscription_screen/`<br>`SubscriptionBloc` | `app/subscriptions/router.py`<br>`/api/v1/subscriptions/*` | `app/subscriptions/service.py` | PostgreSQL `subscriptions`, `plans` |

---

## 5. Protocol & Payload Specifications

### WebSocket Envelope Standards

#### Outbound (Frontend ➔ Backend)
```json
{
  "type": "send_message",
  "temp_id": "uuid-v4-generated-by-client",
  "conversation_id": "uuid-of-conversation",
  "content": "Encrypted or plain string",
  "reply_to_message_id": null,
  "attachment": {
    "media_id": "media-record-uuid",
    "url": "https://s3.amazonaws.com/...",
    "type": "CHAT_IMAGE",
    "security": {
      "isLocked": false,
      "accessUsers": [],
      "allowDownload": true,
      "allowShare": true
    },
    "viewControl": {
      "type": "once",
      "maxViews": 1
    }
  }
}
```

#### Inbound (Backend ➔ Frontend)
```json
{
  "type": "new_message",
  "message": {
    "id": "msg_01J...",
    "temp_id": "uuid-v4-generated-by-client",
    "conversation_id": "c_...",
    "sender_id": "u_...",
    "content": "Hello world",
    "status": "sent",
    "created_at": "2026-10-12T08:30:00Z",
    "attachment": null,
    "security": {}
  }
}
```

#### Status Receipts
```json
// Delivered receipt
{
  "type": "delivery_receipt",
  "message_ids": ["msg_01J..."]
}

// Read receipt
{
  "type": "read_receipt",
  "conversation_id": "c_...",
  "message_ids": ["msg_01J..."]
}
```

---

## 🛡️ Resilience & Failure Modes

1. **Network Disconnection**:
   - The Flutter client's `ChatSocketRepository` activates an exponential backoff retry policy (1s, 2s, 5s, 10s, up to 30s).
   - In-flight messages are held in Hive with status `"sending"` and re-flushed upon reconnection.
2. **WebSocket Fallback to FCM**:
   - When a message target is offline in Redis (`user:<id>` channel has no active subscribers), the message persists in PostgreSQL and is forwarded to Celery to generate an immediate Firebase Cloud Notification.
3. **Optimistic UI Reconciliation**:
   - Every sent message generates a local client UUID (`temp_id`). Once the server confirms insertion, it returns `{temp_id, message_id}` so the client can reconcile and update the local database entry without flicker or duplicated bubbles.
