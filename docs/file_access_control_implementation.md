# File Access Control -- Implementation Plan

## 1. Overview

Implement a secure, hierarchical file-sharing system for files, images,
videos, audio, and documents.

Every recipient receives only the permissions explicitly granted to
them. A recipient may share the file further only when they have
effective Share permission. They cannot grant permissions that exceed
their own effective permissions.

**Core principle:** The original owner retains full control. Each
sharing relationship forms a parent-child branch. Revoking a sharing
relationship invalidates that recipient's branch without affecting
unrelated branches.

## 2. Users and sharing hierarchy

Example users:

-   **User 1:** Original file owner.
-   **User 2:** First recipient.
-   **User 3 and User 4:** Recipients shared by User 2.
-   **User 5:** Recipient shared by User 3.

``` mermaid
flowchart TD
    U1["User 1 — Original Owner"] --> U2["User 2"]
    U2 --> U3["User 3"]
    U2 --> U4["User 4"]
    U3 --> U5["User 5"]
```

The hierarchy may contain any number of levels. Every share record must
identify the parent share record that authorized it.

## 3. Permission model

Each sharing relationship has three independent permissions:

  Permission   Meaning                                 Default for a new recipient
  ------------ --------------------------------------- -----------------------------
  View         Open and view the file inside the app   Enabled
  Download     Save the original file to the device    Disabled
  Share        Share the file with another user        Disabled

### Initial sharing

When User 1 sends a file to User 2:

-   View is enabled by default.
-   Download is disabled by default.
-   Share is disabled by default.
-   User 2 can view the file but cannot download or share it.

The sender can explicitly grant Download and/or Share before sending, or
update the recipient's permissions later.

### Permission inheritance

A child must never receive a permission that the child's parent does not
effectively possess.

Example:

  User               View   Download   Share
  ---------------- ------ ---------- -------
  User 1 (owner)      Yes        Yes     Yes
  User 2              Yes        Yes     Yes
  User 3              Yes         No     Yes
  User 5              Yes         No      No

User 3 cannot grant Download to User 5 because User 3 does not have
effective Download permission.

Effective permissions must be evaluated across the complete active
ancestor chain, not just the immediate parent record.

A useful rule is:

`effective_permission(user) = requested_permission AND every_active_ancestor_grants_permission`

The owner is the root authority and is not constrained by a parent
share.

### Permission update behavior

-   A sender may update permissions only for a sharing relationship they
    are authorized to manage.
-   A parent may reduce permissions for its descendants by changing its
    own grant.
-   Descendants must not retain an effective permission when an ancestor
    no longer grants it.
-   A recipient cannot modify their own permissions to gain additional
    access.
-   Permission changes must be checked and enforced by the backend on
    every operation.

## 4. Sharing workflow

### User 1 shares with User 2

1.  User 1 selects a file.
2.  The app displays the permission configuration screen.
3.  View is enabled by default; Download and Share are disabled.
4.  User 1 selects the recipient and sends the file.
5.  The backend creates the root sharing relationship for User 2.
6.  User 2 sees only the actions allowed by their effective permissions.

### User 1 later enables Download and Share

1.  User 1 opens the file's sharing details.
2.  User 1 enables Download and/or Share for User 2.
3.  The backend validates that User 1 is the owner or authorized
    manager.
4.  The backend saves the permission update.
5.  User 2's effective permissions are recalculated.
6.  The app refreshes the available actions and may send a notification.

### User 2 shares with User 3 and User 4

1.  User 2 selects Share.
2.  The backend confirms User 2 has effective Share permission and an
    active share relationship.
3.  User 2 chooses User 3 and/or User 4.
4.  The app shows a permission configuration screen for each recipient.
5.  View is enabled by default.
6.  Download and Share are disabled by default.
7.  User 2 may grant only permissions User 2 effectively possesses.
8.  The backend creates separate child share records with User 2's share
    record as their parent.

### User 3 shares with User 5

The same process applies. User 3 must have effective Share permission.
User 3 may grant User 5 only the permissions User 3 effectively
possesses.

## 5. Revocation behavior

