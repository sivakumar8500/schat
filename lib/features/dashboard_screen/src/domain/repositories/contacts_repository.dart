import 'dart:convert';
import 'package:fast_contacts/fast_contacts.dart';
import 'package:hive/hive.dart';
import 'package:injectable/injectable.dart';
import 'package:schat/core/network/api_result.dart';
import 'package:schat/core/network/api_service.dart';
import 'package:schat/features/profile_screen/src/domain/models/user_model.dart';
import 'package:schat/utils/common_endpoints.dart';

abstract class ContactsRepository {
  Future<List<Contact>> getContacts();
  Future<ApiResult<List<UserModel>>> syncContacts(List<String> phoneNumbers);
  Future<List<UserModel>> getCachedContacts();
  Future<void> cacheContacts(List<UserModel> contacts);
}

@LazySingleton(as: ContactsRepository)
class ContactsRepositoryImpl implements ContactsRepository {
  final ApiService _apiService;
  static const String _contactsBox = 'contacts_box';
  static const String _contactsKey = 'cached_contacts';

  ContactsRepositoryImpl(this._apiService);

  @override
  Future<List<Contact>> getContacts() async {
    try {
      return await FastContacts.getAllContacts();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<ApiResult<List<UserModel>>> syncContacts(List<String> phoneNumbers) async {
    final result = await _apiService.post<List<UserModel>>(
      CommonEndpoints.syncContacts,
      data: {'phone_numbers': phoneNumbers},
      mapper: (data) {
        if (data is List) {
          return data.map((e) => UserModel.fromJson(e as Map<String, dynamic>)).toList();
        }
        return [];
      },
    );

    if (result is Success<List<UserModel>>) {
      await cacheContacts(result.data);
    }

    return result;
  }

  @override
  Future<List<UserModel>> getCachedContacts() async {
    try {
      final box = await Hive.openBox(_contactsBox);
      final String? jsonString = box.get(_contactsKey);
      if (jsonString != null) {
        final List<dynamic> decoded = jsonDecode(jsonString);
        return decoded.map((e) => UserModel.fromJson(e as Map<String, dynamic>)).toList();
      }
    } catch (e) {
      // Log error or handle
    }
    return [];
  }

  @override
  Future<void> cacheContacts(List<UserModel> contacts) async {
    try {
      final box = await Hive.openBox(_contactsBox);
      final String jsonString = jsonEncode(contacts.map((e) => e.toJson()).toList());
      await box.put(_contactsKey, jsonString);
    } catch (e) {
      // Log error or handle
    }
  }
}
