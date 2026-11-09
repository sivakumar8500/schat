# File Control & Access Management — Flutter Integration Guide

This guide provides the complete specification, UI button logic, API endpoints, request/response payloads, and real-time WebSocket listeners needed to implement **Granular File Access Control** in Flutter.

---

## 🌟 Feature Overview

When a user shares a document, photo, video, or audio file, they control:
1. **View (`can_view`)**: Can the recipient open / view the media?
2. **Download (`can_download`)**: Can the recipient save / download the file to device storage?
3. **Share (`can_share`)**: Can the recipient forward / share the file with other users?

### Sub-Licensing & Cascading Rules for Flutter UI:
* **Permission Ceiling**: A user cannot grant permissions they do not possess. (e.g. If Bob does not have `can_download`, the "Allow Download" toggle must be **disabled / greyed out** when Bob forwards to Charlie).
* **Cascading Revocation**: If Alice revokes Bob, Bob and all downstream users (Charlie, Dave, Eve) lose access in real time via WebSockets.
* **Owner Master Control**: The original uploader can view the full **Access Tree** and selectively revoke any downstream user or revoke everyone at once.

---

## 📱 Flutter UI Buttons & Screen Workflows

### Screen 1: File / Media Viewer (Chat Bubble or Fullscreen Preview)

Inside the chat or full-screen media viewer, display these 4 action buttons:

| Button | UI State | Action / API |
|---|---|---|
| **👁️ View / Preview** | Always visible. If `can_view == false`, replace file content with *"Access Revoked"* lock overlay. | Calls `GET /api/v1/media/{id}/view-url` |
| **⬇️ Save / Download** | **Enabled** if `can_download == true`.<br>**Disabled / Hidden** with tooltip *"Download restricted by sender"* if `false`. | Calls `GET /api/v1/media/{id}/download-url` |
| **↗️ Forward / Share** | **Enabled** if `can_share == true`.<br>**Disabled / Hidden** with tooltip *"Forwarding restricted by sender"* if `false`. | Opens the **Share Permission Dialog** (Screen 2) |
| **🌳 Manage Access** | **Visible only for file uploader / granters**.<br>Opens the **Access Tree Screen** (Screen 3). | Calls `GET /api/v1/media/{id}/access-tree` |

---

### Screen 2: "Forward / Share File" Dialog (Flutter Modal BottomSheet)

When the user taps the **Forward / Share** button, show a contact picker modal with permission switches:

```
┌──────────────────────────────────────────────┐
│ Share File: contract_2026.pdf               │
│                                              │
│ Select Recipient: [ Charlie ▼ ]              │
│                                              │
│ Permissions for Recipient:                   │
│                                              │
│ [x] Allow View                               │
│     (Always true)                            │
│                                              │
│ [ ] Allow Download                           │
│     (*) Enabled only if sender has download  │
│     (*) Greyed out if sender lacks download  │
│                                              │
│ [ ] Allow Re-sharing / Forwarding            │
│     (*) Enabled only if sender has share     │
│     (*) Greyed out if sender lacks share     │
│                                              │
│ [   Cancel   ]          [   Send File   ]    │
└──────────────────────────────────────────────┘
```

#### Flutter Toggle State Logic:
```dart
bool canViewToggle = true; // Always true
bool canDownloadToggle = false;
bool canShareToggle = false;

// If current user does NOT have download rights, lock the toggle to false:
bool isDownloadSwitchEnabled = currentUserEffectivePermissions.canDownload;

// If current user does NOT have share rights, lock the toggle to false:
bool isShareSwitchEnabled = currentUserEffectivePermissions.canShare;
```

---

### Screen 3: "Access Management Tree" Screen

Shows the visual hierarchy of everyone who received the file, with per-node revoke buttons.