The system must distinguish between **disabling a permission** and
**revoking access**.

-   **Disable a permission:** Removes one capability, such as Download
    or Share. Other granted permissions may remain.
-   **Revoke access / Stop sharing:** Revokes the recipient's access and
    all access that depends on that recipient's sharing branch.

### Owner-level revocation

If User 1 revokes User 2's share or stops sharing the file:

-   User 2 loses access.
-   All descendants under User 2, including Users 3, 4, and 5, lose
    access through that branch.
-   View, Download, and Share are denied for the revoked branch.
-   The original owner retains access and control.
-   Any access links and tokens must be rejected after revocation is
    effective.

``` mermaid
flowchart TD
    A["User 1 — Owner"] --> B["User 2"]
    B --> C["User 3"]
    B --> D["User 4"]
    C --> E["User 5"]
    A --> F["Owner revokes User 2 branch"]
    F --> G["User 2 access revoked"]
    F --> H["User 3 access revoked"]
    F --> I["User 4 access revoked"]
    F --> J["User 5 access revoked"]
    A -.-> K["Owner retains access"]
```

### Intermediate-user revocation

If User 2 revokes their sharing branch:

-   User 2 retains their own access.
-   User 1 is unaffected.
-   Users 3 and 4 lose access through User 2.
-   User 5 loses access through User 3.
-   Unrelated branches remain unaffected.

If User 3 revokes their share to User 5, User 3 retains access and User
5's branch is revoked.

### Disable Share versus Stop Sharing

If User 3 disables only the Share permission granted to User 4:

-   User 4 loses effective Share permission.
-   User 4 may retain View and Download if those permissions remain
    granted.
-   Descendants under User 4 cannot continue sharing because their
    ancestor no longer has effective Share permission.
-   User 1, User 2, and unrelated branches are unaffected.

If User 3 chooses **Revoke Access** for User 4, User 4 and the
descendants whose access depends on that share lose access.

### Revocation flowchart

``` mermaid
flowchart TD
    A["User selects Stop Sharing / Revoke Access"] --> B["Authenticate user"]
    B --> C["Identify file and share relationship"]
    C --> D{"Is user the owner?"}
    D -->|Yes| E["Revoke selected root share branch"]
    D -->|No| F["Verify user owns or manages this child share"]
    F --> G{"Authorized?"}
    G -->|No| H["Reject request"]
    G -->|Yes| I["Revoke selected child share branch"]
    E --> J["Mark share and dependent descendants revoked"]
    I --> J
    J --> K["Invalidate or reject outstanding access tokens"]
    K --> L["Update effective permissions"]
    L --> M["Notify affected recipients"]
    M --> N["Write audit records"]
```

**Multiple independent shares:** If the same person receives the same
file through two independent branches, revoking one branch must not
automatically revoke the other. Access remains only if another valid
active grant still authorizes it. The backend must evaluate each grant
path and avoid accidentally revoking unrelated branches.

## 6. Database design

The following is a suggested relational schema. Adapt field types,
naming, indexes, and constraints to the existing backend and database.

### 6.1 `files`

Stores the original file metadata.

  Field           Description
  --------------- ----------------------------
  `id`            Unique file ID
  `owner_id`      Original owner user ID
  `storage_key`   Private object-storage key
  `file_name`     Original file name
  `mime_type`     MIME type
  `file_size`     File size in bytes
  `status`        Active / Deleted
  `created_at`    Creation timestamp
  `updated_at`    Last update timestamp

### 6.2 `file_shares`

Stores each sender-to-recipient relationship. Every child share points
to the share that authorized it.

  -----------------------------------------------------------------------
  Field                               Description
  ----------------------------------- -----------------------------------
  `id`                                Unique share ID

  `file_id`                           Related file

  `sender_id`                         User who shared the file

  `receiver_id`                       Recipient user

  `parent_share_id`                   Parent share ID; null for an
                                      owner-created root share

  `status`                            Active / Revoked / Expired

  `created_at`                        Share creation timestamp

  `revoked_at`                        Revocation timestamp, nullable

  `revoked_by`                        User who revoked it, nullable
  -----------------------------------------------------------------------

