import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:schat/features/profile_screen/src/data/models/add_emergency_contact_request.dart';
import 'package:schat/features/profile_screen/src/domain/repositories/profile_repository.dart';
import 'package:schat/features/profile_screen/src/presentation/bloc/emergency_contacts_state.dart';

class EmergencyContactsCubit extends Cubit<EmergencyContactsState> {
  final ProfileRepository _repository;

  EmergencyContactsCubit(this._repository) : super(const EmergencyContactsInitial());

  Future<void> fetchContacts() async {
    emit(const EmergencyContactsLoading());
    try {
      final result = await _repository.getAllEmergencyContacts();

      result.when(
        success: (response) => emit(EmergencyContactsLoaded(response)),
        failure: (message, _) => emit(EmergencyContactsError(message)),
      );
    } catch (e) {
      emit(EmergencyContactsError(e.toString()));
    }
  }

  Future<void> addContact(String name, String phone) async {
    emit(const EmergencyContactsAdding());
    final request = AddEmergencyContactRequest(contactName: name, phoneNumber: phone);
    final result = await _repository.addEmergencyContact(request);
    result.when(
      success: (_) {
        emit(const EmergencyContactsAddSuccess());
        fetchContacts();
      },
      failure: (message, _) => emit(EmergencyContactsAddError(message)),
    );
  }

  Future<void> updateContact(String id, String name) async {
    emit(const EmergencyContactsAdding());
    final result = await _repository.updateEmergencyContact(id, name);
    result.when(
      success: (_) {
        emit(const EmergencyContactsAddSuccess());
        fetchContacts();
      },
      failure: (message, _) => emit(EmergencyContactsAddError(message)),
    );
  }

  Future<void> deleteContact(String id) async {
    emit(const EmergencyContactsAdding());
    final result = await _repository.deleteEmergencyContact(id);
    result.when(
      success: (_) {
        emit(const EmergencyContactsAddSuccess());
        fetchContacts();
      },
      failure: (message, _) => emit(EmergencyContactsAddError(message)),
    );
  }
}