```
┌─────────────────────────────────────────────────────────────┐
│ File Access Control: contract_2026.pdf                      │
│                                                             │
│ [!] Revoke All Access (Owner Only - Red Button)             │
│─────────────────────────────────────────────────────────────│
│                                                             │
│ 👤 Alice (You - Owner)                                      │
│    └── 👤 Bob                                               │
│        Permissions: [View] [Download] [Share]               │
│        [ 🗑️ Revoke Bob & Downstream ]                        │
│        │                                                    │
│        └── 👤 Charlie                                       │
│            Permissions: [View]                              │
│            [ 🗑️ Revoke Charlie & Downstream ]               │
│            │                                                │
│            └── 👤 Dave                                      │
│                Permissions: [View]                          │
│                [ 🗑️ Revoke Dave & Downstream ]              │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## 🚀 API Endpoints & Payloads

Base URL: `https://your-api-domain.com/api/v1/media`  
Headers on all requests:
```http
Authorization: Bearer <access_token>
Content-Type: application/json
```

---

### 1. Check My Permissions for a File

Call this when opening a media message or preview screen to know which buttons to enable/disable.

#### `GET /api/v1/media/{media_id}/permissions`

#### Response (`200 OK`):
```json
{
  "file_id": "550e8400-e29b-41d4-a716-446655440000",
  "user_id": "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb",
  "is_owner": false,
  "permissions": {
    "can_view": true,
    "can_download": false,
    "can_share": true
  }
}
```

#### Button Binding:
* `can_view == true` $\rightarrow$ Render file preview.
* `can_download == false` $\rightarrow$ Disable / hide Download button.
* `can_share == true` $\rightarrow$ Enable Forward button.

---

### 2. Get Secure Download URL

Call this when user taps the **Download / Save** button.

#### `GET /api/v1/media/{media_id}/download-url`

#### Success (`200 OK`):
```json
{
  "download_url": "https://s3.amazonaws.com/bucket/uploads/file.pdf?X-Amz-Signature=..."
}
```
*(Proceed to download file using Flutter `dio` / `http` client)*.

#### Forbidden (`403 Forbidden`) — When user lacks download right:
```json
{
  "detail": "You do not have permission to download this media"
}
```
*(Show Flutter toast: "Download not permitted by file owner")*.

---

### 3. Get Secure View / Preview URL

Call this when user taps to open / stream the media.

#### `GET /api/v1/media/{media_id}/view-url`

#### Success (`200 OK`):
```json
{
  "view_url": "https://s3.amazonaws.com/bucket/uploads/file.jpg?X-Amz-Signature=..."
}
```

#### Forbidden (`403 Forbidden`) — When access revoked:
```json
{
  "detail": "You do not have permission to view this media"
}
```

---

### 4. Share / Forward File with Permissions

Call this when user confirms the **Forward / Share Modal** (Screen 2).

#### `POST /api/v1/media/{media_id}/shares`

#### Request Body:
```json
{
  "recipient_user_id": "cccccccc-cccc-cccc-cccc-cccccccccccc",
  "permissions": {
    "can_view": true,
    "can_download": false,
    "can_share": true
  }
}
```

#### Success Response (`200 OK`):
```json
{
  "id": "22222222-2222-2222-2222-222222222222",
  "file_id": "550e8400-e29b-41d4-a716-446655440000",
  "granter_id": "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb",
  "grantee_id": "cccccccc-cccc-cccc-cccc-cccccccccccc",
  "permissions": {
    "can_view": true,
    "can_download": false,
    "can_share": true
  },
  "status": "active",
  "created_at": "2026-11-09T14:00:00Z"
}
```

#### Privilege Escalation Error (`403 Forbidden`):
```json
{
  "detail": "Cannot grant 'can_download' exceeding your own effective access"
}
```
*(Show Flutter alert: "You cannot grant download permission because you do not have download access")*.

---

### 5. Fetch File Access Tree

Call this when loading the **Access Management Tree** (Screen 3).

#### `GET /api/v1/media/{media_id}/access-tree`

#### Response (`200 OK`):
```json
{
  "file_id": "550e8400-e29b-41d4-a716-446655440000",
  "uploader_id": "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa",
  "total_grants": 3,
  "access_tree": [
    {
      "grant_id": "11111111-1111-1111-1111-111111111111",
      "granter": { "id": "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa", "name": "Alice" },
      "grantee": { "id": "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb", "name": "Bob" },
      "permissions": { "can_view": true, "can_download": true, "can_share": true },
      "effective_permissions": { "can_view": true, "can_download": true, "can_share": true },
      "status": "active",
      "created_at": "2026-11-09T14:00:00Z",
      "downstream_shares": [
        {
          "grant_id": "22222222-2222-2222-2222-222222222222",
          "granter": { "id": "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb", "name": "Bob" },
          "grantee": { "id": "cccccccc-cccc-cccc-cccc-cccccccccccc", "name": "Charlie" },
          "permissions": { "can_view": true, "can_download": false, "can_share": true },
          "effective_permissions": { "can_view": true, "can_download": false, "can_share": true },
          "status": "active",
          "created_at": "2026-11-09T14:05:00Z",
          "downstream_shares": []
        }
      ]
    }
  ]
}
```