Recommended constraints and indexes:

-   Index `(file_id, receiver_id, status)`.
-   Index `parent_share_id`.
-   Index `(sender_id, file_id, status)`.
-   Use a foreign key from `parent_share_id` to `file_shares.id`.
-   Validate that parent and child records refer to the same file.
-   Prevent cycles and self-sharing.
-   Define how duplicate active shares to the same recipient are
    handled.

### 6.3 `file_permissions`

Stores the permission grant for each share relationship.

  Field            Description
  ---------------- ------------------------------
  `id`             Permission record ID
  `share_id`       Related share ID
  `can_view`       View permission
  `can_download`   Download permission
  `can_share`      Share permission
  `updated_at`     Last update timestamp
  `updated_by`     User who updated permissions

Add a unique constraint on `share_id` if each share has exactly one
current permission record. Alternatively, use versioned permission
records if historical snapshots are required.

### 6.4 `file_access_logs`

Stores security and activity audit events.

  Field              Description
  ------------------ ------------------------------------------------------
  `id`               Log ID
  `file_id`          File reference
  `share_id`         Relevant sharing relationship, nullable
  `user_id`          User performing the action
  `action`           View / Download / Share / Permission Update / Revoke
  `target_user_id`   Recipient, when applicable
  `result`           Allowed / Denied
  `created_at`       Event timestamp
  `metadata`         Safe structured event details

Do not log file contents, access tokens, or other secrets.

## 7. Backend permission validation

All permissions must be enforced by the backend. Hiding a button in the
app is not security enforcement.

### Share validation

Before creating a child share:

1.  Authenticate the requesting user.
2.  Confirm the file exists and is active.
3.  Confirm the requester is the owner or has a valid active share.
4.  If the requester is not the owner, verify effective Share permission
    across the full ancestor chain.
5.  Verify the recipient is valid and sharing with them is permitted by
    product rules.
6.  Verify every requested permission is within the requester's
    effective permissions.
7.  Create the child share and permission grant atomically.
8.  Write an audit event and notify the recipient.

### Pseudocode

``` text
function shareFile(requester, file, recipient, requestedPermissions):
    authenticate(requester)

    assert file.status == ACTIVE
    assert recipient is valid
    assert requester != recipient

    if requester is file.owner:
        parentShare = null
        requesterPermissions = OWNER_PERMISSIONS
    else:
        parentShare = findActiveShare(file, requester)
        assert parentShare exists
        requesterPermissions = calculateEffectivePermissions(parentShare)
        assert requesterPermissions.share == true

    assert requestedPermissions.view <= requesterPermissions.view
    assert requestedPermissions.download <= requesterPermissions.download
    assert requestedPermissions.share <= requesterPermissions.share

    transaction:
        childShare = createShare(
            file_id = file.id,
            sender_id = requester.id,
            receiver_id = recipient.id,
            parent_share_id = parentShare.id if parentShare else null
        )
        savePermissions(childShare, requestedPermissions)
        writeAuditEvent("SHARE")

    notifyRecipient(recipient, file)
```

The pseudocode is conceptual. Production code must handle multiple
active grants, transaction conflicts, duplicate shares, recipient
eligibility, and authorization edge cases.

### Effective permission calculation

For a given share path, a permission is effective only if:

-   The share itself is active.
-   Every ancestor share in that path is active.
-   The permission is granted at every required level.
-   The file is active and available.
-   The user is authorized through that path.

If multiple independent active paths exist, evaluate each path
separately. A valid path may continue to authorize access even if
another path is revoked.

## 8. Suggested API endpoints

These are proposed REST endpoint names; align them with existing API
conventions.

  ----------------------------------------------------------------------------------------
  Method                  Endpoint                                 Purpose
  ----------------------- ---------------------------------------- -----------------------
  `POST`                  `/files/share`                           Create a share

  `GET`                   `/files/{file_id}/permissions`           Get current effective
                                                                   permissions

  `PUT`                   `/files/shares/{share_id}/permissions`   Update a share's
                                                                   permissions

  `POST`                  `/files/shares/{share_id}/revoke`        Revoke a share and its
                                                                   dependent branch

  `GET`                   `/files/{file_id}/sharing-tree`          Get authorized sharing
                                                                   hierarchy

  `GET`                   `/files/{file_id}/history`               Get authorized sharing
                                                                   history

  `GET`                   `/files/{file_id}/view`                  Validate and serve view
                                                                   access

  `GET`                   `/files/{file_id}/download`              Validate and serve
                                                                   download access
  ----------------------------------------------------------------------------------------

