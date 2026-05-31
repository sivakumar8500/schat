import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:schat/features/status_screen/src/domain/status_model.dart';

void main() {
  group('StatusContactModel Tests', () {
    test('allViewed should be true if all statuses are viewed', () {
      final contact = StatusContactModel(
        contactId: '1',
        name: 'Test',
        profileColor: Colors.blue,
        statuses: [
          StatusItemModel(id: '1', timestamp: DateTime.now(), viewed: true),
          StatusItemModel(id: '2', timestamp: DateTime.now(), viewed: true),
        ],
      );

      expect(contact.allViewed, isTrue);
    });

    test('allViewed should be false if any status is not viewed', () {
      final contact = StatusContactModel(
        contactId: '1',
        name: 'Test',
        profileColor: Colors.blue,
        statuses: [
          StatusItemModel(id: '1', timestamp: DateTime.now(), viewed: true),
          StatusItemModel(id: '2', timestamp: DateTime.now(), viewed: false),
        ],
      );

      expect(contact.allViewed, isFalse);
    });

    test('statusCount should return correct number of statuses', () {
      final contact = StatusContactModel(
        contactId: '1',
        name: 'Test',
        profileColor: Colors.blue,
        statuses: [
          StatusItemModel(id: '1', timestamp: DateTime.now(), viewed: true),
          StatusItemModel(id: '2', timestamp: DateTime.now(), viewed: false),
        ],
      );

      expect(contact.statusCount, equals(2));
    });
  });
}
