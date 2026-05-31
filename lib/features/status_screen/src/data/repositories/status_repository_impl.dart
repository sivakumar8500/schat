import 'package:flutter/material.dart';
import 'package:injectable/injectable.dart';
import '../../domain/repositories/status_repository.dart';
import '../../domain/status_model.dart';

@LazySingleton(as: StatusRepository)
class StatusRepositoryImpl implements StatusRepository {
  @override
  Future<List<StatusContactModel>> getRecentUpdates() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return [
      StatusContactModel(
        contactId: '1',
        name: 'Siva',
        profileColor: Colors.blue,
        statuses: [
          StatusItemModel(id: 's1', text: 'Hello World', timestamp: DateTime.now().subtract(const Duration(minutes: 10)), backgroundColor: Colors.blueAccent),
          StatusItemModel(id: 's2', text: 'Flutter is awesome', timestamp: DateTime.now().subtract(const Duration(minutes: 5)), backgroundColor: Colors.purple),
        ],
      ),
      StatusContactModel(
        contactId: '2',
        name: 'Anitha',
        profileColor: Colors.green,
        statuses: [
          StatusItemModel(id: 's3', imagePath: 'assets/images/sample.jpg', timestamp: DateTime.now().subtract(const Duration(minutes: 30)), backgroundColor: Colors.black),
        ],
      ),
    ];
  }

  @override
  Future<List<StatusContactModel>> getViewedUpdates() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return [
      StatusContactModel(
        contactId: '3',
        name: 'John',
        profileColor: Colors.orange,
        statuses: [
          StatusItemModel(id: 's4', text: 'Good Morning!', timestamp: DateTime.now().subtract(const Duration(hours: 2)), backgroundColor: Colors.orangeAccent, viewed: true),
        ],
      ),
    ];
  }

  @override
  Future<List<StatusContactModel>> getMutedUpdates() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return [];
  }

  @override
  Future<void> muteContact(String contactId, bool mute) async {
    await Future.delayed(const Duration(milliseconds: 200));
  }
}