For every endpoint:

-   Authenticate the user.
-   Authorize the exact file and share relationship.
-   Avoid trusting client-supplied user IDs or permission values.
-   Return consistent access-denied responses without leaking private
    file metadata.
-   Log relevant allow/deny outcomes.

## 9. Flutter UI requirements

### 9.1 Before sending

Show a permission configuration panel for each file attachment:

-   File name, type, and size.
-   View toggle: ON by default.
-   Download toggle: OFF by default.
-   Share toggle: OFF by default.
-   Recipient selection.
-   Send action.

Do not allow a sender to enable a permission they do not effectively
possess.

### 9.2 Received file

Show only actions that the backend reports as currently allowed:

-   View
-   Download
-   Share

A disabled action may be displayed with a clear explanation, or hidden
according to the product's design system. In either case, the backend
must reject unauthorized requests.

### 9.3 File details

Display:

-   File name, type, and size.
-   Original owner.
-   Shared by (immediate sender).
-   Share date and time.
-   Current effective permissions.
-   Sharing history or branch details, subject to access rights.
-   Manage Permissions, where authorized.
-   Stop Sharing / Revoke Access, where authorized.

### 9.4 Permission refresh

Refresh permissions when:

-   The file details screen opens.
-   The user attempts View, Download, or Share.
-   A permission-change or revocation event is received.
-   The app resumes after being in the background.

Treat server responses as authoritative. Do not rely on cached
permission state for sensitive operations.

## 10. Security requirements

1.  Store files in private object storage; do not expose permanent
    public URLs.
2.  Use short-lived signed URLs only after backend authorization.
3.  Revalidate permission on every view, download, and share request.
4.  Revalidate the full active sharing path.
5.  Ensure revoked links and tokens cannot continue to provide access
    beyond the defined security validity window.
6.  For immediate revocation, use an authenticated streaming/proxy layer
    or another design that checks authorization during access.
    Short-lived signed URLs alone cannot guarantee instant revocation.
7.  Prevent users from changing permissions by modifying client
    requests.
8.  Use transactions for share creation, permission updates, and
    revocation.
9.  Record audit events for permission changes and access attempts.
10. Use WebSocket or push notifications to refresh recipient UI after
    permission changes.
11. Rate-limit sensitive endpoints and protect against enumeration.
12. Validate file type, size, and upload security independently of
    sharing permissions.
13. Consider Android secure-window protections and iOS capture detection
    for view-only content. These reduce casual capture but cannot
    guarantee prevention of screenshots, external cameras, or all
    recording methods.
14. Define retention, deletion, backup, and legal-hold behavior for
    revoked or deleted files.

## 11. Sharing and revocation flowcharts

### End-to-end sharing flow

``` mermaid
flowchart TD
    A["User selects file / image"] --> B["Configure permissions"]
    B --> C["View ON by default"]
    C --> D["Download OFF and Share OFF by default"]
    D --> E["Select recipient and send"]
    E --> F["Backend authenticates sender"]
    F --> G{"Is sender owner or authorized sharer?"}
    G -->|No| H["Reject share"]
    G -->|Yes| I["Validate requested permissions"]
    I --> J{"Within sender's effective permissions?"}
    J -->|No| H
    J -->|Yes| K["Create share and parent relationship"]
    K --> L["Save permission grant"]
    L --> M["Notify recipient"]
    M --> N["Recipient opens file"]
    N --> O["Backend evaluates effective permissions"]
    O --> P["Show allowed actions"]
```

### Access request flow

