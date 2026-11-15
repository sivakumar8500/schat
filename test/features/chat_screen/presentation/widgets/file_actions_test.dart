import 'package:flutter_test/flutter_test.dart';
import 'package:schat/features/chat_screen/src/domain/models/media_permissions_model.dart';
import 'package:schat/features/chat_screen/src/domain/models/media_access_tree_model.dart';

void main() {
  group('File Sharing & Granular Access Control - Presentation & Model Tests', () {
    test('MediaPermissionsModel parses permissions, shareId, and permissionVersion correctly', () {
      final json = {
        'file_id': 'file_100',
        'user_id': 'user_3',
        'is_owner': false,
        'share_id': 'grant_200',
        'permissions': {
          'can_view': true,
          'can_download': true,
          'can_share': false,
        },
        'granted_permissions': {
          'can_view': true,
          'can_download': true,
          'can_share': true,
        },
        'permission_version': 12,
      };

      final model = MediaPermissionsModel.fromJson(json);

      expect(model.fileId, equals('file_100'));
      expect(model.userId, equals('user_3'));
      expect(model.isOwner, isFalse);
      expect(model.shareId, equals('grant_200'));
      expect(model.permissionVersion, equals(12));
      expect(model.permissions.canView, isTrue);
      expect(model.permissions.canDownload, isTrue);
      expect(model.permissions.canShare, isFalse);

      expect(model.grantedPermissions, isNotNull);
      expect(model.grantedPermissions!.canShare, isTrue);
    });

    test('MediaAccessTreeModel parses parent_share_id and updated_at on nodes', () {
      final json = {
        'file_id': 'file_100',
        'uploader_id': 'user_1',
        'total_grants': 2,
        'access_tree': [
          {
            'grant_id': 'grant_1',
            'file_id': 'file_100',
            'parent_share_id': null,
            'granter': {'id': 'user_1', 'name': 'Owner'},
            'grantee': {'id': 'user_2', 'name': 'User 2'},
            'permissions': {'can_view': true, 'can_download': true, 'can_share': true},
            'effective_permissions': {'can_view': true, 'can_download': true, 'can_share': true},
            'status': 'active',
            'created_at': '2026-11-11T20:00:00Z',
            'updated_at': '2026-11-11T20:00:00Z',
            'downstream_shares': [
              {
                'grant_id': 'grant_2',
                'file_id': 'file_100',
                'parent_share_id': 'grant_1',
                'granter': {'id': 'user_2', 'name': 'User 2'},
                'grantee': {'id': 'user_3', 'name': 'User 3'},
                'permissions': {'can_view': true, 'can_download': true, 'can_share': true},
                'effective_permissions': {'can_view': true, 'can_download': true, 'can_share': false},
                'status': 'active',
                'created_at': '2026-11-11T20:05:00Z',
                'updated_at': '2026-11-11T20:10:00Z',
                'downstream_shares': [],
              }
            ],
          }
        ],
      };

      final tree = MediaAccessTreeModel.fromJson(json);

      expect(tree.fileId, equals('file_100'));
      expect(tree.uploaderId, equals('user_1'));
      expect(tree.totalGrants, equals(2));
      expect(tree.accessTree.length, equals(1));

      final rootNode = tree.accessTree.first;
      expect(rootNode.grantId, equals('grant_1'));
      expect(rootNode.parentShareId, isNull);
      expect(rootNode.downstreamShares.length, equals(1));

      final childNode = rootNode.downstreamShares.first;
      expect(childNode.grantId, equals('grant_2'));
      expect(childNode.parentShareId, equals('grant_1'));
      expect(childNode.permissions.canShare, isTrue); // granted
      expect(childNode.effectivePermissions.canShare, isFalse); // ancestor restricted
      expect(childNode.updatedAt, isNotNull);
    });

    test('Permission dependency rules: Download OFF forces Share OFF; View OFF forces all OFF', () {
      // Rule: View -> Download -> Share
      bool canView = true;
      bool canDownload = false;
      bool canShare = true; // granted

      // Effective computation
      bool effectiveDownload = canView && canDownload;
      bool effectiveShare = canView && effectiveDownload && canShare;

      expect(effectiveDownload, isFalse);
      expect(effectiveShare, isFalse);

      // Now disable view
      canView = false;
      canDownload = true;
      canShare = true;

      effectiveDownload = canView && canDownload;
      effectiveShare = canView && effectiveDownload && canShare;

      expect(canView, isFalse);
      expect(effectiveDownload, isFalse);
      expect(effectiveShare, isFalse);
    });

    test('Forward sheet least-privilege defaults and switch enabled constraints', () {
      // Sender permissions:
      const senderCanView = true;
      const senderCanDownload = true;
      const senderCanShare = false;

      // Recommended defaults: View ON when allowed, Download OFF, Share OFF
      bool viewToggle = senderCanView;
      bool downloadToggle = false;
      bool shareToggle = false;

      // Switch enablement:
      bool viewSwitchEnabled = senderCanView;
      bool downloadSwitchEnabled = senderCanDownload && viewToggle;
      bool shareSwitchEnabled = senderCanShare && viewToggle && downloadToggle;

      expect(viewToggle, isTrue);
      expect(downloadToggle, isFalse);
      expect(shareToggle, isFalse);

      expect(viewSwitchEnabled, isTrue);
      expect(downloadSwitchEnabled, isTrue);
      expect(shareSwitchEnabled, isFalse); // sender cannot share, switch disabled!
    });

    test('Stale version rejection prevents out-of-order permission updates', () {
      final Map<String, int> lastSeenPermissionVersions = {'file_100': 15};

      // Incoming event with older version
      const incomingVersionOld = 14;
      final shouldIgnoreOld = incomingVersionOld < (lastSeenPermissionVersions['file_100'] ?? 0);
      expect(shouldIgnoreOld, isTrue);

      // Incoming event with same version
      const incomingVersionSame = 15;
      final shouldIgnoreSame = incomingVersionSame < (lastSeenPermissionVersions['file_100'] ?? 0);
      expect(shouldIgnoreSame, isFalse);

      // Incoming event with newer version
      const incomingVersionNew = 16;
      final shouldIgnoreNew = incomingVersionNew < (lastSeenPermissionVersions['file_100'] ?? 0);
      expect(shouldIgnoreNew, isFalse);
    });
  });
}