---

### 6. Revoke a Specific Share & Descendants

Call this when user taps the red **"Revoke"** button next to any recipient in the Access Tree.

#### `POST /api/v1/media/{media_id}/shares/{grant_id}/revoke`

#### Response (`200 OK`):
```json
{
  "success": true,
  "message": "Successfully revoked share and 2 descendant shares",
  "revoked_shares_count": 3,
  "affected_users_count": 3,
  "affected_user_ids": [
    "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb",
    "cccccccc-cccc-cccc-cccc-cccccccccccc",
    "dddddddd-dddd-dddd-dddd-dddddddddddd"
  ],
  "share_ids": [
    "11111111-1111-1111-1111-111111111111",
    "22222222-2222-2222-2222-222222222222",
    "33333333-3333-3333-3333-333333333333"
  ]
}
```

---

### 7. Emergency Revoke All Access (Owner Only)

Call this when the original owner taps **"Revoke All Access"**.

#### `POST /api/v1/media/{media_id}/revoke-all`

#### Response (`200 OK`):
```json
{
  "success": true,
  "message": "All share grants for this media revoked successfully"
}
```

---

## ⚡ Real-Time WebSocket Listeners

When an upstream user updates permissions or revokes a file, the server broadcasts WebSocket events immediately to affected clients.

Listen to these events on your existing chat WebSocket connection:

### Event 1: `file_permission_revoked`
Fired when someone revokes access to this file.
```json
{
  "type": "file_permission_revoked",
  "file_id": "550e8400-e29b-41d4-a716-446655440000",
  "affected_user_ids": ["bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb", "..."],
  "share_ids": ["11111111-1111-1111-1111-111111111111"]
}
```
#### Flutter Action:
* If `affected_user_ids.contains(currentUserId)`:
  * Close full-screen viewer if open.
  * Update chat message bubble state to **"Access Revoked"** with locked icon.
  * Clear cached presigned URL so user cannot play/open the file.

---

### Event 2: `file_permission_updated`
Fired when a granter modifies download or share permissions.
```json
{
  "type": "file_permission_updated",
  "file_id": "550e8400-e29b-41d4-a716-446655440000",
  "user_id": "cccccccc-cccc-cccc-cccc-cccccccccccc",
  "permissions": {
    "can_view": true,
    "can_download": true,
    "can_share": false
  }
}
```
#### Flutter Action:
* Update local permission state for this `file_id`.
* Dynamically enable or disable the **Download** and **Forward** buttons without refreshing the screen.

---

## 📦 Ready-to-Use Flutter Dart Models

Copy and paste these classes directly into your Flutter project:

```dart
class FilePermissions {
  final bool canView;
  final bool canDownload;
  final bool canShare;

  FilePermissions({
    required this.canView,
    required this.canDownload,
    required this.canShare,
  });

  factory FilePermissions.fromJson(Map<String, dynamic> json) {
    return FilePermissions(
      canView: json['can_view'] ?? true,
      canDownload: json['can_download'] ?? false,
      canShare: json['can_share'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'can_view': canView,
    'can_download': canDownload,
    'can_share': canShare,
  };
}

class EffectiveFilePermissions {
  final String fileId;
  final String userId;
  final bool isOwner;
  final FilePermissions permissions;

  EffectiveFilePermissions({
    required this.fileId,
    required this.userId,
    required this.isOwner,
    required this.permissions,
  });

  factory EffectiveFilePermissions.fromJson(Map<String, dynamic> json) {
    return EffectiveFilePermissions(
      fileId: json['file_id'],
      userId: json['user_id'],
      isOwner: json['is_owner'] ?? false,
      permissions: FilePermissions.fromJson(json['permissions']),
    );
  }
}
```