``` mermaid
flowchart TD
    A["User requests View / Download / Share"] --> B["Authenticate user"]
    B --> C["Find active grant path(s)"]
    C --> D{"Any valid active path?"}
    D -->|No| E["Deny access"]
    D -->|Yes| F["Calculate effective permission"]
    F --> G{"Requested action allowed?"}
    G -->|No| E
    G -->|Yes| H["Serve or perform requested action"]
    H --> I["Write audit event"]
```

## 12. Mandatory test scenarios

  ----------------------------------------------------------------------------
                            \# Scenario              Expected result
  ---------------------------- --------------------- -------------------------
                             1 Owner sends with      Only View is enabled
                               defaults              

                             2 Recipient attempts    Backend denies
                               Download without      
                               permission            

                             3 Recipient attempts    Backend denies
                               Share without         
                               permission            

                             4 Owner enables         Recipient can download
                               Download              

                             5 Owner enables Share   Recipient can share

                             6 Recipient shares with New recipient gets only
                               another user          explicitly granted
                                                     permissions

                             7 Child tries to grant  Backend rejects
                               more than their       
                               effective permissions 

                             8 Owner revokes a root  All descendants dependent
                               branch                on that branch lose
                                                     access

                             9 Intermediate user     Only dependent
                               revokes their branch  descendants lose access

                            10 One independent       Other valid branches
                               branch is revoked     remain active

                            11 Parent disables       Descendants lose
                               Download              effective Download
                                                     through that path

                            12 Parent disables Share Descendants cannot
                                                     continue sharing through
                                                     that path

                            13 User uses an old link Access is denied
                               after revocation      according to revocation
                                                     guarantees

                            14 User manipulates      Backend rejects
                               permission values in  unauthorized grant
                               an API request        

                            15 Parent and child      Transaction/consistency
                               permissions change    rules prevent privilege
                               concurrently          escalation

                            16 Same recipient has    Revoking one does not
                               two independent       incorrectly revoke the
                               grants                other

                            17 Revoked user tries to Backend denies new access
                               open a cached file    
                               URL                   

                            18 Unauthorized user     Backend denies access to
                               requests sharing tree private hierarchy
  ----------------------------------------------------------------------------

## 13. Recommended development sequence

1.  **Database and sharing hierarchy:** Create file, share,
    parent-share, permission, and audit models.
2.  **Initial permission UI:** Add View, Download, and Share controls
    before sending.
3.  **Permission engine:** Implement ancestor-chain validation and
    effective permission calculation.
4.  **Recipient UI:** Display only currently allowed actions.
5.  **Multi-level sharing:** Support recipient-to-recipient sharing with
    parent-child relationships.
6.  **Permission updates:** Allow authorized users to update their own
    grants.
7.  **Revocation:** Implement root and branch revocation, including
    descendant invalidation.
8.  **Storage security:** Add private storage, controlled access, and
    revocation-aware delivery.
9.  **Notifications and audit:** Notify affected users and record all
    relevant events.
10. **Testing:** Complete unit, integration, API security, concurrency,
    and device-level tests.

## 14. Definition of done

The feature is ready only when:

-   View, Download, and Share are independent permissions.
-   New recipients receive View by default and no other permissions by
    default.
-   Every child grant is limited by the sender's effective permissions.
-   The complete active parent-child chain is checked on the backend.
-   Owner revocation disables all dependent descendant access.
-   Intermediate revocation affects only the relevant branch.
-   Unrelated valid sharing paths continue to work.
-   Previously issued access mechanisms meet the defined revocation
    guarantees.
-   Unauthorized API calls cannot bypass UI restrictions.
-   Audit history and notifications work as specified.
-   All mandatory test scenarios pass.

## 15. Final architecture recommendation

Use a hierarchy based on:

`file_id + share_id + parent_share_id`

Treat each sharing relationship as a distinct branch. Store the
permission grant on the share relationship, calculate effective
permissions across each active path, and enforce every operation on the
backend.

This supports:

`User 1 → User 2 → User 3 → User 5`

and

`User 1 → User 2 → User 4`

while preserving original-owner control and branch-level revocation.

**Key implementation rule:** The frontend controls what users see; the
backend decides what users are allowed to do.
